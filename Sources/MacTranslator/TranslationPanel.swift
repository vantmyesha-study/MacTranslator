import Cocoa
import SwiftUI

enum TranslationStatus {
    case loading, success, error
}

class TranslationPanel {
    private var panel: NSPanel?
    private let viewModel = TranslationViewModel()
    private var monitor: Any?

    func show(at point: NSPoint, sourceText: String, status: TranslationStatus) {
        viewModel.sourceText = sourceText
        viewModel.translatedText = ""
        viewModel.status = status

        close()

        let panelWidth: CGFloat = 420
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let maxPanelHeight = screen.visibleFrame.height * 0.6

        let contentView = TranslationPanelView(viewModel: viewModel, maxPanelHeight: maxPanelHeight, onCopy: { [weak self] in
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(self?.viewModel.translatedText ?? "", forType: .string)
        }, onClose: { [weak self] in
            self?.close()
        })

        let hosting = NSHostingView(rootView: contentView)
        hosting.frame = NSRect(x: 0, y: 0, width: panelWidth, height: 1000)
        hosting.layoutSubtreeIfNeeded()
        let fittingSize = hosting.fittingSize
        let panelHeight = min(max(fittingSize.height, 140), maxPanelHeight)
        hosting.frame = NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight)

        var x = point.x - panelWidth / 2
        var y = point.y - panelHeight - 10

        let frame = screen.visibleFrame
        x = max(frame.minX + 4, min(x, frame.maxX - panelWidth - 4))
        y = max(frame.minY + 4, min(y, frame.maxY - panelHeight - 4))

        let p = NSPanel(
            contentRect: NSRect(x: x, y: y, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .floating
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.isMovableByWindowBackground = true
        p.contentView = hosting
        p.hasShadow = true
        p.backgroundColor = .clear
        p.orderFrontRegardless()

        panel = p

        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel else { return }
            if !panel.frame.contains(event.locationInWindow) {
                self.close()
            }
        }
    }

    func update(translated: String, status: TranslationStatus) {
        viewModel.translatedText = translated
        viewModel.status = status

        guard let panel, let hosting = panel.contentView as? NSHostingView<TranslationPanelView> else { return }

        DispatchQueue.main.async {
            hosting.layoutSubtreeIfNeeded()
            let screen = NSScreen.main ?? NSScreen.screens[0]
            let maxH = screen.visibleFrame.height * 0.6
            let fittingSize = hosting.fittingSize
            let newHeight = min(max(fittingSize.height, 140), maxH)

            var frame = panel.frame
            let delta = newHeight - frame.height
            frame.origin.y -= delta
            frame.size.height = newHeight
            panel.setFrame(frame, display: true, animate: true)
        }
    }

    func close() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        panel?.close()
        panel = nil
    }
}

class TranslationViewModel: ObservableObject {
    @Published var sourceText: String = ""
    @Published var translatedText: String = ""
    @Published var status: TranslationStatus = .loading
}

struct TranslationPanelView: View {
    @ObservedObject var viewModel: TranslationViewModel
    let maxPanelHeight: CGFloat
    let onCopy: () -> Void
    let onClose: () -> Void

    private var maxSectionHeight: CGFloat { maxPanelHeight * 0.4 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("原文")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(viewModel.sourceText)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)

            Divider()

            Text("译文")
                .font(.caption)
                .foregroundColor(.secondary)

            Group {
                switch viewModel.status {
                case .loading:
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("翻译中…").foregroundColor(.secondary)
                    }
                case .success:
                    Text(viewModel.translatedText)
                        .font(.system(size: 14, weight: .medium))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(nil)
                case .error:
                    Text(viewModel.translatedText)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)

            HStack {
                Spacer()
                if viewModel.status == .success {
                    Button(action: onCopy) {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                Button("关闭", action: onClose)
                    .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 420)
        .background(.ultraThinMaterial)
    }
}
