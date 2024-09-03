


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
    let roundType: RoundType
    
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
    @State private var showNinePointWinner = false
    @State private var currentCarouselPage = 0
    
    private var startingHoleIndex: Int {
        switch roundType {
        case .full18, .front9:
            return 0
        case .back9:
            return 9
        }
    }

    private var endingHoleIndex: Int {
        switch roundType {
        case .full18:
            return 17
        case .front9:
            return 8
        case .back9:
            return 17
        }
    }
    
    init(teeId: String, holeNumber: Int, roundType: RoundType) {
        self.teeId = teeId
        self.roundType = roundType
        let initialHole = holeNumber ?? (roundType == .back9 ? 10 : 1)
        self._currentHoleIndex = State(initialValue: initialHole - 1)
        self._scoreInputs = State(initialValue: [:])
        self._showMissingScores = State(initialValue: false)
        self._missingScores = State(initialValue: [:])
        self._holesLoaded = State(initialValue: false)
        self._orientation = State(initialValue: .unknown)
        self._scores = State(initialValue: [:])
        self._currentHole = State(initialValue: initialHole)
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
                    if roundViewModel.isMatchPlay {
                        if let losingPlayer = MatchPlayPressModel.getLosingPlayer(roundViewModel: roundViewModel) {
                            MatchPlayPressModel.initiatePress(roundViewModel: roundViewModel, atHole: currentHoleIndex + 1)
                        }
                    } else if roundViewModel.isBetterBall {
                        if let losingTeam = BetterBallPressModel.getLosingTeam(roundViewModel: roundViewModel) {
                            BetterBallPressModel.initiateBetterBallPress(roundViewModel: roundViewModel, atHole: currentHoleIndex + 1)
                        }
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
            if currentHoleIndex > startingHoleIndex {
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
            
            if currentHoleIndex < endingHoleIndex {
                Button(action: {
                    if roundViewModel.isMatchPlay {
                        MatchPlayModel.recalculateTallies(roundViewModel: roundViewModel, upToHole: currentHoleIndex + 1)
                        MatchPlayModel.updateMatchStatus(roundViewModel: roundViewModel, for: currentHoleIndex + 1)
                        
                        // Explicitly update all presses
                        for pressIndex in roundViewModel.presses.indices {
                            if currentHoleIndex + 1 >= roundViewModel.presses[pressIndex].startHole {
                                MatchPlayPressModel.updatePressMatchStatus(roundViewModel: roundViewModel, pressIndex: pressIndex, for: currentHoleIndex + 1)
                            }
                        }
                    }
                    
                    if roundViewModel.isBetterBall {
                        BetterBallModel.recalculateBetterBallTallies(roundViewModel: roundViewModel, upToHole: currentHoleIndex + 1)
                        BetterBallModel.updateBetterBallMatchStatus(roundViewModel: roundViewModel, for: currentHoleIndex + 1)
                        
                        // Explicitly update all Better Ball presses
                        for pressIndex in roundViewModel.betterBallPresses.indices {
                            if currentHoleIndex + 1 >= roundViewModel.betterBallPresses[pressIndex].startHole {
                                BetterBallPressModel.updateBetterBallPressMatchStatus(roundViewModel: roundViewModel, pressIndex: pressIndex, for: currentHoleIndex + 1)
                            }
                        }
                    }
                    
                    if roundViewModel.isNinePoint {
                        // Recalculate Nine Point scores up to the current hole
                        NinePointModel.recalculateNinePointScores(roundViewModel: roundViewModel, upToHole: currentHoleIndex + 1)
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
            
            gameStatusCarousel
            
            scoreHeaderView
            
            ScrollView {
                VStack {
                    golferScoresView
                    checkScoresButton
                    reviewRoundButton
                }
            }
        }
        .gesture(holeNavigationGesture)
    }
    
    private var gameStatusCarousel: some View {
        let pages = carouselPages
        
        return VStack {
            TabView(selection: $currentCarouselPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pages[index]
                        .tag(index)
                        .frame(height: getPageHeight(for: index))
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: getMaxPageHeight())
            
            // Custom page indicators
            if pages.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentCarouselPage ? Color.blue : Color.gray)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func getPageHeight(for index: Int) -> CGFloat {
        switch index {
        case 0 where roundViewModel.isMatchPlay:
            return CGFloat(100 + (roundViewModel.pressStatuses.count * 20))
        case 0 where roundViewModel.isBetterBall:
            return CGFloat(120 + (roundViewModel.betterBallPressStatuses.count * 15))
        case 0 where roundViewModel.isNinePoint:
            return CGFloat(80 + (roundViewModel.golfers.count * 25))
        default:
            return 150
        }
    }
    
    private func getMaxPageHeight() -> CGFloat {
        let heights = (0..<carouselPages.count).map { getPageHeight(for: $0) }
        return heights.max() ?? 150
    }
    
    private var carouselPages: [AnyView] {
        var pages: [AnyView] = []

        if roundViewModel.isMatchPlay {
            pages.append(AnyView(matchStatusView))
        }

        if roundViewModel.isBetterBall {
            pages.append(AnyView(BetterBallTeamsView()))
        }

        if roundViewModel.isNinePoint {
            pages.append(AnyView(NinePointScoresView(showWinner: $showNinePointWinner)))
        }

        // If no game types are selected, show a default view
        if pages.isEmpty {
            pages.append(AnyView(
                Text("No game types selected")
                    .font(.headline)
                    .foregroundColor(.secondary)
            ))
        }

        return pages
    }
    
    private var matchStatusView: some View {
        VStack(alignment: .center, spacing: 8) {
            if roundViewModel.isMatchPlay {
                if let (golfer1, golfer2) = roundViewModel.matchPlayGolfers {
                    Text("\(golfer1.firstName) vs \(golfer2.firstName)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text(roundViewModel.matchPlayStatus ?? "Match Play Status Not Available")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.vertical, 4)
                
                if !roundViewModel.pressStatuses.isEmpty {
                    Text("Presses")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top, 4)
                    
                    ForEach(roundViewModel.pressStatuses, id: \.self) { pressStatus in
                        Text(pressStatus)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private struct BetterBallTeamsView: View {
        @EnvironmentObject var roundViewModel: RoundViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                Text("Better Ball")
                    .font(.headline)
                    .padding(.bottom, 2)
                
                ForEach(["Team A", "Team B"], id: \.self) { team in
                    HStack {
                        Text("\(team):")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        let teamMembers = roundViewModel.golfers
                            .filter { roundViewModel.betterBallTeamAssignments[$0.id] == team }
                            .map { $0.formattedName(golfers: roundViewModel.golfers) }
                            .joined(separator: " / ")
                        
                        Text(teamMembers)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                betterBallStatusSection
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .fixedSize(horizontal: true, vertical: false)
        }
        
        private var betterBallStatusSection: some View {
            VStack(alignment: .center, spacing: 2) {
                Text(roundViewModel.betterBallMatchStatus ?? "Better Ball Status Not Available")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                
                if !roundViewModel.betterBallPressStatuses.isEmpty {
                    Text("Presses:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top, 2)
                    
                    ForEach(roundViewModel.betterBallPressStatuses, id: \.self) { pressStatus in
                        Text(pressStatus)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private struct NinePointScoresView: View {
        @EnvironmentObject var roundViewModel: RoundViewModel
        @Binding var showWinner: Bool
        
        var body: some View {
            if roundViewModel.isNinePoint {
                VStack(alignment: .center, spacing: 4) {
                    Text("Nine Point Scores")
                        .font(.headline)
                        .padding(.bottom, 2)
                    
                    let sortedGolfers = roundViewModel.golfers.sorted {
                        (roundViewModel.ninePointTotalScores[$0.id] ?? 0) > (roundViewModel.ninePointTotalScores[$1.id] ?? 0)
                    }
                    
                    ForEach(sortedGolfers, id: \.id) { golfer in
                        HStack {
                            if showWinner && golfer == sortedGolfers.first {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text(golfer.formattedName(golfers: roundViewModel.golfers))
                                .fontWeight(.semibold)
                            Text("\(roundViewModel.ninePointTotalScores[golfer.id] ?? 0) points")
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var scoreHeaderView: some View {
        HStack {
            Text("Golfer")
            Spacer()
            Text("Score")
                .frame(width: 90, alignment: .trailing)
            if roundViewModel.isMatchPlay || roundViewModel.isBetterBall {
                Text("Press")
                    .frame(width: 90, alignment: .trailing)
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
                
                if roundViewModel.isMatchPlay || roundViewModel.isBetterBall {
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
            if currentHoleIndex == endingHoleIndex && roundViewModel.allScoresEntered(for: currentHoleIndex + 1) {
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
            if roundViewModel.isMatchPlay {
                matchPlayPressButton(for: golfer)
            } else if roundViewModel.isBetterBall {
                betterBallPressButton(for: golfer)
            }
        }
    }
    
    private func matchPlayPressButton(for golfer: Golfer) -> some View {
        Group {
            if let (leadingPlayer, trailingPlayer, score) = MatchPlayPressModel.getCurrentPressStatus(roundViewModel: roundViewModel) {
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
    
    private func betterBallPressButton(for golfer: Golfer) -> some View {
        Group {
            if let (leadingTeam, trailingTeam, score) = BetterBallPressModel.getCurrentBetterBallPressStatus(roundViewModel: roundViewModel) {
                ZStack {
                    if score == 0 {
                        Text("")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    } else if let trailingTeam = trailingTeam,
                              roundViewModel.betterBallTeamAssignments[golfer.id] == trailingTeam,
                              isFirstPlayerOfTeam(golfer, team: trailingTeam),
                              (roundViewModel.betterBallMatchWinner == nil || !roundViewModel.betterBallPresses.isEmpty),
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
            }
        }
        .frame(width: 60, height: 30)
    }
    
    private func isFirstPlayerOfTeam(_ golfer: Golfer, team: String) -> Bool {
        let teamPlayers = roundViewModel.golfers.filter { roundViewModel.betterBallTeamAssignments[$0.id] == team }
        return teamPlayers.first?.id == golfer.id
    }
    
    private var holeNavigationGesture: some Gesture {
        DragGesture()
            .onEnded { gesture in
                let threshold: CGFloat = 50
                if gesture.translation.width > threshold && currentHoleIndex > startingHoleIndex {
                    currentHoleIndex -= 1
                    updateScoresForCurrentHole()
                } else if gesture.translation.width < -threshold && currentHoleIndex < endingHoleIndex {
                    if roundViewModel.isMatchPlay {
                        MatchPlayModel.recalculateTallies(roundViewModel: roundViewModel, upToHole: currentHoleIndex + 1)
                        MatchPlayModel.updateMatchStatus(roundViewModel: roundViewModel, for: currentHoleIndex + 1)
                    }
                    if roundViewModel.isBetterBall {
                        BetterBallModel.recalculateBetterBallTallies(roundViewModel: roundViewModel, upToHole: currentHoleIndex + 1)
                        BetterBallModel.updateBetterBallMatchStatus(roundViewModel: roundViewModel, for: currentHoleIndex + 1)
                    }
                    
                    if roundViewModel.isNinePoint {
                        // Recalculate Nine Point scores up to the current hole
                        NinePointModel.recalculateNinePointScores(roundViewModel: roundViewModel, upToHole: currentHoleIndex + 1)
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
        
        //print("HoleView updateScoresForCurrentHole() - Updated scores for Hole \(currentHoleNumber): \(scoreInputs)")
    }
    
    private func updateScore(for golferId: String, score: String) {
        let currentHoleNumber = currentHoleIndex + 1
        if let scoreInt = Int(score) {
            // Always update gross scores
            roundViewModel.grossScores[currentHoleNumber, default: [:]][golferId] = scoreInt
            
            // Always update stroke play scores
            StrokePlayModel.updateStrokePlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: currentHoleNumber, scoreInt: scoreInt)
            
            // Update game-specific scores
            if roundViewModel.isMatchPlay {
                MatchPlayModel.updateMatchPlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: currentHoleNumber, scoreInt: scoreInt)
            }
            
            if roundViewModel.isBetterBall {
                BetterBallModel.updateBetterBallScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: currentHoleNumber, scoreInt: scoreInt)
            }
            
            if roundViewModel.isNinePoint {
                NinePointModel.updateNinePointScore(roundViewModel: roundViewModel, holeNumber: currentHoleNumber)
            }
        } else {
            // Reset scores if the input is invalid
            roundViewModel.grossScores[currentHoleNumber, default: [:]][golferId] = nil
            roundViewModel.netStrokePlayScores[currentHoleNumber, default: [:]][golferId] = nil
            
            if roundViewModel.isMatchPlay {
                MatchPlayModel.resetMatchPlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: currentHoleNumber)
            }
            
            if roundViewModel.isBetterBall {
                BetterBallModel.resetBetterBallScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: currentHoleNumber)
            }
            
            if roundViewModel.isNinePoint {
                NinePointModel.resetNinePointScore(roundViewModel: roundViewModel, holeNumber: currentHoleNumber)
            }
        }
        
        // Update tallies if all scores are entered
        if roundViewModel.allScoresEntered(for: currentHoleNumber) {
            if roundViewModel.isMatchPlay {
                MatchPlayModel.updateMatchPlayTallies(roundViewModel: roundViewModel, currentHoleNumber: currentHoleNumber)
            }
            
            if roundViewModel.isBetterBall {
                BetterBallModel.updateBetterBallTallies(roundViewModel: roundViewModel, for: currentHoleNumber)
            }
            
            if roundViewModel.isNinePoint {
                // No need for additional tally updates for Nine Point, as it's done in updateNinePointScore
            }
            
            // Force view update
            roundViewModel.forceUIUpdate()
        }
    }
        
        private func checkScores() {
            showMissingScores = true
            for golfer in roundViewModel.golfers {
                missingScores[golfer.id] = getMissingScoresForRoundType(golferId: golfer.id)
            }
            
            // If there are no missing scores, update the final match status
            if missingScores.values.allSatisfy({ $0.isEmpty }) {
                if roundViewModel.isMatchPlay {
                    MatchPlayModel.updateFinalMatchStatus(roundViewModel: roundViewModel)
                } else if roundViewModel.isBetterBall {
                    BetterBallModel.updateFinalBetterBallMatchStatus(roundViewModel: roundViewModel)
                } else if roundViewModel.isNinePoint {
                    // Update Nine Point scoring for the last hole
                    let lastHole = roundViewModel.roundType == .front9 ? 9 : 18
                    NinePointModel.updateNinePointScore(roundViewModel: roundViewModel, holeNumber: lastHole)
                    // Display final results
                    _ = NinePointModel.displayFinalResults(roundViewModel: roundViewModel)
                    // Set showNinePointWinner to true
                    showNinePointWinner = true
                }
            }
            
            // Force view update
            roundViewModel.forceUIUpdate()
        }
        
        private func getMissingScoresForRoundType(golferId: String) -> [Int] {
            switch roundViewModel.roundType {
            case .full18:
                return roundViewModel.getMissingScores(for: golferId)
            case .front9:
                return roundViewModel.getMissingScores(for: golferId).filter { $0 <= 9 }
            case .back9:
                return roundViewModel.getMissingScores(for: golferId).filter { $0 > 9 }
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
        // print("Debug: HoleView strokeHoleInfo() - Match Play")
        return (isStrokeHole, isNegativeHandicap)
    } else if roundViewModel.isBetterBall {
        let isStrokeHole = roundViewModel.betterBallStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        // print("Debug: HoleView strokeHoleInfo() - Better Ball")
        return (isStrokeHole, isNegativeHandicap)
    } else if roundViewModel.isNinePoint {
        let isStrokeHole = roundViewModel.ninePointStrokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        // print("Debug: HoleView strokeHoleInfo() - Nine Point")
        return (isStrokeHole, isNegativeHandicap)
    } else {
        let isStrokeHole = roundViewModel.strokeHoles[golferId]?.contains(currentHoleNumber) ?? false
        // print("Debug: HoleView strokeHoleInfo() - Stroke Play")
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
    
    struct HoleView_Previews: PreviewProvider {
        static var previews: some View {
            HoleView(teeId: "mockTeeId", holeNumber: 1, roundType: .full18)
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
            .keyboardType(.decimalPad)
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
