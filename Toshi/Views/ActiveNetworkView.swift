// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit
import TinyConstraints
import SweetUIKit

class ActiveNetworkView: UIView {
    static let height: CGFloat = 32.0
    private let margin: CGFloat = 6.0

    var heightConstraint: NSLayoutConstraint?

    private var isDefaultNetworkActive = NetworkSwitcher.shared.isDefaultNetworkActive

    private lazy var textLabel: UILabel = {
        let textLabel = UILabel(withAutoLayout: true)

        textLabel.font = Theme.regular(size: 14)
        textLabel.textColor = Theme.lightTextColor
        textLabel.textAlignment = .center

        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = 0.8

        return textLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }

    private func setupView() {
        backgroundColor = Theme.darkTextColor

        addSubview(textLabel)
        textLabel.edges(to: self, insets: UIEdgeInsets(top: margin, left: margin, bottom: -margin, right: -margin), priority: .defaultHigh)

        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        updateTitle()

        heightConstraint?.isActive = true
    }

    func updateTitle() {
        textLabel.text = String(format: Localized.active_network_format, NetworkSwitcher.shared.activeNetworkLabel)
    }

    var isAtZeroHeight: Bool {
        return heightConstraint?.constant == 0
    }

    var isAtFullHeight: Bool {
        return heightConstraint?.constant == ActiveNetworkView.height
    }

    func setZeroHeight() {
        heightConstraint?.constant = 0
    }

    func setFullHeight() {
        heightConstraint?.constant = ActiveNetworkView.height
    }

    /// For use when you're displaying this on something with a dark background and need more contrast
    func useLighterBackground() {
        backgroundColor = Theme.mediumTextColor
    }
}
