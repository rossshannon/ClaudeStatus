import Foundation

public struct StatusPageSummary: Decodable, Equatable, Sendable {
    public let page: StatusPage
    public let status: StatusPageStatus
    public let components: [StatusPageComponent]
    public let incidents: [StatusPageIncident]

    public init(
        page: StatusPage,
        status: StatusPageStatus,
        components: [StatusPageComponent],
        incidents: [StatusPageIncident]
    ) {
        self.page = page
        self.status = status
        self.components = components
        self.incidents = incidents
    }
}

public struct StatusPage: Decodable, Equatable, Sendable {
    public let id: String?
    public let name: String
    public let url: URL
    public let timeZone: String?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case timeZone = "time_zone"
        case updatedAt = "updated_at"
    }

    public init(id: String?, name: String, url: URL, timeZone: String?, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.url = url
        self.timeZone = timeZone
        self.updatedAt = updatedAt
    }
}

public struct StatusPageStatus: Decodable, Equatable, Sendable {
    public let indicator: String
    public let description: String

    public init(indicator: String, description: String) {
        self.indicator = indicator
        self.description = description
    }
}

public struct StatusPageComponent: Decodable, Equatable, Sendable, Identifiable {
    public let id: String?
    public let name: String
    public let status: String

    public init(id: String?, name: String, status: String) {
        self.id = id
        self.name = name
        self.status = status
    }
}

public struct StatusPageIncident: Decodable, Equatable, Sendable, Identifiable {
    public let id: String?
    public let name: String
    public let status: String
    public let impact: String?
    public let shortlink: URL?
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case impact
        case shortlink
        case updatedAt = "updated_at"
    }

    public init(id: String?, name: String, status: String, impact: String?, shortlink: URL?, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.status = status
        self.impact = impact
        self.shortlink = shortlink
        self.updatedAt = updatedAt
    }
}
