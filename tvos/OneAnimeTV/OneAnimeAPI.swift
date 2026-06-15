import Foundation

enum OneAnimeAPI {
    static let animeList = URL(string: "https://d1zquzjgwo9yb.cloudfront.net/")!
    static let animeBaseURL = URL(string: "https://anime1.me")!
    static let videoAPI = URL(string: "https://v.anime1.me/api")!
    static let userAgent = "Predidit/oneAnime/1.4.5 (AppleTV; tvOS)"

    static func animePageURL(category id: Int) -> URL {
        URL(string: "https://anime1.me/?cat=\(id)")!
    }
}

struct AnimeInfo: Hashable {
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

struct VideoResource {
    let url: URL
    let cookie: String
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
        let pageURL = OneAnimeAPI.animePageURL(category: anime.id)
        let html = try await fetchString(pageURL)
        var tokens = videoTokens(in: html)
        if tokens.isEmpty {
            throw OneAnimeError.noVideoToken
        }
        if firstEntryTitle(in: html)?.hasSuffix("[01]") == true {
            tokens.reverse()
        }
        let safeEpisode = min(max(episode, 1), tokens.count)
        return try await fetchVideoSource(token: tokens[tokens.count - safeEpisode])
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
        let cookie = (headers?["Set-Cookie"] as? String) ?? ""
        return VideoResource(url: url, cookie: videoCookie(from: cookie))
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

    private func videoCookie(from header: String) -> String {
        header
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
