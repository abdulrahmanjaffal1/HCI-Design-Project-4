import SwiftUI
import PhotosUI

struct Composer: View {
    @EnvironmentObject var store: Store
    let didPublish: () -> Void
    @AppStorage("compose.photo") private var selected = ""
    @AppStorage("compose.caption") private var caption = ""
    @AppStorage("compose.place") private var place = ""
    init(account: String, didPublish: @escaping () -> Void) {
        self.didPublish = didPublish
        _selected = AppStorage(wrappedValue: "", account + ".compose.photo")
        _caption = AppStorage(wrappedValue: "", account + ".compose.caption")
        _place = AppStorage(wrappedValue: "", account + ".compose.place")
    }
    @State private var picking = false
    @State private var libraryItem: PhotosPickerItem?
    @State private var candidate = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(text: "New post")
                Text("Create post").font(.largeTitle.bold())
                if !selected.isEmpty { Photo(key: selected).frame(height: 220).cornerRadius(16) }
                Button {
                    candidate = selected; picking = true
                } label: {
                    Label(selected.isEmpty ? "Select photo" : "Change photo", systemImage: "photo.on.rectangle")
                        .padding().frame(maxWidth: .infinity).background(sage).cornerRadius(14)
                }
                SectionLabel(text: "Caption")
                TextField("What would you like to share?", text: $caption, axis: .vertical)
                    .lineLimit(3...8).padding().background(.white).cornerRadius(12)
                SectionLabel(text: "Location · optional")
                TextField("Add a café or neighborhood", text: $place).textFieldStyle(.roundedBorder)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack { ForEach(["Union café","Campus trail","North lawn","Ceramics studio"], id: \.self) { p in
                        Button(p) { place = p }.buttonStyle(.bordered)
                    } }
                }
                Button { publish() } label: { Label("Share post", systemImage: "paperplane") }
                    .buttonStyle(Primary()).disabled(selected.isEmpty || trim(caption).isEmpty)
                Text("Choose a photo and add a caption to share.").font(.footnote).foregroundColor(.secondary)
            }.padding(20)
        }.background(paper).navigationDestination(isPresented: $picking) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Camera roll").font(.largeTitle.bold())
                    Text("Choose one photo for your post.")
                    PhotosPicker("Choose from iPhone Photos", selection: $libraryItem, matching: .images)
                    if !candidate.isEmpty && !gallery.contains(candidate) { Photo(key: candidate).frame(height: 140).cornerRadius(12) }
                    SectionLabel(text: "Study photos")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(gallery, id: \.self) { key in
                            Button { candidate = key } label: {
                                Photo(key: key).aspectRatio(1, contentMode: .fit).cornerRadius(12)
                                    .overlay(alignment: .topTrailing) {
                                        if candidate == key { Image(systemName: "checkmark.circle.fill").foregroundStyle(.white, forest).padding(6) }
                                    }
                            }.accessibilityLabel(key.capitalized + (candidate == key ? ", selected" : ""))
                        }
                    }
                    Button("Next") { selected = candidate; picking = false }.buttonStyle(Primary()).disabled(candidate.isEmpty)
                }.padding(20)
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(paper)
                .task(id: libraryItem) {
                    guard let item = libraryItem else { return }
                    do {
                        guard let bytes = try await item.loadTransferable(type: Data.self) else { throw CocoaError(.fileReadUnknown) }
                        let key = try await LocalPhoto.save(bytes)
                        try Task.checkCancellation()
                        candidate = key
                    } catch { if !Task.isCancelled { store.error = "Couldn’t load this photo. Try another image." } }
                }
        }
    }
    func publish() {
        guard let p = store.data.person else { return }
        let post = Moment(name: p.name, handle: p.handle, photo: selected, caption: trim(caption), place: trim(place), mine: true)
        if store.change({ $0.posts.insert(post, at: 0) }) {
            selected = ""; caption = ""; place = ""; didPublish()
        }
    }
}
