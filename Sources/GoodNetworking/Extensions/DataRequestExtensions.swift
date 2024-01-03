//
//  DataRequestExtensions.swift
//
//
//  Created by Dominik Pethö on 4/30/19.
//

import Foundation
import Alamofire
import Combine

@available(iOS 13, *)
public extension DataRequest {

    /// Creates a `DataResponsePublisher` for this instance and uses a ``DecodableResponseSerializer`` to serialize the
    /// response.
    ///
    /// - Parameters:
    ///   - type:                `Decodable` type to which to decode response `Data`. Inferred from the context by default.
    ///   - queue:               `DispatchQueue` on which the `DataResponse` will be published. `.main` by default.
    ///   - preprocessor:        `DataPreprocessor` which filters the `Data` before serialization. `PassthroughPreprocessor()`
    ///                          by default.
    ///   - emptyResponseCodes:  `Set<Int>` of HTTP status codes for which empty responses are allowed. `[204, 205]` by
    ///                          default.
    ///   - emptyRequestMethods: `Set<HTTPMethod>` of `HTTPMethod`s for which empty responses are allowed, regardless of
    ///                          status code. `[.head]` by default.
    ///   - decoder:             `JSONDecoder` instance used to decode response `Data`. For `Decodable` `JSONDecoder()` by default.
    ///                          For `Decodable & WithCustomDecoder` custom `decoder` used by default.
    ///
    /// - Returns:               The `DataResponsePublisher`.
    func goodify<T: Decodable>(
        type: T.Type = T.self,
        queue: DispatchQueue = .main,
        preprocessor: DataPreprocessor = DecodableResponseSerializer<T>.defaultDataPreprocessor,
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<T>.defaultEmptyResponseCodes,
        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<T>.defaultEmptyRequestMethods,
        decoder: JSONDecoder = (T.self as? WithCustomDecoder.Type)?.decoder ?? JSONDecoder()
    ) -> AnyPublisher<T, AFError> {
        let serializer = DecodableResponseSerializer<T>(
            dataPreprocessor: preprocessor,
            decoder: decoder,
            emptyResponseCodes: emptyResponseCodes,
            emptyRequestMethods: emptyResponseMethods
        )
        return self.validate()
            .publishResponse(using: serializer, on: queue)
            .value()
    }

    /// Creates a `DataResponsePublisher` for this instance and uses a `DecodableResponseSerializer` to serialize the
    /// response.
    ///
    /// - Parameters:
    ///   - type:                `Decodable` type to which to decode response `Data`. Inferred from the context by default.
    ///   - queue:               `DispatchQueue` on which the `DataResponse` will be published. `.main` by default.
    ///   - preprocessor:        `DataPreprocessor` which filters the `Data` before serialization. `PassthroughPreprocessor()`
    ///                          by default.
    ///   - emptyResponseCodes:  `Set<Int>` of HTTP status codes for which empty responses are allowed. `[204, 205]` by
    ///                          default.
    ///   - emptyRequestMethods: `Set<HTTPMethod>` of `HTTPMethod`s for which empty responses are allowed, regardless of
    ///                          status code. `[.head]` by default.
    ///   - decoder:             `JSONDecoder` instance used to decode response `Data`. For `Decodable` `JSONDecoder()` by default.
    ///                          For `Decodable & WithCustomDecoder` custom `decoder` used by default.
    /// - Returns:               The `DataResponsePublisher`.
    func goodify<T: Decodable>(
        type: T.Type = T.self,
        queue: DispatchQueue = .main,
        preprocessor: DataPreprocessor = DecodableResponseSerializer<T>.defaultDataPreprocessor,
        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<T>.defaultEmptyResponseCodes,
        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<T>.defaultEmptyRequestMethods,
        decoder: JSONDecoder = (T.self as? WithCustomDecoder.Type)?.decoder ?? JSONDecoder()
    ) -> AnyPublisher<[T], AFError> {
        let serializer = DecodableResponseSerializer<[T]>(
            dataPreprocessor: preprocessor,
            decoder: decoder,
            emptyResponseCodes: emptyResponseCodes,
            emptyRequestMethods: emptyResponseMethods
        )
        return self.validate()
            .publishResponse(using: serializer, on: queue)
            .value()
    }

}

// MARK: - Private

public extension DataRequest {

    /// Creates a `DataResponse` object from the input `value`.
    ///
    /// - Parameter value: The value to be stored in the resulting `DataResponse` object.
    /// - Returns: A `DataResponse` object with the input `value` as its result.
    func response<T>(withValue value: T) -> DataResponse<T, AFError> {
        return DataResponse<T, AFError>(
            request: request,
            response: response,
            data: data,
            metrics: .none,
            serializationDuration: 30,
            result: AFResult<T>.success(value)
        )
    }

    /// Returns a `DataResponse` with a specified error.
    /// 
    /// - Parameter error: The error to be included in the response.
    /// - Returns: A `DataResponse` with the specified error.
    func response<T>(withError error: AFError) -> DataResponse<T, AFError> {
        return DataResponse<T, AFError>(
            request: request,
            response: response,
            data: data,
            metrics: .none,
            serializationDuration: 30,
            result: AFResult<T>.failure(error)
        )
    }

}
