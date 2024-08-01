//
//  LegendItem.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/31/24.
//

import SwiftUI

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack {
            if color == .black {
                Rectangle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .border(Color.primary)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
            }
            Text(text)
                .foregroundColor(.primary)
                .font(.system(size: 9))
        }
    }
}
