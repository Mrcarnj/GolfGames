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
    @State private var showingAddFriendSheet = false
    @Environment(\.presentationMode) var presentationMode
    var onDone: () -> Void

    var body: some View {
        VStack {
            List(viewModel.friends) { friend in
                HStack {
                    Text(friend.fullName)
                    Spacer()
                    if selectedFriends.contains(where: { $0.id == friend.id }) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let index = selectedFriends.firstIndex(where: { $0.id == friend.id }) {
                        selectedFriends.remove(at: index)
                    } else {
                        selectedFriends.append(friend)
                    }
                }
            }
            .navigationTitle("Friends List")
            .navigationBarItems(trailing: Button(action: {
                showingAddFriendSheet.toggle()
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $showingAddFriendSheet) {
                CreateGolferView(golfers: $selectedFriends, golferToEdit: .constant(nil))
            }

            if !selectedFriends.isEmpty {
                Button(action: {
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
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                viewModel.setUserId(user.id)
                viewModel.fetchFriends()
            }
        }
    }
}

struct FriendsListView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsListView(viewModel: FriendsViewModel(userId: "mockUserId"), selectedFriends: .constant([]), onDone: {})
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
    }
}
