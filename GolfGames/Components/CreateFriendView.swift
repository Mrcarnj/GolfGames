//
//  CreateFriendView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/18/24.
//

import SwiftUI

struct CreateFriendView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @Binding var friendToEdit: Golfer?
    @Environment(\.presentationMode) var presentationMode
    @State private var fullName = ""
    @State private var ghinNumber = ""
    @State private var handicap = ""
    @State private var isPlusHandicap = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Friend Information")) {
                    TextField("Full Name", text: $fullName)
                    TextField("GHIN (Optional)", text: $ghinNumber)
                        .keyboardType(.numberPad)
                    HStack {
                        Toggle(isOn: $isPlusHandicap) {
                            Text("+")
                        }
                        .fixedSize()
                        TextField("Handicap", text: $handicap)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationBarTitle(friendToEdit == nil ? "Add Friend" : "Edit Friend", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(friendToEdit == nil ? "Add" : "Update") {
                    friendToEdit == nil ? addFriend() : updateFriend()
                }
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            if let friend = friendToEdit {
                fullName = friend.fullName
                ghinNumber = friend.ghinNumber.map(String.init) ?? ""
                if friend.handicap < 0 {
                    isPlusHandicap = true
                    handicap = String(format: "%.1f", abs(friend.handicap))
                } else {
                    handicap = String(format: "%.1f", friend.handicap)
                }
            }
        }
    }

    private func addFriend() {
        guard validateInput() else { return }
        
        let ghinNumberValue = Int(ghinNumber)
        var handicapValue = Float(handicap) ?? 0.0
        if isPlusHandicap {
            handicapValue = -handicapValue
        }
        
        viewModel.addFriend(fullName: fullName, ghinNumber: ghinNumberValue, handicap: handicapValue) { result in
            handleResult(result)
        }
    }

    private func updateFriend() {
        guard validateInput() else { return }
        
        let ghinNumberValue = Int(ghinNumber)
        var handicapValue = Float(handicap) ?? 0.0
        if isPlusHandicap {
            handicapValue = -handicapValue
        }
        
        guard let friend = friendToEdit else { return }
        
        viewModel.updateFriend(friend, fullName: fullName, ghinNumber: ghinNumberValue, handicap: handicapValue) { result in
            handleResult(result)
        }
    }

    private func validateInput() -> Bool {
        guard !fullName.isEmpty else {
            alertMessage = "Please enter a name"
            showAlert = true
            return false
        }
        
        guard let _ = Float(handicap) else {
            alertMessage = "Please enter a valid handicap"
            showAlert = true
            return false
        }
        
        return true
    }

    private func handleResult(_ result: Result<Void, Error>) {
        switch result {
        case .success:
            presentationMode.wrappedValue.dismiss()
        case .failure(let error):
            alertMessage = "Failed to \(friendToEdit == nil ? "add" : "update") friend: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

//struct CreateFriendView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateFriendView(viewModel: FriendsViewModel(userId:))
//    }
//}