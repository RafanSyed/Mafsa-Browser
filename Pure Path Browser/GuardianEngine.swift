//
//  GuardianEngine.swift
//  Pure Path Browser
//
//  Created by Rafan Syed on 10/2/26.
//

import Foundation

enum Verdict {
    case allow
    case block(reason: String)
    case lockdown(until: Date)
}

@MainActor
final class GuardianEngine {
    static let shared = GuardianEngine()

    // Tunables
    private let hitsToTrigger = 3
    private let lockdownDuration: TimeInterval = 30 * 60   // drop to 60 while testing
    private let failOpenWhenBackendDown = true             // matches the extension today

    // Lockdown state
    private let lockdownKey = "lockdownUntil"
    private var lockdownUntilTs: TimeInterval
    private var blockHits = 0
    private var currentWindowMinute = -1
    private var recentBlocks: [String: Date] = [:]

    // Precompiled keyword regexes
    private var hardRegexes: [(String, NSRegularExpression)] = []
    private var softRegexes: [(String, NSRegularExpression)] = []

    private init() {
        lockdownUntilTs = UserDefaults.standard.double(forKey: lockdownKey)
        hardRegexes = Keywords.hardBlock.compactMap { Self.compile($0) }
        softRegexes = Keywords.keywords.compactMap { kw in
            if Keywords.hardBlock.contains(kw) || Keywords.exceptions.contains(kw) { return nil }
            return Self.compile(kw)
        }
    }

    var lockdownUntil: Date { Date(timeIntervalSince1970: lockdownUntilTs) }
    private var isLockedDown: Bool { Date().timeIntervalSince1970 < lockdownUntilTs }

    // MARK: - Main entry point

    func check(_ url: URL) async -> Verdict {
        clearExpiredLockdown()
        if isLockedDown { return .lockdown(until: lockdownUntil) }

        let rootDomain = APIClient.normalizeDomain(url)
        guard !rootDomain.isEmpty else { return .allow }
        let pq = pathQuery(of: url)

        // 1. YouTube video
        if (rootDomain == "youtube.com" || rootDomain == "m.youtube.com") && pq.contains("watch") {
            let result = await APIClient.classifyYoutube(url.absoluteString)
            return result == "BLOCK" ? blocked("YouTube video restricted", url: url) : .allow
        }

        // 2. Search pages
        if isSearchURL(url) {
            let query = searchQuery(from: url)
            if query.isEmpty { return .allow }

            if let kw = matchKeyword(query) {
                return blocked("Search matched keyword: \(kw)", url: url)
            }
            let ai = await APIClient.classifySearchQuery(query)
            return ai == "BLOCK" ? blocked("AI blocked search", url: url) : .allow
        }

        // 3. Standard website visits
        let filter: String
        do {
            if let found = try await APIClient.lookupDomain(rootDomain) {
                filter = found
            } else {
                filter = await APIClient.classifyWebsite(domain: rootDomain, url: url.absoluteString)
                do { try await APIClient.addDomain(rootDomain, filter: filter) }
                catch { print("[Pure Path] Could not persist \(rootDomain):", error) }
            }
        } catch {
            print("[Pure Path] Domain lookup failed:", error)
            return failOpenWhenBackendDown
                ? .allow
                : .block(reason: "Couldn't verify this site (backend unreachable)")
        }

        if filter == "BLOCKED" { return blocked("Domain is blocked", url: url) }
        if filter == "SAFE" { return .allow }

        // OKAY: domain is fine, still check path/query
        if !pq.isEmpty {
            if let kw = matchKeyword(pq) {
                return blocked("Path matched keyword: \(kw)", url: url)
            }
            if await APIClient.parseURL(pathQuery: pq, domain: rootDomain) == "BLOCK" {
                return blocked("AI blocked URL path content", url: url)
            }
        }
        return .allow
    }

    // MARK: - Lockdown

    private func clearExpiredLockdown() {
        if lockdownUntilTs != 0 && Date().timeIntervalSince1970 >= lockdownUntilTs {
            lockdownUntilTs = 0
            UserDefaults.standard.removeObject(forKey: lockdownKey)
            print("[Pure Path] 🔓 Lockdown expired")
        }
    }

    private func blocked(_ reason: String, url: URL) -> Verdict {
        let now = Date()
        let key = url.absoluteString
        if let prev = recentBlocks[key], now.timeIntervalSince(prev) < 3 {
            return .block(reason: reason)          // same URL again: don't double-count
        }
        recentBlocks[key] = now
        recentBlocks = recentBlocks.filter { now.timeIntervalSince($0.value) < 30 }
        print("[Pure Path] 🚫 \(reason)")
        return recordBlockHit() ? .lockdown(until: lockdownUntil) : .block(reason: reason)
    }

    // Returns true if this hit triggered lockdown
    private func recordBlockHit() -> Bool {
        let now = Date().timeIntervalSince1970
        let thisMinute = Int(now / 60)
        if thisMinute != currentWindowMinute {
            currentWindowMinute = thisMinute
            blockHits = 0
        }
        blockHits += 1
        print("[Pure Path] 📊 Block hits this minute: \(blockHits)/\(hitsToTrigger)")

        if blockHits >= hitsToTrigger {
            lockdownUntilTs = now + lockdownDuration
            UserDefaults.standard.set(lockdownUntilTs, forKey: lockdownKey)
            blockHits = 0
            currentWindowMinute = -1
            print("[Pure Path] 🔒 LOCKDOWN MODE TRIGGERED")
            return true
        }
        return false
    }

    // MARK: - Keyword matching

    static func normalizeText(_ text: String) -> String {
        var s = text.lowercased().decomposedStringWithCompatibilityMapping
        s = s.replacingOccurrences(of: "[\\u0300-\\u036f]", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "[_\\-.]", with: " ", options: .regularExpression)
        for (from, to) in [("0", "o"), ("1", "i"), ("3", "e"), ("4", "a"), ("5", "s"), ("7", "t")] {
            s = s.replacingOccurrences(of: from, with: to)
        }
        s = s.replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func compile(_ keyword: String) -> (String, NSRegularExpression)? {
        let norm = normalizeText(keyword)
        guard !norm.isEmpty else { return nil }   // an empty pattern would match everything
        let pattern = "(?<![a-z0-9])\(NSRegularExpression.escapedPattern(for: norm))(?![a-z0-9])"
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        return (keyword, re)
    }

    private func matchKeyword(_ text: String) -> String? {
        guard !text.isEmpty else { return nil }
        let n = Self.normalizeText(text)
        let range = NSRange(n.startIndex..., in: n)
        for (kw, re) in hardRegexes where re.firstMatch(in: n, range: range) != nil { return kw }
        for (kw, re) in softRegexes where re.firstMatch(in: n, range: range) != nil { return kw }
        return nil
    }

    // MARK: - URL helpers

    private func isSearchURL(_ url: URL) -> Bool {
        guard let h = url.host?.lowercased() else { return false }
        let engines = ["google.com", "www.google.com", "bing.com", "www.bing.com"]
        return engines.contains(h) && url.path == "/search"
    }

    private func searchQuery(from url: URL) -> String {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "q" })?.value ?? ""
    }

    private func pathQuery(of url: URL) -> String {
        guard let c = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return "" }
        var p = c.percentEncodedPath
        if p.hasPrefix("/") { p.removeFirst() }
        if let q = c.percentEncodedQuery, !q.isEmpty { p += "?" + q }
        return p.trimmingCharacters(in: .whitespaces)
    }
}
