//
//  SessionLogger.swift
//
//
//  Created by Matus Klasovity on 30/01/2024.
//

import Foundation
import OSLog

public protocol SessionLogger {

    func log(level: OSLogType, message: String)

}
