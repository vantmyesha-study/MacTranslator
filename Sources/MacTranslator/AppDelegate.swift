import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotkeyManager: HotkeyManager!
    private var translationService: TranslationService!
    private var floatingPanel: TranslationPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        translationService = TranslationService()
        floatingPanel = TranslationPanel()
        hotkeyManager = HotkeyManager(onTrigger: { [weak self] in
            self?.handleTranslation()
        })

        setupStatusBar()
        hotkeyManager.register()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "character.book.closed",
                                   accessibilityDescription: "Translator")
        }

        let menu = NSMenu()

        let translateItem = NSMenuItem(title: "翻译选中文本 (⌥T)", action: #selector(triggerTranslation), keyEquivalent: "")
        translateItem.target = self
        menu.addItem(translateItem)

        menu.addItem(NSMenuItem.separator())

        // 设置 → 子菜单展开 API Key 输入
        let settingsItem = NSMenuItem(title: "设置", action: nil, keyEquivalent: "")
        let settingsSubmenu = NSMenu()

        let settingsView = MenuPanelView(service: translationService)
        let hostingView = NSHostingView(rootView: settingsView)
        let fitting = hostingView.fittingSize
        hostingView.frame = NSRect(x: 0, y: 0, width: fitting.width, height: fitting.height)

        let viewItem = NSMenuItem()
        viewItem.view = hostingView
        settingsSubmenu.addItem(viewItem)

        settingsItem.submenu = settingsSubmenu
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func triggerTranslation() {
        handleTranslation()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func handleTranslation() {
        let savedContents = NSPasteboard.general.pasteboardItems?.compactMap {
            $0.data(forType: .string)
        }

        NSPasteboard.general.clearContents()

        let src = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self else { return }
            let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            NSPasteboard.general.clearContents()
            if let saved = savedContents {
                for data in saved {
                    NSPasteboard.general.setData(data, forType: .string)
                }
            }

            guard !text.isEmpty else { return }

            let mouseLocation = NSEvent.mouseLocation
            self.floatingPanel.show(at: mouseLocation, sourceText: text, status: .loading)

            self.translationService.translate(text) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let translated):
                        self.floatingPanel.update(translated: translated, status: .success)
                    case .failure(let error):
                        self.floatingPanel.update(translated: error.localizedDescription, status: .error)
                    }
                }
            }
        }
    }
}
