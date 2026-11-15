import SwiftUI

struct Profile: View {
    @EnvironmentObject var store: Store
    @State var saved = false
    @State var switching = false
    var body: some View {
        ScrollView {
            if let person = store.data.person {
                VStack(alignment: .leading, spacing: 16) {
                    Portrait(person: person)
                    Text(person.name).font(.largeTitle.bold())
                    Text("@" + person.handle).foregroundColor(.secondary)
                    Text(person.bio ?? "")
                    NavigationLink("Edit profile", destination: EditProfile(person: person))
                    NavigationLink("Explore people", destination: People())
                    Button("Switch account") { switching = true }
                        .confirmationDialog("Switch account", isPresented: $switching, titleVisibility: .visible) {
                            ForEach(store.data.people.filter { $0.handle != person.handle && store.data.remembered.contains($0.handle) }) { account in
                                Button("@" + account.handle) { store.change { $0.activate(account, demo: StudyConfiguration.acceleratedBreak) } }
                            }
                            Button("Log in to another account") { store.change { $0.active = nil } }
                            Button("Cancel", role: .cancel) {}
                        }
                    NavigationLink(destination: BreakMenu()) { Label("Break", systemImage: "clock").frame(maxWidth: .infinity).padding().background(sage).cornerRadius(14) }
                    Picker("Collection", selection: $saved) { Text("My posts").tag(false); Text("Saved").tag(true) }.pickerStyle(.segmented)
                    let posts = store.data.posts.filter { saved ? ($0.savedBy?.contains(person.handle) == true) : $0.handle == person.handle }
                    if posts.isEmpty { Text(saved ? "Posts you save appear here." : "Your first shared post will appear here.").foregroundColor(.secondary) }
                    ForEach(posts) { PostCard(post: $0) }
                    Button("Log out") { store.change { $0.remembered.remove(person.handle); $0.active = nil } }.padding(.vertical)
                }.padding(20)
            }
        }.background(paper)
    }
}

struct BreakMenu: View {
    @EnvironmentObject var store: Store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionLabel(text: "Community schedule")
                Text("Break menu").font(.largeTitle.bold())
                Label("Daily break", systemImage: "clock").font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    Text(hours[store.slot]).font(.title.bold())
                    Text(store.localSlot(store.slot))
                }.padding().frame(maxWidth: .infinity, alignment: .leading).background(sage).cornerRadius(16)
                Text("Everyone pauses at the same instant. Each account has one standing vote. The leading slot becomes active at midnight UTC.")
                if let vote = store.data.vote { Label("Your proposal: " + hours[vote], systemImage: "checkmark.circle") }
                NavigationLink(destination: Vote()) { Text(store.data.vote == nil ? "Vote on break hours" : "Change your vote") }.buttonStyle(Primary())
            }.padding(20)
        }.background(paper)
    }
}
struct Vote: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State var choice: Int?
    @State var confirmed = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Vote for break timeframe").font(.largeTitle.bold())
                Text("Choose one universal daily break. Times below use UTC.")
                ForEach(hours.indices, id: \.self) { i in
                    Button { choice = i } label: {
                        HStack { Image(systemName: choice == i ? "checkmark.circle.fill" : "circle")
                            Text(hours[i]).font(.headline); Spacer(); Text("\(store.data.poll.count(i)) votes").font(.caption); if i == store.slot { Text("Current").font(.caption) }
                        }.padding().background(choice == i ? sage : Color.white).cornerRadius(12)
                    }
                }
                Text("Your latest choice counts once. Ties keep the current slot if it is tied, then favor the earlier slot.").font(.footnote)
                Button("Submit vote") {
                    if let choice = choice, store.change({ if let me = $0.active { $0.poll.ballots[me] = choice } }) { confirmed = true }
                }.buttonStyle(Primary()).disabled(choice == nil)
            }.padding(20)
        }.background(paper).onAppear { choice = store.data.vote }
            .alert("Vote sent", isPresented: $confirmed) {
                Button("OK") { dismiss() }
            } message: { Text("Your preferred break hour has been recorded.") }
    }
}
