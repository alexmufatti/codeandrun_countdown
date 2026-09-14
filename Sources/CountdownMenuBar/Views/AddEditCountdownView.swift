import SwiftUI

struct AddEditCountdownView: View {
    @EnvironmentObject private var store: CountdownStore

    let editing: Countdown?
    let onDismiss: () -> Void

    @State private var title: String = ""
    @State private var shortLabel: String = ""
    @State private var date: Date = Date().addingTimeInterval(86400)
    @State private var format: CountdownFormat = .adaptive

    init(editing: Countdown? = nil, onDismiss: @escaping () -> Void = {}) {
        self.editing = editing
        self.onDismiss = onDismiss
        if let editing {
            _title = State(initialValue: editing.title)
            _shortLabel = State(initialValue: editing.shortLabel ?? "")
            _date = State(initialValue: editing.date)
            _format = State(initialValue: editing.format)
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
        if var countdown = editing {
            countdown.title = trimmed
            countdown.shortLabel = trimmedLabel.isEmpty ? nil : trimmedLabel
            countdown.date = date
            countdown.format = format
            store.update(countdown)
        } else {
            store.add(Countdown(title: trimmed, date: date, format: format, shortLabel: trimmedLabel.isEmpty ? nil : trimmedLabel))
        }
        onDismiss()
    }
}
