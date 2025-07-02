//
//  PrintNetworkLogger.swift
//  GoodNetworking
//
//  Created by Filip Šašala on 02/07/2025.
//

public struct PrintNetworkLogger: NetworkLogger {

    public init() {}

    nonisolated public func logNetworkEvent(
        message: Any,
        level: LogLevel,
        file: String,
        line: Int
    ) {
        print(message)
    }

}
