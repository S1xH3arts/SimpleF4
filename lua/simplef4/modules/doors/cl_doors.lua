local C=SimpleF4.Config
if not SimpleF4.IsModuleEnabled("DoorHUD") then return end

local doorClasses={func_door=true,func_door_rotating=true,prop_door_rotating=true}

local function cfg() return C.Modules and C.Modules.DoorHUD or {} end
local function enabled()
    local c=cfg()
    if SimpleF4.IsModuleTestMode() then return true end
    if c.Enabled==false then return false end
    if c.AllowPlayerDisable==false then return true end
    return SimpleF4.GetUserSetting("DoorHUDEnabled")
end

local function info(ent)
    local custom=hook.Run("SimpleF4_GetDoorInfo",ent,LocalPlayer())
    if istable(custom) then return custom end

    local owner=ent.getDoorOwner and ent:getDoorOwner() or nil
    local title=ent.getKeysTitle and ent:getKeysTitle() or nil
    local group=ent.getKeysDoorGroup and ent:getKeysDoorGroup() or nil
    local nonOwnable=ent.getKeysNonOwnable and ent:getKeysNonOwnable() or false

    local co={}
    if ent.getKeysCoOwners then
        for id in pairs(ent:getKeysCoOwners() or {}) do
            local ply=Player(id)
            if IsValid(ply) then table.insert(co,ply:Nick()) end
        end
    end

    return {
        Title=title and title~="" and title or group or SimpleF4.L("DoorTitle"),
        Owner=IsValid(owner) and owner:Nick() or nil,
        CoOwners=co,
        NonOwnable=nonOwnable,
    }
end

hook.Add("HUDShouldDraw","SimpleF4.Doors.HideDefault",function(name)
    if enabled() and name=="DarkRP_EntityDisplay" then return false end
end)

hook.Add("HUDPaint","SimpleF4.Doors.Paint",function()
    if not enabled() then return end

    local ply=LocalPlayer()
    if not IsValid(ply) then return end

    local testMode=SimpleF4.IsModuleTestMode()
    local tr=ply:GetEyeTrace()
    local ent=tr.Entity
    local data

    if testMode then
        data={
            Title=SimpleF4.L("ModuleTestDoorTitle"),
            Owner=LocalPlayer():Nick(),
            CoOwners={"Test Co-owner"},
            NonOwnable=false,
        }
    else
        if not IsValid(ent)
        or not doorClasses[ent:GetClass()] then
            return
        end

        if tr.HitPos:Distance(ply:EyePos())
        > (tonumber(cfg().MaxDistance) or 220) then
            return
        end

        data=info(ent)
    end

    local status

    if data.NonOwnable then
        status=SimpleF4.L("DoorNotOwnable")
    elseif data.Owner then
        status=SimpleF4.L(
            "DoorOwner",
            {name=data.Owner}
        )

        if #data.CoOwners>0 then
            status=
                status
                .. " • "
                .. SimpleF4.L(
                    "DoorCoOwners",
                    {count=#data.CoOwners}
                )
        end
    else
        status=SimpleF4.L("DoorForSale")
    end

    local x=ScrW()/2
    local y=
        ScrH()/2
        + SimpleF4.S(
            tonumber(cfg().YOffset) or 70
        )

    local iconSize=SimpleF4.S(16)
    local gap=SimpleF4.S(6)

    surface.SetFont("SimpleF4.BodyBold")
    local titleW=surface.GetTextSize(data.Title)

    local totalW=
        iconSize
        + gap
        + titleW

    local startX=x-(totalW/2)

    -- Small shadow only: no full rectangular card.
    surface.SetMaterial(
        Material("icon16/door.png","smooth")
    )
    surface.SetDrawColor(0,0,0,190)
    surface.DrawTexturedRect(
        startX+1,
        y+1,
        iconSize,
        iconSize
    )

    surface.SetDrawColor(255,255,255,255)
    surface.DrawTexturedRect(
        startX,
        y,
        iconSize,
        iconSize
    )

    draw.SimpleText(
        data.Title,
        "SimpleF4.BodyBold",
        startX+iconSize+gap+1,
        y+(iconSize/2)+1,
        Color(0,0,0,210),
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
        data.Title,
        "SimpleF4.BodyBold",
        startX+iconSize+gap,
        y+(iconSize/2),
        C.Theme.Text,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
        status,
        "SimpleF4.Small",
        x+1,
        y+SimpleF4.S(24)+1,
        Color(0,0,0,210),
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
        status,
        "SimpleF4.Small",
        x,
        y+SimpleF4.S(24),
        data.Owner
            and C.Theme.Muted
            or C.Theme.Success,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER
    )
end)

hook.Add("SimpleF4_PopulateModuleSettingsSections","SimpleF4.Doors.Settings",function(sections)
    if cfg().Enabled==false then return end
    table.insert(sections,{ID="DoorHUD",Order=85,Label="DoorHUDSettings",Items={{
        Type="toggle",Key="DoorHUDEnabled",Label="DoorHUDEnabled",Description="DoorHUDEnabledDesc",
    }}})
end)
