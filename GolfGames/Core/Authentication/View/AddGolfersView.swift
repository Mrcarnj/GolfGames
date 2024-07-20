//
//  AddGolfersView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

import Firebase
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
    @State private var playingHandicap: Int? = nil
    @State private var additionalGolfers: [Golfer] = []
    @State private var showingAddGolferSheet = false
    @State private var golferToEdit: Golfer?

    var selectedCourse: Course?
    var selectedLocation: String?

    var formIsValid: Bool {
        return selectedTee != nil && selectedTee?.tee_name != "Select Tees"
    }

    var body: some View {
        VStack {
            Image("golfgamble_bag")
                .resizable()
                .cornerRadius(10)
                .scaledToFill()
                .frame(width: 100, height: 120)
                .padding(.vertical, 32)
                .shadow(radius: 10)

            if let course = selectedCourse {
                Text("\(course.name)")
                    .font(.title2)
                    .padding(.top)
                    .foregroundColor(Color.primary)

                Text("Add Golfers")
                    .font(.headline)
                    .foregroundColor(Color.primary)
                    .padding(.top)

                if let currentUser = authViewModel.currentUser {
                    let golfer = convertUserToGolfer(user: currentUser)

                    VStack(alignment: .leading) {
                        HStack {
                            Text(currentUser.fullname)
                                .font(.subheadline)
                                .foregroundColor(Color.primary)
                            Spacer()
                            Text("HCP: \(String(format: "%.1f", currentUser.handicap ?? 0.0))")
                                .font(.subheadline)
                                .foregroundColor(Color.primary)
                            Spacer()

                            if let playingHandicap = playingHandicap {
                                Text("CH: \(playingHandicap)")
                                    .font(.subheadline)
                                    .foregroundColor(Color.primary)
                            }
                        }
                        .padding(.bottom, 5)

                        HStack {
                            TeePickerView(
                                selectedTee: $selectedTee,
                                playingHandicap: $playingHandicap,
                                currentGolfer: golfer
                            )
                            .environmentObject(singleRoundViewModel)
                        }
                    }
                    .padding()
                    .onAppear {
                        if let course = selectedCourse {
                            singleRoundViewModel.fetchTees(for: course) { tees in
                                roundViewModel.selectedCourse = course
                                print("Selected Course: \(course.name)")
                                if self.selectedTee == nil {
                                    self.selectedTee = nil // Explicitly set to nil for placeholder
                                }
                                print("Selected Tee: \(self.selectedTee?.tee_name ?? "None")")
                            }
                        }
                    }

                    // Additional Golfers List
                    ForEach(additionalGolfers, id: \.id) { golfer in
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

                                if let selectedTee = golfer.tee {
                                    let playingHandicap = HandicapCalculator.calculateCourseHandicap(
                                        handicapIndex: golfer.handicap,
                                        slopeRating: selectedTee.slope_rating,
                                        courseRating: selectedTee.course_rating,
                                        par: selectedTee.course_par
                                    )
                                    Text("CH: \(playingHandicap)")
                                        .font(.subheadline)
                                        .foregroundColor(Color.primary)
                                }
                            }
                            if let selectedTee = golfer.tee {
                                Text("\(selectedTee.tee_name) \(selectedTee.tee_yards) yds (\(String(format: "%.1f", selectedTee.course_rating))/\(selectedTee.slope_rating)) Par \(selectedTee.course_par)")
                                    .font(.footnote)
                                    .foregroundColor(Color.primary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            golferToEdit = golfer
                            showingAddGolferSheet.toggle()
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                if let index = additionalGolfers.firstIndex(of: golfer) {
                                    additionalGolfers.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    Button(action: {
                        showingAddGolferSheet.toggle()
                    }) {
                        Text("Add Golfer")
                            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                            .foregroundColor(.white)
                            .background(Color(.systemGray))
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    .sheet(isPresented: $showingAddGolferSheet) {
                        FriendsListView(
                            viewModel: FriendsViewModel(userId: authViewModel.currentUser?.id),
                            additionalGolfers: $additionalGolfers,
                            alreadyAddedGolfers: Set(additionalGolfers.map { $0.id })
                        )
                        .environmentObject(singleRoundViewModel)
                        .environmentObject(authViewModel)
                    }

                    Button(action: {
                        print("Begin Round button clicked")
                        print("Selected Course: \(selectedCourse?.name ?? "None")")
                        print("Selected Tee: \(selectedTee?.tee_name ?? "None")")
                        
                        roundViewModel.selectedCourse = selectedCourse
                        roundViewModel.selectedTee = selectedTee
                        
                        if let selectedCourse = selectedCourse, let selectedTee = selectedTee {
                            roundViewModel.beginRound(for: currentUser, additionalGolfers: additionalGolfers) { roundId, courseId, teeId in
                                if let roundId = roundId, let courseId = courseId, let teeId = teeId {
                                    self.roundId = roundId
                                    self.courseId = courseId
                                    self.teeId = teeId
                                    self.navigateToRoundView = true
                                    print("Navigation to RoundView triggered")
                                } else {
                                    print("Failed to begin round")
                                }
                            }
                        } else {
                            print("Selected Course or Tee is nil")
                        }
                    }) {
                        Text("Begin Round")
                            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                            .foregroundColor(.white)
                            .background(Color(.systemTeal))
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    .disabled(!formIsValid)
                    .opacity(formIsValid ? 1.0 : 0.5)

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
                    .foregroundColor(Color.primary)
            }
        }
        .navigationTitle("Add Golfers")
        .background(
            NavigationLink(
                destination: RoundView(roundId: roundId ?? "", selectedCourseId: courseId, selectedTeeId: teeId)
                    .environmentObject(authViewModel)
                    .environmentObject(singleRoundViewModel)
                    .environmentObject(roundViewModel),
                isActive: $navigateToRoundView,
                label: { EmptyView() }
            )
        )
        .background(Color(.systemBackground))
        .onAppear {
            OrientationUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        }
        .onDisappear {
            OrientationUtility.lockOrientation(.all)
        }
    }
}

struct AddGolfersView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(id: "mockId", fullname: "Mock User", email: "mockuser@example.com", handicap: 10.0, ghinNumber: 123456)
        let mockCourse = Course(id: "courseId", name: "Mock Course", location: "Mock Location")

        return AddGolfersView(
            selectedCourse: mockCourse,
            selectedLocation: "Mock State"
        )
        .environmentObject(SingleRoundViewModel())
        .environmentObject(AuthViewModel(mockUser: mockUser))
    }
}
