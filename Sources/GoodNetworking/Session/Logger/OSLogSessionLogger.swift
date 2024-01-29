//
//  OSLogSessionLogger.swift
//
//
//  Created by Matus Klasovity on 30/01/2024.
//

import Foundation
import OSLog

@available(iOS 14, *)
final class OSLogSessionLogger: SessionLogger {

    private let logger = Logger(subsystem: "OSLogSessionLogger", category: "Networking")

    func log(level: OSLogType, message: String) {
        logger.log(level: level, "\(message)")
    }

}
