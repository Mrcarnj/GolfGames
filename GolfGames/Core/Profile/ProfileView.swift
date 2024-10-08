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
    @State private var isEditing = false
    @State private var editedFullname = ""
    @State private var editedEmail = ""
    @State private var editedHandicap = ""
    @State private var editedGHIN = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
                            if isEditing {
                                TextField("Full Name", text: $editedFullname)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                TextField("Email", text: $editedEmail)
                                    .font(.footnote)
                                    .foregroundStyle(.gray)
                            } else {
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
                }
                Section("Golfer Info") {
                    HStack {
                        SettingsRowView(imageName: "figure.golf", title: "Handicap", tintColor: Color(.systemGray))
                        Spacer()
                        if isEditing {
                            TextField("Handicap", text: $editedHandicap)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text(user.handicap != nil ? String(format: "%.1f", user.handicap!) : "N/A")
                                .font(.subheadline)
                                .foregroundStyle(colorScheme == .dark ? Color.white : Color(.gray))
                        }
                    }
                    HStack {
                        SettingsRowView(imageName: "numbersign", title: "GHIN", tintColor: Color(.systemGray))
                        Spacer()
                        if isEditing {
                            TextField("GHIN", text: $editedGHIN)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        } else {
                            Text(user.ghinNumber != nil ? String(user.ghinNumber!) : "N/A")
                                .font(.subheadline)
                                .foregroundStyle(colorScheme == .dark ? Color.white : Color(.gray))
                        }
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
            .navigationBarItems(trailing: Button(isEditing ? "Update" : "Edit") {
                if isEditing {
                    updateUserInfo()
                } else {
                    isEditing.toggle()
                }
            })
            .onAppear {
                initializeEditFields(with: user)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Profile Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func initializeEditFields(with user: User) {
        editedFullname = user.fullname
        editedEmail = user.email
        editedHandicap = user.handicap != nil ? String(format: "%.1f", user.handicap!) : ""
        editedGHIN = user.ghinNumber != nil ? String(user.ghinNumber!) : ""
    }
    
    private func updateUserInfo() {
        guard let user = viewModel.currentUser else { return }
        
        let updatedUser = User(
            id: user.id,
            fullname: editedFullname,
            email: editedEmail,
            handicap: Float(editedHandicap),
            ghinNumber: Int(editedGHIN)
        )
        
        Task {
            do {
                try await viewModel.updateUserProfile(updatedUser)
                isEditing = false
                alertMessage = "Profile updated successfully"
                showAlert = true
            } catch {
                alertMessage = "Failed to update profile: \(error.localizedDescription)"
                showAlert = true
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
