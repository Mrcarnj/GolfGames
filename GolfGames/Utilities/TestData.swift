//
//  TestData.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/6/24.
//

import SwiftUI

struct TestData: View {
    @State private var handicapIndex: String = ""
    @State private var slopeRating: String = ""
    @State private var courseRating: String = ""
    @State private var par: String = ""
    @State private var calculatedHandicap: Int?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Handicap Calculator Test")
                .font(.title)
            
            TextField("Handicap Index", text: $handicapIndex)
                .keyboardType(.decimalPad)
            
            TextField("Slope Rating", text: $slopeRating)
                .keyboardType(.numberPad)
            
            TextField("Course Rating", text: $courseRating)
                .keyboardType(.decimalPad)
            
            TextField("Par", text: $par)
                .keyboardType(.numberPad)
            
            Button("Calculate") {
                calculateHandicap()
            }
            
            if let handicap = calculatedHandicap {
                Text("Calculated Course Handicap: \(handicap)")
                    .font(.headline)
            }
        }
        .padding()
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    private func calculateHandicap() {
        guard let handicapIndex = Float(handicapIndex),
              let slopeRating = Int(slopeRating),
              let courseRating = Float(courseRating),
              let par = Int(par) else {
            return
        }
        
        calculatedHandicap = calculateCourseHandicap(
            handicapIndex: handicapIndex,
            slopeRating: slopeRating,
            courseRating: courseRating,
            par: par
        )
    }
}

// MARK: - Handicap Calculation Functions
extension TestData {
    func calculateCourseHandicap(handicapIndex: Float, slopeRating: Int, courseRating: Float, par: Int) -> Int {
        let courseHandicap = (handicapIndex * Float(slopeRating) / 113) + (courseRating - Float(par))
        let roundedHandicap: Int
        
        if courseHandicap.truncatingRemainder(dividingBy: 1) >= 0.5 {
            roundedHandicap = Int(courseHandicap.rounded(.up))
        } else {
            roundedHandicap = Int(courseHandicap.rounded(.down))
        }
        
        return roundedHandicap
    }
    
//    func determineStrokePlayStrokeHoles(courseHandicap: Int, holes: [Hole]) -> [Int] {
//        let sortedHoles = holes.sorted { $0.handicap < $1.handicap }
//        let strokeHoles = sortedHoles.prefix(courseHandicap).map { $0.holeNumber }
//        return strokeHoles
//    }
//    
//    func determineMatchPlayStrokeHoles(matchPlayHandicap: Int, holes: [Hole]) -> [Int] {
//        let sortedHoles = holes.sorted { $0.handicap < $1.handicap }
//        let strokeHoles = sortedHoles.prefix(matchPlayHandicap).map { $0.holeNumber }
//        return strokeHoles
//    }
}

//// MARK: - Hole Structure
//struct Hole {
//    let holeNumber: Int
//    let handicap: Int
//}

// MARK: - Preview
struct TestData_Previews: PreviewProvider {
    static var previews: some View {
        TestData()
    }
}
