local PANEL = {}

local C = SimpleF4.Config
local F = SimpleF4.Functions

local function S(v)
    return SimpleF4.S(v)
end

local function text(str, font, x, y, col, ax, ay)
    draw.SimpleText(
        tostring(str or ""),
        font,
        x,
        y,
        col or color_white,
        ax or TEXT_ALIGN_LEFT,
        ay or TEXT_ALIGN_TOP
    )
end

local function formatUptime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))

    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return days .. "d " .. hours .. "h"
    elseif hours > 0 then
        return hours .. "h " .. minutes .. "m"
    end

    return minutes .. "m"
end

local function pingQuality(ping)
    ping = tonumber(ping) or 0

    if ping <= 60 then
        return SimpleF4.L("PingGood"), C.Theme.Success
    elseif ping <= 120 then
        return SimpleF4.L("PingOkay"), C.Theme.Warning
    end

    return SimpleF4.L("PingPoor"), C.Theme.Danger
end

local function statCard(parent, title, valueFn, subtitleFn)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetTall(S(120))

    pnl.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)

        text(title, "SimpleF4.Small", 18, 16, C.Theme.Muted)
        text(valueFn(), "SimpleF4.CardNumber", 18, 43, C.Theme.Text)

        if subtitleFn then
            text(subtitleFn(), "SimpleF4.Small", 18, 88, C.Theme.Muted)
        end
    end

    return pnl
end

function PANEL:Init()
    self:Dock(FILL)

    local D = C.Dashboard or {}


    local maintenance = C.Maintenance or {}

    local maintenanceEnabled =
        GetGlobalBool(
            "SimpleF4.Maintenance",
            maintenance.Enabled == true
        )

    if maintenanceEnabled then
        local banner = vgui.Create("DPanel", self)
        banner:Dock(TOP)
        banner:SetTall(S(58))
        banner:DockMargin(0, 0, 0, S(8))

        banner.Paint = function(_, w, h)
            surface.SetDrawColor(C.Theme.Surface)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(C.Theme.Warning)
            surface.DrawRect(0, 0, S(4), h)

            text(
                tostring(
                    maintenance.Title
                    or SimpleF4.L("MaintenanceTitleFallback")
                ),
                "SimpleF4.BodyBold",
                S(18),
                S(10),
                C.Theme.Warning
            )

            text(
                tostring(maintenance.Message or ""),
                "SimpleF4.Small",
                S(18),
                S(34),
                C.Theme.Muted
            )
        end
    end

    ---------------------------------------------------
    -- TOP STATS
    ---------------------------------------------------

    local cards = {}

    if D.ShowPlayersOnline ~= false then
        table.insert(cards, {
            SimpleF4.L("PlayersOnline"),
            function() return player.GetCount() end,
            function() return SimpleF4.L("ConnectedRightNow") end
        })
    end

    if D.ShowStaffOnline ~= false then
        table.insert(cards, {
            SimpleF4.L("StaffOnline"),
            function() return F.GetOnlineStaff() end,
            function() return SimpleF4.L("VisibleStaffMembers") end
        })
    end

    if D.ShowWallet ~= false then
        table.insert(cards, {
            SimpleF4.L("YourWallet"),
            function() return F.FormatMoney(F.GetMoney(LocalPlayer())) end,
            function() return F.GetJobName(LocalPlayer()) end
        })
    end


    table.insert(cards, {
        SimpleF4.L("ServerUptime"),
        function() return formatUptime(CurTime()) end,
        function() return SimpleF4.L("SinceServerStarted") end
    })

    table.insert(cards, {
        SimpleF4.L("YourPing"),
        function()
            return SimpleF4.L("PingMilliseconds", {
                ping = IsValid(LocalPlayer()) and LocalPlayer():Ping() or 0,
            })
        end,
        function()
            local ping = IsValid(LocalPlayer()) and LocalPlayer():Ping() or 0
            local quality = pingQuality(ping)
            return quality
                .. " • "
                .. SimpleF4.L("PlayersOnlineCount", {
                    count = player.GetCount(),
                })
        end
    })

    if #cards > 0 then
        self.Top = vgui.Create("DIconLayout", self)
        self.Top:Dock(TOP)
        self.Top:SetTall(S(140))
        self.Top:SetSpaceX(S(10))
        self.Top:SetSpaceY(S(10))

        for _, data in ipairs(cards) do
            local card = statCard(
                self.Top,
                data[1],
                data[2],
                data[3]
            )

            local hasAnnouncements =
                #F.GetVisibleAnnouncements(
                    LocalPlayer(),
                    false
                ) > 0

            card:SetSize(
                hasAnnouncements and S(205) or S(220),
                S(120)
            )
            self.Top:Add(card)
        end


        local announcements = C.Announcements or {}
        local visibleAnnouncements =
            F.GetVisibleAnnouncements(
                LocalPlayer(),
                false
            )

        if announcements.Enabled == true
        and #visibleAnnouncements > 0 then
            local panel = vgui.Create("DButton", self.Top)
            panel:SetSize(S(350), S(120))
            panel:SetText("")
            panel:SetCursor("hand")
            self.Top:Add(panel)

            panel.Paint = function(button, w, h)
                local rotate =
                    math.max(
                        1,
                        tonumber(
                            announcements.RotateSeconds
                        ) or 8
                    )

                local index =
                    (
                        math.floor(CurTime() / rotate)
                        % #visibleAnnouncements
                    ) + 1

                local item =
                    visibleAnnouncements[index] or {}

                local accent =
                    item.Color or C.Theme.Accent

                surface.SetDrawColor(
                    button:IsHovered()
                    and C.Theme.SurfaceHover
                    or C.Theme.Surface
                )
                surface.DrawRect(0, 0, w, h)

                surface.SetDrawColor(accent)
                surface.DrawRect(0, 0, S(4), h)

                if item.Badge and item.Badge ~= "" then
                    local unreadCount =
                        SimpleF4.GetUnreadAnnouncementCount(false)

                    local badgeLabel =
                        tostring(item.Badge)

                    if unreadCount > 0 then
                        badgeLabel =
                            badgeLabel
                            .. "  •  "
                            .. tostring(unreadCount)
                            .. " NEW"
                    end

                    text(
                        badgeLabel,
                        "SimpleF4.Small",
                        S(18),
                        S(14),
                        accent
                    )
                end

                text(
                    tostring(
                        item.Title or "Announcement"
                    ),
                    "SimpleF4.BodyBold",
                    S(18),
                    S(38),
                    C.Theme.Text
                )

                text(
                    F.CleanText(
                        tostring(item.Text or ""),
                        88
                    ),
                    "SimpleF4.Small",
                    S(18),
                    S(72),
                    C.Theme.Muted
                )
            end

            panel.DoClick = function()
                local rotate =
                    math.max(
                        1,
                        tonumber(
                            announcements.RotateSeconds
                        ) or 8
                    )

                local index =
                    (
                        math.floor(CurTime() / rotate)
                        % #visibleAnnouncements
                    ) + 1

                local item =
                    visibleAnnouncements[index]

                if item then
                    SimpleF4.MarkAnnouncementRead(item)
                end

                if announcements.ShowHistoryOnClick ~= false then
                    SimpleF4.OpenAnnouncementHistory()
                end
            end
        end

        for _, data in ipairs(SimpleF4.GetDashboardCards()) do
            local visible = true
            if isfunction(data.CanSee) then
                local ok, result = pcall(data.CanSee, LocalPlayer())
                visible = ok and result ~= false
            end

            if visible then
                local card = statCard(
                    self.Top,
                    data.Title or data.ID or "Custom",
                    function()
                        if isfunction(data.Value) then
                            local ok, value = pcall(data.Value, LocalPlayer())
                            if ok then return tostring(value or "") end
                        end
                        return tostring(data.Value or "")
                    end,
                    function()
                        if isfunction(data.Subtitle) then
                            local ok, value = pcall(data.Subtitle, LocalPlayer())
                            if ok then return tostring(value or "") end
                        end
                        return tostring(data.Subtitle or "")
                    end
                )
                card:SetSize(S(data.Width or 220), S(120))
                self.Top:Add(card)
            end
        end
    end

    ---------------------------------------------------
    -- SERVER OVERVIEW
    ---------------------------------------------------

    local overviewEnabled =
        D.ShowServerOverview ~= false
        and (
            D.ShowRichestPlayer ~= false
            or D.ShowPoorestPlayer ~= false
            or D.ShowMostKills ~= false
        )

    if overviewEnabled then
        self.SectionTitle = vgui.Create("DPanel", self)
        self.SectionTitle:Dock(TOP)
        self.SectionTitle:SetTall(S(44))

        self.SectionTitle.Paint = function(_, w, h)
            text(
                SimpleF4.L("ServerOverview"),
                "SimpleF4.Heading",
                0,
                h / 2,
                C.Theme.Text,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end

        self.Overview = vgui.Create("DPanel", self)
        self.Overview:Dock(TOP)
        self.Overview:SetTall(S(120))

        self.Overview.Paint = function(_, w, h)
            surface.SetDrawColor(C.Theme.Surface)
            surface.DrawRect(0, 0, w, h)

            local columns = {}

            if D.ShowRichestPlayer ~= false then
                local richestName, richestMoney = F.GetRichestPlayer()

                table.insert(columns, {
                    SimpleF4.L("RichestPlayer"),
                    richestName,
                    F.FormatMoney(richestMoney),
                    C.Theme.Success
                })
            end

            if D.ShowPoorestPlayer ~= false then
                local poorestName, poorestMoney = F.GetPoorestPlayer()

                table.insert(columns, {
                    SimpleF4.L("PoorestPlayer"),
                    poorestName,
                    F.FormatMoney(poorestMoney),
                    C.Theme.Warning
                })
            end

            if D.ShowMostKills ~= false then
                local killsName, kills = F.GetMostKills()

                table.insert(columns, {
                    SimpleF4.L("MostKills"),
                    killsName,
                    kills .. " kills",
                    C.Theme.Accent
                })
            end

            local count = math.max(#columns, 1)
            local colWidth = w / count

            for i, data in ipairs(columns) do
                local center = colWidth * (i - 0.5)

                if i > 1 then
                    surface.SetDrawColor(C.Theme.Line)
                    surface.DrawRect(
                        colWidth * (i - 1),
                        15,
                        1,
                        h - 30
                    )
                end

                text(data[1], "SimpleF4.Small", center, 18, C.Theme.Muted, TEXT_ALIGN_CENTER)
                text(data[2], "SimpleF4.BodyBold", center, 45, C.Theme.Text, TEXT_ALIGN_CENTER)
                text(data[3], "SimpleF4.Small", center, 74, data[4], TEXT_ALIGN_CENTER)
            end
        end
    end


    ---------------------------------------------------
    -- QUICK ACTIONS
    ---------------------------------------------------

    if istable(C.QuickActions) and #C.QuickActions > 0 then
        self.QuickTitle = vgui.Create("DPanel", self)
        self.QuickTitle:Dock(TOP)
        self.QuickTitle:SetTall(S(48))
        self.QuickTitle.Paint = function(_, w, h)
            text(SimpleF4.L("QuickActions"), "SimpleF4.Heading", 0, h / 2, C.Theme.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        self.QuickActions = vgui.Create("DIconLayout", self)
        self.QuickActions:Dock(TOP)
        self.QuickActions:SetTall(S(58))
        self.QuickActions:SetSpaceX(S(8))
        self.QuickActions:SetSpaceY(S(8))

        for _, action in ipairs(C.QuickActions) do
            local btn = self.QuickActions:Add("DButton")
            btn:SetSize(S(180), S(44))
            btn:SetText("")

            btn.Paint = function(button, w, h)
                surface.SetDrawColor(button:IsHovered() and C.Theme.AccentSoft or C.Theme.Surface)
                surface.DrawRect(0, 0, w, h)

                text(
                    action.Name or SimpleF4.L("Action"),
                    "SimpleF4.BodyBold",
                    w / 2,
                    h / 2,
                    C.Theme.Text,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end

            SimpleF4.AttachTooltip(btn, function()
                return tostring(
                    action.Description
                    or action.Prompt
                    or SimpleF4.L("OpenAction", {
                        name = action.Name
                            or SimpleF4.L("ThisAction"),
                    })
                )
            end)

            btn.DoClick = function()
                if action.Input then
                    SimpleF4.OpenQuickAction(action)
                    return
                end

                -- Non-input actions should behave like direct F4 buttons,
                -- but close the F4 menu first.
                SimpleF4.Close()

                timer.Simple(0, function()
                    SimpleF4.ExecuteQuickAction(action, nil)
                end)
            end
        end
    end

    ---------------------------------------------------
    -- STAFF LIST
    ---------------------------------------------------

    if D.ShowStaffList == false then
        return
    end

    self.StaffTitle = vgui.Create("DPanel", self)
    self.StaffTitle:Dock(TOP)
    self.StaffTitle:SetTall(S(52))

    self.StaffTitle.Paint = function(_, w, h)
        text(
            SimpleF4.L("StaffOnline"),
            "SimpleF4.Heading",
            0,
            h / 2 + 4,
            C.Theme.Text,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end

    self.StaffScroll = vgui.Create("DScrollPanel", self)
    SimpleF4.StyleScrollPanel(self.StaffScroll)
    self.StaffScroll:Dock(FILL)

    self.StaffList = vgui.Create("DIconLayout", self.StaffScroll)
    self.StaffList:Dock(TOP)
    self.StaffList:SetSpaceX(S(8))
    self.StaffList:SetSpaceY(S(8))

    for _, ply in ipairs(player.GetAll()) do
        if ply == LocalPlayer()
        and LocalPlayer():IsSuperAdmin()
        and SimpleF4.GetUserSetting("SuperAdminHideSelfFromStaff") then
            continue
        end

        if not F.IsStaffVisible(ply, LocalPlayer()) then
            continue
        end

        local role, roleColour = F.GetStaffRole(ply)

        local btn = self.StaffList:Add("DButton")
        btn:SetSize(S(330), S(76))
        btn:SetText("")

        if D.ShowSteamAvatar ~= false then
            local avatar = vgui.Create("AvatarImage", btn)
            avatar:SetSize(S(48), S(48))
            avatar:SetPos(S(10), S(14))
            avatar:SetPlayer(ply, 64)
            avatar:SetMouseInputEnabled(false)
        end

        btn.Paint = function(button, w, h)
            surface.SetDrawColor(button:IsHovered() and C.Theme.SurfaceHover or C.Theme.Surface)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(roleColour or C.DefaultStaffColour)
            surface.DrawRect(0, 0, S(3), h)

            local left = D.ShowSteamAvatar ~= false and S(70) or S(14)

            -- Staff name
            text(
                IsValid(ply) and ply:Nick() or "Disconnected",
                "SimpleF4.BodyBold",
                left,
                S(8),
                C.Theme.Text
            )

            -- SteamID below the name.
            if IsValid(ply) and D.ShowStaffSteamID ~= false then
                text(
                    ply:SteamID(),
                    "SimpleF4.Small",
                    left,
                    S(30),
                    C.Theme.Muted
                )
            end

            -- Rank below the SteamID.
            text(
                role or ply:GetUserGroup(),
                "SimpleF4.Small",
                left,
                S(51),
                roleColour or C.DefaultStaffColour
            )

            -- Ping stays in the top-right.
            if IsValid(ply) and D.ShowStaffPing ~= false then
                text(
                    ply:Ping() .. " ms",
                    "SimpleF4.Small",
                    w - S(12),
                    S(8),
                    C.Theme.Muted,
                    TEXT_ALIGN_RIGHT
                )
            end
        end

        if D.StaffCardsOpenSteamProfile ~= false then
            btn:SetCursor("hand")
            btn.DoClick = function()
                if IsValid(ply) then
                    gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
                end
            end
        else
            btn:SetCursor("arrow")
        end
    end
end


function PANEL:Think()
    -- Values such as wallet, ping, online players, uptime and overview stats
    -- are resolved during Paint. Mark the panel for repaint while F4 is open
    -- so those values visibly update without reopening the menu.
    self:InvalidateLayout(false)
end

vgui.Register("SimpleF4.Dashboard", PANEL, "Panel")

SimpleF4.RegisterPage("Dashboard", {
    Label = SimpleF4.L("Dashboard"),
    ClassName = "SimpleF4.Dashboard",
    Order = 10,
})
