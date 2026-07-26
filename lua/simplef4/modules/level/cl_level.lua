local C=SimpleF4.Config
if not SimpleF4.IsModuleEnabled("LevelHUD") then return end

local previousLevel
local nextLevelCheck=0

local function cfg() return C.Modules and C.Modules.LevelHUD or {} end
local function enabled()
    local c=cfg()
    if SimpleF4.IsModuleTestMode() then return true end
    if c.Enabled==false then return false end
    if c.AllowPlayerDisable==false then return true end
    return SimpleF4.GetUserSetting("LevelHUDEnabled")
end

SimpleF4.RegisterLevelProvider("DarkRPVars",function(ply)
    if not IsValid(ply) or not ply.getDarkRPVar then return end
    local level=tonumber(ply:getDarkRPVar("level") or ply:getDarkRPVar("Level"))
    local xp=tonumber(ply:getDarkRPVar("xp") or ply:getDarkRPVar("XP") or ply:getDarkRPVar("experience"))
    if level==nil and xp==nil then return end
    level=level or 0
    xp=xp or 0

    local maxXP=tonumber(
        ply:getDarkRPVar("maxxp")
        or ply:getDarkRPVar("MaxXP")
        or ply:getDarkRPVar("xpmax")
    )

    if not maxXP then
        local mult=1
        if LevelSystemConfiguration and tonumber(LevelSystemConfiguration.XPMult) then
            mult=tonumber(LevelSystemConfiguration.XPMult)
        elseif LevelingConfiguration and tonumber(LevelingConfiguration.XpMultiplier) then
            mult=tonumber(LevelingConfiguration.XpMultiplier)
        end
        maxXP=(10+((math.max(level,1)*(math.max(level,1)+1)*90)))*mult
    end

    return {Level=level,XP=xp,MaxXP=math.max(1,maxXP)}
end,0)


hook.Add(
    "Think",
    "SimpleF4.Level.LevelUpWatch",
    function()
        if CurTime() < nextLevelCheck then
            return
        end

        nextLevelCheck=CurTime()+.5

        local data=
            SimpleF4.GetLevelData(
                LocalPlayer()
            )

        if not istable(data) then
            SimpleF4.SetModuleRuntimeStatus(
                "LevelHUD",
                "missing_provider",
                SimpleF4.L(
                    "ModuleStatusWaitingLevel"
                )
            )
            previousLevel=nil
            return
        end

        SimpleF4.SetModuleRuntimeStatus(
            "LevelHUD",
            "ready",
            SimpleF4.L(
                "ModuleStatusLevelReady"
            )
        )

        local levelValue =
            tonumber(data.Level)

        if not levelValue then
            return
        end

        if previousLevel ~= nil
        and levelValue > previousLevel then
            SimpleF4.Notify({
                Title = SimpleF4.L(
                    "LevelUpTitle"
                ),
                Text = SimpleF4.L(
                    "LevelUpText",
                    {level=levelValue}
                ),
                Type = "level",
                Icon = "icon16/star.png",
                Duration = 5,
            })
        end

        previousLevel=levelValue
    end
)

hook.Add("HUDPaint","SimpleF4.Level.Paint",function()
    if not enabled() then return end
    local data

    if SimpleF4.IsModuleTestMode() then
        data={Level=12,XP=650,MaxXP=1000}
    else
        data=SimpleF4.GetLevelData(LocalPlayer())
    end

    if not istable(data) then return end

    local level=tonumber(data.Level) or 0
    local xp=tonumber(data.XP) or 0
    local maxXP=math.max(1,tonumber(data.MaxXP) or 1)
    local frac=math.Clamp(xp/maxXP,0,1)
    local c=cfg()
    local w=SimpleF4.S(tonumber(c.Width) or 340)
    local h=SimpleF4.S(28)
    local x=SimpleF4.S(tonumber(c.Left) or 24)
    local y=ScrH()-SimpleF4.S(tonumber(c.Bottom) or 158)-h

    surface.SetDrawColor(C.Theme.Background)
    surface.DrawRect(x,y,w,h)
    surface.SetDrawColor(C.Theme.Line)
    surface.DrawOutlinedRect(x,y,w,h,1)
    surface.SetDrawColor(C.Theme.Surface2)
    surface.DrawRect(x+SimpleF4.S(34),y+SimpleF4.S(7),w-SimpleF4.S(42),SimpleF4.S(14))
    surface.SetDrawColor(C.Theme.Accent)
    surface.DrawRect(x+SimpleF4.S(34),y+SimpleF4.S(7),(w-SimpleF4.S(42))*frac,SimpleF4.S(14))

    surface.SetMaterial(Material("icon16/star.png","smooth"))
    surface.SetDrawColor(255,255,255)
    surface.DrawTexturedRect(x+SimpleF4.S(9),y+SimpleF4.S(6),SimpleF4.S(16),SimpleF4.S(16))
    draw.SimpleText(
        SimpleF4.L("LevelBarText",{level=level,percent=math.floor(frac*100)}),
        "SimpleF4.Small",
        x+w/2+SimpleF4.S(12),y+h/2,C.Theme.Text,
        TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER
    )
end)

hook.Add("SimpleF4_PopulateModuleSettingsSections","SimpleF4.Level.Settings",function(sections)
    if cfg().Enabled==false then return end
    table.insert(sections,{ID="LevelHUD",Order=86,Label="LevelHUDSettings",Items={{
        Type="toggle",Key="LevelHUDEnabled",Label="LevelHUDEnabled",Description="LevelHUDEnabledDesc",
    }}})
end)
