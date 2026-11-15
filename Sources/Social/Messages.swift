import SwiftUI

struct Messages: View {
    @EnvironmentObject var store: Store
    @State var search = ""
    var body: some View {
        List {
            ForEach(store.data.people.filter {
                $0.handle != store.data.active && (search.isEmpty || ($0.name + $0.handle).localizedCaseInsensitiveContains(search))
            }) { p in
                NavigationLink(destination: Conversation(peer: p.handle)) {
                    HStack { Portrait(person: p, size: 38)
                        VStack(alignment: .leading) { Text(p.name).bold()
                            Text(store.data.conversation(p.handle).last?.text ?? "Start a conversation").font(.subheadline).lineLimit(1)
                        }
                    }
                }
            }
        }.navigationTitle("Messages").searchable(text: $search, prompt: "Find a person")
    }
}
struct Conversation: View {
    @EnvironmentObject var store: Store
    let peer: String
    @State var draft = ""
    var body: some View {
        let notes = store.data.conversation(peer)
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    if notes.isEmpty { Text("Say hello to " + (store.data.account(peer)?.name ?? peer)).foregroundColor(.secondary) }
                    ForEach(notes) { n in
                        let outgoing = n.sender == store.data.active
                        HStack {
                            if outgoing { Spacer(minLength: 35) }
                            Text(n.text).padding(12).background(outgoing ? sage : Color.white).cornerRadius(14)
                            if !outgoing { Spacer(minLength: 35) }
                        }.id(n.id)
                    }
                }.padding()
            }.onChange(of: notes.count) { _ in if let last = notes.last { proxy.scrollTo(last.id) } }
        }.background(paper).navigationTitle(store.data.account(peer)?.name ?? peer).navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("Write a message", text: $draft, axis: .vertical)
                    Button("Send") {
                        guard let me = store.data.active else { return }
                        if store.change({ $0.messages.append(DirectMessage(sender: me, recipient: peer, text: trim(draft))) }) { draft = "" }
                    }.disabled(trim(draft).isEmpty)
                }.padding().background(.regularMaterial)
            }
    }
}
