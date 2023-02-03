//
//  RequestManagerType.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import Foundation

protocol RequestManagerType: AnyObject {

    func fetchHero(heroId: Int) -> RequestPublisher<HeroResponse>
    
}
