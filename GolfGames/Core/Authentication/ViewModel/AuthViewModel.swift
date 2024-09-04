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
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
            
            // Check if migration has been performed
            if !UserDefaults.hasPerformedMigration {
                await migrateExistingUsers()
                await migrateExistingFriends()
                UserDefaults.hasPerformedMigration = true
            }
            
            self.loginError = nil // Clear any previous error
        } catch let error as NSError {
            print("DEBUG: Failed to log in with error \(error.localizedDescription)")
            print("DEBUG: Error code: \(error.code)")
            
            let errorCode = AuthErrorCode(_nsError: error)
            switch errorCode.code {
            case .invalidCredential, .wrongPassword, .userNotFound:
                print("DEBUG: Invalid credentials")
                self.loginError = "Invalid email or password. Please try again."
            case .invalidEmail:
                print("DEBUG: Invalid email format")
                self.loginError = "Invalid email format"
            case .networkError:
                print("DEBUG: Network error")
                self.loginError = "Network error. Please check your connection."
            default:
                print("DEBUG: Other error: \(errorCode.code)")
                self.loginError = "An error occurred. Please try again."
            }
            throw error
        }
    }
    
    func createUser(withEmail email: String, password: String, firstName: String, lastName: String, handicap: Float?, ghinNumber: Int?) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let user = User(id: result.user.uid, firstName: firstName, lastName: lastName, email: email, handicap: handicap, ghinNumber: ghinNumber)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch {
            print("DEBUG: Failed to create user with error \(error.localizedDescription)")
            throw error
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
