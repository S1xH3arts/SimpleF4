local C = SimpleF4.Config

SimpleF4.RegisterModule("Overhead", {
    Name = "Player Info",
    Description = "Compact player overhead information using the SimpleF4 style.",
    Version = "1.0.0",
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}
local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = true,

    MaxDistance = 300,
    FadeStart = 200,

    -- Vertical position above the player's head.
    HeightOffset = 18,

    ShowWanted = true,
    ShowSpeaking = true,
    FadeDistance = true,

    -- Suppress the normal DarkRP target/player information while this
    -- module is active, leaving SimpleF4 as the visible player info.
    DisableDefaultOverhead = true,

    -- Keep the world text compact rather than drawing a large card.
    DrawBackground = false,

    -- Larger, Graphite-inspired side layout while keeping SimpleF4 styling.
    -- SideOffset is measured in the 3D2D canvas. Higher values move the
    -- information farther away from the player's body.
    -- VerticalOffset is a world-space height adjustment from EyePos().
    Scale = 0.05,
    SideOffset = 260,
    VerticalOffset = 8,

    -- Also attempts to remove common third-party/default player-info hooks
    -- so only the SimpleF4 overhead remains visible.
    AggressiveDefaultSuppression = true,

    -- Readability in bright areas.
    TextShadow = true,
    TextShadowAlpha = 240,
    TextShadowOffset = 2,

    IconShadow = true,
    IconShadowAlpha = 210,
    IconShadowOffset = 2,

    -- A subtle dark backdrop behind the compact lines. This is not the
    -- large card style; it only sits tightly behind the text.
    ReadabilityBackdrop = false,
    ReadabilityBackdropAlpha = 80,
    ReadabilityPadding = 6,
}

local moduleConfig = C.Modules.Overhead or {}
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

C.Modules.Overhead = moduleConfig
