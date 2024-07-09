//
//  AddGolfersView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

import SwiftUI

struct AddGolfersView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @StateObject private var roundViewModel = RoundViewModel()
    @State private var selectedTee: Tee? = nil
    @State private var navigateToRoundView = false
    @State private var roundId: String?
    @State private var courseId = ""
    @State private var teeId = ""

    var selectedCourse: Course?
    var selectedLocation: String?

    var body: some View {
        VStack {
            if let course = selectedCourse {
                Text("Selected Course: \(course.name)")
                    .font(.headline)
                    .padding()

                Text("Add Golfers")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.top)

                if let currentUser = authViewModel.currentUser {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(currentUser.fullname)")
                                .font(.subheadline)
                            Spacer()
                            Text("Handicap: \(String(format: "%.1f", currentUser.handicap ?? 0.0))")
                                .font(.subheadline)
                        }
                        .padding(.bottom, 5)

                        HStack {
                            Text("Select Tees")
                                .font(.headline)
                            Picker("Select Tees", selection: $roundViewModel.selectedTee) {
                                Text("Select Tees").tag(Tee?.none)
                                    .foregroundStyle(.gray)
                                    .font(.subheadline)
                                ForEach(singleRoundViewModel.tees, id: \.id) { tee in
                                    Text("\(tee.tee_name) \(tee.tee_yards) yds (\(String(format: "%.1f", tee.course_rating))/\(tee.slope_rating)) Par \(tee.course_par)")
                                        .tag(tee as Tee?)
                                        .foregroundStyle(.black)
                                        .font(.subheadline)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundStyle(.black)
                            .font(.headline)
                        }
                    }
                    .padding()
                    .onAppear {
                        if let course = selectedCourse {
                            singleRoundViewModel.fetchTees(for: course)
                            roundViewModel.selectedCourse = course
                        }
                    }

                    Button(action: {
                        // Debug print statements
                        print("Selected Course: \(roundViewModel.selectedCourse?.name ?? "None")")
                        print("Selected Tee: \(roundViewModel.selectedTee?.tee_name ?? "None")")

                        roundViewModel.beginRound(for: currentUser) { roundId, courseId, teeId in
                            if let roundId = roundId, let courseId = courseId, let teeId = teeId {
                                self.roundId = roundId
                                self.courseId = courseId
                                self.teeId = teeId
                                self.navigateToRoundView = true
                            }
                        }
                    }) {
                        Text("Begin Round")
                            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                            .foregroundColor(.white)
                            .background(Color(.systemTeal))
                            .cornerRadius(10)
                    }
                    .padding(.top)

                } else {
                    Text("User not logged in")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            } else {
                Text("No course selected")
                    .font(.headline)
                    .padding()
            }
        }
        .navigationTitle("Add Golfers")
        .background(
            NavigationLink(
                destination: RoundView(roundId: roundId ?? "", selectedCourseId: courseId, selectedTeeId: teeId)
                    .environmentObject(authViewModel),
                isActive: $navigateToRoundView,
                label: { EmptyView() }
            )
        )
    }
}

struct AddGolfersView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(id: "mockId", fullname: "Mock User", email: "mockuser@example.com", handicap: 10.0, ghinNumber: 123456)
        let mockCourse = Course(id: "courseId", name: "Mock Course", location: "Mock Location")

        return AddGolfersView(selectedCourse: mockCourse, selectedLocation: "Mock State")
            .environmentObject(SingleRoundViewModel())
            .environmentObject(AuthViewModel(mockUser: mockUser))
    }
}
