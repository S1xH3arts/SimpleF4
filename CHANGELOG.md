# Changelog

All notable SimpleF4 changes are documented here.

## 42.0.6

- Added a clear SimpleF4 startup banner to the server console.
- Startup now prints installed version, release channel, release name and update provider.
- GitHub update checking is enabled by default for `S1xH3arts/SimpleF4`.
- Update checks now always print the latest GitHub release version, even when the server is already up to date.

## 42.0.5

- Fixed module section headers being covered by their first setting row.
- Added reserved header space to every player module card and Module Testing.
- Added a clear header background/divider to each module box.
- Reset the Modules page scrollbar to the top when the page is built.
- Kept the SimpleF4 custom scrollbar.

## 42.0.4

- Replaced the Modules page masonry/two-column card layout with a deterministic full-width stacked layout.
- Removed manual column reparenting that caused clipping, overlap and partially-visible cards while scrolling.
- Kept Module Status internally two-column only when there is enough width.
- Kept the real SimpleF4 custom scrollbar through `SimpleF4.StyleScrollPanel`.
- Search now hides whole module sections without recalculating manual card positions.

## 42.0.3

- Rebuilt the Modules page layout to prevent large gaps and mismatched card flow.
- Module Testing and Module Status now stack cleanly at the top for superadmins.
- Player module settings use balanced two-column packing and fall back to one column on narrow screens.
- Fixed the Modules page to use `SimpleF4.StyleScrollPanel`, matching the custom SimpleF4 scrollbar.
- Improved the Modules search placeholder/rendering.

## 42.0.2

- Fixed a Lua syntax error in `core/sv_core.lua` caused by the new command wrapper around `simplef4_reload`.
- Removed the stale duplicate `canReload` permission check from that command.

## 42.0.1

- Connected the built-in GitHub update checker to `S1xH3arts/SimpleF4`.
- Added the public GitHub Releases URL to the default configuration.

## 42.0.0 — Release Polish

- Added release metadata: version, channel and release name.
- Added GitHub Releases update checking.
- Retained legacy raw-text update checking as an optional provider.
- Added rank-scoped console command permissions.
- Added `simplef4_status`, `simplef4_modules`, `simplef4_updatecheck`,
  `simplef4_regression` and `simplef4_commands`.
- Added a server-side regression self-check.
- Reworked README into a release-oriented guide.
- Added a formal regression checklist.
- Module/status/test tools remain permission-aware.

## 41.0.0

- Redesigned Modules page with compact cards and search.
- Added shared HUD visual helpers.
- Improved configuration organisation.
- Added module-development examples and recommended file structure.

## 40.2.0

- Added FED/HUNGRY/STARVING hunger states.
- Added health and armour change feedback.
- Added health/armour bar flashes.
- Kept Module Status superadmin-only and the core HUD always enabled.

## 40.0.0

- Added module dependencies and runtime statuses.
- Added Module Status.
- Added rich custom notification API.
- Added hunger warnings and level-up notifications.
- Improved wanted/warrant overhead details.

## 39.x

- Added the modular HUD suite: notifications, laws/agenda, lockdown, voice,
  wanted/warrant, door HUD and level provider support.
- Added module test mode and the dedicated Modules page.
- Added shared-file auto refresh.
