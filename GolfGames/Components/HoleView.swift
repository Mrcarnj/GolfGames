

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
    @State private var navigateToFriendsList = false
    
    let teeId: String
    let initialHoleIndex: Int
    
    @State private var currentHoleIndex: Int
    @State private var scoreInputs: [String: String] = [:]
    @FocusState private var focusedField: String?
    @State private var showMissingScores = false
    @State private var missingScores: [String: [Int]] = [:]
    @State private var holesLoaded = false
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var scores: [String: Int] = [:]
    @State private var currentHole: Int
    
    @State private var isLandscape = false
    @State private var showSideMenu = false
    @State private var viewSize: CGSize = .zero
    @State private var showingPressConfirmation = false
    @State private var scoresChecked = false
    
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
                        SideMenuView(isShowing: $showSideMenu,
                                     navigateToInitialView: $navigateToInitialView,
                                     showDiscardButton: true)
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
            loadHoleData()
            initializeScores()
            loadScores()
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
                showSideMenu = false
            } else {
                OrientationHelper.setOrientation(to: .portrait)
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
        .alert(isPresented: $showingPressConfirmation) {
            Alert(
                title: Text("Confirm Press"),
                message: Text("Are you sure you want to initiate a press?"),
                primaryButton: .default(Text("Yes")) {
                    if let losingPlayer = roundViewModel.getLosingPlayer() {
                        roundViewModel.initiatePress(atHole: currentHoleIndex + 1)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
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
                        
                        // Explicitly update all presses
                        for pressIndex in roundViewModel.presses.indices {
                            if currentHoleIndex + 1 >= roundViewModel.presses[pressIndex].startHole {
                                roundViewModel.updatePressMatchStatus(pressIndex: pressIndex, for: currentHoleIndex + 1)
                            }
                        }
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
            HoleDetailsView(hole: hole)
            
            ScrollView {
                VStack {
                    matchPlayStatusView
                    pressStatusesView
                    scoreHeaderView
                    golferScoresView
                    checkScoresButton
                    reviewRoundButton
                }
            }
        }
        .gesture(holeNavigationGesture)
    }
    
    private var matchPlayStatusView: some View {
        Group {
            if roundViewModel.isMatchPlay {
                Text(roundViewModel.matchPlayStatus ?? "")
                    .font(.headline)
                    .padding(.vertical, 5)
            }
        }
    }
    
    private var pressStatusesView: some View {
        ForEach(roundViewModel.pressStatuses, id: \.self) { pressStatus in
            Text(pressStatus)
                .font(.subheadline)
                .padding(.horizontal)
        }
    }
    
    private var scoreHeaderView: some View {
        HStack {
            Text("Golfer")
            Spacer()
            Text("Score")
            if roundViewModel.isMatchPlay {
                Text("Press")
                    .frame(width: 60)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .fontWeight(.bold)
        .foregroundColor(Color.primary)
        .background(Color.secondary)
    }
    
    private var golferScoresView: some View {
        ForEach(roundViewModel.golfers, id: \.id) { golfer in
            HStack {
                Text(golfer.formattedName(golfers: roundViewModel.golfers))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScoreInputView(
                    scoreInputs: $scoreInputs,
                    golfer: golfer,
                    strokeHoleInfo: strokeHoleInfo(for: golfer.id),
                    updateScore: updateScore
                )
                .focused($focusedField, equals: golfer.id)
                
                if roundViewModel.isMatchPlay {
                    pressButton(for: golfer)
                }
            }
            .padding(.horizontal)
            
            if showMissingScores, let missingHoles = missingScores[golfer.id], !missingHoles.isEmpty {
                Text("Golfer \(golfer.formattedName(golfers: roundViewModel.golfers)) is missing scores for holes: \(missingHoles.map(String.init).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var checkScoresButton: some View {
        Group {
            if currentHoleIndex == 17 && roundViewModel.allScoresEntered(for: currentHoleIndex + 1) {
                Button("Check For Missing Scores") {
                    checkScores()
                    scoresChecked = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    private var reviewRoundButton: some View {
        Group {
            if showMissingScores && roundViewModel.allScoresEntered(for: currentHoleIndex + 1) {
                NavigationLink(destination: ScorecardView()
                    .environmentObject(roundViewModel)
                    .environmentObject(singleRoundViewModel)
                    .environmentObject(authViewModel)) {
                        Text("Review Round")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemTeal))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
            }
        }
    }
    
    private func pressButton(for golfer: Golfer) -> some View {
        Group {
            if let (leadingPlayer, trailingPlayer, score) = roundViewModel.getCurrentPressStatus() {
                ZStack {
                    if score == 0 {
                        Text("")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    } else if trailingPlayer?.id == golfer.id && roundViewModel.currentPressStartHole == nil &&
                                (roundViewModel.matchWinner == nil || !roundViewModel.presses.isEmpty) &&
                                !scoresChecked && currentHoleIndex < 17 {
                        Button(action: {
                            showingPressConfirmation = true
                        }) {
                            Text("Press")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 50, height: 24)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .frame(width: 60, height: 30)
            }
        }
    }
    
    private var holeNavigationGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                let threshold: CGFloat = 50
                if gesture.translation.width > threshold && currentHoleIndex > 0 {
                    currentHoleIndex -= 1
                    updateScoresForCurrentHole()
                } else if gesture.translation.width < -threshold && currentHoleIndex < singleRoundViewModel.holes.count - 1 {
                    if roundViewModel.isMatchPlay {
                        roundViewModel.recalculateTallies(upToHole: currentHoleIndex + 1)
                        roundViewModel.updateMatchStatus(for: currentHoleIndex + 1)
                    }
                    currentHoleIndex += 1
                    updateScoresForCurrentHole()
                }
            }
    }
    
    private func loadHoleData() {
        guard let courseId = roundViewModel.selectedCourse?.id,
              let teeId = roundViewModel.selectedTee?.id else {
            return
        }
        
        singleRoundViewModel.loadHoles(for: courseId, teeId: teeId) { loadedHoles in
            self.holesLoaded = true
        }
    }
    
    private func initializeScores() {
        updateScoresForCurrentHole()
    }
    
    private func updateScoresForCurrentHole() {
        let currentHoleNumber = currentHoleIndex + 1
        scoreInputs = roundViewModel.grossScores[currentHoleNumber]?.mapValues { String($0) } ?? [:]
        
        for golfer in roundViewModel.golfers {
            if scoreInputs[golfer.id] == nil {
                scoreInputs[golfer.id] = ""
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
            
            var logMessage = "Score updated - Golfer: \(roundViewModel.golfers.first(where: { $0.id == golferId })?.formattedName(golfers: roundViewModel.golfers) ?? "Unknown"), Hole: \(currentHoleNumber), Gross Score: \(scoreInt), Stroke Play Net Score: \(netStrokePlayScore), Stroke Play Stroke Hole: \(isStrokePlayStrokeHole)"
            
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
            roundViewModel.currentPressStartHole = nil  // Reset the current press start hole
        }
        
        // Force view update
        roundViewModel.forceUIUpdate()
    }
    
    private func checkScores() {
        showMissingScores = true
        for golfer in roundViewModel.golfers {
            missingScores[golfer.id] = roundViewModel.getMissingScores(for: golfer.id)
        }
        
        // If there are no missing scores, update the final match status
        if missingScores.values.allSatisfy({ $0.isEmpty }) {
            roundViewModel.updateFinalMatchStatus()
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
    
    private func strokeHoleInfo(for golferId: String) -> (isStrokeHole: Bool, isNegativeHandicap: Bool) {
        let currentHoleNumber = currentHoleIndex + 1
        let courseHandicap = roundViewModel.courseHandicaps[golferId] ?? 0
        let isNegativeHandicap = courseHandicap < 0
        
        if roundViewModel.isMatchPlay {
            let isStrokeHole = roundViewModel.matchPlayStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
            return (isStrokeHole, isNegativeHandicap)
        } else {
            let isStrokeHole = roundViewModel.strokeHoles[golferId]?.contains(currentHoleNumber) ?? false
            return (isStrokeHole, isNegativeHandicap)
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
        if let (player1, player2) = roundViewModel.matchPlayGolfers,
           let status = roundViewModel.matchPlayViewModel?.getMatchStatus() {
            Text("\(player1.formattedName(golfers: roundViewModel.golfers)) vs \(player2.formattedName(golfers: roundViewModel.golfers)): \(status)")
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

private struct HoleDetailsView: View {
    let hole: Hole?
    
    var body: some View {
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
    }
}

private struct ScoreInputView: View {
    @Binding var scoreInputs: [String: String]
    @FocusState var focusedField: String?
    @Environment(\.colorScheme) var colorScheme
    let golfer: Golfer
    let strokeHoleInfo: (isStrokeHole: Bool, isNegativeHandicap: Bool)
    let updateScore: (String, String) -> Void
    
    var body: some View {
        TextField("", text: Binding(
            get: { scoreInputs[golfer.id] ?? "" },
            set: { newValue in
                scoreInputs[golfer.id] = newValue
                updateScore(golfer.id, newValue)
            }
        ))
        .keyboardType(.numberPad)
        .focused($focusedField, equals: golfer.id)
        .frame(width: 50, height: 50)
        .background(colorScheme == .dark ? Color.white : Color.gray.opacity(0.2))
        .foregroundColor(colorScheme == .dark ? .black : .primary)
        .cornerRadius(5)
        .multilineTextAlignment(.center)
        .overlay(
            Group {
                if strokeHoleInfo.isStrokeHole {
                    if strokeHoleInfo.isNegativeHandicap {
                        Text("+")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 10, height: 10)
                            .offset(x: 15, y: -17)
                    } else {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 6, height: 6)
                            .offset(x: 20, y: -17)
                    }
                }
            }
        )
    }
}
