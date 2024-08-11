//
//  InititalView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/4/24.
//

import SwiftUI
import Firebase

struct InititalView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var roundsViewModel = RecentRoundsModel()

    var body: some View {
        if let user = authViewModel.currentUser {
            NavigationStack {
                VStack {
                    welcomeMessage(for: user)

                    Image("golfgamble_bag")
                        .resizable()
                        .cornerRadius(10)
                        .scaledToFill()
                        .frame(width: 100, height: 120)
                        .padding(.vertical, 32)
                        .shadow(radius: 10)

                    newRoundButtons()

                    Spacer()

                    Text("Recent Rounds")
                        .font(.headline)
                        .padding(.top, 20)

                    if roundsViewModel.recentRounds.isEmpty {
                        Text("No recent rounds")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ScrollView {
                            RecentRoundsListView(roundsViewModel: roundsViewModel)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            ProfileView()
                        } label: {
                            Image(systemName: "gear")
                                .font(.headline)
                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                }
                .onAppear {
                    roundsViewModel.fetchRecentRounds(for: user)
                }
                .navigationBarBackButtonHidden(true)
            }
        }
    }

    @ViewBuilder
    private func welcomeMessage(for user: User) -> some View {
        Text("Welcome, \(user.fullname)!")
            .padding(.top, 35)
    }

    @ViewBuilder
    private func newRoundButtons() -> some View {
        NavigationLink(destination: SingleRoundSetupView()) {
            HStack {
                Text("New Single Round")
                Image(systemName: "plus")
            }
            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
            .foregroundColor(.white)
            .background(Color(.systemTeal))
            .cornerRadius(10)
        }
// MULTIPLE ROUND BUTTON
//        Button {
//            // Action for Multiple Rounds
//        } label: {
//            HStack {
//                Text("New Multiple Rounds")
//                Image(systemName: "plus")
//            }
//        }
        .frame(width: UIScreen.main.bounds.width - 32, height: 48)
        .foregroundColor(.white)
        .background(Color(.systemTeal))
        .cornerRadius(10)
        .padding(.top, 15)
    }
}

#Preview {
    let mockUser = User(id: "mockId", fullname: "Mock User", email: "mockuser@example.com", handicap: 10.0, ghinNumber: 123456)
    return InititalView()
        .environmentObject(SingleRoundViewModel())
        .environmentObject(AuthViewModel(mockUser: mockUser))
}
