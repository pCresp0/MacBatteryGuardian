// AppInfo.swift
// Metadatos de la app (versión, autor, enlaces).

import Foundation

enum AppInfo {
    static let name = "MacBatteryGuardian"
    static let author = "Pablo Crespo Bellido"
    static let licenseName = "MIT License"
    static let repositoryURL = URL(string: "https://github.com/pCresp0/MacBatteryGuardian")!
    static let authorGitHubURL = URL(string: "https://github.com/pCresp0")!
    static let linkedInURL = URL(string: "https://www.linkedin.com/in/pablocrespobellido")!

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var versionLabel: String {
        "v\(version) (\(build))"
    }
}
