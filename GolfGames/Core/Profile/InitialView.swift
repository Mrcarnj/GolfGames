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
    @State private var showMenu = false

    var body: some View {
        if let user = authViewModel.currentUser {
            NavigationStack {
                GeometryReader { geometry in
                    ZStack {
                        mainContent(for: user, geometry: geometry)
                        
                        if showMenu {
                            Color.black.opacity(0.3)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    withAnimation {
                                        showMenu = false
                                    }
                                }
                            
                            HStack(spacing: 0) {
                                SideMenuView(isShowing: $showMenu, navigateToInitialView: .constant(false), showDiscardButton: false)
                                    .frame(width: min(geometry.size.width * 0.75, 300))
                                    .transition(.move(edge: .leading))
                                    .environmentObject(authViewModel)
                                    .environmentObject(roundsViewModel)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    if !showMenu {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: {
                                withAnimation {
                                    showMenu.toggle()
                                }
                            }) {
                                Image(systemName: "line.horizontal.3")
                                    .font(.headline)
                                    .foregroundStyle(Color(.systemGray))
                            }
                        }
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
                }
            }
        }
    }
    
    @ViewBuilder
    private func mainContent(for user: User, geometry: GeometryProxy) -> some View {
        VStack {
            welcomeMessage(for: user)
            .padding(.bottom, 20)

            Spacer()

            VStack(spacing: 20) {
                Image("golfgamble_bag")
                    .resizable()
                    .cornerRadius(10)
                    .scaledToFit()
                    .frame(height: 120)
                    .shadow(radius: 10)

                newRoundButtons(geometry: geometry)
            }

            Spacer()

            recentRoundsSection
        }
        .padding()
        .frame(maxWidth: .infinity)
        .onAppear {
            roundsViewModel.fetchRecentRounds(for: user)
        }
    }

    @ViewBuilder
    private func welcomeMessage(for user: User) -> some View {
        Text("Welcome, \(user.firstName)!")
            .padding(.top, 35)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func newRoundButtons(geometry: GeometryProxy) -> some View {
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
    }

    @ViewBuilder
    private var recentRoundsSection: some View {
        VStack {
            Text("Recent Rounds")
                .font(.headline)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .center)

            if roundsViewModel.recentRounds.isEmpty {
                Text("No recent rounds")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    RecentRoundsListView(roundsViewModel: roundsViewModel)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let mockUser = User(id: "mockId", firstName: "Mock", lastName: "User", email: "mockuser@example.com", handicap: 10.0, ghinNumber: 123456)
    return InititalView()
        .environmentObject(SingleRoundViewModel())
        .environmentObject(AuthViewModel(mockUser: mockUser))
}