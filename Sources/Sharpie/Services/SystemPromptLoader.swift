import Foundation

enum SystemPromptLoader {
    static func load() throws -> String {
        guard let url = Bundle.module.url(forResource: "sharpen", withExtension: "md") else {
            throw SharpieError.promptResourceNotFound
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}
