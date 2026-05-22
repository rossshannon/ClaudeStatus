import Foundation

public enum StatusEvaluator {
    public static func evaluate(
        summary: StatusPageSummary,
        checkedAt: Date = Date(),
        sourcePageURL: URL = StatusPageClient.defaultStatusPageURL
    ) -> ClaudeServiceStatus {
        let affectedComponents = summary.components.filter { component in
            component.status != "operational"
        }
        let activeIncidents = summary.incidents.filter { incident in
            incident.status != "resolved" && incident.status != "completed"
        }

        let pageSeverity = StatusEvaluator.severity(forIndicator: summary.status.indicator)
        let componentSeverity = affectedComponents
            .map { StatusEvaluator.severity(forComponentStatus: $0.status) }
            .reduce(.operational, StatusEvaluator.strongest)

        var severity = StatusEvaluator.strongest(pageSeverity, componentSeverity)

        if severity == .operational {
            let incidentSeverity = activeIncidents
                .map { StatusEvaluator.severity(forIncidentImpact: $0.impact) }
                .reduce(.operational, StatusEvaluator.strongest)
            severity = StatusEvaluator.strongest(severity, incidentSeverity)
        }

        let headline = headline(for: severity)
        let detail = summary.status.description.trimmingCharacters(in: .whitespacesAndNewlines)

        return ClaudeServiceStatus(
            severity: severity,
            headline: headline,
            detail: detail.isEmpty ? headline : detail,
            pageUpdatedAt: summary.page.updatedAt,
            checkedAt: checkedAt,
            sourcePageURL: sourcePageURL,
            affectedComponents: affectedComponents,
            activeIncidents: activeIncidents
        )
    }

    public static func severity(forIndicator indicator: String) -> ServiceSeverity {
        switch indicator {
        case "none":
            .operational
        case "minor", "maintenance":
            .degraded
        case "major", "critical":
            .outage
        default:
            .unknown
        }
    }

    public static func severity(forComponentStatus status: String) -> ServiceSeverity {
        switch status {
        case "operational":
            .operational
        case "degraded_performance", "partial_outage", "under_maintenance":
            .degraded
        case "major_outage":
            .outage
        default:
            .unknown
        }
    }

    public static func severity(forIncidentImpact impact: String?) -> ServiceSeverity {
        switch impact {
        case "minor":
            .degraded
        case "major", "critical":
            .outage
        default:
            .operational
        }
    }

    public static func humanisedComponentStatus(_ status: String) -> String {
        status
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    private static func strongest(_ lhs: ServiceSeverity, _ rhs: ServiceSeverity) -> ServiceSeverity {
        rank(lhs) >= rank(rhs) ? lhs : rhs
    }

    private static func rank(_ severity: ServiceSeverity) -> Int {
        switch severity {
        case .operational:
            0
        case .degraded:
            1
        case .unknown:
            1
        case .outage:
            2
        }
    }

    private static func headline(for severity: ServiceSeverity) -> String {
        switch severity {
        case .operational:
            "Claude is operational"
        case .degraded:
            "Claude is degraded"
        case .outage:
            "Claude is down"
        case .unknown:
            "Claude status unknown"
        }
    }
}
