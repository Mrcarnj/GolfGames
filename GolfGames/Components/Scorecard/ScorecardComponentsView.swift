//
//  ScorecardComponentsView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import SwiftUI

struct ScorecardComponentsView: View {
    @EnvironmentObject var viewModel: RoundViewModel
    let viewType: ScorecardViewType
    let pars: [Int: Int]

    var body: some View {
        // Front 9 pars and scores
        let front9Pars = (1...9).map { pars[$0] ?? 0 }
        let front9Scores = (1...9).map { viewModel.scores[$0] ?? 0 }
        let front9TotalPar = front9Pars.reduce(0, +)
        let front9TotalScore = front9Scores.reduce(0, +)

        // Back 9 pars and scores
        let back9Pars = (10...18).map { pars[$0] ?? 0 }
        let back9Scores = (10...18).map { viewModel.scores[$0] ?? 0 }
        let back9TotalPar = back9Pars.reduce(0, +)
        let back9TotalScore = back9Scores.reduce(0, +)

        // Total pars and scores
        let totalPar = front9TotalPar + back9TotalPar
        let totalScore = front9TotalScore + back9TotalScore

        return VStack(spacing: 0) {
            HoleRowView(holes: Array(1...9), isOut: true, hasTotalColumn: true)
            ParRowView(pars: front9Pars, totalPar: front9TotalPar, hasTotalColumn: false, totalParText: "")
            ScoreRowView(scores: front9Scores, pars: front9Pars, totalScore: front9TotalScore, totalScoreText: "", hasTotalColumn: false)
            
            if viewType == .scoreAndNet {
                NetScoreRowView(netScores: front9Scores, pars: front9Pars, totalNetScore: front9TotalScore, totalNetScoreText: "", hasTotalColumn: false) // Example net scores
            }
            
            HoleRowView(holes: Array(10...18), isOut: false, hasTotalColumn: true)
                .padding(.top)
            ParRowView(pars: back9Pars, totalPar: back9TotalPar, hasTotalColumn: true, totalParText: "\(totalPar)")
            ScoreRowView(scores: back9Scores, pars: back9Pars, totalScore: back9TotalScore, totalScoreText: "\(totalScore)", hasTotalColumn: true)
            
            if viewType == .scoreAndNet {
                NetScoreRowView(netScores: back9Scores, pars: back9Pars, totalNetScore: back9TotalScore, totalNetScoreText: "\(totalScore)", hasTotalColumn: true) // Example net scores
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ScorecardComponentsView_Previews: PreviewProvider {
    static var previews: some View {
        ScorecardComponentsView(viewType: .scoreOnly, pars: [:])
            .environmentObject(RoundViewModel())
    }
}

