//
//  SampleLogger.swift
//  GoodNetworking-Sample
//
//  Created by Matus Klasovity on 09/06/2025.
//

import Foundation
import GoodNetworking

struct SampleLogger: NetworkLogger {
    
    func logNetworkEvent(message: Any, level: LogLevel, file: String, line: Int) {
        switch level {
        case .debug:
            print("[DEBUG] \(file):\(line) - \(message)")
        case .info:
            print("[INFO] \(file):\(line) - \(message)")
        case .warning:
            print("[WARNING] \(file):\(line) - \(message)")
        case .error:
            print("[ERROR] \(file):\(line) - \(message)")
        }
    }
    
}
