//
//  ScorecardViewType.swift
//  GolfGames
//
//  Created by Mike Dietrich on 7/10/24.
//

import Foundation

enum ScorecardViewType: String, CaseIterable, Identifiable {
    case scoreOnly = "Gross"
    case scoreAndNet = "Gross & Net "
    
    var id: String { self.rawValue }
}
