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
    var playingHandicap: Int?

    init(id: String = UUID().uuidString, fullName: String, handicap: Float, tee: Tee? = nil, ghinNumber: Int? = nil, isChecked: Bool = false, playingHandicap: Int? = nil) {
        self.id = id
        self.fullName = fullName
        self.handicap = handicap
        self.tee = tee
        self.ghinNumber = ghinNumber
        self.isChecked = isChecked
        self.playingHandicap = playingHandicap
    }

    static func == (lhs: Golfer, rhs: Golfer) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

