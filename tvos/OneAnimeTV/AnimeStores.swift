import Foundation

struct AnimeHistoryRecord: Codable, Hashable {
    let anime: AnimeInfo
    let episodeNumber: Int
    let watchedAt: Date

    var title: String {
        anime.name
    }

    var subtitle: String {
        "\(episodeTitle) · \(DateFormatter.oneAnimeHistory.string(from: watchedAt))"
    }

    var episodeTitle: String {
        "第 \(episodeNumber) 集"
    }
}

enum HistoryStore {
    private static let key = "oneAnime.tv.history"
    private static let limit = 80

    static func all() -> [AnimeHistoryRecord] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let records = try? JSONDecoder().decode([AnimeHistoryRecord].self, from: data)
        else {
            return []
        }
        return records.sorted { $0.watchedAt > $1.watchedAt }
    }

    static func add(anime: AnimeInfo, episode: AnimeEpisode) {
        var records = all().filter {
            !($0.anime.id == anime.id && $0.episodeNumber == episode.number)
        }
        records.insert(AnimeHistoryRecord(anime: anime, episodeNumber: episode.number, watchedAt: Date()), at: 0)
        save(Array(records.prefix(limit)))
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func save(_ records: [AnimeHistoryRecord]) {
        guard let data = try? JSONEncoder().encode(records) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}

enum FollowStore {
    private static let key = "oneAnime.tv.follows"

    static func all() -> [AnimeInfo] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let records = try? JSONDecoder().decode([AnimeInfo].self, from: data)
        else {
            return []
        }
        return records.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func contains(_ anime: AnimeInfo) -> Bool {
        all().contains { $0.id == anime.id }
    }

    @discardableResult
    static func toggle(_ anime: AnimeInfo) -> Bool {
        var records = all()
        if let index = records.firstIndex(where: { $0.id == anime.id }) {
            records.remove(at: index)
            save(records)
            return false
        }
        records.insert(anime, at: 0)
        save(records)
        return true
    }

    private static func save(_ records: [AnimeInfo]) {
        guard let data = try? JSONEncoder().encode(records) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }
}

extension DateFormatter {
    static let oneAnimeHistory: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
}
