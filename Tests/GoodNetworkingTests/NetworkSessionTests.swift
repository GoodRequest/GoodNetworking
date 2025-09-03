//
//  NetworkSessionTests.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 08/08/2025.
//

@testable import GoodNetworking
import Testing
import Foundation
import Sextant
import Hitch

let session = NetworkSession(baseUrl: "https://dummyjson.com")

// MARK: - Decoding

@Test func decodeDynamicPosts() async throws {
    let responseData = try await session.get("/products?limit=1000") as Data
    
    print(responseData.count)
    
    measure {
        let jsonResponse = JSON(responseData)
        print(jsonResponse.products[100].title.string as Any)
        print(jsonResponse.products[100]["description"].string as Any)
        print(jsonResponse.products[100].price.double as Any)
        print(jsonResponse.products[100].reviews.array?.first?.comment.string as Any)
        print(jsonResponse.products[100].images.array?.first?.string as Any)
    }

    measure {
        let structResponse = try? JSONDecoder().decode(ProductsResponse.self, from: responseData)
        print(structResponse?.products[100].title as Any)
        print(structResponse?.products[100].description as Any)
        print(structResponse?.products[100].price as Any)
        print(structResponse?.products[100].reviews?.first?.comment as Any)
        print(structResponse?.products[100].images?.first as Any)
    }
    
//    measure {
//        let results = Sextant.shared.query(responseData, values: Hitch(string: "$.products..[?(@.price>10)]..['title', 'description', 'price']")) as [String]?
//        print(results as Any)
//    }
    
}

func measure(_ block: () -> ()) {
    var duration: UInt64 = 0
    for _ in 0..<50 {
        let startTime: UInt64 = mach_absolute_time()
        block()
        let finishTime: UInt64 = mach_absolute_time()
        let timeDelta = (finishTime - startTime) / 1000
        duration += timeDelta
    }
    
    let averageDuration = duration / 50
    print(averageDuration, "us")
}

struct ProductsResponse: Decodable {
    
    struct Product: Decodable {
        let id: Int
        let title: String?
        let description: String?
        let category: String?
        let price: Double?
        let discountPercentage: Double?
        let rating: Double?
        let stock: Int?
        let tags: [String]?
        let brand: String?
        let sku: String?
        let weight: Double?
        let dimensions: Dimensions?
        let warrantyInformation: String?
        let shippingInformation: String?
        let availabilityStatus: String?
        let reviews: [Review]?
        let returnPolicy: String?
        let minimumOrderQuantity: Int?
        let meta: Meta?
        let images: [String]?
        let thumbnail: String?
    }

    struct Dimensions: Decodable {
        let width: Double?
        let height: Double?
        let depth: Double?
    }

    struct Review: Decodable {
        let rating: Int?
        let comment: String?
        let date: String?
        let reviewerName: String?
        let reviewerEmail: String?
    }

    struct Meta: Decodable {
        let createdAt: String?
        let updatedAt: String?
        let barcode: String?
        let qrCode: String?
    }
    
    let products: [Product]
    
}

// MARK: - Encoding

@Test func encodeDynamicJSON() async throws {
    let newUser = NewUserRequest(
        name: "Alice",
        email: "alice@example.com",
        age: 30
    )
    
    let newUserJson = [
        "name": "Alice",
        "email": "alice@example.com",
        "age": 30
    ] as JSON
    
    _ = try await session.post("/users", newUser) as JSON
    _ = try await session.post("/users", newUserJson) as JSON
}

struct NewUserRequest: Encodable {
    
    let name: String
    let email: String
    let age: Int
    
}
