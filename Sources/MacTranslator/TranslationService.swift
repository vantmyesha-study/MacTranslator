import Foundation

class TranslationService {
    private let defaults = UserDefaults.standard
    private let apiKeyKey = "deepseek_api_key"

    var apiKey: String {
        get { defaults.string(forKey: apiKeyKey) ?? "" }
        set { defaults.set(newValue, forKey: apiKeyKey) }
    }

    private func detectDirection(_ text: String) -> (from: String, to: String) {
        let chineseCount = text.unicodeScalars.filter { $0.value >= 0x4E00 && $0.value <= 0x9FFF }.count
        let ratio = Double(chineseCount) / Double(max(text.count, 1))
        return ratio > 0.3 ? ("中文", "英文") : ("英文", "中文")
    }

    func translate(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(TranslationError.noApiKey))
            return
        }

        let direction = detectDirection(text)
        let prompt = """
        你是一个专业翻译。将以下\(direction.from)文本翻译成\(direction.to)。\
        严格保留原文的换行、分点、编号等格式。只输出翻译结果，不要解释，不要加引号。
        """

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": prompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3,
            "max_tokens": 2048
        ]

        var request = URLRequest(url: URL(string: "https://api.deepseek.com/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                completion(.failure(TranslationError.invalidResponse))
                return
            }
            completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
        }.resume()
    }
}

enum TranslationError: LocalizedError {
    case noApiKey
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noApiKey: return "请先在设置中配置 DeepSeek API Key"
        case .invalidResponse: return "API 返回格式异常"
        }
    }
}
