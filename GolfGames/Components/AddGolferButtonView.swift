//
//  AddGolferButtonView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/19/24.
//

import SwiftUI

struct AddGolferButtonView: View {
    @Binding var showingAddGolferSheet: Bool
    @Binding var formIsValid: Bool
    @Binding var navigateToRoundView: Bool
    @Binding var roundId: String?
    @StateObject var roundViewModel: RoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @Binding var additionalGolfers: [Golfer]

    var body: some View {
        VStack {
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
                    selectedFriends: $additionalGolfers,
                    onDone: {
                        showingAddGolferSheet = false
                    },
                    allowSelection: true
                )
                .environmentObject(singleRoundViewModel)
                .environmentObject(authViewModel)
            }

            Button(action: {
                if let currentUser = authViewModel.currentUser {
                    roundViewModel.beginRound(
                        for: currentUser,
                        additionalGolfers: additionalGolfers,
                        isMatchPlay: sharedViewModel.isMatchPlay
                    ) { roundId, error, additionalInfo in
                        if let roundId = roundId {
                            self.roundId = roundId
                            self.navigateToRoundView = true
                        } else if let error = error {
                            print("Failed to create round: \(error.localizedDescription)")
                        }
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
        }
    }
}

func convertUserToGolfer(user: User) -> Golfer {
    return Golfer(id: user.id, fullName: user.fullname, handicap: user.handicap ?? 0.0, ghinNumber: user.ghinNumber, isChecked: false)
}

struct AddGolferButtonView_Previews: PreviewProvider {
    static var previews: some View {
        AddGolferButtonView(
            showingAddGolferSheet: .constant(false),
            formIsValid: .constant(true),
            navigateToRoundView: .constant(false),
            roundId: .constant(nil),
            roundViewModel: RoundViewModel(),
            additionalGolfers: .constant([])
        )
        .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
        .environmentObject(SingleRoundViewModel())
        .environmentObject(SharedViewModel())
    }
}
