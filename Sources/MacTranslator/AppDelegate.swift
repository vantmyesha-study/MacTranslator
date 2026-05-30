import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotkeyManager: HotkeyManager!
    private var translationService: TranslationService!
    private var floatingPanel: TranslationPanel!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        translationService = TranslationService()
        floatingPanel = TranslationPanel()
        hotkeyManager = HotkeyManager(onTrigger: { [weak self] in
            self?.handleTranslation()
        })

        setupStatusBar()
        hotkeyManager.register()

        if translationService.apiKey.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showSettings()
            }
        }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "character.book.closed",
                                   accessibilityDescription: "Translator")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "翻译选中文本 (⌥T)", action: #selector(triggerTranslation), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "设置…", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func triggerTranslation() {
        handleTranslation()
    }

    private func handleTranslation() {
        NSLog("[MacTranslator] hotkey triggered")
        let savedContents = NSPasteboard.general.pasteboardItems?.compactMap {
            $0.data(forType: .string)
        }

        let changeCount = NSPasteboard.general.changeCount
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

            // restore clipboard
            NSPasteboard.general.clearContents()
            if let saved = savedContents {
                for data in saved {
                    NSPasteboard.general.setData(data, forType: .string)
                }
            }

            NSLog("[MacTranslator] clipboard text: %@", text)
            guard !text.isEmpty else { NSLog("[MacTranslator] empty text, skipping"); return }

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

    @objc private func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "MacTranslator 设置"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView(service: translationService))
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
