//
//  LoginView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var viewModel: AuthViewModel
    @FocusState private var focusedField: FocusField?
    @State private var showingResetAlert = false
    @State private var resetAlertMessage = ""
    
    enum FocusField {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // image
                Image("golfgamble_bag")
                    .resizable()
                    .cornerRadius(10)
                    .scaledToFill()
                    .frame(width: 100, height: 170)
                    .padding(.vertical, 32)
                    .shadow(radius: 10)
                
                // form fields
                VStack(spacing: 12) {
                    InputView(text: $email,
                              title: "Email Address",
                              placeholder: "name@example.com")
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                    
                    InputView(text: $password,
                              title: "Password",
                              placeholder: "Enter Password",
                              isSecureField: true)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .password)
                    
                    // Add Forgot Password button
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            Task {
                                await sendPasswordResetEmail()
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 8)

                    if let error = viewModel.loginError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // sign in button
                Button {
                    Task {
                        do {
                            try await viewModel.signIn(withEmail: email, password: password)
                        } catch {
                            // Handle the error, perhaps by showing an alert to the user
                        }
                    }
                } label: {
                    HStack {
                        Text("SIGN IN")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                }
                .background(Color(.systemBlue))
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)
                .cornerRadius(10)
                .padding(.top, 24)
                
                Spacer()
                
                // sign up button
                NavigationLink {
                    RegistrationView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack {
                        Text("Don't have an account?")
                        Text("Sign Up")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Password Reset"),
                    message: Text(resetAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // Add this function to handle password reset
    func sendPasswordResetEmail() async {
        do {
            try await viewModel.sendPasswordReset(to: email)
            resetAlertMessage = "If an account exists for this email, a password reset link has been sent."
            showingResetAlert = true
        } catch {
            resetAlertMessage = "An error occurred. Please try again later."
            showingResetAlert = true
        }
    }
}

//MARK - AuthenticationFormProtocol
extension LoginView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && !password.isEmpty
        // Remove the password length check to allow existing users to sign in
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel()) // Provide a mock or test instance here
}
