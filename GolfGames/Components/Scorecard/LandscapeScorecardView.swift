//
//  LandscapeScorecardView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/31/24.
//

import SwiftUI
import Firebase

struct LandscapeScorecardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedGolferId: String?
    @Binding var navigateToInitialView: Bool
    @Binding var selectedScorecardType: ScorecardType
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var currentPage = 0
    
    private var isLandscape: Bool {
        return UIDevice.current.orientation.isLandscape
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack {
                    if hasGamesSelected {
                    scorecardTypePicker
                    }
                    if selectedScorecardType == .strokePlay && roundViewModel.golfers.count > 1 {
                        golferPicker
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Move page indicators here
                if selectedScorecardType == .games {
                    pageIndicators
                        .padding(.vertical, 8)
                }

                if selectedScorecardType == .games {
                    gamesTabView(geometry: geometry)
                } else {
                    strokePlayScorecard
                        .frame(width: geometry.size.width * 0.95, height: geometry.size.height * 0.85)
                        .scaleEffect(0.9) // Slightly reduce the scale to fit better
                }
            }
        }
        .navigationBarItems(trailing: finishButton)
        .onAppear {
            selectedGolferId = authViewModel.currentUser?.id
        }
    }
    
    private var hasGamesSelected: Bool {
        roundViewModel.isMatchPlay ||
        roundViewModel.isBetterBall ||
        roundViewModel.isNinePoint ||
        roundViewModel.isStablefordGross ||
        roundViewModel.isStablefordNet
    }
    
    private var scorecardTypePicker: some View {
        Picker("Scorecard Type", selection: $selectedScorecardType) {
            Text("Stroke Play").tag(ScorecardType.strokePlay)
            Text("Games").tag(ScorecardType.games)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    private func gamesTabView(geometry: GeometryProxy) -> some View {
        TabView(selection: $currentPage) {
            ForEach(0..<gamePages.count, id: \.self) { index in
                ScrollView {
                    VStack(alignment: .center, spacing: 0) {
                        Text(gamePages[index].title)
                            .font(.headline)
                            .padding(.top, 16)
                        
                        gamePages[index].view
                            .frame(width: geometry.size.width * 0.95)
                            .scaleEffect(scaleForGame(gamePages[index].title))
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: geometry.size.height * 0.85)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < 0 {
                        // Swipe left
                        withAnimation {
                            currentPage = min(currentPage + 1, gamePages.count - 1)
                        }
                    } else if value.translation.width > 0 {
                        // Swipe right
                        withAnimation {
                            currentPage = max(currentPage - 1, 0)
                        }
                    }
                }
        )
    }
    
    private func scaleForGame(_ gameTitle: String) -> CGFloat {
        switch gameTitle {
        case "Nine Point":
            return 0.85
        case "Stableford (Gross)":
            return 0.85
        case "Stableford (Net)":
            return 0.85
        default:
            return 0.95
        }
    }
    
    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<gamePages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.blue : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var gamePages: [(title: String, view: AnyView)] {
        var pages: [(String, AnyView)] = []
        
        if roundViewModel.isMatchPlay {
            pages.append(("Match Play", AnyView(matchPlayScorecard)))
        }
        if roundViewModel.isBetterBall {
            pages.append(("Better Ball", AnyView(betterBallScorecard)))
        }
        if roundViewModel.isNinePoint {
            pages.append(("Nine Point", AnyView(ninePointScorecard.padding(.horizontal, 5))))
        }
        if roundViewModel.isStablefordGross {
            pages.append(("Stableford (Gross)", AnyView(stablefordGrossScorecard)))
        }
        if roundViewModel.isStablefordNet {
            pages.append(("Stableford (Net)", AnyView(stablefordNetScorecard)))
        }
        
        return pages
    }
    
    private var strokePlayScorecard: some View {
        Group {
            if let golfer = selectedGolfer {
                VStack(spacing: 0) { // Reduced spacing
                    Text("Stroke Play")
                    .font(.custom("AmericanTypewriter", size: 30))
                    .padding(.bottom, 30)
                    LandscapeStrokePlayScorecardView(golfer: golfer)
                    scoreLegend
                        .padding(.top, 10)
                }
            }
        }
    }
    
    private var matchPlayScorecard: some View {
        VStack(spacing: 0) { // Reduced spacing
        scoreLegend
        .padding(.bottom, 10)
            MatchPlaySCView()
        }
    }
    
    private var betterBallScorecard: some View {
        VStack(spacing: 0) { // Reduced spacing
        scoreLegend
        .padding(.bottom, 10)
            BetterBallSCView()
        }
    }
    
    private var ninePointScorecard: some View {
        VStack(spacing: 0) { // Reduced spacing
            NinePointSCView()
        }
    }
    
    private var stablefordGrossScorecard: some View {
        VStack(spacing: 0) { // Reduced spacing
            StablefordGrossSCView()
        }
    }
    
    private var stablefordNetScorecard: some View {
        VStack(spacing: 0) { // Reduced spacing
            StablefordNetSCView()
        }
    }
    
    private var golferPicker: some View {
        Picker("Select Golfer", selection: $selectedGolferId) {
            ForEach(roundViewModel.golfers) { golfer in
                Text("\(golfer.firstName) \(golfer.lastName)").tag(golfer.id as String?)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal)
    }
    
    private var allHolesHaveScores: Bool {
        guard let golfer = selectedGolfer else { return false }
        return (1...18).allSatisfy { hole in
            roundViewModel.grossScores[hole]?[golfer.id] != nil
        }
    }
    
    private var finishButton: some View {
        Group {
            if allHolesHaveScores {
                Button("Finish") {
                    finalizeRound()
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func finalizeRound() {
        guard let user = authViewModel.currentUser,
              let course = roundViewModel.selectedCourse,
              let tee = roundViewModel.selectedTee else { return }
        
        let db = Firestore.firestore()
        let roundRef = db.collection("users").document(user.id).collection("rounds").document(roundViewModel.roundId ?? "")
        
        let roundResultID = roundRef.collection("results").document().documentID
        
        var roundData: [String: Any] = [
            "date": Timestamp(date: Date()),
            "courseId": course.id,
            "courseName": course.name,
            "tees": tee.tee_name,
            "courseRating": tee.course_rating,
            "slopeRating": tee.slope_rating,
            "roundResultID": roundResultID,
            "golfers": roundViewModel.golfers.map { golfer in
                [
                    "id": golfer.id,
                    "firstName": golfer.firstName,
                    "lastName": golfer.lastName,
                    "handicap": golfer.handicap,
                    "grossTotal": roundViewModel.grossScores.values.reduce(0) { $0 + ($1[golfer.id] ?? 0) },
                    "netTotal": roundViewModel.netStrokePlayScores.values.reduce(0) { $0 + ($1[golfer.id] ?? 0) }
                ]
            }
        ]
        
        for (hole, scores) in roundViewModel.grossScores {
            for (golferId, score) in scores {
                roundData["gross_hole_\(hole)_\(golferId)"] = score
            }
        }
        
        for (hole, scores) in roundViewModel.netStrokePlayScores {
            for (golferId, score) in scores {
                roundData["net_hole_\(hole)_\(golferId)"] = score
            }
        }
        
        roundRef.setData(roundData) { error in
            if let error = error {
                print("Error saving round: \(error.localizedDescription)")
            } else {
                print("Round successfully saved!")
                resetLocalData()
                navigateToInitialView = true
            }
        }
    }
    
    private func resetLocalData() {
        roundViewModel.grossScores = [:]
        roundViewModel.netStrokePlayScores = [:]
        roundViewModel.strokeHoles = [:]
        roundViewModel.selectedCourse = nil
        roundViewModel.selectedTee = nil
    }
    
    var selectedGolfer: Golfer? {
        if let id = selectedGolferId {
            return roundViewModel.golfers.first { $0.id == id }
        }
        return roundViewModel.golfers.first
    }
    
    func scoreCardView(for golfer: Golfer) -> some View {
        VStack(spacing: 0) {
            nineHoleView(for: golfer, holes: 1...9, title: "Out")
            nineHoleView(for: golfer, holes: 10...18, title: "In", showTotal: true)
        }
        .background(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    func nineHoleView(for golfer: Golfer, holes: ClosedRange<Int>, title: String, showTotal: Bool = false) -> some View {
        VStack(spacing: 0) {
            holeRow(title: "Hole", holes: holes, total: title, showTotal: showTotal, addBlankColumn: !showTotal)
            parRow(holes: holes, showTotal: showTotal, addBlankColumn: !showTotal)
            scoreRow(for: golfer, holes: holes, isGross: true, showTotal: showTotal, addBlankColumn: !showTotal)
            scoreRow(for: golfer, holes: holes, isGross: false, showTotal: showTotal, addBlankColumn: !showTotal)
        }
    }
    
    func holeRow(title: String, holes: ClosedRange<Int>, total: String, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .frame(width: 40, height: 27, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemTeal))
            ForEach(holes, id: \.self) { hole in
                Text("\(hole)")
                    .frame(width: 27, height: 27)
                    .background(Color(UIColor.systemTeal))
            }
            Text(total)
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemTeal))
            if showTotal {
                Text("Tot")
                    .frame(width: 32, height: 27)
                    .background(Color(UIColor.systemTeal))
            } else if addBlankColumn {
                Color(UIColor.systemTeal)
                    .frame(width: 32, height: 27)
            }
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    func parRow(holes: ClosedRange<Int>, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text("Par")
                .frame(width: 40, height: 27, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemTeal))
            ForEach(holes, id: \.self) { hole in
                if let holeData = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole }) {
                    Text("\(holeData.par)")
                        .frame(width: 27, height: 27)
                        .background(Color(UIColor.systemTeal))
                }
            }
            let totalPar = singleRoundViewModel.holes.filter { holes.contains($0.holeNumber) }.reduce(0) { $0 + $1.par }
            Text("\(totalPar)")
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemTeal))
            if showTotal {
                let grandTotalPar = singleRoundViewModel.holes.reduce(0) { $0 + $1.par }
                Text("\(grandTotalPar)")
                    .frame(width: 32, height: 27)
                    .background(Color(UIColor.systemTeal))
            } else if addBlankColumn {
                Color(UIColor.systemTeal)
                    .frame(width: 32, height: 27)
            }
        }
        .foregroundColor(colorScheme == .light ? Color.white : Color.primary)
        .font(.caption)
    }
    
    func scoreRow(for golfer: Golfer, holes: ClosedRange<Int>, isGross: Bool, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text(isGross ? "Gross" : "Net")
                .frame(width: 40, height: 27, alignment: .leading)
                .padding(.horizontal, 2)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            ForEach(holes, id: \.self) { hole in
                scoreCell(for: golfer, hole: hole, isGross: isGross)
                    .frame(width: 27, height: 27)
            }
            let totalScore = holes.reduce(0) { total, hole in
                total + (isGross ? roundViewModel.grossScores[hole]?[golfer.id] ?? 0 : roundViewModel.netStrokePlayScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(totalScore)")
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            if showTotal {
                let grandTotal = singleRoundViewModel.holes.reduce(0) { total, hole in
                    total + (isGross ? roundViewModel.grossScores[hole.holeNumber]?[golfer.id] ?? 0 : roundViewModel.netStrokePlayScores[hole.holeNumber]?[golfer.id] ?? 0)
                }
                Text("\(grandTotal)")
                    .frame(width: 32, height: 27)
                    .background(Color(UIColor.systemGray4))
                    .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                    .fontWeight(.bold)
            } else if addBlankColumn {
                Color(UIColor.systemGray4)
                    .frame(width: 32, height: 27)
            }
        }
        .font(.caption)
    }
    
    func scoreCell(for golfer: Golfer, hole: Int, isGross: Bool) -> some View {
        let par = singleRoundViewModel.holes.first(where: { $0.holeNumber == hole })?.par ?? 0
        let score = isGross ? roundViewModel.grossScores[hole]?[golfer.id] ?? 0 : roundViewModel.netStrokePlayScores[hole]?[golfer.id] ?? 0
        let isStrokeHole = roundViewModel.strokeHoles[golfer.id]?.contains(hole) ?? false
        
        return ZStack {
            scoreCellBackground(score: score, par: par)
            
            if score != 0 {
                Text("\(score)")
                    .foregroundColor(scoreCellTextColor(score: score, par: par))
                    .font(.subheadline)
            }
            
            if isGross && isStrokeHole {
                Circle()
                    .fill(strokeDotColor(score: score, par: par))
                    .frame(width: 6, height: 6)
                    .offset(x: 7, y: -7)
            }
        }
    }
    
    func strokeDotColor(score: Int, par: Int) -> Color {
        if score == par + 1 {
            return .white
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    func scoreCellBackground(score: Int, par: Int) -> some View {
        Group {
            if score == 0 {
                Color.clear
            } else if score <= par - 2 {
                Circle().fill(Color.yellow)
            } else if score == par - 1 {
                Circle().fill(Color.red)
            } else if score == par + 1 {
                Rectangle().fill(Color.black)
                    .if(colorScheme == .dark) { view in
                        view.overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                    }
            } else if score >= par + 2 {
                Rectangle().fill(Color.blue)
            } else {
                Color.clear
            }
        }
    }
    
    func scoreCellTextColor(score: Int, par: Int) -> Color {
        if score == 0 {
            return .clear
        } else if score <= par - 1 || score >= par + 1 {
            return .white
        } else {
            return colorScheme == .light ? .black : .white
        }
    }
    
    func dotColor(score: Int, par: Int) -> Color {
        if colorScheme == .light {
            return score == par ? .black : .white
        } else {
            return .white
        }
    }
    
    private var scoreLegend: some View {
        HStack(spacing: 10) {
            ForEach([
                (color: Color.yellow, shape: AnyShape(Circle()), text: "Eagle or better"),
                (color: Color.red, shape: AnyShape(Circle()), text: "Birdie"),
                (color: Color.black, shape: AnyShape(Rectangle()), text: "Bogey"),
                (color: Color.blue, shape: AnyShape(Rectangle()), text: "Double bogey +")
            ], id: \.text) { item in
                legendItem(color: item.color, shape: item.shape, text: item.text, addBorder: item.color == .black && colorScheme == .dark)
            }
        }
        .padding(.horizontal)
        .background(Color(UIColor.systemBackground).opacity(0.8))
        .font(.caption)
    }
    
    private func legendItem<S: Shape>(color: Color, shape: S, text: String, addBorder: Bool = false) -> some View {
        HStack(spacing: 4) {
            shape
                .fill(color)
                .frame(width: 12, height: 12)
                .if(addBorder) { view in
                    view.overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white, lineWidth: 1)
                    )
                }
            Text(text)
        }
    }
}
