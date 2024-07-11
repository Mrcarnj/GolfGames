//
//  HandicapCalculator.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import Foundation

struct HandicapCalculator {
    static func calculateCourseHandicap(handicapIndex: Float, slopeRating: Int) -> Int {
        let courseHandicap = (handicapIndex * Float(slopeRating)) / 113
        return Int(courseHandicap.rounded())
    }

    static func determineStrokeHoles(courseHandicap: Int, holeHandicaps: [Int]) -> [Int] {
        let sortedHoleHandicaps = holeHandicaps.sorted()
        var strokeHoles: [Int] = []

        for i in 0..<courseHandicap {
            strokeHoles.append(sortedHoleHandicaps[i])
        }

        return strokeHoles
    }
}
