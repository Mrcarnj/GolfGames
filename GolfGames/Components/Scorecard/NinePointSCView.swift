//
//  NinePointSCView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/29/24.
//

import SwiftUI

struct NinePointSCView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    
    private let nameCellWidth: CGFloat = 50
    private let scoreCellWidth: CGFloat = 36
    private let scoreCellHeight: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            mainNinePointView()
        }
        .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
    }
    
    private func mainNinePointView() -> some View {
        VStack(spacing: 0) {
            holeRow()
            parRow()
            ForEach(roundViewModel.golfers, id: \.id) { golfer in
                playerRow(for: golfer)
            }
        }
    }
    
    private func holeRow() -> some View {
        HStack(spacing: 0) {
            Text("Hole")
                .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .center)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemTeal))
            ForEach(1...9, id: \.self) { hole in
                Text("\(hole)")
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
            }
            Text("Out")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemTeal))
            ForEach(10...18, id: \.self) { hole in
                Text("\(hole)")
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
            }
            Text("In")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemTeal))
            Text("Tot")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemTeal))
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    private func parRow() -> some View {
        HStack(spacing: 0) {
            Text("Par")
                .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .center)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemTeal))
            ForEach(1...18, id: \.self) { hole in
                if hole == 10 {
                    let frontNinePar = (1...9).reduce(0) { total, h in
                        total + (singleRoundViewModel.holes.first(where: { $0.holeNumber == h })?.par ?? 0)
                    }
                    Text("\(frontNinePar)")
                        .frame(width: scoreCellWidth, height: scoreCellHeight)
                        .background(Color(UIColor.systemTeal))
                }
                if let holeData = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole }) {
                    Text("\(holeData.par)")
                        .frame(width: scoreCellWidth, height: scoreCellHeight)
                        .background(Color(UIColor.systemTeal))
                }
            }
            let backNinePar = (10...18).reduce(0) { total, h in
                total + (singleRoundViewModel.holes.first(where: { $0.holeNumber == h })?.par ?? 0)
            }
            Text("\(backNinePar)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemTeal))
            let totalPar = singleRoundViewModel.holes.reduce(0) { $0 + $1.par }
            Text("\(totalPar)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemTeal))
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    private func playerRow(for golfer: Golfer) -> some View {
        HStack(spacing: 0) {
            Text(golfer.firstName)
                .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .center)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            
            ForEach(1...18, id: \.self) { hole in
                if hole == 10 {
                    let frontNinePoints = (1...9).reduce(0) { total, h in
                        total + (roundViewModel.ninePointScores[h]?[golfer.id] ?? 0)
                    }
                    Text("\(frontNinePoints)")
                        .frame(width: scoreCellWidth, height: scoreCellHeight)
                        .background(Color(UIColor.systemGray4))
                        .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                        .fontWeight(.bold)
                }
                ninePointScoreCell(for: golfer, hole: hole)
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
            }
            
            let backNinePoints = (10...18).reduce(0) { total, hole in
                total + (roundViewModel.ninePointScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(backNinePoints)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            
            let totalPoints = (1...18).reduce(0) { total, hole in
                total + (roundViewModel.ninePointScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(totalPoints)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
        }
        .font(.caption)
    }
    
    private func ninePointScoreCell(for golfer: Golfer, hole: Int) -> some View {
        let points = roundViewModel.ninePointScores[hole]?[golfer.id] ?? 0
        
        return ZStack {
            Color.clear
            if points != 0 {
                Text("\(points)")
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .font(.subheadline)
            }
        }
        .border(Color.black, width: 1)
    }
}

struct NinePointSCView_Previews: PreviewProvider {
    static var previews: some View {
        NinePointSCView()
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
    }
}


