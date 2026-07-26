local C = SimpleF4.Config
local F = SimpleF4.Functions

if not SimpleF4.IsModuleEnabled("HUD") then return end

local AvatarPanel
local ModelPanel

local animated = {
    Health = 100,
    Armour = 0,
    Hunger = 100,
    Money = 0,
    Salary = 0,
}

local lastActual = {
    Health = nil,
    Armour = nil,
    Money = nil,
}

local feedback = {}
local hungerWarningState = nil

local barFlashUntil = {
    Health = 0,
    Armour = 0,
}
local barFlashColour = {
    Health = nil,
    Armour = nil,
}

local function S(v)
    return SimpleF4.S and SimpleF4.S(v) or v
end

local function hudConfig()
    return C.Modules and C.Modules.HUD or {}
end

local function enabled()
    local config = hudConfig()

    if SimpleF4.IsModuleTestMode() then
        return true
    end

    return config.Enabled ~= false
end

local function smooth(current, target)
    local config = hudConfig()

    if config.SmoothAnimations == false
    or SimpleF4.GetUserSetting("ReduceMotion") then
        return target
    end

    local speed = tonumber(config.AnimationSpeed) or 8

    return Lerp(
        math.Clamp(FrameTime() * speed, 0, 1),
        current,
        target
    )
end

local function getMoney(ply)
    local hooked = hook.Run("SimpleF4_GetMoney", ply)

    if hooked ~= nil then
        return tonumber(hooked) or 0
    end

    if ply.getDarkRPVar then
        return tonumber(ply:getDarkRPVar("money")) or 0
    end

    return 0
end

local function getSalary(ply)
    if ply.getDarkRPVar then
        return tonumber(ply:getDarkRPVar("salary")) or 0
    end

    return 0
end

local function getHunger(ply)
    local hooked = hook.Run("SimpleF4_GetHunger", ply)

    if hooked ~= nil then
        return tonumber(hooked)
    end

    if not ply.getDarkRPVar then return nil end

    for _, key in ipairs({
        "Energy",
        "energy",
        "Hunger",
        "hunger",
    }) do
        local value = ply:getDarkRPVar(key)

        if value ~= nil then
            return tonumber(value)
        end
    end

    return nil
end

local function getJob(ply)
    if F.GetJobName then
        return F.GetJobName(ply)
    end

    return team.GetName(ply:Team()) or SimpleF4.L("Unknown")
end

local function weaponName(wep)
    if not IsValid(wep) then return "" end

    local name = wep:GetPrintName()

    if not name
    or name == ""
    or name == "Scripted Weapon" then
        name = wep:GetClass()
    end

    if isstring(name)
    and string.StartWith(name, "#") then
        name = language.GetPhrase(string.sub(name, 2))
    end

    return tostring(name or wep:GetClass())
end

local function isLockdown()
    local hooked = hook.Run("SimpleF4_IsLockdown")

    if hooked ~= nil then
        return hooked == true
    end

    return GetGlobalBool("DarkRP_LockDown", false)
        or GetGlobalBool("DarkRP_Lockdown", false)
end

local function getAgenda(ply)
    local hooked = hook.Run("SimpleF4_GetAgendaText", ply)

    if hooked ~= nil then
        return tostring(hooked or "")
    end

    if ply.getDarkRPVar then
        local value = ply:getDarkRPVar("agenda")

        if value ~= nil then
            return tostring(value)
        end
    end

    return ""
end

local hidden = {
    DarkRP_HUD = true,
    DarkRP_LocalPlayerHUD = true,
    CHudHealth = true,
    CHudBattery = true,
    CHudAmmo = true,
    CHudSecondaryAmmo = true,
}

hook.Add("HUDShouldDraw", "SimpleF4.HUD.HideDefault", function(name)
    if not enabled() then return end

    if hidden[name] then
        return false
    end
end)

local function ensureAvatar(ply)
    if IsValid(AvatarPanel) then
        if AvatarPanel.SimpleF4Player ~= ply then
            AvatarPanel:SetPlayer(ply, 64)
            AvatarPanel.SimpleF4Player = ply
        end

        return AvatarPanel
    end

    AvatarPanel = vgui.Create("AvatarImage")
    AvatarPanel:SetMouseInputEnabled(false)
    AvatarPanel:SetKeyboardInputEnabled(false)
    AvatarPanel:SetPlayer(ply, 64)
    AvatarPanel.SimpleF4Player = ply

    return AvatarPanel
end

local function ensureModel(ply)
    if not IsValid(ModelPanel) then
        ModelPanel = vgui.Create("DModelPanel")
        ModelPanel:SetMouseInputEnabled(false)
        ModelPanel:SetKeyboardInputEnabled(false)
        ModelPanel:SetFOV(42)
        ModelPanel:SetAnimated(false)
        ModelPanel.LayoutEntity = function() end
    end

    local model = ply:GetModel()

    if ModelPanel.SimpleF4Model ~= model then
        ModelPanel:SetModel(model)
        ModelPanel.SimpleF4Model = model

        local ent = ModelPanel.Entity

        if IsValid(ent) then
            local mins, maxs = ent:GetRenderBounds()
            local height = math.max(1, maxs.z - mins.z)
            local head = Vector(
                (mins.x + maxs.x) * 0.5,
                (mins.y + maxs.y) * 0.5,
                mins.z + height * 0.84
            )

            ModelPanel:SetLookAt(
                head + Vector(0, 0, -4)
            )
            ModelPanel:SetCamPos(
                head + Vector(height * 0.52, 0, 0)
            )

            if ent.SetEyeTarget then
                ent:SetEyeTarget(
                    head + Vector(height * 0.2, 0, 0)
                )
            end
        end
    end

    return ModelPanel
end

local function hidePortraits()
    if IsValid(AvatarPanel) then
        AvatarPanel:SetVisible(false)
    end

    if IsValid(ModelPanel) then
        ModelPanel:SetVisible(false)
    end
end

local function panelBox(x, y, w, h, accent)
    surface.SetDrawColor(C.Theme.Background)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(C.Theme.Line)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    surface.SetDrawColor(accent or C.Theme.Accent)
    surface.DrawRect(x, y, S(3), h)
end

local function drawServerBar(x, y, w, h)
    surface.SetDrawColor(C.Theme.Surface)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(C.Theme.Line)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    surface.SetDrawColor(C.Theme.Accent)
    surface.DrawRect(x, y + h - S(2), w, S(2))

    draw.SimpleText(
        tostring(C.ServerName or "DarkRP Server"),
        "SimpleF4.BodyBold",
        x + S(10),
        y + h / 2,
        C.Theme.Text,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
        tostring(C.Subtitle or ""),
        "SimpleF4.Small",
        x + w - S(10),
        y + h / 2,
        C.Theme.Muted,
        TEXT_ALIGN_RIGHT,
        TEXT_ALIGN_CENTER
    )
end

local function drawBar(x, y, w, h, fraction, colour, value)
    fraction = math.Clamp(tonumber(fraction) or 0, 0, 1)

    surface.SetDrawColor(C.Theme.Surface2)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(colour)
    surface.DrawRect(
        x,
        y,
        math.floor(w * fraction),
        h
    )

    draw.SimpleText(
        tostring(value),
        "SimpleF4.Small",
        x + w - S(5),
        y + h / 2,
        C.Theme.Text,
        TEXT_ALIGN_RIGHT,
        TEXT_ALIGN_CENTER
    )
end

local function updateAnimated(ply, hunger)
    animated.Health = smooth(
        animated.Health,
        math.max(0, ply:Health())
    )

    animated.Armour = smooth(
        animated.Armour,
        math.max(0, ply:Armor())
    )

    if hunger ~= nil then
        animated.Hunger = smooth(
            animated.Hunger,
            hunger
        )
    end

    animated.Money = smooth(
        animated.Money,
        getMoney(ply)
    )

    animated.Salary = smooth(
        animated.Salary,
        getSalary(ply)
    )
end


local function flashBar(kind, colour)
    local settings =
        hudConfig().Feedback or {}

    if settings.BarFlash == false then
        return
    end

    barFlashUntil[kind] =
        CurTime()
        + (
            tonumber(
                settings.BarFlashDuration
            )
            or 0.35
        )

    barFlashColour[kind] = colour
end

local function addFeedback(textValue, colour, kind)
    local config = hudConfig()
    local settings = config.Feedback or {}

    if settings.Enabled == false
    or SimpleF4.GetUserSetting("ReduceMotion") then
        return
    end

    table.insert(feedback, {
        Text = tostring(textValue),
        Colour = colour,
        Kind = tostring(kind or "generic"),
        Born = CurTime(),
        DieAt =
            CurTime()
            + (
                tonumber(settings.Duration)
                or 2
            ),
    })

    while #feedback > 4 do
        table.remove(feedback, 1)
    end
end

local function updateFeedback(ply)
    local health =
        math.max(0, ply:Health())

    local armour =
        math.max(0, ply:Armor())

    local money =
        math.floor(getMoney(ply))

    if lastActual.Health ~= nil
    and health ~= lastActual.Health then
        local delta =
            health - lastActual.Health

        local colour =
            delta > 0
            and C.Theme.Success
            or C.Theme.Danger

        addFeedback(
            (
                delta > 0
                and "+"
                or ""
            )
            .. tostring(delta)
            .. " HP",
            colour,
            "health"
        )

        flashBar(
            "Health",
            colour
        )
    end

    if lastActual.Armour ~= nil
    and armour ~= lastActual.Armour then
        local delta =
            armour - lastActual.Armour

        local colour =
            delta > 0
            and C.Theme.Success
            or Color(80, 145, 255)

        addFeedback(
            (
                delta > 0
                and "+"
                or ""
            )
            .. tostring(delta)
            .. " ARMOUR",
            colour,
            "armour"
        )

        flashBar(
            "Armour",
            colour
        )
    end

    if lastActual.Money ~= nil
    and money ~= lastActual.Money then
        local delta =
            money - lastActual.Money

        addFeedback(
            (
                delta > 0
                and "+"
                or "-"
            )
            .. F.FormatMoney(
                math.abs(delta)
            ),
            delta > 0
                and C.Theme.Success
                or C.Theme.Danger,
            "money"
        )
    end

    lastActual.Health = health
    lastActual.Armour = armour
    lastActual.Money = money
end

local function getHungerState(hunger)
    local settings =
        hudConfig().HungerWarnings or {}

    local hungryAt =
        tonumber(settings.HungryAt) or 25

    local starvingAt =
        tonumber(settings.StarvingAt) or 10

    if hunger <= starvingAt then
        return "starving"
    end

    if hunger <= hungryAt then
        return "hungry"
    end

    return "fed"
end

local function updateHungerWarning(hunger)
    if hunger == nil then
        hungerWarningState = nil
        return
    end

    local settings =
        hudConfig().HungerWarnings or {}

    if settings.Enabled == false then
        return
    end

    local hungryAt =
        tonumber(settings.HungryAt) or 25

    local starvingAt =
        tonumber(settings.StarvingAt) or 10

    local resetAbove =
        tonumber(settings.ResetAbove) or 30

    if hunger > resetAbove then
        hungerWarningState = nil
        return
    end

    local nextState

    if hunger <= starvingAt then
        nextState = "starving"
    elseif hunger <= hungryAt then
        nextState = "hungry"
    end

    if not nextState
    or nextState == hungerWarningState then
        return
    end

    hungerWarningState = nextState

    if nextState == "starving" then
        SimpleF4.Notify({
            Title = SimpleF4.L("HungerStarvingTitle"),
            Text = SimpleF4.L("HungerStarvingText"),
            Type = "warning",
            Icon = "icon16/exclamation.png",
            Duration = 5,
        })
    else
        SimpleF4.Notify({
            Title = SimpleF4.L("HungerHungryTitle"),
            Text = SimpleF4.L("HungerHungryText"),
            Type = "warning",
            Icon = "icon16/cup.png",
            Duration = 4,
        })
    end
end

local function drawFeedback(x, y, w)
    local now = CurTime()
    local visible = {}

    for index = #feedback, 1, -1 do
        local item = feedback[index]

        if now >= item.DieAt then
            table.remove(feedback, index)
        else
            table.insert(visible, item)
        end
    end

    local offsets = {
        money = 0,
        health = 0,
        armour = 0,
        generic = 0,
    }

    local baseY = {
        money = y + S(43),
        health = y + S(64),
        armour = y + S(78),
        generic = y + S(20),
    }

    for _, item in ipairs(visible) do
        local life =
            math.Clamp(
                (item.DieAt-now)
                / math.max(
                    .01,
                    item.DieAt-item.Born
                ),
                0,
                1
            )

        local alpha =
            math.floor(255*life)

        local kind =
            baseY[item.Kind]
            and item.Kind
            or "generic"

        local drawX =
            x + w + S(10)

        local drawY =
            baseY[kind]
            + offsets[kind]

        offsets[kind] =
            offsets[kind] + S(15)

        draw.SimpleText(
            item.Text,
            "SimpleF4.Small",
            drawX + 1,
            drawY + 1,
            Color(0, 0, 0, alpha),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )

        draw.SimpleText(
            item.Text,
            "SimpleF4.Small",
            drawX,
            drawY,
            Color(
                item.Colour.r,
                item.Colour.g,
                item.Colour.b,
                alpha
            ),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end
end

local function drawBarFlash(
    kind,
    x,
    y,
    w,
    h
)
    local untilTime =
        barFlashUntil[kind] or 0

    if untilTime <= CurTime() then
        return
    end

    local settings =
        hudConfig().Feedback or {}

    local duration =
        tonumber(
            settings.BarFlashDuration
        )
        or 0.35

    local fraction =
        math.Clamp(
            (untilTime-CurTime())
            / duration,
            0,
            1
        )

    local colour =
        barFlashColour[kind]
        or C.Theme.Text

    surface.SetDrawColor(
        colour.r,
        colour.g,
        colour.b,
        math.floor(120*fraction)
    )
    surface.DrawRect(
        x,
        y,
        w,
        h
    )
end

local function drawPlayerPanel(ply)
    local config = hudConfig()
    local layout = config.PlayerPanel or {}
    local compact = SimpleF4.GetUserSetting("HUDCompact")

    local w = S(tonumber(layout.Width) or 340)
    local left = S(tonumber(layout.Left) or 24)
    local bottom = S(tonumber(layout.Bottom) or 24)

    local portraitMode =
        SimpleF4.GetUserChoice(
            "HUDPortraitMode",
            "Avatar"
        )

    -- The identity portrait is a permanent part of the SimpleF4 HUD.
    -- Players only choose whether it uses their Steam avatar or model.
    local portraitVisible = true

    local hunger = getHunger(ply)
    local showHunger = hunger ~= nil

    updateAnimated(ply, hunger)
    updateFeedback(ply)
    updateHungerWarning(hunger)

    local playerH = S(
        (compact and 82 or 92)
        + (showHunger and 14 or 0)
    )

    local serverBarEnabled = layout.ServerBar ~= false
    local serverBarH =
        serverBarEnabled
        and S(tonumber(layout.ServerBarHeight) or 28)
        or 0

    local gap = serverBarEnabled and S(4) or 0

    local x = left
    local y = ScrH() - bottom - playerH
    local serverY = y - gap - serverBarH

    if serverBarEnabled then
        drawServerBar(x, serverY, w, serverBarH)
    end

    panelBox(x, y, w, playerH, C.Theme.Accent)

    local pad = S(compact and 8 or 9)
    local portraitSize = S(compact and 44 or 50)
    local contentX = x + pad

    if portraitVisible then
        if portraitMode == "Model" then
            if IsValid(AvatarPanel) then
                AvatarPanel:SetVisible(false)
            end

            local modelPanel = ensureModel(ply)
            modelPanel:SetSize(portraitSize, portraitSize)
            modelPanel:SetPos(x + pad, y + pad)
            modelPanel:SetVisible(true)
        else
            if IsValid(ModelPanel) then
                ModelPanel:SetVisible(false)
            end

            local avatar = ensureAvatar(ply)
            avatar:SetSize(portraitSize, portraitSize)
            avatar:SetPos(x + pad, y + pad)
            avatar:SetVisible(true)
        end

        contentX =
            x + pad + portraitSize + S(9)
    else
        hidePortraits()
    end

    draw.SimpleText(
        ply:Nick(),
        "SimpleF4.BodyBold",
        contentX,
        y + S(8),
        C.Theme.Text
    )

    draw.SimpleText(
        getJob(ply),
        "SimpleF4.Small",
        contentX,
        y + S(compact and 25 or 27),
        C.Theme.Muted
    )

    local moneyText =
        F.FormatMoney(
            math.floor(animated.Money + 0.5)
        )
        .. " ("
        .. F.FormatMoney(
            math.floor(animated.Salary + 0.5)
        )
        .. ")"

    draw.SimpleText(
        moneyText,
        "SimpleF4.Small",
        contentX,
        y + S(compact and 41 or 44),
        C.Theme.Success
    )

    local barX = contentX
    local barW = w - (barX - x) - pad
    local barH = S(compact and 9 or 10)
    local healthY = y + S(compact and 57 or 61)

    do
        draw.SimpleText(
            "♥",
            "SimpleF4.Small",
            barX - S(6),
            healthY + barH / 2,
            Color(230, 75, 75),
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER
        )

        local maxHealth =
            math.max(1, ply:GetMaxHealth())

        drawBar(
            barX,
            healthY,
            barW,
            barH,
            animated.Health / maxHealth,
            Color(190, 45, 45),
            math.floor(animated.Health + 0.5)
        )

        drawBarFlash(
            "Health",
            barX,
            healthY,
            barW,
            barH
        )
    end

    do
        local armourY =
            healthY + barH + S(4)

        draw.SimpleText(
            "♦",
            "SimpleF4.Small",
            barX - S(6),
            armourY + barH / 2,
            Color(85, 145, 255),
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER
        )

        drawBar(
            barX,
            armourY,
            barW,
            barH,
            animated.Armour / 100,
            Color(55, 105, 205),
            math.floor(animated.Armour + 0.5)
        )

        drawBarFlash(
            "Armour",
            barX,
            armourY,
            barW,
            barH
        )
    end

    if showHunger then
        local hungerY =
            healthY + (barH * 2) + S(8)

        local hungerState =
            getHungerState(
                animated.Hunger
            )

        local settings =
            hudConfig().HungerWarnings
            or {}

        local hungerColour =
            C.Theme.Success

        local stateLabel =
            SimpleF4.L(
                "HungerStateFed"
            )

        if hungerState == "hungry" then
            hungerColour =
                C.Theme.Warning

            stateLabel =
                SimpleF4.L(
                    "HungerStateHungry"
                )
        elseif hungerState == "starving" then
            hungerColour =
                C.Theme.Danger

            stateLabel =
                SimpleF4.L(
                    "HungerStateStarving"
                )

            if settings.PulseWhenStarving ~= false then
                local pulse =
                    .65
                    + .35
                    * (
                        (
                            math.sin(
                                CurTime()*5
                            )
                            + 1
                        )
                        / 2
                    )

                hungerColour = Color(
                    C.Theme.Danger.r,
                    C.Theme.Danger.g,
                    C.Theme.Danger.b,
                    math.floor(
                        255*pulse
                    )
                )
            end
        end

        draw.SimpleText(
            "●",
            "SimpleF4.Small",
            barX - S(6),
            hungerY + barH / 2,
            hungerColour,
            TEXT_ALIGN_RIGHT,
            TEXT_ALIGN_CENTER
        )

        drawBar(
            barX,
            hungerY,
            barW,
            barH,
            animated.Hunger / 100,
            hungerColour,
            math.floor(
                animated.Hunger + 0.5
            )
            .. "% • "
            .. stateLabel
        )
    end

    drawFeedback(x, y, w)

    return x, serverY, w
end

local function drawLockdown(x, y, w)
    local config = hudConfig()
    local lockdownConfig = config.Lockdown or {}

    if lockdownConfig.Enabled == false
    or not SimpleF4.GetUserSetting("HUDShowLockdown")
    or not isLockdown() then
        return y
    end

    local h = S(28)
    y = y - h - S(4)

    surface.SetDrawColor(C.Theme.Surface)
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(C.Theme.Danger)
    surface.DrawRect(x, y, S(3), h)

    draw.SimpleText(
        SimpleF4.L("HUDLockdown"),
        "SimpleF4.BodyBold",
        x + S(10),
        y + h / 2,
        C.Theme.Danger,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )

    return y
end

local function wrapAgenda(textValue, maxChars, maxLines)
    local words = string.Explode(" ", tostring(textValue or ""))
    local lines = {}
    local current = ""

    for _, word in ipairs(words) do
        local test =
            current == ""
            and word
            or (current .. " " .. word)

        if #test > maxChars and current ~= "" then
            table.insert(lines, current)
            current = word

            if #lines >= maxLines then
                break
            end
        else
            current = test
        end
    end

    if current ~= ""
    and #lines < maxLines then
        table.insert(lines, current)
    end

    return lines
end

local function drawAgenda(x, y)
    local config = hudConfig()
    local agendaConfig = config.Agenda or {}

    if agendaConfig.Enabled == false
    or not SimpleF4.GetUserSetting("HUDShowAgenda") then
        return
    end

    local agenda = getAgenda(LocalPlayer())
    if agenda == "" then return end

    local w =
        S(tonumber(agendaConfig.Width) or 340)
    local maxLines =
        math.max(
            1,
            tonumber(agendaConfig.MaxLines) or 5
        )

    local lines =
        wrapAgenda(agenda, 48, maxLines)

    if #lines == 0 then return end

    local lineH = S(16)
    local h =
        S(34)
        + (#lines * lineH)
        + S(8)

    y = y - h - S(4)

    panelBox(x, y, w, h, C.Theme.Accent)

    draw.SimpleText(
        SimpleF4.L("HUDAgenda"),
        "SimpleF4.BodyBold",
        x + S(10),
        y + S(8),
        C.Theme.Text
    )

    for index, line in ipairs(lines) do
        draw.SimpleText(
            line,
            "SimpleF4.Small",
            x + S(10),
            y + S(30) + ((index - 1) * lineH),
            C.Theme.Muted
        )
    end
end

local function drawAmmoPanel(ply)
    if not SimpleF4.GetUserSetting("HUDShowAmmo") then
        return
    end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end

    local primaryAmmoType = wep:GetPrimaryAmmoType()
    local clip = wep:Clip1()

    if clip < 0 and primaryAmmoType < 0 then
        return
    end

    local config = hudConfig()
    local layout = config.AmmoPanel or {}
    local compact = SimpleF4.GetUserSetting("HUDCompact")

    local w = S(tonumber(layout.Width) or 180)
    local h = S(compact and 62 or 70)

    local x =
        ScrW()
        - w
        - S(tonumber(layout.Right) or 24)

    local y =
        ScrH()
        - h
        - S(tonumber(layout.Bottom) or 24)

    panelBox(x, y, w, h, C.Theme.Accent)

    draw.SimpleText(
        weaponName(wep),
        "SimpleF4.Small",
        x + S(10),
        y + S(7),
        C.Theme.Text
    )

    local reserve = 0

    if primaryAmmoType >= 0 then
        reserve = ply:GetAmmoCount(primaryAmmoType)
    end

    local leftCentre = x + w * 0.30
    local rightCentre = x + w * 0.72

    draw.SimpleText(
        tostring(math.max(clip, 0)),
        "SimpleF4.Title",
        leftCentre,
        y + S(compact and 24 or 26),
        C.Theme.Text,
        TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
        tostring(math.max(reserve, 0)),
        "SimpleF4.Title",
        rightCentre,
        y + S(compact and 24 or 26),
        C.Theme.Text,
        TEXT_ALIGN_CENTER
    )

    draw.SimpleText(
        SimpleF4.L("HUDClip"),
        "SimpleF4.Small",
        leftCentre,
        y + h - S(8),
        C.Theme.Muted,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_BOTTOM
    )

    draw.SimpleText(
        SimpleF4.L("HUDReserve"),
        "SimpleF4.Small",
        rightCentre,
        y + h - S(8),
        C.Theme.Muted,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_BOTTOM
    )

    surface.SetDrawColor(C.Theme.Line)
    surface.DrawRect(
        x + math.floor(w / 2),
        y + S(25),
        1,
        h - S(34)
    )
end

hook.Add("HUDPaint", "SimpleF4.HUD.Paint", function()
    if not enabled() then
        hidePortraits()
        return
    end

    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:Alive() then
        hidePortraits()
        return
    end

    local x, topY, w = drawPlayerPanel(ply)
    drawAmmoPanel(ply)
end)

hook.Add(
    "SimpleF4_PopulateModuleSettingsSections",
    "SimpleF4.HUD.Settings",
    function(sections)
        local config = hudConfig()

        if config.Enabled == false then return end

        local items = {}

        table.Add(items, {
            {
                Type = "choice",
                Key = "HUDPortraitMode",
                Label = "HUDPortraitMode",
                Description = "HUDPortraitModeDesc",
                Values = {"Avatar", "Model"},
                ValueLabels = {
                    Avatar = "HUDPortraitAvatar",
                    Model = "HUDPortraitModel",
                },
            },
            {
                Type = "toggle",
                Key = "HUDShowAmmo",
                Label = "HUDShowAmmo",
                Description = "HUDShowAmmoDesc",
            },
            {
                Type = "toggle",
                Key = "HUDCompact",
                Label = "HUDCompact",
                Description = "HUDCompactDesc",
            },
        })

        table.insert(sections, {
            ID = "HUD",
            Order = 60,
            Label = "HUDSettings",
            Items = items,
        })
    end
)


hook.Add(
    "SimpleF4_UserSettingChanged",
    "SimpleF4.HUD.PortraitModeChanged",
    function(key)
        if key ~= "HUDPortraitMode" then return end
        hidePortraits()
    end
)

hook.Add("ShutDown", "SimpleF4.HUD.Cleanup", function()
    if IsValid(AvatarPanel) then
        AvatarPanel:Remove()
    end

    if IsValid(ModelPanel) then
        ModelPanel:Remove()
    end
end)
