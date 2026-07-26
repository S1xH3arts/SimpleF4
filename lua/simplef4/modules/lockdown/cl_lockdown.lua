local C=SimpleF4.Config
if not SimpleF4.IsModuleEnabled("Lockdown") then return end

local alpha=0
local function cfg() return C.Modules and C.Modules.Lockdown or {} end
local function enabled()
    local c=cfg()
    if c.Enabled==false then return false end
    if c.AllowPlayerDisable==false then return true end
    return SimpleF4.GetUserSetting("LockdownHUDEnabled")
end
local function active()
    if SimpleF4.IsModuleTestMode() then
        return true
    end

    local custom=hook.Run("SimpleF4_IsLockdown")
    if custom~=nil then return custom==true end
    return GetGlobalBool("DarkRP_LockDown",false) or GetGlobalBool("DarkRP_Lockdown",false)
end

hook.Add("HUDPaint","SimpleF4.Lockdown.Paint",function()
    if not enabled() then return end
    local target=active() and 1 or 0
    alpha=Lerp(math.Clamp(FrameTime()*7,0,1),alpha,target)
    if alpha<.01 then return end

    local issuer=hook.Run("SimpleF4_GetLockdownIssuer")
    local reason=hook.Run("SimpleF4_GetLockdownReason")

    if SimpleF4.IsModuleTestMode() then
        issuer=SimpleF4.L("ModuleTestMayor")
        reason=SimpleF4.L("ModuleTestLockdownReason")
    end
    local title=SimpleF4.L("HUDLockdown")
    local desc=reason and tostring(reason) or SimpleF4.L("HUDLockdownDefaultReason")
    if issuer then desc=tostring(issuer).." • "..desc end

    surface.SetFont("SimpleF4.BodyBold")
    local tw=surface.GetTextSize(title)
    surface.SetFont("SimpleF4.Small")
    local dw=surface.GetTextSize(desc)
    local w=math.max(SimpleF4.S(260),tw+SimpleF4.S(70),dw+SimpleF4.S(40))
    local h=SimpleF4.S(54)
    local x=ScrW()/2-w/2
    local y=SimpleF4.S(tonumber(cfg().Top) or 24)
    local pulse=1
    if cfg().Pulse~=false then pulse=.7+.3*((math.sin(CurTime()*4)+1)/2) end
    local a=math.floor(255*alpha)

    surface.SetDrawColor(C.Theme.Background.r,C.Theme.Background.g,C.Theme.Background.b,math.floor(a*.96))
    surface.DrawRect(x,y,w,h)
    surface.SetDrawColor(C.Theme.Danger.r,C.Theme.Danger.g,C.Theme.Danger.b,math.floor(a*pulse))
    surface.DrawRect(x,y,SimpleF4.S(4),h)

    surface.SetMaterial(Material("icon16/lock.png","smooth"))
    surface.SetDrawColor(255,255,255,a)
    surface.DrawTexturedRect(x+SimpleF4.S(12),y+SimpleF4.S(12),SimpleF4.S(16),SimpleF4.S(16))

    draw.SimpleText(title,"SimpleF4.BodyBold",x+SimpleF4.S(38),y+SimpleF4.S(10),Color(C.Theme.Danger.r,C.Theme.Danger.g,C.Theme.Danger.b,a))
    draw.SimpleText(desc,"SimpleF4.Small",x+SimpleF4.S(38),y+SimpleF4.S(31),Color(C.Theme.Muted.r,C.Theme.Muted.g,C.Theme.Muted.b,a))
end)

hook.Add("SimpleF4_PopulateModuleSettingsSections","SimpleF4.Lockdown.Settings",function(sections)
    if cfg().Enabled==false then return end
    table.insert(sections,{ID="Lockdown",Order=82,Label="LockdownSettings",Items={{
        Type="toggle",Key="LockdownHUDEnabled",Label="LockdownHUDEnabled",Description="LockdownHUDEnabledDesc",
    }}})
end)
