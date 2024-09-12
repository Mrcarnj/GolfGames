//
//  Round.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Round: Identifiable, Codable {
    @DocumentID var id: String?
    var courseId: String
    var courseName: String
    var teeName: String
    var golfers: [Golfer]
    var date: Date
    var roundType: RoundType
    
    // Add new fields for stats
    var birdies: [String: Int]?
    var eagles: [String: Int]?
    var pars: [String: Int]?
    var bogeys: [String: Int]?
    var doubleBogeyPlus: [String: Int]?
    
    struct Golfer: Identifiable, Codable {
        var id: String
        var firstName: String
        var lastName: String
        var handicap: Float
        
        var fullName: String {
            return "\(firstName) \(lastName)"
        }
    }
}

enum RoundType: String, Codable {
    case full18
    case front9
    case back9
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
