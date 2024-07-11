//
//  SingleRoundSetupView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/4/24.
//

import SwiftUI

struct SingleRoundSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SingleRoundViewModel()
    @State private var selectedLocation: String? = nil
    @State private var selectedCourse: Course? = nil
    @State private var navigateToAddGolfersView = false
    
    var formIsValid: Bool {
        return selectedLocation != nil && selectedCourse != nil
    }

    var body: some View {
        NavigationView {
            VStack {
                Image("golfgamble_bag")
                    .resizable()
                    .cornerRadius(10)
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .padding(.vertical, 32)
                    .shadow(radius: 10)
                Text("Single Round Setup \(Image(systemName: "figure.golf"))")
                    .font(.title)
                    .shadow(radius: 10)
                    .foregroundColor(Color.primary) // Adaptive color

                HStack {
                    Picker("Select a State", selection: $selectedLocation) {
                        Text("None Selected").tag(String?.none)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        ForEach(viewModel.uniqueLocations, id: \.self) { location in
                            Text(location).tag(location as String?)
                                .foregroundColor(Color.primary) // Adaptive color
                                .font(.subheadline)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .foregroundColor(Color.primary) // Adaptive color
                    .font(.headline)
                    .onChange(of: selectedLocation) { newValue in
                        viewModel.filterCourses(by: newValue)
                        selectedCourse = nil
                    }
                }
                .padding()

                if let _ = selectedLocation, !viewModel.filteredCourses.isEmpty {
                    HStack {
                        Picker("Course", selection: $selectedCourse) {
                            Text("None Selected").tag(Course?.none)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            ForEach(viewModel.filteredCourses, id: \.id) { course in
                                Text(course.name).tag(course as Course?)
                                    .foregroundColor(Color.primary) // Adaptive color
                                    .font(.subheadline)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .foregroundColor(Color.primary) // Adaptive color
                        .font(.headline)
                        .onChange(of: selectedCourse) { newValue in
                            if let course = newValue {
                                viewModel.fetchTees(for: course) { tees in
                                    // handle the fetched tees if needed
                                }
                            }
                        }
                    }
                    .padding()
                }

                Spacer()

                // Button to navigate to Add Golfers View
                Button(action: {
                    navigateToAddGolfersView = true
                }) {
                    HStack {
                        Text("Add Golfers")
                        Image(systemName: "plus")
                    }
                    .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                    .foregroundColor(.white)
                    .background(Color(.systemTeal))
                    .cornerRadius(10)
                }
                .padding(.top)
                .disabled(!formIsValid)
                .opacity(formIsValid ? 1.0 : 0.5)

                NavigationLink(
                    destination: AddGolfersView(selectedCourse: selectedCourse, selectedLocation: selectedLocation)
                        .environmentObject(viewModel)
                        .environmentObject(authViewModel),
                    isActive: $navigateToAddGolfersView,
                    label: {
                        EmptyView()
                    }
                )
            }
            .onAppear {
                viewModel.fetchCourses()
            }
            .background(Color(.systemBackground)) // Adaptive background color
        }
    }
}

struct SingleRoundSetupView_Previews: PreviewProvider {
    static var previews: some View {
        SingleRoundSetupView()
            .environmentObject(SingleRoundViewModel())
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
    }
}
