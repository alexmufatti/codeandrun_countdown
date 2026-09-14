import Foundation

enum CountdownFormat: String, Codable, CaseIterable, Identifiable {
    case adaptive
    case daysOnly
    case daysHoursMinutes

    var id: String { rawValue }

    var label: String {
        switch self {
        case .adaptive: return "Adattivo (giorni → ore/minuti)"
        case .daysOnly: return "Solo giorni"
        case .daysHoursMinutes: return "Giorni + ore:minuti"
        }
    }

    /// How often the display needs refreshing for this format.
    var refreshInterval: TimeInterval {
        switch self {
        case .daysOnly: return 60 * 60
        case .daysHoursMinutes, .adaptive: return 30
        }
    }
}
