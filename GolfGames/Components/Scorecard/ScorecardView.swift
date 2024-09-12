import SwiftUI
import Firebase
import Photos

class ImageSaver: NSObject {
    var successHandler: (() -> Void)?
    var errorHandler: ((Error) -> Void)?
    
    func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            errorHandler?(error)
        } else {
            successHandler?()
        }
    }
}

struct ScorecardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var roundViewModel: RoundViewModel
    @EnvironmentObject var singleRoundViewModel: SingleRoundViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedGolferId: String?
    @State private var navigateToInitialView = false
    @State private var selectedScorecardType: ScorecardType = .strokePlay
    @State private var isLandscape = false
    @State private var imageSaver = ImageSaver()
    @State private var currentScale: CGFloat = 1.0
    @State private var previousScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if geometry.size.width > geometry.size.height {
                    LandscapeScorecardView(
                        navigateToInitialView: $navigateToInitialView,
                        selectedScorecardType: $selectedScorecardType
                    )
                    
                } else {
                    portraitLayout
                }
            }
        }
        .navigationTitle("Round Review")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    shareScorecard()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            selectedGolferId = authViewModel.currentUser?.id
            AppDelegate.lockOrientation(.allButUpsideDown)
        }
        .onDisappear {
            AppDelegate.lockOrientation(.portrait)
        }
        .background(
            NavigationLink(destination: InititalView().environmentObject(authViewModel).environmentObject(roundViewModel), isActive: $navigateToInitialView) {
                EmptyView()
            }
            .isDetailLink(false)
        )
        .onChange(of: selectedScorecardType) { newValue in
            switch newValue {
            case .matchPlay, .betterBall, .ninePoint, .stablefordGross:
                AppDelegate.setOrientation(to: .landscapeRight)
            case .strokePlay:
                AppDelegate.lockOrientation(.allButUpsideDown)
            @unknown default:
                AppDelegate.lockOrientation(.allButUpsideDown)
            }
        }
    }
    
    func unlockOrientation() {
        AppDelegate.orientationLock = .all
        UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
    
    private var portraitLayout: some View {
        VStack(spacing: 10) {
            if roundViewModel.isMatchPlay || roundViewModel.isBetterBall || roundViewModel.isNinePoint || roundViewModel.isStablefordGross{
                scorecardTypePicker
            }
            
            if roundViewModel.golfers.count > 1 {
                golferPicker
            }
            
            if let golfer = selectedGolfer {
                ScrollView([.horizontal, .vertical]) {
                    scorecardContent(for: golfer)
                        .scaleEffect(currentScale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / self.previousScale
                                    self.previousScale = value
                                    let newScale = self.currentScale * delta
                                    self.currentScale = min(max(newScale, 1.0), 3.0) // Limit zoom between 1x and 3x
                                }
                                .onEnded { _ in
                                    self.previousScale = 1.0
                                }
                        )
                    
                    StatsView(golfer: golfer)
                        .environmentObject(roundViewModel)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            finalizeRoundButton
                .padding(.vertical, 10)
        }
    }
    
    private func scorecardContent(for golfer: Golfer) -> some View {
        VStack(spacing: 10) {
            switch selectedScorecardType {
            case .strokePlay:
                scoreCardView(for: golfer)
            case .matchPlay:
                MatchPlaySCView()
                    .environmentObject(roundViewModel)
            case .betterBall:
                BetterBallSCView()
                    .environmentObject(roundViewModel)
            case .ninePoint:
                NinePointSCView()
                    .environmentObject(roundViewModel)
            case .stablefordGross:
                StablefordGrossSCView()
                    .environmentObject(roundViewModel)
            case .games:
                // Handle the .games case here
                // You might want to show a different view or a placeholder
                Text("Games scorecard not implemented")
            @unknown default:
                // This catches any future cases that might be added to the enum
                Text("Unknown scorecard type")
            }
            scoreLegend
        }
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    withAnimation {
                        self.currentScale = 1.0
                    }
                }
        )
    }
    
    private var scorecardTypePicker: some View {
        Picker("Scorecard Type", selection: $selectedScorecardType) {
            Text("Stroke Play").tag(ScorecardType.strokePlay)
            if roundViewModel.isMatchPlay {
                Text("Match Play").tag(ScorecardType.matchPlay)
            }
            if roundViewModel.isBetterBall {
                Text("Better Ball").tag(ScorecardType.betterBall)
            }
            if roundViewModel.isNinePoint {
                Text("Nine Point").tag(ScorecardType.ninePoint)
            }
            if roundViewModel.isStablefordGross {
                Text("Stableford (Gross)").tag(ScorecardType.stablefordGross)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    private var finalizeRoundButton: some View {
        GeometryReader { geometry in
            Button(action: {
                // Reset zoom scale
                withAnimation {
                    self.currentScale = 1.0
                }
                // Wait for the animation to complete before finalizing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    finalizeRound()
                }
            }) {
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
    
    func shareScorecard() {
    guard let golfer = selectedGolfer else { return }
    
    let image = createShareableImage(for: golfer)
    
    // Convert the image to data
    guard let imageData = image.pngData() else {
        print("Failed to create image data")
        return
    }
    
    // Create an array of items to share
    let itemsToShare: [Any] = [imageData]
    
    // Create and configure the UIActivityViewController
    let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
    
    // Configure the popover presentation controller for iPad
    if let popoverController = activityViewController.popoverPresentationController {
        popoverController.sourceView = UIApplication.shared.windows.first
        popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
        popoverController.permittedArrowDirections = []
    }
    
    // Present the share sheet
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first,
       let rootViewController = window.rootViewController {
        rootViewController.present(activityViewController, animated: true, completion: nil)
    }
}
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        imageSaver.successHandler = {
            print("Image saved successfully")
            // You can show a success alert to the user here
        }
        imageSaver.errorHandler = { error in
            print("Error saving image: \(error.localizedDescription)")
            // You can show an error alert to the user here
        }
        imageSaver.saveImage(image)
    }
    
    private func presentShareSheet(for image: UIImage) {
        guard let imageData = image.pngData() else {
            print("Failed to create image data")
            return
        }
        
        let activityViewController = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = UIApplication.shared.windows.first
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    private func finalizeRound() {
        guard let user = authViewModel.currentUser,
              let course = roundViewModel.selectedCourse,
              let tee = roundViewModel.selectedTee else { return }
        
        let db = Firestore.firestore()
        let roundRef = db.collection("users").document(user.id).collection("rounds").document(roundViewModel.roundId ?? "")
        
        let roundResultID = roundRef.collection("results").document().documentID
        
        // Break down the roundData dictionary into smaller parts
        let basicRoundData: [String: Any] = [
            "date": Timestamp(date: Date()),
            "courseId": course.id,
            "courseName": course.name,
            "tees": tee.tee_name,
            "courseRating": tee.course_rating,
            "slopeRating": tee.slope_rating,
            "roundResultID": roundResultID
        ]
        
        let golfersData = roundViewModel.golfers.map { golfer in
            let grossTotal = roundViewModel.grossScores.values.reduce(0) { $0 + ($1[golfer.id] ?? 0) }
            let netTotal = roundViewModel.netStrokePlayScores.values.reduce(0) { $0 + ($1[golfer.id] ?? 0) }
            let birdies = roundViewModel.birdieCount[golfer.id] ?? 0
            let eagles = roundViewModel.eagleCount[golfer.id] ?? 0
            let pars = roundViewModel.parCount[golfer.id] ?? 0
            let bogeys = roundViewModel.bogeyCount[golfer.id] ?? 0
            let doubleBogeyPlus = roundViewModel.doubleBogeyPlusCount[golfer.id] ?? 0

            return [
                "id": golfer.id,
                "firstName": golfer.firstName,
                "lastName": golfer.lastName,
                "handicap": golfer.handicap,
                "grossTotal": grossTotal,
                "netTotal": netTotal,
                "birdies": birdies,
                "eagles": eagles,
                "pars": pars,
                "bogeys": bogeys,
                "doubleBogeyPlus": doubleBogeyPlus
            ]
        }
        
        var roundData = basicRoundData
        roundData["golfers"] = golfersData
        
        // Add hole-by-hole scores
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
                
                // Force orientation change to portrait
                AppDelegate.lockOrientation(.portrait, andRotateTo: .portrait)
                
                // Wait a short moment to ensure the orientation change has taken effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.navigateToInitialView = true
                }
            }
        }
    }
    
    private func resetLocalData() {
        // Reset general round data
        roundViewModel.grossScores.removeAll()
        roundViewModel.netStrokePlayScores.removeAll()
        roundViewModel.strokeHoles.removeAll()
        roundViewModel.selectedCourse = nil
        roundViewModel.selectedTee = nil
        roundViewModel.golfers.removeAll()
        roundViewModel.roundId = nil
        roundViewModel.holesPlayed = 0
        roundViewModel.courseHandicaps.removeAll()
        roundViewModel.holes.removeAll()
        roundViewModel.pars.removeAll()

        // Reset Match Play data
        roundViewModel.isMatchPlay = false
        roundViewModel.matchPlayNetScores.removeAll()
        roundViewModel.matchPlayStrokeHoles.removeAll()
        roundViewModel.holeWinners.removeAll()
        roundViewModel.matchStatusArray = Array(repeating: 0, count: 18)
        roundViewModel.matchScore = 0
        roundViewModel.matchWinner = nil
        roundViewModel.winningScore = nil
        roundViewModel.matchWinningHole = nil
        roundViewModel.finalMatchStatusArray = nil
        roundViewModel.matchPlayStatus = nil
        roundViewModel.presses.removeAll()
        roundViewModel.pressStatuses.removeAll()
        roundViewModel.currentPressStartHole = nil

        // Reset Better Ball data
        roundViewModel.isBetterBall = false
        roundViewModel.betterBallTeamAssignments.removeAll()
        roundViewModel.betterBallMatchStatus = nil
        roundViewModel.betterBallMatchWinner = nil
        roundViewModel.betterBallStrokeHoles.removeAll()
        roundViewModel.betterBallPresses.removeAll()
        roundViewModel.betterBallPressStatuses.removeAll()

        // Reset Nine Point data
        roundViewModel.isNinePoint = false
        roundViewModel.ninePointScores.removeAll()
        roundViewModel.ninePointTotalScores.removeAll()
        roundViewModel.ninePointStrokeHoles.removeAll()

        // Reset Stableford Gross data
        roundViewModel.isStablefordGross = false
        roundViewModel.stablefordGrossScores.removeAll()
        roundViewModel.stablefordGrossQuotas.removeAll()
        roundViewModel.stablefordGrossTotalScores.removeAll()

        // Reset round type and scorecard type
        roundViewModel.roundType = .full18
        roundViewModel.selectedScorecardType = .strokePlay

        // Reset stats
        roundViewModel.birdieCount.removeAll()
        roundViewModel.eagleCount.removeAll()
        roundViewModel.parCount.removeAll()
        roundViewModel.bogeyCount.removeAll()
        roundViewModel.doubleBogeyPlusCount.removeAll()

        // Force a UI update
        roundViewModel.objectWillChange.send()
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
        .foregroundColor(colorScheme == .light ? Color.primary : Color.black)
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
        .foregroundColor(colorScheme == .light ? Color.primary : Color.black)
        .font(.caption)
    }
    
    func scoreRow(for golfer: Golfer, holes: ClosedRange<Int>, isGross: Bool, showTotal: Bool = false, addBlankColumn: Bool = false) -> some View {
    HStack(spacing: 0) {
        Text(isGross ? "Gross" : "Net")
            .frame(width: 40, height: 27, alignment: .leading)
            .padding(.horizontal, 2)
            .background(Color(UIColor.systemGray4))
            .foregroundColor(colorScheme == .light ? Color.black : Color.white)
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
            .foregroundColor(colorScheme == .light ? Color.primary : Color.white)
            .fontWeight(.bold)
        if showTotal {
            let grandTotal = singleRoundViewModel.holes.reduce(0) { total, hole in
                total + (isGross ? roundViewModel.grossScores[hole.holeNumber]?[golfer.id] ?? 0 : roundViewModel.netStrokePlayScores[hole.holeNumber]?[golfer.id] ?? 0)
            }
            Text("\(grandTotal)")
                .frame(width: 32, height: 27)
                .background(Color(UIColor.systemGray4))
                .foregroundColor(colorScheme == .light ? Color.black : Color.white)
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
            if isNegativeHandicap(for: golfer.id) {
                Text("+")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(strokeDotColor(score: score, par: par))
                    .offset(x: 7, y: -7)
            } else {
                Circle()
                    .fill(strokeDotColor(score: score, par: par))
                    .frame(width: 6, height: 6)
                    .offset(x: 7, y: -7)
            }
        }
    }
}
    
    private func isNegativeHandicap(for golferId: String) -> Bool {
        return roundViewModel.courseHandicaps[golferId] ?? 0 < 0
    }
    
    func strokeDotColor(score: Int, par: Int) -> Color {
        if score <= par - 1 || score >= par + 1 {
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
            Circle()
                .stroke(Color.yellow, lineWidth: 3)
        } else if score == par - 1 {
            Circle()
                .stroke(Color.red, lineWidth: 3)
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
        } else if score >= par + 1 {
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
                Text("\(golfer.firstName) \(golfer.lastName)").tag(golfer.id as String?)
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

    func requestPhotoLibraryAccess() {
    PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
            switch status {
            case .authorized, .limited:
                print("Photo library access granted")
                // You can enable your "Save Image" functionality here
            case .denied, .restricted:
                print("Photo library access denied")
                // You might want to show an alert to the user explaining how to enable access in Settings
            case .notDetermined:
                print("Photo library access not determined")
                // This shouldn't happen at this point, but you might want to handle it just in case
            @unknown default:
                print("Unknown photo library access status")
            }
        }
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

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
    var value: CGSize
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

struct StatsView: View {
    let golfer: Golfer
    @EnvironmentObject var roundViewModel: RoundViewModel

    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            Text("Stats")
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack {
                statItem(label: "Eagles", value: roundViewModel.eagleCount[golfer.id] ?? 0)
                statItem(label: "Birdies", value: roundViewModel.birdieCount[golfer.id] ?? 0)
            }
            
            HStack {
                statItem(label: "Pars", value: roundViewModel.parCount[golfer.id] ?? 0)
            }
            
            HStack {
                statItem(label: "Bogeys", value: roundViewModel.bogeyCount[golfer.id] ?? 0)
                statItem(label: "Double+", value: roundViewModel.doubleBogeyPlusCount[golfer.id] ?? 0)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private func statItem(label: String, value: Int) -> some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

extension ScorecardView {
    func createShareableImage(for golfer: Golfer) -> UIImage {
    let scorecard = scoreCardView(for: golfer)
    
    let controller = UIHostingController(rootView: scorecard)
    controller.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    controller.view.layoutIfNeeded()
    
    let targetSize = controller.view.sizeThatFits(CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
    controller.view.bounds = CGRect(origin: .zero, size: targetSize)
    controller.view.sizeToFit()
    
    let scorecardImage = controller.view.asImage(size: targetSize)
    
    let headerHeight: CGFloat = 40
    let legendHeight: CGFloat = 30
    let footerHeight: CGFloat = 50
    let horizontalPadding: CGFloat = 22
    let finalSize = CGSize(width: targetSize.width, height: targetSize.height + headerHeight + legendHeight + footerHeight)
    
    let format = UIGraphicsImageRendererFormat()
    format.scale = 5.0
    let renderer = UIGraphicsImageRenderer(size: finalSize, format: format)
    
    return renderer.image { context in
        UIColor.systemBackground.setFill()
        context.fill(CGRect(origin: .zero, size: finalSize))
        
        // Draw the logo
        if let logoImage = UIImage(named: "golfgamble_bag") {
            let logoSize = CGSize(width: 30, height: 30)
            let logoRect = CGRect(x: horizontalPadding, y: 5, width: logoSize.width, height: logoSize.height)
            context.cgContext.saveGState()
            context.cgContext.addPath(UIBezierPath(roundedRect: logoRect, cornerRadius: 5).cgPath)
            context.cgContext.clip()
            logoImage.draw(in: logoRect)
            context.cgContext.restoreGState()
        }
        
        // Draw "BirdieBank" text
        let birdieBankAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
        "BirdieBank".draw(with: CGRect(x: horizontalPadding + 35, y: 17, width: 100, height: 20), options: .usesLineFragmentOrigin, attributes: birdieBankAttrs, context: nil)
        
        // Draw date in top right
        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label
        ]
        let dateSize = (dateString as NSString).size(withAttributes: dateAttrs)
        dateString.draw(with: CGRect(x: finalSize.width - dateSize.width - horizontalPadding - 5, y: 20, width: dateSize.width, height: 20), options: .usesLineFragmentOrigin, attributes: dateAttrs, context: nil)
        
        // Draw golfer name in top right
        let golferName = "\(golfer.firstName) \(golfer.lastName)"
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label
        ]
        let nameSize = (golferName as NSString).size(withAttributes: nameAttrs)
        golferName.draw(with: CGRect(x: finalSize.width - nameSize.width - horizontalPadding - 5, y: 20, width: nameSize.width, height: 20), options: .usesLineFragmentOrigin, attributes: nameAttrs, context: nil)
        
        // Draw the scorecard
        scorecardImage.draw(at: CGPoint(x: 0, y: headerHeight))
        
        // Draw the legend
        drawLegend(in: context, at: CGPoint(x: 0, y: headerHeight + targetSize.height), width: finalSize.width)
        
        // Draw additional information below the scorecard and legend
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        
        let courseName = roundViewModel.selectedCourse?.name ?? "Unknown Course"
        let teeName = roundViewModel.selectedTee?.tee_name ?? "Unknown Tee"
        let slope = roundViewModel.selectedTee?.slope_rating ?? 0
        let courseRating = roundViewModel.selectedTee?.course_rating ?? 0
        let par = singleRoundViewModel.holes.reduce(0) { $0 + $1.par }
        let yardage = roundViewModel.selectedTee?.tee_yards ?? 0
        
        let infoString = """
        \(courseName) | Tees: \(teeName)
        Slope: \(slope) | Rating: \(String(format: "%.1f", courseRating)) | Par: \(par) | \(yardage) Yards
        """
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let footerAttrsWithParagraphStyle = footerAttrs.merging([.paragraphStyle: paragraphStyle]) { (_, new) in new }
        
        let infoRect = CGRect(x: 0, y: headerHeight + targetSize.height + legendHeight + 5, width: finalSize.width, height: footerHeight - 10)
        infoString.draw(with: infoRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: footerAttrsWithParagraphStyle, context: nil)
    }
}

func drawLegend(in context: UIGraphicsImageRendererContext, at point: CGPoint, width: CGFloat) {
    let legendItems: [(color: UIColor, shape: String, text: String)] = [
        (.yellow, "●", "Eagle or better"),
        (.red, "●", "Birdie"),
        (.black, "■", "Bogey"),
        (.blue, "■", "Double bogey +")
    ]
    
    let fontSize: CGFloat = 10
    let shapeSize: CGFloat = 10
    let itemSpacing: CGFloat = 10
    let itemHeight: CGFloat = 20
    
    // Calculate total width of all items
    let totalWidth = legendItems.reduce(0) { (result, item) -> CGFloat in
        let textWidth = (item.text as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: fontSize)]).width
        return result + shapeSize + 5 + textWidth + itemSpacing
    } - itemSpacing // Subtract last spacing
    
    // Calculate start X position to center the legend
    let startX = (width - totalWidth) / 2
    
    var currentX = startX
    for item in legendItems {
        // Draw shape
        let shapeRect = CGRect(x: currentX, y: point.y + (itemHeight - shapeSize) / 2, width: shapeSize, height: shapeSize)
        context.cgContext.setFillColor(item.color.cgColor)
        
        if item.shape == "●" {
            context.cgContext.fillEllipse(in: shapeRect)
        } else {
            // For square shapes
            if item.color == .black && UITraitCollection.current.userInterfaceStyle == .dark {
                // Draw white border for black square in dark mode
                context.cgContext.setStrokeColor(UIColor.white.cgColor)
                context.cgContext.setLineWidth(1)
                context.cgContext.stroke(shapeRect)
            }
            context.cgContext.fill(shapeRect)
        }
        
        // Draw text
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.label
        ]
        let textSize = (item.text as NSString).size(withAttributes: textAttributes)
        let textRect = CGRect(x: currentX + shapeSize + 5, y: point.y + (itemHeight - textSize.height) / 2, width: textSize.width, height: textSize.height)
        item.text.draw(with: textRect, options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
        
        // Move to next item
        currentX += shapeSize + 5 + textSize.width + itemSpacing
    }
}
}
extension UIView {
    func asImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
    }
}
