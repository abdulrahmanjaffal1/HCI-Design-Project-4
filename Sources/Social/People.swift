import SwiftUI
import PhotosUI

struct People: View {
    @EnvironmentObject var store: Store
    @State var query = ""
    var body: some View {
        List(store.data.people.filter { query.isEmpty || ($0.name + " " + $0.handle).localizedCaseInsensitiveContains(query) }) { p in
            NavigationLink(destination: PublicProfile(handle: p.handle)) {
                HStack { Portrait(person: p, size: 42); VStack(alignment: .leading) { Text(p.name).bold(); Text("@" + p.handle).font(.caption) } }
            }
        }.navigationTitle("People").searchable(text: $query)
    }
}
struct PublicProfile: View {
    @EnvironmentObject var store: Store
    let handle: String
    var body: some View {
        ScrollView {
            if let p = store.data.account(handle), let me = store.data.active {
                VStack(alignment: .leading, spacing: 14) {
                    Portrait(person: p)
                    Text(p.name).font(.largeTitle.bold())
                    Text("@" + p.handle)
                    if let bio = p.bio { Text(bio) }
                    let posts = store.data.posts.filter { $0.handle == handle }
                    Text("\(posts.count) posts · \(store.data.follows.values.filter { $0.contains(handle) }.count) followers · \(store.data.follows[handle]?.count ?? 0) following")
                        .font(.subheadline)
                    if handle != me {
                        HStack {
                            Button(store.data.follows[me]?.contains(handle) == true ? "Unfollow" : "Follow") {
                                store.change { $0.follows[me] = toggling(handle, in: $0.follows[me]) }
                            }.buttonStyle(.borderedProminent)
                            NavigationLink("Message", destination: Conversation(peer: handle)).buttonStyle(.bordered)
                        }
                    }
                    if posts.isEmpty { Text("No posts yet.").foregroundColor(.secondary) }
                    ForEach(posts) { PostCard(post: $0) }
                }.padding()
            }
        }.background(paper).navigationBarTitleDisplayMode(.inline)
    }
}
struct EditProfile: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State var person: Person
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoError = ""
    var body: some View {
        Form {
            Section("Display name") { TextField("Name", text: $person.name) }
            Section("Bio") { TextField("About you", text: Binding(get: { person.bio ?? "" }, set: { person.bio = $0 }), axis: .vertical) }
            Section("Profile picture") {
                Portrait(person: person)
                PhotosPicker("Change photo", selection: $selectedPhoto, matching: .images)
                if selectedPhoto != nil { ProgressView("Loading photo…") }
                if person.photo != nil {
                    Button("Remove photo", role: .destructive) {
                        selectedPhoto = nil
                        person.photo = nil
                        photoError = ""
                    }
                }
                if person.photo == nil {
                    Picker("Avatar color", selection: $person.avatar) {
                        ForEach(colors.indices, id: \.self) { Text(colors[$0]).tag($0) }
                    }
                }
                if !photoError.isEmpty { Text(photoError).foregroundColor(.red) }
            }
            Button("Save changes") {
                person.name = trim(person.name)
                if store.change({ d in
                    if let i = d.people.firstIndex(where: { $0.handle == person.handle }) { d.people[i] = person }
                }) { dismiss() }
            }.disabled(selectedPhoto != nil || !(1...40).contains(trim(person.name).count) || (person.bio?.count ?? 0) > 150)
        }.navigationTitle("Edit profile")
            .task(id: selectedPhoto) {
                guard let item = selectedPhoto else { return }
                photoError = ""
                do {
                    guard let bytes = try await item.loadTransferable(type: Data.self),
                          let original = UIImage(data: bytes),
                          let thumbnail = await original.byPreparingThumbnail(ofSize: CGSize(width: 384, height: 384)),
                          let jpeg = thumbnail.jpegData(compressionQuality: 0.82)
                    else { throw CocoaError(.fileReadCorruptFile) }
                    guard !Task.isCancelled, selectedPhoto == item else { return }
                    person.photo = jpeg
                } catch {
                    guard !Task.isCancelled, selectedPhoto == item else { return }
                    photoError = "Couldn’t load that photo. Try another image."
                }
                selectedPhoto = nil
            }
    }
}
