//
//  DebugUtilities.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/3/24.
//

import Foundation

struct DebugCache {
    static var lastPrintedHoleInfo: [String: String] = [:]
    static var lastPrintedScoreUpdate: [String: String] = [:]
}

struct DebugUtilities {
    static func printHoleInfo(for golferId: String, hole: Int, gross: Int, net: Int, matchPlayNet: Int, regularStrokes: Int, matchPlayStrokes: Int) {
        let info = "Hole \(hole) for golfer \(golferId): Gross \(gross), Net \(net), Match Play Net \(matchPlayNet), Regular Strokes: \(regularStrokes), Match Play Strokes: \(matchPlayStrokes)"
        let key = "\(golferId)-\(hole)"
        
        if DebugCache.lastPrintedHoleInfo[key] != info {
            print(info)
            DebugCache.lastPrintedHoleInfo[key] = info
        }
    }

    static func printScoreUpdate(golfer: String, hole: Int, grossScore: Int, netScore: Int, isStrokeHole: Bool) {
        let info = "Score updated - Golfer: \(golfer), Hole: \(hole), Gross Score: \(grossScore), Net Score: \(netScore), Stroke Hole: \(isStrokeHole)"
        let key = "\(golfer)-\(hole)"
        
        if DebugCache.lastPrintedScoreUpdate[key] != info {
            print(info)
            DebugCache.lastPrintedScoreUpdate[key] = info
        }
    }
}
