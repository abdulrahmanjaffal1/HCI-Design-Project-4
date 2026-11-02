import SwiftUI

struct ProfileView: View {
    @Environment(FeedStore.self) private var store
    @State private var showingSaved = false
    @State private var showOpenHourInfo = false

    /// The current user's own posts (hardcoded for the prototype).
    private let myPhotos = ["park", "coffee", "pottery", "picnic", "coast", "flowers",
                            "coffee", "park", "coast", "flowers", "picnic", "pottery"]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            AppHeader()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    profileHeader

                    HStack(spacing: 10) {
                        PillButton(title: "Edit profile", systemImage: "pencil", isActive: true) {}
                        PillButton(title: "Open hour", systemImage: "clock", isActive: true) { showOpenHourInfo = true }
                    }

                    HStack(spacing: 10) {
                        PillButton(title: "Posts", systemImage: "square.grid.2x2", isActive: !showingSaved) { showingSaved = false }
                        PillButton(title: "Saved", systemImage: "bookmark", isActive: showingSaved) { showingSaved = true }
                    }

                    grid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showOpenHourInfo) {
            OpenHourInfoSheet()
                .presentationDetents([.medium])
        }
    }

    private var profileHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            AvatarView(size: 88)
            VStack(alignment: .leading, spacing: 6) {
                Text(store.currentUser.name)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text(store.currentUser.handle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.tint, in: Capsule())
                Text("Finding little moments outside.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
                HStack(spacing: 18) {
                    stat("\(myPhotos.count)", "posts")
                    stat("248", "followers")
                    stat("186", "following")
                }
            }
        }
        .padding(.top, 8)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
            Text(label).font(.caption2).foregroundStyle(Theme.secondary)
        }
    }

    @ViewBuilder
    private var grid: some View {
        let photos = showingSaved
            ? store.posts.filter(\.isSaved).compactMap(\.photos.first)
            : myPhotos

        if photos.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "bookmark")
                    .font(.title2)
                    .foregroundStyle(Theme.green)
                Text("Nothing saved yet")
                    .font(.subheadline.weight(.semibold))
                Text("Tap Save on a post in your feed to keep it here.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(photos.enumerated()), id: \.offset) { _, name in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(PhotoView(name: name))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

struct PillButton: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isActive ? Theme.green : Theme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isActive ? Theme.tint : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct OpenHourInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SHARED OPEN HOUR")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.green)
            Text("Everyone's online at the same time")
                .font(.title3.weight(.semibold))
            Text("Social only opens for one hour a day, at the same time for everyone in your region. The rest of the day it's closed, so you never miss anything, and you get to talk with friends in real time.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondary)
            HStack {
                Image(systemName: "clock")
                Text("Every day, \(SampleData.openHour)")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Theme.green)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text("Voting on your region's open hour is coming in the next build.")
                .font(.footnote)
                .foregroundStyle(Theme.secondary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.green, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Theme.text)
        .padding(24)
        .background(Theme.background)
    }
}
