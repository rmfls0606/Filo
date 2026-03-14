//
//  SettingsViewController.swift
//  Filo
//
//  Created by Codex on 3/12/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

private enum SettingsItem {
    case screenLock(isEnabled: Bool)
}

private enum ScreenLockItem {
    case lock(isOn: Bool)
    case biometric(isOn: Bool, isAvailable: Bool)
    case changePasscode
}

final class SettingsViewController: BaseViewController {
    private let tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = GrayStyle.gray100.color
        view.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return view
    }()

    private let disposeBag = DisposeBag()
    private let settingsRelay = BehaviorRelay<ChatLockSettings>(value: ChatLockSettingsStore.shared.settings())

    override func configureHierarchy() {
        view.addSubview(tableView)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "설정"
        tableView.sectionHeaderTopPadding = 0
    }

    override func configureBind() {
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        rx.methodInvoked(#selector(UIViewController.viewWillAppear(_:)))
            .bind(with: self) { owner, _ in
                owner.refreshSettings()
            }
            .disposed(by: disposeBag)

        settingsRelay
            .map { [SettingsItem.screenLock(isEnabled: $0.isLockEnabled)] }
            .bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { _, item, cell in
                var config = UIListContentConfiguration.valueCell()
                switch item {
                case .screenLock(let isEnabled):
                    config.text = "화면 잠금"
                    config.secondaryText = isEnabled ? "켜짐" : "꺼짐"
                }
                config.textProperties.color = GrayStyle.gray30.color ?? .label
                config.textProperties.font = UIFont.Pretendard.body1 ?? .systemFont(ofSize: 16, weight: .medium)
                config.secondaryTextProperties.color = GrayStyle.gray60.color ?? .secondaryLabel
                config.secondaryTextProperties.font = UIFont.Pretendard.body2 ?? .systemFont(ofSize: 14)
                cell.contentConfiguration = config
                cell.backgroundColor = GrayStyle.gray100.color
                cell.accessoryType = .none
                cell.selectionStyle = .default
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(SettingsItem.self)
            .bind(with: self) { owner, item in
                owner.tableView.deselectRow(at: owner.tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0), animated: true)
                switch item {
                case .screenLock(let isEnabled):
                    owner.openScreenLockSettings(isLockEnabled: isEnabled)
                }
            }
            .disposed(by: disposeBag)
    }

    private func refreshSettings() {
        settingsRelay.accept(ChatLockSettingsStore.shared.settings())
    }

    private func openScreenLockSettings(isLockEnabled: Bool) {
        if isLockEnabled {
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await DeviceSecurityAuthenticator.shared.authenticateWithAppPasscode(from: self)
                    navigationController?.pushViewController(ScreenLockSettingsViewController(), animated: true)
                } catch let error as DeviceSecurityAuthError where error == .canceled {
                    return
                } catch let error as DeviceSecurityAuthError {
                    showAlert(title: "화면 잠금", message: error.errorDescription)
                } catch {
                    showAlert(title: "화면 잠금", message: DeviceSecurityAuthError.failed.errorDescription)
                }
            }
            return
        }

        navigationController?.pushViewController(ScreenLockSettingsViewController(), animated: true)
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView(frame: .zero)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView(frame: .zero)
    }
}

final class ScreenLockSettingsViewController: BaseViewController {
    private let tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.backgroundColor = GrayStyle.gray100.color
        view.register(SettingsSwitchCell.self, forCellReuseIdentifier: SettingsSwitchCell.identifier)
        view.register(UITableViewCell.self, forCellReuseIdentifier: "valueCell")
        return view
    }()

    private let store = ChatLockSettingsStore.shared
    private let disposeBag = DisposeBag()
    private let settingsRelay = BehaviorRelay<ChatLockSettings>(value: ChatLockSettingsStore.shared.settings())

    override func configureHierarchy() {
        view.addSubview(tableView)
    }

    override func configureLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func configureView() {
        view.backgroundColor = GrayStyle.gray100.color
        navigationItem.title = "화면 잠금"
        tableView.sectionHeaderTopPadding = 0
    }

    override func configureBind() {
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)

        settingsRelay
            .map { [weak self] settings -> [ScreenLockItem] in
                self?.makeItems(from: settings) ?? []
            }
            .bind(to: tableView.rx.items) { [weak self] tableView, row, item in
                guard let self else { return UITableViewCell() }
                let indexPath = IndexPath(row: row, section: 0)
                switch item {
                case .lock(let isOn):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: SettingsSwitchCell.identifier,
                        for: indexPath
                    ) as? SettingsSwitchCell else {
                        return UITableViewCell()
                    }
                    cell.configure(title: "화면 잠금", isOn: isOn)
                    cell.onToggle = { [weak self] value in
                        self?.handleLockToggle(isOn: value)
                    }
                    return cell
                case .biometric(let isOn, let isAvailable):
                    guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: SettingsSwitchCell.identifier,
                        for: indexPath
                    ) as? SettingsSwitchCell else {
                        return UITableViewCell()
                    }
                    let title = isAvailable ? "생체 인증" : "생체 인증(사용 불가)"
                    cell.configure(title: title, isOn: isOn, isEnabled: isAvailable)
                    cell.onToggle = { [weak self] value in
                        self?.handleBiometricToggle(isOn: value)
                    }
                    return cell
                case .changePasscode:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "valueCell", for: indexPath)
                    var config = UIListContentConfiguration.valueCell()
                    config.text = "암호 변경"
                    config.textProperties.color = GrayStyle.gray30.color ?? .label
                    config.textProperties.font = UIFont.Pretendard.body1 ?? .systemFont(ofSize: 16, weight: .medium)
                    cell.contentConfiguration = config
                    cell.backgroundColor = GrayStyle.gray100.color
                    cell.accessoryType = .disclosureIndicator
                    return cell
                }
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(ScreenLockItem.self)
            .bind(with: self) { owner, item in
                owner.tableView.deselectRow(at: owner.tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0), animated: true)
                guard case .changePasscode = item else { return }
                owner.changePasscode()
            }
            .disposed(by: disposeBag)
    }

    private func makeItems(from settings: ChatLockSettings) -> [ScreenLockItem] {
        if settings.isLockEnabled {
            return [
                .lock(isOn: settings.isLockEnabled),
                .biometric(isOn: settings.isBiometricEnabled, isAvailable: store.canUseBiometrics()),
                .changePasscode
            ]
        }
        return [.lock(isOn: settings.isLockEnabled)]
    }

    private func refreshSettings() {
        settingsRelay.accept(store.settings())
    }

    private func handleLockToggle(isOn: Bool) {
        let settings = settingsRelay.value
        if isOn {
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    if !settings.hasPasscode {
                        try await configureInitialPasscode()
                    }
                    store.setLockEnabled(true)
                    store.setBiometricEnabled(store.canUseBiometrics())
                    refreshSettings()
                } catch let error as DeviceSecurityAuthError where error == .unavailable {
                    showAlert(title: "화면 잠금", message: error.errorDescription)
                    refreshSettings()
                } catch {
                    refreshSettings()
                }
            }
            return
        }

        store.setLockEnabled(false)
        refreshSettings()
    }

    private func handleBiometricToggle(isOn: Bool) {
        guard settingsRelay.value.isLockEnabled else {
            refreshSettings()
            return
        }

        if isOn && !store.canUseBiometrics() {
            showAlert(title: "생체 인증", message: "Face ID 또는 Touch ID를 사용할 수 없습니다.")
            refreshSettings()
            return
        }

        store.setBiometricEnabled(isOn)
        refreshSettings()
    }

    private func configureInitialPasscode() async throws {
        let first = try await promptForPasscode(title: "암호 설정", message: "채팅 잠금에 사용할 4자리 숫자 암호를 입력해주세요.")
        let second = try await promptForPasscode(title: "암호 확인", message: "같은 암호를 한 번 더 입력해주세요.")
        guard first == second else {
            await presentMessageAlert(title: "암호 설정", message: "암호가 일치하지 않습니다. 다시 시도해주세요.")
            throw DeviceSecurityAuthError.failed
        }
        try store.updatePasscode(first)
    }

    private func changePasscode() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let current = try await promptForPasscode(title: "현재 암호", message: "현재 4자리 숫자 암호를 입력해주세요.")
                guard store.verifyPasscode(current) else {
                    await presentMessageAlert(title: "암호 변경", message: "현재 암호가 올바르지 않습니다.")
                    return
                }
                let next = try await promptForPasscode(title: "새 암호", message: "새 4자리 숫자 암호를 입력해주세요.")
                let confirm = try await promptForPasscode(title: "새 암호 확인", message: "같은 암호를 한 번 더 입력해주세요.")
                guard next == confirm else {
                    await presentMessageAlert(title: "암호 변경", message: "새 암호가 일치하지 않습니다.")
                    return
                }
                try store.updatePasscode(next)
                await presentMessageAlert(title: "암호 변경", message: "암호가 변경되었습니다.")
                refreshSettings()
            } catch {
            }
        }
    }

    private func promptForPasscode(title: String, message: String) async throws -> String {
        guard let value = await presentTextInputAlert(
            title: title,
            message: message,
            placeholder: "4자리 숫자",
            isSecure: true,
            keyboardType: .numberPad,
            confirmTitle: "확인"
        ) else {
            throw DeviceSecurityAuthError.canceled
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 4,
              CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: trimmed)) else {
            await presentMessageAlert(title: title, message: "4자리 숫자만 입력할 수 있습니다.")
            throw DeviceSecurityAuthError.failed
        }
        return trimmed
    }
}

extension ScreenLockSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView(frame: .zero)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView(frame: .zero)
    }
}

final class SettingsSwitchCell: BaseTableViewCell {
    var onToggle: ((Bool) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .Pretendard.body1
        label.textColor = GrayStyle.gray30.color
        return label
    }()

    private let toggleSwitch: UISwitch = {
        let view = UISwitch()
        view.onTintColor = Brand.brightTurquoise.color
        return view
    }()

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(toggleSwitch)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(toggleSwitch.snp.leading).offset(-12)
        }

        toggleSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    override func configureView() {
        backgroundColor = GrayStyle.gray100.color
        selectionStyle = .none
        toggleSwitch.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    }

    func configure(title: String, isOn: Bool, isEnabled: Bool = true) {
        titleLabel.text = title
        toggleSwitch.isOn = isOn
        toggleSwitch.isEnabled = isEnabled
        titleLabel.textColor = isEnabled ? (GrayStyle.gray30.color ?? .label) : (GrayStyle.gray60.color ?? .secondaryLabel)
    }

    @objc private func toggleChanged() {
        onToggle?(toggleSwitch.isOn)
    }
}
