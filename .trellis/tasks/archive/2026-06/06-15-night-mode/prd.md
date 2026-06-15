# brainstorm: night mode feature

## Goal

Add a quick night mode toggle button and feature to allow users to easily switch between light and dark themes without navigating deep into the settings.

## What I already know

* The app already has a `ThemeProvider` and `ThemeSettingsPage` which supports `light`, `dark`, and `system` theme modes.
* The state is persisted in Hive (`SettingBoxKey.themeMode`).
* The app uses a custom `SysAppBar` widget for its top bar.
* The main pages are managed by `ScaffoldMenu` (`lib/pages/menu/menu.dart`) which has a bottom navigation bar for mobile and a side navigation rail for desktop/landscape.
* The `PopularPage` (home) has a `SysAppBar` with a search field, but no action buttons currently except the window controls on desktop.

## Assumptions (temporary)

* The user wants a quick toggle button on the UI (e.g., in the AppBar or side menu) to toggle the theme mode between `light` and `dark` (or `system`).
* The existing `ThemeProvider` is sufficient for the "feature" part, we just need to expose it nicely and ensure it works seamlessly.

## Open Questions

* (Resolved) User preference: Placed on the "My" (Settings) page. Just click to switch sun/moon, no popups.

## Requirements (evolving)

* A toggle button (Sun/Moon icon) located on the `MyPage` (Settings page).
* The toggle should sync with the existing `ThemeProvider` and switch between `light` and `dark` modes immediately on click.
* No dialogs or popups should appear.
* The state should be persisted using the existing Hive mechanism.

## Acceptance Criteria (evolving)

* [x] Clicking the night mode button toggles the app's theme immediately.
* [x] The icon reflects the current mode (e.g., Sun for light mode, Moon for dark mode).
* [x] The setting is persisted across app restarts.

## Definition of Done (team quality bar)

* Tests added/updated (unit/integration where appropriate)
* Lint / typecheck / CI green
* Docs/notes updated if behavior changes

## Out of Scope (explicit)

* Redesigning the entire app's color palette (relying on existing Material You colors).

## Technical Notes

* Files impacted: `lib/pages/popular/popular_page.dart` (or other pages if we add it to the global AppBar), `lib/pages/my/my_page.dart`, `lib/bean/settings/theme_provider.dart`.
