import SwiftUI
import UIKit
import Security
import BreakClock

let forest = Color(red: 53/255, green: 95/255, blue: 72/255)
let paper = Color(red: 247/255, green: 246/255, blue: 240/255)
let sage = Color(red: 233/255, green: 238/255, blue: 223/255)
let gallery = ["park", "coffee", "pottery", "picnic", "coast", "flowers"]
let colors = ["Green", "Clay", "Sky", "Lilac", "Sand", "Stone"]
let swatches: [Color] = [forest, .brown, .blue, .purple, .orange, .gray]
let hours = ["14:00–15:00 UTC", "15:00–16:00 UTC", "17:00–18:00 UTC"]
let trim: (String) -> String = { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

@MainActor final class Store: ObservableObject {
    @Published private(set) var data = Archive()
    @Published var error: String?
    private var db: CommunityDB?
    init() {
        do {
            let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let database = try CommunityDB(dir.appendingPathComponent("community.sqlite"))
            if let existing = try database.load() { data = existing }
            else {
                let legacy = dir.appendingPathComponent("social-v1.json")
                let initial = try CommunityDB.importLegacy(at: legacy)
                for (i, person) in initial.people.prefix(Archive.names.count).enumerated() {
                    guard Credential.save("password" + String(i+1), account: person.email) else { throw CocoaError(.fileWriteUnknown) }
                }
                try database.save(initial)
                data = initial
                if let old = initial.people.dropFirst(Archive.names.count).first {
                    let defaults = UserDefaults.standard
                    for field in ["photo","caption","place"] {
                        let key = "compose." + field
                        if let value = defaults.string(forKey: key) { defaults.set(value, forKey: old.handle + "." + key) }
                    }
                }
            }
            db = database
        } catch { self.error = error.localizedDescription }
    }
    @Published var manualLock = false
    func isLocked(at date: Date) -> Bool {
        let slot = data.poll.slot(at: date)
        let clock = BreakClock(zone: TimeZone(secondsFromGMT: 0)!, hour: UniversalPoll.slots[slot])
        return clock.isLocked(at: date, peerTesting: StudyConfiguration.peerTesting, manualLock: manualLock)
    }
    var slot: Int { data.poll.slot(at: Date()) }
    func localSlot(_ index: Int) -> String {
        let start = Date(timeIntervalSince1970: Double(UniversalPoll.day(Date()) * 86400 + UniversalPoll.slots[index] * 3600))
        let format = DateFormatter()
        format.timeStyle = .short
        format.timeZone = TimeZone(identifier: data.person?.zone ?? "") ?? .current
        return format.string(from: start) + "–" + format.string(from: start.addingTimeInterval(3600)) + " · " + format.timeZone.identifier
    }
    @discardableResult func change(protected: Bool = true, _ edit: (inout Archive) -> Void) -> Bool {
        guard let db = db else { error = "Database unavailable. Reopen One Hour and try again."; return false }
        guard !protected || (data.signedIn && !isLocked(at: Date())) else { return false }
        var next = data
        next.poll.advance(to: Date())
        edit(&next)
        do { try db.save(next); data = next; return true }
        catch { self.error = error.localizedDescription; return false }
    }
    func update(_ id: UUID, _ edit: (inout Moment) -> Void) {
        change { archive in
            if let i = archive.posts.firstIndex(where: { $0.id == id }) { edit(&archive.posts[i]) }
        }
    }
}

enum Credential {
    static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "Social.local-login",
         kSecAttrAccount as String: account]
    }
    static func save(_ password: String, account: String) -> Bool {
        var q = query(account)
        let value = Data(password.utf8)
        q[kSecValueData as String] = value
        q[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let result = SecItemAdd(q as CFDictionary, nil)
        if result == errSecDuplicateItem {
            return SecItemUpdate(query(account) as CFDictionary, [kSecValueData as String: value] as CFDictionary) == errSecSuccess
        }
        return result == errSecSuccess
    }
    static func matches(_ password: String, account: String) -> Bool {
        var q = query(account)
        q[kSecReturnData as String] = true
        var item: CFTypeRef?
        return SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess && (item as? Data) == Data(password.utf8)
    }
}
