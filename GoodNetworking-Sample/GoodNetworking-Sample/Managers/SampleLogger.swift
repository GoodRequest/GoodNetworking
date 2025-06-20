//
//  SampleLogger.swift
//  GoodNetworking-Sample
//
//  Created by Matus Klasovity on 09/06/2025.
//

import Foundation
import GoodNetworking

struct SampleLogger: NetworkLogger {
    
    func logNetworkEvent(message: Any, level: LogLevel, fileName: String, lineNumber: Int) {
        switch level {
        case .debug:
            print("[DEBUG] \(fileName):\(lineNumber) - \(message)")
        case .info:
            print("[INFO] \(fileName):\(lineNumber) - \(message)")
        case .warning:
            print("[WARNING] \(fileName):\(lineNumber) - \(message)")
        case .error:
            print("[ERROR] \(fileName):\(lineNumber) - \(message)")
        }
    }
    
}
