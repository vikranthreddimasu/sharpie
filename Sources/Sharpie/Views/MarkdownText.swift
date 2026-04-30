import SwiftUI

// Lightweight markdown renderer for the output area. The stdlib's
// `AttributedString(markdown:)` only handles inline syntax (bold, italic,
// inline code, links). Sharpie's rewrites also use line-level structure —
// numbered lists, bulleted lists, paragraph breaks — so we split into
// blocks ourselves and let stdlib handle the inline parts within each
// block.
//
// The clipboard always carries the raw markdown text. Receiving tools
// (Claude Code, Cursor, ChatGPT) parse it on their end. This rendering
// is purely for visual readability inside Sharpie.
struct MarkdownText: View {
    let source: String

    var body: some View {
        let blocks = MarkdownText.parse(source)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(blocks.indices, id: \.self) { i in
                blocks[i].view
            }
        }
    }

    enum Block {
        case paragraph(AttributedString)
        case list(ordered: Bool, items: [AttributedString])
        case code(String)

        @ViewBuilder var view: some View {
            switch self {
            case .paragraph(let attr):
                Text(attr)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            case .list(let ordered, let items):
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items.indices, id: \.self) { j in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(ordered ? "\(j + 1)." : "•")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 22, alignment: .trailing)
                                .monospacedDigit()
                            Text(items[j])
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            case .code(let text):
                Text(text)
                    .font(.system(.callout, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
                    .textSelection(.enabled)
            }
        }
    }

    static func parse(_ source: String) -> [Block] {
        var blocks: [Block] = []
        var paragraph: [String] = []
        var listItems: [String] = []
        var listOrdered: Bool = false
        var codeBuffer: [String] = []
        var inCode: Bool = false

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            let joined = paragraph.joined(separator: " ")
            let attr = (try? AttributedString(
                markdown: joined,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )) ?? AttributedString(joined)
            blocks.append(.paragraph(attr))
            paragraph.removeAll()
        }
        func flushList() {
            guard !listItems.isEmpty else { return }
            let attrs: [AttributedString] = listItems.map { item in
                (try? AttributedString(
                    markdown: item,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                )) ?? AttributedString(item)
            }
            blocks.append(.list(ordered: listOrdered, items: attrs))
            listItems.removeAll()
        }
        func flushCode() {
            guard !codeBuffer.isEmpty else { return }
            blocks.append(.code(codeBuffer.joined(separator: "\n")))
            codeBuffer.removeAll()
        }

        for rawLine in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            // Fenced code blocks: ``` toggles
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCode {
                    flushCode()
                    inCode = false
                } else {
                    flushParagraph()
                    flushList()
                    inCode = true
                }
                continue
            }
            if inCode {
                codeBuffer.append(line)
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flushParagraph()
                flushList()
                continue
            }

            // Bulleted item: -, *, or • at line start
            if let bulletBody = bulletBody(in: line) {
                flushParagraph()
                if !listItems.isEmpty && listOrdered { flushList() }
                listOrdered = false
                listItems.append(bulletBody)
                continue
            }

            // Numbered item: "1. ", "12. " at line start
            if let numberedBody = numberedBody(in: line) {
                flushParagraph()
                if !listItems.isEmpty && !listOrdered { flushList() }
                listOrdered = true
                listItems.append(numberedBody)
                continue
            }

            // Regular paragraph line
            flushList()
            paragraph.append(trimmed)
        }
        flushParagraph()
        flushList()
        flushCode()
        if blocks.isEmpty {
            blocks.append(.paragraph(AttributedString(source)))
        }
        return blocks
    }

    private static func bulletBody(in line: String) -> String? {
        let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
        for marker in ["- ", "* ", "• "] {
            if trimmed.hasPrefix(marker) {
                return String(trimmed.dropFirst(marker.count))
            }
        }
        return nil
    }

    private static func numberedBody(in line: String) -> String? {
        let trimmed = String(line.drop(while: { $0 == " " || $0 == "\t" }))
        var idx = trimmed.startIndex
        var sawDigit = false
        while idx < trimmed.endIndex, trimmed[idx].isASCII, trimmed[idx].isNumber {
            sawDigit = true
            idx = trimmed.index(after: idx)
        }
        // Accept either "1. " or "1) " — AIs use both.
        guard sawDigit, idx < trimmed.endIndex,
              trimmed[idx] == "." || trimmed[idx] == ")"
        else { return nil }
        let afterSeparator = trimmed.index(after: idx)
        guard afterSeparator < trimmed.endIndex, trimmed[afterSeparator] == " " else { return nil }
        return String(trimmed[trimmed.index(after: afterSeparator)...])
    }
}
