import AppKit

protocol StatusMenuDelegate: AnyObject {
    func statusMenu(_ menu: StatusMenu, didChangeEnabled isEnabled: Bool)
    func statusMenu(_ menu: StatusMenu, didChangeMiniHUD isEnabled: Bool)
    func statusMenu(_ menu: StatusMenu, didChangeLoginItem isEnabled: Bool)
    func statusMenuRequestedAbout(_ menu: StatusMenu)
    func statusMenuRequestedQuit(_ menu: StatusMenu)
}

final class StatusMenu: NSObject {
    struct Context {
        let isMasterEnabled: Bool
        let showMiniHUD: Bool
        let loginItemEnabled: Bool
        let isSwitchAvailable: Bool
        let isSecureInputActive: Bool
        let needsInputMonitoringPermission: Bool
        let needsAccessibilityPermission: Bool
        let currentSymbol: String
    }

    weak var delegate: StatusMenuDelegate?

    private let statusItem: NSStatusItem
    private let menu: NSMenu

    private let enableItem: NSMenuItem
    private let miniHUDItem: NSMenuItem
    private let loginItemItem: NSMenuItem
    private let aboutItem: NSMenuItem
    private let quitItem: NSMenuItem

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()

        enableItem = NSMenuItem(title: "활성화", action: #selector(toggleEnabled), keyEquivalent: "")
        miniHUDItem = NSMenuItem(title: "한/영 전환 미니 알림", action: #selector(toggleMiniHUD), keyEquivalent: "")
        loginItemItem = NSMenuItem(title: "로그인 시 자동 실행", action: #selector(toggleLoginItem), keyEquivalent: "")
        aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        quitItem = NSMenuItem(title: "Exit", action: #selector(quitApp), keyEquivalent: "")

        super.init()

        enableItem.target = self
        miniHUDItem.target = self
        loginItemItem.target = self
        aboutItem.target = self
        quitItem.target = self

        let separator = NSMenuItem.separator()

        menu.items = [
            enableItem,
            miniHUDItem,
            loginItemItem,
            separator,
            aboutItem,
            quitItem
        ]

        statusItem.menu = menu
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.image = StatusMenu.makeSymbolImage(text: "⇄")
        statusItem.button?.appearsDisabled = false
        statusItem.button?.toolTip = "Korean Shifter"
    }

    func update(context: Context) {
        enableItem.state = context.isMasterEnabled ? .on : .off
        miniHUDItem.state = context.showMiniHUD ? .on : .off
        loginItemItem.state = context.loginItemEnabled ? .on : .off

        let icon = StatusMenu.makeSymbolImage(text: context.currentSymbol)
        statusItem.button?.image = icon

        let tooltip: String
        if !context.isSwitchAvailable {
            tooltip = "ENG/KOR 입력 소스가 감지되지 않았습니다."
        } else if context.needsInputMonitoringPermission {
            tooltip = "Korean Shifter: 입력 모니터링 권한이 필요합니다."
        } else if context.needsAccessibilityPermission {
            tooltip = "Korean Shifter: 손쉬운사용 권한이 필요합니다."
        } else if context.isSecureInputActive {
            tooltip = "Korean Shifter: 보안 입력 중"
        } else {
            tooltip = "Korean Shifter"
        }
        statusItem.button?.toolTip = tooltip
        statusItem.button?.appearsDisabled = (
            !context.isMasterEnabled ||
            !context.isSwitchAvailable ||
            context.needsInputMonitoringPermission ||
            context.needsAccessibilityPermission ||
            context.isSecureInputActive
        )

        enableItem.isEnabled = true
        miniHUDItem.isEnabled = context.isMasterEnabled
    }

    private static func makeSymbolImage(text: String) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = NSRect(origin: .zero, size: size)
        NSColor.clear.setFill()
        NSBezierPath(rect: rect).fill()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: NSColor.labelColor
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textRect = attributed.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin])
        let origin = NSPoint(
            x: rect.midX - textRect.width / 2,
            y: rect.midY - textRect.height / 2
        )
        attributed.draw(at: origin)

        image.isTemplate = true
        return image
    }

    @objc private func toggleEnabled() {
        let newValue = enableItem.state != .on
        delegate?.statusMenu(self, didChangeEnabled: newValue)
    }

    @objc private func toggleMiniHUD() {
        let newValue = miniHUDItem.state != .on
        delegate?.statusMenu(self, didChangeMiniHUD: newValue)
    }

    @objc private func toggleLoginItem() {
        let newValue = loginItemItem.state != .on
        delegate?.statusMenu(self, didChangeLoginItem: newValue)
    }

    @objc private func showAbout() {
        delegate?.statusMenuRequestedAbout(self)
    }

    @objc private func quitApp() {
        delegate?.statusMenuRequestedQuit(self)
    }
}
