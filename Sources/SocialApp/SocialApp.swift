import SwiftUI

@main
struct SocialPrototypeApp: App {
    @State private var store = FeedStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    enum Tab { case home, post, messages, profile }

    @State private var tab: Tab = .home

    var body: some View {
        TabView(selection: $tab) {
            FeedView()
                .tabBarStyle()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

            ComingSoonView(
                title: "Create post",
                icon: "plus.square",
                message: "Pick a photo, add a caption and location, then share it with your friends."
            )
            .tabBarStyle()
            .tabItem { Label("Post", systemImage: "plus.square") }
            .tag(Tab.post)

            ComingSoonView(
                title: "Messages",
                icon: "bubble.left",
                message: "Chat with friends during the open hours, while everyone else is online too."
            )
            .tabBarStyle()
            .tabItem { Label("Messages", systemImage: "bubble.left") }
            .tag(Tab.messages)

            ProfileView()
                .tabBarStyle()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(Tab.profile)
        }
        .tint(Theme.green)
    }
}

private extension View {
    func tabBarStyle() -> some View {
        self
            .toolbarBackground(Theme.background, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}
