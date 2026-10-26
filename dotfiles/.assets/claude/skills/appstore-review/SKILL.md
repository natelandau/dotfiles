---
name: appstore-review
version: "1.2.0"
description: >
  App Store review readiness audit for iOS apps. Scans the codebase,
  entitlements, Info.plist, privacy manifests, paywall/subscription UI, and
  metadata for anything that could trigger a warning or rejection during
  App Store review. Invoke explicitly when preparing a submission.
  Do NOT trigger automatically.
disable-model-invocation: true
author: 3 Paws AI Studio
license: MIT
agents:
  - claude-code
tags:
  - ios
  - app-store
  - review
  - submission
  - privacy-manifest
  - storekit
trigger: manual
last_verified: "2026-07-24"
---

# App Store Review Readiness Audit

## Purpose
Catch every issue that could cause an App Store warning or rejection — before
submitting. This skill runs a two-track audit: **code/entitlements** and
**submission metadata**. It is ordered by rejection frequency (highest-risk first)
based on Apple's 2024 Transparency Report data.

**Reference file**: `references/appstore-review-ref.md` contains the full
catalog of Apple docs, WWDC sessions, and community resources backing each check.

---

## How to Run the Audit

When invoked, execute every section below **in order**. For each check:
1. Inspect the relevant files/config in the project
2. Report **PASS**, **WARN**, or **FAIL** with a one-line explanation
3. At the end, produce a summary table of all results

Do NOT skip sections. Do NOT ask the user which sections to run — run them all.

---

## Track 1 — Code & Entitlements Audit

### 1.1 App Completeness (Guideline 2.1) — #1 rejection cause

This accounts for over 40% of all unresolved rejections.

- [ ] App launches without crashing on a clean install
- [ ] No placeholder or Lorem Ipsum text anywhere in the UI (search all `.swift` files and asset catalogs)
- [ ] No TODO/FIXME/HACK comments that indicate unfinished work visible to the user
- [ ] All navigation paths are functional — no dead-end screens or unimplemented buttons
- [ ] All URLs (support, privacy policy, terms) are valid and load correctly
- [ ] Login/onboarding flows complete without errors
- [ ] Deep links and universal links resolve correctly (if applicable)
- [ ] App works in airplane mode or gracefully handles no-network state

### 1.2 Privacy Manifest (ITMS-91053 / ITMS-91061) — automated rejection

Enforced since May 1, 2024. Missing declarations cause rejection before human
review.

- [ ] `PrivacyInfo.xcprivacy` exists in the app target
- [ ] All five Required Reason API categories are checked for usage:
  - `NSPrivacyAccessedAPICategoryFileTimestamp` — `creationDate`, `modificationDate`, `stat()`
  - `NSPrivacyAccessedAPICategorySystemBootTime` — `systemUptime`, `mach_absolute_time()`
  - `NSPrivacyAccessedAPICategoryDiskSpace` — `volumeAvailableCapacityKey`, `NSFileSystemFreeSize`
  - `NSPrivacyAccessedAPICategoryActiveKeyboards` — `UITextInputMode.activeInputModes`
  - `NSPrivacyAccessedAPICategoryUserDefaults` — `UserDefaults`
- [ ] Every used Required Reason API has a matching declaration with an approved reason code
- [ ] `NSPrivacyCollectedDataTypes` accurately reflects all data the app collects
- [ ] `NSPrivacyTracking` is set correctly (`true` only if using IDFA/ATT)
- [ ] Third-party SDKs on Apple's list include their own privacy manifests
- [ ] Generate a Privacy Report via Xcode Organizer to cross-check declarations

### 1.3 Subscription & IAP Compliance (Guideline 3.1.1 / 3.1.2)

Second-highest risk area for subscription apps.

**Paywall UI — required disclosures (Guideline 3.1.2(c) + Schedule 2 §3.8(b)):**
- [ ] Subscription name and duration displayed
- [ ] Full renewal price is the **most prominent pricing element** (not monthly equivalent)
- [ ] Free trial duration and post-trial price shown (if applicable)
- [ ] Tappable link to Terms of Use present and functional
- [ ] Tappable link to Privacy Policy present and functional
- [ ] "Restore Purchases" button/mechanism is accessible (Guideline 3.1.1)
- [ ] No dark patterns: no fake urgency, no hiding annual pricing, no pre-selected expensive option without clear disclosure
- [ ] Subscription auto-renewal language present (e.g., "Subscriptions auto-renew unless canceled at least 24 hours before the end of the current period")
- [ ] Cancellation/management instructions present (or use `AppStore.showManageSubscriptions(in:)`)

**Note:** In-app disclosures alone are not sufficient. Section 2.1 checks that
Terms of Use and Privacy Policy links also appear in the App Store description
or EULA field in App Store Connect — Apple requires both.

**StoreKit implementation:**
- [ ] Using StoreKit 2 (not deprecated StoreKit 1 / `SKPaymentQueue`)
- [ ] Transactions are verified (JWS verification or RevenueCat handling)
- [ ] Entitlements update correctly after purchase, restore, and subscription expiry
- [ ] Grace period handling implemented (if enabled in App Store Connect)
- [ ] Sandbox purchases work correctly in the app

**App Store Connect configuration:**
- [ ] IAP products are in "Prepare for Submission" and attached to a review submission (status "Ready for Review" inside that submission) or "Approved" — the standalone "Ready to Submit" terminology predates the current review-submission model
- [ ] IAP **App Review screenshot** is a raw capture of the actual purchase UI at an app-supported device screenshot size (e.g. 6.9" = 1320×2868) — **not** 1024×1024 (that is the adjacent **promotional image** field and will be rejected as a review screenshot)
- [ ] Each IAP has a review screenshot (a shared capture of a purchase sheet showing multiple SKUs is acceptable for each of those SKUs)
- [ ] Per-IAP review notes: how to reach the purchase in-app, what it unlocks, the restore mechanism, and a note if no account is required
- [ ] Subscription group configured correctly
- [ ] Pricing set for all required territories

**Submission topology:** the review-submission assembly rules (which products must ride along with the version, and when) are covered in Section 2.7 — a first-ever IAP has bitten real submissions here.

### 1.4 Privacy & Data Handling (Guideline 5.1)

- [ ] Privacy Policy URL is set in App Store Connect and is accessible
- [ ] Privacy Policy URL is also accessible from within the app
- [ ] App Privacy nutrition labels in App Store Connect match actual data collection
- [ ] If app uses IDFA: ATT prompt is implemented (`ATTrackingManager.requestTrackingAuthorization`)
- [ ] If app uses third-party AI: explicit consent for data sharing (Guideline 5.1.2(i), enforcement Nov 2025)
- [ ] Account deletion option provided if the app has account creation (Guideline 5.1.1(v))

**Pre-permission priming copy (Guideline 5.1.1(iv)):**
- [ ] Grep onboarding/priming views for buttons shown **before** a system permission prompt labeled "Enable …", "Allow …", or "Turn On …" — these must use neutral wording ("Continue"/"Next"); a button that pre-answers the system prompt is a 5.1.1(iv) rejection
- [ ] Explanatory body copy on the priming screen is fine and encouraged — only the button label must be neutral
- [ ] Post-denial screens that point the user to Settings are exempt (they may say "Open Settings")

### 1.4b Face & Biometric Data (Guideline 2.1 / 5.1)

If the app uses Vision / face-detection APIs **at all** — even purely on-device with
zero collection — expect Apple's standard six-question face-data questionnaire during
review. The six question areas are:

1. What face data is collected and how it is used
2. Whether face data is shared with third parties (and who)
3. How long face data is retained
4. Whether/how face data is deleted
5. Where face data is stored (on-device vs. server)
6. Where in the privacy policy this is disclosed (Apple asks you to quote the text)

- [ ] Privacy policy has an explicit, quotable **"Face data"** section covering collection, use, sharing, retention, deletion, and storage — generic "photos" language does **not** satisfy the reviewer
- [ ] That section truthfully enumerates **every** face-detection call site in the binary — Apple falsifies claims against actual API usage (an overlooked export-time detection is enough to fail)
- [ ] No faceprint / face-recognition APIs — or, if present, ADPLA §3.3.3(C)/(K) compliance is documented
- [ ] Third-party AI processors' retention claims match the processor's **own documented** retention policy — claim zero retention only when a contractual Zero Data Retention (ZDR) agreement is actually in place
- [ ] Pre-drafted answers to the six standard questions are kept with the submission metadata (note: the App Store Connect reply box caps at 4,000 characters, so long policy quotes must be excerpted)

### 1.5 App Transport Security

- [ ] No `NSAllowsArbitraryLoads = YES` in Info.plist (unless justified)
- [ ] All network connections use HTTPS / TLS 1.2+
- [ ] If domain exceptions exist via `NSExceptionDomains`, each has a documented justification

### 1.6 Export Compliance

- [ ] `ITSAppUsesNonExemptEncryption` is set in Info.plist
- [ ] If only standard HTTPS (URLSession), value is `NO` (exempt)
- [ ] If custom encryption is used, value is `YES` and CCATS/ERN documentation exists

### 1.7 Entitlements & Capabilities

- [ ] Only required entitlements are present (no unused capabilities)
- [ ] App ID is explicit (non-wildcard) — required for IAP
- [ ] In-App Purchase capability is enabled in Signing & Capabilities
- [ ] Push Notification entitlement present only if push is implemented
- [ ] No `com.apple.developer.in-app-payments` unless Apple Pay is used (this is NOT the IAP entitlement)

**Platform destinations (drive screenshot demands — see 2.2):**
- [ ] `TARGETED_DEVICE_FAMILY` matches product intent (`1` for iPhone-only; the Xcode template default `"1,2"` declares iPad and triggers iPad screenshot demands in App Store Connect)
- [ ] `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD`, Mac Catalyst, and other designed-for destinations are deliberately set, not left at template defaults
- [ ] Note: review may still run the app on an iPad in compatibility mode even when iPad is not a declared destination

### 1.8 Code Quality Flags

- [ ] No `print()` statements in production code (use `os.Logger`)
- [ ] No force-unwraps (`!`) outside of tests
- [ ] No hardcoded API keys, secrets, or tokens in source
- [ ] No references to internal/debug URLs, test servers, or staging endpoints
- [ ] No `#if DEBUG` blocks that expose test UI in release builds

---

## Track 2 — Submission Metadata Checklist

### 2.0 One-Time App Information Gates

These app-level settings silently block the **Add for Review** button until complete —
they are the same class of gate as the age-rating questionnaire (Section 2.5).

- [ ] **Content Rights Information** declared on the App Information page (does the app contain third-party content, yes/no — the answer is app-specific: typically "no" for user-generated-only content, "yes" when displaying external/web content)
- [ ] All required App Information fields complete before the first **Add for Review**

### 2.1 App Store Connect Metadata

- [ ] App Name: ≤30 characters, no keyword stuffing
- [ ] Subtitle: ≤30 characters
- [ ] Description: hook in first line, benefits over features, no placeholder text
- [ ] Keywords: ≤100 characters, comma-separated, no spaces after commas, no duplicates of title words
- [ ] Promotional Text: set (editable without new version)
- [ ] What's New: written in plain language, user-benefit framing
- [ ] Support URL: set and loads correctly
- [ ] Privacy Policy URL: set and loads correctly
- [ ] If app has subscriptions: Terms of Use (EULA) link in App Description OR custom EULA set in App Store Connect
- [ ] If app has subscriptions: Privacy Policy link in App Description
- [ ] If app has subscriptions: auto-renewal language in App Description (price, duration, cancellation)
- [ ] Copyright: set with current year and correct entity name
- [ ] Primary Category and optional Secondary Category set appropriately

### 2.2 Screenshots & Previews

- [ ] At least one screenshot set at an exact iPhone upload-slot spec: 6.9" = 1320×2868 or 6.5" = 1284×2778 — other real device sizes (e.g. 6.3") are **not** valid upload slots
- [ ] iPad screenshots if universal app
- [ ] Screenshot demands beyond iPhone (iPad, visionOS) mean the target's declared destinations should be re-audited — see Section 1.7 (`TARGETED_DEVICE_FAMILY` / designed-for defaults are the usual cause)
- [ ] Screenshots are in JPEG or PNG format
- [ ] No placeholder or obviously fake screenshots
- [ ] App previews ≤30 seconds, H.264 or ProRes 422 (if used)
- [ ] Screenshots show actual app UI (not misleading)

### 2.3 App Icon

- [ ] 1024x1024 App Store icon provided
- [ ] Icon does not contain transparency or alpha channel
- [ ] Icon is not a duplicate of another app's icon
- [ ] In-app icon matches App Store icon

### 2.4 Version & Build

- [ ] Version number bumped appropriately (semantic versioning)
- [ ] Build number incremented from last upload
- [ ] Both app target AND extension targets (if any) have matching version/build
- [ ] Built with the current required SDK version

### 2.5 Age Rating

- [ ] Age rating questionnaire completed in App Store Connect
- [ ] Rating reflects actual content (especially AI/chatbot content if applicable)
- [ ] If expanded age ratings apply (13+/16+/18+): responses updated by Jan 31, 2026 deadline

### 2.6 Review Notes

- [ ] If app has login: demo credentials provided in review notes
- [ ] If app has special flows (subscriptions, hardware features): instructions provided
- [ ] If app uses on-device AI: note about device/OS requirements
- [ ] If app has subscriptions: review notes describe where in-app subscription disclosures can be found (paywall location, settings, etc.)
- [ ] Contact information for the reviewer is current

### 2.7 Review Submission Assembly (Guideline 2.1(b))

App Store Connect groups a version and its IAPs into a single **review submission**.
The topology rules below are not obvious in the UI and cause 2.1(b) App Completeness
rejections:

- The **first-ever IAP of an app MUST be attached to the SAME review submission as the app version.** Submitting the version alone while products sit in "Prepare for Submission" triggers a 2.1(b) rejection ("app includes references to a product but the associated In-App Purchase products have not been submitted") — and Apple's prescribed remedy is submitting the IAPs **plus a new binary**.
- **One review submission per platform at a time.** While a version is Waiting for Review / In Review, IAPs sent for review land in a **separate draft submission** that cannot be submitted and does **not** ride along automatically. If the version submission is already sealed, there is no UI path to attach them — you wait for a rejection or approval.

Checks:
- [ ] All IAP products referenced by the binary are **attached to the same review submission as the version** (not merely in a "ready" state)
- [ ] First-ever IAP: confirmed **inside the version's submission BEFORE** clicking **Add for Review** on the version
- [ ] If a version is already in review without its IAPs: expect 2.1(b) — prepare a new build number in advance
- [ ] Launch-timing: an approved version with unapproved IAPs ships a paywall that cannot load products — hold manual release until the IAPs are approved if needed

---

## Output Format

After running all checks, produce this summary:

```
## App Store Review Audit — [App Name]
Date: [YYYY-MM-DD]

### Results
| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1.1 | App Completeness | PASS/WARN/FAIL | ... |
| 1.2 | Privacy Manifest | PASS/WARN/FAIL | ... |
| ... | ... | ... | ... |

### Critical Issues (FAIL — must fix before submission)
- [list]

### Warnings (WARN — should fix, risk of rejection)
- [list]

### Recommendations
- [list]
```

If there are zero FAIL items, state: "No blocking issues found. Ready for submission."

---

## When Requirements Change

Apple publishes enforcement deadlines at:
`https://developer.apple.com/news/upcoming-requirements/`

If the user mentions a specific deadline or new requirement, cross-reference
with `references/appstore-review-ref.md` Section 8 for the latest tracked changes.
