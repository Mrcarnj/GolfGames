//
//  RecentRoundsListView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/24/24.
//

import SwiftUI

struct RecentRoundsListView: View {
    @ObservedObject var roundsViewModel: RecentRoundsModel
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(roundsViewModel.recentRounds, id: \.id) { round in
                HStack {
                    Text(dateFormatter.string(from: round.date))
                    Spacer()
                    Text(round.course)
                    Spacer()
                    Text(round.tees)
                    Spacer()
                    Text("(\(String(format: "%.1f", round.courseRating))/\(Int(round.slopeRating)))")
                    Spacer()
                    Text("\(round.totalScore)")
                        .fontWeight(.bold)
                }
                .font(.system(size: 10))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

//#Preview {
//    let roundsViewModel = RecentRoundsModel()
//    roundsViewModel.recentRounds = [
//        Round(id: "1", date: Date(), course: "Course 1", tees: "Blue", courseRating: 72.5, slopeRating: 113, totalScore: 85),
//        Round(id: "2", date: Date(), course: "Course 2", tees: "White", courseRating: 70.0, slopeRating: 110, totalScore: 90)
//    ]
//    return RecentRoundsListView(roundsViewModel: roundsViewModel)
//}
