//
//  TestingLogger.swift
//  GoodNetworking
//
//  Created by Andrej Jasso on 05/02/2025.
//

import GoodLogger

final class TestingLogger: GoodLogger {

    nonisolated(unsafe) var messages = [String]()

    nonisolated func log(
        message: Any,
        level: LogLevel?,
        privacy: PrivacyType?,
        fileName: String?,
        lineNumber: Int?
    ) {
        print(message)
        messages.append(String(describing: message))
    }

}
