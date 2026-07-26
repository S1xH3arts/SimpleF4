local C = SimpleF4.Config

SimpleF4.RegisterModule("Notifications", {
    Name = "Notifications",
    Description = "SimpleF4 replacement notification stack.",
    Version = "1.0.0",
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}

local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = true,
    Right = 24,
    Bottom = 110,
    Width = 360,
    Duration = 5,
    MaxVisible = 5,
    MaxTextLines = 3,
    TextPadding = 12,
    PlaySounds = false,
}

local moduleConfig = C.Modules.Notifications or {}
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

C.Modules.Notifications = moduleConfig
