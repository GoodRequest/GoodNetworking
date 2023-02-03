//
//  UINavigationBarExtensions.swift
//  GoodNetworking-Sample
//
//  Created by GoodRequest on 09/02/2023.
//

import UIKit

extension UINavigationBar {

    static func setAppearance() {
        let appearance = self.appearance()
        appearance.prefersLargeTitles = true
        appearance.tintColor = .black
    }

}
