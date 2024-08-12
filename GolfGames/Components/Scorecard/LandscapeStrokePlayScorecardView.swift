//
//  LandscapeStrokePlayScorecardView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/12/24.
//

import SwiftUI

struct LandscapeStrokePlayScorecardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    let golfer: Golfer
    
    private let nameCellWidth: CGFloat = 50
    private let scoreCellWidth: CGFloat = 36
    private let scoreCellHeight: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                nineHoleView(holes: 1...9, title: "Out", showFirstColumn: true)
                nineHoleView(holes: 10...18, title: "In", showTotal: true, showFirstColumn: false)
            }
        }
        .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private func nineHoleView(holes: ClosedRange<Int>, title: String, showTotal: Bool = false, showFirstColumn: Bool) -> some View {
        VStack(spacing: 0) {
            holeRow(title: "Hole", holes: holes, total: title, showTotal: showTotal, showFirstColumn: showFirstColumn)
            parRow(holes: holes, showTotal: showTotal, showFirstColumn: showFirstColumn)
            scoreRow(holes: holes, isGross: true, showTotal: showTotal, showFirstColumn: showFirstColumn)
            scoreRow(holes: holes, isGross: false, showTotal: showTotal, showFirstColumn: showFirstColumn)
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
    
    private func scoreRow(holes: ClosedRange<Int>, isGross: Bool, showTotal: Bool, showFirstColumn: Bool) -> some View {
        HStack(spacing: 0) {
            if showFirstColumn {
                Text(isGross ? "Gross" : "Net")
                    .frame(width: nameCellWidth, height: scoreCellHeight, alignment: .center)
                    .padding(.horizontal, 2)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            }
            ForEach(holes, id: \.self) { hole in
                scoreCell(hole: hole, isGross: isGross)
                    .frame(width: scoreCellWidth, height: scoreCellHeight)
            }
            let totalScore = holes.reduce(0) { total, hole in
                total + (isGross ? roundViewModel.grossScores[hole]?[golfer.id] ?? 0 : roundViewModel.netStrokePlayScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(totalScore)")
                .frame(width: scoreCellWidth, height: scoreCellHeight)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            if showTotal {
                let grandTotal = singleRoundViewModel.holes.reduce(0) { total, hole in
                    total + (isGross ? roundViewModel.grossScores[hole.holeNumber]?[golfer.id] ?? 0 : roundViewModel.netStrokePlayScores[hole.holeNumber]?[golfer.id] ?? 0)
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
    
    private func scoreCell(hole: Int, isGross: Bool) -> some View {
        let par = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole })?.par ?? 0
        let score = isGross ? roundViewModel.grossScores[hole]?[golfer.id] ?? 0 : roundViewModel.netStrokePlayScores[hole]?[golfer.id] ?? 0
        let isStrokeHole = roundViewModel.strokeHoles[golfer.id]?.contains(hole) ?? false
        
        return ZStack {
            scoreCellBackground(score: score, par: par)
            
            if score != 0 {
                Text("\(score)")
                    .foregroundColor(scoreCellTextColor(score: score, par: par))
                    .font(.subheadline)
            }
            
            if isGross && isStrokeHole {
                Circle()
                    .fill(strokeDotColor(score: score, par: par))
                    .frame(width: 6, height: 6)
                    .offset(x: 7, y: -7)
            }
        }
    }
    
    // Include the scoreCellBackground, scoreCellTextColor, strokeDotColor, and scoreLegend functions from your existing LandscapeScorecardView
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
    
    var scoreLegend: some View {
        HStack(spacing: 10) {
            ForEach([
                (color: Color.yellow, shape: AnyShape(Circle()), text: "Eagle or better"),
                (color: Color.red, shape: AnyShape(Circle()), text: "Birdie"),
                (color: Color.black, shape: AnyShape(Rectangle()), text: "Bogey"),
                (color: Color.blue, shape: AnyShape(Rectangle()), text: "Double bogey +")
            ], id: \.text) { item in
                legendItem(color: item.color, shape: item.shape, text: item.text, addBorder: item.color == .black && colorScheme == .dark)
            }
        }
        .font(.caption)
    }
    
    func legendItem<S: Shape>(color: Color, shape: S, text: String, addBorder: Bool = false) -> some View {
        HStack(spacing: 4) {
            shape
                .fill(color)
                .frame(width: 12, height: 12)
                .if(addBorder) { view in
                    view.overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white, lineWidth: 1)
                    )
                }
            Text(text)
        }
    }
}