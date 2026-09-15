import Foundation
import SwiftUI

struct Countdown: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var format: CountdownFormat = .adaptive
    /// Short label shown in the menu bar instead of `title`, when the full
    /// title would be too long for the menu bar's limited width.
    var shortLabel: String?
    /// The time zone the event's date/time was entered in — e.g. a flight
    /// departing 10:00 Tokyo time. `date` itself is always an absolute
    /// instant, so the countdown is correct regardless of where you are;
    /// this only affects how the target date/time is displayed.
    var timeZoneIdentifier: String = TimeZone.current.identifier

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    var isPast: Bool {
        date < Date()
    }

    private static let menuBarLabelMaxLength = 14

    /// The label shown in the menu bar: the user-defined short label if set,
    /// otherwise the title truncated to fit the menu bar's limited width.
    /// The untruncated title is meant to be shown as a tooltip on hover.
    var menuBarLabel: String {
        let label = shortLabel?.trimmingCharacters(in: .whitespaces)
        if let label, !label.isEmpty { return label }
        return Self.truncated(title, maxLength: Self.menuBarLabelMaxLength)
    }

    private static func truncated(_ text: String, maxLength: Int) -> String {
        guard text.count > maxLength else { return text }
        return String(text.prefix(maxLength - 1)) + "…"
    }

    /// Color hinting how urgent this countdown is, for the badge in the list.
    var urgencyColor: Color {
        guard !isPast else { return .secondary }
        let daysRemaining = date.timeIntervalSinceNow / 86400
        if daysRemaining <= 1 { return .red }
        if daysRemaining <= 7 { return .orange }
        return .green
    }

    private static func dateFormatter(timeZone: TimeZone, includeZone: Bool) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = includeZone ? "EEE d MMM yyyy HH:mm (zzz)" : "EEE d MMM yyyy HH:mm"
        formatter.locale = Locale(identifier: "it_IT")
        formatter.timeZone = timeZone
        return formatter
    }

    /// The event's date/time, shown in `timeZone`. The zone abbreviation is
    /// appended only when it differs from the device's own — the common case
    /// (a local event) stays uncluttered.
    var formattedDate: String {
        let includeZone = timeZoneIdentifier != TimeZone.current.identifier
        return Self.dateFormatter(timeZone: timeZone, includeZone: includeZone).string(from: date)
    }

    /// Renders the remaining (or elapsed, if past) time according to `format`.
    func displayString(now: Date = Date()) -> String {
        let interval = date.timeIntervalSince(now)
        let past = interval < 0
        let absInterval = abs(interval)

        let days = Int(absInterval) / 86400
        let hours = (Int(absInterval) % 86400) / 3600
        let minutes = (Int(absInterval) % 3600) / 60

        let body: String
        switch format {
        case .daysOnly:
            body = "\(days)g"
        case .daysHoursMinutes:
            body = String(format: "%dg %02d:%02d", days, hours, minutes)
        case .adaptive:
            if days >= 1 {
                body = "\(days)g"
            } else if hours >= 1 {
                body = String(format: "%dh %02dm", hours, minutes)
            } else {
                let seconds = Int(absInterval) % 60
                body = String(format: "%dm %02ds", minutes, seconds)
            }
        }
        return past ? "\(body) fa" : body
    }
}

extension Countdown {
    private enum CodingKeys: String, CodingKey {
        case id, title, date, format, shortLabel, timeZoneIdentifier
    }

    /// Custom decoding so JSON saved before `timeZoneIdentifier` existed
    /// still loads, falling back to the device's current time zone.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        format = try container.decodeIfPresent(CountdownFormat.self, forKey: .format) ?? .adaptive
        shortLabel = try container.decodeIfPresent(String.self, forKey: .shortLabel)
        timeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .timeZoneIdentifier) ?? TimeZone.current.identifier
    }
}
