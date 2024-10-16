//
//  JobUser.swift
//  GoodNetworking-Sample
//
//  Created by Filip Šašala on 19/07/2024.
//

import GoodNetworking

// MARK: - Model + remote

#warning("Unused example")
struct JobUser: Codable, Identifiable {

    var id: String?
    var name: String?
    var job: String?
    var createdAt: String?

}

extension JobUser: Placeholdable {

    static let placeholder: JobUser = JobUser(
        id: nil,
        name: "John Apple",
        job: "Engineer",
        createdAt: nil
    )

}
