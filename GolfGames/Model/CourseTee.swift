//
//  CourseTee.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/4/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Course: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var location: String
    
    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct Tee: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var course_id: String
    var tee_name: String
    var course_rating: Float
    var slope_rating: Int
    var course_par: Int
    var tee_yards: Int
    
    static func == (lhs: Tee, rhs: Tee) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}



