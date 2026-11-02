import SwiftUI
import UIKit

/// Colors taken from the team's Figma design.
enum Theme {
    static let background = Color(hex: 0xF5F4EE)  // cream page background
    static let card       = Color.white
    static let border     = Color(hex: 0xE4E2DA)
    static let green      = Color(hex: 0x375F4A)  // primary buttons, accents
    static let tint       = Color(hex: 0xE6EDDF)  // light green chips and avatars
    static let text       = Color(hex: 0x1F2A24)
    static let secondary  = Color(hex: 0x6E736B)
    static let heart      = Color(hex: 0xB5654A)  // liked heart (clay)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Photos bundled with the app

enum PhotoLibrary {
    private static var cache: [String: UIImage] = [:]

    /// Finds the SwiftPM resource bundle without using `Bundle.module`,
    /// which would crash the app if the bundle were ever missing.
    private static let resourceBundle: Bundle? = {
        guard let root = Bundle.main.resourceURL else { return nil }
        if let bundle = Bundle(url: root.appendingPathComponent("SocialApp_SocialApp.bundle")) {
            return bundle
        }
        let items = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        for url in items where url.pathExtension == "bundle" {
            if let bundle = Bundle(url: url), bundle.url(forResource: "park", withExtension: "jpg") != nil {
                return bundle
            }
        }
        return nil
    }()

    static func image(named name: String) -> UIImage? {
        if let cached = cache[name] { return cached }
        for bundle in [resourceBundle, Bundle.main].compactMap({ $0 }) {
            if let url = bundle.url(forResource: name, withExtension: "jpg"),
               let image = UIImage(contentsOfFile: url.path) {
                cache[name] = image
                return image
            }
        }
        return nil
    }
}

/// Shows a bundled photo, or a soft placeholder if the file is missing.
struct PhotoView: View {
    let name: String

    var body: some View {
        if let image = PhotoLibrary.image(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Theme.tint
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(Theme.green.opacity(0.6))
            }
        }
    }
}

/// A photo cropped to a fixed shape with rounded corners.
struct RoundedPhoto: View {
    let name: String
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = 14

    var body: some View {
        Color.clear
            .frame(width: width, height: height)
            .overlay(PhotoView(name: name))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .contentShape(Rectangle())
    }
}

// MARK: - Shared components

struct AppHeader<Trailing: View>: View {
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .strokeBorder(Theme.text.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                .frame(width: 22, height: 22)
            Text("Social")
                .font(.system(size: 18))
                .foregroundStyle(Theme.text)
            Spacer()
            trailing
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

extension AppHeader where Trailing == EmptyView {
    init() {
        self.init(trailing: { EmptyView() })
    }
}

struct AvatarView: View {
    var size: CGFloat = 36
    var initials: String? = nil

    var body: some View {
        ZStack {
            Circle().fill(Theme.tint)
            if let initials {
                Text(initials)
                    .font(.system(size: size * 0.34, weight: .semibold))
                    .foregroundStyle(Theme.green)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(Theme.green)
                    .offset(y: size * 0.1)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.border)
            )
    }
}

extension View {
    func card(cornerRadius: CGFloat = 18) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }
}
