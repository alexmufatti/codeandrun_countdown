import Foundation
import Combine

@MainActor
final class CountdownStore: ObservableObject {
    @Published private(set) var countdowns: [Countdown] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("CodeAndRunCountdown", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("countdowns.json")
        load()
    }

    /// The countdown to show in the menu bar: the soonest one that hasn't passed yet,
    /// falling back to the most recently passed one if everything is in the past.
    var active: Countdown? {
        let upcoming = countdowns.filter { !$0.isPast }.sorted { $0.date < $1.date }
        if let next = upcoming.first { return next }
        return countdowns.sorted { $0.date > $1.date }.first
    }

    func add(_ countdown: Countdown) {
        countdowns.append(countdown)
        save()
    }

    func update(_ countdown: Countdown) {
        guard let index = countdowns.firstIndex(where: { $0.id == countdown.id }) else { return }
        countdowns[index] = countdown
        save()
    }

    func remove(_ countdown: Countdown) {
        countdowns.removeAll { $0.id == countdown.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        countdowns = (try? decoder.decode([Countdown].self, from: data)) ?? []
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(countdowns) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
