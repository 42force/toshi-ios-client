// Copyright (c) 2017 Token Browser, Inc
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
import SweetUIKit

open class SettingsController: UIViewController {

    enum SettingsSection: Int {
        case profile
        case balance
        case security
        case settings

        var items: [SettingsItem] {
            switch self {
            case .profile:
                return [.profile, .qrCode]
            case .balance:
                return [.balance]
            case .security:
                return [.security]
            case .settings:
                #if DEBUG
                    return [.advanced, .signOut]
                #else
                    return [.signOut]
                #endif
            }
        }

        var headerTitle: String? {
            switch self {
            case .profile:
                return Localized("Profile")
            case .balance:
                return Localized("Balance")
            case .security:
                return Localized("Security")
            case .settings:
                #if DEBUG
                    return Localized("Settings")
                #else
                    return nil
                #endif
            }
        }

        var footerTitle: String? {
            switch self {
            case .settings:
                let info = Bundle.main.infoDictionary!
                let version = info["CFBundleShortVersionString"]
                let buildNumber = info["CFBundleVersion"]

                return "App version: \(version ?? "").\(buildNumber ?? "")"
            default:
                return nil
            }
        }
    }

    enum SettingsItem: Int {
        case profile, qrCode, balance, security, advanced, signOut
    }

    fileprivate var ethereumAPIClient: EthereumAPIClient {
        return EthereumAPIClient.shared
    }

    fileprivate var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private var isAccountSecured: Bool {
        return TokenUser.current?.verified ?? false
    }

    fileprivate let sections: [SettingsSection] = [.profile, .balance, .security, .settings]

    fileprivate lazy var tableView: UITableView = {

        let view = UITableView(frame: self.view.frame, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsSelection = true
        view.estimatedRowHeight = 64.0
        view.dataSource = self
        view.delegate = self
        view.tableFooterView = UIView()

        view.register(UITableViewCell.self)

        return view
    }()

    fileprivate var balance: NSDecimalNumber? {
        didSet {
            self.tableView.reloadData()
        }
    }

    static func instantiateFromNib() -> SettingsController {
        guard let settingsController = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as? SettingsController else { fatalError("Storyboard named 'Settings' should be provided in application") }
        
        return  settingsController
    }

    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        title = Localized("Me")

        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.backgroundColor = Theme.settingsBackgroundColor

        tableView.registerNib(SettingsProfileCell.self)

        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .currentUserUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleBalanceUpdate(notification:)), name: .ethereumBalanceUpdateNotification, object: nil)

        self.fetchAndUpdateBalance()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        IDAPIClient.shared.updateContact(with: Cereal.shared.address)
    }

    @objc private func updateUI() {
        self.tableView.reloadData()
    }

    @objc private func handleBalanceUpdate(notification: Notification) {
        guard notification.name == .ethereumBalanceUpdateNotification, let balance = notification.object as? NSDecimalNumber else { return }
        self.balance = balance
    }

    fileprivate func fetchAndUpdateBalance() {
        self.ethereumAPIClient.getBalance(address: Cereal.shared.paymentAddress) { [weak self] balance, error in
            if let error = error {
                let alertController = UIAlertController.errorAlert(error as NSError)
                Navigator.presentModally(alertController)
            } else {
                self?.balance = balance
            }
        }
    }

    fileprivate func handleSignOut() {
        guard let currentUser = TokenUser.current else {
            let alert = UIAlertController(title: "No user found!", message: "This is an error. Please report this.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                fatalError()
            }))
            Navigator.presentModally(alert)

            return
        }

        let alert = self.alertController(balance: currentUser.balance)
        // We dispatch it back to the main thread here, even tho we are already inside the main thread
        // to avoid some weird issue where the alert controller will take seconds to present, instead of being instant.
        DispatchQueue.main.async {
            Navigator.presentModally(alert)
        }
    }

    func alertController(balance: NSDecimalNumber) -> UIAlertController {
        var alert: UIAlertController

        if self.isAccountSecured {
            alert = UIAlertController(title: "Have you secured your backup phrase?", message: "Without this you will not be able to recover your account or sign back in.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Sign out", style: .destructive) { _ in
                (UIApplication.shared.delegate as? AppDelegate)?.signOutUser()
            })
        } else if balance == .zero {
            alert = UIAlertController(title: "Are you sure you want to sign out?", message: "Since you have no funds and did not secure your account, it will be deleted.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                (UIApplication.shared.delegate as? AppDelegate)?.signOutUser()
            })
        } else {
            alert = UIAlertController(title: "Sign out cancelled", message: "You need to complete at least one of the security steps to sign out.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
        }

        alert.view.tintColor = Theme.tintColor

        return alert
    }

    fileprivate func setupProfileCell(_ cell: UITableViewCell) {
        guard let cell = cell as? SettingsProfileCell else { return }

        cell.displayNameLabel.text = TokenUser.current?.name
        cell.usernameLabel.text = TokenUser.current?.displayUsername

        guard let avatarPath = TokenUser.current?.avatarPath as String? else { return }
        AvatarManager.shared.avatar(for: avatarPath) { image, _ in
            cell.avatarImageView.image = image
        }
    }

    fileprivate func pushViewController(_ storyboardName: String) {
        guard let storyboard = UIStoryboard(name: storyboardName, bundle: nil) as UIStoryboard? else { return }
        guard let controller = storyboard.instantiateInitialViewController() else { return }

        self.navigationController?.pushViewController(controller, animated: true)
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 2 {
            let view = SettingsSectionHeader(title: "Security", error: "Your account is at risk")
            view.setErrorHidden(self.isAccountSecured, animated: false)

            return view
        }

        return nil
    }
}

extension SettingsController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell

        let section = sections[indexPath.section]
        let item = section.items[indexPath.row]

        switch item {
        case .profile:
            cell = tableView.dequeue(SettingsProfileCell.self, for: indexPath)
        default:
            cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        }

        switch item {
        case .profile:
            setupProfileCell(cell)
        case .qrCode:
            cell.textLabel?.text = Localized("My QR Code")
            cell.textLabel?.textColor = Theme.darkTextColor
            cell.accessoryType = .disclosureIndicator
        case .balance:
            let balance = self.balance ?? .zero

            let attributes = cell.textLabel?.attributedText?.attributes(at: 0, effectiveRange: nil)
            let balanceString = EthereumConverter.balanceSparseAttributedString(forWei: balance, exchangeRate: EthereumAPIClient.shared.exchangeRate, width: UIScreen.main.bounds.width - 50, attributes: attributes)

            cell.textLabel?.attributedText = balanceString

            cell.accessoryType = .disclosureIndicator
        case .security:
            cell.textLabel?.text = Localized("Store backup phrase")
            cell.textLabel?.textColor = Theme.darkTextColor
            cell.accessoryType = .disclosureIndicator
        case .advanced:
            cell.textLabel?.text = Localized("Advanced")
            cell.textLabel?.textColor = Theme.darkTextColor
            cell.accessoryType = .disclosureIndicator
        case .signOut:
            cell.textLabel?.text = Localized("Sign out")
            cell.textLabel?.textColor = Theme.errorColor
            cell.accessoryType = .none
        }

        return cell
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = sections[section]
        return sectionInfo.items.count
    }
}

extension SettingsController: UITableViewDelegate {

    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionInfo = sections[indexPath.section]
        let item = sectionInfo.items[indexPath.row]

        switch item {
        case .profile:
            self.navigationController?.pushViewController(ProfileController(), animated: true)
        case .qrCode:
            guard let current = TokenUser.current else { return }
            let qrCodeController = QRCodeController(for: current.displayUsername, name: current.name)

            self.navigationController?.pushViewController(qrCodeController, animated: true)
        case .balance:
            let controller = BalanceController()
            if let balance = balance {
                controller.balance = balance
            }
            self.navigationController?.pushViewController(controller, animated: true)
        case .security:
            self.navigationController?.pushViewController(BackupPhraseEnableController(), animated: true)
        case .advanced:
            self.pushViewController("AdvancedSettings")
        case .signOut:
            self.handleSignOut()
        }
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = sections[section]
        return sectionInfo.headerTitle
    }

    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionInfo = sections[section]
        return sectionInfo.footerTitle
    }
}
