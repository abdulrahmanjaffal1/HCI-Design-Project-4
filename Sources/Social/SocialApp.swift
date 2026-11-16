import SwiftUI
import BreakClock

@main struct SocialApp: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup { Gate().environmentObject(store).tint(forest).preferredColorScheme(.light) }
    }
}

struct Primary: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(14)
            .background(forest.opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.45))
            .foregroundColor(.white).cornerRadius(14)
    }
}
struct Brand: View {
    var body: some View {
        HStack { Image(systemName: "circle.dashed").foregroundColor(forest); Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "One Hour").font(.headline); Spacer() }
            .padding(.horizontal, 20).padding(.vertical, 10).background(paper)
    }
}
struct Photo: View {
    let key: String
    var body: some View {
        GeometryReader { geo in
            if let path = LocalPhoto.url(key),
               let picture = UIImage(contentsOfFile: path.path) {
                Image(uiImage: picture).resizable().scaledToFill().frame(width: geo.size.width, height: geo.size.height).clipped()
            }
        }.accessibilityLabel(Text(UUID(uuidString: key) == nil ? key.capitalized : "Uploaded photo"))
    }
}
struct Portrait: View {
    let person: Person
    var size: CGFloat = 72
    var body: some View {
        Group {
            if let data = person.photo, let im = UIImage(data: data) {
                Image(uiImage: im).resizable().scaledToFill()
            } else {
                Image(systemName: "person.fill").resizable().scaledToFit().padding(size/4)
                    .foregroundColor(swatches[person.avatar]).background(swatches[person.avatar].opacity(0.14))
            }
        }.frame(width: size, height: size).clipShape(Circle())
    }
}
struct SectionLabel: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.caption.weight(.semibold)).tracking(1.2).foregroundColor(forest) }
}
struct Gate: View {
    @EnvironmentObject var store: Store
    @Environment(\.scenePhase) var phase
    @State private var now = Date()
    let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        let locked = store.data.signedIn && store.isLocked(at: now)
        ZStack(alignment: .trailing) {
            VStack(spacing: 0) {
                Brand()
                if store.data.signedIn { SocialTabs().id(store.data.active) }
                else { AccountFlow() }
            }
            .disabled(locked)
            .accessibilityHidden(locked)

            if locked {
                if StudyConfiguration.peerTesting {
                    Button { store.manualLock = false } label: { lockScreen }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Showcase lockout. Dismiss and return to the app.")
                } else { lockScreen }
            } else if StudyConfiguration.peerTesting && store.data.signedIn {
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                    store.manualLock = true
                } label: {
                    Image(systemName: "lock.fill").font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white).frame(width: 24, height: 24)
                        .background(forest).clipShape(Circle())
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Show showcase lockout")
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(paper)
            .ignoresSafeArea(.keyboard)
            .overlay { if phase != .active { paper.ignoresSafeArea().accessibilityHidden(true) } }
            .onReceive(tick) { now = $0 }
            .onChange(of: phase) { _ in now = Date() }
            .alert("Couldn’t save this change", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
    }
    var lockScreen: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock").font(.largeTitle).padding(30).background(sage).clipShape(Circle())
            Text("Time for a pause.").font(.largeTitle.bold())
            SectionLabel(text: "Community open hour")
            Text(hours[store.slot]).font(.title2.bold())
            Text(store.localSlot(store.slot))
            if StudyConfiguration.peerTesting {
                Text("Tap anywhere to return").foregroundColor(.secondary)
            }
        }.multilineTextAlignment(.center).padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(paper.ignoresSafeArea()).contentShape(Rectangle())
    }
}
struct SocialTabs: View {
    @EnvironmentObject var store: Store
    @State var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { Feed() }.tabItem { Label("Home", systemImage: "house") }.tag(0)
            NavigationStack { Composer(account: store.data.active ?? "") { tab = 0 } }.tabItem { Label("Post", systemImage: "plus.square") }.tag(1)
            NavigationStack { Profile() }.tabItem { Label("Profile", systemImage: "person") }.tag(2)
            NavigationStack { Messages() }.tabItem { Label("Messages", systemImage: "bubble.left.and.bubble.right") }.tag(3)
        }
    }
}
