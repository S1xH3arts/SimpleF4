local C = SimpleF4.Config

if not SimpleF4.IsModuleEnabled("Notifications") then return end

local queue = SimpleF4.NotificationQueue or {}
SimpleF4.NotificationQueue = queue

local oldLegacy = notification.AddLegacy
local oldProgress = notification.AddProgress
local oldKill = notification.Kill

local mats = {
    [NOTIFY_ERROR] = Material("icon16/exclamation.png", "smooth"),
    [NOTIFY_HINT] = Material("icon16/help.png", "smooth"),
    [NOTIFY_UNDO] = Material("icon16/arrow_undo.png", "smooth"),
    [NOTIFY_CLEANUP] = Material("icon16/bin.png", "smooth"),
    [NOTIFY_GENERIC] = Material("icon16/information.png", "smooth"),
}

local function cfg()
    return C.Modules and C.Modules.Notifications or {}
end

local function enabled()
    local c=cfg()
    if c.Enabled == false then return false end
    if c.AllowPlayerDisable == false then return true end
    return SimpleF4.GetUserSetting("NotificationsEnabled")
end

local function push(textValue, kind, duration, id, progress, extra)
    if not enabled() then
        if oldLegacy and not progress then
            oldLegacy(textValue, kind, duration)
        end
        return
    end

    if id then
        for _,v in ipairs(queue) do
            if v.ID == id then
                v.Text=tostring(textValue)
                v.Progress=progress
                v.DieAt=CurTime()+(tonumber(duration) or 9999)

                if istable(extra) then
                    v.Title=extra.Title
                    v.Type=tostring(extra.Type or v.Type or "info")
                    v.Icon=extra.Icon or v.Icon
                    v.Accent=extra.Accent or v.Accent
                end
                return
            end
        end
    end

    extra = istable(extra) and extra or {}

    table.insert(queue,1,{
        Text=tostring(textValue or ""),
        Title=extra.Title
            and tostring(extra.Title)
            or nil,
        Kind=tonumber(kind) or NOTIFY_GENERIC,
        Type=tostring(extra.Type or "info"),
        Icon=extra.Icon,
        Born=CurTime(),
        DieAt=CurTime()+(tonumber(duration) or tonumber(cfg().Duration) or 5),
        ID=id,
        Progress=progress,
        Accent=extra.Accent,
    })
end

local kindMap = {
    error = NOTIFY_ERROR,
    warning = NOTIFY_HINT,
    success = NOTIFY_GENERIC,
    info = NOTIFY_GENERIC,
    money = NOTIFY_GENERIC,
    wanted = NOTIFY_ERROR,
    level = NOTIFY_GENERIC,
}

function SimpleF4.PushNotification(data)
    if not istable(data) then return false end

    local notificationType =
        tostring(data.Type or data.Kind or "info")

    push(
        data.Text or data.Message or "",
        kindMap[notificationType]
            or NOTIFY_GENERIC,
        data.Duration,
        data.ID,
        data.Progress,
        {
            Title = data.Title,
            Type = notificationType,
            Icon = data.Icon,
            Accent = data.Accent,
        }
    )

    return true
end

notification.AddLegacy=function(textValue,kind,duration)
    push(textValue,kind,duration)
end

notification.AddProgress=function(id,textValue,frac)
    push(textValue,NOTIFY_GENERIC,9999,id,frac == nil and -1 or frac)
end

notification.Kill=function(id)
    for i=#queue,1,-1 do
        if queue[i].ID == id then
            table.remove(queue,i)
        end
    end
end

local function splitLongWord(word, font, maxWidth)
    surface.SetFont(font)

    local chunks = {}
    local current = ""

    for index = 1, #word do
        local char = string.sub(word, index, index)
        local test = current .. char

        if current ~= ""
        and surface.GetTextSize(test) > maxWidth then
            table.insert(chunks, current)
            current = char
        else
            current = test
        end
    end

    if current ~= "" then
        table.insert(chunks, current)
    end

    return chunks
end

local function wrapNotificationText(
    textValue,
    font,
    maxWidth,
    maxLines
)
    surface.SetFont(font)

    local rawWords = string.Explode(
        " ",
        tostring(textValue or ""),
        false
    )

    local words = {}

    for _, word in ipairs(rawWords) do
        if surface.GetTextSize(word) > maxWidth then
            for _, chunk in ipairs(
                splitLongWord(word, font, maxWidth)
            ) do
                table.insert(words, chunk)
            end
        else
            table.insert(words, word)
        end
    end

    local lines = {}
    local current = ""

    for _, word in ipairs(words) do
        local test =
            current == ""
            and word
            or (current .. " " .. word)

        if surface.GetTextSize(test) > maxWidth
        and current ~= "" then
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

    local reconstructed =
        table.concat(words, " ")

    local visibleText =
        table.concat(lines, " ")

    if #lines >= maxLines
    and #visibleText < #reconstructed then
        local last = lines[#lines] or ""

        while #last > 0
        and surface.GetTextSize(
            last .. "..."
        ) > maxWidth do
            last = string.sub(last, 1, -2)
        end

        lines[#lines] = last .. "..."
    end

    return lines
end

hook.Add("HUDPaint","SimpleF4.Notifications.Paint",function()
    if not enabled()
    and not SimpleF4.IsModuleTestMode() then
        return
    end

    local c=cfg()
    local maxVisible=math.max(1,tonumber(c.MaxVisible) or 5)
    local width=SimpleF4.S(tonumber(c.Width) or 360)
    local right=SimpleF4.S(tonumber(c.Right) or 24)
    local bottom=SimpleF4.S(tonumber(c.Bottom) or 110)
    local gap=SimpleF4.S(6)
    local now=CurTime()
    local font="SimpleF4.Small"
    local textPad=SimpleF4.S(tonumber(c.TextPadding) or 12)
    local maxLines=math.max(1,tonumber(c.MaxTextLines) or 3)
    local textXOffset=SimpleF4.S(36)
    local availableTextWidth=
        width
        - textXOffset
        - textPad

    for i=#queue,1,-1 do
        local n=queue[i]
        if not n.ID and now >= n.DieAt then
            table.remove(queue,i)
        end
    end

    local visible={}
    for i=1,math.min(maxVisible,#queue) do
        table.insert(visible,queue[i])
    end

    if SimpleF4.IsModuleTestMode()
    and #visible==0 then
        visible={
            {
                Text=SimpleF4.L("NotificationTestLong"),
                Kind=NOTIFY_HINT,
                Born=now,
                DieAt=now+9999,
            },
            {
                Text=SimpleF4.L("NotificationTestSuccess"),
                Kind=NOTIFY_GENERIC,
                Born=now,
                DieAt=now+9999,
            },
        }
    end

    local stackY=ScrH()-bottom

    for index,n in ipairs(visible) do
        local age=now-(n.Born or now)
        local remaining=(n.DieAt or (now+9999))-now
        local alpha=255

        if age < .2 then
            alpha=math.floor(
                255*math.Clamp(age/.2,0,1)
            )
        end

        if not n.ID and remaining < .25 then
            alpha=math.floor(
                255*math.Clamp(remaining/.25,0,1)
            )
        end

        local lines=wrapNotificationText(
            n.Text,
            font,
            availableTextWidth,
            maxLines
        )

        local lineH=SimpleF4.S(16)
        local titleH =
            n.Title and SimpleF4.S(18) or 0

        local rowH=math.max(
            SimpleF4.S(46),
            SimpleF4.S(18)
            + titleH
            + (#lines*lineH)
            + (n.Progress~=nil and SimpleF4.S(5) or 0)
        )

        local x=ScrW()-right-width
        local y=stackY-rowH

        surface.SetDrawColor(
            C.Theme.Background.r,
            C.Theme.Background.g,
            C.Theme.Background.b,
            math.floor(alpha*.95)
        )
        surface.DrawRect(x,y,width,rowH)

        surface.SetDrawColor(
            C.Theme.Line.r,
            C.Theme.Line.g,
            C.Theme.Line.b,
            alpha
        )
        surface.DrawOutlinedRect(x,y,width,rowH,1)

        local accent =
            n.Accent
            or (
                n.Type == "success"
                and C.Theme.Success
            )
            or (
                n.Type == "money"
                and C.Theme.Success
            )
            or (
                n.Type == "wanted"
                and C.Theme.Danger
            )
            or (
                n.Type == "level"
                and C.Theme.Warning
            )
            or (
                n.Kind == NOTIFY_ERROR
                and C.Theme.Danger
            )
            or (
                n.Kind == NOTIFY_HINT
                and C.Theme.Warning
            )
            or C.Theme.Accent

        surface.SetDrawColor(
            accent.r,accent.g,accent.b,alpha
        )
        surface.DrawRect(
            x,y,SimpleF4.S(3),rowH
        )

        local mat =
            n.Icon
            and Material(
                tostring(n.Icon),
                "smooth"
            )
            or mats[n.Kind]
            or mats[NOTIFY_GENERIC]
        surface.SetMaterial(mat)
        surface.SetDrawColor(255,255,255,alpha)
        surface.DrawTexturedRect(
            x+SimpleF4.S(10),
            y+SimpleF4.S(14),
            SimpleF4.S(16),
            SimpleF4.S(16)
        )

        local contentH =
            titleH + (#lines*lineH)

        local textY=
            y
            + math.max(
                SimpleF4.S(8),
                (rowH-contentH)/2
            )

        if n.Title then
            draw.SimpleText(
                n.Title,
                "SimpleF4.BodyBold",
                x+textXOffset,
                textY,
                Color(
                    C.Theme.Text.r,
                    C.Theme.Text.g,
                    C.Theme.Text.b,
                    alpha
                )
            )

            textY=textY+titleH
        end

        for lineIndex,line in ipairs(lines) do
            draw.SimpleText(
                line,
                font,
                x+textXOffset,
                textY+(lineIndex-1)*lineH,
                Color(
                    C.Theme.Text.r,
                    C.Theme.Text.g,
                    C.Theme.Text.b,
                    alpha
                )
            )
        end

        if n.Progress ~= nil then
            local frac=n.Progress

            if frac < 0 then
                frac=(CurTime()*0.7)%1
            end

            surface.SetDrawColor(
                accent.r,accent.g,accent.b,alpha
            )
            surface.DrawRect(
                x,
                y+rowH-SimpleF4.S(3),
                width*math.Clamp(frac,0,1),
                SimpleF4.S(3)
            )
        end

        stackY=y-gap
    end
end)

hook.Add("SimpleF4_PopulateModuleSettingsSections","SimpleF4.Notifications.Settings",function(sections)
    if cfg().Enabled == false then return end
    table.insert(sections,{
        ID="Notifications",Order=80,Label="NotificationsSettings",
        Items={{
            Type="toggle",Key="NotificationsEnabled",
            Label="NotificationsEnabled",Description="NotificationsEnabledDesc",
        }},
    })
end)

-- DarkRP legacy notifications.
local lastSound=0
local function darkRPNotify(msg)
    local textValue=msg:ReadString()
    local kind=msg:ReadShort()
    local duration=msg:ReadLong()
    notification.AddLegacy(textValue,kind,duration)

    if cfg().PlaySounds == true and lastSound+.1 < SysTime() then
        surface.PlaySound(kind == NOTIFY_ERROR and "buttons/button10.wav" or "buttons/button15.wav")
        lastSound=SysTime()
    end
end

usermessage.Hook("_Notify",darkRPNotify)
