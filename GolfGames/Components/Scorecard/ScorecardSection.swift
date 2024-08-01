//
//  ScorecardSection.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/31/24.
//

import SwiftUI

struct ScorecardSection: View {
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    let holeRange: ClosedRange<Int>
    let isOut: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScorecardRow(title: "Hole", values: holeRange.map { String($0) }, total: isOut ? "Out" : "In", showTotal: true)
            ScorecardRow(title: "Par", values: parValues.map { String($0) }, total: String(parValues.reduce(0, +)), showTotal: true)
            ScorecardRow(title: "Score", values: scoreValues.map { String($0) }, total: String(scoreValues.reduce(0, +)), showTotal: true, pars: parValues.map { String($0) }, isScoreRow: true, strokeHoles: strokeHoles)
        }
        .border(Color.gray, width: 1)
        .onAppear {
            print("ScorecardSection appeared for holes \(holeRange)")
            print("Par values: \(parValues)")
            print("Score values: \(scoreValues)")
        }
    }

    private var parValues: [Int] {
        let values = holeRange.map { holeNumber in
            singleRoundViewModel.holes.first(where: { $0.holeNumber == holeNumber })?.par ?? 0
        }
        print("Calculated par values for holes \(holeRange): \(values)")
        return values
    }

    private var scoreValues: [Int] {
        holeRange.map { holeNumber in
            roundViewModel.grossScores[holeNumber]?.values.first ?? 0
        }
    }

    private var strokeHoles: Set<Int> {
        Set(roundViewModel.strokeHoles.flatMap { $0.value.filter { holeRange.contains($0) } })
    }
}
