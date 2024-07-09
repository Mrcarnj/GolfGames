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
                    .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)

                HStack {
                    Picker("Select a State", selection: $selectedLocation) {
                        Text("None Selected").tag(String?.none)
                            .foregroundStyle(.gray)
                            .font(.subheadline)
                        ForEach(viewModel.uniqueLocations, id: \.self) { location in
                            Text(location).tag(location as String?)
                                .foregroundStyle(.black)
                                .font(.subheadline)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .foregroundStyle(.black)
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
                                .foregroundStyle(.gray)
                                .font(.subheadline)
                            ForEach(viewModel.filteredCourses, id: \.id) { course in
                                Text(course.name).tag(course as Course?)
                                    .foregroundStyle(.black)
                                    .font(.subheadline)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        .foregroundStyle(.black)
                        .font(.headline)
                        .onChange(of: selectedCourse) { newValue in
                            if let course = newValue {
                                viewModel.fetchTees(for: course)
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
