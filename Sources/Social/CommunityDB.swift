import Foundation
import SQLite3
import BreakClock

final class CommunityDB {
    private var db: OpaquePointer?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private struct Settings: Codable {
        var remembered: Set<String>?
        var active: String?
        var follows: [String: Set<String>]
        var poll: UniversalPoll
    }
    private struct Failure: LocalizedError {
        var errorDescription: String?
    }
    private var failure: Failure { Failure(errorDescription: String(cString: sqlite3_errmsg(db))) }
    init(_ url: URL) throws {
        guard sqlite3_open(url.path, &db) == SQLITE_OK else { throw failure }
        try exec("""
            CREATE TABLE IF NOT EXISTS profiles(handle TEXT PRIMARY KEY, email TEXT COLLATE NOCASE UNIQUE, body BLOB NOT NULL);
            CREATE TABLE IF NOT EXISTS posts(body BLOB NOT NULL);
            CREATE TABLE IF NOT EXISTS messages(body BLOB NOT NULL);
            CREATE TABLE IF NOT EXISTS settings(body BLOB NOT NULL);
            """)
    }
    deinit { sqlite3_close(db) }
    private func exec(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw failure }
    }
    private func read<T: Decodable>(_ table: String, as: T.Type) throws -> [T] {
        var q: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT body FROM " + table + " ORDER BY rowid", -1, &q, nil) == SQLITE_OK else { throw failure }
        defer { sqlite3_finalize(q) }
        var result: [T] = []
        var status = sqlite3_step(q)
        while status == SQLITE_ROW {
            guard let pointer = sqlite3_column_blob(q, 0) else { throw failure }
            result.append(try decoder.decode(T.self, from: Data(bytes: pointer, count: Int(sqlite3_column_bytes(q, 0)))))
            status = sqlite3_step(q)
        }
        guard status == SQLITE_DONE else { throw failure }
        return result
    }
    func load() throws -> Archive? {
        guard let s = try read("settings", as: Settings.self).first else { return nil }
        var d = Archive()
        d.people = try read("profiles", as: Person.self)
        d.posts = try read("posts", as: Moment.self)
        d.messages = try read("messages", as: DirectMessage.self)
        d.remembered = s.remembered ?? Set([s.active].compactMap { $0 })
        d.active = s.active; d.follows = s.follows; d.poll = s.poll
        return d
    }
    private func insert<T: Encodable>(_ value: T, into table: String, person: Person? = nil) throws {
        var q: OpaquePointer?
        let columns = person == nil ? "(body) VALUES (?)" : "(body,handle,email) VALUES (?,?,?)"
        guard sqlite3_prepare_v2(db, "INSERT INTO " + table + columns, -1, &q, nil) == SQLITE_OK else { throw failure }
        defer { sqlite3_finalize(q) }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let bytes = try encoder.encode(value)
        let bound = bytes.withUnsafeBytes { sqlite3_bind_blob(q, 1, $0.baseAddress, Int32($0.count), transient) }
        guard bound == SQLITE_OK else { throw failure }
        if let person = person {
            guard sqlite3_bind_text(q, 2, person.handle, -1, transient) == SQLITE_OK,
                  sqlite3_bind_text(q, 3, person.email, -1, transient) == SQLITE_OK else { throw failure }
        }
        guard sqlite3_step(q) == SQLITE_DONE else { throw failure }
    }
    func save(_ d: Archive) throws {
        try exec("BEGIN IMMEDIATE")
        do {
            try exec("DELETE FROM profiles; DELETE FROM posts; DELETE FROM messages; DELETE FROM settings;")
            for p in d.people { try insert(p, into: "profiles", person: p) }
            for p in d.posts { try insert(p, into: "posts") }
            for m in d.messages { try insert(m, into: "messages") }
            try insert(Settings(remembered: d.remembered, active: d.active, follows: d.follows, poll: d.poll), into: "settings")
            try exec("COMMIT")
        } catch { try? exec("ROLLBACK"); throw error }
    }
    static func importLegacy(at url: URL) throws -> Archive {
        struct Legacy: Decodable {
            struct Thread: Decodable {
                struct Note: Decodable { let text: String; let outgoing: Bool }
                let name: String
                let notes: [Note]
            }
            let person: Person?
            let signedIn: Bool
            let vote: Int?
                let posts: [Moment]
            let threads: [Thread]
        }
        guard FileManager.default.fileExists(atPath: url.path) else { return .seeded() }
        let old = try JSONDecoder().decode(Legacy.self, from: Data(contentsOf: url))
        var d = Archive.seeded(avoiding: old.person)
        guard let owner = old.person else { return d }
        d.people.append(owner)
        d.active = old.signedIn ? owner.handle : nil
        if old.signedIn { d.remembered.insert(owner.handle) }
        if let vote = old.vote, UniversalPoll.slots.indices.contains(vote) { d.poll.ballots[owner.handle] = vote }
        d.posts = old.posts.map { post in
            var p = post
            p.handle = p.mine ? owner.handle : d.people.first { $0.name == p.name }?.handle ?? p.handle
            p.likedBy = p.liked ? [owner.handle] : []
            p.savedBy = p.saved ? [owner.handle] : []
            for i in p.replies.indices {
                let name = p.replies[i].name
                p.replies[i].author = name == owner.name ? owner.handle : d.people.first { $0.name == name }?.handle
                p.replies[i].likedBy = p.replies[i].liked ? [owner.handle] : []
            }
            return p
        }
        d.messages = old.threads.flatMap { thread -> [DirectMessage] in
            guard let peer = d.people.first(where: { $0.name == thread.name }) else { return [] }
            return thread.notes.map { DirectMessage(sender: $0.outgoing ? owner.handle : peer.handle,
                                                    recipient: $0.outgoing ? peer.handle : owner.handle, text: $0.text) }
        }
        return d
    }
}
