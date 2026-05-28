import SwiftUI

struct WorkspaceSettingsSheet: View {
    let replayOnboarding: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()

                Capsule()
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 34, height: 4)

                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.studioMuted)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.055), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close settings")
            }
            .padding(.top, 10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(StudioType.control)
                    .foregroundStyle(Color.studioText)

                Text("Local studio behavior")
                    .font(StudioType.metadataSmall)
                    .foregroundStyle(Color.studioMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                replayOnboarding()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.studioGold)
                        .frame(width: 34, height: 34)
                        .background(Color.studioGold.opacity(0.10), in: Circle())

                    Text("Replay onboarding")
                        .font(StudioType.metadata.weight(.semibold))
                        .foregroundStyle(Color.studioText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.studioMuted)
                }
                .frame(minHeight: 50)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.040), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Replay onboarding")

            VStack(spacing: 0) {
                StudioSettingsInfoRow(title: "Version", value: "v\(appVersion) (\(buildNumber))")

                Rectangle()
                    .fill(Color.white.opacity(0.055))
                    .frame(height: 1)
                    .padding(.leading, 12)

                StudioSettingsInfoRow(title: "Library", value: "Local only")
            }
            .background(Color.white.opacity(0.032), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: 382)
        .background(Color.studioPanelRaised.ignoresSafeArea())
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(22)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("workspace-settings-sheet")
    }
}

private struct StudioSettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(StudioType.metadataSmall.weight(.semibold))
                .foregroundStyle(Color.studioMuted)

            Spacer()

            Text(value)
                .font(StudioType.metadataSmall.weight(.semibold))
                .foregroundStyle(Color.studioText.opacity(0.86))
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
    }
}
