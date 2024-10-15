@Published var isStablefordGross: Bool = false

// Add these properties to store Stableford scores and quotas
@Published var stablefordGrossScores: [Int: [String: Int]] = [:]
@Published var stablefordGrossQuotas: [String: Int] = [:]
@Published var stablefordGrossTotalScores: [String: Int] = [:]

// Add these functions to the RoundViewModel class

func initializeStablefordGross(quotas: [String: Int]) {
    StablefordGrossModel.initializeStablefordGross(roundViewModel: self, quotas: quotas)
}

private func calculateStablefordGrossQuotas() -> [String: Int] {
    var quotas: [String: Int] = [:]
    for golfer in golfers {
        if let courseHandicap = courseHandicaps[golfer.id] {
            let quota = 36 - courseHandicap
            quotas[golfer.id] = quota
        }
    }
    return quotas
}

func updateStablefordGrossScore(for holeNumber: Int) {
    StablefordGrossModel.updateStablefordGrossScore(roundViewModel: self, holeNumber: holeNumber)
}

func recalculateStablefordGrossScores(upToHole: Int) {
    StablefordGrossModel.recalculateStablefordGrossScores(roundViewModel: self, upToHole: upToHole)
}

func resetStablefordGrossScore(for holeNumber: Int) {
    StablefordGrossModel.resetStablefordGrossScore(roundViewModel: self, holeNumber: holeNumber)
}

func displayStablefordGrossFinalResults() -> String {
    return StablefordGrossModel.displayFinalResults(roundViewModel: self)
}