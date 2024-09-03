//
//  Golfer.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//
// Golfer.swift

import Foundation
import FirebaseFirestoreSwift

struct Golfer: Identifiable, Equatable, Codable, Hashable {
    var id: String
    var firstName: String
    var lastName: String
    var handicap: Float
    var tee: Tee?
    var ghinNumber: Int?
    var isChecked: Bool
    var courseHandicap: Int?
    
    init(id: String = UUID().uuidString, firstName: String, lastName: String, handicap: Float, tee: Tee? = nil, ghinNumber: Int? = nil, isChecked: Bool = false, courseHandicap: Int? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.handicap = handicap
        self.tee = tee
        self.ghinNumber = ghinNumber
        self.isChecked = isChecked
        self.courseHandicap = courseHandicap
    }
    
    static func == (lhs: Golfer, rhs: Golfer) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }

    func formattedName(golfers: [Golfer]) -> String {
        let golfersWithSameFirstName = golfers.filter { $0.firstName == self.firstName }
        
        if golfersWithSameFirstName.count > 1 {
            return "\(firstName) \(lastName.prefix(1))."
        } else {
            return firstName
        }
    }
    
    func lastNameFirstFormat() -> String {
        return "\(lastName), \(firstName.prefix(1))."
    }
}

// Extension to allow sorting of Golfers by last name
extension Array where Element == Golfer {
    func sortedByLastName() -> [Golfer] {
        return self.sorted { $0.lastNameFirstFormat() < $1.lastNameFirstFormat() }
    }
}