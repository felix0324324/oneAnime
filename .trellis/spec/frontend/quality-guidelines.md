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

### Convention: Platform Checks

**What**: Use `AppPlatform` from `lib/utils/app_platform.dart` for platform intent checks instead of scattering raw `Platform.is*` combinations when behavior differs by device class.

**Why**: tvOS can share Apple/iOS runtime paths while needing living-room layout behavior. Centralizing checks keeps phone, desktop, and TV behavior from drifting.

**Example**:
```dart
if (AppPlatform.isHandheldMobile) {
  // phone-only status bar or compact UI behavior
}

if (AppPlatform.usesTVLayout) {
  // landscape, remote-friendly TV behavior
}
```

---

## Testing Requirements

<!-- What level of testing is expected -->

(To be filled by the team)

---

## Code Review Checklist

<!-- What reviewers should check -->

(To be filled by the team)
