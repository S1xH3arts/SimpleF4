local C = SimpleF4.Config

SimpleF4.RegisterModule("VoiceHUD", {
    Name = "Voice HUD",
    Description = "Speaking player list.",
    Version = "1.0.0",
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}

local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = true,
    Right = 24,
    Top = 300,
    Width = 250,
}

local moduleConfig = C.Modules.VoiceHUD or {}
local enabledOverride = moduleConfig.Enabled
local disableOverride = moduleConfig.AllowPlayerDisable

for key, value in pairs(moduleDefaults) do
    if key ~= "Enabled"
    and key ~= "AllowPlayerDisable" then
        moduleConfig[key] = value
    end
end

moduleConfig.Enabled =
    enabledOverride == nil
    and moduleDefaults.Enabled
    or enabledOverride

moduleConfig.AllowPlayerDisable =
    disableOverride == nil
    and moduleDefaults.AllowPlayerDisable
    or disableOverride

C.Modules.VoiceHUD = moduleConfig
