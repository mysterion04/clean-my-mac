import SwiftUI

// MARK: - Toolbar Header

struct ToolbarHeader: View {
    let title: String
    let systemImage: String
    let accentColor: Color
    let statusMessage: String
    let isLoading: Bool
    let primaryLabel: String
    let primaryAction: () -> Void
    let destructiveLabel: String?
    let destructiveAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(.secondary)
                    }
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let label = destructiveLabel, let action = destructiveAction {
                Button(action: action) {
                    Label(label, systemImage: "trash")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isLoading)
            }

            Button(action: primaryAction) {
                Label(primaryLabel, systemImage: isLoading ? "stop.fill" : "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(accentColor)
            .disabled(isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "161616"))
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let actionLabel: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Button(action: action) {
                Text(actionLabel)
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "111111"))
    }
}

// MARK: - Scanning Progress

struct ScanningProgressView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(.blue)
            Text(message.isEmpty ? "Scanning..." : message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "111111"))
    }
}

// MARK: - Summary Bar

struct SummaryBar: View {
    let selectedCount: Int
    let totalSize: Int64
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(color)
            Text("\(selectedCount) item(s) selected — \(FormattingUtils.formatBytes(totalSize))")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(0.12))
        .overlay(alignment: .top) {
            Divider().background(color.opacity(0.3))
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(.white)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.06))
        )
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
