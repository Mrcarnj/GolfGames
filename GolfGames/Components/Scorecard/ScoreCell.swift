//
//  ScoreCell.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/31/24.
//

import SwiftUI

struct ScoreCell: View {
    let score: Int
    let par: Int
    let isStrokeHole: Bool

    var body: some View {
        ZStack {
            backgroundColor
            Text("\(score)")
                .foregroundColor(textColor)
            if isStrokeHole {
                Circle()
                    .fill(Color.black)
                    .frame(width: 6, height: 6)
                    .offset(x: 10, y: -10)
            }
        }
        .frame(width: 30, height: 30)
    }

    private var backgroundColor: Color {
        if score <= par - 2 { return .yellow }
        else if score == par - 1 { return .red }
        else if score == par + 1 { return .black }
        else if score >= par + 2 { return .blue }
        else { return .clear }
    }

    private var textColor: Color {
        backgroundColor == .clear ? .black : .white
    }
}
