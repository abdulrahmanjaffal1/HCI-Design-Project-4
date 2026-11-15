import UIKit

enum LocalPhoto {
    private static var folder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("PostPhotos")
    }
    static func url(_ key: String) -> URL? {
        if UUID(uuidString: key) != nil { return folder.appendingPathComponent(key + ".jpg") }
        return Bundle.module.url(forResource: key, withExtension: "jpg", subdirectory: "Photos")
    }
    static func save(_ bytes: Data) async throws -> String {
        guard let image = UIImage(data: bytes),
              let small = await image.byPreparingThumbnail(ofSize: CGSize(width: 1440, height: 1440)),
              let jpeg = small.jpegData(compressionQuality: 0.85) else { throw CocoaError(.fileReadCorruptFile) }
        let key = UUID().uuidString
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try jpeg.write(to: folder.appendingPathComponent(key + ".jpg"), options: [.atomic, .completeFileProtection])
        return key
    }
}
