//
//  Goodify.swift
//  GoodNetworking
//
//  Created by Dominik Pethö on 4/30/19.
//

@preconcurrency import Alamofire
import Combine
import Foundation

public extension DataRequest {

    /// Creates a `DataResponse` with the specified success value.
    ///
    /// - Parameter value: The value to set as the success result.
    /// - Returns: A `DataResponse` object with the success value.
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

    /// Creates a `DataResponse` with the specified error.
    ///
    /// - Parameter error: The error to set as the failure result.
    /// - Returns: A `DataResponse` object with the failure error.
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
