//
//  TeePickerView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/19/24.
//

import SwiftUI

struct TeePickerView: View {
    @Binding var selectedTee: Tee?
    @Binding var playingHandicap: Int?
    var currentGolfer: Golfer
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel

    var body: some View {
        Picker("", selection: $selectedTee) {
            Text("Select Tees").tag(Tee?.none)
            ForEach(singleRoundViewModel.tees, id: \.id) { tee in
                Text("\(tee.tee_name) \(tee.tee_yards) yds (\(String(format: "%.1f", tee.course_rating))/\(tee.slope_rating)) Par \(tee.course_par)")
                    .tag(tee as Tee?)
            }
        }
        .pickerStyle(.navigationLink)
        .onChange(of: selectedTee) { newValue in
            if let tee = newValue {
                playingHandicap = HandicapCalculator.calculateCourseHandicap(
                    handicapIndex: currentGolfer.handicap,
                    slopeRating: tee.slope_rating,
                    courseRating: tee.course_rating,
                    par: tee.course_par
                )
            } else {
                playingHandicap = nil
            }
        }
    }
}
