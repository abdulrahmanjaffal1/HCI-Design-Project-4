import SwiftUI

/// Opened by tapping a post in the feed.
struct PostDetailView: View {
    @Environment(FeedStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let postID: Post.ID

    @State private var page = 0
    @State private var isFollowing = false
    @State private var draft = ""
    @FocusState private var commentFocused: Bool

    var body: some View {
        Group {
            if let post = store.post(postID) {
                content(post)
            } else {
                Text("This post is no longer available.")
                    .foregroundStyle(Theme.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func content(_ post: Post) -> some View {
        VStack(spacing: 0) {
            topBar(post)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header(post)
                        carousel(post)
                        actions(post)
                        captionBlock(post)
                        commentsBlock(post)
                    }
                    .padding(14)
                    .card()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: post.comments.count) {
                    if let last = post.comments.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            commentBar(post)
        }
    }

    // MARK: Pieces

    private func topBar(_ post: Post) -> some View {
        HStack(spacing: 10) {
            CircleIconButton(systemImage: "chevron.left", accessibility: "Back") { dismiss() }
            Spacer()
            ShareLink(item: "\(post.author.name) on Social: \(post.caption)") {
                CircleIcon(systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("Share")
            CircleIconButton(systemImage: "ellipsis", accessibility: "More") {}
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func header(_ post: Post) -> some View {
        HStack(spacing: 10) {
            AvatarView(size: 38, initials: post.author.initials)
            VStack(alignment: .leading, spacing: 1) {
                Text(post.author.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                Text(post.author.handle)
                    .font(.caption)
                    .foregroundStyle(Theme.secondary)
            }
            Spacer()
            Button {
                isFollowing.toggle()
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .foregroundStyle(isFollowing ? Theme.green : .white)
                    .background(isFollowing ? Theme.tint : Theme.green, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func carousel(_ post: Post) -> some View {
        VStack(spacing: 8) {
            TabView(selection: $page) {
                ForEach(post.photos.indices, id: \.self) { i in
                    RoundedPhoto(name: post.photos[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 300)

            if post.photos.count > 1 {
                HStack(spacing: 6) {
                    ForEach(post.photos.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Theme.green : Theme.border)
                            .frame(width: i == page ? 16 : 6, height: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: page)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func actions(_ post: Post) -> some View {
        HStack(spacing: 10) {
            SquareIconButton(
                systemImage: post.isLiked ? "heart.fill" : "heart",
                color: post.isLiked ? Theme.heart : Theme.green,
                accessibility: post.isLiked ? "Unlike" : "Like"
            ) { store.toggleLike(post.id) }

            SquareIconButton(systemImage: "bubble.left", color: Theme.green, accessibility: "Comment") {
                commentFocused = true
            }

            SquareIconButton(
                systemImage: post.isSaved ? "bookmark.fill" : "bookmark",
                color: Theme.green,
                accessibility: post.isSaved ? "Unsave" : "Save"
            ) { store.toggleSave(post.id) }

            Spacer()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: post.isLiked)
    }

    private func captionBlock(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(post.likes) likes  ·  \(post.comments.count) comments")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.text)
            Text("\(Text(post.author.name).fontWeight(.semibold)) \(post.caption)")
                .font(.subheadline)
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(post.timeAgo) ago")
                .font(.caption)
                .foregroundStyle(Theme.secondary)
        }
    }

    private func commentsBlock(_ post: Post) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("COMMENTS")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.secondary)

            if post.comments.isEmpty {
                Text("No comments yet. Be the first.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
            }

            ForEach(post.comments) { comment in
                CommentRow(
                    comment: comment,
                    onLike: { store.toggleCommentLike(postID: post.id, commentID: comment.id) },
                    onReply: {
                        draft = "\(comment.author.handle) "
                        commentFocused = true
                    }
                )
                .id(comment.id)
            }
        }
    }

    private func commentBar(_ post: Post) -> some View {
        let canSend = !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return HStack(spacing: 10) {
            AvatarView(size: 32, initials: store.currentUser.initials)
            TextField("Add a comment…", text: $draft)
                .font(.subheadline)
                .focused($commentFocused)
                .submitLabel(.send)
                .onSubmit { send(post) }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Theme.card, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.border))
            Button("Post") { send(post) }
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .foregroundStyle(.white)
                .background(Theme.green.opacity(canSend ? 1 : 0.4), in: Capsule())
                .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background)
        .overlay(alignment: .top) { Divider() }
    }

    private func send(_ post: Post) {
        if store.addComment(draft, to: post.id) != nil {
            draft = ""
            commentFocused = false
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let onLike: () -> Void
    let onReply: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(size: 30, initials: comment.author.initials)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(comment.author.name)
                        .font(.footnote.weight(.semibold))
                    Text("\(comment.author.handle) · \(comment.timeAgo)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondary)
                }
                Text(comment.text)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Reply", action: onReply)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.tint, in: Capsule())
                    .buttonStyle(.plain)
            }
            .foregroundStyle(Theme.text)
            Spacer(minLength: 0)
            // Liking comments was a usability issue found in DP3 testing.
            Button(action: onLike) {
                VStack(spacing: 2) {
                    Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                        .font(.footnote)
                    if comment.likes > 0 {
                        Text("\(comment.likes)").font(.caption2)
                    }
                }
                .foregroundStyle(comment.isLiked ? Theme.heart : Theme.secondary)
                .frame(minWidth: 28, minHeight: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(comment.isLiked ? "Unlike comment" : "Like comment")
        }
    }
}

// MARK: - Small buttons

struct CircleIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.text)
            .frame(width: 38, height: 38)
            .background(Theme.card, in: Circle())
            .overlay(Circle().strokeBorder(Theme.border))
    }
}

struct CircleIconButton: View {
    let systemImage: String
    let accessibility: String
    let action: () -> Void

    var body: some View {
        Button(action: action) { CircleIcon(systemImage: systemImage) }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibility)
    }
}

struct SquareIconButton: View {
    let systemImage: String
    let color: Color
    let accessibility: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(Theme.tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
    }
}
