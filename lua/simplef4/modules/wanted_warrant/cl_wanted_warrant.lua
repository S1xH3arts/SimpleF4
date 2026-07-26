local C=SimpleF4.Config
if not SimpleF4.IsModuleEnabled("WantedWarrant") then return end
local alpha=0

local function cfg() return C.Modules and C.Modules.WantedWarrant or {} end
local function enabled()
    local c=cfg()
    if SimpleF4.IsModuleTestMode() then return true end
    if c.Enabled==false then return false end
    if c.AllowPlayerDisable==false then return true end
    return SimpleF4.GetUserSetting("WantedHUDEnabled")
end

local function state(ply)
    if SimpleF4.IsModuleTestMode() then
        return {
            Wanted=true,
            Warrant=true,
            Reason=SimpleF4.L("ModuleTestWantedReason"),
        }
    end

    local custom=hook.Run("SimpleF4_GetWantedWarrantState",ply)
    if istable(custom) then return custom end
    local wanted=false
    local warrant=false
    local reason=""
    if ply.getDarkRPVar then
        wanted=ply:getDarkRPVar("wanted")==true
        reason=tostring(ply:getDarkRPVar("wantedReason") or "")
        warrant=ply:getDarkRPVar("HasWarrant")==true
            or ply:getDarkRPVar("warrant")==true
    end
    return {Wanted=wanted,Warrant=warrant,Reason=reason}
end

hook.Add("HUDPaint","SimpleF4.WantedWarrant.Paint",function()
    if not enabled() then return end
    local ply=LocalPlayer()
    if not IsValid(ply) then return end
    local s=state(ply)
    local visible=s.Wanted or s.Warrant
    alpha=Lerp(math.Clamp(FrameTime()*8,0,1),alpha,visible and 1 or 0)
    if alpha<.01 then return end

    local pieces={}
    if s.Wanted then table.insert(pieces,SimpleF4.L("WantedStatus")) end
    if s.Warrant then table.insert(pieces,SimpleF4.L("WarrantStatus")) end
    local title=table.concat(pieces," • ")
    local reason=s.Reason~="" and s.Reason or SimpleF4.L("WantedNoReason")

    surface.SetFont("SimpleF4.BodyBold")
    local tw=surface.GetTextSize(title)
    surface.SetFont("SimpleF4.Small")
    local rw=surface.GetTextSize(reason)
    local w=math.max(SimpleF4.S(250),tw+SimpleF4.S(60),rw+SimpleF4.S(40))
    local h=SimpleF4.S(54)
    local x=ScrW()/2-w/2
    local y=ScrH()-SimpleF4.S(tonumber(cfg().Bottom) or 24)-h
    local a=math.floor(alpha*255)

    surface.SetDrawColor(C.Theme.Background.r,C.Theme.Background.g,C.Theme.Background.b,math.floor(a*.96))
    surface.DrawRect(x,y,w,h)
    surface.SetDrawColor(C.Theme.Danger.r,C.Theme.Danger.g,C.Theme.Danger.b,a)
    surface.DrawRect(x,y,SimpleF4.S(4),h)
    surface.SetMaterial(Material("icon16/exclamation.png","smooth"))
    surface.SetDrawColor(255,255,255,a)
    surface.DrawTexturedRect(x+SimpleF4.S(12),y+SimpleF4.S(12),SimpleF4.S(16),SimpleF4.S(16))
    draw.SimpleText(title,"SimpleF4.BodyBold",x+SimpleF4.S(38),y+SimpleF4.S(10),Color(C.Theme.Danger.r,C.Theme.Danger.g,C.Theme.Danger.b,a))
    draw.SimpleText(reason,"SimpleF4.Small",x+SimpleF4.S(38),y+SimpleF4.S(31),Color(C.Theme.Muted.r,C.Theme.Muted.g,C.Theme.Muted.b,a))
end)

hook.Add("SimpleF4_PopulateModuleSettingsSections","SimpleF4.WantedWarrant.Settings",function(sections)
    if cfg().Enabled==false then return end
    table.insert(sections,{ID="WantedWarrant",Order=84,Label="WantedWarrantSettings",Items={{
        Type="toggle",Key="WantedHUDEnabled",Label="WantedHUDEnabled",Description="WantedHUDEnabledDesc",
    }}})
end)
