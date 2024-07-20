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
    var course: Course?

    @Environment(\.presentationMode) var presentationMode
    @State private var fullName = ""
    @State private var ghinNumber = ""
    @State private var handicap = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Friend Information")) {
                    TextField("Full Name", text: $fullName)
                    TextField("GHIN (Optional)", text: $ghinNumber)
                        .keyboardType(.numberPad)  // Ensure only numbers can be entered
                    TextField("Handicap", text: $handicap)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationBarTitle("Add Friend", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Create") {
                if let handicapValue = Float(handicap) {
                    let ghinNumberValue = Int(ghinNumber)  // Convert to optional Int
                    let newGolfer = Golfer(
                        id: UUID().uuidString,
                        fullName: fullName,
                        handicap: handicapValue,
                        tee: nil,
                        ghinNumber: ghinNumberValue,
                        isChecked: false
                    )
                    golfers.append(newGolfer)
                    presentationMode.wrappedValue.dismiss()
                }
            })
        }
        .onAppear {
            if let golferToEdit = golferToEdit {
                fullName = golferToEdit.fullName
                ghinNumber = golferToEdit.ghinNumber != nil ? String(golferToEdit.ghinNumber!) : ""
                handicap = String(golferToEdit.handicap)
            }
        }
    }
}

struct CreateGolferView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGolferView(golfers: .constant([]), golferToEdit: .constant(nil), course: nil)
    }
}
