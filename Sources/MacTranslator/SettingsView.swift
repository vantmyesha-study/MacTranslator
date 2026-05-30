import SwiftUI

struct SettingsView: View {
    @ObservedObject private var vm: SettingsViewModel

    init(service: TranslationService) {
        self.vm = SettingsViewModel(service: service)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MacTranslator")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text("DeepSeek API Key")
                    .font(.headline)
                SecureField("sk-...", text: $vm.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { vm.save() }
            }

            HStack {
                Text("快捷键: ⌥T (Option + T)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("保存") { vm.save() }
                    .buttonStyle(.borderedProminent)
            }

            if !vm.message.isEmpty {
                Text(vm.message)
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(24)
        .frame(width: 420)
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
