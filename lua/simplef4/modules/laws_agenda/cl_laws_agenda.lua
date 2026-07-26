local C=SimpleF4.Config
if not SimpleF4.IsModuleEnabled("LawsAgenda") then return end

local function cfg() return C.Modules and C.Modules.LawsAgenda or {} end
local function enabled()
    local c=cfg()
    if SimpleF4.IsModuleTestMode() then return true end
    if c.Enabled==false then return false end
    if c.AllowPlayerDisable==false then return true end
    return SimpleF4.GetUserSetting("LawsAgendaEnabled")
end

local function getAgenda()
    if SimpleF4.IsModuleTestMode() then
        return SimpleF4.L("AgendaTestText")
    end

    local hookValue=hook.Run("SimpleF4_GetAgendaText",LocalPlayer())
    if hookValue ~= nil then return tostring(hookValue or "") end
    if LocalPlayer().getDarkRPVar then
        return tostring(LocalPlayer():getDarkRPVar("agenda") or "")
    end
    return ""
end

local function getLaws()
    if SimpleF4.IsModuleTestMode() then
        return {
            SimpleF4.L("LawTestOne"),
            SimpleF4.L("LawTestTwo"),
            SimpleF4.L("LawTestThree"),
        }
    end

    local custom=hook.Run("SimpleF4_GetLaws",LocalPlayer())
    if custom ~= nil then return custom end

    if DarkRP and isfunction(DarkRP.getLaws) then
        local result=DarkRP.getLaws()
        if istable(result) then return result end
        if isstring(result) then return string.Explode("\n",result,false) end
    end

    if GAMEMODE and GAMEMODE.Config and istable(GAMEMODE.Config.DefaultLaws) then
        return GAMEMODE.Config.DefaultLaws
    end

    return {}
end

local function cleanLines(value,maxLines)
    local out={}
    if istable(value) then
        for _,line in ipairs(value) do
            line=string.Trim(tostring(line or ""))
            if line~="" then
                table.insert(out,line)
                if #out>=maxLines then break end
            end
        end
    else
        for _,line in ipairs(string.Explode("\n",tostring(value or ""),false)) do
            line=string.Trim(line)
            if line~="" then
                table.insert(out,line)
                if #out>=maxLines then break end
            end
        end
    end
    return out
end

local function drawPanel(x,y,w,title,icon,lines,accent)
    if #lines==0 then return 0 end
    local lineH=SimpleF4.S(17)
    local h=SimpleF4.S(38)+lineH*#lines+SimpleF4.S(8)

    surface.SetDrawColor(C.Theme.Background)
    surface.DrawRect(x,y,w,h)
    surface.SetDrawColor(C.Theme.Line)
    surface.DrawOutlinedRect(x,y,w,h,1)
    surface.SetDrawColor(accent)
    surface.DrawRect(x,y,SimpleF4.S(3),h)

    local mat=Material(icon,"smooth")
    surface.SetMaterial(mat)
    surface.SetDrawColor(255,255,255)
    surface.DrawTexturedRect(x+SimpleF4.S(10),y+SimpleF4.S(11),SimpleF4.S(16),SimpleF4.S(16))

    draw.SimpleText(title,"SimpleF4.BodyBold",x+SimpleF4.S(34),y+SimpleF4.S(18),C.Theme.Text,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)

    for i,line in ipairs(lines) do
        draw.SimpleText(
            line,
            "SimpleF4.Small",
            x+SimpleF4.S(10),
            y+SimpleF4.S(37)+(i-1)*lineH,
            C.Theme.Muted
        )
    end
    return h
end

hook.Add("HUDShouldDraw","SimpleF4.LawsAgenda.HideDefault",function(name)
    if enabled() and (name=="DarkRP_Agenda" or name=="DarkRP_Laws") then return false end
end)

hook.Add("HUDPaint","SimpleF4.LawsAgenda.Paint",function()
    if not enabled() then return end
    local c=cfg()
    local w=SimpleF4.S(tonumber(c.Width) or 360)
    local x=ScrW()-SimpleF4.S(tonumber(c.Right) or 24)-w
    local y=SimpleF4.S(tonumber(c.Top) or 24)

    if SimpleF4.GetUserSetting("LawsAgendaShowLaws") then
        local laws=cleanLines(getLaws(),math.max(1,tonumber(c.MaxLaws) or 8))
        local numbered={}
        for i,line in ipairs(laws) do
            table.insert(numbered,tostring(i)..". "..line)
        end
        local h=drawPanel(x,y,w,SimpleF4.L("HUDLaws"),"icon16/script.png",numbered,C.Theme.Accent)
        if h>0 then y=y+h+SimpleF4.S(8) end
    end

    if SimpleF4.GetUserSetting("LawsAgendaShowAgenda") then
        local agenda=cleanLines(getAgenda(),math.max(1,tonumber(c.MaxAgendaLines) or 6))
        drawPanel(x,y,w,SimpleF4.L("HUDAgenda"),"icon16/date.png",agenda,C.Theme.Warning)
    end
end)

hook.Add("SimpleF4_PopulateModuleSettingsSections","SimpleF4.LawsAgenda.Settings",function(sections)
    if cfg().Enabled==false then return end
    table.insert(sections,{
        ID="LawsAgenda",Order=81,Label="LawsAgendaSettings",
        Items={
            {Type="toggle",Key="LawsAgendaEnabled",Label="LawsAgendaEnabled",Description="LawsAgendaEnabledDesc"},
            {Type="toggle",Key="LawsAgendaShowLaws",Label="LawsAgendaShowLaws",Description="LawsAgendaShowLawsDesc"},
            {Type="toggle",Key="LawsAgendaShowAgenda",Label="LawsAgendaShowAgenda",Description="LawsAgendaShowAgendaDesc"},
        },
    })
end)
