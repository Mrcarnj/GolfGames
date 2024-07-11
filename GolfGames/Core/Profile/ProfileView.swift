//
//  ProfileView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        if let user = viewModel.currentUser {
            List {
                Section {
                    HStack {
                        Text(user.initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(.white))
                            .frame(width: 72, height: 72)
                            .background(Color(.systemGray3))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullname)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.top, 4)
                            
                            Text(user.email)
                                .font(.footnote)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                Section("Golfer Info") {
                    HStack {
                        SettingsRowView(imageName: "figure.golf", title: "Handicap", tintColor: Color(.systemGray))
                        
                        Spacer()
                        
                        Text(user.handicap != nil ? String(format: "%.1f", user.handicap!) : "N/A")
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color(.gray))
                        
                    }
                    HStack {
                        SettingsRowView(imageName: "numbersign", title: "GHIN", tintColor: Color(.systemGray))
                        
                        Spacer()
                        
                        Text(user.ghinNumber != nil ? String( user.ghinNumber!) : "N/A")
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color(.gray))
                    }
                }
                
                Section("App Info") {
                    HStack {
                        SettingsRowView(imageName: "gear", title: "Version", tintColor: Color(.systemGray))
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color(.gray))
                    }
                }
                Section("Account") {
                    Button {
                        viewModel.signOut()
                    } label: {
                        SettingsRowView(imageName: "arrow.left.circle.fill",
                                        title: "Sign Out",
                                        tintColor: .red)
                    }
                    
                    Button {
                        viewModel.deleteAccount()
                    } label: {
                        SettingsRowView(imageName: "xmark.circle.fill",
                                        title: "Delete Account",
                                        tintColor: .red)
                    }
                }
            }
        }
    }
}

#Preview {
    let mockUser = User(id: "mockId", fullname: "Mock User", email: "mockuser@example.com", handicap: 10.0, ghinNumber: 123456)
        return ProfileView()
            .environmentObject(SingleRoundViewModel())
            .environmentObject(AuthViewModel(mockUser: mockUser))
}

