//
//  BlockPage.swift
//  Pure Path Browser
//
//  Created by Rafan Syed on 10/2/26.
//

import Foundation

enum BlockPage {
    static func html(reason: String, url: URL?, lockdownUntil: Date? = nil) -> String {
        let shown = url.map { ($0.host ?? "") + $0.path } ?? ""

        var countdown = ""
        if let until = lockdownUntil {
            let ms = Int(until.timeIntervalSince1970 * 1000)
            countdown = """
            <div class="countdown-block">
                <div class="detail-label">Lockdown Remaining</div>
                <div id="cd" class="countdown-timer">--:--</div>
            </div>
            <script>
            const until = \(ms);
            function tick() {
              const r = Math.max(0, Math.floor((until - Date.now()) / 1000));
              document.getElementById('cd').textContent =
                String(Math.floor(r / 60)).padStart(2, '0') + ':' + String(r % 60).padStart(2, '0');
            }
            tick(); setInterval(tick, 1000);
            </script>
            """
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>Blocked — Pure Path</title>
        <style>
          :root {
            --tan-bg: #EFE6D6;
            --card: #FBF6EC;
            --ink: #2B2621;
            --ink-soft: #5C5348;
            --moss: #6B7A5E;
            --moss-dark: #4F5C45;
            --clay: #A97452;
            --line: #DCD0BC;
          }
          * { box-sizing: border-box; }
          html, body { margin: 0; padding: 0; height: 100%; }
          body {
            background: var(--tan-bg); color: var(--ink);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            display: flex; align-items: center; justify-content: center; min-height: 100vh; padding: 24px;
          }
          .card {
            max-width: 560px; width: 100%; background: var(--card); border: 1px solid var(--line);
            border-radius: 18px; padding: 48px 44px;
            box-shadow: 0 1px 2px rgba(43,38,33,0.04), 0 12px 32px rgba(43,38,33,0.06);
          }
          .mark {
            width: 44px; height: 44px; border-radius: 50%; background: var(--moss);
            display: flex; align-items: center; justify-content: center; margin-bottom: 28px;
            animation: breathe 4s ease-in-out infinite;
          }
          @keyframes breathe { 0%,100% { transform: scale(1); opacity: 0.85; } 50% { transform: scale(1.12); opacity: 1; } }
          .mark svg { width: 20px; height: 20px; stroke: #FBF6EC; }
          h1 {
            font-family: Georgia, "Iowan Old Style", "Palatino Linotype", serif;
            font-size: 28px; line-height: 1.25; font-weight: 600; margin: 0 0 12px; color: var(--ink);
          }
          .sub { font-size: 15px; line-height: 1.6; color: var(--ink-soft); margin: 0 0 28px; }
          .detail-block {
            background: rgba(107,122,94,0.08); border: 1px solid rgba(107,122,94,0.18);
            border-radius: 12px; padding: 16px 18px; margin-bottom: 24px;
          }
          .detail-row { display: flex; justify-content: space-between; gap: 16px; font-size: 13px; padding: 6px 0; }
          .detail-row + .detail-row { border-top: 1px solid rgba(107,122,94,0.14); }
          .detail-label {
            color: var(--moss-dark); font-weight: 600; letter-spacing: 0.02em; text-transform: uppercase;
            font-size: 11px; white-space: nowrap; padding-top: 2px;
          }
          .detail-value { color: var(--ink); text-align: right; word-break: break-word; font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace; font-size: 12.5px; }
          .countdown-block {
            background: rgba(169,116,82,0.08); border: 1px solid rgba(169,116,82,0.2);
            border-radius: 12px; padding: 16px 18px; text-align: center; margin-bottom: 24px;
          }
          .countdown-timer {
            font-size: 36px; font-weight: 700; color: var(--clay);
            font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace; margin-top: 6px;
          }
          .footer-note { margin-top: 28px; font-size: 12px; color: var(--ink-soft); opacity: 0.75; text-align: center; }
        </style>
        </head>
        <body>
          <div class="card">
            <div class="mark">
              <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M12 3l7 3v6c0 4.5-3 8-7 9-4-1-7-4.5-7-9V6l7-3z"></path>
              </svg>
            </div>
            <h1>This one's not part of the plan.</h1>
            <p class="sub">You set this boundary for a reason. It's still holding.</p>

            <div class="detail-block">
              \(shown.isEmpty ? "" : """
              <div class="detail-row">
                <span class="detail-label">Site</span>
                <span class="detail-value">\(escape(shown))</span>
              </div>
              """)
              <div class="detail-row">
                <span class="detail-label">Reason</span>
                <span class="detail-value">\(escape(reason))</span>
              </div>
            </div>

            \(countdown)

            <p class="footer-note">Pure Path — this list was set by you, for you.</p>
          </div>
        </body>
        </html>
        """
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
