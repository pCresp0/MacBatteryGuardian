// AboutTabView.swift
// Pestaña Acerca de: autor, licencia y enlaces.

import SwiftUI
import AppKit

struct AboutTabView: View {

    var body: some View {
        VStack(spacing: 16) {
            heroCard
            detailsCard
            linksCard
            privacyCard
        }
        .padding(16)
    }

    // MARK: - Tarjetas

    private var heroCard: some View {
        MetricCardView(title: AppInfo.name, icon: "battery.100", iconColor: .green) {
            VStack(spacing: 12) {
                Text("Monitor de batería y sistema para macOS")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(AppInfo.versionLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12), in: Capsule())

                HStack(spacing: 4) {
                    Text("Desarrollado por")
                    Text(AppInfo.author)
                        .fontWeight(.semibold)
                }
                .font(.body)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var detailsCard: some View {
        MetricCardView(title: "Licencia y código", icon: "doc.text", iconColor: .blue) {
            VStack(alignment: .leading, spacing: 10) {
                aboutRow(
                    icon: "scalemass",
                    title: "Licencia",
                    detail: "\(AppInfo.licenseName) — libre uso, modificación y distribución con atribución."
                )
                aboutRow(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "Código abierto",
                    detail: "Swift 6 · SwiftUI · 100 % nativo para Apple Silicon (macOS 14+)."
                )
                aboutRow(
                    icon: "internaldrive",
                    title: "Privacidad",
                    detail: "Sin cuentas, sin telemetría ni conexiones de red. Los datos permanecen en tu Mac."
                )
            }
        }
    }

    private var linksCard: some View {
        MetricCardView(title: "Enlaces", icon: "link", iconColor: .accentColor) {
            VStack(spacing: 8) {
                linkButton(
                    title: "Repositorio en GitHub",
                    subtitle: "github.com/pCresp0/MacBatteryGuardian",
                    icon: "link.circle.fill",
                    url: AppInfo.repositoryURL
                )
                linkButton(
                    title: "Perfil de GitHub",
                    subtitle: AppInfo.author,
                    icon: "person.crop.circle",
                    url: AppInfo.authorGitHubURL
                )
                linkButton(
                    title: "LinkedIn",
                    subtitle: "pablocrespobellido",
                    icon: "briefcase.fill",
                    url: AppInfo.linkedInURL
                )
            }
        }
    }

    private var privacyCard: some View {
        MetricCardView(title: "Notas técnicas", icon: "info.circle", iconColor: .secondary) {
            VStack(alignment: .leading, spacing: 8) {
                Text("La temperatura del procesador y la velocidad de ventiladores no están disponibles vía APIs públicas de Apple en Apple Silicon; la app usa estimaciones del sistema cuando corresponde.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Componentes

    private func aboutRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func linkButton(title: String, subtitle: String, icon: String, url: URL) -> some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
