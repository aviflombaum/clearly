import Foundation

struct ChangedownAnnotationFootnote {
    let id: String
    let author: String?
    let date: String?
    let type: String?
    let status: String?
    let summary: String?
    let startLine: Int
    let endLine: Int
}

enum ChangedownAnnotationParser {
    private static let headerRegex = try! NSRegularExpression(
        pattern: #"^\[\^(cn-[A-Za-z0-9.-]+)\]:\s*(.*)$"#,
        options: []
    )

    private static let discussionRegex = try! NSRegularExpression(
        pattern: #"^\s*@[^:]+\d{4}-\d{2}-\d{2}(?:\s+\[[^\]]+\])?:\s*(.*)$"#,
        options: []
    )

    static func parseFootnotes(in markdown: String) -> [String: ChangedownAnnotationFootnote] {
        let lines = markdown.components(separatedBy: "\n")
        var result: [String: ChangedownAnnotationFootnote] = [:]
        var lineIndex = 0

        while lineIndex < lines.count {
            let line = lines[lineIndex]
            let fullRange = NSRange(location: 0, length: (line as NSString).length)

            guard let match = headerRegex.firstMatch(in: line, range: fullRange) else {
                lineIndex += 1
                continue
            }

            let id = substring(in: line, match.range(at: 1))
            let headerContent = substring(in: line, match.range(at: 2))
            let headerParts = headerContent
                .split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }

            let author = headerParts.indices.contains(0) && !headerParts[0].isEmpty ? headerParts[0] : nil
            let date = headerParts.indices.contains(1) && !headerParts[1].isEmpty ? headerParts[1] : nil
            let type = headerParts.indices.contains(2) && !headerParts[2].isEmpty ? headerParts[2] : nil
            let status = headerParts.indices.contains(3) && !headerParts[3].isEmpty ? headerParts[3] : nil

            var endLine = lineIndex
            var summary: String?
            var scanIndex = lineIndex + 1

            while scanIndex < lines.count {
                let candidate = lines[scanIndex]
                let trimmed = candidate.trimmingCharacters(in: .whitespaces)

                if trimmed.isEmpty {
                    endLine = scanIndex
                    scanIndex += 1
                    continue
                }

                if candidate.hasPrefix("    ") || candidate.hasPrefix("\t") {
                    if summary == nil {
                        let candidateRange = NSRange(location: 0, length: (candidate as NSString).length)
                        if let discussionMatch = discussionRegex.firstMatch(in: candidate, range: candidateRange) {
                            summary = substring(in: candidate, discussionMatch.range(at: 1))
                        } else if let colonIndex = trimmed.firstIndex(of: ":") {
                            let afterColon = trimmed[trimmed.index(after: colonIndex)...]
                            let normalized = afterColon.trimmingCharacters(in: .whitespaces)
                            summary = normalized.isEmpty ? nil : normalized
                        } else {
                            summary = trimmed
                        }
                    }

                    endLine = scanIndex
                    scanIndex += 1
                    continue
                }

                break
            }

            result[id] = ChangedownAnnotationFootnote(
                id: id,
                author: author,
                date: date,
                type: type,
                status: status,
                summary: summary,
                startLine: lineIndex,
                endLine: endLine
            )

            lineIndex = max(scanIndex, lineIndex + 1)
        }

        return result
    }

    private static func substring(in string: String, _ range: NSRange) -> String {
        guard let swiftRange = Range(range, in: string) else { return "" }
        return String(string[swiftRange])
    }
}
