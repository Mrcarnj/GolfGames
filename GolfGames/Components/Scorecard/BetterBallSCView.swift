//
//  BetterBallSCView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/24/24.
//

import SwiftUI
import Firebase

struct BetterBallSCView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var matchStatusUpdateTrigger = false
    @State private var scorecardUpdateTrigger = UUID()
    
    private let nameCellWidth: CGFloat = 70
    private let scoreCellWidth: CGFloat = 30
    private let scoreCellHeight: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 0) {
            if roundViewModel.isBetterBall {
                mainMatchResultSummary()
                mainMatchView()
                let teamA = roundViewModel.golfers.filter { roundViewModel.betterBallTeamAssignments[$0.id] == "Team A" }
                let teamB = roundViewModel.golfers.filter { roundViewModel.betterBallTeamAssignments[$0.id] == "Team B" }
                pressesView(teamA: teamA, teamB: teamB)
            } else {
                Text("Better Ball match not enabled")
            }
        }
        .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
        .onChange(of: roundViewModel.betterBallMatchArray) { _ in
            scorecardUpdateTrigger = UUID()
        }
        .onChange(of: roundViewModel.betterBallPressesUpdateTrigger) { _ in
            scorecardUpdateTrigger = UUID()
        }
        .id(scorecardUpdateTrigger)
    }
    
    private func mainMatchResultSummary() -> some View {
    Group {
        if let winner = roundViewModel.betterBallMatchWinner, let score = roundViewModel.betterBallWinningScore {
            Text("\(winner) won \(score)")
        } else if let status = roundViewModel.betterBallMatchStatus {
            Text(status)
        } else {
            let teamA = roundViewModel.golfers.filter { roundViewModel.betterBallTeamAssignments[$0.id] == "Team A" }
            let teamB = roundViewModel.golfers.filter { roundViewModel.betterBallTeamAssignments[$0.id] == "Team B" }
            Text("Team A (\(teamA.map { $0.firstName }.joined(separator: "/"))) vs Team B (\(teamB.map { $0.firstName }.joined(separator: "/")))")
        }
    }
    .padding(.vertical, 8)
    .foregroundColor(.primary)
    .font(.headline)
}
    
    private func mainMatchView() -> some View {
        let teamA = roundViewModel.golfers.filter { roundViewModel.betterBallTeamAssignments[$0.id] == "Team A" }
        let teamB = roundViewModel.golfers.filter { roundViewModel.betterBallTeamAssignments[$0.id] == "Team B" }
        
        switch roundViewModel.roundType {
        case .full18:
            return AnyView(
                HStack(spacing: 0) {
                    nineHoleView(holes: 1...9, teamA: teamA, teamB: teamB, title: "Out", showLabels: true)
                    nineHoleView(holes: 10...18, teamA: teamA, teamB: teamB, title: "In", showTotal: true, showLabels: false)
                }
            )
        case .front9:
            return AnyView(
                nineHoleView(holes: 1...9, teamA: teamA, teamB: teamB, title: "Out", showTotal: true, showLabels: true)
            )
        case .back9:
            return AnyView(
                nineHoleView(holes: 10...18, teamA: teamA, teamB: teamB, title: "In", showTotal: true, showLabels: true)
            )
        }
    }

    private func pressesView(teamA: [Golfer], teamB: [Golfer]) -> some View {
        ForEach(roundViewModel.betterBallPresses.indices, id: \.self) { index in
            VStack(spacing: 4) {
                pressMatchResultSummary(pressIndex: index)
                Text("Started at hole \(roundViewModel.betterBallPresses[index].startHole)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                pressMatchView(teamA: teamA, teamB: teamB, pressIndex: index)
            }
            .padding(.top, 16)
        }
    }

    private func pressMatchView(teamA: [Golfer], teamB: [Golfer], pressIndex: Int) -> some View {
        switch roundViewModel.roundType {
        case .full18:
            return AnyView(
                HStack(spacing: 0) {
                    nineHoleView(holes: 1...9, teamA: teamA, teamB: teamB, title: "Out", showLabels: true, pressIndex: pressIndex)
                    nineHoleView(holes: 10...18, teamA: teamA, teamB: teamB, title: "In", showTotal: true, showLabels: false, pressIndex: pressIndex)
                }
            )
        case .front9:
            return AnyView(
                nineHoleView(holes: 1...9, teamA: teamA, teamB: teamB, title: "Out", showTotal: true, showLabels: true, pressIndex: pressIndex)
            )
        case .back9:
            return AnyView(
                nineHoleView(holes: 10...18, teamA: teamA, teamB: teamB, title: "In", showTotal: true, showLabels: true, pressIndex: pressIndex)
            )
        }
    }

    private func nineHoleView(holes: ClosedRange<Int>, teamA: [Golfer], teamB: [Golfer], title: String, showTotal: Bool = false, showLabels: Bool = true, pressIndex: Int? = nil) -> some View {
    VStack(spacing: 0) {
        holeRow(title: "Hole", holes: holes, total: title, showTotal: showTotal, showLabel: showLabels)
        parRow(holes: holes, showTotal: showTotal, showLabel: showLabels)
        teamRow(for: teamA, team: "A", holes: holes, showTotal: showTotal, showLabel: showLabels)
        matchStatusRow(for: "A", holes: holes, showTotal: showTotal, showLabel: showLabels, pressIndex: pressIndex)
        teamRow(for: teamB, team: "B", holes: holes, showTotal: showTotal, showLabel: showLabels)
        matchStatusRow(for: "B", holes: holes, showTotal: showTotal, showLabel: showLabels, pressIndex: pressIndex)
    }
}
    
    private func teamRow(for team: [Golfer], team teamName: String, holes: ClosedRange<Int>, showTotal: Bool, showLabel: Bool) -> some View {
        HStack(spacing: 0) {
            if showLabel {
                Text("Team \(teamName)")
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .leading)
                    .padding(.horizontal, 2)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            }
            ForEach(holes, id: \.self) { hole in
                teamScoreCell(for: team, hole: hole)
            }
            totalScoreCell(for: team, holes: holes)
            if showTotal {
                grandTotalScoreCell(for: team)
            }
        }
        .font(.caption)
    }
    
    private func teamScoreCell(for team: [Golfer], hole: Int) -> some View {
        let par = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole })?.par ?? 0
        let teamScore = team.compactMap { golfer in
            roundViewModel.betterBallNetScores[hole]?[golfer.id]
        }.min() ?? 0

        return ZStack {
            scoreCellBackground(score: teamScore, par: par)
            if teamScore != 0 {
                Text("\(teamScore)")
                    .foregroundColor(scoreCellTextColor(score: teamScore, par: par))
                    .font(.subheadline)
            }
        }
        .frame(width: scoreCellWidth, height: scoreCellHeight)
    }
    
    private func totalScoreCell(for team: [Golfer], holes: ClosedRange<Int>) -> some View {
        let totalTeamScore = holes.reduce(0) { total, hole in
            total + (team.compactMap { roundViewModel.betterBallNetScores[hole]?[$0.id] }.min() ?? 0)
        }
        return Text("\(totalTeamScore)")
            .frame(width: scoreCellWidth, height: scoreCellHeight)
            .background(Color(UIColor.systemGray4))
            .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
            .fontWeight(.bold)
    }
    
    private func grandTotalScoreCell(for team: [Golfer]) -> some View {
        let grandTotalTeamScore = singleRoundViewModel.holes.reduce(0) { total, hole in
            total + (team.compactMap { roundViewModel.betterBallNetScores[hole.holeNumber]?[$0.id] }.min() ?? 0)
        }
        return Text("\(grandTotalTeamScore)")
            .frame(width: scoreCellWidth, height: scoreCellHeight)
            .background(Color(UIColor.systemGray4))
            .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
            .fontWeight(.bold)
    }
    
    private func matchStatusRow(for team: String, holes: ClosedRange<Int>, showTotal: Bool, showLabel: Bool, pressIndex: Int? = nil) -> some View {
    HStack(spacing: 0) {
        if showLabel {
            Text(pressIndex == nil ? "Match" : "Press \(pressIndex! + 1)")
                .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
        }
        ForEach(holes, id: \.self) { hole in
            if let pressIndex = pressIndex {
                pressMatchStatusCell(for: team, hole: hole, pressIndex: pressIndex)
            } else {
                mainMatchStatusCell(for: team, hole: hole)
            }
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
    private func pressMatchResultSummary(pressIndex: Int) -> some View {
    Group {
        let press = roundViewModel.betterBallPresses[pressIndex]
        if let winner = press.winner, let score = press.winningScore {
            Text("Press \(pressIndex + 1): \(winner) won \(score)")
        } else {
            let pressStatus = press.matchStatusArray.reduce(0, +)
            if pressStatus == 0 {
                Text("Press \(pressIndex + 1): All Square")
            } else {
                let leadingTeam = pressStatus > 0 ? "Team A" : "Team B"
                let leadAmount = abs(pressStatus)
                Text("Press \(pressIndex + 1): \(leadingTeam) \(leadAmount) UP")
            }
        }
    }
    .font(.subheadline)
    .foregroundColor(.primary)
}

private func matchStatusCell(for team: String, hole: Int, pressIndex: Int? = nil) -> some View {
    if let pressIndex = pressIndex {
        return AnyView(pressMatchStatusCell(for: team, hole: hole, pressIndex: pressIndex))
    } else {
        return AnyView(mainMatchStatusCell(for: team, hole: hole))
    }
}

    private func mainMatchStatusCell(for team: String, hole: Int) -> some View {
    let statusArray = roundViewModel.betterBallMatchArray
    let winningHole = roundViewModel.betterBallMatchWinningHole
    let relevantHolesPlayed = roundViewModel.currentHole
    let startingHole = BetterBallModel.getStartingHole(for: roundViewModel.roundType)
    
    return Group {
        if hole >= startingHole && hole <= relevantHolesPlayed {
            if let winningHole = winningHole, hole > winningHole {
                Color.clear
            } else if hole == winningHole, let winner = roundViewModel.betterBallMatchWinner, let score = roundViewModel.betterBallWinningScore, winner == "Team \(team)" {
                Text(score)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                displayMatchStatus(for: team, hole: hole, startHole: startingHole, statusArray: statusArray)
            }
        } else {
            Color.clear
        }
    }
    .frame(width: scoreCellWidth, height: scoreCellHeight)
    .background(Color(UIColor.systemGray4))
    .border(Color.black, width: 1)
}
    
    private func displayMatchStatus(for team: String, hole: Int, startHole: Int, statusArray: [Int]) -> some View {
        let cumulativeStatus = statusArray[0..<(hole - startHole + 1)].reduce(0, +)
        let absStatus = abs(cumulativeStatus)
        let isTeamA = team == "A"
        
        return Group {
            if hole == startHole && statusArray[hole - startHole] == 0 {
                Text("AS")
            } else if cumulativeStatus == 0 && isTeamA {
                Text("AS")
            } else if (cumulativeStatus > 0 && isTeamA) || (cumulativeStatus < 0 && !isTeamA) {
                HStack(spacing: 2) {
                    Text("\(absStatus)")
                    Image(systemName: "arrow.up")
                }
            } else {
                Color.clear
            }
        }
    }
    
    private func holeRow(title: String, holes: ClosedRange<Int>, total: String, showTotal: Bool, showLabel: Bool) -> some View {
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
    
    private func parRow(holes: ClosedRange<Int>, showTotal: Bool, showLabel: Bool) -> some View {
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

    private func pressMatchStatusCell(for team: String, hole: Int, pressIndex: Int) -> some View {
    let press = roundViewModel.betterBallPresses[pressIndex]
    let statusArray = press.matchStatusArray
    let startHole = press.startHole
    let winningHole = press.winningHole
    
    // Calculate the last relevant hole for this press
    let lastRelevantHole = max((statusArray.lastIndex(where: { $0 != 0 }) ?? -1) + startHole, roundViewModel.currentHole)
    
    return Group {
        if hole >= startHole && hole <= lastRelevantHole {
            if let winningHole = winningHole, hole > winningHole {
                Color.clear
            } else if hole == winningHole, let winner = press.winner, let score = press.winningScore, winner == "Team \(team)" {
                Text(BetterBallModel.formatBetterBallWinningScore(score))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            } else {
                displayMatchStatus(for: team, hole: hole, startHole: startHole, statusArray: statusArray)
            }
        } else {
            Color.clear
        }
    }
    .frame(width: scoreCellWidth, height: scoreCellHeight)
    .background(Color(UIColor.systemGray4))
    .border(Color.black, width: 1)
}
    
    private func scoreCellBackground(score: Int, par: Int) -> some View {
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
    
    private func scoreCellTextColor(score: Int, par: Int) -> Color {
        if score == 0 {
            return .clear
        } else if score <= par - 1 || score >= par + 1 {
            return .white
        } else {
            return colorScheme == .light ? .black : .white
        }
    }
}
