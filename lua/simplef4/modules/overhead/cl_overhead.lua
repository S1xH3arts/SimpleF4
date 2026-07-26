local C = SimpleF4.Config
local F = SimpleF4.Functions

if not SimpleF4.IsModuleEnabled("Overhead") then return end

surface.CreateFont("SimpleF4.OverheadName", {
    font = "Roboto",
    size = 42,
    weight = 700,
    antialias = true,
})

surface.CreateFont("SimpleF4.OverheadLine", {
    font = "Roboto",
    size = 34,
    weight = 500,
    antialias = true,
})

local ICONS = {
    Name = Material("icon16/user_gray.png", "smooth"),
    Job = Material("icon16/group.png", "smooth"),
    Health = Material("icon16/heart.png", "smooth"),
    Licence = Material("icon16/page_white_text.png", "smooth"),
    Wanted = Material("icon16/exclamation.png", "smooth"),
    Warrant = Material("icon16/page_white_magnify.png", "smooth"),
    Speaking = Material("icon16/sound.png", "smooth"),
}

local function cfg()
    return C.Modules and C.Modules.Overhead or {}
end

local function enabled()
    local config = cfg()

    if SimpleF4.IsModuleTestMode() then
        return true
    end

    if config.Enabled == false then return false end

    if config.AllowPlayerDisable == false then
        return true
    end

    return SimpleF4.GetUserSetting("OverheadEnabled")
end

local function isCloaked(ply)
    if not IsValid(ply) then return true end
    if ply:GetNoDraw() then return true end
    if ply:GetColor().a <= 5 then return true end

    if ply:GetNWBool("Cloaked", false)
    or ply:GetNWBool("cloaked", false)
    or ply:GetNWBool("Invisible", false)
    or ply:GetNWBool("invisible", false)
    or ply:GetNWBool("IsCloaked", false) then
        return true
    end

    local hookResult =
        hook.Run("SimpleF4_IsPlayerCloaked", ply)

    if hookResult ~= nil then
        return hookResult == true
    end

    return false
end

local function getJobName(ply)
    if F.GetJobName then
        return F.GetJobName(ply)
    end

    return team.GetName(ply:Team()) or SimpleF4.L("Unknown")
end

local function getRankName(ply)
    local hooked =
        hook.Run("SimpleF4_GetOverheadRank", ply)

    if hooked ~= nil then
        return tostring(hooked)
    end

    local group = ply:GetUserGroup()

    if not group or group == "" then
        return SimpleF4.L("Unknown")
    end

    return group
end

local function ownsLicence(ply)
    local hooked =
        hook.Run("SimpleF4_PlayerHasLicence", ply)

    if hooked ~= nil then
        return hooked == true
    end

    if ply.getDarkRPVar then
        local value =
            ply:getDarkRPVar("HasGunlicense")

        if value == nil then
            value =
                ply:getDarkRPVar("HasGunLicense")
        end

        return value == true
    end

    return false
end

local function isWanted(ply)
    local hooked =
        hook.Run("SimpleF4_IsPlayerWanted", ply)

    if hooked ~= nil then
        return hooked == true
    end

    if ply.getDarkRPVar then
        return ply:getDarkRPVar("wanted") == true
    end

    return false
end


local function getWantedReason(ply)
    local hooked =
        hook.Run(
            "SimpleF4_GetWantedReason",
            ply
        )

    if hooked ~= nil then
        return tostring(hooked or "")
    end

    if ply.getDarkRPVar then
        return tostring(
            ply:getDarkRPVar(
                "wantedReason"
            )
            or ""
        )
    end

    return ""
end

local function hasWarrant(ply)
    local hooked =
        hook.Run(
            "SimpleF4_PlayerHasWarrant",
            ply
        )

    if hooked ~= nil then
        return hooked == true
    end

    if ply.getDarkRPVar then
        return
            ply:getDarkRPVar(
                "HasWarrant"
            ) == true
            or ply:getDarkRPVar(
                "warrant"
            ) == true
    end

    return false
end

local function alphaForDistance(distance)
    local config = cfg()

    if not SimpleF4.GetUserSetting("OverheadFadeDistance")
    or config.FadeDistance == false then
        return 255
    end

    local maxDistance =
        tonumber(config.MaxDistance) or 300

    local fadeStart =
        tonumber(config.FadeStart) or 200

    if distance <= fadeStart then
        return 255
    end

    if distance >= maxDistance then
        return 0
    end

    return math.Clamp(
        255
        * (
            1
            - (
                (distance - fadeStart)
                / math.max(1, maxDistance - fadeStart)
            )
        ),
        0,
        255
    )
end

local function alphaColor(col, alpha)
    return Color(col.r, col.g, col.b, alpha)
end

local function drawIcon(material, x, y, size, colour)
    local config = cfg()

    surface.SetMaterial(material)

    if config.IconShadow ~= false then
        local offset =
            tonumber(config.IconShadowOffset) or 2

        surface.SetDrawColor(
            0,
            0,
            0,
            tonumber(config.IconShadowAlpha) or 210
        )

        surface.DrawTexturedRect(
            x + offset,
            y - size / 2 + offset,
            size,
            size
        )
    end

    surface.SetDrawColor(colour)
    surface.DrawTexturedRect(
        x,
        y - size / 2,
        size,
        size
    )
end

local function shouldSuppressHookName(id)
    local value = string.lower(tostring(id or ""))

    if string.find(value, "simplef4", 1, true) then
        return false
    end

    return
        string.find(value, "darkrp", 1, true) ~= nil
        or string.find(value, "targetid", 1, true) ~= nil
        or string.find(value, "playerinfo", 1, true) ~= nil
        or string.find(value, "headhud", 1, true) ~= nil
        or string.find(value, "overhead", 1, true) ~= nil
        or string.find(value, "graphite", 1, true) ~= nil
end

local function suppressDefaultOverheads()
    local config = cfg()

    if config.DisableDefaultOverhead == false
    or config.AggressiveDefaultSuppression == false then
        return
    end

    local hookTable = hook.GetTable()

    for _, hookName in ipairs({
        "HUDDrawTargetID",
        "PostPlayerDraw",
    }) do
        local entries = hookTable[hookName]

        if istable(entries) then
            for id in pairs(entries) do
                if shouldSuppressHookName(id) then
                    hook.Remove(hookName, id)
                end
            end
        end
    end
end

hook.Add(
    "InitPostEntity",
    "SimpleF4.Overhead.SuppressDefaults",
    function()
        timer.Simple(0.5, suppressDefaultOverheads)
        timer.Simple(2, suppressDefaultOverheads)
    end
)

hook.Add(
    "OnReloaded",
    "SimpleF4.Overhead.SuppressDefaultsReload",
    function()
        timer.Simple(0, suppressDefaultOverheads)
    end
)

-- Stop DarkRP's normal target ID before its gamemode fallback gets a chance
-- to render.
hook.Add(
    "HUDDrawTargetID",
    "000_SimpleF4.Overhead.DisableDefault",
    function()
        if enabled()
        and cfg().DisableDefaultOverhead ~= false then
            return false
        end
    end
)

hook.Add(
    "HUDShouldDraw",
    "SimpleF4.Overhead.HideDarkRPTarget",
    function(name)
        if not enabled() then return end

        if name == "DarkRP_EntityDisplay"
        or name == "DarkRP_ZombieInfo" then
            return false
        end
    end
)


local function drawShadowText(
    textValue,
    font,
    x,
    y,
    colour,
    xAlign,
    yAlign,
    alpha
)
    local config = cfg()

    xAlign = xAlign or TEXT_ALIGN_LEFT
    yAlign = yAlign or TEXT_ALIGN_CENTER

    if config.TextShadow ~= false then
        local offset =
            tonumber(config.TextShadowOffset) or 2
        local shadowAlpha =
            math.min(
                alpha,
                tonumber(config.TextShadowAlpha) or 220
            )

        draw.SimpleText(
            textValue,
            font,
            x + offset,
            y + offset,
            Color(0, 0, 0, shadowAlpha),
            xAlign,
            yAlign
        )
    end

    draw.SimpleText(
        textValue,
        font,
        x,
        y,
        colour,
        xAlign,
        yAlign
    )
end

hook.Add(
    "PostPlayerDraw",
    "SimpleF4.Overhead.Draw",
    function(ply)
        if not enabled() then return end
        if not IsValid(ply) then return end
        if ply == LocalPlayer() then return end
        if not ply:Alive() then return end
        if isCloaked(ply) then return end

        local localPly = LocalPlayer()
        if not IsValid(localPly) then return end

        local distance =
            localPly:GetPos():Distance(ply:GetPos())

        local config = cfg()
        local maxDistance =
            tonumber(config.MaxDistance) or 300

        if distance > maxDistance then return end

        local alpha = alphaForDistance(distance)
        if alpha <= 0 then return end

        local pos =
            ply:EyePos()
            + Vector(
                0,
                0,
                tonumber(config.VerticalOffset) or 8
            )

        local ang =
            Angle(
                0,
                EyeAngles().y - 90,
                90
            )

        local scale =
            tonumber(config.Scale) or 0.05

        local wanted =
            config.ShowWanted ~= false
            and SimpleF4.GetUserSetting("OverheadShowWanted")
            and isWanted(ply)

        local speaking =
            config.ShowSpeaking ~= false
            and SimpleF4.GetUserSetting("OverheadShowSpeaking")
            and ply:IsSpeaking()

        local warrant = hasWarrant(ply)
        local wantedReason =
            wanted and getWantedReason(ply)
            or ""

        local showLicence =
            SimpleF4.GetUserSetting("OverheadShowLicence")

        local licence =
            showLicence and ownsLicence(ply)

        cam.Start3D2D(pos, ang, scale)
            local sideOffset =
                tonumber(config.SideOffset) or 260

            local x = sideOffset
            local y = 0
            local lineH = 42
            local iconSize = 28

            if config.ReadabilityBackdrop ~= false then
                local padding =
                    tonumber(config.ReadabilityPadding) or 8

                local backdropH =
                    (showLicence and 4 or 3) * lineH
                    + padding * 2

                surface.SetDrawColor(
                    0,
                    0,
                    0,
                    math.min(
                        alpha,
                        tonumber(
                            config.ReadabilityBackdropAlpha
                        ) or 115
                    )
                )

                surface.DrawRect(
                    x - padding,
                    y - padding,
                    440,
                    backdropH
                )
            end

            local textColour =
                alphaColor(C.Theme.Text, alpha)

            local muted =
                alphaColor(C.Theme.Muted, alpha)

            local accent =
                alphaColor(
                    wanted
                    and C.Theme.Danger
                    or C.Theme.Accent,
                    alpha
                )

            if config.DrawBackground == true then
                local bgW = 430
                local bgH =
                    showLicence
                    and 176
                    or 134

                surface.SetDrawColor(
                    alphaColor(
                        C.Theme.Background,
                        math.floor(alpha * 0.84)
                    )
                )
                surface.DrawRect(
                    x - 18,
                    y - 18,
                    bgW,
                    bgH
                )

                surface.SetDrawColor(accent)
                surface.DrawRect(
                    x - 18,
                    y - 18,
                    4,
                    bgH
                )
            end

            drawIcon(
                ICONS.Name,
                x,
                y + lineH / 2,
                iconSize,
                Color(255, 255, 255, alpha)
            )

            drawShadowText(
                ply:Nick()
                    .. " | "
                    .. getRankName(ply),
                "SimpleF4.OverheadName",
                x + 38,
                y + lineH / 2,
                textColour,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER,
                alpha
            )

            local statusX = x + 400

            if wanted then
                local pulse =
                    .7
                    + .3
                    * (
                        (
                            math.sin(
                                CurTime()*5
                            )
                            + 1
                        )
                        / 2
                    )

                drawIcon(
                    ICONS.Wanted,
                    statusX,
                    y + lineH / 2,
                    iconSize,
                    alphaColor(
                        C.Theme.Danger,
                        math.floor(
                            alpha*pulse
                        )
                    )
                )

                statusX = statusX - 38
            end

            if warrant then
                drawIcon(
                    ICONS.Warrant,
                    statusX,
                    y + lineH / 2,
                    iconSize,
                    alphaColor(
                        C.Theme.Warning,
                        alpha
                    )
                )

                statusX = statusX - 38
            end

            if speaking then
                drawIcon(
                    ICONS.Speaking,
                    statusX,
                    y + lineH / 2,
                    iconSize,
                    alphaColor(
                        C.Theme.Success,
                        alpha
                    )
                )
            end

            y = y + lineH

            drawIcon(
                ICONS.Job,
                x,
                y + lineH / 2,
                iconSize,
                muted
            )

            drawShadowText(
                getJobName(ply),
                "SimpleF4.OverheadLine",
                x + 38,
                y + lineH / 2,
                textColour,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER,
                alpha
            )

            y = y + lineH

            drawIcon(
                ICONS.Health,
                x,
                y + lineH / 2,
                iconSize,
                alphaColor(
                    C.Theme.Danger,
                    alpha
                )
            )

            drawShadowText(
                tostring(
                    math.max(0, ply:Health())
                ),
                "SimpleF4.OverheadLine",
                x + 38,
                y + lineH / 2,
                textColour,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER,
                alpha
            )

            if wanted then
                y = y + lineH

                drawIcon(
                    ICONS.Wanted,
                    x,
                    y + lineH / 2,
                    iconSize,
                    alphaColor(
                        C.Theme.Danger,
                        alpha
                    )
                )

                local wantedText =
                    wantedReason ~= ""
                    and SimpleF4.L(
                        "OverheadWantedReason",
                        {reason=wantedReason}
                    )
                    or SimpleF4.L(
                        "OverheadWanted"
                    )

                drawShadowText(
                    wantedText,
                    "SimpleF4.OverheadLine",
                    x + 38,
                    y + lineH / 2,
                    alphaColor(
                        C.Theme.Danger,
                        alpha
                    ),
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER,
                    alpha
                )
            end

            if warrant then
                y = y + lineH

                drawIcon(
                    ICONS.Warrant,
                    x,
                    y + lineH / 2,
                    iconSize,
                    alphaColor(
                        C.Theme.Warning,
                        alpha
                    )
                )

                drawShadowText(
                    SimpleF4.L(
                        "OverheadWarrant"
                    ),
                    "SimpleF4.OverheadLine",
                    x + 38,
                    y + lineH / 2,
                    alphaColor(
                        C.Theme.Warning,
                        alpha
                    ),
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER,
                    alpha
                )
            end

            if showLicence then
                y = y + lineH

                drawIcon(
                    ICONS.Licence,
                    x,
                    y + lineH / 2,
                    iconSize,
                    alphaColor(
                        licence
                        and C.Theme.Success
                        or C.Theme.Muted,
                        alpha
                    )
                )

                drawShadowText(
                    licence
                    and SimpleF4.L(
                        "OverheadOwnLicence"
                    )
                    or SimpleF4.L(
                        "OverheadNoLicence"
                    ),
                    "SimpleF4.OverheadLine",
                    x + 38,
                    y + lineH / 2,
                    licence
                    and alphaColor(
                        C.Theme.Success,
                        alpha
                    )
                    or muted,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER,
                    alpha
                )
            end
        cam.End3D2D()
    end
)


hook.Add(
    "HUDPaint",
    "SimpleF4.Overhead.TestPaint",
    function()
        if not SimpleF4.IsModuleTestMode() then
            return
        end

        local x = ScrW() * 0.56
        local y = ScrH() * 0.34
        local lineH = SimpleF4.S(22)
        local iconSize = SimpleF4.S(16)

        local rows = {
            {
                Icon = ICONS.Name,
                Text = SimpleF4.L("ModuleTestPlayerName"),
                Colour = Color(255, 255, 255),
            },
            {
                Icon = ICONS.Job,
                Text = SimpleF4.L("ModuleTestJobName"),
                Colour = C.Theme.Muted,
            },
            {
                Icon = ICONS.Health,
                Text = "100",
                Colour = C.Theme.Danger,
            },
            {
                Icon = ICONS.Licence,
                Text = SimpleF4.L("OverheadOwnLicence"),
                Colour = C.Theme.Success,
            },
        }

        for index, row in ipairs(rows) do
            local ry = y + ((index - 1) * lineH)

            surface.SetMaterial(row.Icon)
            surface.SetDrawColor(row.Colour)
            surface.DrawTexturedRect(
                x,
                ry,
                iconSize,
                iconSize
            )

            draw.SimpleText(
                row.Text,
                index == 1
                    and "SimpleF4.BodyBold"
                    or "SimpleF4.Small",
                x + iconSize + SimpleF4.S(6),
                ry + iconSize / 2,
                C.Theme.Text,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end

        surface.SetMaterial(ICONS.Wanted)
        surface.SetDrawColor(C.Theme.Danger)
        surface.DrawTexturedRect(
            x + SimpleF4.S(190),
            y,
            iconSize,
            iconSize
        )

        surface.SetMaterial(ICONS.Speaking)
        surface.SetDrawColor(C.Theme.Success)
        surface.DrawTexturedRect(
            x + SimpleF4.S(212),
            y,
            iconSize,
            iconSize
        )
    end
)

hook.Add(
    "SimpleF4_PopulateModuleSettingsSections",
    "SimpleF4.Overhead.Settings",
    function(sections)
        local config = cfg()

        if config.Enabled == false then return end

        local items = {}

        if config.AllowPlayerDisable ~= false then
            table.insert(items, {
                Type = "toggle",
                Key = "OverheadEnabled",
                Label = "OverheadEnabled",
                Description = "OverheadEnabledDesc",
            })
        end

        table.Add(items, {
            {
                Type = "toggle",
                Key = "OverheadShowWanted",
                Label = "OverheadShowWanted",
                Description = "OverheadShowWantedDesc",
            },
            {
                Type = "toggle",
                Key = "OverheadShowSpeaking",
                Label = "OverheadShowSpeaking",
                Description = "OverheadShowSpeakingDesc",
            },
            {
                Type = "toggle",
                Key = "OverheadShowLicence",
                Label = "OverheadShowLicence",
                Description = "OverheadShowLicenceDesc",
            },
            {
                Type = "toggle",
                Key = "OverheadFadeDistance",
                Label = "OverheadFadeDistance",
                Description = "OverheadFadeDistanceDesc",
            },
        })

        table.insert(sections, {
            ID = "Overhead",
            Order = 70,
            Label = "OverheadSettings",
            Items = items,
        })
    end
)
