//
//  ArrayEncoding.swift
//  
//
//  Created by Andrej Jasso on 18/10/2023.
//

import XCTest
import Alamofire
import GoodNetworking
import Combine

final class ArrayEncodingTests: XCTestCase {
    
    // MARK: - Alamofire Encode
    
    func test_encode_whenContainsArray() {
        if let body: [String] = assertEncodedBody(parameters: ["Hello", "World"].asParameters()) {
            XCTAssertEqual(body.count, 2)
            XCTAssertEqual(body[0], "Hello")
        }
    }

    func test_encode_whenContainsDictionary() {
        if let body: [String: String] = assertEncodedBody(parameters: ["Hello": "World"]) {
            XCTAssertEqual(body["Hello"], "World")
        }
    }

    // MARK: HELPERS

    private func assertEncodedBody<T>(parameters: Parameters) -> T? {
        let encoding = ArrayEncoding(defaultEncoder: JSONEncoding.default)
        let request = URLRequest(url: URL(string: "example.com")!)

        let requestEncoded = try! encoding.encode(request, with: parameters)

        do {
            return try JSONSerialization.jsonObject(with: requestEncoded.httpBody!) as? T
        } catch {
            XCTFail("Serialization Failed")
            return nil
        }
        
    }
    
    // MARK: - GRSession Request Encode
    
    enum Base: String {

        case base = "https://httpbin.org"

    }
    
    var testCancellable: AnyCancellable?

    func testGRSessionPostWithTopArrayJSON() {
        let session = GRSession<Endpoint, Base>(baseURL: .base, configuration: .default)
        let request: AnyPublisher<EmptyResponse,AFError> = session.request(endpoint: .unkeyedTopLevelList(MyStruct.sample))
            .goodify(type: EmptyResponse.self)
        let requestExpectation = expectation(description: "Request Expectation")

        testCancellable = request
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("Request failed with error: \(error)")
                }
                requestExpectation.fulfill()
                
            }, receiveValue: { _ in }
            )
        waitForExpectations(timeout: 5) // Adjust the timeout as needed
    }
    
    func testEndpointBuilder() {
        let session = GRSession<Endpoint, Base>(baseURL: .base, configuration: .default)
        let urlBodyTupple = session.endpointBuilder(endpoint: .unkeyedTopLevelList(MyStruct.sample))
        
        XCTAssert(urlBodyTupple.body != nil, "URL Body is nil")
        XCTAssert(urlBodyTupple.url != nil, "URL is nil")
    }
    
    // MARK: - Test Array Object Validity JSON
    
    func testValidJSONObject() {
        // Create an object that adheres to the JSON rules
        let validObject: [String: Any] = [
            "name": "John Doe",
            "age": 30,
            "address": [
                "street": "123 Main St",
                "city": "Sample City"
            ],
            "isActive": true
        ]

        XCTAssertTrue(JSONSerialization.isValidJSONObject(["Hello", "World"]))
        XCTAssertTrue(JSONSerialization.isValidJSONObject(validObject))
    }

    func testInvalidJSONObject() {
        // Create an object that does not adhere to the JSON rules
        let invalidObject: [String: Any] = [
            "name": "John Doe",
            "age": 30,
            "address": [
                "street": "123 Main St",
                "city": "Sample City",
                "country": ["name": "Country Name"] // Nested dictionary with a non-string key
            ],
            "isActive": Double.nan // NaN value
        ]
        
        // The binaryData key contains a Data object, which is not one of the supported types for JSON serialization.
        let invalidObject1: [String: Any] = [
            "name": "John Doe",
            "age": 30,
            "binaryData": Data(bytes: [0x01, 0x02, 0x03]) // Binary data
        ]
        
        // The colors key contains an array of UIColor objects, which are not one of the supported data types.
        let invalidObject2: [String: Any] = [
            "name": "John Doe",
            "age": 30,
            "colors": [UIColor.red, UIColor.blue] // UIColor objects
        ]
        
        // In this example, the dictionary uses an integer (42) as a key, which is not an NSString.
        let invalidObject3: [AnyHashable: Any] = [
            "name": "John Doe",
            42: "Answer to Everything" // Non-string key
        ]
        
        // The salary key contains a Double with an infinity value, which is not allowed.
        let invalidObject4: [String: Any] = [
            "name": "John Doe",
            "age": 30,
            "salary": Double.infinity // Infinity value
        ]
        
        // In this example, the isStudent key contains a custom class object (Student) which is not one of the supported types for JSON serialization.
        let invalidObject5: [String: Any] = [
            "name": "John Doe",
            "age": 30,
            "isStudent": MyObject(property1: "test", property2: 5) // Custom class object
        ]

        XCTAssertFalse(JSONSerialization.isValidJSONObject(invalidObject))
        XCTAssertFalse(JSONSerialization.isValidJSONObject(invalidObject1))
        XCTAssertFalse(JSONSerialization.isValidJSONObject(invalidObject2))
        XCTAssertFalse(JSONSerialization.isValidJSONObject(invalidObject3))
        XCTAssertFalse(JSONSerialization.isValidJSONObject(invalidObject4))
        XCTAssertFalse(JSONSerialization.isValidJSONObject(invalidObject5))
    }
    
}
