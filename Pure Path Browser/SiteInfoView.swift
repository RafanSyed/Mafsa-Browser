//
//  SiteInfoView.swift
//  Pure Path Browser
//
//  Created by Rafan Syed on 10/2/26.
//

import SwiftUI

// MARK: - Theme (from popup.css)

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Theme {
    static let tan = Color(hex: 0xEFE6D6)
    static let card = Color(hex: 0xFBF6EC)
    static let ink = Color(hex: 0x2B2621)
    static let inkSoft = Color(hex: 0x5C5348)
    static let moss = Color(hex: 0x6B7A5E)
    static let mossDark = Color(hex: 0x4F5C45)
    static let clay = Color(hex: 0xA97452)
    static let danger = Color(hex: 0xB4432E)
    static let dangerDark = Color(hex: 0x93341F)
    static let line = Color(hex: 0xDCD0BC)
}

// MARK: - Popup

struct SiteInfoView: View {
    @ObservedObject var tab: BrowserTab
    @Environment(\.dismiss) private var dismiss

    private enum Phase { case checking, ready, offline }

    @State private var phase: Phase = .checking
    @State private var filter: String?          // "SAFE" | "OKAY" | "BLOCKED" | nil (untracked)
    @State private var blockedCount: String = "—"
    @State private var totalCount: String = "—"
    @State private var showConfirm = false
    @State private var working = false
    @State private var toast: String?

    private var pageURL: URL? { URL(string: tab.address) }
    private var domain: String { pageURL.map { APIClient.normalizeDomain($0) } ?? "" }

    private var canBlock: Bool {
        !domain.isEmpty && phase != .checking && !working && filter != "BLOCKED" && filter != "SAFE"
    }

    private var blockTitle: String {
        if domain.isEmpty { return "Invalid domain" }
        if working { return "Blocking…" }
        if filter == "BLOCKED" { return "Already blocked" }
        if filter == "SAFE" { return "Permanently safe — can't block here" }
        return "Block this site"
    }

    var body: some View {
        ZStack {
            Theme.tan.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header
                card
                Spacer(minLength: 0)
            }
            .padding(18)
        }
        .task { await load() }
    }

    // MARK: Pieces

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Theme.moss).frame(width: 26, height: 26)
                Image(systemName: "shield")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.card)
            }
            Text("Pure Path")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.ink)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CURRENT SITE")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(Theme.inkSoft)
                .padding(.bottom, 4)

            Text(domain.isEmpty ? "—" : domain)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Theme.ink)
                .padding(.bottom, 12)

            statusBadge.padding(.bottom, 16)

            if showConfirm { confirmBox } else { blockButton }

            HStack(spacing: 8) {
                stat(blockedCount, "Blocked")
                stat(totalCount, "Tracked")
            }
            .padding(.top, 14)

            if let toast {
                Text(toast)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.mossDark)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Theme.moss.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder private var statusBadge: some View {
        if phase == .checking {
            badge("Checking…", fg: Theme.inkSoft, bg: Theme.inkSoft.opacity(0.1))
        } else if phase == .offline {
            badge("⚠️ Backend offline", fg: Theme.inkSoft, bg: Theme.inkSoft.opacity(0.1))
        } else {
            switch filter {
            case "BLOCKED": badge("🚫 Blocked", fg: Theme.dangerDark, bg: Theme.danger.opacity(0.12))
            case "SAFE":    badge("✅ Permanently safe", fg: Theme.mossDark, bg: Theme.moss.opacity(0.14))
            case "OKAY":    badge("🟡 Okay (path checked)", fg: Theme.clay, bg: Theme.clay.opacity(0.14))
            default:        badge("❔ Not tracked yet", fg: Theme.inkSoft, bg: Theme.inkSoft.opacity(0.1))
            }
        }
    }

    private func badge(_ text: String, fg: Color, bg: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var blockButton: some View {
        Button { showConfirm = true } label: {
            Text(blockTitle)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(canBlock ? Theme.card : Theme.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(canBlock ? Theme.danger : Theme.inkSoft.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(!canBlock)
    }

    private var confirmBox: some View {
        VStack(spacing: 10) {
            Text("Block this site?")
                .font(.system(size: 12.5))
                .foregroundColor(Theme.ink)
            HStack(spacing: 8) {
                Button { Task { await blockNow() } } label: {
                    Text("Yes, block")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Theme.card)
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(Theme.danger)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button { showConfirm = false } label: {
                    Text("Cancel")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Theme.inkSoft)
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(Theme.inkSoft.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Theme.danger.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.danger.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Theme.ink)
            Text(label.uppercased())
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Theme.ink.opacity(0.03))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Actions

    private func load() async {
        async let stats: Void = loadStats()

        guard !domain.isEmpty else {
            phase = .ready
            await stats
            return
        }
        do {
            filter = try await APIClient.lookupDomain(domain)
            phase = .ready
        } catch {
            phase = .offline
        }
        await stats
    }

    private func loadStats() async {
        do {
            async let blocked = APIClient.listDomains(filter: "BLOCKED")
            async let all = APIClient.listDomains()
            let (b, a) = try await (blocked, all)
            blockedCount = String(b.count)
            totalCount = String(a.count)
        } catch {
            blockedCount = "—"
            totalCount = "—"
        }
    }

    private func blockNow() async {
        showConfirm = false
        working = true
        defer { working = false }

        do {
            try await APIClient.blockDomain(domain)
            filter = "BLOCKED"
            await flash("\"\(domain)\" has been blocked")
            await loadStats()

            // Replace the page with the block page (doesn't count toward lockdown)
            if let url = pageURL {
                tab.show(.block(reason: "Manually blocked via Pure Path"), for: url)
            }
            try? await Task.sleep(nanoseconds: 900_000_000)
            dismiss()
        } catch {
            await flash("Failed to block — check backend connection")
        }
    }

    private func flash(_ message: String) async {
        toast = message
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if toast == message { toast = nil }
        }
    }
}
