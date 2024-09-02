//
//  SharedViewModel.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/30/24.
//

import SwiftUI

class SharedViewModel: ObservableObject {
    @Published var golfers: [Golfer] = []
    @Published var selectedTees: [String: Tee?] = [:]
    @Published var courseHandicaps: [String: Int] = [:]
    @Published var selectedCourse: Course?
    @Published var roundId: String?
    @Published var currentUserGolfer: Golfer?
    @Published var golferTeeSelections: [String: String] = [:]  // [GolferID: TeeID]
    @Published var isMatchPlay: Bool = false
    @Published var holes: [String: [Hole]] = [:] // Tee ID : [Hole]
    @Published var matchPlayHandicap: Int = 0

    func addGolfer(_ golfer: Golfer) {
        if !golfers.contains(where: { $0.id == golfer.id }) {
            golfers.append(golfer)
            if currentUserGolfer == nil {
                currentUserGolfer = golfer
            }
        }
    }

    func removeGolfer(_ golfer: Golfer) {
        golfers.removeAll { $0.id == golfer.id }
    }

    func resetForNewRound() {
        golfers = []
        selectedTees = [:]
        courseHandicaps = [:]
        selectedCourse = nil
        roundId = nil
        golferTeeSelections = [:]
        isMatchPlay = false
    }

    func createNewRound(isMatchPlay: Bool) {
        self.isMatchPlay = isMatchPlay
    }

    func updateHoles(_ newHoles: [String: [Hole]]) {
        holes = newHoles
    }
}