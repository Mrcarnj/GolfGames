//
//  ScoringModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Score: Identifiable, Codable {
    @DocumentID var id: String?
    var golferId: String
    var holeNumber: Int
    var score: Int
}

