struct ScoreCardView: View {
    @State private var selectedRoundType: RoundType = .full18
    @EnvironmentObject var roundViewModel: RoundViewModel

    var body: some View {
        VStack {
            // ... other content ...
            
            NinePointSCView(selectedRoundType: $selectedRoundType)
            
            // ... other content ...
        }
        .onAppear {
            // Ensure the selectedRoundType matches the roundViewModel's roundType
            selectedRoundType = roundViewModel.roundType
        }
        .onChange(of: selectedRoundType) { newValue in
            // Update roundViewModel when selectedRoundType changes
            roundViewModel.roundType = newValue
        }
    }
}