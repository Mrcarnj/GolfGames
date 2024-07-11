//
//  ScorecardView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import SwiftUI
import Firebase

struct ScorecardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedViewType: ScorecardViewType = .scoreOnly
    @EnvironmentObject var viewModel: RoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var pars: [Int: Int] = [:]
    @State private var navigateToInitialView = false
    
    var showFinishButton: Bool // Add this parameter

    var body: some View {
        VStack {
            Picker("Select View", selection: $selectedViewType) {
                ForEach(ScorecardViewType.allCases) { viewType in
                    Text(viewType.rawValue).tag(viewType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            ScorecardComponentsView(viewType: selectedViewType, pars: pars)
                .environmentObject(viewModel)
            
            HStack {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 10, height: 10)
                    
                Text("Eagle or better").foregroundColor(colorScheme == .dark ? Color.white : Color.black).font(.system(size: 9))
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    
                Text("Birdie").foregroundColor(colorScheme == .dark ? Color.white : Color.black).font(.system(size: 9))
                
                Rectangle()
                    .fill(.black) // Use foregroundColor instead of fill
                    .frame(width: 10, height: 10)
                    .border(colorScheme == .dark ? Color.white : Color.black)
                    
                Text("Bogey").foregroundColor(colorScheme == .dark ? Color.white : Color.black).font(.system(size: 9))
                
                Rectangle()
                    .fill(Color.blue).opacity(0.8)
                    .frame(width: 10, height: 10)
                    
                Text("Double Bogey or worse").foregroundColor(colorScheme == .dark ? Color.white : Color.black).font(.system(size: 9))
            }
            .padding()

            if showFinishButton { // Conditionally display the button
                Button(action: finishRound) {
                    Text("Finish Round")
                        .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                        .foregroundColor(.white)
                        .background(Color(.systemTeal))
                        .cornerRadius(10)
                }
                .padding(.top)
            }
        }
        .onAppear {
            // Fetch the pars for the selected course and tee
            if let selectedCourseId = viewModel.selectedCourse?.id,
               let selectedTeeId = viewModel.selectedTee?.id,
               let user = authViewModel.currentUser {
                viewModel.fetchPars(for: selectedCourseId, teeId: selectedTeeId, user: user) { fetchedPars in
                    self.pars = fetchedPars
                    // Debug print statements
                    print("Fetched pars:")
                    for (holeNumber, par) in fetchedPars.sorted(by: { $0.key < $1.key }) {
                        print("Hole \(holeNumber): Par \(par)")
                    }
                }
            } else {
                print("Course or Tee ID is missing.")
            }
        }
        .navigationBarBackButtonHidden(!showFinishButton)
        .background(
            NavigationLink(destination: InititalView().environmentObject(authViewModel).environmentObject(viewModel), isActive: $navigateToInitialView) {
                EmptyView()
            }
        )
    }

    private func finishRound() {
        guard let user = authViewModel.currentUser else { return }
        guard let course = viewModel.selectedCourse else { return }
        guard let tee = viewModel.selectedTee else { return }

        let db = Firestore.firestore()
        let roundRef = db.collection("users").document(user.id).collection("rounds").document(viewModel.roundId ?? "")

        // Generate a unique round result ID
        let roundResultID = roundRef.collection("results").document().documentID

        // Helper function to sum the scores from the nested dictionary
        func sumScores() -> Int {
            return viewModel.scores.values.flatMap { $0.values }.reduce(0, +)
        }

        var roundData: [String: Any] = [
            "date": Timestamp(date: Date()),  // Use Firestore Timestamp for date
            "course": course.name,
            "tees": tee.tee_name,
            "course_rating": tee.course_rating,  // Add course rating
            "slope_rating": tee.slope_rating,  // Add slope rating
            "total_score": sumScores(),
            "roundResultID": roundResultID  // Add round result ID to the data
        ]

        for (hole, scores) in viewModel.scores {
            for (golfer, score) in scores {
                roundData["hole_\(hole)_\(golfer)"] = score
            }
        }

        roundRef.setData(roundData) { error in
            if let error = error {
                print("Error saving round: \(error.localizedDescription)")
            } else {
                print("Round successfully saved!")
            }
        }
    }

    private func resetLocalData() {
        viewModel.scores = [:]
        viewModel.pars = [:]
        viewModel.selectedCourse = nil
        viewModel.selectedTee = nil
    }
}

struct ScorecardView_Previews: PreviewProvider {
    static var previews: some View {
        ScorecardView(showFinishButton: true)
            .environmentObject(RoundViewModel())
    }
}
