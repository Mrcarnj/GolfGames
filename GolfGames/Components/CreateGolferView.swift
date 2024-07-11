//
//  CreateGolferView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//

import SwiftUI

struct CreateGolferView: View {
    @Binding var golfers: [Golfer]
    @State private var fullName: String = ""
    @State private var handicap: String = ""
    @State private var selectedTee: Tee? = nil
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @Binding var golferToEdit: Golfer?
    var course: Course?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Golfer Details")) {
                    TextField("Full Name", text: $fullName)
                    TextField("Handicap", text: $handicap)
                        .keyboardType(.decimalPad)
                }
                
                if let course = course {
                    Section(header: Text("Select Tees")) {
                        Picker("Tees", selection: $selectedTee) {
                            Text("Select Tees").tag(Tee?.none)
                            ForEach(singleRoundViewModel.tees, id: \.id) { tee in
                                Text("\(tee.tee_name) \(tee.tee_yards) yds (\(String(format: "%.1f", tee.course_rating))/\(tee.slope_rating)) Par \(tee.course_par)")
                                    .tag(tee as Tee?)
                            }
                        }
                    }
                    .onAppear {
                        singleRoundViewModel.fetchTees(for: course) { tees in
                            // handle the fetched tees if needed
                        }
                    }
                }

                if golferToEdit == nil {
                    Button(action: addOrUpdateGolfer) {
                        Text("Submit & Add Another")
                    }
                }
            }
            .navigationTitle(golferToEdit == nil ? "Add Golfer" : "Edit Golfer")
            .navigationBarItems(trailing: Button("Done") {
                if let golfer = createGolfer() {
                    if let golferToEdit = golferToEdit, let index = golfers.firstIndex(of: golferToEdit) {
                        golfers[index] = golfer
                    } else {
                        golfers.append(golfer)
                    }
                }
                self.presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                if let golfer = golferToEdit {
                    fullName = golfer.fullName
                    handicap = String(golfer.handicap)
                    selectedTee = golfer.tee
                }
            }
        }
    }

    @Environment(\.presentationMode) var presentationMode

    func createGolfer() -> Golfer? {
        guard !fullName.isEmpty, let handicapValue = Float(handicap) else {
            return nil
        }
        return Golfer(fullName: fullName, handicap: handicapValue, tee: selectedTee)
    }

    func addOrUpdateGolfer() {
        if let golfer = createGolfer() {
            if let golferToEdit = golferToEdit, let index = golfers.firstIndex(of: golferToEdit) {
                golfers[index] = golfer
            } else {
                golfers.append(golfer)
            }
            golferToEdit = nil
            fullName = ""
            handicap = ""
            selectedTee = nil
        }
    }
}
