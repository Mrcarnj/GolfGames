//
//  AuthViewModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol AuthenticationFormProtocol{
    var formIsValid: Bool {get}
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var loginError: String?

    init() {
        self.userSession = Auth.auth().currentUser
        
        Task {
            await fetchUser()
        }
    }
    
    init(mockUser: User) {
        self.currentUser = mockUser
        self.userSession = nil // Set this to nil or a mock FirebaseAuth.User if needed
    }
    
    // Add a new method for input validation
    private func validateInput(_ input: String, type: InputType) -> Bool {
        switch type {
        case .email:
            // Use a more robust email validation regex
            let emailRegex = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"
            return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: input)
        case .password:
            // Enforce password complexity rules
            let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
            return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: input)
        case .name:
            // Allow only letters and spaces, with a reasonable length limit
            let nameRegex = "^[a-zA-Z ]{1,50}$"
            return NSPredicate(format: "SELF MATCHES %@", nameRegex).evaluate(with: input)
        case .handicap:
            // Allow only numbers and one decimal point, with a reasonable range
            let handicapRegex = "^\\d{1,2}(\\.\\d)?$"
            if NSPredicate(format: "SELF MATCHES %@", handicapRegex).evaluate(with: input) {
                if let value = Float(input) {
                    return value >= 0 && value <= 54 // Assuming max handicap is 54
                }
            }
            return false
        case .ghinNumber:
            // Allow only numbers with a specific length
            let ghinRegex = "^\\d{7}$"
            return NSPredicate(format: "SELF MATCHES %@", ghinRegex).evaluate(with: input)
        }
    }

    // Update the createUser method to include input validation
    func createUser(withEmail email: String, password: String, firstName: String, lastName: String, handicap: String?, ghinNumber: String?) async throws {
        guard validateInput(email, type: .email),
              validateInput(password, type: .password),
              validateInput(firstName, type: .name),
              validateInput(lastName, type: .name),
              handicap == nil || validateInput(handicap!, type: .handicap),
              ghinNumber == nil || validateInput(ghinNumber!, type: .ghinNumber) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid input"])
        }

        // Sanitize inputs
        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let result = try await Auth.auth().createUser(withEmail: sanitizedEmail, password: password)
            self.userSession = result.user
            let user = User(id: result.user.uid, 
                            firstName: sanitizedFirstName, 
                            lastName: sanitizedLastName, 
                            email: sanitizedEmail, 
                            handicap: Float(handicap ?? ""), 
                            ghinNumber: Int(ghinNumber ?? ""))
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch {
            print("DEBUG: Failed to create user with error \(error.localizedDescription)")
            throw error
        }
    }

    // Update the signIn method to use less strict password validation
    func signIn(withEmail email: String, password: String) async throws {
        guard validateInput(email, type: .email) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email format"])
        }
        
        // Remove password validation for sign-in
        // This allows existing users with shorter passwords to still sign in

        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let result = try await Auth.auth().signIn(withEmail: sanitizedEmail, password: password)
            self.userSession = result.user
            await fetchUser()
            
            // ... rest of the signIn method ...
        } catch {
            // ... error handling ...
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("DEBUG: Failed to sign out with error \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() {
        // Implementation needed
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
        self.currentUser = try? snapshot.data(as: User.self)
    }
    
    func updateUserProfile(_ updatedUser: User) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }
        
        do {
            let encodedUser = try Firestore.Encoder().encode(updatedUser)
            try await Firestore.firestore().collection("users").document(uid).setData(encodedUser)
            self.currentUser = updatedUser
        } catch {
            print("DEBUG: Failed to update user profile with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func performAutoSignOutIfNeeded() {
            if !UserDefaults.hasPerformedAutoSignOut {
                signOut()
                UserDefaults.hasPerformedAutoSignOut = true
            }
        }
    
    // Add a migration function to update existing users
    func migrateExistingUsers() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        
        do {
            let snapshot = try await userRef.getDocument()
            if let data = snapshot.data(), let fullName = data["fullname"] as? String {
                let nameParts = fullName.components(separatedBy: " ")
                let firstName = nameParts.first ?? ""
                let lastName = nameParts.dropFirst().joined(separator: " ")
                
                try await userRef.updateData([
                    "firstName": firstName,
                    "lastName": lastName,
                    "fullname": FieldValue.delete()
                ])
                
                print("User migrated successfully")
            }
        } catch {
            print("Error migrating user: \(error.localizedDescription)")
        }
    }
    
    // Add a migration function to update existing friends
    func migrateExistingFriends() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let friendsRef = db.collection("users").document(uid).collection("friends")
        
        do {
            let snapshot = try await friendsRef.getDocuments()
            for document in snapshot.documents {
                let data = document.data()
                if let fullName = data["fullName"] as? String {
                    let nameParts = fullName.components(separatedBy: " ")
                    let firstName = nameParts.first ?? ""
                    let lastName = nameParts.dropFirst().joined(separator: " ")
                    
                    try await friendsRef.document(document.documentID).updateData([
                        "firstName": firstName,
                        "lastName": lastName,
                        "fullName": FieldValue.delete()
                    ])
                    
                    print("Friend migrated successfully: \(fullName)")
                }
            }
            print("All friends migrated successfully")
        } catch {
            print("Error migrating friends: \(error.localizedDescription)")
        }
    }
    
    
}

extension UserDefaults {
    static var hasPerformedMigration: Bool {
        get { UserDefaults.standard.bool(forKey: "hasPerformedMigration") }
        set { UserDefaults.standard.set(newValue, forKey: "hasPerformedMigration") }
    }
    static var hasPerformedAutoSignOut: Bool {
        get { UserDefaults.standard.bool(forKey: "hasPerformedAutoSignOut") }
        set { UserDefaults.standard.set(newValue, forKey: "hasPerformedAutoSignOut") }
    }
}

class MockAuthViewModel: AuthViewModel {
    override init() {
        super.init()
        self.currentUser = User(id: NSUUID().uuidString, firstName: "Tiger", lastName: "Woods", email: "tiger@tgl.com", handicap: 1.2, ghinNumber: 1709023)
    }
}

// Add an enum for input types
enum InputType {
    case email
    case password
    case name
    case handicap
    case ghinNumber
}
