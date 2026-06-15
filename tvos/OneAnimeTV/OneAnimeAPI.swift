import CryptoKit
import Foundation

enum OneAnimeAPI {
    static let animeList = URL(string: "https://d1zquzjgwo9yb.cloudfront.net/")!
    static let animeBaseURL = URL(string: "https://anime1.me")!
    static let videoAPI = URL(string: "https://v.anime1.me/api")!
    static let dandanAPIBaseURL = URL(string: "https://api.dandanplay.net")!
    static let userAgent = "Predidit/oneAnime/1.4.5 (AppleTV; tvOS)"
    static let dandanAppID = "kvpx7qkqjh"
    static let dandanAppSecret = "rABUaBLqdz7aCSi3fe88ZDj2gwga9Vax"

    static func animePageURL(category id: Int) -> URL {
        URL(string: "https://anime1.me/?cat=\(id)")!
    }
}

struct AnimeInfo: Codable, Hashable {
    let id: Int
    let name: String
    let episode: String
    let year: String
    let season: String
    let subtitle: String

    init?(json: Any) {
        guard
            let row = json as? [Any],
            row.count >= 6,
            let id = row[0] as? Int,
            id > 0
        else { return nil }

        self.id = id
        name = row[1] as? String ?? ""
        episode = row[2] as? String ?? ""
        year = row[3] as? String ?? ""
        season = row[4] as? String ?? ""
        subtitle = row[5] as? String ?? ""
    }
}

struct AnimeEpisode: Hashable {
    let number: Int
    let token: String

    var title: String {
        "第 \(number) 集"
    }
}

struct VideoResource {
    let url: URL
    let cookie: String
}

struct DanmakuComment: Hashable {
    let time: TimeInterval
    let text: String
}

enum OneAnimeError: LocalizedError {
    case invalidResponse
    case noVideoToken
    case noVideoSource

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Server response is not valid."
        case .noVideoToken:
            return "No video token was found on this anime page."
        case .noVideoSource:
            return "No playable video source was returned."
        }
    }
}

final class OneAnimeService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchAnimeList() async throws -> [AnimeInfo] {
        let (data, _) = try await session.data(from: OneAnimeAPI.animeList)
        let payload = try JSONSerialization.jsonObject(with: data)
        guard let rows = payload as? [Any] else {
            throw OneAnimeError.invalidResponse
        }
        return rows.compactMap(AnimeInfo.init(json:))
    }

    func resolveVideo(for anime: AnimeInfo, episode: Int = 1) async throws -> VideoResource {
        let episodes = try await fetchEpisodes(for: anime)
        guard !episodes.isEmpty else {
            throw OneAnimeError.noVideoToken
        }
        let safeEpisode = min(max(episode, 1), episodes.count)
        return try await resolveVideo(token: episodes[safeEpisode - 1].token)
    }

    func fetchEpisodes(for anime: AnimeInfo) async throws -> [AnimeEpisode] {
        let pageURL = OneAnimeAPI.animePageURL(category: anime.id)
        let html = try await fetchString(pageURL)
        var tokens = videoTokens(in: html)
        if tokens.isEmpty {
            throw OneAnimeError.noVideoToken
        }
        if firstEntryTitle(in: html)?.hasSuffix("[01]") == true {
            tokens.reverse()
        }

        return (1...tokens.count).map { number in
            AnimeEpisode(number: number, token: tokens[tokens.count - number])
        }
    }

    func resolveVideo(token: String) async throws -> VideoResource {
        try await fetchVideoSource(token: token)
    }

    func fetchDanmaku(title: String, episode: Int) async throws -> [DanmakuComment] {
        let bangumiID = try await fetchDandanBangumiID(title: title)
        guard bangumiID != 100000 else {
            return []
        }
        return try await fetchDandanComments(bangumiID: bangumiID, episode: episode)
    }

    private func fetchString(_ url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(OneAnimeAPI.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func fetchVideoSource(token: String) async throws -> VideoResource {
        var request = URLRequest(url: OneAnimeAPI.videoAPI)
        request.httpMethod = "POST"
        request.httpBody = "d=\(token)".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(OneAnimeAPI.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(OneAnimeAPI.animeBaseURL.absoluteString, forHTTPHeaderField: "Referer")

        let (data, response) = try await session.data(for: request)
        let payload = try JSONSerialization.jsonObject(with: data)
        guard
            let object = payload as? [String: Any],
            let sources = object["s"] as? [[String: Any]],
            let rawSource = sources.first?["src"] as? String
        else { throw OneAnimeError.noVideoSource }

        let source = rawSource.hasPrefix("http") ? rawSource : "https:\(rawSource)"
        guard let url = URL(string: source) else {
            throw OneAnimeError.noVideoSource
        }

        let headers = (response as? HTTPURLResponse)?.allHeaderFields
        return VideoResource(url: url, cookie: videoCookie(from: headers?["Set-Cookie"]))
    }

    private func fetchDandanBangumiID(title: String) async throws -> Int {
        let path = "/api/v2/search/anime"
        var components = URLComponents(url: dandanURL(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "keyword", value: title)]
        guard let url = components?.url else {
            throw OneAnimeError.invalidResponse
        }

        let data = try await fetchDandanData(url: url, path: path)
        let payload = try JSONSerialization.jsonObject(with: data)
        guard
            let object = payload as? [String: Any],
            let animes = object["animes"] as? [[String: Any]]
        else { throw OneAnimeError.invalidResponse }

        return animes
            .compactMap { $0["animeId"] as? Int }
            .filter { $0 >= 8692 }
            .min() ?? 100000
    }

    private func fetchDandanComments(bangumiID: Int, episode: Int) async throws -> [DanmakuComment] {
        let path = "/api/v2/comment/\(bangumiID)\(String(format: "%04d", episode))"
        var components = URLComponents(url: dandanURL(path: path), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "withRelated", value: "true")]
        guard let url = components?.url else {
            throw OneAnimeError.invalidResponse
        }

        let data = try await fetchDandanData(url: url, path: path)
        let payload = try JSONSerialization.jsonObject(with: data)
        guard
            let object = payload as? [String: Any],
            let comments = object["comments"] as? [[String: Any]]
        else { return [] }

        return comments.compactMap { comment in
            guard
                let position = comment["p"] as? String,
                let text = comment["m"] as? String,
                let seconds = Double(position.split(separator: ",").first ?? "")
            else { return nil }
            return DanmakuComment(time: seconds, text: text)
        }
    }

    private func fetchDandanData(url: URL, path: String) async throws -> Data {
        let timestamp = Int(Date().timeIntervalSince1970)
        var request = URLRequest(url: url)
        request.setValue(OneAnimeAPI.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("1", forHTTPHeaderField: "X-Auth")
        request.setValue(OneAnimeAPI.dandanAppID, forHTTPHeaderField: "X-AppId")
        request.setValue(String(timestamp), forHTTPHeaderField: "X-Timestamp")
        request.setValue(dandanSignature(path: path, timestamp: timestamp), forHTTPHeaderField: "X-Signature")
        let (data, _) = try await session.data(for: request)
        return data
    }

    private func dandanURL(path: String) -> URL {
        URL(string: OneAnimeAPI.dandanAPIBaseURL.absoluteString + path)!
    }

    private func dandanSignature(path: String, timestamp: Int) -> String {
        let text = OneAnimeAPI.dandanAppID + String(timestamp) + path + OneAnimeAPI.dandanAppSecret
        let digest = SHA256.hash(data: Data(text.utf8))
        return Data(digest).base64EncodedString()
    }

    private func videoTokens(in html: String) -> [String] {
        matches(in: html, pattern: #"data-apireq\s*=\s*"([^"]+)""#)
    }

    private func firstEntryTitle(in html: String) -> String? {
        matches(in: html, pattern: #"<[^>]*class="[^"]*entry-title[^"]*"[^>]*>(.*?)</[^>]+>"#)
            .first?
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let capture = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return String(text[capture])
        }
    }

    private func videoCookie(from header: Any?) -> String {
        let values: [String]
        if let header = header as? String {
            values = [header]
        } else if let header = header as? [String] {
            values = header
        } else {
            values = []
        }

        return values
            .joined(separator: "; ")
            .split(separator: ",")
            .map(String.init)
            .flatMap { $0.split(separator: ";").map(String.init) }
            .compactMap { part -> String? in
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                guard
                    let name = trimmed.split(separator: "=").first,
                    ["e", "p", "h"].contains(String(name)) || name.hasPrefix("_ga")
                else { return nil }
                return trimmed
            }
            .joined(separator: "; ")
    }
}

actor AnimeLibrary {
    static let shared = AnimeLibrary()

    private let service = OneAnimeService()
    private var cachedList: [AnimeInfo]?

    func fetchAnimeList() async throws -> [AnimeInfo] {
        if let cachedList {
            return cachedList
        }
        return try await reloadAnimeList()
    }

    func reloadAnimeList() async throws -> [AnimeInfo] {
        let result = try await service.fetchAnimeList()
        cachedList = result
        return result
    }
}
