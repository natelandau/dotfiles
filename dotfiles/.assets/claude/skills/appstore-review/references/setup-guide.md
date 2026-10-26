---
last_verified: "2026-03-30"
---

# appstore-review — Setup & Usage Guide

This guide helps you wire the `appstore-review` skill into your AI coding agent
so it works reliably in your projects.

---

## 1. Install the skill

### Option A: Install script

```bash
git clone https://github.com/3paws-ai/mobile-ai-skills.git
cd mobile-ai-skills
./scripts/install.sh appstore-review
```

This copies the skill to `~/.claude/skills/appstore-review/`.

### Option B: Manual copy

```bash
cp -R skills/appstore-review ~/.claude/skills/appstore-review
```

### Verify installation

After installing, confirm these files exist:

```
~/.claude/skills/appstore-review/
  SKILL.md
  references/
    appstore-review-ref.md
    setup-guide.md
```

---

## 2. Register the skill in your CLAUDE.md

For Claude Code to know about the skill, add it to your `~/.claude/CLAUDE.md`
(global) or your project's `CLAUDE.md`. Add an entry to your skills table:

```markdown
## Skills

| Task | Skill to read |
|---|---|
| App Store review readiness audit | `~/.claude/skills/appstore-review/SKILL.md` |
```

This tells the agent where to find the skill when invoked.

---

## 3. Optional: Add a standing checklist

If you submit to the App Store regularly, add a quick-reference checklist to
your CLAUDE.md so the agent flags these even outside of a full audit:

```markdown
## App Store Submission — Standing Checklist
Before any release, verify:
- [ ] All new APIs have Privacy Manifest entries (`PrivacyInfo.xcprivacy`)
- [ ] App Tracking Transparency prompt implemented if using IDFA
- [ ] No placeholder or Lorem Ipsum text anywhere in the UI
- [ ] All required device screenshots generated (6.9", 6.5", iPad if universal)
- [ ] Release notes written in plain language, user-benefit framing
- [ ] Version and build number bumped in both targets (app + extensions)
- [ ] TestFlight beta tested on a real device before submission
- [ ] App Review notes drafted if app has any login, special flows, or content
```

This is a lightweight complement to the full audit — the audit is comprehensive
while the checklist is a quick gate.

---

## 4. How to invoke

From your iOS project directory in Claude Code:

```
/appstore-review
```

The agent reads `SKILL.md` and systematically inspects your project — Swift
source, Info.plist, entitlements, xcprivacy manifests, asset catalogs, and
project configuration.

**The skill runs all checks in order without prompting.** You don't pick
sections. It inspects everything and produces a summary.

---

## 5. When to run it

| Timing | Why |
|--------|-----|
| Before every App Store submission | Primary use case — full pre-submission audit |
| Before TestFlight builds | Catch issues before they reach testers |
| After adding subscriptions or IAP | Paywall compliance checks are detailed and easy to miss |
| After updating privacy-sensitive APIs | Privacy manifest declarations must match actual usage |
| After a major dependency update | Third-party SDKs may introduce new privacy manifest requirements |

---

## 6. What output to expect

The skill reports each check as **PASS**, **WARN**, or **FAIL** and ends with a
summary table:

```
## App Store Review Audit — YourApp
Date: 2026-03-30

### Results
| #   | Check              | Status | Notes                              |
|-----|--------------------|--------|------------------------------------|
| 1.1 | App Completeness   | PASS   | No placeholder text found          |
| 1.2 | Privacy Manifest   | WARN   | UserDefaults reason code missing   |
| 1.3 | Subscription IAP   | PASS   | All disclosures present            |
| ... | ...                | ...    | ...                                |

### Critical Issues (FAIL — must fix before submission)
- None

### Warnings (WARN — should fix, risk of rejection)
- 1.2: PrivacyInfo.xcprivacy declares UserDefaults but no reason code

### Recommendations
- Add reason code C617.1 for UserDefaults access
```

If there are zero FAIL items: **"No blocking issues found. Ready for submission."**

---

## 7. Sections that don't apply to your app

The skill adapts to your project:

- **No subscriptions?** — IAP/paywall checks report PASS (not applicable). The
  skill detects StoreKit usage before evaluating compliance.
- **No push notifications?** — Push entitlement check skips gracefully.
- **No IDFA usage?** — ATT prompt check reports PASS.

You don't need to configure which sections to run.

---

## 8. Keeping the skill current

Apple publishes enforcement deadlines at:
`https://developer.apple.com/news/upcoming-requirements/`

The reference file (`references/appstore-review-ref.md`) catalogs ~60 source
URLs with a `last_verified` date. Section 8 of that file tracks time-sensitive
requirements for 2024-2026.

If you find a new requirement or a stale URL:
- Update the reference file
- Bump the version in `SKILL.md` frontmatter
- Update `last_verified`
- Consider contributing the fix back to the repo
