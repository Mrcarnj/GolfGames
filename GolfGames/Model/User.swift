//
//  User.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let fullname: String
    let email: String
    let handicap: Float?
    let ghinNumber: Int?
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let compnents = formatter.personNameComponents(from: fullname) {
            formatter.style = .abbreviated
            return formatter.string(from: compnents)
        }
        return ""
    }
}

extension User {
    static var MOCK_USER = User(id: NSUUID().uuidString, fullname: "Tiger Woods", email: "tiger@tgl.com", handicap: 1.2, ghinNumber: 1709023)
}
