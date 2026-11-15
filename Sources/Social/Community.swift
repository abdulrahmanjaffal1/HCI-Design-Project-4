import Foundation
import BreakClock

struct Person: Codable, Identifiable {
    var id: String { handle }
    var bio: String?
    var name: String
    var handle: String
    var email: String
    var avatar = 0
    var photo: Data?
    var zone = TimeZone.current.identifier
}
struct Reply: Codable, Identifiable {
    var id = UUID()
    let name: String
    var author: String?
    var parent: UUID?
    var likedBy: Set<String>?
    let text: String
    var liked = false
}
struct Moment: Codable, Identifiable {
    var id = UUID()
    let name: String
    var handle: String
    let photo: String
    var caption: String
    var place: String
    var likedBy: Set<String>?
    var savedBy: Set<String>?
    var likes = 0
    var liked = false
    var saved = false
    var mine = false
    var replies: [Reply] = []
}

struct DirectMessage: Codable, Identifiable {
    var id = UUID()
    let sender: String
    let recipient: String
    let text: String
}

struct Archive: Codable {
    var people: [Person] = []
    var posts = samples
    var messages: [DirectMessage] = []
    var remembered: Set<String> = []
    var active: String?
    var follows: [String: Set<String>] = [:]
    var poll = UniversalPoll()
    var demoStart: Date?
    var person: Person? { people.first { $0.handle == active } }
    var signedIn: Bool { person != nil }
    var vote: Int? { active.flatMap { poll.ballots[$0] } }
    func account(_ login: String) -> Person? {
        let id = login.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return people.first { $0.handle == id || $0.email == id }
    }
    func conversation(_ peer: String) -> [DirectMessage] {
        messages.filter { ($0.sender == active && $0.recipient == peer) || ($0.sender == peer && $0.recipient == active) }
    }
    mutating func activate(_ person: Person, demo: Bool) {
        remembered.insert(person.handle)
        active = person.handle
        if demo && demoStart == nil { demoStart = Date() }
    }
    static let names = ["Maya Chen","Sam Rivera","Nina Park","Jordan Lee","Alex Shah","Iris Kim","Taylor Kim","Casey Brooks","Robin Ellis"]
    static func seeded(avoiding reserved: Person? = nil) -> Archive {
        var d = Archive()
        for (i,name) in names.enumerated() {
            var h = "user" + String(i + 1)
            if reserved?.handle == h { h += "_demo" }
            var email = h + "@social.example"
            if reserved?.email == email { email = h + "+demo@social.example" }
            d.people.append(Person(name: name, handle: h, email: email, avatar: i % 6, zone: "UTC"))
        }
        d.posts = d.posts.map { post in
            var p = post
            p.handle = d.people.first { $0.name == p.name }!.handle
            p.likes = 0
            p.likedBy = Set(d.people.filter { $0.handle != p.handle }.prefix(3).map(\.handle))
            for i in p.replies.indices { p.replies[i].author = d.people.first { $0.name == p.replies[i].name }?.handle }
            return p
        }
        d.messages = [DirectMessage(sender: d.people[1].handle, recipient: d.people[0].handle, text: "Want to walk the river path later?")]
        return d
    }
    static let samples: [Moment] = [
        ("Maya Chen","mayachen","park","Took the long way home today. Worth it.","Campus trail"),
        ("Sam Rivera","samrivera","pottery","Morning studio light is the best light.","Ceramics studio"),
        ("Nina Park","ninapark","coffee","A small pause on a busy day.","Union café"),
        ("Jordan Lee","jordanlee","picnic","Lunch outside with the usual crew.","North lawn"),
        ("Alex Shah","alexshah","coast","The water was still when we arrived.","Coast path"),
        ("Iris Kim","iriskim","flowers","Something blooming on every corner.","Market square"),
        ("Maya Chen","mayachen","coast","One more mile before heading home.","Cliff walk"),
        ("Sam Rivera","samrivera","coffee","Coffee before glazing day.","Studio café"),
        ("Nina Park","ninapark","flowers","Saturday market finds.","Flower market"),
        ("Jordan Lee","jordanlee","park","Shade all the way back to campus.","Creek trail")
    ].enumerated().map { i, row in
        Moment(name: row.0, handle: row.1, photo: row.2, caption: row.3, place: row.4,
               likes: i == 0 ? 42 : 8+i, replies: i == 0 ? [
                Reply(name: "Nina Park", text: "Beautiful light. A good reminder to slow down."),
                Reply(name: "Jordan Lee", text: "The green and the light feel so calm.")] : [])
    }
}

func toggling(_ handle: String, in existing: Set<String>?) -> Set<String> {
    var result = existing ?? []
    if result.contains(handle) { result.remove(handle) } else { result.insert(handle) }
    return result
}
