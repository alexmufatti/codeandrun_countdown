import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject private var store: CountdownStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if store.countdowns.isEmpty {
                emptyState
            } else {
                VStack(spacing: 2) {
                    ForEach(store.countdowns.sorted { $0.date < $1.date }) { countdown in
                        row(for: countdown)
                    }
                }
                .padding(.vertical, 6)
            }

            Divider()

            footer
        }
        .frame(width: 300)
    }

    private var header: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundStyle(.tint)
            Text("Countdown")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Nessun countdown")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Button {
                AddEditWindowPresenter.shared.present(editing: nil, store: store)
            } label: {
                Label("Nuovo countdown…", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Esci", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func row(for countdown: Countdown) -> some View {
        HStack(spacing: 10) {
            Text(countdown.displayString())
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(minWidth: 64)
                .background(countdown.urgencyColor, in: .rect(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 1) {
                Text(countdown.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(countdown.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    AddEditWindowPresenter.shared.present(editing: countdown, store: store)
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    store.remove(countdown)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
    }
}
