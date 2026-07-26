local C = SimpleF4.Config

SimpleF4.RegisterModule("LevelHUD", {
    Name = "Level Bar",
    Description = "Level / experience bar with provider support.",
    Version = "1.0.0",
    OptionalDepends = {"Notifications"},
    EnabledByDefault = true,
})

C.Modules = C.Modules or {}

local moduleDefaults = {
    Enabled = true,
    AllowPlayerDisable = true,
    AlwaysVisible = true,
    Left = 24,
    Bottom = 158,
    Width = 340,
}

local moduleConfig = C.Modules.LevelHUD or {}
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

C.Modules.LevelHUD = moduleConfig

SimpleF4.LevelProviders = SimpleF4.LevelProviders or {}

function SimpleF4.RegisterLevelProvider(id, fn, priority)
    if not isstring(id) or id=="" or not isfunction(fn) then return false end
    SimpleF4.LevelProviders[id]={Fn=fn,Priority=tonumber(priority) or 0}
    return true
end

function SimpleF4.GetLevelData(ply)
    local hooked=hook.Run("SimpleF4_GetLevelData",ply)
    if istable(hooked) then return hooked end

    local providers={}
    for id,data in pairs(SimpleF4.LevelProviders) do
        table.insert(providers,{ID=id,Fn=data.Fn,Priority=data.Priority})
    end
    table.sort(providers,function(a,b) return a.Priority>b.Priority end)

    for _,provider in ipairs(providers) do
        local ok,result=pcall(provider.Fn,ply)
        if ok and istable(result) then return result end
    end
end
