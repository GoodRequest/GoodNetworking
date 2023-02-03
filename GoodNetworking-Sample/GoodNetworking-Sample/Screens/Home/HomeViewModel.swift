// 
//  AboutViewModel.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import Combine
import Alamofire

final class HomeViewModel {

    // MARK: - TypeAliases

    typealias DI = WithRequestManager

    // MARK: - Enums

    enum HeroFetchingResultState {

        case idle
        case loading
        case success(HeroResponse)
        case error(AFError)

    }

    // MARK: - Constants

    private let di: DI
    private let coordinator: Coordinator<AppStep>

    // MARK: Combine

    let heroResult = CurrentValueSubject<HeroFetchingResultState, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(di: DI, coordinator: Coordinator<AppStep>) {
        self.coordinator = coordinator
        self.di = di
    }

}

// MARK: - Public

extension HomeViewModel {

    func fetchHero() {
        di.requestManager.fetchHero(heroId: Int.random(in: Constants.Hero.range))
            .map{ HeroFetchingResultState.success($0) }
            .catch { Just(HeroFetchingResultState.error($0)) }
            .prepend(HeroFetchingResultState.loading)
            .eraseToAnyPublisher()
            .sink { [weak self] result in self?.heroResult.send(result) }
            .store(in: &cancellables)
    }

    func goToAbout() {
        coordinator.navigate(to: .home(.goToAbout))
    }

}
