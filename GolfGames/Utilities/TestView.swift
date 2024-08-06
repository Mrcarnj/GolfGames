import SwiftUI
import Firebase

struct ScorecardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedGolferId: String?
    @State private var navigateToInitialView = false
    
    private var isLandscape: Bool {
        return horizontalSizeClass == .regular
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isLandscape {
                landscapeLayout(geometry: geometry)
            } else {
                portraitLayout(geometry: geometry)
            }
        }
        .navigationTitle("Round Review")
        .navigationBarTitleDisplayMode(isLandscape ? .inline : .large)
        .navigationBarItems(trailing: isLandscape ? finishButton : nil)
        .navigationBarHidden(false)
        .onAppear {
            selectedGolferId = authViewModel.currentUser?.id
        }
        .background(
            NavigationLink(destination: InititalView().environmentObject(authViewModel).environmentObject(roundViewModel), isActive: $navigateToInitialView) {
                EmptyView()
            }
        )
    }
    
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                scoreLegend
                Spacer()
            }
            .frame(width: geometry.size.width * 0.2)
            .padding(.top, 20)
            
            VStack(spacing: 10) {
                if roundViewModel.golfers.count > 1 {
                    golferPicker
                }
                
                if let golfer = selectedGolfer {
                    scoreCardView(for: golfer)
                        .scaleEffect(1.1)
                }
                
                Spacer()
            }
            .frame(width: geometry.size.width * 0.8)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            if roundViewModel.golfers.count > 1 {
                golferPicker
            }
            
            if let golfer = selectedGolfer {
                Spacer()
                scoreCardView(for: golfer)
                scoreLegend
                Spacer()
            }
            
            finalizeRoundButton
                .padding(.vertical, 10)
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
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
    
    private var finishButton: some View {
        Button("Finish") {
            finalizeRound()
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
                    "name": golfer.fullName,
                    "handicap": golfer.handicap,
                    "grossTotal": roundViewModel.grossScores.values.reduce(0) { $0 + ($1[golfer.id] ?? 0) },
                    "netTotal": roundViewModel.netScores.values.reduce(0) { $0 + ($1[golfer.id] ?? 0) }
                ]
            }
        ]

        for (hole, scores) in roundViewModel.grossScores {
            for (golferId, score) in scores {
                roundData["gross_hole_\(hole)_\(golferId)"] = score
            }
        }

        for (hole, scores) in roundViewModel.netScores {
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
        roundViewModel.netScores = [:]
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
                total + (isGross ? roundViewModel.grossScores[hole]?[golfer.id] ?? 0 : roundViewModel.netScores[hole]?[golfer.id] ?? 0)
            }
            Text("\(totalScore)")
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.primary : Color.secondary)
                .fontWeight(.bold)
            if showTotal {
                let grandTotal = singleRoundViewModel.holes.reduce(0) { total, hole in
                    total + (isGross ? roundViewModel.grossScores[hole.holeNumber]?[golfer.id] ?? 0 : roundViewModel.netScores[hole.holeNumber]?[golfer.id] ?? 0)
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
        let score = isGross ? roundViewModel.grossScores[hole]?[golfer.id] ?? 0 : roundViewModel.netScores[hole]?[golfer.id] ?? 0
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
                    .fill(strokeDotColor)
                    .frame(width: 3, height: 3)
                    .offset(x: 7, y: -7)
            }
        }
    }

    var strokeDotColor: Color {
        colorScheme == .light ? .black : .white
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
        Group {
            if isLandscape {
                VStack(alignment: .leading, spacing: 5) {
                    legendItem(color: .yellow, shape: Circle(), text: "Eagle or better")
                    legendItem(color: .red, shape: Circle(), text: "Birdie")
                    legendItem(color: .black, shape: Rectangle(), text: "Bogey", addBorder: colorScheme == .dark)
                    legendItem(color: .blue, shape: Rectangle(), text: "Double bogey +")
                }
            } else {
                HStack(spacing: 10) {
                    legendItem(color: .yellow, shape: Circle(), text: "Eagle or better")
                    legendItem(color: .red, shape: Circle(), text: "Birdie")
                    legendItem(color: .black, shape: Rectangle(), text: "Bogey", addBorder: colorScheme == .dark)
                    legendItem(color: .blue, shape: Rectangle(), text: "Double bogey +")
                }
            }
            .font(.caption)
        }
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