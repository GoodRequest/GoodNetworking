//
//  HeroResponse.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import Foundation

struct HeroResponse: Decodable {
    
    let name: String
    let mass: String
    let height: String
    let gender: String
    
    var massText: String { "Mass: \(mass)" }
    var heightText: String { "Height: \(height)" }
    var genderText: String { "Gender: \(gender)" }
    
}
