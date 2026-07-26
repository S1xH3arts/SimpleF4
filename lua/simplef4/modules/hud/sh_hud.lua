local C = SimpleF4.Config

SimpleF4.RegisterModule("HUD", {
    Name = "Simple HUD",
    Description = "DarkRP player HUD using the active SimpleF4 theme.",
    Version = "1.0.0",
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}
local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = false,

    -- Screenshot-style layout.
    PlayerPanel = {
        X = 24,
        Y = 24,
        Width = 330,
    },

    AmmoPanel = {
        Right = 24,
        Bottom = 24,
        Width = 180,
    },

    SmoothAnimations = true,
    AnimationSpeed = 8,

    HungerWarnings = {
        Enabled = true,

        -- HUD state labels:
        -- FED above HungryAt, HUNGRY at/below HungryAt,
        -- STARVING at/below StarvingAt.
        HungryAt = 25,
        StarvingAt = 10,
        ResetAbove = 30,

        -- Pulse the hunger bar when starving.
        PulseWhenStarving = true,
    },

    Feedback = {
        Enabled = true,
        Duration = 2,

        -- Brief bar flashes after health/armour changes.
        BarFlash = true,
        BarFlashDuration = 0.35,
    },

    Lockdown = {
        Enabled = true,
    },

    Agenda = {
        Enabled = true,
        Width = 340,
        MaxLines = 5,
    },
}

local moduleConfig = C.Modules.HUD or {}
local enabledOverride = moduleConfig.Enabled
local disableOverride = moduleConfig.AllowPlayerDisable

-- Re-apply tunable shared settings every time this sh_ file is included.
-- This makes AutoRefresh edits visible immediately.
for key, value in pairs(moduleDefaults) do
    if key ~= "Enabled"
    and key ~= "AllowPlayerDisable" then
        moduleConfig[key] = value
    end
end

if enabledOverride == nil then
    moduleConfig.Enabled = moduleDefaults.Enabled
else
    moduleConfig.Enabled = enabledOverride
end

if disableOverride == nil then
    moduleConfig.AllowPlayerDisable =
        moduleDefaults.AllowPlayerDisable
else
    moduleConfig.AllowPlayerDisable = disableOverride
end

C.Modules.HUD = moduleConfig
