//
//  MatchPlaySCView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/6/24.
//

import SwiftUI
import Firebase

struct MatchPlaySCView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var matchStatusUpdateTrigger = false
    
    private var isLandscape: Bool {
        return orientation.isLandscape
    }
    
    private let nameCellWidth: CGFloat = 70
    private let scoreCellWidth: CGFloat = 30
    private let scoreCellHeight: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 0) {
            if let (golfer1, golfer2) = roundViewModel.matchPlayGolfers {
                matchResultSummary()
                    .padding(.vertical, 8)
                    .foregroundColor(.primary)
                    .font(.headline)
                HStack(spacing: 0) {
                    nineHoleView(holes: 1...9, golfer1: golfer1, golfer2: golfer2, title: "Out", showLabels: true)
                    nineHoleView(holes: 10...18, golfer1: golfer1, golfer2: golfer2, title: "In", showTotal: true, showLabels: false)
                }
            } else {
                Text("Match play golfers not selected")
            }
        }
        .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
        .onChange(of: roundViewModel.matchStatusArray) { _ in
            matchStatusUpdateTrigger.toggle()
        }
        .id(matchStatusUpdateTrigger)
    }
    
    func nineHoleView(holes: ClosedRange<Int>, golfer1: Golfer, golfer2: Golfer, title: String, showTotal: Bool = false, showLabels: Bool = true) -> some View {
        VStack(spacing: 0) {
            holeRow(title: "Hole", holes: holes, total: title, showTotal: showTotal, showLabel: showLabels)
            parRow(holes: holes, showTotal: showTotal, showLabel: showLabels)
            playerRow(for: golfer1, holes: holes, showTotal: showTotal, showLabel: showLabels)
            matchStatusRow(for: golfer1, holes: holes, showTotal: showTotal, showLabel: showLabels)
            playerRow(for: golfer2, holes: holes, showTotal: showTotal, showLabel: showLabels)
            matchStatusRow(for: golfer2, holes: holes, showTotal: showTotal, showLabel: showLabels)
        }
    }
    
    func holeRow(title: String, holes: ClosedRange<Int>, total: String, showTotal: Bool = false, showLabel: Bool = true) -> some View {
        HStack(spacing: 0) {
            if showLabel {
                Text(title)
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .leading)
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
    
    func parRow(holes: ClosedRange<Int>, showTotal: Bool = false, showLabel: Bool = true) -> some View {
        HStack(spacing: 0) {
            if showLabel {
                Text("Par")
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .leading)
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

    func playerRow(for golfer: Golfer, holes: ClosedRange<Int>, showTotal: Bool = false, showLabel: Bool = true) -> some View {
        HStack(spacing: 0) {
            if showLabel {
                Text(golfer.firstName)
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .leading)
                    .padding(.horizontal, 2)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            }
            ForEach(holes, id: \.self) { hole in
                scoreCell(for: golfer, hole: hole)
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
            }
            let totalGrossScore = holes.reduce(0) { total, hole in
                total + (roundViewModel.grossScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(totalGrossScore)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            if showTotal {
                let grandTotalGrossScore = singleRoundViewModel.holes.reduce(0) { total, hole in
                    total + (roundViewModel.grossScores[hole.holeNumber]?[golfer.id] ?? 0)
                }
                Text("\(grandTotalGrossScore)")
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            }
        }
        .font(.caption)
    }    
    
    func scoreCell(for golfer: Golfer, hole: Int) -> some View {
        let par = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole })?.par ?? 0
        let grossScore = roundViewModel.grossScores[hole]?[golfer.id] ?? 0
        let isMatchPlayStrokeHole = roundViewModel.matchPlayStrokeHoles[golfer.id]?.contains(hole) ?? false
        
        return ZStack {
            scoreCellBackground(score: grossScore, par: par)
            
            if grossScore != 0 {
                Text("\(grossScore)")
                    .foregroundColor(scoreCellTextColor(score: grossScore, par: par))
                    .font(.subheadline)
            }
            
            if isMatchPlayStrokeHole {
                Circle()
                    .fill(strokeDotColor(score: grossScore, par: par))
                    .frame(width: 6, height: 6)
                    .offset(x: 7, y: -7)
            }
        }
    }
    
    func strokeDotColor(score: Int, par: Int) -> Color {
        if score == par + 1 {
            return .white
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    func scoreCellBackground(score: Int, par: Int) -> some View {
        Group {
            if score == 0 {
                Color.clear
            } else if score <= par - 2 {
                Circle().fill(Color.yellow)
            } else if score == par - 1 {
                Circle().fill(Color.red)
            } else if score == par + 1 {
                Rectangle().fill(Color.black)
                    .if(colorScheme == .dark) { view in
                        view.overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                    }
            } else if score >= par + 2 {
                Rectangle().fill(Color.blue)
            } else {
                Color.clear
            }
        }
    }
    
    func scoreCellTextColor(score: Int, par: Int) -> Color {
        if score == 0 {
            return .clear
        } else if score <= par - 1 || score >= par + 1 {
            return .white
        } else {
            return colorScheme == .light ? .black : .white
        }
    }
    
    func matchStatusRow(for golfer: Golfer, holes: ClosedRange<Int>, showTotal: Bool = false, showLabel: Bool = true) -> some View {
        HStack(spacing: 0) {
            if showLabel {
                Text("Match")
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .leading)
                    .padding(.horizontal, 2)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            }
            
            ForEach(holes, id: \.self) { hole in
                matchStatusCell(for: golfer, hole: hole)
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
            }
            
            Color(UIColor.systemGray4)
                .frame(width: scoreCellWidth, height: scoreCellHeight)
            
            if showTotal {
                Color(UIColor.systemGray4)
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
            }
        }
        .font(.caption)
    }
    
    func matchStatusCell(for golfer: Golfer, hole: Int) -> some View {
        let statusArray = roundViewModel.finalMatchStatusArray ?? roundViewModel.matchStatusArray
        let cumulativeStatus = statusArray[0..<hole].reduce(0, +)
        let absStatus = abs(cumulativeStatus)
        let isFirstGolfer = golfer.id == roundViewModel.matchPlayGolfers?.0.id

        return Group {
            if let winningHole = roundViewModel.matchWinningHole {
                if hole < winningHole {
                    displayMatchStatus(cumulativeStatus: cumulativeStatus, absStatus: absStatus, isFirstGolfer: isFirstGolfer)
                } else if hole == winningHole {
                    Text(roundViewModel.winningScore ?? "")
                        .font(.caption)
                } else {
                    Color.clear
                }
            } else if hole <= roundViewModel.holesPlayed {
                displayMatchStatus(cumulativeStatus: cumulativeStatus, absStatus: absStatus, isFirstGolfer: isFirstGolfer)
            } else {
                Color.clear
            }
        }
        .frame(width: scoreCellWidth, height: scoreCellHeight)
        .background(Color(UIColor.systemGray4))
        .border(Color.black, width: 1)
    }
    
    private func displayMatchStatus(cumulativeStatus: Int, absStatus: Int, isFirstGolfer: Bool) -> some View {
        Group {
            if cumulativeStatus == 0 && isFirstGolfer {
                Text("AS")
            } else if (cumulativeStatus > 0 && isFirstGolfer) || (cumulativeStatus < 0 && !isFirstGolfer) {
                HStack(spacing: 2) {
                    Text("\(absStatus)")
                    Image(systemName: "arrow.up")
                }
            } else {
                Color.clear
            }
        }
    }

    private func matchResultSummary() -> some View {
        Group {
            if let winner = roundViewModel.matchWinner, let score = roundViewModel.winningScore {
                Text("\(winner) won \(score)")
            } else if let (golfer1, golfer2) = roundViewModel.matchPlayGolfers {
                Text("\(golfer1.fullName) vs \(golfer2.fullName)")
            } else {
                Text("Match play not set up")
            }
        }
    }
}

struct MatchPlaySCView_Previews: PreviewProvider {
    static var previews: some View {
        MatchPlaySCView()
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
            .environmentObject(AuthViewModel())
    }
}

extension Golfer {
    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }
}