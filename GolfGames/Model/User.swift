//
//  User.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/3/24.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let handicap: Float?
    let ghinNumber: Int?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullName) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
}

extension User {
    static var MOCK_USER = User(id: NSUUID().uuidString, firstName: "Tiger", lastName: "Woods", email: "tiger@tgl.com", handicap: 1.2, ghinNumber: 1709023)
}
