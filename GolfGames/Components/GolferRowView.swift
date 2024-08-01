//
//  GolferRowView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/19/24.
//

import SwiftUI

struct GolferRowView: View {
    @Binding var golfer: Golfer
    var isEditing: Bool
    var onRemove: () -> Void
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(golfer.fullName)
                    .font(.subheadline)
                    .foregroundColor(Color.primary)
                Spacer()
                Text("HCP: \(String(format: "%.1f", golfer.handicap))")
                    .font(.subheadline)
                    .foregroundColor(Color.primary)
                Spacer()

                if let playingHandicap = golfer.playingHandicap {
                    Text("CH: \(playingHandicap)")
                        .font(.subheadline)
                        .foregroundColor(Color.primary)
                }
            }
            .padding(.bottom, 5)

            HStack {
                Picker("", selection: $golfer.selectedTee) {
                    Text("Select Tees").tag(Tee?.none)
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    ForEach(singleRoundViewModel.tees, id: \.id) { tee in
                        Text("\(tee.tee_name) \(tee.tee_yards) yds (\(String(format: "%.1f", tee.course_rating))/\(tee.slope_rating)) Par \(tee.course_par)")
                            .tag(tee as Tee?)
                            .foregroundColor(Color.primary)
                            .font(.subheadline)
                    }
                }
                .pickerStyle(.navigationLink)
                .foregroundColor(Color.primary)
                .font(.headline)
                .onChange(of: golfer.selectedTee) { newValue in
                    if let newTee = newValue {
                        golfer.playingHandicap = HandicapCalculator.calculateCourseHandicap(
                            handicapIndex: golfer.handicap,
                            slopeRating: newTee.slope_rating,
                            courseRating: newTee.course_rating,
                            par: newTee.course_par
                        )
                    } else {
                        golfer.playingHandicap = nil
                    }
                }
                
                if isEditing {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                    }
                    .padding(.leading, 5)
                }
            }
        }
        .padding()
    }
}
