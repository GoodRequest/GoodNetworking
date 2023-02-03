// 
//  AboutViewController.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import UIKit
import Combine

final class HomeViewController: BaseViewController<HomeViewModel>  {

    // MARK: - Constants

    private let heroView: HeroView = {
        let heroView = HeroView()
        heroView.translatesAutoresizingMaskIntoConstraints = false

        return heroView
    }()

    private let fetchHeroButton: ActionButton = {
        let button = ActionButton()
        button.setTitle(Constants.Texts.Home.fetchHero, for: .normal)
        button.updateActivityIndicatorColor(color: .black)

        return button
    }()

    private let aboutAppButton: ActionButton = {
        let button = ActionButton()
        button.setTitle(Constants.Texts.Home.aboutApp, for: .normal)

        return button
    }()

    private let bottomStackView: UIStackView = {
        let bottomStackView = UIStackView()
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomStackView.axis = .vertical
        bottomStackView.spacing = 16

        return bottomStackView
    }()

}

// MARK: - Lifecycle

extension HomeViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()

        bindState(reactor: viewModel)
        bindActions(reactor: viewModel)
    }

}

// MARK: - Combine

private extension HomeViewController {

    func bindState(reactor: HomeViewModel) {
        fetchHeroButton.publisher(for: .touchUpInside)
            .sink { reactor.fetchHero() }
            .store(in: &cancellables)

        aboutAppButton.publisher(for: .touchUpInside)
            .sink { reactor.goToAbout() }
            .store(in: &cancellables)
    }

    func bindActions(reactor: HomeViewModel) {
        reactor.heroResult
            .sink { [weak self] in self?.handle(heroResult: $0) }
            .store(in: &cancellables)
    }

}

// MARK: - Setup

private extension HomeViewController {

    func setupLayout() {
        view.backgroundColor = UIColor(named: "background")
        title = Constants.Texts.Home.title

        [fetchHeroButton, aboutAppButton].forEach { bottomStackView.addArrangedSubview($0) }
        [bottomStackView, heroView].forEach {view.addSubview($0)}

        setupConstraints()
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            heroView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            heroView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            heroView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            bottomStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -32),
            bottomStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            bottomStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

}

// MARK: - Handle result

private extension HomeViewController {

    func handle(heroResult: HomeViewModel.HeroFetchingResultState) {
        fetchHeroButton.isLoading = false

        switch heroResult {
        case .idle:
            heroView.setupIdle()

        case .loading:
            fetchHeroButton.isLoading = true

        case .success(let hero):
            heroView.animate(hero: hero, animate: .fromRight)

        case .error(let error):
            let alert: UIAlertController = {
                let alert = UIAlertController(
                    title: nil,
                    message: error.localizedDescription,
                    preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Cancel", style: .destructive))

                return alert
            }()

            present(alert, animated: true)
        }
    }

}
