//
//  HeroView.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import UIKit

final class HeroView: UIView {

    // MARK: - Constants

    let verticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .leading

        return verticalStackView
    }()

    private let nameLabel: MultiLineLabel = {
        let nameLabel = MultiLineLabel.create(font: .systemFont(ofSize: 40, weight: .black))
        nameLabel.textColor = UIColor(named: "primary")

        return nameLabel
    }()

    private let massLabel: MultiLineLabel = {
        let massLabel = MultiLineLabel.create(font: .systemFont(ofSize: 34, weight: .semibold))
        massLabel.textColor = UIColor(named: "secondary")

        return massLabel
    }()

    private let heightLabel: MultiLineLabel = {
        let heightLabel = MultiLineLabel.create(font: .systemFont(ofSize: 24, weight: .medium))
        heightLabel.textColor = UIColor(named: "tertiary")

        return heightLabel
    }()

    private let genderLabel: MultiLineLabel = {
        let genderLabel = MultiLineLabel.create(font: .systemFont(ofSize: 16, weight: .regular))
        genderLabel.textColor = UIColor(named: "tertiary")

        return genderLabel
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Public

extension HeroView {

    func animate(hero: HeroResponse, animate direction: CATransitionSubtype? = nil) {
        guard let direction = direction else { return setup(with: hero) }

        let transition: CATransition = {
            let transition = CATransition()
            transition.type = .push
            transition.subtype = direction
            transition.duration = 0.3
            transition.timingFunction = .init(name: .linear)
            transition.fillMode = .removed

            return transition
        }()

        layer.add(transition, forKey: "slideTransition")
        setup(with: hero)
    }

    func setupIdle() {
        nameLabel.text = Constants.Texts.Hero.placholder
    }

}

// MARK: - Private

private extension HeroView {

    func setup(with hero: HeroResponse) {
        nameLabel.text = hero.name
        massLabel.text = hero.massText
        heightLabel.text = hero.heightText
        genderLabel.text = hero.genderText
    }

    func setupLayout() {
        [nameLabel, massLabel, heightLabel, genderLabel].forEach {
            verticalStackView.addArrangedSubview($0)
        }

        addSubview(verticalStackView)
        setupConstraints()
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            verticalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalStackView.topAnchor.constraint(equalTo: topAnchor),
            verticalStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

}
