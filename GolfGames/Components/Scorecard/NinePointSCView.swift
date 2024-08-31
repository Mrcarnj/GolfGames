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
            HStack(spacing: 0) {
                switch roundViewModel.roundType {
                case .full18:
                    nineHoleView(holes: 1...9, title: "Out", showFirstColumn: true)
                    nineHoleView(holes: 10...18, title: "In", showTotal: true, showFirstColumn: false)
                case .front9:
                    nineHoleView(holes: 1...9, title: "Out", showTotal: false, showFirstColumn: true)
                case .back9:
                    nineHoleView(holes: 10...18, title: "In", showTotal: false, showFirstColumn: true)
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
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
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
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemTeal))
            }
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    private func playerRow(for golfer: Golfer, holes: ClosedRange<Int>, showTotal: Bool, showFirstColumn: Bool) -> some View {
        HStack(spacing: 0) {
            if showFirstColumn {
                Text(golfer.firstName)
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .center)
                    .padding(.horizontal, 2)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            }
            ForEach(holes, id: \.self) { hole in
                ninePointScoreCell(for: golfer, hole: hole)
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
            }
            let totalPoints = holes.reduce(0) { total, hole in
                total + (roundViewModel.ninePointScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(totalPoints)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            if showTotal {
                let grandTotal = (1...18).reduce(0) { total, hole in
                    total + (roundViewModel.ninePointScores[hole]?[golfer.id] ?? 0)
                }
                Text("\(grandTotal)")
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            }
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


