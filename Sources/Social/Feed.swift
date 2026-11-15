import SwiftUI

struct Feed: View {
    @EnvironmentObject var store: Store
    @State var query = ""
    @State var followingOnly = false
    var filtered: [Moment] {
        store.data.posts.filter { post in
            let followed = store.data.follows[store.data.active ?? ""]?.contains(post.handle) == true
            let fields = [store.data.account(post.handle)?.name ?? post.name, post.handle, post.caption, post.place]
            return (!followingOnly || followed) && (query.isEmpty || fields.contains { $0.localizedCaseInsensitiveContains(query) })
        }
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                NavigationLink(destination: BreakMenu()) {
                    HStack {
                        Image(systemName: "clock")
                        VStack(alignment: .leading) {
                            Text("Break window").font(.headline)
                            Text(StudyConfiguration.acceleratedBreak ? "Timed classroom demonstration" : hours[store.slot]).font(.caption)
                        }; Spacer(); Image(systemName: "chevron.right")
                    }.padding().background(sage).cornerRadius(14)
                }
                HStack { Image(systemName: "magnifyingglass"); TextField("Search posts or people", text: $query).autocorrectionDisabled()
                    if !query.isEmpty { Button("Clear") { query = "" } }
                }.padding(12).background(.white).cornerRadius(12)
                NavigationLink("Explore people", destination: People())
                Picker("Feed", selection: $followingOnly) { Text("Everyone").tag(false); Text("Following").tag(true) }.pickerStyle(.segmented)
                if filtered.isEmpty { Text(followingOnly ? "Follow someone to see their posts here." : "No posts match your search.").padding() }
                ForEach(filtered) { post in PostCard(post: post) }
            }.padding(.horizontal, 16).padding(.vertical, 8)
        }.background(paper).navigationBarTitleDisplayMode(.inline)
    }
}

struct Identity: View {
    @EnvironmentObject var store: Store
    let post: Moment
    var body: some View {
        NavigationLink(destination: PublicProfile(handle: post.handle)) { HStack {
            if let author = store.data.account(post.handle) {
                Portrait(person: author, size: 38)
            } else {
                Image(systemName: "person.crop.circle").frame(width: 38, height: 38)
            }
            VStack(alignment: .leading) { Text(store.data.account(post.handle)?.name ?? post.name).bold(); Text("@" + post.handle).font(.caption).foregroundColor(.secondary) }
            Spacer()
        } }
    }
}
struct PostCard: View {
    @EnvironmentObject var store: Store
    let post: Moment
    @State private var confirmDelete = false
    var me: String { store.data.active ?? "" }
    var liked: Bool { post.likedBy?.contains(me) == true }
    var saved: Bool { post.savedBy?.contains(me) == true }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Identity(post: post)
                if post.handle == me {
                    Menu {
                        NavigationLink("Edit post", destination: EditPost(post: post))
                        Button("Delete post", role: .destructive) { confirmDelete = true }
                    } label: { Image(systemName: "ellipsis").padding(8) }.accessibilityLabel("Post options")
                }
            }
            NavigationLink(destination: PostDetail(id: post.id)) { Photo(key: post.photo).frame(height: 222).cornerRadius(14) }
                .accessibilityLabel("Open post by " + post.name)
            HStack(spacing: 18) {
                Button { store.update(post.id) { $0.likedBy = toggling(me, in: $0.likedBy) } } label: {
                    Label("\(post.likes + (post.likedBy?.count ?? 0))", systemImage: liked ? "heart.fill" : "heart")
                }.accessibilityLabel(liked ? "Unlike post" : "Like post")
                NavigationLink(destination: PostDetail(id: post.id)) { Label("\(post.replies.count)", systemImage: "bubble.left") }
                Button { store.update(post.id) { $0.savedBy = toggling(me, in: $0.savedBy) } } label: {
                    Label(saved ? "Saved" : "Save", systemImage: saved ? "bookmark.fill" : "bookmark")
                }
            }.font(.subheadline).frame(minHeight: 44)
            Text("@" + post.handle).bold() + Text("  " + post.caption)
            Text(post.place).font(.caption).foregroundColor(.secondary)
            NavigationLink("View comments", destination: PostDetail(id: post.id)).font(.footnote)
        }.padding(14).background(.white).cornerRadius(20)
            .confirmationDialog("Delete this post and its comments?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete post", role: .destructive) { store.change { d in d.posts.removeAll { $0.id == post.id && $0.handle == me } } }
                Button("Cancel", role: .cancel) {}
            }
    }
}
struct PostDetail: View {
    @EnvironmentObject var store: Store
    let id: UUID
    @State var draft = ""
    @State var replyingTo: Reply?
    var body: some View {
        if let post = store.data.posts.first(where: { $0.id == id }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Identity(post: post)
                    Photo(key: post.photo).frame(height: 280).cornerRadius(16)
                    Text(post.caption).font(.headline)
                    Text(post.place).font(.subheadline).foregroundColor(.secondary)
                    SectionLabel(text: "Comments · \(post.replies.count)")
                    ForEach(post.replies.filter { $0.parent == nil }) { root in
                        comment(root)
                        ForEach(post.replies.filter { $0.parent == root.id }) { child in
                            comment(child).padding(.leading, 20)
                        }
                    }
                    if post.replies.isEmpty { Text("Start the conversation.").foregroundColor(.secondary) }
                }.padding()
            }.background(paper).navigationTitle("Post").navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom) {
                    VStack(alignment: .leading) {
                        if let target = replyingTo {
                            HStack { Text("Replying to " + (store.data.account(target.author ?? "")?.name ?? target.name)).font(.caption); Spacer()
                                Button("Cancel") { replyingTo = nil }
                            }
                        }
                        HStack {
                        TextField(replyingTo == nil ? "Add a comment" : "Write a reply", text: $draft, axis: .vertical).lineLimit(1...3)
                        Button("Post") {
                            let text = trim(draft)
                            let name = store.data.person?.name ?? "You"
                            store.update(id) { $0.replies.append(Reply(name: name, author: store.data.active, parent: replyingTo.map { $0.parent ?? $0.id }, text: text)) }; draft = ""; replyingTo = nil
                        }.disabled(trim(draft).isEmpty)
                        }
                    }.padding().background(.regularMaterial)
                }
        }
    }

    func comment(_ reply: Reply) -> some View {
        let me = store.data.active ?? ""
        let liked = reply.likedBy?.contains(me) == true
        return VStack(alignment: .leading, spacing: 6) {
            if let author = reply.author {
                NavigationLink(store.data.account(author)?.name ?? reply.name, destination: PublicProfile(handle: author)).bold()
            } else { Text(reply.name).bold() }
            Text(reply.text)
            HStack {
                Button("Reply") { replyingTo = reply }
                Spacer()
                Button {
                    store.update(id) { p in
                        if let i = p.replies.firstIndex(where: { $0.id == reply.id }) {
                            p.replies[i].likedBy = toggling(me, in: p.replies[i].likedBy)
                        }
                    }
                } label: { Label(String(reply.likedBy?.count ?? 0), systemImage: liked ? "heart.fill" : "heart") }
            }.font(.subheadline)
        }.padding().background(.white).cornerRadius(12)
    }
}

struct EditPost: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State var post: Moment
    var body: some View {
        Form {
            Section("Caption") { TextField("Caption", text: $post.caption, axis: .vertical) }
            Section("Location") { TextField("Location", text: $post.place) }
            Button("Save changes") {
                guard post.handle == store.data.active else { return }
                store.update(post.id) { $0.caption = trim(post.caption); $0.place = trim(post.place) }
                dismiss()
            }.disabled(trim(post.caption).isEmpty)
        }.navigationTitle("Edit post")
    }
}
