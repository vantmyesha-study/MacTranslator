import SwiftUI

struct MenuPanelView: View {
    @ObservedObject private var vm: SettingsViewModel

    init(service: TranslationService) {
        self.vm = SettingsViewModel(service: service)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("API Key")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                SecureField("sk-...", text: $vm.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .onSubmit { vm.save() }
                Button("保存") { vm.save() }
                    .controlSize(.small)
            }
            if !vm.message.isEmpty {
                Text(vm.message)
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(10)
    }
}

class SettingsViewModel: ObservableObject {
    @Published var apiKey: String
    @Published var message = ""
    private let service: TranslationService

    init(service: TranslationService) {
        self.service = service
        self.apiKey = service.apiKey
    }

    func save() {
        service.apiKey = apiKey
        message = "已保存"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.message = ""
        }
    }
}
