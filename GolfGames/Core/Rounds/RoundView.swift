//
//  RoundView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct RoundView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedViewType: ScorecardViewType = .scoreOnly
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @State private var navigateToInitialView = false
    
    var roundId: String
    var showFinishButton: Bool

    var body: some View {
        VStack {
            Picker("Select View", selection: $selectedViewType) {
                ForEach(ScorecardViewType.allCases) { viewType in
                    Text(viewType.rawValue).tag(viewType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

//            ScrollView {
//                ScorecardComponentsView(viewType: selectedViewType)
//                    .environmentObject(roundViewModel)
//                    .environmentObject(singleRoundViewModel)
//            }
            
            if showFinishButton {
                finishButton
            }
        }
        .onAppear(perform: loadRoundData)
        .navigationBarBackButtonHidden(!showFinishButton)
        .background(
            NavigationLink(destination: InititalView().environmentObject(authViewModel).environmentObject(roundViewModel), isActive: $navigateToInitialView) {
                EmptyView()
            }
        )
    }

    private var finishButton: some View {
        Button(action: finishRound) {
            Text("Finish Round")
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                .foregroundColor(.white)
                .background(Color(.systemTeal))
                .cornerRadius(10)
        }
        .padding(.top)
    }

    private func loadRoundData() {
        guard let courseId = roundViewModel.selectedCourse?.id,
              let teeId = roundViewModel.selectedTee?.id else {
            print("Course or Tee not selected")
            return
        }

        print("Loading holes for Course ID: \(courseId), Tee ID: \(teeId)")
        singleRoundViewModel.loadHoles(for: courseId, teeId: teeId) { loadedHoles in
            print("Holes loaded: \(loadedHoles.map { "Hole \($0.holeNumber): Par \($0.par)" }.joined(separator: ", "))")
            self.roundViewModel.calculateStrokeHoles(holes: loadedHoles)
            print("Holes loaded and stroke holes calculated")
        }
    }

    private func finishRound() {
        guard let user = authViewModel.currentUser,
              let course = roundViewModel.selectedCourse,
              let tee = roundViewModel.selectedTee else { return }

        let db = Firestore.firestore()
        let roundRef = db.collection("users").document(user.id).collection("rounds").document(roundViewModel.roundId ?? "")

        let roundResultID = roundRef.collection("results").document().documentID

        var roundData: [String: Any] = [
            "date": Timestamp(date: Date()),
            "course": course.name,
            "tees": tee.tee_name,
            "course_rating": tee.course_rating,
            "slope_rating": tee.slope_rating,
            "total_score": roundViewModel.grossScores.values.flatMap { $0.values }.reduce(0, +),
            "roundResultID": roundResultID
        ]

        for (hole, scores) in roundViewModel.grossScores {
            for (golfer, score) in scores {
                roundData["hole_\(hole)_\(golfer)"] = score
            }
        }

        roundRef.setData(roundData) { error in
            if let error = error {
                print("Error saving round: \(error.localizedDescription)")
            } else {
                print("Round successfully saved!")
                resetLocalData()
                navigateToInitialView = true
            }
        }
    }

    private func resetLocalData() {
        roundViewModel.grossScores = [:]
        roundViewModel.netScores = [:]
        roundViewModel.strokeHoles = [:]
        roundViewModel.selectedCourse = nil
        roundViewModel.selectedTee = nil
    }
}

struct RoundView_Previews: PreviewProvider {
    static var previews: some View {
        RoundView(
            roundId: "mockRoundId",
            showFinishButton: true
        )
        .environmentObject(RoundViewModel())
        .environmentObject(AuthViewModel())
        .environmentObject(SingleRoundViewModel())
    }
}
