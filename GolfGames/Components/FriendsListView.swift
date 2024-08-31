//
//  FriendsListView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/18/24.
//

import SwiftUI

struct FriendsListView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @Binding var selectedFriends: [Golfer]
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddFriendSheet = false
    @State private var friendToEdit: Golfer?
    @State private var localSelectedFriends: Set<String> = Set()
    var onDone: () -> Void
    var allowSelection: Bool

    var body: some View {
        NavigationView {
            VStack {
                friendsList
                doneButton
            }
            .navigationTitle("Friends List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
        }
        .sheet(isPresented: $showingAddFriendSheet) {
            CreateFriendView(viewModel: viewModel, friendToEdit: $friendToEdit)
        }
        .onChange(of: friendToEdit) { _ in
            showingAddFriendSheet = friendToEdit != nil
        }
        .onAppear(perform: loadFriends)
    }

    private var friendsList: some View {
        List {
            ForEach(viewModel.friends) { friend in
                FriendRow(
                    friend: friend,
                    isSelected: localSelectedFriends.contains(friend.id),
                    allowSelection: allowSelection,
                    toggleSelection: { toggleFriendSelection(friend) }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if allowSelection {
                        toggleFriendSelection(friend)
                    }
                }
                .contextMenu {
                    Button(action: {
                        friendToEdit = friend
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
            .onDelete(perform: deleteFriends)

            Text("Tip: Long press on a friend to edit them. Update their handicaps to their current handicap index before each round.")
                .italic()
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .listRowBackground(Color.clear)
                .padding(.vertical, 8)
        }
    }

    private var addButton: some View {
        Button(action: {
            friendToEdit = nil
            showingAddFriendSheet = true
        }) {
            Text("Add New")
            Image(systemName: "plus")
        }
    }

    private var doneButton: some View {
        Button(action: {
            if allowSelection {
                selectedFriends = viewModel.friends.filter { localSelectedFriends.contains($0.id) }
            }
            onDone()
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Done")
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                .foregroundColor(.white)
                .background(Color(.systemGreen))
                .cornerRadius(10)
        }
        .padding()
    }

    private func loadFriends() {
        if let user = authViewModel.currentUser {
            viewModel.setUserId(user.id)
            viewModel.fetchFriends()
        }
        localSelectedFriends = Set(selectedFriends.map { $0.id })
    }

    private func toggleFriendSelection(_ friend: Golfer) {
        if allowSelection {
            if localSelectedFriends.contains(friend.id) {
                localSelectedFriends.remove(friend.id)
            } else {
                localSelectedFriends.insert(friend.id)
            }
        }
    }

    private func deleteFriends(at offsets: IndexSet) {
        for index in offsets {
            let friend = viewModel.friends[index]
            viewModel.removeFriend(friend)
            localSelectedFriends.remove(friend.id)
        }
    }
}

struct FriendRow: View {
    let friend: Golfer
    let isSelected: Bool
    let allowSelection: Bool
    let toggleSelection: () -> Void

    var body: some View {
        HStack {
            Text(friend.lastNameFirstFormat())
            Spacer()
            HStack(spacing: 10) {
                Text(formatHandicap(friend.handicap))
                    .foregroundColor(.secondary)
                if allowSelection {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .gray)
                        .animation(.easeInOut, value: isSelected)
                }
            }
            .frame(width: 70, alignment: .trailing)
        }
    }

    private func formatHandicap(_ handicap: Float) -> String {
        if handicap < 0 {
            return String(format: "+%.1f", abs(handicap))
        } else {
            return String(format: "%.1f", handicap)
        }
    }
}

struct FriendsListView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsListView(viewModel: FriendsViewModel(userId: "mockUserId"), selectedFriends: .constant([]), onDone: {}, allowSelection: true)
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
    }
}
