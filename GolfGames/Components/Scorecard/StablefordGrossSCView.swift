//
//  StablefordGrossSCView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 9/3/24.
//

import SwiftUI

struct StablefordGrossSCView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    
    private let nameCellWidth: CGFloat = 55
    private let scoreCellWidth: CGFloat = 30
    private let scoreCellHeight: CGFloat = 40
    private let totalCellWidth: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                switch roundViewModel.roundType {
                case .full18:
                    nineHoleView(holes: 1...9, title: "Out", showFirstColumn: true)
                    nineHoleView(holes: 10...18, title: "In", showTotal: true, showFirstColumn: false)
                case .front9:
                    nineHoleView(holes: 1...9, title: "Out", showTotal: true, showFirstColumn: true)
                case .back9:
                    nineHoleView(holes: 10...18, title: "In", showTotal: true, showFirstColumn: true)
                }
            }
        }
        .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
    }
    
    private func nineHoleView(holes: ClosedRange<Int>, title: String, showTotal: Bool = false, showFirstColumn: Bool) -> some View {
        VStack(spacing: 0) {
            holeRow(title: "Hole", holes: holes, total: title, showTotal: showTotal, showFirstColumn: showFirstColumn)
            parRow(holes: holes, showTotal: showTotal, showFirstColumn: showFirstColumn)
            ForEach(roundViewModel.golfers, id: \.id) { golfer in
                playerRow(for: golfer, holes: holes, showTotal: showTotal, showFirstColumn: showFirstColumn)
            }
        }
    }
    
    private func holeRow(title: String, holes: ClosedRange<Int>, total: String, showTotal: Bool, showFirstColumn: Bool) -> some View {
        HStack(spacing: 0) {
            if showFirstColumn {
                Text(title)
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .center)
                    .padding(.horizontal, 2)
                    .background(Color(UIColor.systemTeal))
            }
            ForEach(holes, id: \.self) { hole in
                Text("\(hole)")
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
            }
            Text(total)
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemTeal))
            if showTotal {
                Text("Tot")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
                Text("Quota")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
                Text("Diff")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
            }
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    private func parRow(holes: ClosedRange<Int>, showTotal: Bool, showFirstColumn: Bool) -> some View {
        HStack(spacing: 0) {
            if showFirstColumn {
                Text("Par")
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .center)
                    .padding(.horizontal, 2)
                    .background(Color(UIColor.systemTeal))
            }
            ForEach(holes, id: \.self) { hole in
                if let holeData = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole }) {
                    Text("\(holeData.par)")
                        .frame(width: scoreCellWidth, height: scoreCellHeight)
                        .background(Color(UIColor.systemTeal))
                }
            }
            let totalPar = singleRoundViewModel.holes.filter { holes.contains($0.holeNumber) }.reduce(0) { $0 + $1.par }
            Text("\(totalPar)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemTeal))
            if showTotal {
                let grandTotalPar = singleRoundViewModel.holes.reduce(0) { $0 + $1.par }
                Text("\(grandTotalPar)")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
                Text("")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
                Text("")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
            }
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    private func playerRow(for golfer: Golfer, holes: ClosedRange<Int>, showTotal: Bool, showFirstColumn: Bool) -> some View {
        HStack(spacing: 0) {
            if showFirstColumn {
                Text(golfer.formattedName(golfers: roundViewModel.golfers))
                    .fontWeight(.semibold)
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .center)
                    .padding(.horizontal, 2)
                    .background(Color(UIColor.systemGray4))
            }
            ForEach(holes, id: \.self) { hole in
                if let points = roundViewModel.stablefordGrossScores[hole]?[golfer.id] {
                    Text("\(points)")
                        .frame(width: scoreCellWidth, height: scoreCellHeight)
                        .background(Color(.clear))
                        .foregroundColor(colorScheme == .light ? .black : .white)
                } else {
                    Text("")
                        .frame(width: scoreCellWidth, height: scoreCellHeight)
                        .background(Color(.clear))
                }
            }
            let totalPoints = holes.reduce(0) { total, hole in
                total + (roundViewModel.stablefordGrossScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(totalPoints)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemGray4))
                .fontWeight(.bold)
            if showTotal {
                let grandTotalPoints = roundViewModel.stablefordGrossTotalScores[golfer.id] ?? 0
                Text("\(grandTotalPoints)")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemGray4))
                    .fontWeight(.bold)
                let quota = roundViewModel.stablefordGrossQuotas[golfer.id] ?? 0
                Text("\(quota)")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemGray4))
                    .fontWeight(.bold)
                let diff = grandTotalPoints - quota
                Text("\(diff > 0 ? "+" : "")\(diff)")
                    .frame(width: totalCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(diff >= 0 ? .green : .red)
                    .fontWeight(.bold)
            }
        }
        .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
        .font(.caption)
    }
}

struct StablefordGrossSCView_Previews: PreviewProvider {
    static var previews: some View {
        StablefordGrossSCView()
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
    }
}
