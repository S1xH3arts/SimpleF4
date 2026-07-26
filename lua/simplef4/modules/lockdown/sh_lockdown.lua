local C = SimpleF4.Config

SimpleF4.RegisterModule("Lockdown", {
    Name = "Lockdown",
    Description = "Animated DarkRP lockdown warning.",
    Version = "1.0.0",
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}

local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = true,
    Top = 24,
    Pulse = true,
}

local moduleConfig = C.Modules.Lockdown or {}
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

C.Modules.Lockdown = moduleConfig
