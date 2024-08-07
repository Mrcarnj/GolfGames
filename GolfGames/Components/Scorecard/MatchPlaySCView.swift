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
    @Binding var selectedGolferId: String?
    @State private var orientation = UIDeviceOrientation.unknown
    
    private var isLandscape: Bool {
        return orientation.isLandscape
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let golfer = selectedGolfer {
                nineHoleView(for: golfer, holes: 1...9, title: "Out", addBlankColumn: true)
                nineHoleView(for: golfer, holes: 10...18, title: "In", showTotal: true, addBlankColumn: false)
            } else {
                Text("No golfer selected")
            }
        }
        .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
    }
    
    var selectedGolfer: Golfer? {
        if let id = selectedGolferId {
            return roundViewModel.golfers.first { $0.id == id }
        }
        return roundViewModel.golfers.first
    }
    
    func nineHoleView(for golfer: Golfer, holes: ClosedRange<Int>, title: String, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
        VStack(spacing: 0) {
            holeRow(title: "Hole", holes: holes, total: title, showTotal: showTotal, addBlankColumn: addBlankColumn)
            parRow(holes: holes, showTotal: showTotal, addBlankColumn: addBlankColumn)
            scoreRow(for: golfer, holes: holes, isGross: true, showTotal: showTotal, addBlankColumn: addBlankColumn)
            scoreRow(for: golfer, holes: holes, isGross: false, showTotal: showTotal, addBlankColumn: addBlankColumn)
            matchStatusRow(for: golfer, holes: holes, showTotal: showTotal, addBlankColumn: addBlankColumn)
        }
    }
    
    func holeRow(title: String, holes: ClosedRange<Int>, total: String, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .frame(width: 40, height: 27, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemTeal))
            ForEach(holes, id: \.self) { hole in
                Text("\(hole)")
                    .frame(width: 27, height: 27)
                    .background(Color(UIColor.systemTeal))
            }
            Text(total)
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemTeal))
            if showTotal {
                Text("Tot")
                    .frame(width: 32, height: 27)
                    .background(Color(UIColor.systemTeal))
            } else if addBlankColumn {
                Color(UIColor.systemTeal)
                    .frame(width: 32, height: 27)
            }
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    func parRow(holes: ClosedRange<Int>, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text("Par")
                .frame(width: 40, height: 27, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemTeal))
            ForEach(holes, id: \.self) { hole in
                if let holeData = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole }) {
                    Text("\(holeData.par)")
                        .frame(width: 27, height: 27)
                        .background(Color(UIColor.systemTeal))
                }
            }
            let totalPar = singleRoundViewModel.holes.filter { holes.contains($0.holeNumber) }.reduce(0) { $0 + $1.par }
            Text("\(totalPar)")
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemTeal))
            if showTotal {
                let grandTotalPar = singleRoundViewModel.holes.reduce(0) { $0 + $1.par }
                Text("\(grandTotalPar)")
                    .frame(width: 32, height: 27)
                    .background(Color(UIColor.systemTeal))
            } else if addBlankColumn {
                Color(UIColor.systemTeal)
                    .frame(width: 32, height: 27)
            }
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    func scoreRow(for golfer: Golfer, holes: ClosedRange<Int>, isGross: Bool, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text(isGross ? "Gross" : "Net")
                .frame(width: 40, height: 27, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            ForEach(holes, id: \.self) { hole in
                scoreCell(for: golfer, hole: hole, isGross: isGross)
                    .frame(width: 27, height: 27)
            }
            let totalScore = holes.reduce(0) { total, hole in
                total + (isGross ? roundViewModel.grossScores[hole]?[golfer.id] ?? 0 : roundViewModel.matchPlayNetScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(totalScore)")
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            if showTotal {
                let grandTotal = singleRoundViewModel.holes.reduce(0) { total, hole in
                    total + (isGross ? roundViewModel.grossScores[hole.holeNumber]?[golfer.id] ?? 0 : roundViewModel.matchPlayNetScores[hole.holeNumber]?[golfer.id] ?? 0)
                }
                Text("\(grandTotal)")
                    .frame(width: 32, height: 27)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            } else if addBlankColumn {
                Color(UIColor.systemGray4)
                    .frame(width: 32, height: 27)
            }
        }
        .font(.caption)
    }
    
    func scoreCell(for golfer: Golfer, hole: Int, isGross: Bool) -> some View {
        let par = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole })?.par ?? 0
        let score = isGross ? roundViewModel.grossScores[hole]?[golfer.id] ?? 0 : roundViewModel.matchPlayNetScores[hole]?[golfer.id] ?? 0
        let isMatchPlayStrokeHole = roundViewModel.matchPlayStrokeHoles[golfer.id]?.contains(hole) ?? false
        
        return ZStack {
            scoreCellBackground(score: score, par: par)
            
            if score != 0 {
                Text("\(score)")
                    .foregroundColor(scoreCellTextColor(score: score, par: par))
                    .font(.subheadline)
            }
            
            if isGross && isMatchPlayStrokeHole {
                Circle()
                    .fill(strokeDotColor(score: score, par: par))
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
    
    func matchStatusRow(for golfer: Golfer, holes: ClosedRange<Int>, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text("Match")
                .frame(width: 40, height: 27, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            
            if addBlankColumn {
                Color(UIColor.systemGray4)
                    .frame(width: 32, height: 27)
            }
            
            ForEach(holes, id: \.self) { hole in
                matchStatusCell(for: golfer, hole: hole)
                    .frame(width: 27, height: 27)
            }
            
            Text("")
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemGray4))
            
            if showTotal {
                Color(UIColor.systemGray4)
                    .frame(width: 32, height: 27)
            }
        }
        .font(.caption)
    }
    
    func matchStatusCell(for golfer: Golfer, hole: Int) -> some View {
        let status = roundViewModel.matchStatus[hole]?[golfer.id] ?? 0
        let absStatus = abs(status)
        
        return Group {
            if hole <= roundViewModel.currentHole && roundViewModel.grossScores[hole]?[golfer.id] != nil {
                if status == 0 {
                    Text("AS")
                } else {
                    HStack(spacing: 2) {
                        Text("\(absStatus)")
                        Image(systemName: status > 0 ? "arrow.up" : "arrow.down")
                    }
                }
            } else {
                Color.clear
            }
        }
        .frame(width: 27, height: 27)
        .background(Color(UIColor.systemGray4))
    }
}

struct MatchPlaySCView_Previews: PreviewProvider {
    static var previews: some View {
        MatchPlaySCView(selectedGolferId: .constant(nil))
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
            .environmentObject(AuthViewModel())
    }
}
