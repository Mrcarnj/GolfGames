//
//  ScorecardRow.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/31/24.
//

import SwiftUI

struct ScorecardRow: View {
    let title: String
    let values: [String]
    let total: String
    let showTotal: Bool
    let pars: [String]?
    let isScoreRow: Bool
    let strokeHoles: Set<Int>

    init(title: String, values: [String], total: String, showTotal: Bool, pars: [String]? = nil, isScoreRow: Bool = false, strokeHoles: Set<Int> = []) {
        self.title = title
        self.values = values
        self.total = total
        self.showTotal = showTotal
        self.pars = pars
        self.isScoreRow = isScoreRow
        self.strokeHoles = strokeHoles
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .frame(width: 50, alignment: .leading)
                .padding(.horizontal, 5)
                .background(Color.gray.opacity(0.2))
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                if isScoreRow, let pars = pars, let score = Int(value), let par = Int(pars[index]) {
                    ScoreCell(score: score, par: par, isStrokeHole: strokeHoles.contains(index + 1))
                } else {
                    Text(value)
                        .frame(width: 30)
                        .border(Color.gray, width: 0.5)
                }
            }
            if showTotal {
                Text(total)
                    .frame(width: 40)
                    .background(Color.gray.opacity(0.2))
            }
        }
        .frame(height: 30)
        .border(Color.gray, width: 0.5)
    }
}
