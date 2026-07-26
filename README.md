# SimpleF4

SimpleF4 is an open-source DarkRP F4 menu and HUD framework for Garry's Mod.

**Current release:** `v42.0.6 stable — Release Polish`

## Features

- Modern DarkRP F4 menu
- Jobs, entities and weapons with search/category support
- Dashboard, announcements and maintenance mode
- Permission-aware pages/categories/content
- Modular HUD system
- Player overhead information
- Notifications, laws/agenda, lockdown, voice, doors, wanted/warrant and level modules
- Player language selection
- Theme presets
- Shared-file auto refresh
- Module dependencies/runtime status
- Public developer APIs and module examples

## Installation

Place:

```text
simple_f4/
```

inside:

```text
garrysmod/addons/
```

Then restart the server and edit:

```text
lua/simplef4/config/sh_config.lua
```

Module-specific tuning lives beside each module:

```text
lua/simplef4/modules/<module>/sh_<module>.lua
```

## Quick configuration

The top of `sh_config.lua` contains a configuration map.

The main areas are:

```text
BRANDING / LANGUAGE
MENU / PAGES
MODULES
THEME / APPEARANCE
PERMISSIONS / VISIBILITY
DASHBOARD / ANNOUNCEMENTS
DEVELOPER / AUTO REFRESH
```

## GitHub update support

SimpleF4 can check the newest published GitHub Release.

```lua
C.UpdateCheck = {
    Enabled = true,
    Provider = "github",

    GitHub = {
        Owner = "S1xH3arts",
        Repository = "SimpleF4",
        ReleasesURL = "https://github.com/S1xH3arts/SimpleF4/releases",
    },

    RawURL = "",
    Interval = 21600,
    Verbose = true,
}
```

The GitHub provider reads the latest published release tag. Public repository
release data does not require authentication. GitHub's documented endpoint is
`GET /repos/{owner}/{repo}/releases/latest`.

Legacy plain-text version checking remains available:

```lua
Provider = "raw"
RawURL = "https://example.com/simplef4-version.txt"
```

The plain-text response should be a version such as:

```text
42.0.1
```

## Release metadata

Available at runtime:

```lua
SimpleF4.Version
SimpleF4.Release
SimpleF4.ReleaseName
```

For this release:

```text
Version: 42.0.6
Channel: stable
Name: Release Polish
```

## Console commands

Command access is controlled in:

```lua
C.CommandPermissions
```

Server console always has access.

| Command | Purpose |
| --- | --- |
| `simplef4_version` | Installed release information |
| `simplef4_status` | Short addon/module summary |
| `simplef4_reload` | Refresh currently-open F4 menus |
| `simplef4_refresh_shared` | Reload watched shared Lua files |
| `simplef4_modules` | Print module states |
| `simplef4_updatecheck` | Force an update check |
| `simplef4_regression` | Run server-side regression self-check |
| `simplef4_maintenance_toggle` | Toggle runtime maintenance |
| `simplef4_commands` | List commands available to the caller |

Example:

```lua
C.CommandPermissions = {
    status = {
        admin = true,
        superadmin = true,
    },

    update = {
        superadmin = true,
    },
}
```

Do not give ranks commands they do not need.

## Modules

Official modules are automatically discovered from:

```text
lua/simplef4/modules/<module>/
```

Recommended structure:

```text
my_module/
├── sh_module.lua
├── cl_module.lua
└── sv_module.lua
```

Files are loaded by prefix:

- `sh_` — shared
- `cl_` — client
- `sv_` — server

A complete example is included in:

```text
lua/simplef4/examples/modules/example_status_module/
```

### Register a module

```lua
SimpleF4.RegisterModule("MyModule", {
    Name = "My Module",
    Version = "1.0.0",

    Depends = {
        "HUD",
    },

    OptionalDepends = {
        "Notifications",
    },
})
```

### Runtime status

```lua
SimpleF4.SetModuleRuntimeStatus(
    "MyModule",
    "ready",
    "Provider detected."
)
```

Superadmins can inspect module status from the Modules page.

## Notifications API

Legacy:

```lua
SimpleF4.Notify("Saved!", "success")
```

Rich notification:

```lua
SimpleF4.Notify({
    Title = "Purchase Complete",
    Text = "You purchased an item.",
    Type = "success",
    Icon = "icon16/accept.png",
    Duration = 5,
})
```

Built-in types include:

```text
info
success
warning
error
money
wanted
level
```

## Level provider API

```lua
SimpleF4.RegisterLevelProvider(
    "MyLevels",
    function(ply)
        return {
            Level = 12,
            XP = 450,
            MaxXP = 1000,
        }
    end,
    100
)
```

## Localisation

Language files live in:

```text
lua/simplef4/languages/
```

Register strings through:

```lua
SimpleF4.RegisterLanguage(...)
```

Use translated strings with:

```lua
SimpleF4.L("MyKey")
```

Bundled languages:

```text
English
German
French
Spanish
Dutch
Polish
```

Missing keys fall back to English.

## Live development

`simplef4_refresh_shared` watches/reloads supported shared files.

Watched areas include:

```text
config/sh_config.lua
core/sh_functions.lua
modules/*/sh_*.lua
```

`simplef4_reload` rebuilds currently-open F4 menus against the currently loaded
configuration.

## Regression testing

A manual regression checklist is included at:

```text
docs/REGRESSION_CHECKLIST.md
```

Start with:

```text
simplef4_regression
```

Then perform the client/UI checks from the checklist in a DarkRP server.

The included automated check verifies core registration/configuration state; it
does not replace actual in-game testing of Derma, HUD drawing, DarkRP purchases
or third-party addon compatibility.

## Changelog

See:

```text
CHANGELOG.md
```

## License / redistribution

Add the licence you want to release SimpleF4 under before publishing the
repository publicly.
