import Foundation

public enum ServiceSeverity: Equatable, Sendable {
    case operational
    case degraded
    case outage
    case unknown

    public var displayName: String {
        switch self {
        case .operational:
            "Operational"
        case .degraded:
            "Degraded"
        case .outage:
            "Outage"
        case .unknown:
            "Unknown"
        }
    }

    public var shortLabel: String {
        switch self {
        case .operational:
            "OK"
        case .degraded:
            "Degraded"
        case .outage:
            "Down"
        case .unknown:
            "Unknown"
        }
    }
}

public struct ClaudeServiceStatus: Equatable, Sendable {
    public let severity: ServiceSeverity
    public let headline: String
    public let detail: String
    public let pageUpdatedAt: Date?
    public let checkedAt: Date
    public let sourcePageURL: URL
    public let affectedComponents: [StatusPageComponent]
    public let activeIncidents: [StatusPageIncident]

    public init(
        severity: ServiceSeverity,
        headline: String,
        detail: String,
        pageUpdatedAt: Date?,
        checkedAt: Date,
        sourcePageURL: URL,
        affectedComponents: [StatusPageComponent],
        activeIncidents: [StatusPageIncident]
    ) {
        self.severity = severity
        self.headline = headline
        self.detail = detail
        self.pageUpdatedAt = pageUpdatedAt
        self.checkedAt = checkedAt
        self.sourcePageURL = sourcePageURL
        self.affectedComponents = affectedComponents
        self.activeIncidents = activeIncidents
    }

    public var tooltip: String {
        "Claude status: \(severity.displayName) - \(detail)"
    }

    public static func unavailable(
        error: Error,
        checkedAt: Date = Date(),
        sourcePageURL: URL = StatusPageClient.defaultStatusPageURL
    ) -> ClaudeServiceStatus {
        ClaudeServiceStatus(
            severity: .unknown,
            headline: "Claude status unknown",
            detail: "Could not reach the Claude status page: \(error.localizedDescription)",
            pageUpdatedAt: nil,
            checkedAt: checkedAt,
            sourcePageURL: sourcePageURL,
            affectedComponents: [],
            activeIncidents: []
        )
    }
}
