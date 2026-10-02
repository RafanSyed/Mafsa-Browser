# Masfa

**Browse with boundaries.**

Masfa is a web browser for iPhone built around intention. Every search and website is checked before it loads, so the things you've decided don't belong in your day are stopped at the door.

---

## Features

- **Checks before loading.** Searches and sites are screened before the page opens.
- **Block any site in one tap.** Tap the shield in the address bar to see a site's status and block it.
- **Lockdown mode.** Repeated attempts to reach blocked content start a timed lockdown across all open tabs.
- **A calmer YouTube.** Shorts, comments, and autoplay previews are removed, and videos only go fullscreen when you tap the fullscreen button.
- **Favorites start page.** New tabs open on your own list of sites. Tap the heart on any page to add it, and press and hold a tile to remove it.
- **Tabs and everyday browsing.** Multiple tabs, back and forward, and a combined search and address bar, built on Apple's WebKit engine.

---

## Support

Need help, found a bug, or have a site that was blocked by mistake?

- **Email:** rafansyed30@gmail.com
- **Report an issue:** open an issue in this repository's **Issues** tab
- **Response time:** I aim to reply within [2–3 business days]

When you write in, it helps to include:
- Your iPhone model and iOS version
- The Masfa version (shown in the App Store listing)
- The website or search that caused the problem
- What you expected to happen and what happened instead

---

## Frequently asked questions

**A site was blocked and shouldn't have been. What do I do?**
Email me the site's address and I'll review it. No filter is perfect, and reports help improve it.

**A site that should be blocked got through. Can I block it myself?**
Yes. Open the site, tap the shield icon in the address bar, and choose **Block this site**.

**How does lockdown work?**
If several blocked attempts happen within a short window, Masfa locks every tab for a set time and shows a countdown until it lifts. [Currently: 3 blocked attempts within a minute triggers a 30-minute lockdown.]

**Why is the first visit to a new site a little slower?**
Masfa checks unfamiliar sites and searches before loading them. Sites it has already seen load faster. If the service hasn't been used in a while, the first check can take longer.

**Can I make Masfa my default browser?**
No. Apple restricts default-browser status to approved apps, so links from Messages and other apps will still open in Safari unless you copy them into Masfa.

**Does Masfa work with private browsing or other browsers?**
Masfa only filters what you open inside Masfa. Other browsers on your device aren't affected, so for the best results combine it with Screen Time restrictions.

**Where is my data stored?**
Your favorites and lockdown timer are stored on your device. See Privacy below for what is sent to the classification service.

---

## Privacy

To decide whether a site or search is appropriate, Masfa sends the domain, address, or search text you are about to visit to Masfa's classification service. This is what makes the pre-load check work. [Masfa does not sell your data or use it for advertising.]

- **Stored on your device:** favorites, lockdown timer
- **Sent to the service:** domains and search text being checked, and sites you choose to block
- **Not collected:** name, email, contacts, location.
Full details: https://github.com/RafanSyed/Mafsa-Browser/blob/main/PRIVACYPOLICY.md

---

## Limitations

Masfa is one layer of a broader plan, not a guarantee. Content classification can make mistakes in both directions, and Masfa only applies to browsing done inside the app.

---

© [2026] [Mafsa]. All rights reserved.
