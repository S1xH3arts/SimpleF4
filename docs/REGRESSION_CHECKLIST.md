# SimpleF4 Regression Checklist

Run `simplef4_regression` as a superadmin or from server console first.

## Core menu

- F4 opens once and replaces the default DarkRP menu.
- F4 closes with F4 and Escape.
- Dashboard, Jobs, Entities, Weapons, Modules and Settings open.
- `/` focuses supported search fields.
- Maintenance mode only leaves the intended pages available.
- Permission Preview does not permanently alter the local player's settings.

## Jobs

- Categories expand/collapse.
- Hidden/locked jobs respect permissions.
- Job model preview loads and cycles models.
- Full jobs and prerequisite jobs show the correct state.
- Changing job closes the menu when configured.

## Entities / Weapons

- Categories and searches work.
- Affordability states update.
- Purchases invoke the configured DarkRP command.
- Purchase cooldown/confirmation still behaves as configured.

## HUD

- Core HUD cannot be disabled by players.
- Steam avatar/model portrait selector swaps cleanly.
- Health, armour, hunger, wallet, salary and job always display.
- Money/HP/armour feedback appears beside the HUD, not above the server bar.
- FED/HUNGRY/STARVING states use the configured thresholds.
- Ammo box only appears when appropriate.

## Modules

- Modules page search filters cards.
- Module Status and Module Testing are visible only to superadmins.
- Notifications wrap long text.
- Voice HUD appears/disappears correctly.
- Laws/agenda obey personal visibility settings.
- Lockdown warning appears only during lockdown.
- Door HUD appears only when looking at a supported door.
- Level bar reports waiting state if no provider exists.
- Wanted/warrant overhead data respects available DarkRP/provider data.

## Languages

- Switch through every bundled language.
- Missing keys fall back to English.
- No language file throws an unfinished-string Lua error.

## Live reload

- `simplef4_reload` refreshes currently-open menus.
- `simplef4_refresh_shared` reloads watched shared files.
- Module shared config changes apply without reconnecting.

## Updates

- GitHub provider gracefully handles blank repository configuration.
- Public GitHub Release returns its tag/version.
- Raw provider still accepts a plain text semantic version.
- A newer version fires `SimpleF4_UpdateAvailable`.

## Commands

- Server console can use all commands.
- Admin/superadmin permissions match `C.CommandPermissions`.
- Lower ranks cannot invoke protected commands.
- `simplef4_commands` only lists commands the caller can use.
