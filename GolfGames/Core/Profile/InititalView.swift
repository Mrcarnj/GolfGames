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

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy" // Adjusted date format
        return formatter
    }

    var body: some View {
        if let user = authViewModel.currentUser {
            NavigationStack {
                VStack {
                    Text("Welcome, \(user.fullname)!")
                        .padding(.top, 35)

                    Image("golfgamble_bag")
                        .resizable()
                        .cornerRadius(10)
                        .scaledToFill()
                        .frame(width: 100, height: 120)
                        .padding(.vertical, 32)
                        .shadow(radius: 10)

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

                    Button {
                        // Action for Multiple Rounds
                    } label: {
                        HStack {
                            Text("New Multiple Rounds")
                            Image(systemName: "plus")
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                    .foregroundColor(.white)
                    .background(Color(.systemTeal))
                    .cornerRadius(10)
                    .padding(.top, 15)

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
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(roundsViewModel.recentRounds, id: \.id) { round in
                                    HStack {
                                        Text(dateFormatter.string(from: round.date))
                                        Spacer()
                                        Text(round.course)
                                        Spacer()
                                        Text(round.tees)
                                        Spacer()
                                        Text("(\(String(format: "%.1f", round.courseRating))/\(Int(round.slopeRating)))")
                                        Spacer()
                                        Text("\(round.totalScore)")
                                            .fontWeight(.bold)
                                    }
                                    .font(.system(size: 10))
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
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
                    OrientationUtility.lockOrientation(.portrait, andRotateTo: .portrait)
                }
                .onDisappear {
                    OrientationUtility.lockOrientation(.all)
                }
                .navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    let mockUser = User(id: "mockId", fullname: "Mock User", email: "mockuser@example.com", handicap: 10.0, ghinNumber: 123456)
    return InititalView()
        .environmentObject(SingleRoundViewModel())
        .environmentObject(AuthViewModel(mockUser: mockUser))
}
