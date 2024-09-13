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
        print("DEBUG: Initializing AuthViewModel")
        if let app = FirebaseApp.app() {
            print("DEBUG: Firebase app is configured")
            let options = app.options
            print("DEBUG: Firebase project ID: \(options.projectID)")
            print("DEBUG: Firebase API Key: \(options.apiKey)")
            print("DEBUG: Firebase Bundle ID: \(options.bundleID)")
        } else {
            print("DEBUG: Firebase app is not configured")
        }
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
        print("DEBUG: Starting user creation process")
        
        if !validateInput(email, type: .email) {
            print("DEBUG: Invalid email format")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email format"])
        }
        if !validateInput(password, type: .password) {
            print("DEBUG: Invalid password format")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid password format"])
        }
        if !validateInput(firstName, type: .name) {
            print("DEBUG: Invalid first name format")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid first name format"])
        }
        if !validateInput(lastName, type: .name) {
            print("DEBUG: Invalid last name format")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid last name format"])
        }
        if let handicap = handicap, !validateInput(handicap, type: .handicap) {
            print("DEBUG: Invalid handicap format")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid handicap format"])
        }
        if let ghinNumber = ghinNumber, !validateInput(ghinNumber, type: .ghinNumber) {
            print("DEBUG: Invalid GHIN number format")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid GHIN number format"])
        }

        // Sanitize inputs
        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await withTimeout(seconds: 30) { [weak self] in
                guard let self = self else { throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Self is nil"]) }
                
                print("DEBUG: Checking for existing user")
                let querySnapshot = try await Firestore.firestore().collection("users")
                    .whereField("email", isEqualTo: sanitizedEmail)
                    .getDocuments()

                print("DEBUG: Creating new Auth user")
                let result = try await Auth.auth().createUser(withEmail: sanitizedEmail, password: password)
                self.userSession = result.user
                print("DEBUG: New Auth user created with ID: \(result.user.uid)")

                let user: User
                if let existingUserDoc = querySnapshot.documents.first {
                    print("DEBUG: Existing user found, updating document")
                    let oldUserId = existingUserDoc.documentID
                    let newUserId = result.user.uid

                    user = User(
                        id: newUserId,
                        firstName: sanitizedFirstName,
                        lastName: sanitizedLastName,
                        email: sanitizedEmail,
                        handicap: Float(handicap ?? ""),
                        ghinNumber: Int(ghinNumber ?? "")
                    )
                    
                    print("DEBUG: Updating user document")
                    try await Firestore.firestore().collection("users").document(newUserId).setData(from: user)

                    print("DEBUG: Migrating friends")
                    try await self.migrateFriends(from: oldUserId, to: newUserId)

                    print("DEBUG: Migrating rounds")
                    try await self.migrateRounds(from: oldUserId, to: newUserId)

                    print("DEBUG: Deleting old user document")
                    try await existingUserDoc.reference.delete()

                    print("DEBUG: Updated user document and migrated data for \(sanitizedEmail)")
                } else {
                    print("DEBUG: Creating new user document")
                    user = User(
                        id: result.user.uid, 
                        firstName: sanitizedFirstName, 
                        lastName: sanitizedLastName, 
                        email: sanitizedEmail, 
                        handicap: Float(handicap ?? ""), 
                        ghinNumber: Int(ghinNumber ?? "")
                    )
                    try await Firestore.firestore().collection("users").document(user.id).setData(from: user)
                    print("DEBUG: Created new user document for \(sanitizedEmail)")
                }

                print("DEBUG: Updating currentUser")
                self.currentUser = user

                print("DEBUG: User creation process completed successfully")
            }
        } catch is TimeoutError {
            print("DEBUG: User creation process timed out")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "The operation timed out. Please try again."])
        } catch {
            print("DEBUG: Failed to create user with error: \(error.localizedDescription)")
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
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
        }

        do {
            // Store the user's email before deleting the account
            let userEmail = user.email ?? ""

            // Delete user from Firebase Authentication
            try await user.delete()

            // Update Firestore document to mark the account as deleted
            let userRef = Firestore.firestore().collection("users").document(user.uid)
            try await userRef.updateData([
                "isDeleted": true,
                "deletedAt": FieldValue.serverTimestamp(),
                "lastKnownEmail": userEmail
            ])

            // Sign out and clear local user data
            self.signOut()

            print("DEBUG: User account deleted from Authentication and marked as deleted in Firestore")
        } catch {
            print("DEBUG: Failed to delete account with error \(error.localizedDescription)")
            throw error
        }
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
    
    func sendPasswordReset(to email: String) async throws {
        guard validateInput(email, type: .email) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid email format"])
        }

        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            // Instead of checking if the account exists, just attempt to send the reset email
            try await Auth.auth().sendPasswordReset(withEmail: sanitizedEmail)
            print("DEBUG: Password reset email sent successfully to: \(sanitizedEmail)")
        } catch {
            print("DEBUG: Failed to send password reset email with error: \(error.localizedDescription)")
            print("DEBUG: Error details: \(error)")
            throw error
        }
    }
    
    func checkUserExistence(email: String) async {
        do {
            // Check Authentication
            let methods = try await Auth.auth().fetchSignInMethods(forEmail: email)
            print("DEBUG: Authentication methods for \(email): \(methods)")
            
            // Check Firestore
            let querySnapshot = try await Firestore.firestore().collection("users").whereField("email", isEqualTo: email).getDocuments()
            print("DEBUG: Firestore documents for \(email): \(querySnapshot.documents.count)")
        } catch {
            print("DEBUG: Error checking user existence: \(error.localizedDescription)")
        }
    }
    
    func checkUserExistenceInAuth(email: String) async {
        do {
            let methods = try await Auth.auth().fetchSignInMethods(forEmail: email)
            print("DEBUG: Sign-in methods for \(email): \(methods)")
            if methods.isEmpty {
                print("DEBUG: No account found in Firebase Authentication for \(email)")
            } else {
                print("DEBUG: Account exists in Firebase Authentication for \(email)")
            }
        } catch {
            print("DEBUG: Error checking user existence in Auth: \(error.localizedDescription)")
        }
    }
    
    func createAuthAccountIfNeeded(email: String, password: String) async throws {
        do {
            let methods = try await Auth.auth().fetchSignInMethods(forEmail: email)
            if methods.isEmpty {
                // No account exists, so create one
                try await Auth.auth().createUser(withEmail: email, password: password)
                print("DEBUG: Created new account in Firebase Authentication for \(email)")
            } else {
                print("DEBUG: Account already exists in Firebase Authentication for \(email)")
            }
        } catch {
            print("DEBUG: Error creating/checking account: \(error.localizedDescription)")
            throw error
        }
    }

    private func migrateFriends(from oldUserId: String, to newUserId: String) async throws {
        print("DEBUG: Starting friends migration from \(oldUserId) to \(newUserId)")
        let oldFriendsRef = Firestore.firestore().collection("users").document(oldUserId).collection("friends")
        let newFriendsRef = Firestore.firestore().collection("users").document(newUserId).collection("friends")

        let snapshot = try await oldFriendsRef.getDocuments()
        print("DEBUG: Found \(snapshot.documents.count) friends to migrate")
        for doc in snapshot.documents {
            try await newFriendsRef.document(doc.documentID).setData(doc.data())
            print("DEBUG: Migrated friend \(doc.documentID)")
        }
        print("DEBUG: Friends migration completed")
    }

    private func migrateRounds(from oldUserId: String, to newUserId: String) async throws {
        print("DEBUG: Starting rounds migration from \(oldUserId) to \(newUserId)")
        let oldRoundsRef = Firestore.firestore().collection("users").document(oldUserId).collection("rounds")
        let newRoundsRef = Firestore.firestore().collection("users").document(newUserId).collection("rounds")

        let snapshot = try await oldRoundsRef.getDocuments()
        print("DEBUG: Found \(snapshot.documents.count) rounds to migrate")
        for doc in snapshot.documents {
            try await newRoundsRef.document(doc.documentID).setData(doc.data())
            print("DEBUG: Migrated round \(doc.documentID)")
        }
        print("DEBUG: Rounds migration completed")
    }

    func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    struct TimeoutError: Error {}
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
