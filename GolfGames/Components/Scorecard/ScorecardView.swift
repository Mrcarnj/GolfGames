import SwiftUI
import Firebase

struct ScorecardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedGolferId: String?
    @State private var navigateToInitialView = false
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var selectedScorecardType: ScorecardType = .strokePlay
    
    private var isLandscape: Bool {
        return orientation.isLandscape
    }
    
    var body: some View {
        Group {
            if isLandscape {
                LandscapeScorecardView(
                    navigateToInitialView: $navigateToInitialView,
                    selectedScorecardType: $selectedScorecardType
                )
            } else {
                portraitLayout
            }
        }
        .navigationTitle("Round Review")
        .navigationBarTitleDisplayMode(isLandscape ? .inline : .large)
        .navigationBarHidden(false)
        .onAppear {
            selectedGolferId = authViewModel.currentUser?.id
            orientation = UIDevice.current.orientation
        }
        .onRotate { newOrientation in
            orientation = newOrientation
        }
        .background(
            NavigationLink(destination: InititalView().environmentObject(authViewModel).environmentObject(roundViewModel), isActive: $navigateToInitialView) {
                EmptyView()
            }
        )
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 10) {
            if roundViewModel.isMatchPlay {
                scorecardTypePicker
            }
            
            if roundViewModel.golfers.count > 1 {
                golferPicker
            }
            
            if let golfer = selectedGolfer {
                Spacer()
                if selectedScorecardType == .strokePlay {
                    scoreCardView(for: golfer)
                } else {
                    MatchPlaySCView(selectedGolferId: $selectedGolferId)
                        .environmentObject(roundViewModel)
                }
                scoreLegend
                Spacer()
            }
            
            finalizeRoundButton
                .padding(.vertical, 10)
        }
    }
    
    private var scorecardTypePicker: some View {
        Picker("Scorecard Type", selection: $selectedScorecardType) {
            Text("Stroke Play").tag(ScorecardType.strokePlay)
            Text("Match Play").tag(ScorecardType.matchPlay)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    private var finalizeRoundButton: some View {
        GeometryReader { geometry in
            Button(action: finalizeRound) {
                Text("Finalize Round")
                    .frame(width: min(geometry.size.width * 0.9, 400), height: 48)
                    .foregroundColor(.white)
                    .background(Color(.systemTeal))
                    .cornerRadius(10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: 60)
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
                    "name": golfer.fullName,
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
        .frame(maxWidth: .infinity)
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
    
    var scoreLegend: some View {
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
        .font(.caption)
    }
    
    private var golferPicker: some View {
        Picker("Select Golfer", selection: $selectedGolferId) {
            ForEach(roundViewModel.golfers) { golfer in
                Text(golfer.fullName).tag(golfer.id as String?)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal)
    }
    
    func legendItem<S: Shape>(color: Color, shape: S, text: String, addBorder: Bool = false) -> some View {
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

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

