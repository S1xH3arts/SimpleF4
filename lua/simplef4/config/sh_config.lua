local C = SimpleF4.Config

--=====================================================
-- QUICK CONFIG MAP
--=====================================================
--
-- BRANDING / LANGUAGE
--   ServerName, Subtitle, Language, server links
--
-- MENU / PAGES
--   menu size, page visibility, close behaviour
--
-- MODULES
--   enable/disable official modules
--   individual module tuning lives in:
--   lua/simplef4/modules/<module>/sh_<module>.lua
--
-- THEME / APPEARANCE
--   theme presets, colours, density
--
-- PERMISSIONS / VISIBILITY
--   pages, categories, hidden content, staff
--
-- DASHBOARD / ANNOUNCEMENTS
--   dashboard cards, announcements, maintenance
--
-- DEVELOPER / AUTO REFRESH
--   live shared-file refresh and debug options
--
-- The addon is intentionally split this way so sh_config.lua contains
-- server-wide policy, while each module owns its own tunable defaults.


--=====================================================
-- BRANDING
--=====================================================

C.ServerName = "DarkRP Server"
C.Language = "en"

-- Let each player choose from languages registered with
-- SimpleF4.RegisterLanguage().
C.AllowPlayerLanguageSelection = true

-- Language files live in:
--   lua/simplef4/languages/
--
-- Add a new .lua file there and register it with:
-- SimpleF4.RegisterLanguage("fr", {
--     Dashboard = "Tableau de bord",
--     Jobs = "Métiers",
-- }, "Français")
--
-- Files are discovered automatically. No autorun edit is required.
-- Missing keys fall back to en.lua.
-- Developers can run: simplef4_language_missing <code>
C.Subtitle = "Roleplay Menu"

C.WebsiteURL = "https://example.com"
C.DiscordURL = "https://discord.gg/example"
C.DonateURL = "https://example.com/donate"
C.RulesURL = "https://example.com/rules"


-- Extra top navigation links.
-- Supported types:
--   "url"     -> gui.OpenURL(Value)
--   "chat"    -> say Value
--   "command" -> LocalPlayer():ConCommand(Value)
--
-- Order controls left-to-right order amongst custom navbar buttons.
C.NavButtons = {
    -- {
    --     Name = "Forums",
    --     Type = "url",
    --     Value = "https://example.com/forums",
    --     Order = 10,
    --
    --     -- Optional permissions:
    --     UserGroups = { admin = true, superadmin = true },
    --     Teams = { TEAM_POLICE },
    --     Categories = { ["Police Department"] = true },
    --     JobNames = { ["Police Officer"] = true },
    --     SteamIDs = { ["STEAM_0:1:123456"] = true },
    --     SteamID64s = { ["76561198000000000"] = true },
    --     AdminOnly = false,
    --     SuperAdminOnly = false,
    --     MinPlaytimeSeconds = 0, -- uses SimpleF4_GetPlaytime hook
    --     CustomCheck = function(ply) return true end,
    -- },
    -- {
    --     Name = "Workshop",
    --     Type = "url",
    --     Value = "https://steamcommunity.com/sharedfiles/...",
    --     Order = 20,
    -- },
}

-- Optional navbar dropdown for servers with many links.
C.NavDropdown = {
    Enabled = false,
    Name = "More",

    Items = {
        -- {
        --     Name = "Forums",
        --     Type = "url",
        --     Value = "https://example.com/forums",
        -- },
    },
}


--=====================================================
-- MORE MENU
--=====================================================

-- Instead of using a full Links page, server links live in one
-- compact MORE button on the right side of the navbar.
C.MoreMenu = {
    Enabled = true,
    Name = "More",
    Width = 250,

    -- Built-in links are added automatically when their URL is set:
    -- Website, Discord, Donate and Rules.
    --
    -- C.NavButtons and C.NavDropdown.Items are also merged into this menu.
}


--=====================================================
-- MENU
--=====================================================

C.Width = 0.82
C.Height = 0.82
C.MinWidth = 900
C.MinHeight = 620

-- UI measurements use a 1920x1080 reference scale:
--   scale = min(ScrW()/1920, ScrH()/1080, 1)
-- This matches the screen-scaling method from the original server menu:
-- it scales DOWN on smaller resolutions but never makes the UI oversized
-- above 1080p.
C.ReferenceWidth = 1920
C.ReferenceHeight = 1080

C.DefaultPage = "Dashboard"

C.EnableBlur = true
C.CloseOnJobChange = true
C.CloseOnPurchase = true

-- Show the player's current job and wallet beneath their name
-- in the top-right of the F4 menu.
C.ShowHeaderJob = true
C.ShowHeaderMoney = true

--=====================================================
-- UPDATE CHECKER
--=====================================================

C.UpdateCheck = {
    Enabled = true,

    -- "github" uses the latest published GitHub Release.
    -- "raw" keeps compatibility with the older plain-text version URL.
    Provider = "github",

    GitHub = {
        Owner = "S1xH3arts",
        Repository = "SimpleF4",

        -- Public releases page shown in status output.
        ReleasesURL = "https://github.com/S1xH3arts/SimpleF4/releases",
    },

    RawURL = "",

    -- Minimum enforced interval is one hour.
    Interval = 21600,

    -- Prints the newest release name/body URL information to console.
    Verbose = true,
}

--=====================================================
-- PAGES
--=====================================================

-- Individual pages can be disabled without editing the UI code.
C.Pages = {
    Dashboard = true,
    Jobs = true,
    Entities = true,
    Weapons = true,
    Settings = true,
    Modules = true,
}



--=====================================================
-- MODULES
--=====================================================

-- Official and community modules are loaded automatically from:
-- lua/simplef4/modules/<module_name>/
--
-- A module can be disabled here without deleting its files.
C.Modules = {
    HUD = {
        Enabled = true,

        -- Core SimpleF4 HUD is always visible for players.
        AllowPlayerDisable = false,
    },
}

--=====================================================
-- MODULE UI STYLE
--=====================================================

-- Shared presentation rules used by official HUD modules.
-- Keeping these values together makes the HUD suite feel consistent.
C.ModuleUI = {
    Border = true,
    AccentWidth = 3,
    Padding = 10,
    Gap = 6,
    IconSize = 16,
    ShadowAlpha = 190,
}

--=====================================================
-- SHARED FILE AUTO REFRESH
--=====================================================

-- Watches SimpleF4 shared Lua files and applies changes live.
--
-- Watched:
--   config/sh_config.lua
--   core/sh_functions.lua
--   modules/*/sh_*.lua
--
-- This is especially useful while tuning HUD/Overhead module values.
C.AutoRefresh = {
    Enabled = true,

    -- Seconds between file-content checks.
    Interval = 1,

    -- Print changed files/reload status in server console.
    Debug = true,
}

--=====================================================
-- ACCESSIBILITY
--=====================================================

C.Accessibility = {
    -- Multiplies SimpleF4 font sizes. Recommended range: 0.85 - 1.35
    TextScale = 1.0,

    -- Disables page fade animations.
    ReduceMotion = false,

    -- Uses brighter separators/text contrast.
    HighContrast = false,

    -- Turns off menu blur regardless of C.EnableBlur.
    DisableBlur = false,
}


--=====================================================
-- PLAYER SETTINGS PAGE
--=====================================================

C.PlayerSettings = {
    Enabled = true,

    -- These are the defaults before a player changes their own setting.
    ReduceMotion = false,
    DisableBlur = false,
    Tooltips = true,

    -- Reopen the page the player last used.
    RememberLastPage = true,

    -- Start categories collapsed for this player.
    CollapseCategories = false,

    -- Player-side visibility preferences.
    ShowResultCount = true,
    ShowPageSubtitles = true,

    -- Layout density: "Comfortable" or "Compact".
    Density = "Comfortable",

    -- Page-specific display preferences.
    JobsShowDescriptions = true,
    JobsShowLocked = true,

    -- When enabled, eligible job rows use BECOME instead of VIEW JOB
    -- and skip the preview screen. Locked/full/current checks still apply.
    JobsQuickJoin = false,
    JobsQuickJoinConfirmVote = true,

    -- Superadmin-only personal controls.
    SuperAdminShowHiddenStuff = false,
    SuperAdminBypassChecks = false,
    SuperAdminHideSelfFromStaff = false,
    SuperAdminDeveloperTools = false,
    SuperAdminPermissionPreview = false,
    EntitiesShowLimits = true,
    EntitiesShowAffordability = true,
    WeaponsShowLimits = true,
    WeaponsShowAffordability = true,

    -- Official HUD module.
    HUDEnabled = true,
    HUDShowHealth = true,
    HUDShowArmour = true,
    HUDShowHunger = true,
    HUDShowMoney = true,
    HUDShowSalary = true,
    HUDShowJob = true,
    HUDShowAvatar = true,
    HUDShowAmmo = true,
    HUDCompact = false,
    HUDPortraitMode = "Avatar",
    HUDShowLockdown = true,
    HUDShowAgenda = true,

    -- Official Overhead module.
    OverheadEnabled = true,
    OverheadShowWanted = true,
    OverheadShowSpeaking = true,
    OverheadShowLicence = true,
    OverheadFadeDistance = true,

    NotificationsEnabled = true,
    VoiceHUDEnabled = true,
    LawsAgendaEnabled = true,
    LawsAgendaShowLaws = true,
    LawsAgendaShowAgenda = true,
    LockdownHUDEnabled = true,
    WantedHUDEnabled = true,
    DoorHUDEnabled = true,
    LevelHUDEnabled = true,
}

--=====================================================
-- UI OPTIONS
--=====================================================

C.UI = {
    SearchEnabled = true,
    ShowPageSubtitles = true,
    ShowCategoryCounts = true,
    ShowJobDescriptions = true,
    ShowSearchResultCount = true,
    ShowSearchClearButton = true,

    -- Start all category headers closed instead of open.
    CategoriesDefaultCollapsed = false,
}

--=====================================================
-- DASHBOARD
--=====================================================

C.Dashboard = {
    ShowPlayersOnline = true,
    ShowStaffOnline = true,
    ShowWallet = true,

    ShowServerOverview = true,
    ShowRichestPlayer = true,
    ShowPoorestPlayer = true,
    ShowMostKills = true,

    ShowStaffList = true,

    -- Clicking a staff card opens their Steam profile.
    StaffCardsOpenSteamProfile = true,

    -- Staff card display options.
    ShowSteamAvatar = true,
    ShowStaffSteamID = true,
    ShowStaffPing = true,
}

--=====================================================
-- STAFF
--=====================================================

-- Rank display names.
C.StaffGroups = {
    superadmin = "Super Administrator",
    admin = "Administrator",
    moderator = "Moderator",
}

-- Colours used for normal staff ranks.
-- Add any ULX/SAM/SAdmin/etc. usergroups here.
C.StaffGroupColours = {
    superadmin = Color(220, 75, 75),
    admin = Color(70, 145, 235),
    moderator = Color(75, 190, 120),
}

-- Optional SteamID-specific roles.
--
-- SpecialRoles override BOTH the rank name and rank colour.
--
-- String format is still supported:
-- ["STEAM_0:1:123456"] = "Developer",
--
-- Recommended format:
-- ["STEAM_0:1:123456"] = {
--     Name = "Developer",
--     Color = Color(185, 95, 235),
-- },
C.SpecialRoles = {}

-- Fallback colour if a staff rank has no colour configured above.
C.DefaultStaffColour = Color(47, 132, 225)

-- Optional NWBool used by your own staff stealth system.
-- Leave blank to disable stealth filtering.
C.StaffStealthNWBool = ""


--=====================================================
-- JOBS
--=====================================================

C.Jobs = {
    -- "category", "alphabetical", "salary", "players"
    SortMode = "category",

    -- When false, jobs that fail allowed/customCheck remain visible
    -- and show as LOCKED instead of disappearing.
    HideLockedJobs = false,

    ShowRequirements = true,

    -- Optional extra progression protection.
    -- 0 = disabled.
    -- Example: 300 requires a player to stay in the prerequisite job
    -- for 5 minutes before moving to a promoted job.
    MinimumTimeInRequiredJob = 0,
}

-- Optional requirement provider.
-- Return a table of { Text = "...", Passed = true/false } entries.
-- Servers can replace this function or use the hook documented below.
C.GetJobRequirements = function(job, teamID, ply)
    return {}
end



--=====================================================
-- HIDDEN JOBS
--=====================================================

-- Completely remove selected DarkRP jobs from SimpleF4.
-- They will not appear in categories, searches, counts, VIEW JOB or Quick Job.
C.HiddenJobs = {
    Names = {
        -- ["Mayor"] = true,
    },

    Commands = {
        -- ["mayor"] = true,
    },

    TeamIDs = {
        -- [TEAM_MAYOR] = true,
    },
}

--=====================================================
-- HIDDEN WEAPONS / SHIPMENTS
--=====================================================

-- Completely remove selected DarkRP weapons/shipments from SimpleF4.
-- Match by displayed Name, weapon Class, or shipment Entity class.
C.HiddenWeapons = {
    Names = {
        -- ["AK-47"] = true,
    },

    WeaponClasses = {
        -- ["weapon_ak47"] = true,
    },

    EntityClasses = {
        -- ["spawned_shipment"] = true,
    },
}

--=====================================================
-- HIDDEN ENTITIES
--=====================================================

-- Completely remove selected DarkRP entities from SimpleF4.
-- They will not appear in categories, searches or empty-state counts.
--
-- You can match by displayed Name, DarkRP Command, or entity Class.
-- Both keyed and list-style entries are supported.
C.HiddenEntities = {
    Names = {
        -- ["Example Entity"] = true,
        -- "Another Entity",
    },

    Commands = {
        -- ["buyexample"] = true,
    },

    Classes = {
        -- ["example_entity"] = true,
    },
}

--=====================================================
-- PURCHASES
--=====================================================

C.Purchases = {
    ShowAffordability = true,

    -- Show "Owned: X / Y" when a purchase limit exists.
    ShowPurchaseLimits = true,

    -- Keep unavailable purchases visible and explain why they are locked.
    ShowLockedPurchases = true,

    -- Confirmation can be controlled separately per purchase type.
    Confirm = {
        Entities = true,
        Weapons = true,
    },

    ConfirmAbovePrice = 10000,

    -- Local UI countdown after a purchase. Set either to 0 to disable.
    -- This does not replace DarkRP's server-side validation.
    Cooldown = {
        Entities = 1.0,
        Weapons = 1.0,
    },
}

--=====================================================
-- QUICK ACTIONS
--=====================================================

-- Supported types:
--  "command" -> runs a console command
--  "chat"    -> runs "say <Value>"
--  "url"     -> opens a URL
C.QuickActions = {
    {
        Name = "Change Name",
        Type = "chat",
        Input = true,
        Prompt = "Enter your new RP name",
        Placeholder = "New RP name...",
        Prefix = "/name ",
        ConfirmText = "CHANGE NAME",
        Description = "Change your DarkRP roleplay name.",
    },
    {
        Name = "Drop Money",
        Type = "chat",
        Input = true,
        Prompt = "How much money do you want to drop?",
        Placeholder = "Amount...",
        Prefix = "/dropmoney ",
        ConfirmText = "DROP MONEY",
        Description = "Drop money in front of your player.",
    },
    {
        Name = "Laws",
        Type = "chat",
        Value = "/laws",
        ConfirmText = "VIEW LAWS",
        Description = "Open the current DarkRP laws.",
    },
}



--=====================================================
-- CATEGORY ICONS
--=====================================================

-- Optional material icons shown beside category names.
-- Leave a category out to show no icon.
C.CategoryIcons = {
    Jobs = {
        -- ["Citizens"] = "icon16/user.png",
        -- ["Civil Protection"] = {
        --     Icon = "icon16/shield.png",
        --     Color = Color(80, 170, 255),
        --     Size = 16,
        -- },
    },

    Entities = {
        -- ["Other"] = "icon16/box.png",
    },

    Weapons = {
        -- ["Other"] = "icon16/gun.png",
    },

    -- Legacy flat entries are still supported:
    -- ["Citizens"] = "icon16/user.png",
}

C.CategoryDescriptions = {
    Jobs = {
        -- ["Civil Protection"] = "Law-enforcement roles.",
    },
    Entities = {},
    Weapons = {},
}

-- How restricted categories/pages are displayed:
-- "hidden" = do not show them
-- "locked" = show a locked entry with the configured permission reason
C.PermissionDisplay = {
    Categories = "locked",
    Pages = "hidden",
}


--=====================================================
-- DISPLAY / ORDER / SEARCH CUSTOMISATION
--=====================================================

-- Hide entire categories from SimpleF4.
C.HiddenCategories = {
    Jobs = {},
    Entities = {},
    Weapons = {},
}

-- Lower numbers appear first. Missing categories default to 100.
C.CategoryOrder = {
    Jobs = {},
    Entities = {},
    Weapons = {},
}

-- Lower numbers appear first inside their category.
-- Targets may be job/entity/weapon display names, commands/classes,
-- or team IDs for Jobs.
C.ItemOrder = {
    Jobs = {},
    Entities = {},
    Weapons = {},
}

-- Change only what SimpleF4 displays. This does not rename the DarkRP item.
C.DisplayNames = {
    Jobs = {
        -- ["Civil Protection"] = "Police Officer",
        -- [TEAM_POLICE] = "Police Officer",
    },
    Entities = {},
    Weapons = {},
    Categories = {
        Jobs = {},
        Entities = {},
        Weapons = {},
    },

    Pages = {
        -- Dashboard = "Home",
    },
}

-- Extra terms that should match search.
C.SearchAliases = {
    Jobs = {
        -- ["Civil Protection"] = {"police", "cop", "officer"},
    },
    Entities = {},
    Weapons = {},
}

-- Config-only badges. Targets are the same identifiers used by ordering.
C.Badges = {
    Jobs = {
        -- ["Mayor"] = {
        --     {
        --         Text = "IMPORTANT",
        --         Color = Color(220, 165, 60),
        --         Icon = "icon16/star.png",
        --         Tooltip = "Important server role",
        --         Order = 10,
        --     },
        -- },
    },
    Entities = {},
    Weapons = {},
}

-- Optional page permissions. Missing entries remain available.
-- Uses the same permission fields as navbar entries.
C.PagePermissions = {
    -- Weapons = {
    --     UserGroups = {admin = true, superadmin = true},
    -- },
}


--=====================================================
-- CATEGORY COLOURS
--=====================================================

C.CategoryColours = {
    Jobs = {
        -- ["Civil Protection"] = Color(80, 170, 255),
    },
    Entities = {},
    Weapons = {},
}

--=====================================================
-- DASHBOARD ANNOUNCEMENTS / CHANGELOG
--=====================================================

C.Announcements = {
    Enabled = true,
    RotateSeconds = 8,

    -- Clicking the Dashboard card opens announcement history.
    ShowHistoryOnClick = true,

    Items = {
        {
            ID = "welcome",
            Title = "Welcome",
            Text = "Configure announcements in sh_config.lua.",
            Badge = "NEWS",
            Color = nil, -- nil = active theme accent

            -- Optional Unix timestamp used for history sorting/date labels.
            -- Falls back to StartTime, then 0 when omitted.
            PublishedAt = 0,

            -- Pinned announcements stay at the top of history.
            Pinned = false,

            -- Optional targeting:
            -- UserGroups = {vip = true, admin = true},
            -- Teams = {TEAM_POLICE},
            -- Categories = {["Police Department"] = true},
            -- AdminOnly = false,
            -- SuperAdminOnly = false,
            -- CustomCheck = function(ply) return true end,

            -- Optional Unix timestamps:
            -- StartTime = 0,
            -- EndTime = 0,

            Dismissible = false,
        },

        -- {
        --     ID = "police-update-1",
        --     Title = "Police Update",
        --     Text = "New equipment has been added.",
        --     Badge = "UPDATE",
        --     Color = Color(80, 170, 255),
        --     PublishedAt = os.time(),
        --     Pinned = true,
        --     Categories = {["Police Department"] = true},
        --     Dismissible = true,
        -- },
    },
}

--=====================================================
-- MAINTENANCE MODE
--=====================================================

C.Maintenance = {
    Enabled = false,
    Title = "SimpleF4 Maintenance",
    Message = "Job changes and purchases are temporarily unavailable.",

    -- Superadmins are also affected by maintenance.
    -- Their personal "Bypass SimpleF4 checks" setting is the only bypass.

    -- While maintenance blocks a player, SimpleF4 only shows:
    -- Dashboard and Settings.
}

--=====================================================
-- SUPERADMIN CONTROLS
--=====================================================

C.SuperAdmin = {
    Enabled = true,

    -- Defaults for the personal Superadmin Settings section.
    ShowHiddenStuff = false,
    BypassSimpleF4Checks = false,
    HideSelfFromStaffOnline = false,
    DeveloperTools = false,
    ModuleTestMode = false,
    PermissionPreview = false,
    PreviewTeamID = -1,
    PreviewUserGroup = "user",
}

--=====================================================
-- CATEGORY PERMISSIONS
--=====================================================

-- Category rules are optional. Missing categories remain visible.
--
-- A category rule may be:
--   true / false
--   function(ply, category, kind) return true/false end
--   {
--       UserGroups = { admin = true, superadmin = true },
--       Teams = { [TEAM_POLICE] = true },
--       CustomCheck = function(ply) return true end,
--   }
C.CategoryPermissions = {
    Jobs = {},
    Entities = {},
    Weapons = {},
}

--=====================================================
-- CUSTOM BADGES
--=====================================================

-- Custom badges are registered from Lua using:
-- SimpleF4.AddBadge("Jobs", TEAM_POLICE, {
--     Text = "VIP",
--     Color = Color(190, 100, 255),
-- })
--
-- Valid kinds: "Jobs", "Entities", "Weapons".
-- Targets can be team IDs, names, commands/classes, or a function.

--=====================================================
-- NEW BADGES
--=====================================================

-- Entries may be keyed by team ID/name/command/class, or listed as values.
--
-- Examples:
-- C.NewContent.Jobs[TEAM_POLICE] = true
-- C.NewContent.Entities["Money Printer"] = true
-- C.NewContent.Weapons["AK-47"] = true
C.NewContent = {
    Jobs = {},
    Entities = {},
    Weapons = {},
}

--=====================================================
-- SEARCH FILTERS
--=====================================================

C.Filters = {
    Jobs = true,
    EntitiesAffordableOnly = true,
    WeaponsType = true,
    WeaponsAffordableOnly = true,
}


--=====================================================
-- ADMIN / DEBUG
--=====================================================

C.Debug = false

-- Console command permissions.
-- Server console can always use every command.
-- Only put ranks here that actually need each command.
C.CommandPermissions = {
    version = {
        admin = true,
        superadmin = true,
    },

    status = {
        admin = true,
        superadmin = true,
    },

    reload = {
        admin = true,
        superadmin = true,
    },

    refresh_shared = {
        superadmin = true,
    },

    modules = {
        admin = true,
        superadmin = true,
    },

    update = {
        superadmin = true,
    },

    regression = {
        superadmin = true,
    },

    maintenance = {
        superadmin = true,
    },

    commands = {
        admin = true,
        superadmin = true,
    },
}

-- Backwards compatibility for older configs.
C.ReloadGroups = C.CommandPermissions.reload

--=====================================================
-- FILTERS
--=====================================================

-- Return false to hide a job entirely.
C.JobFilter = function(job, teamID, ply)
    return true
end

-- Return false to hide an entity entirely.
C.EntityFilter = function(ent, ply)
    return true
end

-- Return false to hide a shipment/weapon entirely.
C.ShipmentFilter = function(shipment, ply)
    return true
end

--=====================================================
-- THEME
--=====================================================


-- Built-in preset names:
-- "Blue", "Purple", "Red", "Green", "Orange", "Mono", "Custom"
C.ThemePreset = "Blue"

C.ThemePresets = {
    Blue = {
        Accent = Color(47, 132, 225),
        AccentSoft = Color(30, 77, 128),
    },

    Purple = {
        Accent = Color(145, 95, 220),
        AccentSoft = Color(82, 54, 128),
    },

    Red = {
        Accent = Color(210, 72, 72),
        AccentSoft = Color(120, 42, 42),
    },

    Green = {
        Accent = Color(60, 175, 105),
        AccentSoft = Color(37, 100, 65),
    },

    Orange = {
        Accent = Color(225, 135, 55),
        AccentSoft = Color(128, 77, 31),
    },

    Mono = {
        Accent = Color(185, 190, 200),
        AccentSoft = Color(92, 96, 105),
    },
}


C.Theme = {
    Background = Color(13, 15, 19),
    Surface = Color(20, 23, 29),
    Surface2 = Color(25, 29, 36),
    SurfaceHover = Color(32, 37, 46),

    Header = Color(10, 12, 16),
    Accent = Color(47, 132, 225),
    AccentSoft = Color(30, 77, 128),

    Text = Color(240, 243, 248),
    Muted = Color(145, 153, 165),

    Success = Color(70, 190, 110),
    Danger = Color(205, 72, 72),
    Warning = Color(220, 165, 60),

    Line = Color(43, 48, 58),
}


-- Preserve the base theme so client-side theme selection can safely
-- return to Custom/default colours.
C.ThemeBase = table.Copy(C.Theme)

-- Apply the selected preset after the base theme is defined.
-- "Custom" skips preset overrides entirely.
do
    local presetName = tostring(C.ThemePreset or "Blue")

    if presetName ~= "Custom" then
        local preset = C.ThemePresets[presetName]

        if preset then
            for key, value in pairs(preset) do
                C.Theme[key] = value
            end
        end
    end
end


-- Accessibility theme pass.
if C.Accessibility and C.Accessibility.HighContrast then
    C.Theme.Text = Color(255, 255, 255)
    C.Theme.Muted = Color(190, 198, 210)
    C.Theme.Line = Color(78, 86, 102)
    C.Theme.SurfaceHover = Color(42, 48, 58)
end

if C.Accessibility and C.Accessibility.DisableBlur then
    C.EnableBlur = false
end
