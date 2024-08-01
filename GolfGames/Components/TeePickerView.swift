//
//  TeePickerView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/19/24.
//

import SwiftUI

struct TeePickerView: View {
    @Binding var selectedTee: Tee?
    @Binding var playingHandicap: Int
    @Binding var currentGolfer: Golfer
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var sharedViewModel: SharedViewModel

    var body: some View {
        Picker("", selection: $selectedTee) {
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
        .onChange(of: selectedTee) { newValue in
            if let tee = newValue {
                playingHandicap = HandicapCalculator.calculateCourseHandicap(
                    handicapIndex: currentGolfer.handicap,
                    slopeRating: tee.slope_rating,
                    courseRating: tee.course_rating,
                    par: tee.course_par
                )
                sharedViewModel.golferTeeSelections[currentGolfer.id] = tee.id
                sharedViewModel.playingHandicaps[currentGolfer.id] = playingHandicap
               // print("Selected tee for golfer \(currentGolfer.fullName): \(tee.tee_name)")
            } else {
                playingHandicap = 0
                sharedViewModel.golferTeeSelections.removeValue(forKey: currentGolfer.id)
                sharedViewModel.playingHandicaps.removeValue(forKey: currentGolfer.id)
            }
        }
    }
}
