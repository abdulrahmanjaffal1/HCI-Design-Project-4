import SwiftUI

/// Simple task: scroll through posts made by other users, tap one to open it.
struct FeedView: View {
    @Environment(FeedStore.self) private var store
    @State private var path: [Post.ID] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                AppHeader {
                    Text("FEED")
                        .font(.caption)
                        .tracking(0.5)
                        .foregroundStyle(Theme.secondary)
                }

                ScrollView {
                    LazyVStack(spacing: 14) {
                        // Prototype: tapping the banner ends the open hour early to show the lock screen.
                        OpenHourBanner(closesAt: store.openUntil) { store.isClosed = true }

                        ForEach(store.posts) { post in
                            PostCard(post: post) { path.append(post.id) }
                        }

                        CaughtUpFooter()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Post.ID.self) { id in
                PostDetailView(postID: id)
            }
        }
    }
}

/// Shows that the app is open right now and how long until it closes.
struct OpenHourBanner: View {
    let closesAt: Date
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 18))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open hour")
                        .font(.footnote.weight(.semibold))
                    Text("Today, \(SampleData.openHour) · everyone's online")
                        .font(.caption)
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeLeft(at: context.date))
                            .font(.footnote.weight(.semibold).monospacedDigit())
                        Text("left")
                            .font(.caption2)
                            .foregroundStyle(Theme.secondary)
                    }
                }
            }
            .foregroundStyle(Theme.green)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func timeLeft(at date: Date) -> String {
        let seconds = max(0, Int(closesAt.timeIntervalSince(date)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct PostCard: View {
    let post: Post
    let open: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarView(size: 36)
                VStack(alignment: .leading, spacing: 1) {
                    Text(post.author.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.text)
                    Text(post.author.handle)
                        .font(.caption)
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(Theme.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: open)

            photos
                .onTapGesture(perform: open)

            FeedActionRow(post: post)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(Text(post.author.handle).fontWeight(.semibold)) \(post.caption)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(post.timeAgo) ago")
                    .font(.caption)
                    .foregroundStyle(Theme.secondary)
                if !post.comments.isEmpty {
                    Text("View all \(post.comments.count) comments")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: open)
        }
        .padding(14)
        .card()
    }

    @ViewBuilder
    private var photos: some View {
        if post.layout == .hero, let first = post.photos.first {
            RoundedPhoto(name: first, height: 220)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(post.photos.enumerated()), id: \.offset) { _, name in
                        RoundedPhoto(name: name, width: 112, height: 112)
                    }
                }
            }
        }
    }
}

struct FeedActionRow: View {
    @Environment(FeedStore.self) private var store
    let post: Post

    var body: some View {
        HStack(spacing: 18) {
            Button {
                store.toggleLike(post.id)
            } label: {
                Label("\(post.likes)", systemImage: post.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(post.isLiked ? Theme.heart : Theme.text)
            }

            Label("\(post.comments.count)", systemImage: "bubble.left")
                .foregroundStyle(Theme.text)

            Button {
                store.toggleSave(post.id)
            } label: {
                Label(post.isSaved ? "Saved" : "Save", systemImage: post.isSaved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(Theme.green)
            }

            Spacer()
        }
        .font(.subheadline.weight(.medium))
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: post.isLiked)
    }
}

/// The feed ends instead of scrolling forever.
struct CaughtUpFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 28))
                .foregroundStyle(Theme.green)
            Text("You're all caught up")
                .font(.headline)
                .foregroundStyle(Theme.text)
            Text("That's everything from the people you follow. Go enjoy your day.")
                .font(.footnote)
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
    }
}
