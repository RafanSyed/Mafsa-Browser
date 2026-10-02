//
//  APIClient.swift
//  Pure Path Browser
//
//  Created by Rafan Syed on 10/2/26.
//

import Foundation

enum APIConfig {
    static let baseURL = "https://purepathbackend.onrender.com"
    static let authToken = ""   // must match the backend's API_AUTH_TOKEN
}

@MainActor
enum APIClient {
    struct APIError: Error { let message: String }

    private static let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 20
        return URLSession(configuration: c)
    }()
    
    // Optional filter: "BLOCKED" | "OKAY" | "SAFE". Omit for every tracked domain.
    static func listDomains(filter: String? = nil) async throws -> [Any] {
        var path = "/domains"
        if let filter {
            let enc = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? filter
            path += "?filter=\(enc)"
        }
        let json = try await request(path)
        return json["domains"] as? [Any] ?? []
    }

    static func updateDomainFilter(_ domain: String, filter: String) async throws {
        _ = try await request("/domains", method: "PATCH",
                              body: ["domain": domain, "filter": filter], authed: true)
    }

    // Same as the extension: try add first, and if it already exists, update it.
    static func blockDomain(_ domain: String) async throws {
        do { try await addDomain(domain, filter: "BLOCKED") }
        catch { try await updateDomainFilter(domain, filter: "BLOCKED") }
    }
    
    
    static func normalizeDomain(_ url: URL) -> String {
        guard let host = url.host?.lowercased() else { return "" }
        if host.range(of: #"^\d+\.\d+\.\d+\.\d+$"#, options: .regularExpression) != nil { return host }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private static func request(_ path: String,
                                method: String = "GET",
                                body: [String: String]? = nil,
                                authed: Bool = false) async throws -> [String: Any] {
        guard let url = URL(string: APIConfig.baseURL + path) else { throw APIError(message: "Bad URL") }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authed { req.setValue("Bearer \(APIConfig.authToken)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let (data, resp) = try await session.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw APIError(message: (json["error"] as? String) ?? "\(path) failed with status \(status)")
        }
        return json
    }

    // "SAFE" | "OKAY" | "BLOCKED" | nil (unknown). Throws if the backend is unreachable.
    static func lookupDomain(_ domain: String) async throws -> String? {
        let enc = domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? domain
        let json = try await request("/domains/lookup?domain=\(enc)")
        guard (json["found"] as? Bool) == true else { return nil }
        return json["filter"] as? String
    }

    static func addDomain(_ domain: String, filter: String) async throws {
        _ = try await request("/domains", method: "POST",
                              body: ["domain": domain, "filter": filter], authed: true)
    }

    static func classifySearchQuery(_ query: String) async -> String {
        do {
            let json = try await request("/classify-search", method: "POST", body: ["query": query])
            return (json["classification"] as? String) ?? "SAFE"
        } catch {
            print("[Pure Path] classifySearchQuery failed:", error)
            return "UNKNOWN"
        }
    }

    // AI says SAFE/BLOCK -> maps to OKAY/BLOCKED
    static func classifyWebsite(domain: String, url: String) async -> String {
        do {
            let json = try await request("/classify-website", method: "POST",
                                         body: ["domain": domain, "url": url])
            return (json["classification"] as? String) == "BLOCK" ? "BLOCKED" : "OKAY"
        } catch {
            print("[Pure Path] classifyWebsite failed:", error)
            return "OKAY"
        }
    }

    static func parseURL(pathQuery: String, domain: String) async -> String? {
        do {
            let json = try await request("/parse-url", method: "POST",
                                         body: ["domain": domain, "pathQuery": pathQuery])
            return json["classification"] as? String
        } catch {
            print("[Pure Path] parseURL failed:", error)
            return nil
        }
    }

    static func classifyYoutube(_ url: String) async -> String {
        do {
            let json = try await request("/classify-youtube", method: "POST", body: ["url": url])
            return (json["classification"] as? String) ?? "BLOCK"
        } catch {
            print("[Pure Path] classifyYoutube failed:", error)
            return "BLOCK"   // fail-safe for YouTube, same as the extension
        }
    }
}
