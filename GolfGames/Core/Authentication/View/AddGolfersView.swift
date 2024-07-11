//
//  AddGolfersView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

//
//  AddGolfersView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

//
//  AddGolfersView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/6/24.
//

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
                    .foregroundColor(Color.primary) // Adaptive color

                Text("Add Golfers")
                    .font(.headline)
                    .foregroundColor(Color.primary) // Adaptive color
                    .padding(.top)

                if let currentUser = authViewModel.currentUser {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(currentUser.fullname)
                                .font(.subheadline)
                                .foregroundColor(Color.primary) // Adaptive color
                            Spacer()
                            Text("HCP: \(String(format: "%.1f", currentUser.handicap ?? 0.0))")
                                .font(.subheadline)
                                .foregroundColor(Color.primary) // Adaptive color
                            Spacer()
                            
                            if let playingHandicap = playingHandicap {
                                Text("CH: \(playingHandicap)")
                                    .font(.subheadline)
                                    .foregroundColor(Color.primary) // Adaptive color
                            }
                        }
                        .padding(.bottom, 5)

                        HStack {
                            Picker("", selection: $selectedTee) {
                                Text("Select Tees").tag(Tee?.none)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                ForEach(singleRoundViewModel.tees, id: \.id) { tee in
                                    Text("\(tee.tee_name) \(tee.tee_yards) yds (\(String(format: "%.1f", tee.course_rating))/\(tee.slope_rating)) Par \(tee.course_par)")
                                        .tag(tee as Tee?)
                                        .foregroundColor(Color.primary) // Adaptive color
                                        .font(.subheadline)
                                }
                            }
                            .pickerStyle(.navigationLink)
                            .foregroundColor(Color.primary) // Adaptive color
                            .font(.headline)
                            .onChange(of: selectedTee) { newValue in
                                roundViewModel.selectedTee = newValue
                                // Recalculate playing handicap when tees are changed
                                if let tee = newValue, let handicapIndex = currentUser.handicap {
                                    self.playingHandicap = HandicapCalculator.calculateCourseHandicap(
                                        handicapIndex: handicapIndex,
                                        slopeRating: tee.slope_rating,
                                        courseRating: tee.course_rating,
                                        par: tee.course_par
                                    )
                                } else {
                                    self.playingHandicap = nil
                                }
                            }
                        }
                    }
                    .padding()
                    .onAppear {
                        if let course = selectedCourse {
                            singleRoundViewModel.fetchTees(for: course) { tees in
                                roundViewModel.selectedCourse = course
                                // You can handle fetched tees here if needed
                            }
                        }
                    }

                    List {
                        ForEach(additionalGolfers, id: \.id) { golfer in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(golfer.fullName)
                                        .font(.subheadline)
                                        .foregroundColor(Color.primary) // Adaptive color
                                    Spacer()
                                    Text("HCP: \(String(format: "%.1f", golfer.handicap))")
                                        .font(.subheadline)
                                        .foregroundColor(Color.primary) // Adaptive color
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
                                            .foregroundColor(Color.primary) // Adaptive color
                                    }
                                }
                                if let selectedTee = golfer.tee {
                                    Text("\(selectedTee.tee_name) \(selectedTee.tee_yards) yds (\(String(format: "%.1f", selectedTee.course_rating))/\(selectedTee.slope_rating)) Par \(selectedTee.course_par)")
                                        .font(.footnote)
                                        .foregroundColor(Color.primary) // Adaptive color
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
                    }
                    .listStyle(PlainListStyle())

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
                        CreateGolferView(golfers: $additionalGolfers, golferToEdit: $golferToEdit, course: selectedCourse)
                            .environmentObject(singleRoundViewModel)
                    }

                    Button(action: {
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
                    .foregroundColor(Color.primary) // Adaptive color
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
        .background(Color(.systemBackground)) // Adaptive background color
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

        return AddGolfersView(selectedCourse: mockCourse, selectedLocation: "Mock State")
            .environmentObject(SingleRoundViewModel())
            .environmentObject(AuthViewModel(mockUser: mockUser))
    }
}
