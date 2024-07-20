//
//  FriendsListView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/18/24.
//

import SwiftUI

struct FriendsListView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @Binding var additionalGolfers: [Golfer]
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAddFriendSheet = false
    @Environment(\.presentationMode) var presentationMode
    @State private var checkedGolfers: Set<String> = []
    var alreadyAddedGolfers: Set<String>

    var body: some View {
        VStack {
            // Title
            Text("Friends List")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
                .foregroundColor(Color.primary)

            // Header
            HStack {
                Text("Name")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("GHIN")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("HCP")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Add")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .shadow(radius: 2)

            // List of Friends
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.friends.filter { !alreadyAddedGolfers.contains($0.id) }) { friend in
                        HStack {
                            Text(friend.fullName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(friend.ghinNumber != nil ? String(friend.ghinNumber!) : "N/A")")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text("\(String(format: "%.1f", friend.handicap))")
                                .frame(maxWidth: .infinity, alignment: .center)
                            Toggle(isOn: Binding(
                                get: { checkedGolfers.contains(friend.id) },
                                set: { isChecked in
                                    if isChecked {
                                        checkedGolfers.insert(friend.id)
                                    } else {
                                        checkedGolfers.remove(friend.id)
                                    }
                                }
                            )) {
                                EmptyView()
                            }
                            .toggleStyle(CheckboxToggleStyle())
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 10)
            .padding(.top, 10)

            // Add to Round Button
            Button(action: {
                addSelectedGolfersToRound()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Add to Round")
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                    .foregroundColor(.white)
                    .background(Color(.systemTeal))
                    .cornerRadius(10)
                    .padding()
            }
        }
        .padding()
        .navigationTitle("Friends List")
        .navigationBarItems(trailing: Button(action: {
            showingAddFriendSheet.toggle()
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingAddFriendSheet) {
            CreateFriendView(viewModel: viewModel)
        }
        .onAppear {
            if let user = authViewModel.currentUser {
                viewModel.userId = user.id
                viewModel.fetchFriends {
                    resetFriendSelection()
                }
            }
        }
        .background(Color(.systemBackground))
    }

    private func resetFriendSelection() {
        checkedGolfers.removeAll()
    }

    private func addSelectedGolfersToRound() {
        let selectedGolfers = viewModel.friends.filter { checkedGolfers.contains($0.id) }
        additionalGolfers.append(contentsOf: selectedGolfers)
        additionalGolfers = Array(Set(additionalGolfers)) // Remove duplicates if any
    }
}

struct FriendsListView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsListView(viewModel: FriendsViewModel(userId: "mockUserId"), additionalGolfers: .constant([]), alreadyAddedGolfers: [])
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
    }
}
