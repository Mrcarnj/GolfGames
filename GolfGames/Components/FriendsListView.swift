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
    var onDone: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.friends) { friend in
                        HStack {
                            Text(friend.fullName)
                            Spacer()
                            HStack(spacing: 10) {
                                Text(formatHandicap(friend.handicap))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 70, alignment: .trailing)
                        }
                        .contentShape(Rectangle())
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
                
                Button(action: {
                    onDone()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Friends List")
            .navigationBarItems(
                trailing: Button(action: {
                    friendToEdit = nil
                    showingAddFriendSheet.toggle()
                }) {
                    Image(systemName: "plus")
                }
            )
        }
        .sheet(isPresented: $showingAddFriendSheet) {
            CreateFriendView(viewModel: viewModel, friendToEdit: $friendToEdit)
        }
        .onChange(of: friendToEdit) { _ in
            showingAddFriendSheet = friendToEdit != nil
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                viewModel.setUserId(user.id)
                viewModel.fetchFriends()
            }
        }
    }
    
    private func toggleFriendSelection(_ friend: Golfer) {
        if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
            selectedFriends.remove(at: index)
        } else {
            selectedFriends.append(friend)
        }
    }
    
    private func deleteFriends(at offsets: IndexSet) {
        for index in offsets {
            let friend = viewModel.friends[index]
            viewModel.removeFriend(friend)
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
        FriendsListView(viewModel: FriendsViewModel(userId: "mockUserId"), selectedFriends: .constant([]), onDone: {})
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
    }
}