import Foundation

public struct StatusPageClient: Sendable {
    public static let defaultStatusPageURL = URL(string: "https://status.claude.ai")!
    public static let defaultSummaryURL = URL(string: "https://status.claude.ai/api/v2/summary.json")!

    public let summaryURL: URL
    public let statusPageURL: URL
    public let timeout: TimeInterval

    public init(
        summaryURL: URL = StatusPageClient.defaultSummaryURL,
        statusPageURL: URL = StatusPageClient.defaultStatusPageURL,
        timeout: TimeInterval = 15
    ) {
        self.summaryURL = summaryURL
        self.statusPageURL = statusPageURL
        self.timeout = timeout
    }

    public func fetchStatus(checkedAt: Date = Date()) async throws -> ClaudeServiceStatus {
        let data = try await fetchSummaryData()
        let decoder = JSONDecoder.statusPage
        let summary = try decoder.decode(StatusPageSummary.self, from: data)
        return StatusEvaluator.evaluate(
            summary: summary,
            checkedAt: checkedAt,
            sourcePageURL: statusPageURL
        )
    }

    public func fetchSummaryData() async throws -> Data {
        var request = URLRequest(url: summaryURL)
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ClaudeStatus/0.1", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw StatusPageClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw StatusPageClientError.httpStatus(httpResponse.statusCode)
        }

        return data
    }
}

public enum StatusPageClientError: LocalizedError, Equatable, Sendable {
    case invalidResponse
    case httpStatus(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The status page returned an invalid response."
        case let .httpStatus(statusCode):
            "The status page returned HTTP \(statusCode)."
        }
    }
}

extension JSONDecoder {
    static var statusPage: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            if let date = fractionalFormatter.date(from: value) {
                return date
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            if let date = formatter.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 date: \(value)"
            )
        }
        return decoder
    }
}
