//
//  HoleView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import SwiftUI

struct HoleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var hole: Hole
    var onScoreChange: (String, String) -> Void
    var onNextHole: (() -> Void)?
    var onPreviousHole: (() -> Void)?
    var currentHoleNumber: Int
    var totalHoles: Int

    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @State private var scoreInputs: [String: String] = [:]
    @FocusState private var isTextFieldFocused: Bool
    @State private var currentHoleState: Int = 0

    var body: some View {
        VStack {
            // Navigation Arrows at the Top
            HStack {
                if currentHoleNumber > 1 {
                    Button(action: {
                        onPreviousHole?()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Hole \(currentHoleNumber - 1)")
                        }
                        .fontWeight(.bold)
                    }
                    .padding()
                }

                Spacer()

                if currentHoleNumber < totalHoles {
                    Button(action: {
                        onNextHole?()
                        currentHoleState += 1
                    }) {
                        HStack {
                            Text("Hole \(currentHoleNumber + 1)")
                            Image(systemName: "arrow.right")
                        }
                        .fontWeight(.bold)
                    }
                    .padding()
                } else {
                    // No next button on the last hole
                }
            }

            // Hole Details
            VStack {
                Text("Hole \(hole.holeNumber)")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(3)
                    .background(Color(.systemTeal).opacity(0.3))

                Text("\(hole.yardage) Yards")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)

                Text("Par \(hole.par)")
                    .font(.system(size: 19))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)
                    .background(Color.gray.opacity(0.3))

                Text("Handicap \(hole.handicap)")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)
            }
            .frame(width: UIScreen.main.bounds.width - 32)
            .padding(5)
            .border(Color.secondary)
            .cornerRadius(10)

            // Scores for each golfer
            VStack {
                HStack {
                    Text("Golfer")
                    Spacer()
                    Text("Score")
                }
                .frame(maxWidth: .infinity, maxHeight: 30)
                .padding(.leading)
                .padding(.trailing, 52)
                .fontWeight(.bold)
                .foregroundColor(Color.primary)
                .background(Color.secondary)
            }

            ForEach(roundViewModel.golfers, id: \.id) { golfer in
                VStack {
                    HStack {
                        Text(golfer.fullName)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            TextField("", text: Binding(
                                get: {
                                    if let score = roundViewModel.scores[currentHoleNumber]?[golfer.id] {
                                        return String(score)
                                    } else {
                                        return ""
                                    }
                                },
                                set: { newValue in
                                    scoreInputs[golfer.id] = newValue
                                    if let scoreInt = Int(newValue) {
                                        roundViewModel.scores[currentHoleNumber, default: [:]][golfer.id] = scoreInt
                                        roundViewModel.updateNetScores()
                                    }
                                }
                            ))
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isTextFieldFocused = false
                                        onScoreChange(golfer.id, scoreInputs[golfer.id] ?? "")
                                        if let scoreInt = Int(scoreInputs[golfer.id] ?? "") {
                                            roundViewModel.scores[currentHoleNumber, default: [:]][golfer.id] = scoreInt
                                            roundViewModel.updateNetScores()
                                            print("Scores: \(roundViewModel.scores.sorted { $0.key < $1.key })")
                                            print("Net Scores: \(roundViewModel.netScores.sorted { $0.key < $1.key })")
                                        }
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .multilineTextAlignment(.center)
                            .onAppear {
                                if currentHoleState == currentHoleNumber {
                                    isTextFieldFocused = true // Automatically focus the text field
                                }
                            }

                            if roundViewModel.strokeHoles[golfer.id]?.contains(hole.holeNumber) ?? false {
                                Circle()
                                    .fill(colorScheme == .dark ? Color.white : Color.black)
                                    .frame(width: 6, height: 6)
                                    .offset(x: -20, y: -17)
                            }
                        }
                    }
                    .padding()
                }
            }

            Spacer()
        }
        .onAppear {
            initializeScores()
            currentHoleState = currentHoleNumber
        }
        .navigationBarBackButtonHidden(true)
    }

    private func initializeScores() {
        scoreInputs = roundViewModel.scores[currentHoleNumber]?.mapValues { String($0) } ?? [:]
        // Ensure scoreInputs are cleared for the new hole if no scores are present
        for golfer in roundViewModel.golfers {
            if scoreInputs[golfer.id] == nil {
                scoreInputs[golfer.id] = ""
            }
        }
    }
}

struct HoleView_Previews: PreviewProvider {
    static var previews: some View {
        let mockHole = Hole(id: "mockHoleId", holeNumber: 1, par: 4, handicap: 15, yardage: 420)

        return HoleView(
            hole: mockHole,
            onScoreChange: { _, _ in },
            currentHoleNumber: 1,
            totalHoles: 18
        )
        .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
        .environmentObject(RoundViewModel())
    }
}
