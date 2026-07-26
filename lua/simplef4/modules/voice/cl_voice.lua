local C=SimpleF4.Config
if not SimpleF4.IsModuleEnabled("VoiceHUD") then return end

local panels={}
local container

local function cfg() return C.Modules and C.Modules.VoiceHUD or {} end
local function enabled()
    local c=cfg()
    if SimpleF4.IsModuleTestMode() then return true end
    if c.Enabled==false then return false end
    if c.AllowPlayerDisable==false then return true end
    return SimpleF4.GetUserSetting("VoiceHUDEnabled")
end

local function buildContainer()
    if IsValid(container) then container:Remove() end
    container=vgui.Create("DPanel")
    container:ParentToHUD()
    container:SetPaintBackground(false)
    container:SetSize(SimpleF4.S(tonumber(cfg().Width) or 250),ScrH()-SimpleF4.S(340))
    container:SetPos(
        ScrW()-SimpleF4.S(tonumber(cfg().Right) or 24)-container:GetWide(),
        SimpleF4.S(tonumber(cfg().Top) or 300)
    )
end

local function makePanel(ply)
    if not IsValid(container) then buildContainer() end
    local pnl=vgui.Create("DPanel",container)
    pnl:SetTall(SimpleF4.S(42))
    pnl:Dock(TOP)
    pnl:DockMargin(0,0,0,SimpleF4.S(5))
    pnl.Player=ply
    pnl.AlphaValue=255

    local avatar=vgui.Create("AvatarImage",pnl)
    avatar:SetPlayer(ply,32)
    avatar:SetPos(SimpleF4.S(6),SimpleF4.S(6))
    avatar:SetSize(SimpleF4.S(30),SimpleF4.S(30))

    pnl.Paint=function(self,w,h)
        if not IsValid(self.Player) then return end
        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(0,0,w,h,1)
        draw.SimpleText(self.Player:Nick(),"SimpleF4.Small",SimpleF4.S(44),SimpleF4.S(12),C.Theme.Text)
        local volume=math.Clamp(self.Player:VoiceVolume(),0,1)
        surface.SetDrawColor(C.Theme.Surface2)
        surface.DrawRect(SimpleF4.S(44),h-SimpleF4.S(9),w-SimpleF4.S(52),SimpleF4.S(4))
        surface.SetDrawColor(C.Theme.Success)
        surface.DrawRect(SimpleF4.S(44),h-SimpleF4.S(9),(w-SimpleF4.S(52))*volume,SimpleF4.S(4))
    end

    return pnl
end

hook.Add("InitPostEntity","SimpleF4.Voice.Build",buildContainer)
hook.Add("OnScreenSizeChanged","SimpleF4.Voice.Resize",buildContainer)

hook.Add("PlayerStartVoice","SimpleF4.Voice.Start",function(ply)
    if not enabled() or not IsValid(ply) then return end
    if IsValid(panels[ply]) then panels[ply]:Remove() end
    panels[ply]=makePanel(ply)
    return true
end)

hook.Add("PlayerEndVoice","SimpleF4.Voice.End",function(ply)
    if IsValid(panels[ply]) then
        panels[ply]:Remove()
        panels[ply]=nil
    end
end)

hook.Add("SimpleF4_PopulateModuleSettingsSections","SimpleF4.Voice.Settings",function(sections)
    if cfg().Enabled==false then return end
    table.insert(sections,{ID="VoiceHUD",Order=83,Label="VoiceHUDSettings",Items={{
        Type="toggle",Key="VoiceHUDEnabled",Label="VoiceHUDEnabled",Description="VoiceHUDEnabledDesc",
    }}})
end)


hook.Add(
    "HUDPaint",
    "SimpleF4.Voice.TestPaint",
    function()
        if not SimpleF4.IsModuleTestMode() then
            return
        end

        local c=cfg()
        local w=SimpleF4.S(
            tonumber(c.Width) or 250
        )
        local h=SimpleF4.S(42)
        local x=
            ScrW()
            - SimpleF4.S(
                tonumber(c.Right) or 24
            )
            - w
        local y=
            SimpleF4.S(
                tonumber(c.Top) or 300
            )

        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(x,y,w,h)
        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(x,y,w,h,1)

        surface.SetMaterial(
            Material("icon16/sound.png","smooth")
        )
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(
            x+SimpleF4.S(10),
            y+SimpleF4.S(13),
            SimpleF4.S(16),
            SimpleF4.S(16)
        )

        draw.SimpleText(
            SimpleF4.L("ModuleTestSpeakingPlayer"),
            "SimpleF4.Small",
            x+SimpleF4.S(36),
            y+SimpleF4.S(12),
            C.Theme.Text
        )

        surface.SetDrawColor(C.Theme.Surface2)
        surface.DrawRect(
            x+SimpleF4.S(36),
            y+h-SimpleF4.S(9),
            w-SimpleF4.S(44),
            SimpleF4.S(4)
        )

        surface.SetDrawColor(C.Theme.Success)
        surface.DrawRect(
            x+SimpleF4.S(36),
            y+h-SimpleF4.S(9),
            (w-SimpleF4.S(44))*0.7,
            SimpleF4.S(4)
        )
    end
)
