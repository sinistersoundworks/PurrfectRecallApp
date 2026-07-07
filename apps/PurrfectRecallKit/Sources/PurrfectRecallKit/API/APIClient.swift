import Foundation

public enum APIConfig {
    public static let baseURLKey = "purrfectrecall.api.baseURL"
    private static let legacyBaseURLKey = "studyweb.api.baseURL"
    public static let defaultBaseURL = "http://127.0.0.1:8000"

    public static var baseURL: URL {
        migrateLegacyBaseURLIfNeeded()
        let raw = UserDefaults.standard.string(forKey: baseURLKey) ?? defaultBaseURL
        return URL(string: raw) ?? URL(string: defaultBaseURL)!
    }

    public static func setBaseURL(_ value: String) {
        UserDefaults.standard.set(value, forKey: baseURLKey)
    }

    private static func migrateLegacyBaseURLIfNeeded() {
        guard UserDefaults.standard.string(forKey: baseURLKey) == nil,
              let legacy = UserDefaults.standard.string(forKey: legacyBaseURLKey)
        else { return }
        UserDefaults.standard.set(legacy, forKey: baseURLKey)
    }
}

public enum APIError: LocalizedError, Sendable {
    case invalidURL
    case badStatus(Int, String)
    case decoding(Error)
    case transport(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid API URL"
        case .badStatus(let code, let body): "HTTP \(code): \(body)"
        case .decoding(let error): "Decode error: \(error.localizedDescription)"
        case .transport(let error): error.localizedDescription
        }
    }
}

public struct APIClient: Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = APIDateParser.parse(value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        self.encoder = JSONEncoder()
    }

    private func url(_ path: String) throws -> URL {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }
        return url
    }

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        var req = URLRequest(url: try url(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.badStatus(-1, "No response")
            }
            guard (200...299).contains(http.statusCode) else {
                let text = String(data: data, encoding: .utf8) ?? ""
                throw APIError.badStatus(http.statusCode, text)
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.transport(error)
        }
    }

    private func emptyRequest(_ path: String, method: String, body: Encodable? = nil) async throws {
        struct Empty: Decodable {}
        let _: Empty? = try? await request(path, method: method, body: body)
        // DELETE may return {"message":"deleted"}
        var req = URLRequest(url: try url(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { req.httpBody = try encoder.encode(AnyEncodable(body)) }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError.badStatus(code, text)
        }
    }

    public func fetchSubjects() async throws -> [SubjectDTO] {
        try await request("/subjects")
    }

    public func createSubject(_ payload: SubjectCreateRequest) async throws -> SubjectDTO {
        try await request("/subjects", method: "POST", body: payload)
    }

    public func updateSubject(id: Int, _ payload: SubjectCreateRequest) async throws -> SubjectDTO {
        try await request("/subjects/\(id)", method: "PUT", body: payload)
    }

    public func deleteSubject(id: Int) async throws {
        try await emptyRequest("/subjects/\(id)", method: "DELETE")
    }

    public func fetchStudyQueue(subjectId: Int? = nil, limit: Int = 50) async throws -> [FlashcardDTO] {
        var path = "/flashcards/study-queue?limit=\(limit)"
        if let subjectId {
            path += "&subject_id=\(subjectId)"
        }
        return try await request(path)
    }

    public func fetchFlashcards(subjectId: Int? = nil) async throws -> [FlashcardDTO] {
        if let subjectId {
            return try await request("/flashcards?subject_id=\(subjectId)")
        }
        return try await request("/flashcards")
    }

    public func createFlashcard(_ payload: FlashcardCreateRequest) async throws -> FlashcardDTO {
        try await request("/flashcards", method: "POST", body: payload)
    }

    public func updateFlashcard(id: Int, _ payload: FlashcardUpdateRequest) async throws -> FlashcardDTO {
        try await request("/flashcards/\(id)", method: "PUT", body: payload)
    }

    public func deleteFlashcard(id: Int) async throws {
        try await emptyRequest("/flashcards/\(id)", method: "DELETE")
    }

    public func reviewFlashcard(
        id: Int,
        quality: Int,
        confidence: Int? = nil,
        responseMs: Int? = nil,
        sessionId: String? = nil
    ) async throws -> FlashcardReviewResultDTO {
        try await request(
            "/flashcards/\(id)/review",
            method: "POST",
            body: ReviewRequest(
                quality: quality,
                confidence: confidence,
                responseMs: responseMs,
                sessionId: sessionId
            )
        )
    }

    public func fetchStats() async throws -> StatsDTO {
        try await request("/stats")
    }

    public func fetchForecast(days: Int = 7) async throws -> ForecastDTO {
        try await request("/stats/forecast?days=\(days)")
    }

    /// Lightweight health check for API reachability.
    public func ping() async -> Bool {
        struct Health: Decodable { let status: String }
        do {
            var req = URLRequest(url: try url("/"))
            req.httpMethod = "GET"
            req.timeoutInterval = 2
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return false
            }
            let health = try decoder.decode(Health.self, from: data)
            return health.status == "ok"
        } catch {
            return false
        }
    }

    public func fetchCalibration(subjectId: Int? = nil) async throws -> CalibrationDTO {
        var path = "/stats/calibration"
        if let subjectId {
            path += "?subject_id=\(subjectId)"
        }
        return try await request(path)
    }
}

private enum APIDateParser {
    private static let isoFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fallbackFormats = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss",
    ]

    static func parse(_ value: String) -> Date? {
        if let date = isoFractional.date(from: value) { return date }
        if let date = isoStandard.date(from: value) { return date }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        for format in fallbackFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}

private struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}
