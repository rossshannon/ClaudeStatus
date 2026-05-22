import Foundation
import Testing
@testable import ClaudeStatusCore

@Suite("Status evaluator")
struct StatusEvaluatorTests {
    @Test("operational summary stays operational")
    func operationalSummary() throws {
        let status = StatusEvaluator.evaluate(
            summary: summary(
                indicator: "none",
                description: "All Systems Operational",
                components: [
                    StatusPageComponent(id: "claude-code", name: "Claude Code", status: "operational")
                ],
                incidents: []
            ),
            checkedAt: referenceDate
        )

        #expect(status.severity == .operational)
        #expect(status.affectedComponents.isEmpty)
        #expect(status.activeIncidents.isEmpty)
        #expect(status.tooltip == "Claude status: Operational - All Systems Operational")
    }

    @Test("minor indicator is degraded and records affected components")
    func minorSummary() throws {
        let status = StatusEvaluator.evaluate(
            summary: summary(
                indicator: "minor",
                description: "Partially Degraded Service",
                components: [
                    StatusPageComponent(id: "claude-code", name: "Claude Code", status: "degraded_performance"),
                    StatusPageComponent(id: "api", name: "Claude API", status: "operational")
                ],
                incidents: [
                    StatusPageIncident(
                        id: "incident-1",
                        name: "Elevated error rate",
                        status: "monitoring",
                        impact: "major",
                        shortlink: URL(string: "https://stspg.io/example"),
                        updatedAt: referenceDate
                    )
                ]
            ),
            checkedAt: referenceDate
        )

        #expect(status.severity == .degraded)
        #expect(status.affectedComponents.map(\.name) == ["Claude Code"])
        #expect(status.activeIncidents.map(\.name) == ["Elevated error rate"])
    }

    @Test("major component outage is red-level outage")
    func majorComponentOutage() throws {
        let status = StatusEvaluator.evaluate(
            summary: summary(
                indicator: "none",
                description: "All Systems Operational",
                components: [
                    StatusPageComponent(id: "api", name: "Claude API", status: "major_outage")
                ],
                incidents: []
            ),
            checkedAt: referenceDate
        )

        #expect(status.severity == .outage)
        #expect(status.headline == "Claude is down")
    }

    @Test("resolved incidents are ignored")
    func resolvedIncidentsAreIgnored() throws {
        let status = StatusEvaluator.evaluate(
            summary: summary(
                indicator: "none",
                description: "All Systems Operational",
                components: [],
                incidents: [
                    StatusPageIncident(
                        id: "incident-1",
                        name: "Old incident",
                        status: "resolved",
                        impact: "critical",
                        shortlink: nil,
                        updatedAt: referenceDate
                    )
                ]
            ),
            checkedAt: referenceDate
        )

        #expect(status.severity == .operational)
        #expect(status.activeIncidents.isEmpty)
    }

    @Test("Statuspage dates decode with fractional seconds")
    func decodesStatusPageDates() throws {
        let json = """
        {
          "page": {
            "id": "tymt9n04zgry",
            "name": "Claude",
            "url": "https://status.claude.com",
            "time_zone": "Etc/UTC",
            "updated_at": "2026-05-22T06:32:50.748Z"
          },
          "status": {
            "indicator": "minor",
            "description": "Partially Degraded Service"
          },
          "components": [
            { "id": "code", "name": "Claude Code", "status": "degraded_performance" }
          ],
          "incidents": [
            {
              "id": "abc",
              "name": "Elevated error rate",
              "status": "monitoring",
              "impact": "major",
              "shortlink": "https://stspg.io/example",
              "updated_at": "2026-05-22T06:32:50.738Z"
            }
          ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.statusPage.decode(StatusPageSummary.self, from: json)

        #expect(decoded.status.indicator == "minor")
        #expect(decoded.page.updatedAt != nil)
        #expect(decoded.components.first?.name == "Claude Code")
        #expect(decoded.incidents.first?.shortlink == URL(string: "https://stspg.io/example"))
    }

    private var referenceDate: Date {
        Date(timeIntervalSince1970: 1_779_435_600)
    }

    private func summary(
        indicator: String,
        description: String,
        components: [StatusPageComponent],
        incidents: [StatusPageIncident]
    ) -> StatusPageSummary {
        StatusPageSummary(
            page: StatusPage(
                id: "tymt9n04zgry",
                name: "Claude",
                url: URL(string: "https://status.claude.com")!,
                timeZone: "Etc/UTC",
                updatedAt: referenceDate
            ),
            status: StatusPageStatus(indicator: indicator, description: description),
            components: components,
            incidents: incidents
        )
    }
}
