//
//  Golfer.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//
// Golfer.swift
import Foundation

struct Golfer: Identifiable, Equatable, Codable {
    var id: String = UUID().uuidString
    var fullName: String
    var handicap: Float
    var tee: Tee?

    static func == (lhs: Golfer, rhs: Golfer) -> Bool {
        return lhs.id == rhs.id
    }
}

