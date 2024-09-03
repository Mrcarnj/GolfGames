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
            self.sortFriends()
            completion?()
        }
    }

    private func sortFriends() {
        self.friends = self.friends.sorted { (golfer1: Golfer, golfer2: Golfer) -> Bool in
            let name1 = golfer1.lastName.lowercased()
            let name2 = golfer2.lastName.lowercased()
            return name1 < name2 || (name1 == name2 && golfer1.firstName.lowercased() < golfer2.firstName.lowercased())
        }
    }

    func addFriend(firstName: String, lastName: String, ghinNumber: Int?, handicap: Float, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not set"])))
            return
        }

        let newFriend = Golfer(firstName: firstName, lastName: lastName, handicap: handicap, ghinNumber: ghinNumber)
        
        do {
            try db.collection("users").document(userId).collection("friends").document(newFriend.id).setData(from: newFriend) { error in
                if let error = error {
                    print("Error adding friend: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    self.friends.append(newFriend)
                    self.sortFriends()
                    print("Friend added successfully: \(newFriend.firstName) \(newFriend.lastName)")
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
                print("Friend removed successfully: \(friend.firstName) \(friend.lastName)")
            }
        }
    }
    
    func updateFriend(_ friend: Golfer, firstName: String, lastName: String, ghinNumber: Int?, handicap: Float, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not set"])))
            return
        }

        let updatedFriend = Golfer(id: friend.id, firstName: firstName, lastName: lastName, handicap: handicap, ghinNumber: ghinNumber)
        
        do {
            try db.collection("users").document(userId).collection("friends").document(friend.id).setData(from: updatedFriend) { error in
                if let error = error {
                    print("Error updating friend: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    if let index = self.friends.firstIndex(where: { $0.id == friend.id }) {
                        self.friends[index] = updatedFriend
                    }
                    self.sortFriends()
                    print("Friend updated successfully: \(updatedFriend.firstName) \(updatedFriend.lastName)")
                    completion(.success(()))
                }
            }
        } catch {
            print("Error updating friend: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}
