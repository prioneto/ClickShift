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
}
