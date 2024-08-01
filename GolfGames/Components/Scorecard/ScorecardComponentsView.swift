//
//  ScorecardComponentsView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import SwiftUI

struct ScorecardComponentsView: View {
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    let viewType: ScorecardViewType

    var body: some View {
        VStack(spacing: 10) {
            ScorecardSection(holeRange: 1...9, isOut: true)
            ScorecardSection(holeRange: 10...18, isOut: false)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
        .onAppear {
            print("ScorecardComponentsView appeared")
            print("Number of holes in singleRoundViewModel: \(singleRoundViewModel.holes.count)")
            print("Holes: \(singleRoundViewModel.holes.map { "Hole \($0.holeNumber): Par \($0.par)" }.joined(separator: ", "))")
        }
    }
}


struct ScorecardComponentsView_Previews: PreviewProvider {
    static var previews: some View {
        ScorecardComponentsView(viewType: .scoreOnly)
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
    }
}
