//
//  Favorites.swift
//  Pure Path Browser
//
//  Created by Rafan Syed on 10/2/26.
//

import Foundation
import Combine

struct Favorite: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var urlString: String
}

// "https://www.YouTube.com/watch?v=1" -> "youtube.com"
private func siteKey(_ urlString: String) -> String? {
    guard let host = URL(string: urlString)?.host?.lowercased(), !host.isEmpty else { return nil }
    return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
}

@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published private(set) var items: [Favorite] = []
    private let storageKey = "favorites.v2"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Favorite].self, from: data) {
            items = saved
        } else {
            items = [
                Favorite(name: "Google", urlString: "https://www.google.com"),
                Favorite(name: "YouTube", urlString: "https://www.youtube.com"),
                Favorite(name: "Spotify", urlString: "https://open.spotify.com"),
                Favorite(name: "Kufah", urlString: "https://kufah.org"),
                Favorite(name: "IslamQA", urlString: "https://islamqa.org"),
                Favorite(name: "One Piece Chapters", urlString: "http://tcbonepiecechapters.com/"),
                Favorite(name: "ISONET", urlString: "https://www.newtampamasjid.org/prayer-schedule"),
            ]
            save()
        }
    }

    func contains(_ urlString: String) -> Bool {
        guard let key = siteKey(urlString) else { return false }
        return items.contains { siteKey($0.urlString) == key }
    }

    // Heart button: adds the site (home page of that domain) or removes it
    func toggle(_ urlString: String) {
        guard let key = siteKey(urlString) else { return }
        if let existing = items.first(where: { siteKey($0.urlString) == key }) {
            remove(existing)
            return
        }
        let labels = key.split(separator: ".")
        let base = labels.count >= 2 ? labels[labels.count - 2] : (labels.first ?? "Site")
        items.append(Favorite(name: String(base).capitalized, urlString: "https://\(key)"))
        save()
    }

    func remove(_ favorite: Favorite) {
        items.removeAll { $0.id == favorite.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
