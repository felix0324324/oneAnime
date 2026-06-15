# Quality Guidelines

> Code quality standards for frontend development.

---

## Overview

<!--
Document your project's quality standards here.

Questions to answer:
- What patterns are forbidden?
- What linting rules do you enforce?
- What are your testing requirements?
- What code review standards apply?
-->

(To be filled by the team)

---

## Forbidden Patterns

<!-- Patterns that should never be used and why -->

(To be filled by the team)

---

## Required Patterns

### Convention: tvOS Implementation

**What**: tvOS support must live in a native Swift Apple TV project under `tvos/OneAnimeTV`. Do not add or regenerate Flutter-based tvOS hosts; Flutter does not provide an official Apple tvOS target.

**Why**: A Flutter-style `Runner` scaffold can parse as an Xcode project but is not a reliable Apple TV app path. Native tvOS code can use UIKit focus, `UITabBarController`, collection-view grids, and `AVPlayerViewController`.

**Contracts**:
- Anime list: `GET https://d1zquzjgwo9yb.cloudfront.net/`
- Anime page: `GET https://anime1.me/?cat=<id>`
- Video source: `POST https://v.anime1.me/api` with form body `d=<data-apireq>`
- Playback headers: include `User-Agent`, `Referer: https://anime1.me`, and filtered video cookies.

---

## Testing Requirements

<!-- What level of testing is expected -->

(To be filled by the team)

---

## Code Review Checklist

<!-- What reviewers should check -->

(To be filled by the team)
