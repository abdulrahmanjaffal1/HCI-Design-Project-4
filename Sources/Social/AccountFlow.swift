import SwiftUI
import PhotosUI

struct AccountFlow: View {
    @EnvironmentObject var store: Store
    @State private var step = 0
    @State private var person = Person(name: "", handle: "", email: "")
    @State private var password = ""
    @State private var reveal = false
    @State private var code = ""
    @State private var expected = ""
    @State private var message = ""
    @State private var search = ""
    @State private var photo: PhotosPickerItem?
    @FocusState private var field: Int?
    let titles = ["Create your account", "Verification", "Choose profile picture", "Choose time zone", "Review your profile setup"]
    @State private var returning = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(text: returning ? "Your account" : "Profile setup · Step \(step + 1) of 5")
                Text(returning ? "Welcome back" : titles[step]).font(.largeTitle.bold())
                if returning || step == 0 { credentials }
                else if step == 1 {
                    Text("Enter the six-digit code for \(person.email).")
                    Text("Study inbox · \(expected)").font(.headline).padding().background(sage).cornerRadius(12)
                    TextField("Verification code", text: $code).keyboardType(.numberPad).textContentType(.oneTimeCode)
                    Button("Verify") {
                        if trim(code) == expected { advance() } else { message = "That code didn’t match. Check your study inbox above." }
                    }.buttonStyle(Primary())
                } else if step == 2 {
                    Portrait(person: person).frame(maxWidth: .infinity)
                    Text("Choose a color").font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                        ForEach(colors.indices, id: \.self) { i in
                            Button {
                                person.avatar = i; person.photo = nil; photo = nil
                            } label: {
                                VStack {
                                    Image(systemName: "person.crop.circle.fill").font(.largeTitle).foregroundColor(swatches[i])
                                    Text(colors[i]).font(.caption)
                                    Image(systemName: person.photo == nil && person.avatar == i ? "checkmark.circle.fill" : "circle")
                                }.padding(4)
                            }
                        }
                    }
                    PhotosPicker("Choose from Photos", selection: $photo, matching: .images)
                    Button("Use avatar", action: advance).buttonStyle(Primary())
                } else if step == 3 {
                    Text("Use this time zone to display the universal open hour on your profile.")
                    TextField("Search city or time zone", text: $search)
                    Text(person.zone.replacingOccurrences(of: "_", with: " ")).font(.headline)
                    ForEach(zones, id: \.self) { zone in
                        Button { person.zone = zone } label: {
                            HStack { Text(zone.replacingOccurrences(of: "_", with: " ")); Spacer()
                                Image(systemName: person.zone == zone ? "checkmark.circle.fill" : "circle") }
                        }.padding(12).background(person.zone == zone ? sage : Color.white).cornerRadius(12)
                    }
                    Button("Use time zone", action: advance).buttonStyle(Primary())
                } else {
                    Portrait(person: person)
                    Text(person.name).font(.title2.bold())
                    Text("@\(person.handle) · \(person.email)")
                    Button("Edit profile picture") { step = 2 }
                    Text(person.zone)
                    Button("Edit time zone") { step = 3 }
                    Button("Finish setup") {
                        guard store.data.account(person.handle) == nil && store.data.account(person.email) == nil else { message = "Username or email already in use."; return }
                        guard Credential.save(password, account: person.email) else { message = "Couldn’t save your local login. Try again."; return }
                        store.change(protected: false) {
                            $0.people.append(person); $0.activate(person)
                        }
                    }.buttonStyle(Primary())
                }
                if !message.isEmpty { Text(message).foregroundColor(.red).accessibilityLabel("Error. " + message) }
                if step > 0 && !returning { Button("Back") { step -= 1; message = "" } }
            }.textFieldStyle(.roundedBorder).padding(22)
        }.task(id: photo) {
            guard let item = photo else { return }
            do {
                guard let bytes = try await item.loadTransferable(type: Data.self),
                      let im = UIImage(data: bytes) else { throw CocoaError(.fileReadCorruptFile) }
                let thumb = await im.byPreparingThumbnail(ofSize: CGSize(width: 240, height: 240))
                try Task.checkCancellation()
                person.photo = (thumb ?? im).jpegData(compressionQuality: 0.75)
            } catch { if !Task.isCancelled { message = "Couldn’t open this photo. Choose another image." } }
        }
    }
    var zones: [String] {
        let favorites = [person.zone, "America/New_York","America/Chicago","America/Denver","America/Los_Angeles","Europe/London"]
        if trim(search).isEmpty { return favorites.reduce(into: []) { if !$0.contains($1) { $0.append($1) } } }
        return TimeZone.knownTimeZoneIdentifiers.filter { $0.replacingOccurrences(of: "_", with: " ").localizedCaseInsensitiveContains(search) }
    }
    @ViewBuilder var credentials: some View {
        if !returning {
            Text("Share moments, follow creators, and keep your feed simple.").foregroundColor(.secondary)
            TextField("Name (1–40 characters)", text: $person.name).focused($field, equals: 0).submitLabel(.next).onSubmit { field = 1 }
            TextField("Username (3–20 letters, numbers or _)", text: $person.handle).textInputAutocapitalization(.never)
                .autocorrectionDisabled().focused($field, equals: 1).submitLabel(.next).onSubmit { field = 2 }
        }
        TextField(returning ? "Username or email" : "Email", text: $person.email).textInputAutocapitalization(.never).autocorrectionDisabled()
            .keyboardType(.emailAddress).focused($field, equals: 2).submitLabel(.next).onSubmit { field = 3 }
        HStack {
            Group {
                if reveal { TextField("Password", text: $password) } else { SecureField("Password", text: $password) }
            }.textInputAutocapitalization(.never).autocorrectionDisabled().focused($field, equals: 3).onSubmit { submit() }
            Button { reveal.toggle() } label: { Image(systemName: reveal ? "eye.slash" : "eye").padding(8) }
                .accessibilityLabel(reveal ? "Hide password" : "Show password")
        }
        if !returning { Text("Use 8–64 characters for your password.").font(.footnote) }
        Button(returning ? "Log in" : "Create account", action: submit).buttonStyle(Primary())
        Button(returning ? "Create a new account" : "Already have an account? Log in") {
            returning.toggle(); password = ""; person = Person(name: "", handle: "", email: ""); message = ""; field = nil
        }
        if returning {
            DisclosureGroup("Study accounts") {
                ForEach(Array(store.data.people.prefix(Archive.names.count).enumerated()), id: \.offset) { i, p in
                    Button { person.email = p.handle; password = "password" + String(i+1) } label: {
                        HStack { Text(p.name); Spacer(); Text(p.handle).foregroundColor(.secondary) }
                    }.padding(.vertical, 4)
                }
            }
        }
    }
    func advance() { message = ""; field = nil; step += 1 }
    func submit() {
        person.email = trim(person.email).lowercased()
        if returning {
            if let account = store.data.account(person.email), Credential.matches(password, account: account.email) {
                store.change(protected: false) { $0.activate(account) }
            } else { message = "Check your email and password." }
            return
        }
        person.name = trim(person.name); person.handle = trim(person.handle).lowercased()
        guard (1...40).contains(person.name.count),
              person.handle.range(of: "^[a-z0-9_]{3,20}$", options: .regularExpression) != nil,
              person.email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil,
              (8...64).contains(password.count) else {
            message = "Check the name and username lengths, enter a valid email, and use an 8–64 character password."; return
        }
        guard store.data.account(person.handle) == nil && store.data.account(person.email) == nil else { message = "Username or email already in use."; return }
        expected = String(Int.random(in: 100000...999999)); code = ""; advance()
    }
}
