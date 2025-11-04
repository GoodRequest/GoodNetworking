//
//  JSON.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 15/07/2025.
//

import Foundation

// MARK: - JSON

/// Dynamic enumeration allowing access to JSON properties without having to specify
/// their exact structure as a decodable struct.
///
/// This approach allows variables mixing different types, effectively ignores invalid
/// or missing values, supports mixed-type arrays and easy access to properties within them.
///
/// Usage:
/// ```swift
/// // Get JSON from web response
/// let user: JSON = try await session.get("/user")
///
/// // name as an optional <String?>
/// let name = user.name.string
///
/// // age as <Int?>
/// let age = user.age.int
///
/// // name of the pet if user has pets, it is an array,
/// // and contains an element, which has a `name` property
/// //
/// // resolved as <String?>
/// let petName = user.pets[0].name.string
/// ```
///
/// This approach is very effective in cases where the data is meant to be
/// displayed in the user interface and does not need any further processing.
@dynamicMemberLookup public enum JSON: Sendable {
    
    case dictionary(Dictionary<String, JSON>)
    case array(Array<JSON>)
    case string(String)
    case number(NSNumber)
    case bool(Bool)
    case null
    
    // MARK: - Dynamic Member Lookup
    
    public subscript(dynamicMember member: String) -> JSON {
        if case .dictionary(let dict) = self {
            return dict[member] ?? .null
        }
        return .null
    }
    
    // MARK: - Subscript access
    
    public subscript(index: Int) -> JSON {
        if case .array(let arr) = self {
            return index < arr.count ? arr[index] : .null
        }
        return .null
    }
    
    public subscript(key: String) -> JSON {
        if case .dictionary(let dict) = self {
            return dict[key] ?? .null
        }
        return .null
    }
    
    // MARK: - Initializers
    
    /// Create JSON from raw `Data`
    /// - Parameters:
    ///   - data: Raw `Data` of JSON object
    ///   - options: Optional serialization options
    public init(data: Data, options: JSONSerialization.ReadingOptions = .allowFragments) throws {
        if data.isEmpty {
            self = JSON.null
        } else {
            let object = try JSONSerialization.jsonObject(with: data, options: options)
            self = JSON(object)
        }
    }
    
    /// Create JSON from an encodable model, for example to be sent between
    /// API boundaries or for pretty-printing.
    /// - Parameters:
    ///   - model: `Encodable` model
    ///   - encoder: Encoder for encoding the model
    public init(encodable model: any Encodable, encoder: JSONEncoder) {
        if let data = try? encoder.encode(model), let converted = try? JSON(data: data) {
            self = converted
        } else {
            self = JSON.null
        }
    }
    
    /// Try representing any Swift object as a dynamic structure. If conversion fails,
    /// result of initialization will be `JSON.null`.
    ///
    /// This can be useful when type of objects is not known and needs to be encoded/decoded
    /// before manipulation, or for pretty-printing unknown data.
    ///
    /// - Parameter object: Object to try to represent as JSON
    public init(_ object: Any) {
        if let data = object as? Data, let converted = try? JSON(data: data) {
            self = converted
        } else if let model = object as? any Encodable, let data = try? JSONEncoder().encode(model), let converted = try? JSON(data: data) {
            self = converted
        } else if let dictionary = object as? [String: Any] {
            self = JSON.dictionary(dictionary.mapValues { JSON($0) })
        } else if let array = object as? [Any] {
            self = JSON.array(array.map { JSON($0) })
        } else if let string = object as? String {
            self = JSON.string(string)
        } else if let bool = object as? Bool {
            self = JSON.bool(bool)
        } else if let number = object as? NSNumber {
            self = JSON.number(number)
        } else if let json = object as? JSON {
            self = json
        } else {
            self = JSON.null
        }
    }
    
    // MARK: - Accessors
    
    /// Access the JSON value as a dictionary
    public var dictionary: Dictionary<String, JSON>? {
        if case .dictionary(let value) = self {
            return value
        }
        return nil
    }
    
    /// Access the JSON value as an array
    public var array: Array<JSON>? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }
    
    /// Access the JSON value as a string.
    ///
    /// If the value is a number or a boolean, it is converted to String
    /// before returning.
    public var string: String? {
        if case .string(let value) = self {
            return value
        } else if case .bool(let value) = self {
            return value ? "true" : "false"
        } else if case .number(let value) = self {
            return value.stringValue
        } else {
            return nil
        }
    }
    
    /// Access the JSON value as a number. This allows representing
    /// the same numeric value as different types (see `NSNumber`).
    ///
    /// If the value is string or a boolean, it is converted to NSNumber
    /// before returning.
    public var number: NSNumber? {
        if case .number(let value) = self {
            return value
        } else if case .bool(let value) = self {
            return NSNumber(value: value)
        } else if case .string(let value) = self, let doubleValue = Double(value) {
            return NSNumber(value: doubleValue)
        } else {
            return nil
        }
    }
    
    /// Access the JSON value as a numeric `Double`.
    public var double: Double? {
        return number?.doubleValue
    }
    
    /// Access the JSON value as an Integer.
    public var int: Int? {
        return number?.intValue
    }
    
    /// Access the JSON value as a boolean.
    ///
    /// If the value is a numeric zero, result will be `false`, otherwise `true`.
    ///
    /// If the value is one of `true`, `t`, `yes`, `y` or `1`, result
    /// will be `true`.
    ///
    /// If the value is one of `false`, `f`,  `no`, `n`, `0`, result
    /// will be `false`.
    ///
    /// If the value is not a valid boolean, number, or a string, the result
    /// will be `nil`.
    public var bool: Bool? {
        if case .bool(let value) = self {
            return value
        } else if case .number(let value) = self {
            return value.boolValue
        } else if case .string(let value) = self,
                  (["true", "t", "yes", "y", "1"].contains { value.caseInsensitiveCompare($0) == .orderedSame }) {
            return true
        } else if case .string(let value) = self,
                  (["false", "f", "no", "n", "0"].contains { value.caseInsensitiveCompare($0) == .orderedSame }) {
            return false
        } else {
            return nil
        }
    }
    
    // MARK: - Public
    
    /// Access the JSON value as a Foundation object of unknown type.
    public var object: Any {
        get {
            switch self {
            case .dictionary(let value): return value.mapValues { $0.object }
            case .array(let value): return value.map { $0.object }
            case .string(let value): return value
            case .number(let value): return value
            case .bool(let value): return value
            case .null: return NSNull()
            }
        }
    }
    
    /// Serialize the `JSON` enumeration as `Data` containing the JSON representation.
    /// - Parameter options: Serialization options
    /// - Returns: Representation of the value in JavaScript Object Notation format (JSON)
    public func data(options: JSONSerialization.WritingOptions = []) -> Data {
        return (try? JSONSerialization.data(withJSONObject: self.object, options: options)) ?? Data()
    }
    
}

// MARK: - Comparable

extension JSON: Comparable {
    
    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs, rhs) {
        case (.dictionary, .dictionary): return lhs.dictionary == rhs.dictionary
        case (.array, .array): return lhs.array == rhs.array
        case (.string, .string): return lhs.string == rhs.string
        case (.number, .number): return lhs.number == rhs.number
        case (.bool, .bool): return lhs.bool == rhs.bool
        case (.null, .null): return true
        default: return false
        }
    }
    
    public static func < (lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs, rhs) {
        case (.string, .string):
            if let lhsString = lhs.string, let rhsString = rhs.string {
                return lhsString < rhsString
            }
            return false
            
        case (.number, .number):
            if let lhsNumber = lhs.number, let rhsNumber = rhs.number {
                return lhsNumber.doubleValue < rhsNumber.doubleValue
            }
            return false
            
        default:
            return false
        }
    }
    
}

// MARK: - ExpressibleByLiteral

extension JSON: Swift.ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (String, Any)...) {
        let dictionary = elements.reduce(into: [String: Any](), { $0[$1.0] = $1.1})
        self.init(dictionary)
    }
    
}

extension JSON: Swift.ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
    
}

extension JSON: Swift.ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
    
}

extension JSON: Swift.ExpressibleByFloatLiteral {
    
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
    
}

extension JSON: Swift.ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
    
}

extension JSON: Swift.ExpressibleByBooleanLiteral {
    
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
    
}

// MARK: - Pretty Print

extension JSON: Swift.CustomStringConvertible, Swift.CustomDebugStringConvertible {
    
    public var description: String {
        return String(describing: self.object as AnyObject).replacingOccurrences(of: ";\n", with: "\n")
    }
    
    public var debugDescription: String {
        return description
    }
    
}
