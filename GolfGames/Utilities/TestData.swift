//
//  TestData.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/6/24.
//

import SwiftUI

struct TestData: View {
    @ObservedObject var roundViewModel: RoundViewModel
    
    var body: some View {
        VStack {
            ForEach(roundViewModel.golfers) { golfer in
                Text("\(golfer.fullName) Match Play Net Score: \(getMatchPlayNetScore(for: golfer))")
            }
        }
    }
    
    private func getMatchPlayNetScore(for golfer: Golfer) -> String {
        let totalNetScore = roundViewModel.matchPlayNetScores.values.reduce(0) { total, scores in
            total + (scores[golfer.id] ?? 0)
        }
        return "\(totalNetScore)"
    }
}

#Preview {
    TestData(roundViewModel: RoundViewModel())
}
