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
    var fullName: String
    var handicap: Float
    var tee: Tee?
    var ghinNumber: Int?
    var isChecked: Bool
    var courseHandicap: Int?
    
    init(id: String = UUID().uuidString, fullName: String, handicap: Float, tee: Tee? = nil, ghinNumber: Int? = nil, isChecked: Bool = false, courseHandicap: Int? = nil) {
        self.id = id
        self.fullName = fullName
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
    
    func formattedName(golfers: [Golfer]) -> String {
        let nameComponents = fullName.split(separator: " ")
        
        guard let firstName = nameComponents.first else {
            return fullName // Return the full name if it doesn't contain a space
        }
        
        let lastNameInitial = nameComponents.dropFirst().first?.first.map { String($0) } ?? ""
        
        let golfersWithSameFirstName = golfers.filter { $0.fullName.split(separator: " ").first == firstName }
        
        if golfersWithSameFirstName.count > 1 {
            return "\(firstName) \(lastNameInitial)."
        } else {
            return String(firstName)
        }
    }
}