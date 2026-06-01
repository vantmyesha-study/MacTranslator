import Cocoa
import SwiftUI

enum TranslationStatus {
    case loading, success, error
}

private let kPanelWidth: CGFloat = 420
private let kChromeHeight: CGFloat = 52  // bottom bar (44) + divider (8)

class TranslationPanel {
    private var panel: NSPanel?
    private let viewModel = TranslationViewModel()
    private var monitor: Any?

    func show(at point: NSPoint, sourceText: String, status: TranslationStatus) {
        viewModel.sourceText = sourceText
        viewModel.translatedText = ""
        viewModel.status = status

        close()

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let maxH = screen.visibleFrame.height * 0.7

        let panelHeight = measurePanelHeight(maxH: maxH)

        var x = point.x - kPanelWidth / 2
        var y = point.y - panelHeight - 10
        let frame = screen.visibleFrame
        x = max(frame.minX + 4, min(x, frame.maxX - kPanelWidth - 4))
        y = max(frame.minY + 4, min(y, frame.maxY - panelHeight - 4))

        let maxScrollH = maxH - kChromeHeight
        let contentView = TranslationPanelView(
            viewModel: viewModel,
            maxScrollHeight: maxScrollH,
            onCopy: { [weak self] in
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(self?.viewModel.translatedText ?? "", forType: .string)
            },
            onClose: { [weak self] in self?.close() }
        )

        let hosting = NSHostingView(rootView: contentView)
        hosting.frame = NSRect(x: 0, y: 0, width: kPanelWidth, height: panelHeight)

        let p = NSPanel(
            contentRect: NSRect(x: x, y: y, width: kPanelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView, .resizable],
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

        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let panel = self.panel else { return }
            if !NSMouseInRect(NSEvent.mouseLocation, panel.frame, false) {
                self.close()
            }
        }
    }

    func update(translated: String, status: TranslationStatus) {
        viewModel.translatedText = translated
        viewModel.status = status

        guard let panel else { return }

        DispatchQueue.main.async {
            let screen = NSScreen.main ?? NSScreen.screens[0]
            let maxH = screen.visibleFrame.height * 0.7
            let newHeight = self.measurePanelHeight(maxH: maxH)

            var f = panel.frame
            let delta = newHeight - f.height
            f.origin.y -= delta
            f.size.height = newHeight
            panel.setFrame(f, display: true, animate: true)
        }
    }

    func close() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
        panel?.close()
        panel = nil
    }

    // 用一个无滚动限制的临时 view 测量真实内容高度，再加 chrome 后 clamp
    private func measurePanelHeight(maxH: CGFloat) -> CGFloat {
        let measureView = TranslationContentView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: measureView)
        hosting.frame = NSRect(x: 0, y: 0, width: kPanelWidth - 32, height: 10000)
        hosting.layoutSubtreeIfNeeded()
        let contentH = hosting.fittingSize.height
        return min(max(contentH + kChromeHeight, 120), maxH)
    }
}

class TranslationViewModel: ObservableObject {
    @Published var sourceText: String = ""
    @Published var translatedText: String = ""
    @Published var status: TranslationStatus = .loading
}

// 仅用于高度测量，不带 ScrollView 限制
struct TranslationContentView: View {
    @ObservedObject var viewModel: TranslationViewModel

    private var sourceLines: [String] {
        viewModel.sourceText.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private var translatedLines: [String] {
        viewModel.translatedText.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.status == .error {
                Text(viewModel.translatedText)
                    .font(.system(size: 13)).foregroundColor(.red)
                    .padding(.horizontal, 16).padding(.vertical, 10)
            } else {
                ForEach(Array(sourceLines.enumerated()), id: \.offset) { i, line in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(line)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if i < translatedLines.count {
                            Text(translatedLines[i])
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.mini)
                                Text("翻译中…").foregroundColor(.secondary).font(.system(size: 13))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if i < sourceLines.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
        }
    }
}

struct TranslationPanelView: View {
    @ObservedObject var viewModel: TranslationViewModel
    let maxScrollHeight: CGFloat
    let onCopy: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 可滚动内容区
            ScrollView(.vertical, showsIndicators: true) {
                TranslationContentView(viewModel: viewModel)
            }
            .frame(maxHeight: maxScrollHeight)

            Divider()

            // 底部按钮栏
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: kPanelWidth)
        .background(.ultraThinMaterial)
    }
}
