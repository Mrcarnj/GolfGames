//
//  Golfer.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//
import Foundation

struct Golfer: Identifiable, Equatable {
    let id = UUID()
    var fullName: String
    var handicap: Float
    var tee: Tee?

    static func == (lhs: Golfer, rhs: Golfer) -> Bool {
        return lhs.id == rhs.id
    }
}
