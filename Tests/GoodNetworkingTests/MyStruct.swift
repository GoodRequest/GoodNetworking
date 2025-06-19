import GoodNetworking

struct MyStruct: Encodable, WithCustomEncoder {
    
    let objects: [MyObject]

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(objects)
    }
    
    static let sample: MyStruct = .init(objects: [
        .init(property1: "Test", property2: 1),
        .init(property1: "Test1", property2: 2),
        .init(property1: "Test2", property2: 3),
        .init(property1: "Test3", property2: 4)
    ])
    
}

struct MyObject: Encodable {
    
    let property1: String
    let property2: Int
    
    enum CodingKeys: CodingKey {
        case property1
        case property2
    }
    
    func jsonDict() -> [String: Any] {
        return [
            CodingKeys.property1.stringValue : property1,
            CodingKeys.property2.stringValue : property2
        ]
    }
    
}

struct EmptyResponse: Decodable {}
