


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
    @FocusState private var focusedField: Golfer.ID?
    @State private var showMissingScores = false
    @State private var missingScores: [String: [Int]] = [:]
    @State private var holesLoaded = false
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var scores: [String: Int] = [:]
    @State private var currentHole: Int
    
    @State private var isLandscape = false
    @State private var showSideMenu = false
    @State private var viewWidth: CGFloat = UIScreen.main.bounds.width
    @State private var viewHeight: CGFloat = UIScreen.main.bounds.height
    @State private var showingPressConfirmation = false
    @State private var scoresChecked = false
    @State private var showNinePointWinner = false
    @State private var currentCarouselPage = 0
    @State private var showStablefordGrossWinner = false
    @State private var showStablefordNetWinner = false
    
    @State private var currentScoreToPar: [String: Int] = [:]
    
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
    
    init(teeId: String, holeNumber: Int?, roundType: RoundType) {
        self.teeId = teeId
        self.roundType = roundType
        let initialHole = holeNumber ?? (roundType == .back9 ? 10 : 1)
        self._currentHoleIndex = State(initialValue: initialHole - 1)
        self._currentHole = State(initialValue: initialHole)
        self._scoreInputs = State(initialValue: [:])
        self._showMissingScores = State(initialValue: false)
        self._missingScores = State(initialValue: [:])
        self._holesLoaded = State(initialValue: false)
        self._orientation = State(initialValue: .unknown)
        self._scores = State(initialValue: [:])
    }
    
    var hole: Hole? {
        let adjustedHoleNumber = roundViewModel.roundType == .back9 ? currentHole : (currentHoleIndex % 18) + 1
        return singleRoundViewModel.holes.first(where: { $0.holeNumber == adjustedHoleNumber })
    }
    
    
    // Add this computed property to check if any games are selected
    private var hasGames: Bool {
        return roundViewModel.isMatchPlay || roundViewModel.isBetterBall ||
        roundViewModel.isNinePoint || roundViewModel.isStablefordGross ||
        roundViewModel.isStablefordNet
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
                                    .frame(width: viewWidth, height: viewHeight)
                            } else {
                                ProgressView("Loading hole data...")
                            }
                        }
                        .navigationBarBackButtonHidden(true)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Button(action: {
                                    moveToPreviousField()
                                }) {
                                    Image(systemName: "chevron.up")
                                }
                                
                                Button(action: {
                                    moveToNextField()
                                }) {
                                    Image(systemName: "chevron.down")
                                }
                                
                                Spacer()
                                
                                Button("Done") {
                                    focusedField = nil
                                }
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
                updateViewSize(newSize)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadHoleData()
            initializeScores()
            loadScores()
            selectedScorecardType = roundViewModel.selectedScorecardType
            unlockOrientation()
            updateViewSize(UIScreen.main.bounds.size)
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
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                updateViewSize(UIScreen.main.bounds.size)
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
                    }
                    if roundViewModel.isBetterBall {
                        if let losingTeam = BetterBallPressModel.getLosingTeam(roundViewModel: roundViewModel) {
                            BetterBallPressModel.initiateBetterBallPress(roundViewModel: roundViewModel, atHole: currentHoleIndex + 1)
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: focusedField) { newValue in
            print("Debug: HoleView focusedField changed to \(String(describing: newValue))")
        }
        .onAppear {
            print("Debug: HoleView appeared")
        }
    }
    
    private func updateViewSize(_ size: CGSize) {
        viewWidth = size.width
        viewHeight = size.height
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
    
    private func calculateHoleIndex(for holeNumber: Int) -> Int {
        let startingHole = roundViewModel.getStartingHoleNumber()
        let totalHoles = roundViewModel.roundType == .full18 ? 18 : 9
        let adjustedHoleNumber = roundViewModel.roundType == .back9 ? (holeNumber - 10 + 9) % 9 : (holeNumber - 1)
        return (adjustedHoleNumber + totalHoles) % totalHoles
    }
    
    private func nextHole(_ current: Int) -> Int {
        let startingHole = roundViewModel.getStartingHoleNumber()
        let totalHoles = roundViewModel.roundType == .full18 ? 18 : 9
        
        switch roundViewModel.roundType {
        case .full18:
            return current % 18 + 1
        case .front9:
            let next = (current % 9) + 1
            return next > 9 ? 1 : next
        case .back9:
            let next = (current - 9) % 9 + 10
            return next > 18 ? 10 : next
        }
    }
    
    private func previousHole(_ current: Int) -> Int {
        let startingHole = roundViewModel.getStartingHoleNumber()
        let totalHoles = roundViewModel.roundType == .full18 ? 18 : 9
        
        switch roundViewModel.roundType {
        case .full18:
            return (current - 2 + 18) % 18 + 1
        case .front9:
            let prev = (current - 2 + 9) % 9 + 1
            return prev < 1 ? 9 : prev
        case .back9:
            let prev = (current - 11 + 9) % 9 + 10
            return prev < 10 ? 18 : prev
        }
    }
    
    private var holeNavigation: some View {
        let startingHole = roundViewModel.getStartingHoleNumber()
        
        return HStack {
            if currentHole != startingHole {
                Button(action: {
                    currentHole = previousHole(currentHole)
                    currentHoleIndex = calculateHoleIndex(for: currentHole)
                    updateScoresForCurrentHole()
                    updateStatsForCurrentHole()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Hole \(previousHole(currentHole))")
                    }
                    .fontWeight(.bold)
                }
                .padding()
            }
            
            Spacer()
            
            if !isLastHoleOfRound(currentHole) {
                Button(action: {
                    if roundViewModel.isMatchPlay {
                        MatchPlayModel.recalculateTallies(roundViewModel: roundViewModel, upToHole: currentHole)
                        MatchPlayModel.updateMatchStatus(roundViewModel: roundViewModel, for: currentHole)
                        
                        // Explicitly update all presses
                        for pressIndex in roundViewModel.presses.indices {
                            if currentHole >= roundViewModel.presses[pressIndex].startHole {
                                MatchPlayPressModel.updatePressMatchStatus(roundViewModel: roundViewModel, pressIndex: pressIndex, for: currentHole)
                            }
                        }
                    }
                    
                    if roundViewModel.isBetterBall {
                        BetterBallModel.recalculateBetterBallTallies(roundViewModel: roundViewModel, upToHole: currentHole)
                        BetterBallModel.updateBetterBallMatchStatus(roundViewModel: roundViewModel, for: currentHole)
                        
                        // Explicitly update all Better Ball presses
                        for pressIndex in roundViewModel.betterBallPresses.indices {
                            if currentHole >= roundViewModel.betterBallPresses[pressIndex].startHole {
                                BetterBallPressModel.updateBetterBallPressMatchStatus(roundViewModel: roundViewModel, pressIndex: pressIndex, for: currentHole)
                            }
                        }
                    }
                    
                    if roundViewModel.isNinePoint {
                        NinePointModel.recalculateNinePointScores(roundViewModel: roundViewModel, upToHole: currentHole)
                    }
                    
                    if roundViewModel.isStablefordGross {
                        roundViewModel.recalculateStablefordGrossScores(upToHole: currentHole)
                    }
                    
                    if roundViewModel.isStablefordNet {
                        roundViewModel.recalculateStablefordNetScores(upToHole: currentHole)
                    }
                    
                    currentHole = nextHole(currentHole)
                    currentHoleIndex = calculateHoleIndex(for: currentHole)
                    updateScoresForCurrentHole()
                    updateStatsForCurrentHole()
                }) {
                    HStack {
                        Text("Hole \(nextHole(currentHole))")
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
                .frame(width: min(viewWidth - 32, 350))
                .padding(.bottom)
            ScrollView {
                VStack {
                    golferScoresView
                    gameStatusCarousel
                        .padding(.top)
                    checkScoresButton
                    reviewRoundButton
                }
            }
        }
        .gesture(holeNavigationGesture)
    }
    
    private var gameStatusCarousel: some View {
        let pages = carouselPages
        
        return Group {
            if !pages.isEmpty {
                GeometryReader { geometry in
                    VStack {
                        gameHeaderView
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
                        
                        let maxHeight = getMaxPageHeight()
                        
                        TabView(selection: $currentCarouselPage) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                pages[index]
                                    .tag(index)
                                    .frame(height: maxHeight)
                                    .border(Color.green, width: 2)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: min(maxHeight, geometry.size.height))
                        .border(Color.red, width: 2)
                    }
                    .frame(height: geometry.size.height)
                    .border(Color.blue, width: 2)
                }
                .frame(height: getMaxPageHeight() + 50) // Add extra height for safety
            }
        }
    }
    
    private func getPageHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat
        let pressStatusHeight: CGFloat
        let pressButtonHeight: CGFloat = canInitiatePress() ? 60 : 0
        
        switch index {
        case 0 where roundViewModel.isMatchPlay:
            baseHeight = 100
            pressStatusHeight = CGFloat(roundViewModel.pressStatuses.count * 20)
        case 0 where roundViewModel.isBetterBall:
            baseHeight = 120
            pressStatusHeight = CGFloat(roundViewModel.betterBallPressStatuses.count * 20)
        case 0 where roundViewModel.isNinePoint:
            baseHeight = 30 + CGFloat(roundViewModel.golfers.count * 25)
            pressStatusHeight = 0
        case 0 where roundViewModel.isStablefordGross:
            baseHeight = 80 + CGFloat(roundViewModel.golfers.count * 25)
            pressStatusHeight = 0
        case 0 where roundViewModel.isStablefordNet:
            baseHeight = 80 + CGFloat(roundViewModel.golfers.count * 25)
            pressStatusHeight = 0
        default:
            baseHeight = 0
            pressStatusHeight = 0
        }
        
        let totalHeight = baseHeight + pressStatusHeight + pressButtonHeight + 32 // Add extra padding
        print("Debug: getPageHeight for index \(index): baseHeight: \(baseHeight), pressStatusHeight: \(pressStatusHeight), pressButtonHeight: \(pressButtonHeight), totalHeight: \(totalHeight)")
        return totalHeight
    }
    
    private func getMaxPageHeight() -> CGFloat {
        let heights = (0..<carouselPages.count).map { getPageHeight(for: $0) }
        let maxHeight = heights.max() ?? 0
        print("Debug: getMaxPageHeight: \(maxHeight)")
        return maxHeight
    }
    
    private var carouselPages: [AnyView] {
        var pages: [AnyView] = []
        
        if roundViewModel.isMatchPlay {
            pages.append(AnyView(matchStatusView))
        }
        
        if roundViewModel.isBetterBall {
            pages.append(AnyView(BetterBallTeamsView(showingPressConfirmation: $showingPressConfirmation, currentHoleIndex: currentHoleIndex, scoresChecked: scoresChecked)))
        }
        
        if roundViewModel.isNinePoint {
            pages.append(AnyView(NinePointScoresView(showWinner: $showNinePointWinner)))
        }
        
        if roundViewModel.isStablefordGross {
            pages.append(AnyView(StablefordGrossScoresView(showWinner: $showStablefordGrossWinner)))
        }
        
        if roundViewModel.isStablefordNet {
            pages.append(AnyView(StablefordNetScoresView(showWinner: $showStablefordNetWinner)))
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
                
                if let (leadingPlayer, trailingPlayer, score) = MatchPlayPressModel.getCurrentPressStatus(roundViewModel: roundViewModel) {
                    if score != 0 && roundViewModel.currentPressStartHole == nil &&
                        (roundViewModel.matchWinner == nil || !roundViewModel.presses.isEmpty) &&
                        !scoresChecked && currentHoleIndex < 17 {
                        Button(action: {
                            showingPressConfirmation = true
                        }) {
                            VStack {
                                Text("\(trailingPlayer?.firstName ?? "")")
                                Text("Press?")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: 150)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        .padding(8)
    }
    
    private struct BetterBallTeamsView: View {
        @EnvironmentObject var roundViewModel: RoundViewModel
        @Binding var showingPressConfirmation: Bool
        let currentHoleIndex: Int
        let scoresChecked: Bool
        
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
            .padding(8)
            .onChange(of: roundViewModel.betterBallPressStatuses) { _ in
                DispatchQueue.main.async {
                    // Force layout update
                    withAnimation {
                        roundViewModel.objectWillChange.send()
                    }
                }
            }
        }
        
        private var betterBallStatusSection: some View {
            VStack(alignment: .center, spacing: 2) {
                Text(roundViewModel.betterBallMatchStatus ?? "Better Ball Status Not Available")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                
                if !roundViewModel.betterBallPressStatuses.isEmpty {
                    Text("Presses:")
                        .font(.subheadline)
                        .padding(.top, 2)
                    
                    ForEach(roundViewModel.betterBallPressStatuses, id: \.self) { pressStatus in
                        Text(pressStatus)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                betterBallPressButton
            }
        }
        
        private var betterBallPressButton: some View {
            Group {
                if let (leadingTeam, trailingTeam, score) = BetterBallPressModel.getCurrentBetterBallPressStatus(roundViewModel: roundViewModel) {
                    if score != 0 && trailingTeam != nil &&
                        (roundViewModel.betterBallMatchWinner == nil || !roundViewModel.betterBallPresses.isEmpty) &&
                        !scoresChecked && currentHoleIndex < 17 {
                        Button(action: {
                            showingPressConfirmation = true
                        }) {
                            VStack {
                                Text("\(trailingTeam ?? "")")
                                Text("Press?")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: 150)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.top, 8)
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
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Nine Point Scores")
                        .font(.headline)
                        .padding(.bottom, 2)
                        .frame(maxWidth: .infinity, alignment: .center)
                
                    let sortedGolfers = roundViewModel.golfers.sorted {
                        (roundViewModel.ninePointTotalScores[$0.id] ?? 0) > (roundViewModel.ninePointTotalScores[$1.id] ?? 0)
                    }
                    
                    ForEach(sortedGolfers, id: \.id) { golfer in
                        HStack(spacing: 10) {
                            if showWinner && golfer == sortedGolfers.first {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text(golfer.formattedName(golfers: roundViewModel.golfers))
                                .fontWeight(.semibold)
                            Text("\(roundViewModel.ninePointTotalScores[golfer.id] ?? 0) points")
                                .frame(width: 70, alignment: .leading)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
                .fixedSize(horizontal: true, vertical: false)
                .shadow(radius: 10)
                .padding(8)
            }
        }
    }
    
    private struct StablefordGrossScoresView: View {
        @EnvironmentObject var roundViewModel: RoundViewModel
        @Binding var showWinner: Bool
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                Text("Stableford Gross Scores")
                    .font(.headline)
                    .padding(.bottom, 2)
                
                let sortedGolfers = roundViewModel.golfers.sorted {
                    let overQuota1 = (roundViewModel.stablefordGrossTotalScores[$0.id] ?? 0) - (roundViewModel.stablefordGrossQuotas[$0.id] ?? 0)
                    let overQuota2 = (roundViewModel.stablefordGrossTotalScores[$1.id] ?? 0) - (roundViewModel.stablefordGrossQuotas[$1.id] ?? 0)
                    return overQuota1 > overQuota2
                }
                
                ForEach(sortedGolfers, id: \.id) { golfer in
                    HStack (spacing: 10){
                        if showWinner && golfer == sortedGolfers.first {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        }
                        Text(golfer.formattedName(golfers: roundViewModel.golfers))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        let totalScore = roundViewModel.stablefordGrossTotalScores[golfer.id] ?? 0
                        let quota = roundViewModel.stablefordGrossQuotas[golfer.id] ?? 0
                        let overQuota = totalScore - quota
                        Text("\(totalScore) pts (\(formatOverQuota(overQuota)))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        
        private func formatOverQuota(_ points: Int) -> String {
            if points > 0 {
                return "+\(points)"
            } else if points < 0 {
                return "\(points)"
            } else {
                return "E"
            }
        }
    }
    
    private struct StablefordNetScoresView: View {
        @EnvironmentObject var roundViewModel: RoundViewModel
        @Binding var showWinner: Bool
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                Text("Stableford Net Scores")
                    .font(.headline)
                    .padding(.bottom, 2)
                
                let sortedGolfers = roundViewModel.golfers.sorted {
                    let overQuota1 = (roundViewModel.stablefordNetTotalScores[$0.id] ?? 0) - (roundViewModel.stablefordNetQuotas[$0.id] ?? 0)
                    let overQuota2 = (roundViewModel.stablefordNetTotalScores[$1.id] ?? 0) - (roundViewModel.stablefordNetQuotas[$1.id] ?? 0)
                    return overQuota1 > overQuota2
                }
                
                ForEach(sortedGolfers, id: \.id) { golfer in
                    HStack(spacing: 10) {
                        HStack(spacing: 4) {
                            if showWinner && golfer == sortedGolfers.first {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text(golfer.formattedName(golfers: roundViewModel.golfers))
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        
                        let totalScore = roundViewModel.stablefordNetTotalScores[golfer.id] ?? 0
                        let quota = roundViewModel.stablefordNetQuotas[golfer.id] ?? 0
                        let overQuota = totalScore - quota
                        Text("\(totalScore) pts (\(formatOverQuota(overQuota)))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        
        private func formatOverQuota(_ points: Int) -> String {
            if points > 0 {
                return "+\(points)"
            } else if points < 0 {
                return "\(points)"
            } else {
                return "E"
            }
        }
    }
    
    private var gameHeaderView: some View {
        HStack(spacing: 0) {
            Text("Game Scores")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal)
        .fontWeight(.bold)
        .foregroundColor(Color.primary)
        .background(Color.secondary)
    }
    
    private var golferScoresView: some View {
        ForEach(roundViewModel.golfers, id: \.id) { golfer in
            HStack(spacing: 0) {
                HStack {
                    Text(golfer.formattedName(golfers: roundViewModel.golfers))
                    if roundViewModel.selectedScorecardType == .strokePlay {
                        Text("(\(StrokePlayModel.formatScoreToPar(currentScoreToPar[golfer.id] ?? 0)))")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: 10)
                
                ScoreInputView(
                    scoreInputs: $scoreInputs,
                    focusedField: $focusedField,
                    golfer: golfer,
                    strokeHoleInfo: strokeHoleInfo(for: golfer.id),
                    updateScore: updateScore
                )
                .frame(width: 60)
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
        VStack {
            if isLastHoleOfRound(currentHole) {
                if roundViewModel.allScoresEntered(for: currentHole) {
                    Button(action: {
                        checkScores()
                        scoresChecked = true
                    }) {
                        Text("Check For Missing Scores")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    
                }
            }
        }
    }
    
    private var reviewRoundButton: some View {
        Group {
            if scoresChecked && missingScores.isEmpty {
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
    
    private func canInitiatePress() -> Bool {
        if roundViewModel.isMatchPlay {
            return MatchPlayPressModel.getLosingPlayer(roundViewModel: roundViewModel) != nil &&
            (roundViewModel.matchWinner == nil || !roundViewModel.presses.isEmpty) &&
            !scoresChecked && currentHoleIndex < 17
        } else if roundViewModel.isBetterBall {
            return BetterBallPressModel.getLosingTeam(roundViewModel: roundViewModel) != nil &&
            (roundViewModel.betterBallMatchWinner == nil || !roundViewModel.betterBallPresses.isEmpty) &&
            !scoresChecked && currentHoleIndex < 17
        }
        return false
    }
    
    private func betterBallPressButton(for golfer: Golfer) -> some View {
        Group {
            if let (leadingTeam, trailingTeam, score) = BetterBallPressModel.getCurrentBetterBallPressStatus(roundViewModel: roundViewModel) {
                if score != 0 && trailingTeam != nil &&
                    (roundViewModel.betterBallMatchWinner == nil || !roundViewModel.betterBallPresses.isEmpty) &&
                    !scoresChecked && currentHoleIndex < 17 {
                    Button(action: {
                        showingPressConfirmation = true
                    }) {
                        VStack {
                            Text("\(trailingTeam ?? "")")
                            Text("Press?")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: 150)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
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
                let startingHole = roundViewModel.getStartingHoleNumber()
                
                if gesture.translation.width > threshold && currentHole != startingHole {
                    currentHole = previousHole(currentHole)
                    currentHoleIndex = calculateHoleIndex(for: currentHole)
                    updateScoresForCurrentHole()
                    updateStatsForCurrentHole()
                } else if gesture.translation.width < -threshold && !roundViewModel.isLastHole(currentHole) {
                    updateStatsForCurrentHole() // Update stats for the current hole before moving
                    
                    if roundViewModel.isMatchPlay {
                        MatchPlayModel.recalculateTallies(roundViewModel: roundViewModel, upToHole: currentHole)
                        MatchPlayModel.updateMatchStatus(roundViewModel: roundViewModel, for: currentHole)
                    }
                    if roundViewModel.isBetterBall {
                        BetterBallModel.recalculateBetterBallTallies(roundViewModel: roundViewModel, upToHole: currentHole)
                        BetterBallModel.updateBetterBallMatchStatus(roundViewModel: roundViewModel, for: currentHole)
                    }
                    
                    if roundViewModel.isNinePoint {
                        NinePointModel.recalculateNinePointScores(roundViewModel: roundViewModel, upToHole: currentHole)
                    }
                    
                    if roundViewModel.isStablefordGross {
                        roundViewModel.recalculateStablefordGrossScores(upToHole: currentHole)
                    }
                    
                    if roundViewModel.isStablefordNet {
                        roundViewModel.recalculateStablefordNetScores(upToHole: currentHole)
                    }
                    
                    currentHole = nextHole(currentHole)
                    currentHoleIndex = calculateHoleIndex(for: currentHole)
                    updateScoresForCurrentHole()
                    
                    // Debug: Print cumulative stats after navigating
                    printCumulativeStats()
                }
            }
    }
    
    private func printCumulativeStats() {
        print("Debug: Cumulative stats after navigating to hole \(currentHole):")
        for golfer in roundViewModel.golfers {
            let eaglesless = roundViewModel.eagleOrBetterCount[golfer.id] ?? 0
            let birdies = roundViewModel.birdieCount[golfer.id] ?? 0
            let pars = roundViewModel.parCount[golfer.id] ?? 0
            let bogeys = roundViewModel.bogeyCount[golfer.id] ?? 0
            let doublePlus = roundViewModel.doubleBogeyPlusCount[golfer.id] ?? 0
            
            print("\(golfer.firstName): Eagles or Less: \(eaglesless), Birdies: \(birdies), Pars: \(pars), Bogeys: \(bogeys), Double+: \(doublePlus)")
        }
    }
    
    private func updateStatsForCurrentHole() {
        let currentHoleNumber = currentHole
        guard let hole = singleRoundViewModel.holes.first(where: { $0.holeNumber == currentHoleNumber }) else {
            print("Debug: Hole not found for hole number \(currentHoleNumber)")
            return
        }
        
        let par = hole.par
        
        for golfer in roundViewModel.golfers {
            if let score = roundViewModel.grossScores[currentHoleNumber]?[golfer.id] {
                roundViewModel.updateStats(for: golfer.id, score: score, par: par)
                print("Debug: Updating stats for \(golfer.firstName) - Hole: \(currentHoleNumber), Score: \(score), Par: \(par)")
            } else {
                print("Debug: Score not found for \(golfer.firstName) on hole \(currentHoleNumber)")
            }
        }
        
        // Debug: Print current stats after updating
        printCumulativeStats()
    }
    
    private func moveToNextField() {
        print("Debug: moveToNextField called")
        guard let currentIndex = roundViewModel.golfers.firstIndex(where: { $0.id == focusedField }) else { return }
        let nextIndex = (currentIndex + 1) % roundViewModel.golfers.count
        focusedField = roundViewModel.golfers[nextIndex].id
    }
    
    private func moveToPreviousField() {
        print("Debug: moveToPreviousField called")
        guard let currentIndex = roundViewModel.golfers.firstIndex(where: { $0.id == focusedField }) else { return }
        let previousIndex = (currentIndex - 1 + roundViewModel.golfers.count) % roundViewModel.golfers.count
        focusedField = roundViewModel.golfers[previousIndex].id
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
        let adjustedHoleNumber = currentHole
        print("Debug: updateScoresForCurrentHole called for hole \(adjustedHoleNumber)")
        
        scoreInputs = roundViewModel.grossScores[adjustedHoleNumber]?.mapValues { String($0) } ?? [:]
        
        for golfer in roundViewModel.golfers {
            if scoreInputs[golfer.id] == nil {
                scoreInputs[golfer.id] = ""
            }
            // Update the cumulative score to par
            currentScoreToPar[golfer.id] = StrokePlayModel.calculateCumulativeScoreToPar(
                roundViewModel: roundViewModel,
                singleRoundViewModel: singleRoundViewModel,
                golferId: golfer.id,
                upToHole: adjustedHoleNumber
            )
            print("Debug: Updated score to par for \(golfer.firstName): \(currentScoreToPar[golfer.id] ?? 0)")
        }
        
        // Force view update to refresh the score to par display
        roundViewModel.objectWillChange.send()
    }
    
    private func updateScore(for golferId: String, score: String) {
        let adjustedHoleNumber = currentHole
        if let scoreInt = Int(score) {
            // Always update gross scores
            roundViewModel.grossScores[adjustedHoleNumber, default: [:]][golferId] = scoreInt
            
            // Always update stroke play scores
            StrokePlayModel.updateStrokePlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: adjustedHoleNumber, scoreInt: scoreInt)
            
            // Update game-specific scores
            if roundViewModel.isMatchPlay {
                MatchPlayModel.updateMatchPlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: adjustedHoleNumber, scoreInt: scoreInt)
            }
            
            if roundViewModel.isBetterBall {
                BetterBallModel.updateBetterBallScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: adjustedHoleNumber, scoreInt: scoreInt)
            }

        } else {
            // Reset scores if the input is invalid
            roundViewModel.grossScores[adjustedHoleNumber, default: [:]][golferId] = nil
            roundViewModel.netStrokePlayScores[adjustedHoleNumber, default: [:]][golferId] = nil
            
            if roundViewModel.isMatchPlay {
                MatchPlayModel.resetMatchPlayScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: adjustedHoleNumber)
            }
            
            if roundViewModel.isBetterBall {
                BetterBallModel.resetBetterBallScore(roundViewModel: roundViewModel, golferId: golferId, currentHoleNumber: adjustedHoleNumber)
            }
            
            if roundViewModel.isNinePoint {
                NinePointModel.resetNinePointScore(roundViewModel: roundViewModel, holeNumber: adjustedHoleNumber)
            }
            
            if roundViewModel.isStablefordGross {
                roundViewModel.resetStablefordGrossScore(for: adjustedHoleNumber)
            }
            
            if roundViewModel.isStablefordNet {
                roundViewModel.resetStablefordNetScore(for: adjustedHoleNumber)
            }
        }
        
        // Update tallies if all scores are entered
        if roundViewModel.allScoresEntered(for: adjustedHoleNumber) {
            if roundViewModel.isMatchPlay {
                MatchPlayModel.updateMatchPlayTallies(roundViewModel: roundViewModel, currentHoleNumber: adjustedHoleNumber)
            }
            
            if roundViewModel.isBetterBall {
                BetterBallModel.updateBetterBallTallies(roundViewModel: roundViewModel, for: adjustedHoleNumber)
            }
            
            // Force view update
            roundViewModel.forceUIUpdate()
        }
    }
    
    private func isLastHoleOfRound(_ holeNumber: Int) -> Bool {
        let startingHole = roundViewModel.getStartingHoleNumber()
        let totalHoles = roundViewModel.roundType == .full18 ? 18 : 9
        
        switch roundViewModel.roundType {
        case .full18:
            return (holeNumber - startingHole + 18) % 18 == 17
        case .front9:
            return (holeNumber - startingHole + 9) % 9 == 8
        case .back9:
            return (holeNumber - startingHole + 9) % 9 == 8
        }
    }
    
    private func checkScores() {
        showMissingScores = true
        scoresChecked = true
        missingScores = [:]
        
        let (startHole, endHole) = getHoleRange()
        let totalHoles = roundViewModel.roundType == .full18 ? 18 : 9
        
        for golfer in roundViewModel.golfers {
            var missingHoles: [Int] = []
            for offset in 0..<totalHoles {
                let holeNumber: Int
                switch roundViewModel.roundType {
                case .full18:
                    holeNumber = (startHole + offset - 1) % 18 + 1
                case .front9:
                    holeNumber = ((startHole + offset - 1) % 9) + 1
                case .back9:
                    holeNumber = ((startHole + offset - 10) % 9) + 10
                }
                if roundViewModel.grossScores[holeNumber]?[golfer.id] == nil {
                    missingHoles.append(holeNumber)
                }
            }
            if !missingHoles.isEmpty {
                missingScores[golfer.id] = missingHoles
            }
        }
        
        if missingScores.isEmpty {
            updateFinalScoresAndStats(endHole: endHole)
        }
        
        // Force view update
        roundViewModel.forceUIUpdate()
        
        // Print final cumulative stats
        printCumulativeStats()
    }
    
    private func getHoleRange() -> (Int, Int) {
        let startingHole = roundViewModel.getStartingHoleNumber()
        switch roundViewModel.roundType {
        case .full18:
            return (1, 18)
        case .front9:
            return (1, 9)
        case .back9:
            return (10, 18)
        }
    }
    
    private func updateFinalScoresAndStats(endHole: Int) {
        // Reset all stats before recalculating
        resetAllStats()
        
        let (startHole, _) = getHoleRange()
        let totalHoles = roundViewModel.roundType == .full18 ? 18 : 9
        
        // Update stats for all holes
        for offset in 0..<totalHoles {
            let holeNumber: Int
            switch roundViewModel.roundType {
            case .full18:
                holeNumber = (startHole + offset - 1) % 18 + 1
            case .front9:
                holeNumber = ((startHole + offset - 1) % 9) + 1
            case .back9:
                holeNumber = ((startHole + offset - 10) % 9) + 10
            }
            updateStatsForHole(holeNumber: holeNumber)
        }
        
        // Update score to par for all golfers
        for golfer in roundViewModel.golfers {
            currentScoreToPar[golfer.id] = StrokePlayModel.calculateCumulativeScoreToPar(
                roundViewModel: roundViewModel,
                singleRoundViewModel: singleRoundViewModel,
                golferId: golfer.id,
                upToHole: endHole
            )
        }
        
        // Update game-specific final statuses
        updateFinalGameStatuses(lastHole: endHole)
    }
    
    private func resetAllStats() {
        for golfer in roundViewModel.golfers {
            roundViewModel.eagleOrBetterCount[golfer.id] = 0
            roundViewModel.birdieCount[golfer.id] = 0
            roundViewModel.parCount[golfer.id] = 0
            roundViewModel.bogeyCount[golfer.id] = 0
            roundViewModel.doubleBogeyPlusCount[golfer.id] = 0
        }
    }
    
    private func updateStatsForHole(holeNumber: Int) {
        guard let hole = singleRoundViewModel.holes.first(where: { $0.holeNumber == holeNumber }) else {
            print("Debug: Hole not found for hole number \(holeNumber)")
            return
        }
        
        let par = hole.par
        
        for golfer in roundViewModel.golfers {
            if let score = roundViewModel.grossScores[holeNumber]?[golfer.id] {
                roundViewModel.updateStats(for: golfer.id, score: score, par: par)
                print("Debug: Updating stats for \(golfer.firstName) - Hole: \(holeNumber), Score: \(score), Par: \(par)")
            } else {
                print("Debug: Score not found for \(golfer.firstName) on hole \(holeNumber)")
            }
        }
    }
    
    private func updateFinalGameStatuses(lastHole: Int) {
        if roundViewModel.isMatchPlay {
            MatchPlayModel.updateFinalMatchStatus(roundViewModel: roundViewModel)
        } else if roundViewModel.isBetterBall {
            BetterBallModel.updateFinalBetterBallMatchStatus(roundViewModel: roundViewModel)
        } else if roundViewModel.isNinePoint {
            // Update Nine Point scoring for the last hole
            NinePointModel.updateNinePointScore(roundViewModel: roundViewModel, holeNumber: lastHole)
            // Display final results
            _ = NinePointModel.displayFinalResults(roundViewModel: roundViewModel)
            // Set showNinePointWinner to true
            showNinePointWinner = true
        }
        
        if roundViewModel.isStablefordGross {
            // Update Stableford Gross scoring for the last hole
            StablefordGrossModel.updateStablefordGrossScore(roundViewModel: roundViewModel, holeNumber: lastHole)
            // Recalculate all scores to ensure consistency
            StablefordGrossModel.recalculateStablefordGrossScores(roundViewModel: roundViewModel, upToHole: lastHole)
            // Display final results
            _ = StablefordGrossModel.displayFinalResults(roundViewModel: roundViewModel)
            // Set showStablefordGrossWinner to true
            showStablefordGrossWinner = true
        }
        
        if roundViewModel.isStablefordNet {
            // Update Stableford Net scoring for the last hole
            StablefordNetModel.updateStablefordNetScore(roundViewModel: roundViewModel, holeNumber: lastHole)
            // Recalculate all scores to ensure consistency
            StablefordNetModel.recalculateStablefordNetScores(roundViewModel: roundViewModel, upToHole: lastHole)
            // Display final results
            _ = StablefordNetModel.displayFinalResults(roundViewModel: roundViewModel)
            // Set showStablefordNetWinner to true
            showStablefordNetWinner = true
        }
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
        let currentHoleNumber = currentHole
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Hole \(hole?.holeNumber ?? 0)")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemTeal).opacity(0.3))
            HStack {
                Text("\(hole?.yardage ?? 0) Yards")
                    .font(.subheadline)
                Spacer()
                Text("Par \(hole?.par ?? 0)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .offset(x: -9)
                Spacer()
                Text("HCP \(hole?.handicap ?? 0)")
                    .font(.subheadline)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: 1)
        )
    }
}

private struct ScoreInputView: View {
    @Binding var scoreInputs: [String: String]
    @FocusState.Binding var focusedField: Golfer.ID?
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
                print("Debug: Score input changed for golfer \(golfer.id), new value: \(newValue)")
            }
        ))
        .keyboardType(.numberPad)
        .focused($focusedField, equals: golfer.id)
        .onChange(of: focusedField) { newValue in
            print("Debug: Focus changed in ScoreInputView for golfer \(golfer.id), focused: \(newValue == golfer.id)")
        }
        .frame(width: 50, height: 50)
        .background(colorScheme == .dark ? Color.white : Color.gray.opacity(0.2))
        .foregroundColor(colorScheme == .dark ? .black : .primary)
        .cornerRadius(5)
        .multilineTextAlignment(.center)
        .overlay(strokeHoleOverlay)
        .onTapGesture {
            print("Debug: ScoreInputView tapped for golfer \(golfer.id)")
            focusedField = golfer.id
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private var strokeHoleOverlay: some View {
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
    }
}

