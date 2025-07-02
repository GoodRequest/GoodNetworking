//
//  Goodify.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 4/30/19.
//

//import Combine
//import Foundation

//@available(iOS 13, *)
//public extension DataRequest {
//
//    /// Processes the network request and decodes the response into the specified type.
//    ///
//    /// This method validates the response using the provided `ValidationProviding` instance and then decodes the response data
//    /// into the specified type `T`. The decoding process is customizable with parameters such as data preprocessor,
//    /// JSON decoder, and sets of HTTP methods and status codes to consider as "empty" responses.
//    ///
//    /// - Parameters:
//    ///   - type: The expected type of the response data, defaulting to `T.self`.
//    ///   - validator: The validation provider used to validate the response. Defaults to `DefaultValidationProvider`.
//    ///   - preprocessor: The preprocessor for manipulating the response data before decoding.
//    ///   - emptyResponseCodes: The HTTP status codes that indicate an empty response.
//    ///   - emptyRequestMethods: The HTTP methods that indicate an empty response.
//    ///   - decoder: The JSON decoder used for decoding the response data. If the type conforms to `WithCustomDecoder`, the custom decoder is used.
//    /// - Returns: A `DataTask` that contains the decoded result.
//    func goodify<T: Decodable>(
//        type: T.Type = T.self,
//        validator: any ValidationProviding = DefaultValidationProvider(),
//        preprocessor: DataPreprocessor = DecodableResponseSerializer<T>.defaultDataPreprocessor,
//        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<T>.defaultEmptyResponseCodes,
//        emptyRequestMethods: Set<HTTPMethod> = DecodableResponseSerializer<T>.defaultEmptyRequestMethods,
//        decoder: JSONDecoder = (T.self as? WithCustomDecoder.Type)?.decoder ?? JSONDecoder()
//    ) -> DataTask<T> {
//        return self
//            .validate {
//                self.goodifyValidation(
//                    request: $0,
//                    response: $1,
//                    data: $2,
//                    emptyResponseCodes: emptyResponseCodes,
//                    emptyRequestMethods: emptyRequestMethods,
//                    validator: validator
//                )
//            }
//            .serializingDecodable(
//                T.self,
//                automaticallyCancelling: true,
//                dataPreprocessor: preprocessor,
//                decoder: decoder,
//                emptyResponseCodes: emptyResponseCodes,
//                emptyRequestMethods: emptyRequestMethods
//            )
//    }
//
//    /// Processes the network request and decodes the response into the specified type using Combine.
//    ///
//    /// This is a legacy implementation using Combine for handling network responses. It validates the response,
//    /// then publishes the decoded result or an error. This version of the method is deprecated.
//    ///
//    /// - Parameters:
//    ///   - type: The expected type of the response data, defaulting to `T.self`.
//    ///   - queue: The queue on which the response is published.
//    ///   - preprocessor: The preprocessor for manipulating the response data before decoding.
//    ///   - emptyResponseCodes: The HTTP status codes that indicate an empty response.
//    ///   - emptyResponseMethods: The HTTP methods that indicate an empty response.
//    ///   - decoder: The JSON decoder used for decoding the response data.
//    /// - Returns: A `Publisher` that publishes the decoded result or an `AFError`.
//    @available(*, deprecated, message: "Legacy Combine implementation")
//    func goodify<T: Decodable>(
//        type: T.Type = T.self,
//        queue: DispatchQueue = .main,
//        preprocessor: DataPreprocessor = DecodableResponseSerializer<T>.defaultDataPreprocessor,
//        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<T>.defaultEmptyResponseCodes,
//        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<T>.defaultEmptyRequestMethods,
//        decoder: JSONDecoder = (T.self as? WithCustomDecoder.Type)?.decoder ?? JSONDecoder()
//    ) -> AnyPublisher<T, AFError> where T: Sendable {
//        let serializer = DecodableResponseSerializer<T>(
//            dataPreprocessor: preprocessor,
//            decoder: decoder,
//            emptyResponseCodes: emptyResponseCodes,
//            emptyRequestMethods: emptyResponseMethods
//        )
//        return self.validate()
//            .publishResponse(using: serializer, on: queue)
//            .value()
//    }
//
//    /// Processes the network request and decodes the response into an array of the specified type.
//    ///
//    /// This method validates the response using the provided `ValidationProviding` instance and then decodes the response data
//    /// into an array of the specified type `[T]`. The decoding process is customizable with parameters such as data preprocessor,
//    /// JSON decoder, and sets of HTTP methods and status codes to consider as "empty" responses.
//    ///
//    /// - Parameters:
//    ///   - type: The expected type of the response data, defaulting to `[T].self`.
//    ///   - validator: The validation provider used to validate the response. Defaults to `DefaultValidationProvider`.
//    ///   - preprocessor: The preprocessor for manipulating the response data before decoding.
//    ///   - emptyResponseCodes: The HTTP status codes that indicate an empty response.
//    ///   - emptyRequestMethods: The HTTP methods that indicate an empty response.
//    ///   - decoder: The JSON decoder used for decoding the response data. If the type conforms to `WithCustomDecoder`, the custom decoder is used.
//    /// - Returns: A `DataTask` that contains the decoded array result.
//    func goodify<T: Decodable>(
//        type: [T].Type = [T].self,
//        validator: any ValidationProviding = DefaultValidationProvider(),
//        preprocessor: DataPreprocessor = DecodableResponseSerializer<T>.defaultDataPreprocessor,
//        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<T>.defaultEmptyResponseCodes,
//        emptyRequestMethods: Set<HTTPMethod> = DecodableResponseSerializer<T>.defaultEmptyRequestMethods,
//        decoder: JSONDecoder = (T.self as? WithCustomDecoder.Type)?.decoder ?? JSONDecoder()
//    ) -> DataTask<[T]> {
//        return self
//            .validate {
//                self.goodifyValidation(
//                    request: $0,
//                    response: $1,
//                    data: $2,
//                    emptyResponseCodes: emptyResponseCodes,
//                    emptyRequestMethods: emptyRequestMethods,
//                    validator: validator
//                )
//            }
//            .serializingDecodable(
//                [T].self,
//                automaticallyCancelling: true,
//                dataPreprocessor: preprocessor,
//                decoder: decoder,
//                emptyResponseCodes: emptyResponseCodes,
//                emptyRequestMethods: emptyRequestMethods
//            )
//    }
//
//    /// Processes the network request and decodes the response into an array of the specified type using Combine.
//    ///
//    /// This is a legacy implementation using Combine for handling network responses. It validates the response,
//    /// then publishes the decoded result or an error. This version of the method is deprecated.
//    ///
//    /// - Parameters:
//    ///   - type: The expected type of the response data, defaulting to `[T].self`.
//    ///   - queue: The queue on which the response is published.
//    ///   - preprocessor: The preprocessor for manipulating the response data before decoding.
//    ///   - emptyResponseCodes: The HTTP status codes that indicate an empty response.
//    ///   - emptyResponseMethods: The HTTP methods that indicate an empty response.
//    ///   - decoder: The JSON decoder used for decoding the response data.
//    /// - Returns: A `Publisher` that publishes the decoded result or an `AFError`.
//    @available(*, deprecated, message: "Legacy Combine implementation")
//    func goodify<T: Decodable>(
//        type: [T].Type = [T].self,
//        queue: DispatchQueue = .main,
//        preprocessor: DataPreprocessor = DecodableResponseSerializer<T>.defaultDataPreprocessor,
//        emptyResponseCodes: Set<Int> = DecodableResponseSerializer<T>.defaultEmptyResponseCodes,
//        emptyResponseMethods: Set<HTTPMethod> = DecodableResponseSerializer<T>.defaultEmptyRequestMethods,
//        decoder: JSONDecoder = (T.self as? WithCustomDecoder.Type)?.decoder ?? JSONDecoder()
//    ) -> AnyPublisher<[T], AFError> where T: Sendable {
//        let serializer = DecodableResponseSerializer<[T]>(
//            dataPreprocessor: preprocessor,
//            decoder: decoder,
//            emptyResponseCodes: emptyResponseCodes,
//            emptyRequestMethods: emptyResponseMethods
//        )
//        return self.validate()
//            .publishResponse(using: serializer, on: queue)
//            .value()
//    }
//
//}
//
//public extension DataRequest {
//
//    /// Creates a `DataResponse` with the specified success value.
//    ///
//    /// - Parameter value: The value to set as the success result.
//    /// - Returns: A `DataResponse` object with the success value.
//    func response<T>(withValue value: T) -> DataResponse<T, AFError> {
//        return DataResponse<T, AFError>(
//            request: request,
//            response: response,
//            data: data,
//            metrics: .none,
//            serializationDuration: 30,
//            result: AFResult<T>.success(value)
//        )
//    }
//
//    /// Creates a `DataResponse` with the specified error.
//    ///
//    /// - Parameter error: The error to set as the failure result.
//    /// - Returns: A `DataResponse` object with the failure error.
//    func response<T>(withError error: AFError) -> DataResponse<T, AFError> {
//        return DataResponse<T, AFError>(
//            request: request,
//            response: response,
//            data: data,
//            metrics: .none,
//            serializationDuration: 30,
//            result: AFResult<T>.failure(error)
//        )
//    }
//
//}
//
//// MARK: - Validation
//
//extension DataRequest {
//
//    /// Validates the response using a custom validator.
//    ///
//    /// This method checks if the response data is valid according to the provided `ValidationProviding` instance.
//    /// If the validation fails, an error is returned.
//    ///
//    /// - Parameters:
//    ///   - request: The original URL request.
//    ///   - response: The HTTP response received.
//    ///   - data: The response data.
//    ///   - emptyResponseCodes: The HTTP status codes that indicate an empty response.
//    ///   - emptyRequestMethods: The HTTP methods that indicate an empty response.
//    ///   - validator: The validation provider used to validate the response.
//    /// - Returns: A `ValidationResult` indicating whether the validation succeeded or failed.
//    private func goodifyValidation(
//        request: URLRequest?,
//        response: HTTPURLResponse,
//        data: Data?,
//        emptyResponseCodes: Set<Int>,
//        emptyRequestMethods: Set<HTTPMethod>,
//        validator: any ValidationProviding
//    ) -> ValidationResult {
//        guard let data else {
//            let emptyResponseAllowed = requestAllowsEmptyResponseData(request, emptyRequestMethods: emptyRequestMethods)
//                || responseAllowsEmptyResponseData(response, emptyResponseCodes: emptyResponseCodes)
//            
//            return emptyResponseAllowed
//                ? .success(())
//                : .failure(AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength))
//        }
//
//        do {
//            try validator.validate(statusCode: response.statusCode, data: data)
//            return .success(())
//        } catch let error {
//            return .failure(error)
//        }
//    }
//    
//    /// Determines whether the `request` allows empty response bodies, if `request` exists.
//    ///
//    ///- Parameters:
//    ///   - request: `URLRequest` to evaluate.
//    ///   - emptyRequestMethods: The HTTP methods that indicate an empty response.
//    ///
//    /// - Returns: `Bool` representing the outcome of the evaluation, or `nil` if `request` was `nil`.
//    private func requestAllowsEmptyResponseData(_ request: URLRequest?, emptyRequestMethods: Set<HTTPMethod>) -> Bool {
//        guard let httpMethodString = request?.httpMethod else { return false }
//
//        let httpMethod = HTTPMethod(rawValue: httpMethodString)
//        return emptyRequestMethods.contains(httpMethod)
//    }
//
//    /// Determines whether the `response` allows empty response bodies, if `response` exists.
//    ///
//    ///- Parameters:
//    ///   - request: `HTTPURLResponse` to evaluate.
//    ///   - emptyRequestMethods: The HTTP status codes that indicate an empty response.
//    ///
//    /// - Returns: `Bool` representing the outcome of the evaluation, or `nil` if `response` was `nil`.
//    private func responseAllowsEmptyResponseData(_ response: HTTPURLResponse, emptyResponseCodes: Set<Int>) -> Bool {
//        emptyResponseCodes.contains(response.statusCode)
//    }
//
//}
//