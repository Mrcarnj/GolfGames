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
    @Binding var courseId: String
    @Binding var teeId: String
    @StateObject var roundViewModel: RoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @Binding var additionalGolfers: [Golfer]
    @Binding var selectedTee: Tee?
    @Binding var playingHandicap: Int?

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
                    additionalGolfers: $additionalGolfers,
                    alreadyAddedGolfers: Set(additionalGolfers.map { $0.id })
                )
                .environmentObject(singleRoundViewModel)
                .environmentObject(authViewModel)
            }

            if let currentUser = authViewModel.currentUser {
                let golfer = convertUserToGolfer(user: currentUser)

                HStack {
                    TeePickerView(
                        selectedTee: $selectedTee,
                        playingHandicap: $playingHandicap,
                        currentGolfer: golfer
                    )
                    .environmentObject(singleRoundViewModel)
                }
            }
        }
    }
}

func convertUserToGolfer(user: User) -> Golfer {
    return Golfer(id: user.id, fullName: user.fullname, handicap: user.handicap ?? 0.0, tee: nil, ghinNumber: user.ghinNumber, isChecked: false)
}
