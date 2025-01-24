//
//  Employee.swift
//  HISA
//
//  Created by Barnabas Li on 1/23/25.
//

import Foundation

struct Employee {
    var name: String
    var date: String
    var scans: Int
    var dataAccess: Bool
    var scanHistory: [String] // letting this be an array of strings for now, we can change it to the actual scan pictures later once the backend is done
}
