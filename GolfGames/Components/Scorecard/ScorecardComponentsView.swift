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
        // Front 9 pars, scores, and net scores
        let front9Pars = (1...9).map { pars[$0] ?? 0 }
        let front9Scores = (1...9).map { viewModel.scores[$0] ?? 0 }
        let front9NetScores = (1...9).map { viewModel.netScores[$0] ?? 0 }
        let front9TotalPar = front9Pars.reduce(0, +)
        let front9TotalScore = front9Scores.reduce(0, +)
        let front9TotalNetScore = front9NetScores.reduce(0, +)

        // Back 9 pars, scores, and net scores
        let back9Pars = (10...18).map { pars[$0] ?? 0 }
        let back9Scores = (10...18).map { viewModel.scores[$0] ?? 0 }
        let back9NetScores = (10...18).map { viewModel.netScores[$0] ?? 0 }
        let back9TotalPar = back9Pars.reduce(0, +)
        let back9TotalScore = back9Scores.reduce(0, +)
        let back9TotalNetScore = back9NetScores.reduce(0, +)

        // Total pars and scores
        let totalPar = front9TotalPar + back9TotalPar
        let totalScore = front9TotalScore + back9TotalScore
        let totalNetScore = front9TotalNetScore + back9TotalNetScore

        return VStack(spacing: 0) {
            HoleRowView(holes: Array(1...9), isOut: true, hasTotalColumn: true)
            ParRowView(pars: front9Pars, totalPar: front9TotalPar, hasTotalColumn: false, totalParText: "")
            // Updated to filter stroke holes for the front 9
            ScoreRowView(scores: front9Scores, pars: front9Pars, totalScore: front9TotalScore, totalScoreText: "", hasTotalColumn: false, strokeHoles: viewModel.strokeHoles.filter { $0 <= 9 })
            
            if viewType == .scoreAndNet {
                NetScoreRowView(netScores: front9NetScores, pars: front9Pars, totalNetScore: front9TotalNetScore, totalNetScoreText: "", hasTotalColumn: false)
            }
            
            HoleRowView(holes: Array(10...18), isOut: false, hasTotalColumn: true)
                .padding(.top)
            ParRowView(pars: back9Pars, totalPar: back9TotalPar, hasTotalColumn: true, totalParText: "\(totalPar)")
            // Updated to filter stroke holes for the back 9
            ScoreRowView(scores: back9Scores, pars: back9Pars, totalScore: back9TotalScore, totalScoreText: "\(totalScore)", hasTotalColumn: true, strokeHoles: viewModel.strokeHoles.filter { $0 > 9 })
            
            if viewType == .scoreAndNet {
                NetScoreRowView(netScores: back9NetScores, pars: back9Pars, totalNetScore: back9TotalNetScore, totalNetScoreText: "\(totalNetScore)", hasTotalColumn: true)
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
