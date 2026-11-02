import Foundation
import Observation

struct UserProfile: Identifiable, Hashable {
    let id: String      // the username, without "@"
    let name: String

    var handle: String { "@" + id }

    var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map(String.init)
            .joined()
            .uppercased()
    }
}

struct Comment: Identifiable {
    let id = UUID()
    let author: UserProfile
    let text: String
    let timeAgo: String
    var likes: Int = 0
    var isLiked = false
}

struct Post: Identifiable {
    enum Layout { case hero, strip }

    let id = UUID()
    let author: UserProfile
    let photos: [String]
    let caption: String
    let timeAgo: String
    var layout: Layout = .strip
    var likes: Int
    var isLiked = false
    var isSaved = false
    var comments: [Comment]
}

/// Holds the app's state. Everything is hardcoded sample data for the prototype.
@Observable
final class FeedStore {
    var posts: [Post] = SampleData.posts
    let currentUser = SampleData.me

    /// Prototype: the open hour starts when the app launches and lasts 60 minutes.
    var openUntil = Date().addingTimeInterval(60 * 60)
    /// True when the open hour is over and the app is locked.
    var isClosed = false

    /// Prototype only: start a fresh open hour so the demo can continue.
    func reopenForDemo() {
        openUntil = Date().addingTimeInterval(60 * 60)
        isClosed = false
    }

    func post(_ id: Post.ID) -> Post? {
        posts.first { $0.id == id }
    }

    func toggleLike(_ id: Post.ID) {
        guard let i = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[i].isLiked.toggle()
        posts[i].likes += posts[i].isLiked ? 1 : -1
    }

    func toggleSave(_ id: Post.ID) {
        guard let i = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[i].isSaved.toggle()
    }

    func toggleCommentLike(postID: Post.ID, commentID: Comment.ID) {
        guard let p = posts.firstIndex(where: { $0.id == postID }),
              let c = posts[p].comments.firstIndex(where: { $0.id == commentID }) else { return }
        posts[p].comments[c].isLiked.toggle()
        posts[p].comments[c].likes += posts[p].comments[c].isLiked ? 1 : -1
    }

    @discardableResult
    func addComment(_ text: String, to id: Post.ID) -> Comment.ID? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = posts.firstIndex(where: { $0.id == id }) else { return nil }
        let comment = Comment(author: currentUser, text: trimmed, timeAgo: "now")
        posts[i].comments.append(comment)
        return comment.id
    }
}

// MARK: - Hardcoded data

enum SampleData {
    static let me     = UserProfile(id: "abdulrh", name: "Abdul Rahman")
    static let maya   = UserProfile(id: "mayachen", name: "Maya Chen")
    static let sam    = UserProfile(id: "samrivera", name: "Sam Rivera")
    static let alex   = UserProfile(id: "alexmorgan", name: "Alex Morgan")
    static let nina   = UserProfile(id: "ninapark", name: "Nina Park")
    static let jordan = UserProfile(id: "jordanlee", name: "Jordan Lee")

    /// The one hour a day the app is open, shared by everyone in the region.
    static let openHour = "2:00–3:00 PM"
    static let openHourStart = 14   // 2 PM, 24-hour clock

    static let posts: [Post] = [
        Post(
            author: maya,
            photos: ["park", "coast"],
            caption: "Took the long way home today. Worth it.",
            timeAgo: "2h",
            layout: .hero,
            likes: 42,
            comments: [
                Comment(author: nina, text: "Beautiful light. A good reminder to slow down.", timeAgo: "1h", likes: 3),
                Comment(author: jordan, text: "Beautiful shot. The green and the light feel so calm.", timeAgo: "45m", likes: 1),
                Comment(author: sam, text: "Which park is this? Adding it to my list.", timeAgo: "30m"),
            ]
        ),
        Post(
            author: sam,
            photos: ["pottery", "picnic", "coast"],
            caption: "Morning studio light is the best light.",
            timeAgo: "5h",
            likes: 18,
            comments: [
                Comment(author: alex, text: "Those bowls look amazing.", timeAgo: "4h", likes: 2),
                Comment(author: maya, text: "Save one for me!", timeAgo: "3h"),
            ]
        ),
        Post(
            author: alex,
            photos: ["coffee", "park", "flowers"],
            caption: "Coffee, park light, and a few quiet moments before the day fills up.",
            timeAgo: "7h",
            likes: 24,
            comments: [
                Comment(author: jordan, text: "This is my kind of morning.", timeAgo: "6h", likes: 1),
            ]
        ),
        Post(
            author: nina,
            photos: ["picnic", "coast", "flowers"],
            caption: "A few favorite moments from the week: friends, coast, and a quiet corner with flowers.",
            timeAgo: "9h",
            likes: 31,
            comments: [
                Comment(author: sam, text: "That picnic was the best.", timeAgo: "8h", likes: 4),
                Comment(author: maya, text: "Love the flowers.", timeAgo: "7h"),
            ]
        ),
        Post(
            author: jordan,
            photos: ["coast", "flowers", "coffee"],
            caption: "Coast walk, a quiet corner, and a coffee pause before the afternoon.",
            timeAgo: "11h",
            likes: 27,
            comments: [
                Comment(author: nina, text: "Where is this coast?", timeAgo: "10h"),
            ]
        ),
    ]
}
