import AppKit

enum AppAssets {
    static func image(named name: String, template: Bool = false, size: NSSize? = nil) -> NSImage? {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else {
            return nil
        }

        image.isTemplate = template
        if let size {
            image.size = size
        }
        return image
    }

    static func tintedImage(named name: String, color: NSColor, size: NSSize) -> NSImage? {
        guard let source = image(named: name, size: size) else { return nil }
        let result = NSImage(size: size)
        result.lockFocus()
        color.setFill()
        NSRect(origin: .zero, size: size).fill()
        source.draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .destinationIn,
            fraction: 1
        )
        result.unlockFocus()
        result.isTemplate = false
        return result
    }
}
