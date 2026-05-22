import Cocoa
import ClaudeStatusCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum MenuItemTag: Int {
        case status = 100
        case checkedAt = 101
    }

    private let client = StatusPageClient()
    private var statusItem: NSStatusItem!
    private var refreshTimer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var currentStatus = ClaudeServiceStatus(
        severity: .unknown,
        headline: "Checking Claude status",
        detail: "Checking the Claude status page...",
        pageUpdatedAt: nil,
        checkedAt: Date(),
        sourcePageURL: StatusPageClient.defaultStatusPageURL,
        affectedComponents: [],
        activeIncidents: []
    )

    private var showStatusText: Bool {
        get { UserDefaults.standard.bool(forKey: "showStatusText") }
        set { UserDefaults.standard.set(newValue, forKey: "showStatusText") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        scheduleRefreshTimer()
        refreshStatus()
    }

    func applicationWillTerminate(_ notification: Notification) {
        refreshTimer?.invalidate()
        refreshTask?.cancel()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        rebuildMenu()
        applyStatusToMenuBar()
    }

    private func scheduleRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshStatus()
            }
        }
        refreshTimer?.tolerance = 10
    }

    private func refreshStatus() {
        refreshTask?.cancel()
        refreshTask = Task { [client] in
            do {
                let status = try await client.fetchStatus()
                await MainActor.run {
                    self.currentStatus = status
                    self.applyStatusToMenuBar()
                    self.rebuildMenu()
                }
            } catch {
                let status = ClaudeServiceStatus.unavailable(error: error)
                await MainActor.run {
                    self.currentStatus = status
                    self.applyStatusToMenuBar()
                    self.rebuildMenu()
                }
            }
        }
    }

    private func applyStatusToMenuBar() {
        guard let button = statusItem.button else { return }

        button.image = StatusIconRenderer.image(for: currentStatus.severity)
        button.imagePosition = .imageLeft
        button.title = showStatusText ? " \(currentStatus.severity.shortLabel)" : ""
        button.toolTip = currentStatus.tooltip
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let statusItem = disabledItem(title: "\(currentStatus.severity.displayName): \(currentStatus.detail)")
        statusItem.tag = MenuItemTag.status.rawValue
        menu.addItem(statusItem)

        let checkedItem = disabledItem(title: "Checked: \(format(date: currentStatus.checkedAt))")
        checkedItem.tag = MenuItemTag.checkedAt.rawValue
        menu.addItem(checkedItem)

        if let pageUpdatedAt = currentStatus.pageUpdatedAt {
            menu.addItem(disabledItem(title: "Status page updated: \(format(date: pageUpdatedAt))"))
        }

        addComponentItems(to: menu)
        addIncidentItems(to: menu)

        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Refresh Now", action: #selector(refreshNow), keyEquivalent: "r"))

        let textToggle = actionItem(title: "Show Status Text", action: #selector(toggleStatusText), keyEquivalent: "")
        textToggle.state = showStatusText ? .on : .off
        menu.addItem(textToggle)

        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Open Claude Status Page", action: #selector(openStatusPage), keyEquivalent: "o"))
        menu.addItem(.separator())
        menu.addItem(actionItem(title: "Quit ClaudeStatus", action: #selector(quit), keyEquivalent: "q"))

        self.statusItem.menu = menu
    }

    private func addComponentItems(to menu: NSMenu) {
        menu.addItem(.separator())

        if currentStatus.affectedComponents.isEmpty {
            menu.addItem(disabledItem(title: "All monitored components operational"))
            return
        }

        menu.addItem(disabledItem(title: "Affected Components"))
        for component in currentStatus.affectedComponents {
            let status = StatusEvaluator.humanisedComponentStatus(component.status)
            menu.addItem(disabledItem(title: "\(component.name): \(status)"))
        }
    }

    private func addIncidentItems(to menu: NSMenu) {
        guard !currentStatus.activeIncidents.isEmpty else { return }

        menu.addItem(.separator())
        menu.addItem(disabledItem(title: "Active Incidents"))

        for incident in currentStatus.activeIncidents {
            let title = "\(incident.name): \(StatusEvaluator.humanisedComponentStatus(incident.status))"
            let item = actionItem(title: title, action: #selector(openIncident(_:)), keyEquivalent: "")
            item.representedObject = incident.shortlink
            item.isEnabled = incident.shortlink != nil
            menu.addItem(item)
        }
    }

    private func actionItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func disabledItem(title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    func menuWillOpen(_ menu: NSMenu) {
        if let statusItem = menu.item(withTag: MenuItemTag.status.rawValue) {
            statusItem.title = "\(currentStatus.severity.displayName): \(currentStatus.detail)"
        }

        if let checkedItem = menu.item(withTag: MenuItemTag.checkedAt.rawValue) {
            checkedItem.title = "Checked: \(format(date: currentStatus.checkedAt))"
        }
    }

    @objc private func refreshNow() {
        refreshStatus()
    }

    @objc private func toggleStatusText() {
        showStatusText.toggle()
        applyStatusToMenuBar()
        rebuildMenu()
    }

    @objc private func openStatusPage() {
        NSWorkspace.shared.open(currentStatus.sourcePageURL)
    }

    @objc private func openIncident(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
