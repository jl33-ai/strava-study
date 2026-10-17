import UIKit

/// Session photos, saved as JPEGs in Documents/photos.
enum PhotoStore {
    private static var folder: URL {
        let url = URL.documentsDirectory.appending(path: "photos")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Downscales and saves the picked image, returning its file name.
    static func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(1, 1600 / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try jpeg.write(to: folder.appending(path: name))
            return name
        } catch {
            return nil
        }
    }

    static func image(_ name: String) -> UIImage? {
        UIImage(contentsOfFile: folder.appending(path: name).path())
    }

    static func delete(_ name: String) {
        try? FileManager.default.removeItem(at: folder.appending(path: name))
    }
}
