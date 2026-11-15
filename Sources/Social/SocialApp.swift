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
        HStack { Image(systemName: "circle.dashed").foregroundColor(forest); Text("Social").font(.headline); Spacer() }
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
        VStack(spacing: 0) {
            Brand()
            if !store.data.signedIn { AccountFlow() }
            else if let interval = store.clock.active(at: max(now, Date())) {
                VStack(spacing: 18) {
                    Spacer()
                    Image(systemName: "lock").font(.largeTitle).padding(30).background(sage).clipShape(Circle())
                    Text("Time for a pause.").font(.largeTitle.bold())
                    Text("Your feed, posts and profile reopen at " + time(interval.end) + ".").multilineTextAlignment(.center)
                    VStack(spacing: 8) {
                        SectionLabel(text: "Current break")
                        Text(time(interval.start) + " – " + time(interval.end)).font(.title2.bold())
                        Text("Reopens in " + remaining(interval.end)).monospacedDigit()
                    }.padding().frame(maxWidth: .infinity).background(.white).cornerRadius(18)
                    Text("Read a chapter or take a short walk. Your feed can wait.").foregroundColor(.secondary)
                    Spacer()
                }.padding(24)
            } else { SocialTabs().id(store.data.active) }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(paper)
            .overlay { if phase != .active { paper.ignoresSafeArea().accessibilityHidden(true) } }
            .onReceive(tick) { now = $0 }
            .onChange(of: phase) { _ in now = Date() }
            .alert("Couldn’t save this change", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                Button("OK") { store.error = nil }
            } message: { Text(store.error ?? "") }
    }
    func time(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; f.timeZone = TimeZone(identifier: store.data.person?.zone ?? "") ?? .current
        return f.string(from: date)
    }
    func remaining(_ end: Date) -> String {
        let seconds = max(0, Int(ceil(end.timeIntervalSince(now))))
        return String(format: "%d:%02d", seconds/60, seconds%60)
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
