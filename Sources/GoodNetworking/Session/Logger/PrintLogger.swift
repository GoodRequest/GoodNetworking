//
//  PrintLogger.swift
//
//
//  Created by Matus Klasovity on 30/01/2024.
//

import Foundation
import OSLog

final class PrintLogger: SessionLogger {

    func log(level: OSLogType, message: String) {
        print(message)
    }

}
