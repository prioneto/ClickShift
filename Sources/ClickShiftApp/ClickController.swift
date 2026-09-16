@preconcurrency import CoreBluetooth
import AppKit
import Combine
import Foundation
import ClickShiftCore

final class ClickController: NSObject, ObservableObject {
    enum ConnectionState: Equatable {
        case bluetoothOff
        case scanning
        case foundLeft
        case waitingForWake
        case connecting
        case connected
        case reconnecting
        case waitingForMyWhoosh
        case stopped
        case failed(String)

        var label: String {
            switch self {
            case .bluetoothOff: return "Bluetooth is off"
            case .scanning: return "Searching for right Click v2…"
            case .foundLeft: return "Left Click found; wake the right Click"
            case .waitingForWake: return "Wake your right Click"
            case .connecting: return "Connecting…"
            case .connected: return "Connected"
            case .reconnecting: return "Disconnected; searching again…"
            case .waitingForMyWhoosh: return "Waiting for riding app"
            case .stopped: return "Stopped"
            case .failed(let message): return message
            }
        }

        var isConnected: Bool {
            self == .connected
        }
    }

    @Published private(set) var state: ConnectionState = .waitingForMyWhoosh {
        didSet {
            guard oldValue != state else { return }
            recordEvent(state.label)
            notifyForStateChange(from: oldValue, to: state)
        }
    }
    @Published private(set) var lastAction = "No shifts yet"
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var deviceName = "Right Zwift Click v2"
    @Published private(set) var myWhooshRunning = false

    let settings: AppSettings

    var bluetoothAuthorizationGranted: Bool {
        CBManager.authorization == .allowedAlways
    }

    private let serviceUUID = CBUUID(string: "0000FC82-0000-1000-8000-00805F9B34FB")
    private let asyncUUID = CBUUID(string: "00000002-19CA-4651-86E5-FA29DCDD09D1")
    private let syncRxUUID = CBUUID(string: "00000003-19CA-4651-86E5-FA29DCDD09D1")
    private let syncTxUUID = CBUUID(string: "00000004-19CA-4651-86E5-FA29DCDD09D1")

    private let handshake: [Data] = [
        Data([0x52, 0x69, 0x64, 0x65, 0x4F, 0x6E, 0x02, 0x03]),
        Data([0x00, 0x08, 0x00]),
        Data([0x00, 0x08, 0x10]),
    ]
    private let keepalive = Data([0x00, 0x08, 0x10])

    private lazy var central = CBCentralManager(delegate: self, queue: .main)
    private let keyboard = KeyboardShifter()
    private var peripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var keepaliveTimer: Timer?
    private var reconnectWorkItem: DispatchWorkItem?
    private var wakeRecoveryWorkItem: DispatchWorkItem?
    private var settingsObservers = Set<AnyCancellable>()
    private var pressedButtons = Set<ClickButton>()
    private var handshakeStarted = false
    private var shouldRun = false
    private var setupMode = false
    private var attemptedRememberedConnection = false
    private var unknownPacketCount = 0
    private var diagnosticEvents: [String] = []
    private var lastUnknownCandidate: UUID?
    private var workspaceObservers = [NSObjectProtocol]()
    private var isSystemSleeping = false

    init(settings: AppSettings) {
        self.settings = settings
        super.init()
        accessibilityGranted = keyboard.isAccessibilityGranted
        startWatchingMyWhoosh()
        settings.$profile
            .combineLatest(settings.$customAppName)
            .dropFirst()
            .sink { [weak self] _ in self?.refreshMyWhooshState() }
            .store(in: &settingsObservers)
    }

    deinit {
        wakeRecoveryWorkItem?.cancel()
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func start() {
        shouldRun = true
        guard !isSystemSleeping else {
            state = .reconnecting
            return
        }
        beginScanningIfPossible()
    }

    func startSetupScan() {
        setupMode = true
        shouldRun = true
        attemptedRememberedConnection = false
        guard !isSystemSleeping else {
            state = .reconnecting
            return
        }
        beginScanningIfPossible()
    }

    func finishSetup() {
        setupMode = false
        refreshMyWhooshState()
    }

    func stop() {
        stop(waitingForMyWhoosh: false)
    }

    func setMyWhooshRunning(_ running: Bool) {
        if running {
            start()
        } else {
            stop(waitingForMyWhoosh: true)
        }
    }

    private func startWatchingMyWhoosh() {
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification] {
            let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.refreshMyWhooshState()
            }
            workspaceObservers.append(observer)
        }
        let sleepObserver = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.prepareForSystemSleep()
        }
        workspaceObservers.append(sleepObserver)

        let wakeObserver = center.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recoverFromSystemWake()
        }
        workspaceObservers.append(wakeObserver)
        refreshMyWhooshState()
    }

    private func refreshMyWhooshState() {
        let running = NSWorkspace.shared.runningApplications.contains { settings.matchesTarget($0) }
        myWhooshRunning = running
        if !setupMode {
            if isSystemSleeping {
                shouldRun = running
                state = running ? .reconnecting : .waitingForMyWhoosh
            } else {
                setMyWhooshRunning(running)
            }
        }
    }

    private func prepareForSystemSleep() {
        isSystemSleeping = true
        wakeRecoveryWorkItem?.cancel()
        wakeRecoveryWorkItem = nil
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
        central.stopScan()
        recordEvent("Mac is going to sleep")
    }

    private func recoverFromSystemWake() {
        isSystemSleeping = false
        refreshPermissions()

        let targetRunning = NSWorkspace.shared.runningApplications.contains { settings.matchesTarget($0) }
        myWhooshRunning = targetRunning
        guard setupMode || targetRunning else {
            stop(waitingForMyWhoosh: true)
            recordEvent("Mac woke; waiting for riding app")
            return
        }

        shouldRun = true
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        central.stopScan()
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        clearConnection()
        attemptedRememberedConnection = false
        state = .reconnecting
        recordEvent("Mac woke; restarting Bluetooth connection")
        scheduleWakeRecoveryAttempt()
    }

    private func scheduleWakeRecoveryAttempt(_ attempt: Int = 0) {
        wakeRecoveryWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self, !self.isSystemSleeping, self.shouldRun else { return }
            if self.central.state == .poweredOn {
                self.wakeRecoveryWorkItem = nil
                self.beginScanningIfPossible()
            } else if attempt < 5 {
                self.scheduleWakeRecoveryAttempt(attempt + 1)
            } else {
                self.wakeRecoveryWorkItem = nil
                self.state = .bluetoothOff
            }
        }
        wakeRecoveryWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: item)
    }

    private func stop(waitingForMyWhoosh: Bool) {
        shouldRun = false
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
        central.stopScan()
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        clearConnection()
        attemptedRememberedConnection = false
        state = waitingForMyWhoosh ? .waitingForMyWhoosh : .stopped
    }

    func reconnectNow() {
        shouldRun = true
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        central.stopScan()
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        clearConnection()
        attemptedRememberedConnection = false
        beginScanningIfPossible()
    }

    func refreshPermissions() {
        accessibilityGranted = keyboard.isAccessibilityGranted
    }

    func requestAccessibility() {
        accessibilityGranted = keyboard.requestAccessibility()
        if !accessibilityGranted {
            keyboard.openAccessibilitySettings()
        }
    }

    func testShiftUp() {
        testShift(.up)
    }

    func testShiftDown() {
        testShift(.down)
    }

    private func testShift(_ direction: KeyboardShifter.Direction) {
        guard settings.onlySendToTarget else {
            performShift(direction, source: "Test")
            return
        }
        guard let target = NSWorkspace.shared.runningApplications.first(where: { settings.matchesTarget($0) }) else {
            lastAction = "Open \(settings.targetName) before testing"
            return
        }
        target.activate(options: [.activateIgnoringOtherApps])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.performShift(direction, source: "Test")
        }
    }

    private func beginScanningIfPossible() {
        guard shouldRun else { return }
        guard central.state == .poweredOn else {
            state = .bluetoothOff
            return
        }
        guard peripheral == nil else { return }

        if !attemptedRememberedConnection,
           let identifierString = UserDefaults.standard.string(forKey: "preferredRightClickIdentifier"),
           let identifier = UUID(uuidString: identifierString),
           let remembered = central.retrievePeripherals(withIdentifiers: [identifier]).first {
            attemptedRememberedConnection = true
            connect(remembered, waitingForWake: true)
            return
        }

        state = .scanning
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    private func connect(_ candidate: CBPeripheral, waitingForWake: Bool = false) {
        central.stopScan()
        reconnectWorkItem?.cancel()
        peripheral = candidate
        candidate.delegate = self
        state = waitingForWake ? .waitingForWake : .connecting
        central.connect(candidate, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
    }

    private func sendHandshakeStep(_ index: Int = 0) {
        guard
            index < handshake.count,
            let peripheral,
            let writeCharacteristic,
            peripheral.state == .connected
        else {
            if index >= handshake.count {
                state = .connected
                startKeepalive()
            }
            return
        }

        let writeType: CBCharacteristicWriteType = writeCharacteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        peripheral.writeValue(handshake[index], for: writeCharacteristic, type: writeType)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.sendHandshakeStep(index + 1)
        }
    }

    private func startKeepalive() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard
                let self,
                let peripheral = self.peripheral,
                let characteristic = self.writeCharacteristic,
                peripheral.state == .connected
            else { return }
            let type: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse)
                ? .withoutResponse
                : .withResponse
            peripheral.writeValue(self.keepalive, for: characteristic, type: type)
        }
    }

    private func handleNotification(_ data: Data) {
        guard let nowPressed = ButtonPacketDecoder.decode(data) else {
            unknownPacketCount += 1
            if unknownPacketCount == 5 {
                recordEvent("Unrecognized controller packets detected")
                NotificationManager.shared.send(
                    title: "ClickShift controller warning",
                    body: "The Click firmware may have changed its button messages.",
                    enabled: settings.notificationsEnabled
                )
            }
            return
        }
        unknownPacketCount = 0
        let newlyPressed = nowPressed.subtracting(pressedButtons)

        if newlyPressed.contains(settings.upButton) {
            performShift(.up, source: settings.upButton.displayName)
        }
        if settings.downButton != settings.upButton, newlyPressed.contains(settings.downButton) {
            performShift(.down, source: settings.downButton.displayName)
        }
        pressedButtons = nowPressed
    }

    private func performShift(_ direction: KeyboardShifter.Direction, source: String) {
        if settings.onlySendToTarget && !settings.matchesTarget(NSWorkspace.shared.frontmostApplication) {
            lastAction = "Blocked: \(settings.targetName) isn’t focused"
            recordEvent(lastAction)
            return
        }

        let key = direction == .up ? settings.upKey : settings.downKey
        guard KeyboardShifter.isSupported(key: key) else {
            lastAction = "Unsupported key: \(key)"
            recordEvent(lastAction)
            return
        }

        let success = keyboard.shift(key: key, repeatCount: settings.gearStep)
        accessibilityGranted = keyboard.isAccessibilityGranted
        let directionLabel = direction == .up ? "Shift up (\(key))" : "Shift down (\(key))"
        lastAction = success
            ? "\(source): \(directionLabel) ×\(settings.gearStep)"
            : "Accessibility permission needed"
        recordEvent(lastAction)
        if !success {
            NotificationManager.shared.send(
                title: "ClickShift needs Accessibility",
                body: "Allow Accessibility so ClickShift can send your shift keys.",
                enabled: settings.notificationsEnabled
            )
        }
    }

    private func scheduleReconnect() {
        guard shouldRun, !isSystemSleeping else { return }
        state = .reconnecting
        reconnectWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.beginScanningIfPossible()
        }
        reconnectWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: item)
    }

    private func clearConnection() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
        peripheral = nil
        writeCharacteristic = nil
        handshakeStarted = false
        pressedButtons.removeAll()
    }

    func diagnosticsReport() -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development"
        let events = diagnosticEvents.suffix(30).map { "- \($0)" }.joined(separator: "\n")
        return """
        ClickShift privacy-safe diagnostics
        Version: \(version)
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Profile: \(settings.profile.title)
        State: \(state.label)
        Target running: \(myWhooshRunning)
        Accessibility: \(accessibilityGranted ? "Allowed" : "Required")
        Safety mode: \(settings.onlySendToTarget ? "On" : "Off")
        Gear step: \(settings.gearStep)
        Up mapping: \(settings.upButton.rawValue) -> \(settings.upKey)
        Down mapping: \(settings.downButton.rawValue) -> \(settings.downKey)

        Recent local events (no account, ride, or controller identifiers):
        \(events.isEmpty ? "- None" : events)
        """
    }

    private func recordEvent(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        diagnosticEvents.append("[\(formatter.string(from: Date()))] \(message)")
        if diagnosticEvents.count > 50 { diagnosticEvents.removeFirst(diagnosticEvents.count - 50) }
    }

    private func notifyForStateChange(from oldState: ConnectionState, to newState: ConnectionState) {
        switch newState {
        case .connected:
            NotificationManager.shared.send(
                title: "Click v2 connected",
                body: "ClickShift is ready for \(settings.targetName).",
                enabled: settings.notificationsEnabled
            )
        case .reconnecting where oldState.isConnected:
            NotificationManager.shared.send(
                title: "Click v2 disconnected",
                body: "Wake the right Click; reconnection is automatic.",
                enabled: settings.notificationsEnabled
            )
        default:
            break
        }
    }
}

extension ClickController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            wakeRecoveryWorkItem?.cancel()
            wakeRecoveryWorkItem = nil
            beginScanningIfPossible()
        case .poweredOff:
            state = wakeRecoveryWorkItem == nil ? .bluetoothOff : .reconnecting
        case .unauthorized, .unsupported:
            state = .bluetoothOff
        case .resetting, .unknown:
            if shouldRun { state = .reconnecting }
        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover candidate: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advertisedName ?? candidate.name ?? ""
        guard name.localizedCaseInsensitiveContains("Zwift Click") else { return }

        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let side = ZwiftAdvertisement.clickSide(from: manufacturerData)

        switch side {
        case .right:
            UserDefaults.standard.set(candidate.identifier.uuidString, forKey: "preferredRightClickIdentifier")
            deviceName = name
            connect(candidate)
        case .left:
            if state == .scanning { state = .foundLeft }
        case .unknown:
            // Once a peripheral was positively identified as right, its stable
            // CoreBluetooth identifier is safe to use if a later advert omits
            // manufacturer data.
            let remembered = UserDefaults.standard.string(forKey: "preferredRightClickIdentifier")
            if remembered == candidate.identifier.uuidString {
                connect(candidate)
            } else {
                lastUnknownCandidate = candidate.identifier
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        attemptedRememberedConnection = true
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard self.peripheral?.identifier == peripheral.identifier else { return }
        clearConnection()
        attemptedRememberedConnection = false
        state = .failed("Could not connect: \(error?.localizedDescription ?? "unknown error")")
        scheduleReconnect()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        guard self.peripheral?.identifier == peripheral.identifier else { return }
        clearConnection()
        attemptedRememberedConnection = false
        scheduleReconnect()
    }
}

extension ClickController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            state = .failed("Service discovery failed: \(error.localizedDescription)")
            central.cancelPeripheralConnection(peripheral)
            return
        }
        guard let services = peripheral.services, !services.isEmpty else {
            state = .failed("Zwift service not found")
            central.cancelPeripheralConnection(peripheral)
            return
        }
        for service in services {
            peripheral.discoverCharacteristics([asyncUUID, syncRxUUID, syncTxUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            state = .failed("Button setup failed: \(error.localizedDescription)")
            central.cancelPeripheralConnection(peripheral)
            return
        }
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == syncRxUUID {
                writeCharacteristic = characteristic
            } else if characteristic.uuid == asyncUUID || characteristic.uuid == syncTxUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }

        if writeCharacteristic != nil, !handshakeStarted {
            handshakeStarted = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.sendHandshakeStep()
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil, let data = characteristic.value else { return }
        handleNotification(data)
    }
}
