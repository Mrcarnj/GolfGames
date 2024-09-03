//
//  AddGolfersView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

//
//  AddGolfersView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

import SwiftUI

struct AddGolfersView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @State private var navigateToFriendsList = false
    @State private var selectedFriends: [Golfer] = []
    @State private var navigateToTeeSelection = false
    var selectedCourse: Course?

    var body: some View {
        VStack {
            Image("golfgamble_bag")
                .resizable()
                .cornerRadius(10)
                .scaledToFill()
                .frame(width: 100, height: 120)
                .padding(.vertical, 32)
                .shadow(radius: 10)

            if let course = selectedCourse {
                Text("\(course.name)")
                    .font(.title2)
                    .padding(.top)
                    .foregroundColor(Color.primary)

                Text("Who's Playing Today?")
                    .font(.headline)
                    .foregroundColor(Color.primary)
                    .padding(.top)

                List {
                    if let currentUserGolfer = sharedViewModel.currentUserGolfer {
                        GolferRow(golfer: currentUserGolfer, isCurrentUser: true)
                    }
                    ForEach(selectedFriends, id: \.id) { golfer in
                        GolferRow(golfer: golfer, isCurrentUser: false) {
                            selectedFriends.removeAll { $0.id == golfer.id }
                        }
                    }
                }

                Button(action: {
                    navigateToFriendsList = true
                }) {
                    Text("Add Golfer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Button(action: {
                    let allGolfers = ([sharedViewModel.currentUserGolfer] + selectedFriends).compactMap { $0 }
                    sharedViewModel.golfers = allGolfers
                    navigateToTeeSelection = true
                }) {
                    HStack {
                        Text("Next: Tee Selection")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemTeal))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(sharedViewModel.currentUserGolfer == nil)
            } else {
                Text("No course selected")
                    .font(.headline)
                    .padding()
                    .foregroundColor(Color.primary)
            }
        }
        .background(
            NavigationLink(destination: TeeSelectionView()
                .environmentObject(sharedViewModel)
                .environmentObject(authViewModel)
                .environmentObject(roundViewModel)
                .environmentObject(singleRoundViewModel), isActive: $navigateToTeeSelection) {
                EmptyView()
            }
        )
        .background(
                    NavigationLink(destination: FriendsListView(
                        viewModel: FriendsViewModel(userId: authViewModel.currentUser?.id),
                        selectedFriends: $selectedFriends,
                        onDone: {
                            navigateToFriendsList = false
                        },
                        allowSelection: true
                    )
                    .environmentObject(singleRoundViewModel)
                    .environmentObject(authViewModel), isActive: $navigateToFriendsList) {
                        EmptyView()
                    }
                )
        .onAppear {
            if let user = authViewModel.currentUser {
                sharedViewModel.currentUserGolfer = Golfer(id: user.id, firstName: user.firstName, lastName: user.lastName, handicap: user.handicap ?? 0.0)
            }
            if let course = selectedCourse {
                sharedViewModel.selectedCourse = course
            }
        }
    }
}

struct GolferRow: View {
    let golfer: Golfer
    let isCurrentUser: Bool
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text("\(golfer.firstName) \(golfer.lastName)")
            Spacer()
            if !isCurrentUser {
                Button(action: {
                    onRemove?()
                }) {
                    Image(systemName: "minus.circle")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

//struct AddGolfersView_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockUser = User(id: "mockId", fullname: "Mock User", email: "mockuser@example.com", handicap: 10.0, ghinNumber: 123456)
//        let mockCourse = Course(id: "courseId", name: "Mock Course", location: "Mock Location")
//
//        return AddGolfersView(
//            selectedCourse: mockCourse
//        )
//        .environmentObject(SingleRoundViewModel())
//        .environmentObject(AuthViewModel(mockUser: mockUser))
//        .environmentObject(RoundViewModel())
//        .environmentObject(SharedViewModel())
//    }
//}
