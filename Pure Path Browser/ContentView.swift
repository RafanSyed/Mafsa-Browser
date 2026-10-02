import SwiftUI
import WebKit
import Combine

// MARK: - WebView wrapper (macOS + iOS)

#if os(macOS)
struct BrowserView: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ v: WKWebView, context: Context) {}
}
#else
struct BrowserView: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ v: WKWebView, context: Context) {}
}
#endif

// MARK: - One tab

@MainActor
final class BrowserTab: NSObject, ObservableObject, Identifiable,
                        WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    let id = UUID()
    let webView: WKWebView

    @Published var address = ""
    @Published var title = "New Tab"
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var showStart = true      // true = show the favorites page instead of the web view

    // Set by BrowserModel
    var onOpenNewTab: ((URLRequest) -> Void)?
    var onLockdown: ((Date) -> Void)?

    private var cancellables = Set<AnyCancellable>()

    // Reports client-side URL changes (YouTube etc.) back to Swift
    private static let spaScript = """
    (function() {
      let last = location.href;
      function check() {
        if (location.href !== last) {
          last = location.href;
          window.webkit.messageHandlers.urlChanged.postMessage(location.href);
        }
      }
      const push = history.pushState;
      history.pushState = function() { push.apply(this, arguments); check(); };
      const replace = history.replaceState;
      history.replaceState = function() { replace.apply(this, arguments); check(); };
      window.addEventListener('popstate', check);
      window.addEventListener('hashchange', check);
      setInterval(check, 500);
    })();
    """

    // YouTube: removes Shorts + comments (and the extras in SETTINGS below).
    // NOTE: uses textContent, not innerHTML. YouTube enforces Trusted Types,
    // so innerHTML assignments throw and kill the script.
    private static let youtubeScript = #"""
    (function () {
      if (!/(^|\.)youtube\.com$/.test(location.hostname)) return;
      if (window.__purePathYT) return;
      window.__purePathYT = true;

      const SETTINGS = {
        hideComments: true,
        hideRelated: true,
        blurThumbnails: true,
        useIntentGateOnHome: true,
        allowContinueAnyway: true,
        gateTitle: "Pause for 3 seconds.",
        gateBody: "Use YouTube intentionally: search for exactly what you need, or go to Subscriptions.",
        useIntentGateOnHome: false,
      };

      let gateDismissedForUrl = null;
      const dismissGateForCurrentUrl = () => (gateDismissedForUrl = location.href);
      const isGateDismissedForCurrentUrl = () => gateDismissedForUrl === location.href;
      const isYouTubeHome = () => location.pathname === "/";

      // Force search filter to Videos only (removes Shorts from search results)
      function enforceVideoSearchFilter() {
        if (location.pathname !== "/results") return;
        const url = new URL(location.href);
        const q = url.searchParams.get("search_query");
        if (!q) return;
        const VIDEOS_SP = "EgIQAQ%3D%3D";
        if (url.searchParams.get("sp") === VIDEOS_SP) return;
        url.searchParams.set("sp", VIDEOS_SP);
        location.replace(url.toString());
      }

      // Remove Shorts elements + redirect away from /shorts pages
      function removeShorts() {
        document.querySelectorAll('a[href^="/shorts/"], a[href="/shorts"]').forEach((a) => {
          const guideEntry =
            a.closest("ytd-guide-entry-renderer") ||
            a.closest("ytd-mini-guide-entry-renderer") ||
            a.closest("ytm-pivot-bar-item-renderer");
          if (guideEntry) { guideEntry.remove(); return; }

          const tile =
            a.closest("ytd-rich-item-renderer") ||
            a.closest("ytd-video-renderer") ||
            a.closest("ytd-grid-video-renderer") ||
            a.closest("ytd-compact-video-renderer") ||
            a.closest("ytd-reel-item-renderer") ||
            a.closest("ytm-rich-item-renderer") ||
            a.closest("ytm-video-with-context-renderer") ||
            a.closest("ytm-shorts-lockup-view-model");
          if (tile) tile.remove();
        });

        document
          .querySelectorAll("ytd-reel-shelf-renderer, ytd-reel-item-renderer, ytm-reel-shelf-renderer")
          .forEach((el) => el.remove());

        document.querySelectorAll("ytd-shelf-renderer, ytd-rich-section-renderer").forEach((el) => {
          const titleEl = el.querySelector("#title") || el.querySelector("h2") || el.querySelector("yt-formatted-string");
          const title = (titleEl?.textContent || "").trim().toLowerCase();
          if (title === "shorts") el.remove();
        });

        if (location.pathname.startsWith("/shorts")) {
          location.replace("https://" + location.hostname + "/");
        }
      }
        
      // Remove Shorts tab/shelves by their visible label (mobile + desktop)
      function removeShortsByLabel() {
        document
          .querySelectorAll("ytm-pivot-bar-item-renderer, ytd-guide-entry-renderer, ytd-mini-guide-entry-renderer")
          .forEach((el) => {
            const label = (el.getAttribute("aria-label") || el.textContent || "").trim().toLowerCase();
            if (label === "shorts") el.remove();
          });

        document
          .querySelectorAll(
            "ytm-rich-section-renderer, ytm-shelf-renderer, ytm-item-section-renderer, " +
            "ytm-reel-shelf-renderer, grid-shelf-view-model, ytd-rich-section-renderer, ytd-shelf-renderer"
          )
          .forEach((el) => {
            const h = el.querySelector("h2, .shelf-title, .rich-shelf-title, #title");
            const t = (h?.textContent || "").trim().toLowerCase();
            if (t === "shorts") el.remove();
          });
      }
    
    
      function injectStyles() {
        if (document.getElementById("pure-path-yt-styles")) return;

        let css = `
          /* Shorts */
          ytd-guide-entry-renderer a[title="Shorts"],
          ytd-mini-guide-entry-renderer a[title="Shorts"],
          a[href="/shorts"],
          a[href^="/shorts/"],
          ytd-reel-shelf-renderer,
          ytd-reel-item-renderer,
          ytm-reel-shelf-renderer,
          ytm-shorts-lockup-view-model,
          ytm-shorts-lockup-view-model-v2,
          ytd-rich-shelf-renderer[is-shorts],
          ytd-rich-item-renderer:has(a[href^="/shorts/"]),
          ytd-video-renderer:has(a[href^="/shorts/"]),
          ytd-grid-video-renderer:has(a[href^="/shorts/"]),
          ytd-compact-video-renderer:has(a[href^="/shorts/"]),
          ytd-rich-section-renderer:has(a[href^="/shorts/"]),
          ytm-pivot-bar-item-renderer:has(a[href*="/shorts"]),
          ytm-rich-item-renderer:has(a[href*="/shorts"]),
          ytm-video-with-context-renderer:has(a[href*="/shorts"]),
          ytm-item-section-renderer:has(ytm-reel-shelf-renderer) {
            display: none !important;
          }

          /* End screens + hover previews */
          .ytp-endscreen-content,
          .ytp-ce-element,
          .ytp-ce-covering-overlay,
          ytd-moving-thumbnail-renderer,
          ytd-player-inline-preview-renderer,
          ytd-inline-preview-player {
            display: none !important;
          }
    
            
          /* Feed autoplay previews (only allowed on /watch) */
          html[data-pp-no-previews] video,
          html[data-pp-no-previews] ytm-inline-preview-player-renderer,
          html[data-pp-no-previews] ytm-inline-playback-renderer,
          html[data-pp-no-previews] [class*="inline-preview"] {
            display: none !important;
          }
        `;

        if (SETTINGS.hideComments) {
          css += `
            ytd-comments,
            #comments,
            ytd-comment-thread-renderer,
            ytd-engagement-panel-section-list-renderer[target-id="engagement-panel-comments-section"],
            ytm-comments-entry-point-header-renderer,
            ytm-comment-section-renderer,
            ytm-item-section-renderer[section-identifier="comment-item-section"],
            ytm-engagement-panel-section-list-renderer {
              display: none !important;
            }
          `;
        }

        if (SETTINGS.hideRelated) {
          css += `
            #related,
            ytd-watch-next-secondary-results-renderer {
              display: none !important;
            }
          `;
        }

        if (SETTINGS.blurThumbnails) {
          css += `
            ytd-thumbnail,
            ytd-thumbnail a#thumbnail,
            ytd-rich-grid-media #thumbnail,
            ytd-video-renderer #thumbnail,
            ytd-grid-video-renderer #thumbnail,
            ytd-compact-video-renderer #thumbnail,
            ytd-playlist-renderer #thumbnail,
            yt-img-shadow,
            ytd-thumbnail img,
            ytd-thumbnail yt-img-shadow img,
            yt-img-shadow img,
            img.yt-core-image,
            ytd-rich-grid-media img,
            ytd-video-renderer img,
            ytd-compact-video-renderer img,
            ytd-grid-video-renderer img {
              filter: blur(10px) !important;
            }
          `;
        }

        const style = document.createElement("style");
        style.id = "pure-path-yt-styles";
        style.textContent = css;
        (document.head || document.documentElement).appendChild(style);
      }

      // Remove comment nodes too (belt and braces alongside the CSS)
      function removeComments() {
        if (!SETTINGS.hideComments) return;
        document
          .querySelectorAll("ytd-comments, #comments, ytm-comment-section-renderer, ytm-comments-entry-point-header-renderer")
          .forEach((el) => el.remove());
      }
    
      // Feed previews: only /watch is allowed to have a playing video.
      function updatePreviewGuard() {
        const onWatch = location.pathname === "/watch";
        document.documentElement.toggleAttribute("data-pp-no-previews", !onWatch);
        if (onWatch) return;
        document.querySelectorAll("video").forEach((v) => {
           try { v.pause(); } catch (e) {}
           v.muted = true;
        });
      }

      function ensureIntentGate() {
        if (!SETTINGS.useIntentGateOnHome) return;
        if (!isYouTubeHome()) return;
        if (isGateDismissedForCurrentUrl()) return;
        if (document.getElementById("focus-intent-gate")) return;

        const overlay = document.createElement("div");
        overlay.id = "focus-intent-gate";
        Object.assign(overlay.style, {
          position: "fixed", inset: "0", zIndex: "1000000",
          background: "rgba(0,0,0,0.88)", display: "flex",
          alignItems: "center", justifyContent: "center", padding: "18px",
        });

        const card = document.createElement("div");
        Object.assign(card.style, {
          width: "min(520px, 92vw)", borderRadius: "16px", padding: "24px",
          background: "#FBF6EC", color: "#2B2621", border: "1px solid #DCD0BC",
          fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif",
          boxShadow: "0 12px 32px rgba(43,38,33,0.15)",
        });

        const title = document.createElement("div");
        title.textContent = SETTINGS.gateTitle;
        Object.assign(title.style, { fontSize: "20px", fontWeight: "700", marginBottom: "8px", color: "#2B2621" });

        const body = document.createElement("div");
        body.textContent = SETTINGS.gateBody;
        Object.assign(body.style, { fontSize: "14px", color: "#5C5348", marginBottom: "20px", lineHeight: "1.5" });

        const btnRow = document.createElement("div");
        Object.assign(btnRow.style, { display: "flex", gap: "10px", flexWrap: "wrap", justifyContent: "flex-end" });

        const mkBtn = (label, primary = false) => {
          const b = document.createElement("button");
          b.type = "button";
          b.textContent = label;
          Object.assign(b.style, {
            padding: "10px 16px", borderRadius: "10px",
            border: primary ? "none" : "1px solid #DCD0BC",
            background: primary ? "#6B7A5E" : "transparent",
            color: primary ? "#FBF6EC" : "#2B2621",
            cursor: "pointer", fontSize: "13px", fontWeight: "600",
          });
          return b;
        };

        const btnSearch = mkBtn("Search intentionally", true);
        btnSearch.onclick = () => {
          dismissGateForCurrentUrl();
          overlay.remove();
          const input = document.querySelector("input#search") || document.querySelector('input[name="search_query"]');
          if (input) input.focus();
          else location.href = "https://" + location.hostname + "/results?search_query=";
        };

        const btnSubs = mkBtn("Subscriptions");
        btnSubs.onclick = () => {
          dismissGateForCurrentUrl();
          location.href = "https://" + location.hostname + "/feed/subscriptions";
        };

        btnRow.appendChild(btnSearch);
        btnRow.appendChild(btnSubs);

        if (SETTINGS.allowContinueAnyway) {
          const btnContinue = mkBtn("Continue anyway");
          btnContinue.onclick = () => { dismissGateForCurrentUrl(); overlay.remove(); };
          btnRow.appendChild(btnContinue);
        }

        card.appendChild(title);
        card.appendChild(body);
        card.appendChild(btnRow);
        overlay.appendChild(card);
        document.documentElement.appendChild(overlay);
      }

      let scheduled = false;
      const sweep = () => {
        injectStyles();
        updatePreviewGuard();
        enforceVideoSearchFilter();
        removeShortsByLabel();
        removeShorts();
        removeComments();
        ensureIntentGate();
      };
      const scheduleSweep = () => {
        if (scheduled) return;
        scheduled = true;
        queueMicrotask(() => { scheduled = false; sweep(); });
      };

      scheduleSweep();
      new MutationObserver(scheduleSweep).observe(document.documentElement, { childList: true, subtree: true });

      let lastUrl = location.href;
      setInterval(() => {
        if (location.href !== lastUrl) { lastUrl = location.href; scheduleSweep(); }
      }, 500);
    })();
    """#

    init(initialRequest: URLRequest? = nil) {
        let config = WKWebViewConfiguration()
        #if os(iOS)
        config.allowsInlineMediaPlayback = true     // play in the page, not fullscreen
        #endif
        if #available(macOS 12.3, iOS 15.4, *) {
            config.preferences.isElementFullscreenEnabled = true   // YouTube's fullscreen button works
        }
        let controller = WKUserContentController()

        // 1. SPA listener script
        controller.addUserScript(WKUserScript(source: Self.spaScript,
                                              injectionTime: .atDocumentStart,
                                              forMainFrameOnly: true))

        // 2. YouTube distraction-free script (Shorts, comments, etc.)
        controller.addUserScript(WKUserScript(source: Self.youtubeScript,
                                              injectionTime: .atDocumentStart,
                                              forMainFrameOnly: true))

        config.userContentController = controller
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        controller.add(self, name: "urlChanged")
        webView.navigationDelegate = self
        webView.uiDelegate = self

        #if DEBUG
        if #available(macOS 13.3, iOS 16.4, *) {
            webView.isInspectable = true   // right-click → Inspect Element
        }
        #endif

        // Keep the tab's published state in sync with the web view
        webView.publisher(for: \.title)
            .sink { [weak self] t in
                if let t, !t.isEmpty { self?.title = t }
            }
            .store(in: &cancellables)
        webView.publisher(for: \.url)
            .sink { [weak self] u in
                if let u, u.scheme == "http" || u.scheme == "https" { self?.address = u.absoluteString }
            }
            .store(in: &cancellables)
        webView.publisher(for: \.canGoBack)
            .sink { [weak self] v in self?.canGoBack = v }
            .store(in: &cancellables)
        webView.publisher(for: \.canGoForward)
            .sink { [weak self] v in self?.canGoForward = v }
            .store(in: &cancellables)

        if let initialRequest {
            showStart = false
            webView.load(initialRequest)       // still goes through decidePolicyFor
        } else {
            showStart = true                   // new tab opens on the favorites page
        }
    }

    func teardown() {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "urlChanged")
        cancellables.removeAll()
    }

    func go(_ input: String) {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        showStart = false

        if let url = URL(string: t), let scheme = url.scheme, scheme.hasPrefix("http") {
            webView.load(URLRequest(url: url))
        } else if t.contains("."), !t.contains(" "), let url = URL(string: "https://" + t) {
            webView.load(URLRequest(url: url))
        } else {
            let q = t.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let searchURL = URL(string: "https://www.google.com/search?q=\(q)") {
                webView.load(URLRequest(url: searchURL))
            }
        }
    }

    // MARK: Pre-load check

    func webView(_ webView: WKWebView,
                 decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard action.targetFrame?.isMainFrame ?? true,
              let url = action.request.url,
              url.scheme == "http" || url.scheme == "https" else { return .allow }

        let verdict = await GuardianEngine.shared.check(url)
        if case .allow = verdict { return .allow }

        // Load the block page after this callback returns, so the cancel doesn't clobber it
        Task { self.show(verdict, for: url) }
        return .cancel
    }

    // Links that open a new window: make a new tab (its first load gets checked too)
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { onOpenNewTab?(navigationAction.request) }
        return nil
    }

    // SPA URL changes (checked after the fact, since no real navigation happened)
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "urlChanged",
              let s = message.body as? String,
              let url = URL(string: s),
              url.scheme == "http" || url.scheme == "https" else { return }
        Task {
            let verdict = await GuardianEngine.shared.check(url)
            if case .allow = verdict { return }
            self.show(verdict, for: url)
        }
    }

    // MARK: Block pages

    func show(_ verdict: Verdict, for url: URL) {
        switch verdict {
        case .allow:
            break
        case .block(let reason):
            webView.loadHTMLString(BlockPage.html(reason: reason, url: url), baseURL: nil)
        case .lockdown(let until):
            showLockdownPage(until: until, url: url)
            onLockdown?(until)          // lock every other tab too
        }
    }

    func showLockdownPage(until: Date, url: URL? = nil) {
        webView.loadHTMLString(
            BlockPage.html(reason: "Lockdown: too many blocked attempts", url: url, lockdownUntil: until),
            baseURL: nil)
    }
}

// MARK: - Tab manager

@MainActor
final class BrowserModel: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var selectedID: UUID?

    var selectedTab: BrowserTab? { tabs.first { $0.id == selectedID } }

    init() { newTab() }

    func newTab(request: URLRequest? = nil) {
        let tab = BrowserTab(initialRequest: request)
        tab.onOpenNewTab = { [weak self] req in self?.newTab(request: req) }
        tab.onLockdown = { [weak self, weak tab] until in
            guard let self else { return }
            for other in self.tabs where other.id != tab?.id {
                other.showLockdownPage(until: until)
            }
        }
        tabs.append(tab)
        selectedID = tab.id
    }

    func close(_ tab: BrowserTab) {
        guard let idx = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        tab.teardown()
        tabs.remove(at: idx)
        if tabs.isEmpty { newTab(); return }
        if selectedID == tab.id { selectedID = tabs[min(idx, tabs.count - 1)].id }
    }
}

// MARK: - UI

struct TabChip: View {
    @ObservedObject var tab: BrowserTab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tab.title)
                .font(.caption)
                .lineLimit(1)
            Spacer(minLength: 4)
            Button(action: onClose) {
                Image(systemName: "xmark").font(.caption2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.15))
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

struct AddressBar: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject private var favorites = FavoritesStore.shared
    @State private var showInfo = false

    private var isFavorite: Bool { favorites.contains(tab.address) }
    private var hasSite: Bool { !tab.showStart && URL(string: tab.address)?.host != nil }

    var body: some View {
        HStack(spacing: 8) {
            Button { tab.webView.goBack() } label: { Image(systemName: "chevron.left") }
                .disabled(!tab.canGoBack || tab.showStart)
            Button { tab.webView.goForward() } label: { Image(systemName: "chevron.right") }
                .disabled(!tab.canGoForward || tab.showStart)
            Button { tab.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
                .disabled(tab.showStart)
            TextField("Search or enter URL", text: $tab.address)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.webSearch)
                #endif
                .onSubmit { tab.go(tab.address) }

            Button { favorites.toggle(tab.address) } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? Theme.danger : .primary)
            }
            .disabled(!hasSite)

            Button { showInfo = true } label: { Image(systemName: "shield.lefthalf.filled") }
                .disabled(!hasSite)
                #if os(macOS)
                .popover(isPresented: $showInfo, arrowEdge: .bottom) {
                    SiteInfoView(tab: tab).frame(width: 320, height: 380)
                }
                #else
                .sheet(isPresented: $showInfo) {
                    SiteInfoView(tab: tab).presentationDetents([.medium, .large])
                }
                #endif
        }
    }
}

// Shows either the favorites page or the web view for one tab
struct TabContent: View {
    @ObservedObject var tab: BrowserTab

    var body: some View {
        ZStack {
            BrowserView(webView: tab.webView)
                .opacity(tab.showStart ? 0 : 1)
            if tab.showStart {
                StartPageView(tab: tab)
            }
        }
        // Lets content run under the home-indicator area. Scroll views still inset
        // themselves automatically, so nothing important gets covered.
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

struct ContentView: View {
    @StateObject private var model = BrowserModel()

    var body: some View {
        VStack(spacing: 0) {
            // Tab strip
            HStack(spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(model.tabs) { tab in
                            TabChip(tab: tab,
                                    isSelected: tab.id == model.selectedID,
                                    onSelect: { model.selectedID = tab.id },
                                    onClose: { model.close(tab) })
                        }
                    }
                }
                Button { model.newTab() } label: { Image(systemName: "plus") }
                    .keyboardShortcut("t")
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Selected tab
            if let tab = model.selectedTab {
                AddressBar(tab: tab)
                    .padding(8)
                    .id(tab.id)
                TabContent(tab: tab)
                    .id(tab.id)
            }
        }
    }
}

#Preview {
    ContentView()
}
