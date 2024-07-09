//
//  HoleView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct HoleView: View {
    var hole: Hole
    var score: String
    var onScoreChange: (String) -> Void
    var onNextHole: (() -> Void)?
    var onPreviousHole: (() -> Void)?
    var currentHoleNumber: Int
    var totalHoles: Int
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var scoreInput: String = ""
    @State private var isEditing: Bool = false
    
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
                    }
                    .padding()
                }
                
                Spacer()
                
                if currentHoleNumber < totalHoles {
                    Button(action: {
                        onNextHole?()
                    }) {
                        HStack {
                            Text("Hole \(currentHoleNumber + 1)")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .padding()
                } else {
                    Button(action: {
                        // Navigate to review page
                    }) {
                        HStack {
                            Text("REVIEW")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .padding()
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
                    .foregroundColor(.black)
                
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
            .border(Color.black)
            .cornerRadius(10)
            
            // Player and Score
            VStack {
                HStack {
                    Text("Player")
                    Spacer()
                    Text("Score")
                }
                .frame(maxWidth: .infinity, maxHeight: 30)
                .padding(.leading)
                .padding(.trailing, 52)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .background(Color.black)
                
                HStack {
                    Text(authViewModel.currentUser?.fullname ?? "Unknown")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        if isEditing {
                            TextField("\(hole.par)", text: $scoreInput)
                                .keyboardType(.numberPad)
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                                .onSubmit {
                                    if let scoreInt = Int(scoreInput), scoreInt >= 1 && scoreInt <= 99 {
                                        isEditing = false
                                        onScoreChange(scoreInput)
                                    }
                                }
                        } else {
                            Text(score.isEmpty ? "\(hole.par)" : score)
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)
                                .multilineTextAlignment(.center)
                                .foregroundColor(score.isEmpty ? Color.gray.opacity(0.7) : .black)
                                .fontWeight(score.isEmpty ? .regular : .bold)
                        }
                    }
                    
                    Button(action: {
                        isEditing = true
                        scoreInput = score
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .padding(.leading, 5)
                }
                .padding()
            }
            
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Round")
    }
}

struct HoleView_Previews: PreviewProvider {
    static var previews: some View {
        let mockHole = Hole(id: "mockHoleId", holeNumber: 1, par: 4, handicap: 15, yardage: 420)

        return HoleView(hole: mockHole, score: "", onScoreChange: { _ in }, currentHoleNumber: 1, totalHoles: 18)
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
    }
}
