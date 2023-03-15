//
//  DateDecodingTest.swift
//  
//
//  Created by Matúš Klasovitý on 14/03/2023.
//

import Foundation
import GoodNetworking
import XCTest
import Mockable

final class DateDecodingTest: XCTestCase {
        
    struct IsoDateWrapper: Decodable, WithCustomDecoder {
        
        static var decoder: JSONDecoder {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            return decoder
        }
        
        let date: Date
        
    }
    
    struct MilisecondsDateWrapper: Decodable, WithCustomDecoder {
        
        let date: Date
        
        static var decoder: JSONDecoder {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            
            return decoder
        }
        
    }
    

    func testDecodableWithCustomDecoder() {
        guard let path = Bundle.module.url(forResource: "IsoDate", withExtension: "json") else {
            XCTAssert(false)
            return
        }
        
        guard let milisecondsPath = Bundle.module.url(forResource: "MilisecondsDate", withExtension: "json") else {
            XCTAssert(false)
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        

        do {
            let rawData = try Data(contentsOf: path)
            let data = try IsoDateWrapper.decode(data: rawData)
            XCTAssert(dateFormatter.string(from: data.date) == "19.11.2022")
        } catch {
            print(error)
            XCTAssert(false)
        }

        do {
            let rawData = try Data(contentsOf: milisecondsPath)
            let data = try MilisecondsDateWrapper.decode(data: rawData)
            XCTAssert(dateFormatter.string(from: data.date) == "14.03.2023")
            
        } catch {
            print(error)
            XCTAssert(false)
        }


        XCTAssert(true)
    }

}
