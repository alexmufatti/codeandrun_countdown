import SwiftUI

struct AddEditCountdownView: View {
    @EnvironmentObject private var store: CountdownStore

    let editing: Countdown?
    let onDismiss: () -> Void

    @State private var title: String = ""
    @State private var shortLabel: String = ""
    @State private var date: Date = Date().addingTimeInterval(86400)
    @State private var format: CountdownFormat = .adaptive
    @State private var timeZoneIdentifier: String = TimeZone.current.identifier

    private static let allTimeZoneIdentifiers = TimeZone.knownTimeZoneIdentifiers.sorted()

    init(editing: Countdown? = nil, onDismiss: @escaping () -> Void = {}) {
        self.editing = editing
        self.onDismiss = onDismiss
        if let editing {
            _title = State(initialValue: editing.title)
            _shortLabel = State(initialValue: editing.shortLabel ?? "")
            _format = State(initialValue: editing.format)
            _timeZoneIdentifier = State(initialValue: editing.timeZoneIdentifier)
            // The date picker always displays in the device's own time zone,
            // so re-express the stored absolute instant as the wall-clock
            // date/time it was originally entered as in `timeZoneIdentifier`.
            _date = State(initialValue: Self.pickerDate(from: editing.date, timeZoneIdentifier: editing.timeZoneIdentifier))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Form {
                Section {
                    TextField("Titolo", text: $title)
                    TextField(
                        "Etichetta breve (menu bar)",
                        text: $shortLabel,
                        prompt: Text(title.isEmpty ? "es. Maratona" : title)
                    )
                }
                Section {
                    DatePicker("Data", selection: $date)
                    Picker("Fuso orario", selection: $timeZoneIdentifier) {
                        ForEach(Self.allTimeZoneIdentifiers, id: \.self) { identifier in
                            Text(Self.timeZoneLabel(identifier)).tag(identifier)
                        }
                    }
                    Picker("Formato", selection: $format) {
                        ForEach(CountdownFormat.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)

            HStack {
                Spacer()
                Button("Annulla") { onDismiss() }
                Button(editing == nil ? "Aggiungi" : "Salva") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding([.horizontal, .bottom], 16)
        }
        .frame(width: 360)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: editing == nil ? "plus.circle.fill" : "pencil.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            Text(editing == nil ? "Nuovo countdown" : "Modifica countdown")
                .font(.title3.weight(.semibold))
        }
        .padding(.top, 18)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let trimmedLabel = shortLabel.trimmingCharacters(in: .whitespaces)
        let absoluteDate = Self.absoluteDate(from: date, timeZoneIdentifier: timeZoneIdentifier)
        if var countdown = editing {
            countdown.title = trimmed
            countdown.shortLabel = trimmedLabel.isEmpty ? nil : trimmedLabel
            countdown.date = absoluteDate
            countdown.format = format
            countdown.timeZoneIdentifier = timeZoneIdentifier
            store.update(countdown)
        } else {
            store.add(Countdown(
                title: trimmed,
                date: absoluteDate,
                format: format,
                shortLabel: trimmedLabel.isEmpty ? nil : trimmedLabel,
                timeZoneIdentifier: timeZoneIdentifier
            ))
        }
        onDismiss()
    }

    private static func timeZoneLabel(_ identifier: String) -> String {
        let offset = TimeZone(identifier: identifier).map { $0.secondsFromGMT() / 60 } ?? 0
        let sign = offset < 0 ? "-" : "+"
        let hours = abs(offset) / 60
        let minutes = abs(offset) % 60
        let offsetLabel = minutes == 0 ? "GMT\(sign)\(hours)" : String(format: "GMT%@%d:%02d", sign, hours, minutes)
        return "\(identifier.replacingOccurrences(of: "_", with: " ")) (\(offsetLabel))"
    }

    /// The `DatePicker` always shows its `Date` using the device's own
    /// calendar/time zone. To let it display a given absolute instant as the
    /// wall-clock date/time it represents in `timeZoneIdentifier`, extract
    /// the year/month/day/hour/minute in that zone and rebuild a `Date` from
    /// those same numbers in the device's own zone.
    private static func pickerDate(from absoluteDate: Date, timeZoneIdentifier: String) -> Date {
        var sourceCalendar = Calendar.current
        sourceCalendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        let components = sourceCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: absoluteDate)
        return Calendar.current.date(from: components) ?? absoluteDate
    }

    /// The inverse of `pickerDate(from:timeZoneIdentifier:)`: reads the
    /// year/month/day/hour/minute the user entered (as displayed in the
    /// device's own zone) and reinterprets those same numbers as being in
    /// `timeZoneIdentifier`, producing the correct absolute instant.
    private static func absoluteDate(from pickerDate: Date, timeZoneIdentifier: String) -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: pickerDate)
        var targetCalendar = Calendar.current
        targetCalendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        return targetCalendar.date(from: components) ?? pickerDate
    }
}
