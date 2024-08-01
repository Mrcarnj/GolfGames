//
//  FriendsViewModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/18/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FriendsViewModel: ObservableObject {
    @Published var friends: [Golfer] = []
    private let db = Firestore.firestore()
    public var userId: String?

    init(userId: String?) {
        self.userId = userId
        fetchFriends()
    }

    func setUserId(_ id: String) {
        self.userId = id
        fetchFriends()
    }

    func fetchFriends(completion: (() -> Void)? = nil) {
        guard let userId = userId else { return }
        db.collection("users").document(userId).collection("friends").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching friends: \(error.localizedDescription)")
                completion?()
                return
            }

            guard let documents = snapshot?.documents else {
                print("No friends found")
                completion?()
                return
            }

            self.friends = documents.compactMap { try? $0.data(as: Golfer.self) }
            completion?()
        }
    }

    func addFriend(fullName: String, ghinNumber: Int?, handicap: Float, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not set"])))
            return
        }

        let newFriend = Golfer(fullName: fullName, handicap: handicap, ghinNumber: ghinNumber)
        
        do {
            try db.collection("users").document(userId).collection("friends").document(newFriend.id).setData(from: newFriend) { error in
                if let error = error {
                    print("Error adding friend: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    self.friends.append(newFriend)
                    print("Friend added successfully: \(newFriend.fullName)")
                    completion(.success(()))
                }
            }
        } catch {
            print("Error adding friend: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    func removeFriend(_ friend: Golfer) {
        guard let userId = userId else { return }
        
        db.collection("users").document(userId).collection("friends").document(friend.id).delete { error in
            if let error = error {
                print("Error removing friend: \(error.localizedDescription)")
            } else {
                self.friends.removeAll { $0.id == friend.id }
                print("Friend removed successfully: \(friend.fullName)")
            }
        }
    }
    
    func updateFriend(_ friend: Golfer, fullName: String, ghinNumber: Int?, handicap: Float, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let userId = userId else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not set"])))
                return
            }

            let updatedFriend = Golfer(id: friend.id, fullName: fullName, handicap: handicap, ghinNumber: ghinNumber)
            
            do {
                try db.collection("users").document(userId).collection("friends").document(friend.id).setData(from: updatedFriend) { error in
                    if let error = error {
                        print("Error updating friend: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        if let index = self.friends.firstIndex(where: { $0.id == friend.id }) {
                            self.friends[index] = updatedFriend
                        }
                        print("Friend updated successfully: \(updatedFriend.fullName)")
                        completion(.success(()))
                    }
                }
            } catch {
                print("Error updating friend: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
}
