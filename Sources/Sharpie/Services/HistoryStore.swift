import Foundation

/// One archive of an input → rewrite, plus any edits the user made to
/// the rewrite afterwards. Stored locally as JSON, never sent anywhere.
struct HistoryEntry: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var createdAt: Date
    var originalInput: String
    var aiOutput: String
    var revisions: [Revision]
    var backend: BackendID
    var modelSlug: String?

    /// The most recent text — either the latest revision the user
    /// committed, or the AI's original output if they never edited it.
    var currentText: String {
        revisions.last?.text ?? aiOutput
    }

    /// Whether the user edited the rewrite at all.
    var wasEdited: Bool {
        !revisions.isEmpty && revisions.last?.text != aiOutput
    }
}

struct Revision: Codable, Equatable, Sendable {
    var timestamp: Date
    var text: String
}

/// JSON-backed history store. Lives at
/// `~/Library/Application Support/Sharpie/history.json` with 0600
/// permissions (user-only, both reads and writes). Never written to
/// `disk` in plaintext is the rule for *API keys* — this is a deliberate
/// add by Vikky for prompt history. Disable in Settings if undesired.
@MainActor
final class HistoryStore: ObservableObject {

    @Published private(set) var entries: [HistoryEntry] = []

    private let fileURL: URL
    private static let entryCap = 500

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            self.fileURL = HistoryStore.defaultURL()
        }
        load()
    }

    // MARK: - Storage paths

    static func defaultURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        let dir = appSupport.appendingPathComponent("Sharpie", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        return dir.appendingPathComponent("history.json", isDirectory: false)
    }

    // MARK: - Public API

    /// Append a new entry from a freshly-finalized rewrite. Returns the
    /// entry's id so the caller (the viewmodel) can attach revisions
    /// later.
    @discardableResult
    func appendEntry(
        originalInput: String,
        aiOutput: String,
        backend: BackendID,
        modelSlug: String?
    ) -> UUID {
        let entry = HistoryEntry(
            id: UUID(),
            createdAt: Date(),
            originalInput: originalInput,
            aiOutput: aiOutput,
            revisions: [],
            backend: backend,
            modelSlug: modelSlug
        )
        // Most recent first — the History UI reads top-down.
        entries.insert(entry, at: 0)
        if entries.count > Self.entryCap {
            entries.removeLast(entries.count - Self.entryCap)
        }
        save()
        return entry.id
    }

    /// Append a revision to an existing entry, deduping if the user is
    /// hammering the editor (we don't want a snapshot per keystroke when
    /// they only meant to make one change).
    func appendRevision(entryId: UUID, text: String) {
        guard let idx = entries.firstIndex(where: { $0.id == entryId }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastText = entries[idx].revisions.last?.text ?? entries[idx].aiOutput
        guard trimmed != lastText.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        entries[idx].revisions.append(
            Revision(timestamp: Date(), text: trimmed)
        )
        save()
    }

    func deleteEntry(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([HistoryEntry].self, from: data)
        } catch {
            // Corrupted history shouldn't brick the app. Keep an empty
            // list and back the bad file up so we don't keep bouncing
            // off the same parse error.
            try? FileManager.default.moveItem(
                at: fileURL,
                to: fileURL.deletingPathExtension().appendingPathExtension("corrupt.json")
            )
            entries = []
        }
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: [.atomic])
            // Lock down permissions so other user accounts on the same
            // Mac (rare, but real on shared workstations) can't read it.
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: fileURL.path
            )
        } catch {
            // We can't surface a useful error here without rebuilding
            // the SwiftUI tree on every save. Worst case the user
            // doesn't see history get persisted; the in-memory list
            // still works for the session.
        }
    }
}
