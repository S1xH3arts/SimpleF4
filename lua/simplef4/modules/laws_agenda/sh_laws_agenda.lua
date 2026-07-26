local C = SimpleF4.Config

SimpleF4.RegisterModule("LawsAgenda", {
    Name = "Laws / Agenda",
    Description = "Compact DarkRP laws and agenda panels.",
    Version = "1.0.0",
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}

local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = true,
    Right = 24,
    Top = 24,
    Width = 360,
    MaxLaws = 8,
    MaxAgendaLines = 6,
}

local moduleConfig = C.Modules.LawsAgenda or {}
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

C.Modules.LawsAgenda = moduleConfig
