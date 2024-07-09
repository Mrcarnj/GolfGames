//
//  Round.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/8/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Round: Identifiable, Codable {
    @DocumentID var id: String?
    var courseId: String
    var courseName: String
    var teeName: String
    var golfers: [Golfer]
    var date: Date
    
    struct Golfer: Identifiable, Codable {
        var id: String
        var name: String
        var handicap: Float
    }
}
