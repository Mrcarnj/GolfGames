
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
        mainContent
            .background(colorScheme == .light ? Color.white : Color.black)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal, 10)
            .onChange(of: roundViewModel.matchStatusArray) { _ in
                matchStatusUpdateTrigger.toggle()
            }
            .id(matchStatusUpdateTrigger)
            .padding(10)  // Add padding around the entire content
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)  // Add corner radius to match the rounded edges
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            if let (golfer1, golfer2) = roundViewModel.matchPlayGolfers {
                mainMatchResultSummary()
                mainMatchView(golfer1: golfer1, golfer2: golfer2)
                pressesView(golfer1: golfer1, golfer2: golfer2)
            } else {
                Text("Match play not enabled")
            }
        }
    }
    
    private func mainMatchView(golfer1: Golfer, golfer2: Golfer) -> some View {
        switch roundViewModel.roundType {
        case .full18:
            return AnyView(
                HStack(spacing: 0) {
                    nineHoleView(holes: 1...9, golfer1: golfer1, golfer2: golfer2, title: "Out", showLabels: true)
                    nineHoleView(holes: 10...18, golfer1: golfer1, golfer2: golfer2, title: "In", showTotal: true, showLabels: false)
                }
            )
        case .front9:
            return AnyView(
                nineHoleView(holes: 1...9, golfer1: golfer1, golfer2: golfer2, title: "Out", showTotal: true, showLabels: true)
            )
        case .back9:
            return AnyView(
                nineHoleView(holes: 10...18, golfer1: golfer1, golfer2: golfer2, title: "In", showTotal: true, showLabels: true)
            )
        }
    }
    
    private func pressesView(golfer1: Golfer, golfer2: Golfer) -> some View {
        ForEach(roundViewModel.presses.indices, id: \.self) { index in
            VStack(spacing: 4) {
                pressMatchResultSummary(pressIndex: index)
                Text("Started at hole \(roundViewModel.presses[index].startHole)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                pressMatchView(golfer1: golfer1, golfer2: golfer2, pressIndex: index)
            }
            .padding(.top, 16)
        }
    }
    
    private func pressMatchView(golfer1: Golfer, golfer2: Golfer, pressIndex: Int) -> some View {
        switch roundViewModel.roundType {
        case .full18:
            return AnyView(
                HStack(spacing: 0) {
                    nineHoleView(holes: 1...9, golfer1: golfer1, golfer2: golfer2, title: "Out", showLabels: true, pressIndex: pressIndex)
                    nineHoleView(holes: 10...18, golfer1: golfer1, golfer2: golfer2, title: "In", showTotal: true, showLabels: false, pressIndex: pressIndex)
                }
            )
        case .front9:
            return AnyView(
                nineHoleView(holes: 1...9, golfer1: golfer1, golfer2: golfer2, title: "Out", showTotal: true, showLabels: true, pressIndex: pressIndex)
            )
        case .back9:
            return AnyView(
                nineHoleView(holes: 10...18, golfer1: golfer1, golfer2: golfer2, title: "In", showTotal: true, showLabels: true, pressIndex: pressIndex)
            )
        }
    }
    
    private func mainMatchResultSummary() -> some View {
        Group {
            if let winner = roundViewModel.matchWinner, let score = roundViewModel.winningScore {
                Text("\(winner) won \(score)")
            } else if let (golfer1, golfer2) = roundViewModel.matchPlayGolfers {
                Text("\(golfer1.firstName) \(golfer1.lastName) vs \(golfer2.firstName) \(golfer2.lastName)")
            } else {
                Text("Match play not set up")
            }
        }
        .padding(.vertical, 8)
        .foregroundColor(.primary)
        .font(.headline)
    }
    
    private func pressMatchResultSummary(pressIndex: Int) -> some View {
        Group {
            if let (golfer1, golfer2) = roundViewModel.matchPlayGolfers {
                let press = roundViewModel.presses[pressIndex]
                if let winner = press.winner, let score = press.winningScore {
                    Text("Press \(pressIndex + 1): \(winner) won \(score)")
                } else {
                    let pressStatus = press.matchStatusArray.reduce(0, +)
                    if pressStatus == 0 {
                        Text("Press \(pressIndex + 1): All Square")
                    } else {
                        let leadingGolfer = pressStatus > 0 ? golfer1 : golfer2
                        let leadAmount = abs(pressStatus)
                        Text("Press \(pressIndex + 1): \(leadingGolfer.firstName) \(leadingGolfer.lastName) \(leadAmount) UP")
                    }
                }
            } else {
                Text("Press \(pressIndex + 1) in progress")
            }
        }
        .font(.subheadline)
        .foregroundColor(.primary)
    }
    
    func nineHoleView(holes: ClosedRange<Int>, golfer1: Golfer, golfer2: Golfer, title: String, showTotal: Bool = false, showLabels: Bool = true, pressIndex: Int? = nil) -> some View {
        VStack(spacing: 0) {
            holeRow(title: "Hole", holes: holes, total: title, showTotal: showTotal, showLabel: showLabels)
            parRow(holes: holes, showTotal: showTotal, showLabel: showLabels)
            playerRow(for: golfer1, holes: holes, showTotal: showTotal, showLabel: showLabels)
            matchStatusRow(for: golfer1, holes: holes, showTotal: showTotal, showLabel: showLabels, pressIndex: pressIndex)
            playerRow(for: golfer2, holes: holes, showTotal: showTotal, showLabel: showLabels)
            matchStatusRow(for: golfer2, holes: holes, showTotal: showTotal, showLabel: showLabels, pressIndex: pressIndex)
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
                Text("\(golfer.firstName) \(golfer.lastName.prefix(1)).")
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
    
    func matchStatusRow(for golfer: Golfer, holes: ClosedRange<Int>, showTotal: Bool = false, showLabel: Bool = true, pressIndex: Int? = nil) -> some View {
        HStack(spacing: 0) {
            if showLabel {
                Group {
                    if let index = pressIndex {
                        Text("Press \(index + 1)")
                    } else {
                        Text("Match")
                    }
                }
                .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            }
            
            ForEach(holes, id: \.self) { hole in
                matchStatusCell(for: golfer, hole: hole, pressIndex: pressIndex)
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
    
    func matchStatusCell(for golfer: Golfer, hole: Int, pressIndex: Int? = nil) -> some View {
        if let pressIndex = pressIndex {
            return AnyView(pressMatchStatusCell(for: golfer, hole: hole, pressIndex: pressIndex))
        } else {
            return AnyView(mainMatchStatusCell(for: golfer, hole: hole))
        }
    }

    private func mainMatchStatusCell(for golfer: Golfer, hole: Int) -> some View {
        let statusArray = roundViewModel.finalMatchStatusArray ?? roundViewModel.matchStatusArray
        let winningHole = roundViewModel.matchWinningHole
        let startingHole = MatchPlayModel.getStartingHole(for: roundViewModel.roundType)
        let lastHole = MatchPlayModel.getLastHole(for: roundViewModel.roundType)
        
        return Group {
            if hole >= startingHole && hole <= lastHole {
                if let winningHole = winningHole, hole > winningHole {
                    Color.clear
                } else if hole == winningHole, let winner = roundViewModel.matchWinner, let score = roundViewModel.winningScore, golfer.formattedName(golfers: roundViewModel.golfers) == winner {
                    Text(formatFinalScore(score))
                        .font(.caption)
                        .foregroundColor(.red)
                } else {
                    displayMatchStatus(for: golfer, hole: hole, startingHole: startingHole, statusArray: statusArray, currentHole: roundViewModel.currentHole)
                }
            } else {
                Color.clear
            }
        }
        .frame(width: scoreCellWidth, height: scoreCellHeight)
        .background(Color(UIColor.systemGray4))
        .border(Color.black, width: 1)
    }

    private func pressMatchStatusCell(for golfer: Golfer, hole: Int, pressIndex: Int) -> some View {
        let press = roundViewModel.presses[pressIndex]
        let statusArray = press.matchStatusArray
        let startHole = press.startHole
        let winningHole = press.winningHole
        let startingHole = MatchPlayModel.getStartingHole(for: roundViewModel.roundType)
        let lastHole = MatchPlayModel.getLastHole(for: roundViewModel.roundType)
        
        return Group {
            if hole >= max(startHole, startingHole) && hole <= lastHole {
                if let winningHole = winningHole, hole > winningHole {
                    Color.clear
                } else if hole == winningHole, let winner = press.winner, let score = press.winningScore, golfer.formattedName(golfers: roundViewModel.golfers) == winner {
                    Text(formatFinalScore(score))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                } else {
                    displayMatchStatus(for: golfer, hole: hole, startingHole: startingHole, statusArray: statusArray, currentHole: roundViewModel.currentHole)
                }
            } else {
                Color.clear
            }
        }
        .frame(width: scoreCellWidth, height: scoreCellHeight)
        .background(Color(UIColor.systemGray4))
        .border(Color.black, width: 1)
    }

    private func displayMatchStatus(for golfer: Golfer, hole: Int, startingHole: Int, statusArray: [Int], currentHole: Int) -> some View {
        let adjustedHoleIndex = hole - startingHole
        
        guard adjustedHoleIndex >= 0 && adjustedHoleIndex < statusArray.count && hole <= currentHole else {
            return AnyView(Color.clear)
        }
        
        let cumulativeStatus = statusArray[0...adjustedHoleIndex].reduce(0, +)
        let absStatus = abs(cumulativeStatus)
        let isFirstGolfer = golfer.id == roundViewModel.matchPlayGolfers?.0.id
        
        return AnyView(Group {
            if adjustedHoleIndex == 0 && statusArray[adjustedHoleIndex] == 0 {
                Text("AS")
            } else if cumulativeStatus == 0 && isFirstGolfer {
                Text("AS")
            } else if (cumulativeStatus > 0 && isFirstGolfer) || (cumulativeStatus < 0 && !isFirstGolfer) {
                HStack(spacing: 2) {
                    Text("\(absStatus)")
                    Image(systemName: "arrow.up")
                }
            } else {
                Color.clear
            }
        })
    }

    private func formatFinalScore(_ score: String) -> String {
        if score.hasSuffix("&0") {
            return score.replacingOccurrences(of: "&0", with: "UP")
        }
        return score
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
