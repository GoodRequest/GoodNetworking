//
//  SwapiPerson.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 05/02/2025.
//

struct SwapiPerson: Decodable {
    let name: String
    let height: String
    let mass: String
    let birthYear: String
    let gender: String

    enum CodingKeys: String, CodingKey {
        case name, height, mass
        case birthYear = "birth_year"
        case gender
    }
}
