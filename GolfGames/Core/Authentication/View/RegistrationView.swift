//
//  RegistrationView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import SwiftUI

struct RegistrationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var confirmPassword = ""
    @State private var handicap = ""
    @State private var ghinNumber = ""
    @State private var isPasswordValid: Bool = false
    @State private var hasEightCharacters: Bool = false
    @State private var hasNumber: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack{
                    // image
                    Image("golfgamble_bag")
                        .resizable()
                        .cornerRadius(10)
                        .scaledToFill()
                        .frame(width: 100, height: 170)
                        .padding(.vertical, 32)
                        .shadow(radius: 10)
                    
                    // form fields
                    VStack(spacing: 12){
                        InputView(text: $email,
                                  title: "Email Address",
                                  placeholder: "name@example.com")
                        .autocapitalization(.none)
                        .focused($isFocused)
                        
                        InputView(text: $firstName,
                                  title: "First Name",
                                  placeholder: "John")
                        .focused($isFocused)
                        
                        InputView(text: $lastName,
                                  title: "Last Name",
                                  placeholder: "Smith")
                        .focused($isFocused)
                        
                        ZStack (alignment: .trailing){
                            InputView(text: $password,
                                      title: "Password",
                                      placeholder: "Minimum 8 characters",
                                      isSecureField: true)
                            .autocapitalization(.none)
                            .focused($isFocused)
                            .onChange(of: password) { newValue in
                                validatePassword(newValue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: hasEightCharacters ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(hasEightCharacters ? .green : .red)
                                    Text("Minimum 8 characters")
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Image(systemName: hasNumber ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(hasNumber ? .green : .red)
                                    Text("Includes a number")
                                        .font(.caption)
                                }
                            }
                            
                        }
                        
                        ZStack (alignment: .trailing){
                            InputView(text: $confirmPassword,
                                      title: "Confirm Password",
                                      placeholder: "Re-Enter Password",
                                      isSecureField: true)
                            .autocapitalization(.none)
                            .focused($isFocused)
                            
                            if !password.isEmpty && !confirmPassword.isEmpty{
                                if password == confirmPassword {
                                    Image(systemName: "checkmark.circle.fill")
                                        .imageScale(.large)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(.systemGreen))
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .imageScale(.large)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(.systemRed))
                                }
                            }
                        }
                        
                        InputView(text: $ghinNumber,
                                  title: "GHIN Number (optional)",
                                  placeholder: "1234567")
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        
                        InputView(text: $handicap,
                                  title: "Handicap (optional)",
                                  placeholder: "12.3")
                        .keyboardType(.decimalPad) // Use decimalPad instead of numberPad
                        .focused($isFocused)
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isFocused = false
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    // sign in button
                    Button {
                        Task {
                            do {
                                try await viewModel.createUser(withEmail: email,
                                                               password: password,
                                                               firstName: firstName,
                                                               lastName: lastName,
                                                               handicap: handicap,
                                                               ghinNumber: ghinNumber)
                            } catch {
                                print("DEBUG: Failed to create user with error \(error.localizedDescription)")
                                // Handle the error, perhaps by showing an alert to the user
                            }
                        }
                    } label: {
                        HStack{
                            Text("CREATE ACCOUNT")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(width: UIScreen.main.bounds.width-32, height: 48)
                    }
                    .background(Color(.systemBlue))
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1.0 : 0.5)
                    .cornerRadius(10)
                    .padding(.top, 15)
                    
                    Spacer()
                    
                    // sign up buttons
                    Button{
                        dismiss()
                    }label: {
                        HStack{
                            Text("Already have an account?")
                            Text("Sign In")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                    }
                }
            }
        }
    }
    
    private func validatePassword(_ password: String) {
        hasEightCharacters = password.count >= 8
        hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        isPasswordValid = hasEightCharacters && hasNumber
    }
}

// MARK: - AuthenticationFormProtocol
extension RegistrationView: AuthenticationFormProtocol {
    var formIsValid: Bool {
        return !email.isEmpty
        && email.contains("@")
        && !firstName.isEmpty
        && !lastName.isEmpty
        && !password.isEmpty
        && password.count > 7
        && isPasswordValid
        && password == confirmPassword
    }
}

#Preview {
    RegistrationView()
}
