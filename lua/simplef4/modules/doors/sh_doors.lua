local C = SimpleF4.Config

SimpleF4.RegisterModule("DoorHUD", {
    Name = "Door HUD",
    Description = "Door ownership information when looking at a door.",
    Version = "1.0.0",
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}

local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = true,
    MaxDistance = 220,
    YOffset = 70,
}

local moduleConfig = C.Modules.DoorHUD or {}
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

C.Modules.DoorHUD = moduleConfig
