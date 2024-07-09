//
//  InititalView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/4/24.
//

import SwiftUI
import Firebase

struct InititalView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        if let user = viewModel.currentUser {
            NavigationStack{
                VStack {
                    
                    Text("Welcome, \(user.fullname)!")
                    //  Text("Welcome, Mike Dietrich!")
                        .padding(.top, 35)
                    
                    // image
                    Image("golfgamble_bag")
                        .resizable()
                        .cornerRadius(10)
                        .scaledToFill()
                        .frame(width: 100, height: 120)
                        .padding(.vertical, 32)
                        .shadow(radius: 10)
                }
                
                // Single Round Button
                NavigationLink(destination: SingleRoundSetupView()) {
                    HStack {
                        Text("New Single Round")
                        Image(systemName: "plus")
                    }
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                    .foregroundColor(.white) // Use foregroundColor instead of foregroundStyle for text color
                    .background(Color(.systemTeal))
                    .cornerRadius(10)
                }
                
                // Multiple Round Button
                Button {
                    // Action for Multiple Rounds
                } label: {
                    HStack {
                        Text("New Multiple Rounds")
                        Image(systemName: "plus")
                    }
                }
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                .foregroundStyle(Color(.white))
                .background(Color(.systemTeal))
                .cornerRadius(10)
                .padding(.top, 15)
                
                Spacer()
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
