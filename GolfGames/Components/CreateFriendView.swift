//
//  CreateFriendView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/18/24.
//

import SwiftUI

struct CreateFriendView: View {
    @ObservedObject var viewModel: FriendsViewModel
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
                    viewModel.addFriend(fullName: fullName, ghinNumber: ghinNumberValue, handicap: handicapValue)
                    presentationMode.wrappedValue.dismiss()
                }
            })
        }
    }
}

//struct CreateFriendView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateFriendView(viewModel: FriendsViewModel(userId:))
//    }
//}
