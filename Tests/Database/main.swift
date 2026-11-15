// Run with bin/test-database. Uses the same Swift models and SQLite adapter as the app.
import Foundation
import BreakClock

func expect(_ condition: Bool, _ description: String) {
    precondition(condition, description)
}
let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: dir) }
let file = dir.appendingPathComponent("community.sqlite")
let db = try CommunityDB(file)
var d = Archive.seeded()
expect(d.people.count == 9 && d.posts.allSatisfy { d.account($0.handle) != nil }, "Seed authors must have profiles")
expect(d.account(" USER1 ")?.name == "Maya Chen", "Login lookup")
let new = Person(name: "Tester", handle: "tester", email: "test@example.org")
d.people.append(new)
d.activate(new, demo: false)
d.posts[0].savedBy = [new.handle]
let comment = Reply(name: new.name, author: new.handle, text: "What time?")
d.posts[0].replies.append(comment)
d.activate(d.people[0], demo: false)
d.posts[0].replies.append(Reply(name: "Maya Chen", author: "user1", parent: comment.id, text: "At noon"))
d.messages.append(DirectMessage(sender: "user1", recipient: new.handle, text: "See you there"))
d.poll.ballots["user1"] = 2
try db.save(d)
let reopened = try CommunityDB(file)
var saved = try reopened.load()!
expect(saved.person?.handle == "user1" && saved.vote == 2, "Session and ballot persist")
expect(saved.posts[0].replies.last?.parent == comment.id, "Reply retains parent")
expect(saved.posts[0].savedBy == ["tester"], "Saves stay scoped")
saved.activate(new, demo: false)
expect(saved.vote == nil && saved.conversation("user1").count == 1, "Recipient sees DM and own ballot")
saved.activate(saved.people[2], demo: false)
expect(saved.conversation("user1").isEmpty, "Third account cannot read the conversation")
saved.people.append(saved.people[0])
do { try reopened.save(saved); fatalError("Duplicate handle must fail") } catch {}
let restored = try reopened.load()!
expect(restored.people.count == 10 && restored.person?.handle == "user1", "Failed transaction rolled back")
let oldFile = dir.appendingPathComponent("old.json")
let old = """
{"person":{"name":"First Tester","handle":"user1","email":"user2@social.example","avatar":0,"zone":"UTC"},
 "signedIn":true,"vote":1,"posts":[],"threads":[{"name":"Maya Chen","notes":[{"text":"Hi","outgoing":true}]}]}
"""
try Data(old.utf8).write(to: oldFile)
let migrated = try CommunityDB.importLegacy(at: oldFile)
try reopened.save(migrated)
expect(migrated.person?.name == "First Tester" && migrated.vote == 1, "Legacy account and vote survive")
expect(migrated.conversation("user1_demo").count == 1, "Legacy thread maps to real account")
print("Database checks passed: profiles, session, replies, saves, inbox isolation, ballots, rollback and migration.")
