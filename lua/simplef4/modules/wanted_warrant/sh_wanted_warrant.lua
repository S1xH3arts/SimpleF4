local C = SimpleF4.Config

SimpleF4.RegisterModule("WantedWarrant", {
    Name = "Wanted / Warrant",
    Description = "Local wanted and warrant status panel.",
    Version = "1.0.0",
    OptionalDepends = {"Notifications"},
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}

local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = true,
    Bottom = 24,
}

local moduleConfig = C.Modules.WantedWarrant or {}
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

C.Modules.WantedWarrant = moduleConfig
