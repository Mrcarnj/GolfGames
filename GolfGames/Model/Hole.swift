//
//  Hole.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Hole: Identifiable, Codable {
    @DocumentID var id: String?
    var holeNumber: Int
    var par: Int
    var handicap: Int
    var yardage: Int

    enum CodingKeys: String, CodingKey {
        case holeNumber = "hole_number"
        case par
        case handicap
        case yardage = "hole_yards"
    }
}
