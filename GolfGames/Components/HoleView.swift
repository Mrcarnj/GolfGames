
//
//  HoleView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import SwiftUI

struct HoleView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var sharedViewModel: SharedViewModel
    @State private var navigateToInitialView = false
    @State private var selectedScorecardType: ScorecardType = .strokePlay
    
    let teeId: String
    let initialHoleIndex: Int
    
    @State private var currentHoleIndex: Int
    @State private var scoreInputs: [String: String] = [:]
    @FocusState private var focusedGolferId: String?
    @State private var showMissingScores = false
    @State private var missingScores: [String: [Int]] = [:]
    @State private var holesLoaded = false
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var scores: [String: Int] = [:]
    @State private var currentHole: Int
    
    @State private var isLandscape = false
    @State private var showSideMenu = false
    @State private var viewSize: CGSize = .zero
    
    init(teeId: String, holeNumber: Int) {
        self.teeId = teeId
        self.initialHoleIndex = holeNumber - 1
        self._currentHoleIndex = State(initialValue: holeNumber - 1)
        self._scoreInputs = State(initialValue: [:])
        self._showMissingScores = State(initialValue: false)
        self._missingScores = State(initialValue: [:])
        self._holesLoaded = State(initialValue: false)
        self._orientation = State(initialValue: .unknown)
        self._scores = State(initialValue: [:])
        self._currentHole = State(initialValue: holeNumber)
    }
    
    var hole: Hole? {
        guard currentHoleIndex < singleRoundViewModel.holes.count else {
            // print("Error: currentHoleIndex (\(currentHoleIndex)) is out of range. Total holes: \(singleRoundViewModel.holes.count)")
            return nil
        }
        return singleRoundViewModel.holes[currentHoleIndex]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Group {
                    if isLandscape {
                        LandscapeScorecardView(
                            navigateToInitialView: $navigateToInitialView,
                            selectedScorecardType: $selectedScorecardType
                        )
                        .environmentObject(roundViewModel)
                        .environmentObject(singleRoundViewModel)
                        .environmentObject(authViewModel)
                    } else {
                        VStack(spacing: 0) {
                            customNavigationBar
                            
                            if holesLoaded {
                                portraitHoleContent
                                    .frame(width: viewSize.width, height: viewSize.height)
                            } else {
                                ProgressView("Loading hole data...")
                            }
                        }
                    }
                }

                if showSideMenu && !isLandscape {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                self.showSideMenu = false
                            }
                        }

                    HStack {
                        SideMenuView(isShowing: $showSideMenu, navigateToInitialView: $navigateToInitialView)
                            .frame(width: 250)
                            .transition(.move(edge: .leading))

                        Spacer()
                    }
                }
            }
            .onChange(of: geometry.size) { newSize in
                if !isLandscape {
                    viewSize = newSize
                }
            }
        }
        .onAppear {
            // print("HoleView appeared")
            // print("Round ID: \(roundViewModel.roundId ?? "nil")")
            // print("Selected Course: \(roundViewModel.selectedCourse?.name ?? "nil")")
            // print("Selected Tee: \(roundViewModel.selectedTee?.tee_name ?? "nil")")
            // print("Number of golfers: \(roundViewModel.golfers.count)")
            // print("Golfers: \(roundViewModel.golfers.map { $0.fullName })")
            
            if roundViewModel.roundId == nil {
                // print("Warning: No round has been started yet!")
            }
            
            loadHoleData()
            initializeScores()
            loadScores()
            
            // Sync the local state with the ViewModel when the view appears
            selectedScorecardType = roundViewModel.selectedScorecardType
            
            unlockOrientation()
        }
        .onDisappear {
            lockOrientation()
        }
        .onRotate { newOrientation in
            isLandscape = newOrientation.isLandscape
            if isLandscape {
                OrientationHelper.setOrientation(to: .landscapeRight)
                showSideMenu = false  // Hide side menu when rotating to landscape
            } else {
                OrientationHelper.setOrientation(to: .portrait)
                // Ensure the view size is updated when rotating back to portrait
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        viewSize = windowScene.screen.bounds.size
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .background(
            NavigationLink(destination: InititalView()
                .environmentObject(authViewModel)
                .environmentObject(roundViewModel),
                           isActive: $navigateToInitialView) {
                               EmptyView()
                           }
        )
    }
    
    private var customNavigationBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    withAnimation {
                        self.showSideMenu.toggle()
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .imageScale(.large)
                        .padding(.top)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .shadow(radius: 1)
            
            holeNavigation
        }
    }

    private var holeNavigation: some View {
        HStack {
            if currentHoleIndex > 0 {
                Button(action: {
                    currentHoleIndex -= 1
                    updateScoresForCurrentHole()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Hole \(currentHoleIndex)")
                    }
                    .fontWeight(.bold)
                }
                .padding()
            }
            
            Spacer()
            
            if currentHoleIndex < singleRoundViewModel.holes.count - 1 {
                Button(action: {
                    if roundViewModel.isMatchPlay {
                        roundViewModel.recalculateTallies(upToHole: currentHoleIndex + 1)
                        roundViewModel.updateMatchStatus(for: currentHoleIndex + 1)
                    }
                    currentHoleIndex += 1
                    updateScoresForCurrentHole()
                }) {
                    HStack {
                        Text("Hole \(currentHoleIndex + 2)")
                        Image(systemName: "arrow.right")
                    }
                    .fontWeight(.bold)
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var portraitHoleContent: some View {
        VStack {
            // Hole Details
            VStack {
                Text("Hole \(hole?.holeNumber ?? 0)")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(3)
                    .background(Color(.systemTeal).opacity(0.3))
                
                Text("\(hole?.yardage ?? 0) Yards")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)
                
                Text("Par \(hole?.par ?? 0)")
                    .font(.system(size: 19))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)
                    .background(Color.gray.opacity(0.3))
                
                Text("Handicap \(hole?.handicap ?? 0)")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(0.5)
            }
            .frame(width: UIScreen.main.bounds.width - 32)
            .padding(5)
            .border(Color.secondary)
            .cornerRadius(10)
            
            ScrollView {
                VStack {
                    if roundViewModel.isMatchPlay {
                        Text(matchStatusText)
                            .font(.headline)
                            .padding()
                    }
                    // Scores for each golfer
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
                    
                    ForEach(roundViewModel.golfers, id: \.id) { golfer in
                        VStack {
                            HStack {
                                Text(golfer.fullName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack {
                                    TextField("", text: Binding(
                                        get: { scoreInputs[golfer.id] ?? "" },
                                        set: { newValue in
                                            scoreInputs[golfer.id] = newValue
                                            updateScore(for: golfer.id, score: newValue)
                                        }
                                    ))
                                    .keyboardType(.numberPad)
                                    .focused($focusedGolferId, equals: golfer.id)
                                    .frame(width: 50, height: 50)
                                    .background(colorScheme == .dark ? Color.white : Color.gray.opacity(0.2))
                                    .foregroundColor(colorScheme == .dark ? .black : .primary)
                                    .cornerRadius(5)
                                    .multilineTextAlignment(.center)
                                    
                                    if isStrokeHole(for: golfer.id) {
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 6, height: 6)
                                            .offset(x: -20, y: -17)
                                    }
                                    Text(strokeHoleText(for: golfer.id))
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            
                            if showMissingScores, let missingHoles = missingScores[golfer.id], !missingHoles.isEmpty {
                                Text("Golfer \(golfer.fullName) is missing scores for holes: \(missingHoles.map(String.init).joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            if hole?.holeNumber == 18 {
                Button("Check Scores") {
                    checkScores()
                }
                .padding()
                
                if showMissingScores && roundViewModel.allScoresEntered(for: currentHoleIndex + 1) {
                    NavigationLink(destination: ScorecardView()
                        .environmentObject(roundViewModel)
                        .environmentObject(singleRoundViewModel)
                        .environmentObject(authViewModel)) {
                            Text("Review")
                                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
                                .foregroundColor(.white)
                                .background(Color(.systemTeal))
                                .cornerRadius(10)
                        }
                        .padding()
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    let threshold: CGFloat = 50
                    if gesture.translation.width > threshold && currentHoleIndex > 0 {
                        // Swipe right (previous hole)
                        currentHoleIndex -= 1
                        updateScoresForCurrentHole()
                    } else if gesture.translation.width < -threshold && currentHoleIndex < singleRoundViewModel.holes.count - 1 {
                        // Swipe left (next hole)
                        if roundViewModel.isMatchPlay {
                            roundViewModel.recalculateTallies(upToHole: currentHoleIndex + 1)
                            roundViewModel.updateMatchStatus(for: currentHoleIndex + 1)
                        }
                        currentHoleIndex += 1
                        updateScoresForCurrentHole()
                    }
                }
        )
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    if let golferId = focusedGolferId,
                       let golfer = roundViewModel.golfers.first(where: { $0.id == golferId }) {
                        let score = scoreInputs[golferId] ?? ""
                        updateScore(for: golferId, score: score)
                    }
                    focusedGolferId = nil
                }
            }
        }
    }
    
    private func loadHoleData() {
        // print("loadHoleData called in HoleView")
        guard let courseId = roundViewModel.selectedCourse?.id,
              let teeId = roundViewModel.selectedTee?.id else {
            // print("Course or Tee not selected in RoundViewModel")
            return
        }
        
        // print("Loading holes for Course ID: \(courseId), Tee ID: \(teeId)")
        singleRoundViewModel.loadHoles(for: courseId, teeId: teeId) { loadedHoles in
            self.holesLoaded = true
            //   print("Holes loaded in HoleView: \(loadedHoles.count)")
            // print("Holes: \(loadedHoles.map { "Hole \($0.holeNumber): Par \($0.par)" }.joined(separator: ", "))")
        }
    }
    
    private func initializeScores() {
        updateScoresForCurrentHole()
    }
    
    private func updateScoresForCurrentHole() {
        let currentHoleNumber = currentHoleIndex + 1
        scoreInputs = roundViewModel.grossScores[currentHoleNumber]?.mapValues { String($0) } ?? [:]
        
        // Ensure all golfers have an entry in scoreInputs
        for golfer in roundViewModel.golfers {
            if scoreInputs[golfer.id] == nil {
                scoreInputs[golfer.id] = ""  // Set to empty string instead of par value
            }
        }
        
        print("Updated scores for Hole \(currentHoleNumber): \(scoreInputs)")
    }
    
    private func updateScore(for golferId: String, score: String) {
        let currentHoleNumber = currentHoleIndex + 1
        if let scoreInt = Int(score) {
            roundViewModel.grossScores[currentHoleNumber, default: [:]][golferId] = scoreInt
            roundViewModel.updateStrokePlayNetScores()
            
            let netStrokePlayScore = roundViewModel.netStrokePlayScores[currentHoleNumber]?[golferId] ?? scoreInt
            let isStrokePlayStrokeHole = roundViewModel.strokeHoles[golferId]?.contains(currentHoleNumber) ?? false
            
            var logMessage = "Score updated - Golfer: \(roundViewModel.golfers.first(where: { $0.id == golferId })?.fullName ?? "Unknown"), Hole: \(currentHoleNumber), Gross Score: \(scoreInt), Stroke Play Net Score: \(netStrokePlayScore), Stroke Play Stroke Hole: \(isStrokePlayStrokeHole)"
            
            if roundViewModel.isMatchPlay {
                let isMatchPlayStrokeHole = roundViewModel.matchPlayStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
                let matchPlayNetScore = isMatchPlayStrokeHole ? scoreInt - 1 : scoreInt
                
                roundViewModel.matchPlayNetScores[currentHoleNumber, default: [:]][golferId] = matchPlayNetScore
                
                logMessage += ", Match Play Net Score: \(matchPlayNetScore), Match Play Stroke Hole: \(isMatchPlayStrokeHole)"
            }
            
            print(logMessage)
        } else {
            roundViewModel.grossScores[currentHoleNumber, default: [:]][golferId] = nil
            roundViewModel.netStrokePlayScores[currentHoleNumber, default: [:]][golferId] = nil
            if roundViewModel.isMatchPlay {
                roundViewModel.matchPlayNetScores[currentHoleNumber, default: [:]][golferId] = nil
                roundViewModel.holeWinners[currentHoleNumber] = nil
                roundViewModel.resetTallyForHole(currentHoleNumber)
            }
        }
        
        if roundViewModel.isMatchPlay && roundViewModel.allScoresEntered(for: currentHoleNumber) {
            roundViewModel.updateTallies(for: currentHoleNumber)
        }
    }
    
    private func checkScores() {
        showMissingScores = true
        for golfer in roundViewModel.golfers {
            missingScores[golfer.id] = roundViewModel.getMissingScores(for: golfer.id)
        }
    }
    
    private func saveScores() {
        for (golferId, score) in scores {
            roundViewModel.updateScore(for: currentHole, golferId: golferId, score: score)
        }
        if sharedViewModel.isMatchPlay {
            let currentHoleNumber = currentHoleIndex + 1  // Convert zero-based index to one-based hole number
        }
    }
    
    private func loadScores() {
        for golfer in roundViewModel.golfers {
            scores[golfer.id] = roundViewModel.grossScores[currentHole]?[golfer.id] ?? roundViewModel.pars[currentHole] ?? 0
        }
    }
    
    private func isStrokeHole(for golferId: String) -> Bool {
        let currentHoleNumber = currentHoleIndex + 1
        if roundViewModel.isMatchPlay {
            return roundViewModel.matchPlayStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        } else {
            return roundViewModel.strokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        }
    }
    
    private func strokeHoleText(for golferId: String) -> String {
        if roundViewModel.isMatchPlay {
            return isStrokeHole(for: golferId) ? "Match Stroke" : "No Stroke"
        } else {
            return isStrokeHole(for: golferId) ? "Stroke" : "No Stroke"
        }
    }
    
    private var matchStatusText: String {
        guard roundViewModel.isMatchPlay && roundViewModel.golfers.count >= 2 else {
            return ""
        }
        
        if let winner = roundViewModel.matchWinner, let score = roundViewModel.winningScore {
            return "\(winner) has won \(score)"
        }
        
        let player1 = roundViewModel.golfers[0]
        let player2 = roundViewModel.golfers[1]
        
        if roundViewModel.matchScore == 0 {
            return "All Square through \(roundViewModel.holesPlayed)"
        } else {
            let leadingPlayer = roundViewModel.matchScore > 0 ? player1.fullName : player2.fullName
            let absScore = abs(roundViewModel.matchScore)
            let remainingHoles = 18 - roundViewModel.holesPlayed
            
            if absScore == remainingHoles {
                return "\(leadingPlayer) \(absScore)UP with \(remainingHoles) to play (Dormie)"
            } else {
                return "\(leadingPlayer) \(absScore)UP thru \(roundViewModel.holesPlayed)"
            }
        }
    }
    
    private func unlockOrientation() {
        AppDelegate.lockOrientation(.allButUpsideDown)
    }

    private func lockOrientation() {
        AppDelegate.lockOrientation(.portrait)
    }
}

struct MatchPlayStatusView: View {
    @EnvironmentObject var roundViewModel: RoundViewModel
    
    var body: some View {
        if let status = roundViewModel.matchPlayViewModel?.getMatchStatus() {
            Text(status)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

struct HoleView_Previews: PreviewProvider {
    static var previews: some View {
        HoleView(teeId: "mockTeeId", holeNumber: 1)
            .environmentObject(AuthViewModel(mockUser: User.MOCK_USER))
            .environmentObject(RoundViewModel())
            .environmentObject(SingleRoundViewModel())
            .environmentObject(SharedViewModel())
    }
}
