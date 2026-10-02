//
//  StartPageView.swift
//  Masfa
//
//  Created by Rafan Syed on 10/2/26.
//

import SwiftUI

struct StartPageView: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject private var favorites = FavoritesStore.shared

    private let columns = [GridItem(.adaptive(minimum: 84), spacing: 18)]

    // Soft, light night-blue palette (tweak these to taste)
    private let background = Color(red: 0.84, green: 0.90, blue: 0.98)      // #D6E6FA
    private let tileFill = Color.white.opacity(0.85)
    private let tileBorder = Color(red: 0.72, green: 0.80, blue: 0.92)
    private let labelSoft = Color(red: 0.30, green: 0.38, blue: 0.52)
    private let labelStrong = Color(red: 0.12, green: 0.18, blue: 0.30)
    private let accent = Color(red: 0.22, green: 0.36, blue: 0.62)

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("FAVORITES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(labelSoft)

                    LazyVGrid(columns: columns, spacing: 22) {
                        ForEach(favorites.items) { fav in
                            tile(fav)
                        }
                    }

                    if favorites.items.isEmpty {
                        Text("Tap the heart in the address bar on any site to add it here.")
                            .font(.system(size: 13))
                            .foregroundColor(labelSoft)
                    }
                }
                .padding(20)
            }
        }
    }

    private func tile(_ fav: Favorite) -> some View {
        Button { tab.go(fav.urlString) } label: {
            VStack(spacing: 8) {
                icon(for: fav)
                    .frame(width: 60, height: 60)
                    .background(tileFill)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(tileBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(fav.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(labelStrong)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { favorites.remove(fav) } label: {
                Label("Remove", systemImage: "heart.slash")
            }
        }
    }

    @ViewBuilder
    private func icon(for fav: Favorite) -> some View {
        let host = URL(string: fav.urlString)?.host ?? ""
        let faviconURL = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=128")

        AsyncImage(url: faviconURL) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit().padding(12)
            } else {
                Text(String(fav.name.prefix(1)).uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(accent)
            }
        }
    }
}
