//
//  SingleRoundSetupView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/4/24.
//

import SwiftUI
import CoreLocation

struct SingleRoundSetupView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = SingleRoundViewModel()
    @State private var selectedLocation: String? = nil
    @State private var selectedCourse: Course? = nil
    @State private var navigateToAddGolfersView = false

    var formIsValid: Bool {
        return selectedCourse != nil
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image("golfgamble_bag")
                        .resizable()
                        .cornerRadius(10)
                        .scaledToFill()
                        .frame(width: 100, height: 120)
                        .padding(.vertical, 32)
                        .shadow(radius: 10)
                    Text("Single Round Setup \(Image(systemName: "figure.golf"))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    StyledPicker(
                        selection: $selectedLocation,
                        label: "Select a State",
                        options: viewModel.uniqueLocations,
                        placeholder: "None Selected",
                        content: { Text($0) },
                        displayString: { $0 }
                    )
                    .onChange(of: selectedLocation) { newValue in
                        viewModel.filterCourses(by: newValue)
                        selectedCourse = nil
                    }

                    if let _ = selectedLocation, !viewModel.filteredCourses.isEmpty {
                        StyledPicker(
                            selection: $selectedCourse,
                            label: "Select a Course",
                            options: viewModel.filteredCourses,
                            placeholder: "None Selected",
                            content: { Text($0.name) },
                            displayString: { $0.name }
                        )
                        .onChange(of: selectedCourse) { newValue in
                            if let course = newValue {
                                viewModel.fetchTees(for: course) { tees in
                                    // handle the fetched tees if needed
                                }
                            }
                        }
                    }

                    // Nearby Courses Section
                    if locationManager.isLocationAvailable {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Nearby Courses")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            if viewModel.nearbyCourses.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .padding()
                                    Spacer()
                                }
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 15) {
        ForEach(viewModel.nearbyCourses) { course in
            NearbyCourseCard(course: course, isSelected: selectedCourse?.id == course.id)
                .onTapGesture {
                    selectNearbyCourse(course)
                }
        }
    }
    .padding(.horizontal)
}
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(15)
                    } else {
                        VStack {
                            Text("Location access is required to find nearby golf courses.")
                            Text("Please enable location access in your device settings.")
                            Button("Open Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .padding()
                        }
                        .padding()
                    }

                    Button(action: {
                        navigateToAddGolfersView = true
                    }) {
                        Text("Next")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(formIsValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!formIsValid)
                    .padding(.horizontal)

                    NavigationLink(destination: AddGolfersView(selectedCourse: selectedCourse)
                        .environmentObject(viewModel)
                        .environmentObject(authViewModel)
                        .environmentObject(SharedViewModel()),
                                   isActive: $navigateToAddGolfersView) {
                        EmptyView()
                    }
                }
                .padding()
            }
            .onAppear {
                updateCoursesAndNearby()
            }
            .onChange(of: locationManager.lastLocation) { _ in
                updateCoursesAndNearby()
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func updateCoursesAndNearby() {
        viewModel.fetchCoursesAndNearby(userLocation: locationManager.lastLocation)
    }

    private func selectNearbyCourse(_ course: Course) {
        selectedLocation = nil  // Clear the location picker
        viewModel.filterCourses(by: nil)  // Clear the filtered courses
        selectedCourse = course  // Select the nearby course
        
        // Fetch tees for the selected course, just like in the course picker
        viewModel.fetchTees(for: course) { tees in
            // handle the fetched tees if needed
        }
        
        // If you have any other actions that need to be performed when a course is selected,
        // add them here to ensure consistency with the course picker selection
    }
}

struct StyledPicker<T: Hashable, Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var selection: T?
    let label: String
    let options: [T]
    let placeholder: String
    let content: (T) -> Content
    let displayString: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(.primary)
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selection = option
                    }) {
                        content(option)
                    }
                }
            } label: {
                HStack {
                    Text(selection.map { displayString($0) } ?? placeholder)
                        .foregroundColor(selection == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal)
    }
}

struct NearbyCourseCard: View {
    @Environment(\.colorScheme) var colorScheme
    let course: Course
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text(String(format: "%.1f miles", course.distance ?? 0))
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Text(course.location)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.tertiarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct SingleRoundSetupView_Previews: PreviewProvider {
    static var previews: some View {
        SingleRoundSetupView()
            .environmentObject(SingleRoundViewModel())
            .environmentObject(AuthViewModel())
            .environmentObject(SharedViewModel())
            .environmentObject(LocationManager())
    }
}