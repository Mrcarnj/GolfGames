//
//  CreateGolferView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/11/24.
//

import SwiftUI

struct CreateGolferView: View {
    @Binding var golfers: [Golfer]
    @Binding var golferToEdit: Golfer?
    @Environment(\.presentationMode) var presentationMode

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var ghinNumber = ""
    @State private var handicap = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Golfer Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("GHIN (Optional)", text: $ghinNumber)
                        .keyboardType(.numberPad)
                    TextField("Handicap", text: $handicap)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationBarTitle(golferToEdit == nil ? "Add Golfer" : "Edit Golfer", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(golferToEdit == nil ? "Create" : "Update") {
                    if validateInput() {
                        createOrUpdateGolfer()
                    }
                }
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            populateFieldsForEditing()
        }
    }

    private func createOrUpdateGolfer() {
        if let handicapValue = Float(handicap) {
            let ghinNumberValue = Int(ghinNumber)
            let newGolfer = Golfer(
                id: golferToEdit?.id ?? UUID().uuidString,
                firstName: firstName,
                lastName: lastName,
                handicap: handicapValue,
                ghinNumber: ghinNumberValue,
                isChecked: false
            )
            
            if let index = golfers.firstIndex(where: { $0.id == golferToEdit?.id }) {
                golfers[index] = newGolfer
            } else {
                golfers.append(newGolfer)
            }
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func populateFieldsForEditing() {
        if let golferToEdit = golferToEdit {
            firstName = golferToEdit.firstName
            lastName = golferToEdit.lastName
            ghinNumber = golferToEdit.ghinNumber != nil ? String(golferToEdit.ghinNumber!) : ""
            handicap = String(golferToEdit.handicap)
        }
    }

    private func validateInput() -> Bool {
        if firstName.isEmpty || lastName.isEmpty {
            alertMessage = "Please enter both first name and last name."
            showAlert = true
            return false
        }
        if handicap.isEmpty {
            alertMessage = "Please enter a handicap."
            showAlert = true
            return false
        }
        if Float(handicap) == nil {
            alertMessage = "Please enter a valid handicap."
            showAlert = true
            return false
        }
        return true
    }
}

struct CreateGolferView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGolferView(golfers: .constant([]), golferToEdit: .constant(nil))
    }
}
