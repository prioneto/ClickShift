@preconcurrency import CoreBluetooth
import AppKit
import Foundation
import ClickShiftCore

final class ClickController: NSObject, ObservableObject {
    enum ConnectionState: Equatable {
        case bluetoothOff
        case scanning
        case foundLeft
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
            case .connecting: return "Connecting…"
            case .connected: return "Connected"
            case .reconnecting: return "Disconnected; searching again…"
            case .waitingForMyWhoosh: return "Waiting for MyWhoosh"
            case .stopped: return "Stopped"
            case .failed(let message): return message
            }
        }

        var isConnected: Bool {
            self == .connected
        }
    }

    @Published private(set) var state: ConnectionState = .waitingForMyWhoosh
    @Published private(set) var lastAction = "No shifts yet"
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var deviceName = "Right Zwift Click v2"
    @Published private(set) var myWhooshRunning = false

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
    private var pressedButtons = Set<ClickButton>()
    private var handshakeStarted = false
    private var shouldRun = false
    private var lastUnknownCandidate: UUID?
    private var workspaceObservers = [NSObjectProtocol]()

    override init() {
        super.init()
        accessibilityGranted = keyboard.isAccessibilityGranted
        _ = central
        startWatchingMyWhoosh()
    }

    deinit {
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func start() {
        shouldRun = true
        beginScanningIfPossible()
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
        refreshMyWhooshState()
    }

    private func refreshMyWhooshState() {
        let running = NSWorkspace.shared.runningApplications.contains { app in
            if app.bundleIdentifier == "com.whoosh.whooshgame" { return true }
            return app.localizedName?.localizedCaseInsensitiveContains("MyWhoosh") == true
        }
        myWhooshRunning = running
        setMyWhooshRunning(running)
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
        performShift(.up, source: "Test")
    }

    func testShiftDown() {
        performShift(.down, source: "Test")
    }

    private func beginScanningIfPossible() {
        guard shouldRun else { return }
        guard central.state == .poweredOn else {
            state = .bluetoothOff
            return
        }
        guard peripheral == nil else { return }

        state = .scanning
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    private func connect(_ candidate: CBPeripheral) {
        central.stopScan()
        reconnectWorkItem?.cancel()
        peripheral = candidate
        candidate.delegate = self
        state = .connecting
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
        guard let nowPressed = ButtonPacketDecoder.decode(data) else { return }
        let newlyPressed = nowPressed.subtracting(pressedButtons)

        if newlyPressed.contains(.plus) {
            performShift(.up, source: "+")
        }
        if newlyPressed.contains(.b) {
            performShift(.down, source: "B")
        }
        pressedButtons = nowPressed
    }

    private func performShift(_ direction: KeyboardShifter.Direction, source: String) {
        let success = keyboard.shift(direction)
        accessibilityGranted = keyboard.isAccessibilityGranted
        let directionLabel = direction == .up ? "Shift up (K)" : "Shift down (I)"
        lastAction = success
            ? "\(source): \(directionLabel)"
            : "Accessibility permission needed"
    }

    private func scheduleReconnect() {
        guard shouldRun else { return }
        state = .reconnecting
        reconnectWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.beginScanningIfPossible()
        }
        reconnectWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: item)
    }

    private func clearConnection() {
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
        peripheral = nil
        writeCharacteristic = nil
        handshakeStarted = false
        pressedButtons.removeAll()
    }
}

extension ClickController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            beginScanningIfPossible()
        case .poweredOff, .unauthorized, .unsupported:
            state = .bluetoothOff
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
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        clearConnection()
        state = .failed("Could not connect: \(error?.localizedDescription ?? "unknown error")")
        scheduleReconnect()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        clearConnection()
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
