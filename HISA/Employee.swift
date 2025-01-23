//
//  Employee.swift
//  HISA
//
//  Created by Barnabas Li on 1/23/25.
//

import Foundation

struct Employee {
    let name: String
    let date: String
    let scans: Int
    var dataAccess: Bool
    let scanHistory: [String] // letting this be an array of strings for now, we can change it to the actual scan pictures later once the backend is done
}
