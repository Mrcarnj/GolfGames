//
//  RegistrationView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

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
    @State private var fullname = ""
    @State private var confirmPassword = ""
    @State private var handicap = ""
    @State private var ghinNumber = ""
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack{
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
                    
                    InputView(text: $fullname,
                              title: "Full Name",
                              placeholder: "John Smith")
                    .focused($isFocused)
                    
                    ZStack (alignment: .trailing){
                        InputView(text: $password,
                                  title: "Password",
                                  placeholder: "Minimum 6 characters",
                                  isSecureField: true)
                        .autocapitalization(.none)
                        .focused($isFocused)
                        
                        if !password.isEmpty {
                            if password.count > 5 {
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
                    Task{
                        let ghinNumberValue = Int(ghinNumber)
                        let handicapValue = Float(handicap)
                        do {
                            try await viewModel.createUser(withEmail: email,
                                                           password: password,
                                                           fullname: fullname,
                                                           handicap: handicapValue,
                                                           ghinNumber: ghinNumberValue)
                        } catch {
                            print("DEBUG: Failed to create user with error \(error.localizedDescription)")
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

//MARK - AuthenticationFormProtocol
extension RegistrationView: AuthenticationFormProtocol{
   var formIsValid: Bool {
       return !email.isEmpty
       && email.contains("@")
       && !fullname.isEmpty
       && !password.isEmpty
       && password.count > 5
       && password == confirmPassword
   }
}

#Preview {
    RegistrationView()
}
