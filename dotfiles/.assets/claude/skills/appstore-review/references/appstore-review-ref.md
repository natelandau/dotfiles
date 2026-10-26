---
last_verified: "2026-07-24"
---

# Authoritative references for an iOS App Store audit skill

**Building a robust App Store review-readiness skill for an iOS 17+ SwiftUI app with StoreKit 2 subscriptions requires anchoring to roughly 60 official Apple documents and a handful of battle-tested community resources.** The landscape shifted meaningfully in 2024 with enforced privacy manifests, StoreKit 1's deprecation, and EU DMA compliance — and more changes land in 2025–2026 with expanded age ratings and new SDK build requirements. This report catalogs every reference you should wire into the skill, organized by audit domain, with exact URLs, source classification, and change-date flags.

---

## 1. Core Apple guidelines that anchor the entire skill

The **App Store Review Guidelines** at `https://developer.apple.com/app-store/review/guidelines/` are the single most critical document. For an IAP/subscription app, the sections that trigger the majority of rejections are:

- **Section 3.1.1 (In-App Purchase)** — requires Apple IAP for all digital goods; mandates a "Restore Purchases" mechanism
- **Section 3.1.2 (Subscriptions)** — subsections (a) permissible uses, (b) upgrades/downgrades, (c) subscription information disclosure, (d) third-party content rules
- **Section 3.1.3 (External Links)** — updated in 2024 for US court-decision compliance (StoreKit External Purchase Link Entitlement)
- **Section 2.1 (App Completeness)** — accounts for over **40% of all unresolved rejections** per Apple's own data
- **Section 5.1 (Privacy)** — data collection, usage, sharing; subsection 5.1.2(i) added in 2024 requiring explicit consent for third-party AI data sharing

Two companion guideline hubs should also be referenced. The **App Review preparation page** at `https://developer.apple.com/distribute/app-review/` consolidates common issues and submission tips. Apple's **Upcoming Requirements page** at `https://developer.apple.com/news/upcoming-requirements/` publishes deadlines for new enforcement — your skill should check this page regularly to stay current.

The **Human Interface Guidelines** at `https://developer.apple.com/design/human-interface-guidelines/` include a dedicated **In-App Purchase section** at `https://developer.apple.com/design/human-interface-guidelines/in-app-purchase` covering paywall UI patterns, SubscriptionStoreView usage, and subscription merchandising in SwiftUI. A separate **auto-renewable subscriptions design page** exists at `https://developer.apple.com/design/human-interface-guidelines/in-app-purchase/overview/auto-renewable-subscriptions/`.

**App Store Connect Help** at `https://developer.apple.com/help/app-store-connect/` is the operational reference for every metadata field, submission flow, and configuration step. Key subsections include the **Required, Localizable, and Editable Properties reference** at `https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties/` and the **App and Submission Statuses reference** at `https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-submission-statuses`.

| Resource | URL | Source |
|----------|-----|--------|
| App Store Review Guidelines | `https://developer.apple.com/app-store/review/guidelines/` | Official Apple |
| App Review Preparation | `https://developer.apple.com/distribute/app-review/` | Official Apple |
| Upcoming Requirements | `https://developer.apple.com/news/upcoming-requirements/` | Official Apple |
| Human Interface Guidelines | `https://developer.apple.com/design/human-interface-guidelines/` | Official Apple |
| HIG: In-App Purchase | `https://developer.apple.com/design/human-interface-guidelines/in-app-purchase` | Official Apple |
| App Store Connect Help | `https://developer.apple.com/help/app-store-connect/` | Official Apple |
| Required Properties Reference | `https://developer.apple.com/help/app-store-connect/reference/app-information/required-localizable-and-editable-properties/` | Official Apple |

---

## 2. StoreKit 2 and subscription-specific references

### StoreKit 2 framework documentation

The **StoreKit landing page** at `https://developer.apple.com/storekit/` is the modern entry point covering SwiftUI views (StoreView, ProductView, SubscriptionStoreView), JWS-signed transactions, and Swift concurrency APIs. The **full framework reference** lives at `https://developer.apple.com/documentation/storekit`, and the critical **migration decision guide** ("Choosing a StoreKit API") is at `https://developer.apple.com/documentation/storekit/choosing-a-storekit-api-for-in-app-purchases`. **Warning: 2024 change:** the original StoreKit API was officially deprecated in iOS 18 at WWDC24 — your skill should flag any remaining StoreKit 1 usage.

For server-side integration, the **App Store Server API** at `https://developer.apple.com/documentation/appstoreserverapi` replaces the deprecated `verifyReceipt` endpoint with 12 modern endpoints for transaction history, subscription status, and refund handling. **Server Notifications V2** at `https://developer.apple.com/documentation/AppStoreServerNotifications/App-Store-Server-Notifications-V2` provides JWS-signed event payloads with 20+ event types.

### Required subscription disclosures (high-rejection-risk area)

Apple's **auto-renewable subscriptions page** at `https://developer.apple.com/app-store/subscriptions/` is the single most important subscription-specific reference. Per Guideline 3.1.2(c) and Schedule 2, Section 3.8(b) of the Apple Developer Program License Agreement, the subscription sign-up screen **must** include:

- Subscription name and duration with content/services described
- **Full renewal price displayed as the most prominent pricing element**, localized per currency
- Free trial duration and post-trial price (if applicable)
- Tappable links to both Terms of Use and Privacy Policy
- A "Restore Purchases" mechanism (button or equivalent)

RevenueCat's analysis of the required disclosure language is at `https://www.revenuecat.com/blog/engineering/schedule-2-section-3-8-b/`.

### Testing IAP across all three environments

Your skill should verify testing at **three distinct levels**. Apple's master testing guide is at `https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox`:

| Test Environment | Documentation URL | Key Details |
|------------------|-------------------|-------------|
| Xcode StoreKit Testing (local) | `https://developer.apple.com/documentation/storekit/testing-in-app-purchases-in-xcode` | Uses StoreKit Configuration files; no network required; full control over transactions |
| Sandbox (server-connected) | `https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox` | Server-to-server testing; up to 10,000 sandbox accounts |
| TestFlight | `https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight/` | Uses sandbox environment; 1-month subscription = 24-hour renewal; auto-cancels after 6 renewals |

Sandbox account management in App Store Connect is documented at `https://developer.apple.com/help/app-store-connect/test-in-app-purchases/create-a-sandbox-apple-account/` and `https://developer.apple.com/help/app-store-connect/test-in-app-purchases/manage-sandbox-apple-account-settings/`.

### IAP and subscription configuration in App Store Connect

| Task | URL |
|------|-----|
| Configure IAP overview | `https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/` |
| Create consumable/non-consumable IAP | `https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/` |
| Offer auto-renewable subscriptions | `https://developer.apple.com/help/app-store-connect/manage-subscriptions/offer-auto-renewable-subscriptions/` |
| Set up introductory offers | `https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions/` |
| Set up promotional offers | `https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-promotional-offers-for-auto-renewable-subscriptions/` |
| Set up win-back offers (new 2024) | `https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-win-back-offers/` |
| Manage subscription pricing | `https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/` |
| Enable billing grace period | `https://developer.apple.com/help/app-store-connect/manage-subscriptions/enable-billing-grace-period-for-auto-renewable-subscriptions/` |
| Generate IAP keys (for Server API JWT) | `https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/generate-keys-for-in-app-purchases/` |
| Promote IAP on App Store | `https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/promote-in-app-purchases` |

Each IAP submitted for review requires a **review screenshot** (showing the purchase in-app context) and **review notes**. Promoted IAPs additionally need a **1024x1024 promotional image**.

**Review screenshot vs. promotional image — a real-submission trap.** The IAP **App Review screenshot** must be a raw capture of the actual purchase UI at one of the app's device screenshot specs (e.g. 1320×2868 for 6.9"); arbitrary sizes are rejected with a vague "dimensions are wrong" error. The **1024×1024 promotional image** is an adjacent field on the same page and applies only to promoted IAPs — uploading it into the review-screenshot slot is a common round-trip. One screenshot of a purchase sheet showing multiple SKUs may be reused as the review screenshot for each of those SKUs. Field-level guidance is on the ASC help page below; upload-slot pixel specs are on the Screenshot Specifications page (cross-referenced in Section 4). A real-submission trap: after a failed validation, the ASC screenshot upload widget can silently reject subsequent valid files until the page is reloaded.

| Task | URL |
|------|-----|
| Add In-App Purchase information (review screenshot vs. promotional image) | `https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/add-in-app-purchase-information/` |
| Screenshot Specifications (upload-slot pixel sizes) | `https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/` |

### Review submission assembly (Guideline 2.1(b))

App Store Connect groups a version and its IAPs into a single **review submission**, and the topology rules cause 2.1(b) App Completeness rejections when misunderstood:

- The **first-ever IAP of an app must be attached to the same review submission as the app version.** Submitting the version alone while products sit in "Prepare for Submission" triggers a 2.1(b) rejection ("app includes references to a product but the associated In-App Purchase products have not been submitted"); Apple's prescribed remedy is submitting the IAPs **plus a new binary**.
- **One review submission per platform at a time.** While a version is Waiting for Review / In Review, IAPs added for review land in a separate draft submission that cannot be submitted and does not ride along automatically.

The App and Submission Statuses reference (Section 1) explains the status model; the submission flow itself is documented below.

| Task | URL |
|------|-----|
| Submit for review (assembling a review submission) | `https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-for-review/` |

The subscription management deep link API — `AppStore.showManageSubscriptions(in:)` documented at `https://developer.apple.com/documentation/storekit/appstore/3803198-showmanagesubscriptions` — is strongly recommended for in-app subscription management on iOS 15+.

---

## 3. Code and entitlements audit references

### In-App Purchase capability and entitlements

A critical nuance for your skill: **In-App Purchase is NOT gated by an entitlement key**. There is no `com.apple.developer.in-app-purchase` entitlement. IAP requires only an **explicit (non-wildcard) App ID**, enabled by adding the "In-App Purchase" capability in Xcode's Signing & Capabilities tab. The commonly confused `com.apple.developer.in-app-payments` entitlement is for **Apple Pay / Merchant ID** via PassKit, not StoreKit IAP. This distinction is confirmed in Apple Developer Forums threads at `https://developer.apple.com/forums/thread/738035`.

The general entitlements documentation is at `https://developer.apple.com/documentation/bundleresources/entitlements`, with the capabilities overview at `https://developer.apple.com/help/account/capabilities/capabilities-overview/`. **2024 addition:** The **StoreKit External Purchase Link Entitlement** (US-only) at `https://developer.apple.com/support/storekit-external-entitlement-us/` is a new entitlement for apps offering external purchase links under Guideline 3.1.3(a).

### Privacy manifests — the most impactful 2024 enforcement change

**Enforced since May 1, 2024.** Apps uploaded to App Store Connect without proper `PrivacyInfo.xcprivacy` declarations receive **ITMS-91053** rejections. As of February 12, 2025, third-party SDKs on Apple's list must also include their own privacy manifests (ITMS-91061 rejections). This is the single largest new compliance requirement since App Tracking Transparency.

| Resource | URL | Notes |
|----------|-----|-------|
| Privacy Manifest Files (main docs) | `https://developer.apple.com/documentation/bundleresources/privacy-manifest-files` | Primary reference |
| Adding a Privacy Manifest | `https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk` | Step-by-step guide |
| Describing Use of Required Reason API | `https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api` | Full list of 5 API categories + approved reasons |
| TN3183: Adding Required Reason API Entries | `https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest` | Detailed implementation technote |
| Third-Party SDK Requirements | `https://developer.apple.com/support/third-party-SDK-requirements/` | List of SDKs requiring manifests + signatures |
| WWDC23: Get Started with Privacy Manifests | `https://developer.apple.com/videos/play/wwdc2023/10060/` | Essential overview video |
| Enforcement announcement (May 2024) | `https://developer.apple.com/news/?id=pvszzano` | Deadline confirmation |

The **five Required Reason API categories** your skill must check for:

| Category | Key | Common APIs |
|----------|-----|-------------|
| File Timestamp | `NSPrivacyAccessedAPICategoryFileTimestamp` | `creationDate`, `modificationDate`, `stat()`, `fstat()` |
| System Boot Time | `NSPrivacyAccessedAPICategorySystemBootTime` | `systemUptime`, `mach_absolute_time()` |
| Disk Space | `NSPrivacyAccessedAPICategoryDiskSpace` | `volumeAvailableCapacityKey`, `NSFileSystemFreeSize` |
| Active Keyboards | `NSPrivacyAccessedAPICategoryActiveKeyboards` | `UITextInputMode.activeInputModes` |
| User Defaults | `NSPrivacyAccessedAPICategoryUserDefaults` | `UserDefaults` (virtually every app uses this) |

Xcode 15+ aggregates all privacy manifests from the app and third-party SDKs into a **Privacy Report PDF** accessible via Organizer > right-click archive > "Generate Privacy Report." This report helps accurately complete the **App Privacy nutrition labels** in App Store Connect.

### App Transport Security

ATS is enabled by default for all apps linked against iOS 9+ SDKs and requires **TLS 1.2+** for all HTTP connections via URLSession. The primary reference is `https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity`, with a practical guide at `https://developer.apple.com/documentation/security/preventing-insecure-network-connections`. Setting `NSAllowsArbitraryLoads = YES` triggers App Review scrutiny and requires justification. Domain-specific exceptions via `NSExceptionDomains` are the preferred approach.

---

## 4. Metadata and submission checklist references

### Screenshot and app preview specifications

Only **one screenshot per major device category** is now required (6.5"/6.9" iPhone and 13" iPad); all other sizes auto-scale. Up to 10 screenshots per device size in JPEG/PNG format, and up to 3 app previews per device (30 seconds max, H.264 or ProRes 422).

| Resource | URL |
|----------|-----|
| Screenshot Specifications | `https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/` |
| App Preview Specifications | `https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/` |
| Upload Guide | `https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/` |
| App Previews Best Practices | `https://developer.apple.com/app-store/app-previews/` |

### Metadata field rules

| Field | Limit | Editable Without New Version? |
|-------|-------|-------------------------------|
| App Name | 30 characters | No |
| Subtitle | 30 characters | No |
| Description | 4,000 characters | No |
| Promotional Text | 170 characters | **Yes** |
| Keywords | 100 characters (comma-separated, no spaces after commas) | No |
| What's New | 4,000 characters | Per-version |
| Support URL | Required, must be functional | Yes |
| Marketing URL | Optional | Yes |
| Privacy Policy URL | **Required for all apps** | Yes |
| Copyright | Required (year + entity) | Per-version |

Keyword optimization guidance is at `https://developer.apple.com/app-store/search/`. Product page creation guidance is at `https://developer.apple.com/app-store/product-page/`.

### Privacy nutrition labels, age ratings, and export compliance

**Privacy nutrition labels** (declared in App Store Connect, displayed on the product page) are documented at `https://developer.apple.com/app-store/app-privacy-details/` with the management guide at `https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/`. These are distinct from but informed by privacy manifests.

**Age ratings** are set via questionnaire at `https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/`. **2025-2026 change:** Apple expanded the system to add **13+, 16+, and 18+** ratings alongside existing 4+ and 9+, with new questions covering in-app controls, AI/chatbot content, and medical/wellness topics. Developers were required to respond by **January 31, 2026**.

**Export compliance** documentation is at `https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/`. Most apps using only standard HTTPS via URLSession are **exempt** — set `ITSAppUsesNonExemptEncryption = NO` in Info.plist to skip the questionnaire on each upload. The technical reference is at `https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations`.

---

## 5. What gets apps rejected — data and patterns

Apple's **2024 App Store Transparency Report** (published May 2025) at `https://www.apple.com/legal/more-resources/docs/2024-App-Store-Transparency-Report.pdf` provides hard data: **7.77 million submissions reviewed, 1.93 million rejected** (~25% rejection rate, up 9.5% year-over-year). The top rejection categories by volume are **Performance (#1, ~1.23M rejections)**, Legal (#2), Design (#3, 378,300), Business (#4), and Safety (#5).

For subscription apps specifically, the highest-risk rejection patterns are:

- **Guideline 2.1 (App Completeness)** — crashes during review, sandbox purchase failures, broken links, placeholder content. Over 40% of unresolved issues fall here.
- **Guideline 3.1.2 (Subscriptions)** — pricing mismatch between metadata and in-app display; missing or illegible disclosure text; "dark patterns" like hiding annual pricing behind monthly equivalents; fake urgency claims; missing Terms of Use / Privacy Policy links within the app.
- **Missing "Restore Purchases"** — Guideline 3.1.1 explicitly requires a restore mechanism for restorable IAPs. A missing restore button on the paywall or settings screen is an instant rejection.
- **Privacy manifest violations (ITMS-91053)** — since May 2024, missing Required Reason API declarations cause automated upload rejection before human review even begins.
- **Guideline 5.1 (Privacy)** — missing privacy policy, incorrect data collection disclosures, missing account deletion option.

Apple's **official common-issues page** is at `https://developer.apple.com/distribute/app-review/`, and the **Tech Talk "Tips for preventing common review issues"** is at `https://developer.apple.com/videos/play/tech-talks/10885/`. The Apple Developer Forums FAQ thread at `https://developer.apple.com/forums/thread/131256` provides review-timeline expectations (50% reviewed within 24 hours, 90% within 48 hours).

### Pre-permission priming copy — Guideline 5.1.1(iv)

Under **Guideline 5.1.1(iv)** ("Access") of the App Store Review Guidelines (Section 1), a button shown **before** a system permission prompt must not pre-answer that prompt: labels like "Enable Camera", "Allow", or "Turn On" on a priming/onboarding screen draw a rejection. Neutral wording ("Continue", "Next") is required; explanatory body copy is fine and encouraged. Post-denial screens that route the user to Settings are exempt.

### Face and biometric data — Guideline 2.1 / 5.1 and the ADPLA

Any app that touches faces — including pure on-device Vision face **detection** with zero collection — should expect Apple's standard six-question face-data questionnaire (what is collected and its use, sharing, retention, deletion, storage, and where in the privacy policy it is disclosed with the text quoted). Practical expectations:

- The privacy policy must contain **explicit, quotable "face data" language**; covering "photos" generically does not satisfy the reviewer, and the disclosure must truthfully enumerate every face-detection call site — Apple falsifies claims against actual Vision API usage.
- Faceprint / face-recognition use is governed by the **Apple Developer Program License Agreement, Section 3.3.3(C) and (K)**, which restrict collecting, using, or sharing biometric identifiers; document compliance if any recognition (not merely detection) API is present.
- Third-party AI processors' retention claims must match the processor's **own documented** policy — claim zero retention only with a contractual Zero Data Retention agreement in place.
- The App Store Connect reviewer-reply box caps at **4,000 characters**, so long policy quotes must be excerpted.

---

## 6. Tooling references for validation and submission

**Xcode archive and validation** is documented at `https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases`. Xcode 15+ introduced streamlined one-click "TestFlight & App Store" distribution in the Organizer. Automated validation checks include entitlements verification, code signing, provisioning profile matching, icon requirements, Info.plist validation, privacy manifest checks, and architecture compatibility. Use Organizer > right-click archive > "Generate Privacy Report" to produce a PDF aggregating all privacy declarations.

The **App Store Connect API** (currently at version 3.7) at `https://developer.apple.com/documentation/appstoreconnectapi` supports programmatic management of IAP metadata, subscription groups, pricing, app versions, TestFlight, and submission. The API overview is at `https://developer.apple.com/app-store-connect/api/`.

**Transporter** (Mac App Store app) provides drag-and-drop IPA/PKG upload and is documented at `https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/`. The command-line variant **iTMSTransporter** runs on macOS, Windows, and Linux for CI/CD automation. **altool** upload commands (`xcrun altool --validate-app`, `xcrun altool --upload-app`) remain functional and are not deprecated, though altool's notarization subcommands were removed in November 2023 in favor of **notarytool** (`xcrun notarytool submit`).

---

## 7. Community resources and WWDC sessions worth referencing

### Best community references

| Resource | URL | Why it matters |
|----------|-----|----------------|
| RevenueCat: Ultimate Guide to App Store Rejections | `https://www.revenuecat.com/blog/growth/the-ultimate-guide-to-app-store-rejections/` | Most comprehensive community rejection guide; subscription-focused |
| RevenueCat: App Subscription Launch Checklist | `https://www.revenuecat.com/docs/test-and-launch/launch-checklist` | Pre-launch checklist for subscription apps |
| RevenueCat: Schedule 2, Section 3.8(b) Analysis | `https://www.revenuecat.com/blog/engineering/schedule-2-section-3-8-b/` | Decodes required subscription disclosure language |
| Adapty: App Store Rejection Reasons | `https://adapty.io/blog/app-store-rejection/` | Statistics-driven rejection guide with 2024 data |
| Adapty: Apple Paywall Guidelines | `https://adapty.io/blog/how-to-design-paywall-to-pass-review-for-app-store/` | Paywall compliance patterns |
| GitHub: lukylab/appstore-submission-checklist | `https://github.com/lukylab/appstore-submission-checklist` | Open-source checklist for new apps and updates |
| GitHub: rossbeale/iOS-App-Store-Submission-Checklist | `https://github.com/rossbeale/iOS-App-Store-Submission-Checklist` | Community-curated experience-driven checklist |

### Essential WWDC sessions

| Session | URL | Year | Topic |
|---------|-----|------|-------|
| What's new in StoreKit and In-App Purchase | `https://developer.apple.com/videos/play/wwdc2024/10061/` | 2024 | StoreKit 1 deprecation, win-back offers |
| Implement App Store Offers | `https://developer.apple.com/videos/play/wwdc2024/10110/` | 2024 | Win-back offers + offer codes |
| Explore App Store Server APIs | `https://developer.apple.com/videos/play/wwdc2024/10062/` | 2024 | Server-side IAP lifecycle |
| Meet StoreKit for SwiftUI | `https://developer.apple.com/videos/play/wwdc2023/10013/` | 2023 | ProductView, SubscriptionStoreView |
| Get Started with Privacy Manifests | `https://developer.apple.com/videos/play/wwdc2023/10060/` | 2023 | Privacy manifest implementation |
| Explore Testing IAP | `https://developer.apple.com/videos/play/wwdc2023/10142/` | 2023 | All 3 testing environments walkthrough |
| Meet StoreKit 2 | `https://developer.apple.com/videos/play/wwdc2021/10114/` | 2021 | Foundational StoreKit 2 introduction |

---

## 8. Requirements that changed in 2024 or are changing in 2025-2026

Your skill must flag these time-sensitive requirements:

**Already enforced (2024):**
- **Privacy manifests** — `PrivacyInfo.xcprivacy` with Required Reason API declarations mandatory since May 1, 2024; third-party SDK manifests enforced since February 12, 2025
- **StoreKit 1 deprecated** — original StoreKit API deprecated in iOS 18; `verifyReceipt` endpoint deprecated; migration to StoreKit 2 and App Store Server API required
- **Win-back offers** — new offer type for re-engaging churned subscribers, configurable in App Store Connect
- **AI data sharing disclosure** — Guideline 5.1.2(i) requires explicit consent when sharing personal data with third-party AI services (enforcement: November 2025)
- **EU DMA compliance** — alternative marketplaces and payment providers on iOS 17.4+ (EU only); documented at `https://developer.apple.com/support/dma-and-apps-in-the-eu/`

**Coming in 2025-2026:**
- **Expanded age ratings** — new 13+, 16+, 18+ tiers with AI/chatbot-specific questions; responses required by January 31, 2026
- **iOS/iPadOS 26 SDK requirement** — starting April 28, 2026, apps must be built with the iOS 26 SDK
- **Privacy manifest expansion** — Apple will extend Required Reason requirements to cover the entire app binary (timeline TBD)
- **EU business model consolidation** — Core Technology Fee replaced by 5% Commission on Technology Commerce by January 2026

## Conclusion

The audit skill should be structured in two parallel tracks — a **code/entitlements audit** anchored to the privacy manifest docs, entitlements reference, StoreKit 2 framework docs, and ATS requirements, and a **submission metadata checklist** driven by App Store Connect Help, screenshot specifications, and the Review Guidelines. The single highest-value insight from this research is that **privacy manifests and subscription disclosure compliance** are the two areas where the gap between "what Apple requires" and "what most developers implement" is widest — making them the highest-ROI sections to emphasize in the skill. Wire in the 2024 Transparency Report rejection statistics to prioritize audit checks by actual rejection frequency, and build in a mechanism to periodically check Apple's Upcoming Requirements page for deadline-driven enforcement changes.
