//
//  AuthViewModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

protocol AuthenticationFormProtocol{
    var formIsValid: Bool {get}
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
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
        } catch {
            print("DEBUG: Failed to log in with error \(error.localizedDescription)")
        }
    }
    
    func createUser(withEmail email: String, password:String, fullname:String, handicap: Float?, ghinNumber: Int?) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let user = User(id: result.user.uid, fullname: fullname, email: email, handicap: handicap, ghinNumber: ghinNumber)
            let encodedUser = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            await fetchUser()
        } catch {
            print ("DEBUG: Failed to created user with error \(error.localizedDescription)")
        }
    }
    
    func signOut(){
        do {
            try Auth.auth().signOut() //signs out user on backend
            self.userSession = nil //wipes out user session and takes back to login screen
            self.currentUser = nil //wipes out current user data model
        } catch {
            print ("DEDUG: Failed to sign out with error \(error.localizedDescription)")
        }
    }
    
    func deleteAccount(){
        
    }
    
    func fetchUser() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let snapshot = try? await Firestore.firestore().collection("users").document(uid).getDocument() else { return }
        self.currentUser = try? snapshot.data(as:User.self)
        
    }
}

class MockAuthViewModel: AuthViewModel {
    override init() {
        super.init()
        self.currentUser = User.MOCK_USER
    }
}
