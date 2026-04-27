import AppKit
import ClearlyCore
import Foundation

extension Notification.Name {
    static let previewAnnotationCommand = Notification.Name("ClearlyPreviewAnnotationCommand")
}

enum AnnotationPrompt {
    static func requestComment() -> String? {
        let alert = NSAlert()
        alert.messageText = "Add Annotation"
        alert.informativeText = "Enter a note for the selected text."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        input.placeholderString = "Note"
        alert.accessoryView = input

        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return input.stringValue
    }

    static func present(error: Error) {
        NSAlert(error: error).runModal()
    }
}

enum PreviewAnnotationMapper {
    enum Error: LocalizedError {
        case emptySelection
        case notFound
        case ambiguous

        var errorDescription: String? {
            switch self {
            case .emptySelection:
                return "Select text before adding an annotation."
            case .notFound:
                return "The preview selection could not be matched back to the markdown source. Switch to the editor to annotate this selection."
            case .ambiguous:
                return "That selected text appears more than once in the markdown source. Switch to the editor to annotate the exact occurrence."
            }
        }
    }

    static func sourceRange(for selectedText: String, in markdown: String) throws -> Range<String.Index> {
        let needle = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else {
            throw Error.emptySelection
        }

        let ranges = markdown.ranges(of: needle)
        guard !ranges.isEmpty else {
            throw Error.notFound
        }
        guard ranges.count == 1 else {
            throw Error.ambiguous
        }
        return ranges[0]
    }
}

@MainActor
func performAddAnnotationCommand() {
    if LiveEditorCommandDispatcher.isActive {
        LiveEditorCommandDispatcher.send(.addAnnotation)
    } else if WorkspaceManager.shared.currentViewMode == .preview {
        NotificationCenter.default.post(name: .previewAnnotationCommand, object: nil)
    } else {
        NSApp.sendAction(#selector(ClearlyTextView.addAnnotation(_:)), to: nil, from: nil)
    }
}

private extension String {
    func ranges(of needle: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStart = startIndex

        while searchStart < endIndex,
              let range = self[searchStart...].range(of: needle) {
            ranges.append(range)
            searchStart = range.upperBound
        }

        return ranges
    }
}
