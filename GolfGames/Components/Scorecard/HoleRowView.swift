//
//  HoleRowView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import SwiftUI

struct HoleRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let holes: [Int]
    let isOut: Bool
    let hasTotalColumn: Bool

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Color.teal.opacity(0.5)
                Text("Hole").bold().foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            .frame(width: 50, height: 30)
            .border(Color.gray, width: 1)
            
            ForEach(holes, id: \.self) { hole in
                ZStack {
                    Color.teal.opacity(0.5)
                    Text("\(hole)").foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                .frame(width: 25, height: 30)
                .border(Color.gray, width: 1)
            }
            if isOut {
                ZStack {
                    Color.teal.opacity(0.5)
                    Text("Out").foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                .frame(width: 35, height: 30)
                .border(Color.gray, width: 1)
                
                if hasTotalColumn {
                    ZStack {
                        Color.teal.opacity(0.5)
                        Text("").foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    }
                    .frame(width: 35, height: 30)
                    .border(Color.gray, width: 1)
                }
            } else {
                ZStack {
                    Color.teal.opacity(0.5)
                    Text("In").foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                .frame(width: 35, height: 30)
                .border(Color.gray, width: 1)
                
                if hasTotalColumn {
                    ZStack {
                        Color.teal.opacity(0.5)
                        Text("Tot").foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    }
                    .frame(width: 35, height: 30)
                    .border(Color.gray, width: 1)
                }
            }
        }
    }
}

struct ParRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let pars: [Int]
    let totalPar: Int
    let hasTotalColumn: Bool
    let totalParText: String

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Color.gray.opacity(0.3)
                Text("Par").bold().foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            .frame(width: 50, height: 30)
            .border(Color.gray, width: 1)
            
            ForEach(pars.indices, id: \.self) { index in
                ZStack {
                    Color.gray.opacity(0.3)
                    Text("\(pars[index])").foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                .frame(width: 25, height: 30)
                .border(Color.gray, width: 1)
            }
            ZStack {
                Color.gray.opacity(0.3)
                Text("\(totalPar)").foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            .frame(width: 35, height: 30)
            .border(Color.gray, width: 1)
            
            if hasTotalColumn {
                ZStack {
                    Color.gray.opacity(0.3)
                    Text(totalParText).foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                }
                .frame(width: 35, height: 30)
                .border(Color.gray, width: 1)
            } else {
                ZStack {
                    Color.white
                    Text("").foregroundColor(.black)
                }
                .frame(width: 35, height: 30)
                .border(Color.gray, width: 1)
            }
        }
    }
}

struct ScoreRowView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let scores: [Int]
    let pars: [Int]
    let totalScore: Int
    let totalScoreText: String
    let hasTotalColumn: Bool

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Color.white
                Text("Gross").bold().foregroundColor(.black)
            }
            .frame(width: 50, height: 30)
            
            ForEach(scores.indices, id: \.self) { index in
                ZStack {
                    if scores[index] == pars[index] - 1 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 25, height: 30)
                            .background(.white)
                        Text("\(scores[index])").foregroundColor(.white).bold()
                    } else if scores[index] <= pars[index] - 2 {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 25, height: 30)
                            .background(.white)
                        Text("\(scores[index])").foregroundColor(.white).bold()
                    } else if scores[index] == pars[index] + 1 {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 25, height: 30)
                            .background(.white)
                        Text("\(scores[index])").foregroundColor(.white).bold()
                    } else if scores[index] >= pars[index] + 2 {
                        Rectangle()
                            .fill(Color.blue).opacity(0.8)
                            .frame(width: 25, height: 30)
                            .background(.white)
                        Text("\(scores[index])").foregroundColor(.white).bold()
                    } else {
                        Color.white
                        Text("\(scores[index])").foregroundColor(.black).bold()
                    }
                }
                .frame(width: 25, height: 30)
            }
            ZStack {
                Color.white
                Text("\(totalScore)").bold().foregroundColor(.black)
            }
            .frame(width: 35, height: 30)
//            .border(Color.gray, width: 1)
            
            if hasTotalColumn {
                ZStack {
                    Color.white
                    Text(totalScoreText).bold().foregroundColor(.black)
                }
                .frame(width: 35, height: 30)
            } else {
                ZStack {
                    Color.white
                    Text("").foregroundColor(.black)
                }
                .frame(width: 35, height: 30)
            }
        }
    }
}

struct NetScoreRowView: View {
    @Environment(\.colorScheme) var colorScheme

    let netScores: [Int]
    let pars: [Int]
    let totalNetScore: Int
    let totalNetScoreText: String
    let hasTotalColumn: Bool

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Color.white
                Text("Net").bold().foregroundColor(.black)
            }
            .frame(width: 50, height: 30)
//            .border(Color.gray, width: 1)
            
            ForEach(netScores.indices, id: \.self) { index in
                ZStack {
                    if netScores[index] == pars[index] - 1 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 25, height: 30)
                            .background(colorScheme == .dark ? Color.white : Color.black)
                        Text("\(netScores[index])").foregroundColor(.white).bold()
                    } else if netScores[index] <= pars[index] - 2 {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 25, height: 30)
                            .background(colorScheme == .dark ? Color.white : Color.black)
                        Text("\(netScores[index])").foregroundColor(.white).bold()
                    } else if netScores[index] == pars[index] + 1 {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 25, height: 30)
                            .background(colorScheme == .dark ? Color.white : Color.black)
                        Text("\(netScores[index])").foregroundColor(.white).bold()
                    } else if netScores[index] >= pars[index] + 2 {
                        Rectangle()
                            .fill(Color.blue).opacity(0.8)
                            .frame(width: 25, height: 30)
                            .background(colorScheme == .dark ? Color.white : Color.black)
                        Text("\(netScores[index])").foregroundColor(.white).bold()
                    } else {
                        Color.white
                        Text("\(netScores[index])").foregroundColor(.black).bold()
                    }
                }
                .frame(width: 25, height: 30)
            }
            ZStack {
                Color.white
                Text("\(totalNetScore)").bold().foregroundColor(.black)
            }
            .frame(width: 35, height: 30)
//            .border(Color.gray, width: 1)
            
            if hasTotalColumn {
                ZStack {
                    Color.white
                    Text(totalNetScoreText).bold().foregroundColor(.black)
                }
                .frame(width: 35, height: 30)
            } else {
                ZStack {
                    Color.white
                    Text("").foregroundColor(.black)
                }
                .frame(width: 35, height: 30)
            }
        }
    }
}

