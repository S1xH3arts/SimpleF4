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

function PANEL:Init()
    local wantedW = math.floor(ScrW() * C.Width)
    local wantedH = math.floor(ScrH() * C.Height)

    self:SetSize(
        math.max(C.MinWidth, math.min(wantedW, ScrW() - 40)),
        math.max(C.MinHeight, math.min(wantedH, ScrH() - 40))
    )

    self:Center()

    if not SimpleF4.ReduceMotion() then
        local targetX, targetY = self:GetPos()

        self:SetAlpha(0)
        self:SetPos(targetX, targetY + S(22))
        self:SetWide(math.max(S(40), self:GetWide() - S(18)))
        self:Center()

        local startX, startY = self:GetPos()

        self:AlphaTo(255, 0.18, 0)
        self:SizeTo(
            self:GetWide() + S(18),
            self:GetTall(),
            0.18,
            0,
            0.2
        )
        self:MoveTo(targetX, targetY, 0.18, 0, 0.2)
    else
        self:SetAlpha(255)
    end

    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)
    self.StartTime = SysTime()

    self.ActivePage = nil
    self.PageButtons = {}

    ---------------------------------------------------
    -- HEADER
    ---------------------------------------------------

    self.Header = vgui.Create("DPanel", self)
    self.Header:Dock(TOP)
    self.Header:SetTall(S(82))

    self.Header.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Header)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Accent)
        surface.DrawRect(0, h - S(3), w, S(3))

        text(C.ServerName, "SimpleF4.Title", S(22), S(15), C.Theme.Text)
        text(C.Subtitle, "SimpleF4.Small", S(22), S(46), C.Theme.Muted)
    end

    self.CloseButton = vgui.Create("DButton", self.Header)
    self.CloseButton:Dock(RIGHT)
    self.CloseButton:SetWide(S(64))
    self.CloseButton:DockMargin(0, S(14), S(14), S(14))
    self.CloseButton:SetText("")

    self.CloseButton.Paint = function(btn, w, h)
        surface.SetDrawColor(btn:IsHovered() and C.Theme.Danger or C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)
        text("×", "SimpleF4.Title", w / 2, h / 2 - 1, C.Theme.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.CloseButton.DoClick = function()
        SimpleF4.Close()
    end

    self.PlayerInfo = vgui.Create("DPanel", self.Header)
    self.PlayerInfo:Dock(RIGHT)
    self.PlayerInfo:SetWide(S(280))
    self.PlayerInfo:DockMargin(0, S(10), S(10), S(10))
    self.PlayerInfo.Paint = function(_, w, h)
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        text(
            SimpleF4.L("WelcomeBack", {name = ply:Nick()}),
            "SimpleF4.BodyBold",
            w - S(14),
            S(8),
            C.Theme.Text,
            TEXT_ALIGN_RIGHT
        )

        local lineY = S(30)

        if C.ShowHeaderJob then
            text(
                F.GetJobName(ply),
                "SimpleF4.Small",
                w - S(14),
                lineY,
                C.Theme.Muted,
                TEXT_ALIGN_RIGHT
            )
            lineY = lineY + S(19)
        end

        if C.ShowHeaderMoney then
            text(
                F.FormatMoney(F.GetMoney(ply)),
                "SimpleF4.Small",
                w - S(14),
                lineY,
                C.Theme.Success,
                TEXT_ALIGN_RIGHT
            )
        end
    end

    ---------------------------------------------------
    -- HORIZONTAL NAV
    ---------------------------------------------------

    self.Nav = vgui.Create("DPanel", self)
    self.Nav:Dock(TOP)
    self.Nav:SetTall(S(60))

    self.Nav.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)
    end

    self.NavMore = vgui.Create("DPanel", self.Nav)
    self.NavMore:Dock(RIGHT)
    self.NavMore:SetWide(S(118))
    self.NavMore.Paint = nil

    self.NavLeft = vgui.Create("DPanel", self.Nav)
    self.NavLeft:Dock(FILL)
    self.NavLeft.Paint = nil

    ---------------------------------------------------
    -- CONTENT
    ---------------------------------------------------

    self.Content = vgui.Create("DPanel", self)
    self.Content:Dock(FILL)
    self.Content:DockPadding(S(18), S(18), S(18), S(18))

    self.Content.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(0, 0, w, h)
    end


    -- Public-release credit. Intentionally kept out of the config file.
    self.Credit = vgui.Create("DLabel", self)
    self.Credit:SetFont("SimpleF4.Small")
    self.Credit:SetTextColor(C.Theme.Muted)
    self.Credit:SetText("Simple F4 ©2026")
    self.Credit:SizeToContents()
    self.Credit:SetMouseInputEnabled(false)

    for _, pageData in ipairs(SimpleF4.GetPages()) do
        local enabled = true

        pageData.SimpleF4Locked = nil
        pageData.SimpleF4LockReason = nil

        if C.Pages and C.Pages[pageData.ID] == false then
            enabled = false
        end

        local pageAllowed, pageReason =
            F.PageAccessState(pageData.ID, LocalPlayer())

        local maintenanceBlocked =
            F.IsMaintenanceBlocked(LocalPlayer())

        if maintenanceBlocked
        and pageData.ID ~= "Dashboard"
        and pageData.ID ~= "Settings" then
            enabled = false
        elseif enabled and not pageAllowed then
            if tostring(C.PermissionDisplay and C.PermissionDisplay.Pages)
                ~= "locked" then
                enabled = false
            else
                pageData.SimpleF4Locked = true
                pageData.SimpleF4LockReason = pageReason
            end
        end

        if pageData.ID == "Settings"
        and C.PlayerSettings
        and C.PlayerSettings.Enabled == false then
            enabled = false
        end

        if enabled then
            self:AddPageButton(
                F.GetPageDisplayName(pageData.ID, pageData.Label),
                pageData.ClassName,
                pageData
            )
        end
    end


    if not F.IsMaintenanceBlocked(LocalPlayer()) then
        self:AddMoreMenu()
    end

    local defaultPage =
        SimpleF4.GetLastPage()
        or C.DefaultPage
        or "Dashboard"

    if not self.PageButtons[defaultPage]
    or (
        self.PageButtons[defaultPage].Data
        and self.PageButtons[defaultPage].Data.SimpleF4Locked
    ) then
        for name, pageInfo in pairs(self.PageButtons) do
            if not (
                pageInfo.Data
                and pageInfo.Data.SimpleF4Locked
            ) then
                defaultPage = name
                break
            end
        end
    end

    self:OpenPage(defaultPage)
end

function PANEL:AddPageButton(label, className, pageData)
    local pageID = pageData and pageData.ID or label
    local btn = vgui.Create("DButton", self.NavLeft)
    btn:Dock(LEFT)
    btn:SetWide(S(122))
    btn:SetText("")

    btn.Paint = function(button, w, h)
        local active = self.ActivePage == pageID
        local hovered = button:IsHovered()
        local locked = pageData and pageData.SimpleF4Locked

        if active or hovered then
            surface.SetDrawColor(active and C.Theme.Surface2 or C.Theme.SurfaceHover)
            surface.DrawRect(0, 0, w, h)
        end

        if active then
            surface.SetDrawColor(C.Theme.Accent)
            surface.DrawRect(S(18), h - S(4), w - S(36), S(4))
        end

        text(
            locked and (label .. " " .. SimpleF4.L("LockedSuffix")) or label,
            "SimpleF4.BodyBold",
            w / 2,
            h / 2,
            locked and C.Theme.Warning
                or (active and C.Theme.Text or C.Theme.Muted),
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    btn.DoClick = function()
        if pageData and pageData.SimpleF4Locked then
            SimpleF4.Notify(
                pageData.SimpleF4LockReason or SimpleF4.L("RestrictedPage"),
                "warning"
            )
            return
        end

        self:OpenPage(pageID, className)
    end

    if pageData and pageData.SimpleF4Locked then
        SimpleF4.AttachTooltip(
            btn,
            pageData.SimpleF4LockReason or SimpleF4.L("RestrictedPage")
        )
    end

    self.PageButtons[pageID] = {
        Button = btn,
        ClassName = className,
        Data = pageData,
    }
end

function PANEL:AddMoreMenu()
    local config = C.MoreMenu or {}

    if config.Enabled == false then return end
    if not IsValid(self.NavMore) then return end

    local items = {}

    local function addBuiltIn(name, url, order)
        if not url or tostring(url) == "" then return end

        table.insert(items, {
            Name = name,
            Type = "url",
            Value = tostring(url),
            Order = order,
        })
    end

    addBuiltIn(SimpleF4.L("Website"), C.WebsiteURL, 10)
    addBuiltIn(SimpleF4.L("Discord"), C.DiscordURL, 20)
    addBuiltIn(SimpleF4.L("Donate"), C.DonateURL, 30)
    addBuiltIn(SimpleF4.L("Rules"), C.RulesURL, 40)

    for _, data in ipairs(C.NavButtons or {}) do
        if SimpleF4.NavItemAllowed(data, LocalPlayer()) then
            table.insert(items, table.Copy(data))
        end
    end

    if C.NavDropdown
    and C.NavDropdown.Enabled == true
    and istable(C.NavDropdown.Items) then
        for _, data in ipairs(C.NavDropdown.Items) do
            if SimpleF4.NavItemAllowed(data, LocalPlayer()) then
                table.insert(items, table.Copy(data))
            end
        end
    end

    if #items == 0 then
        self.NavMore:SetWide(0)
        return
    end

    table.sort(items, function(a, b)
        local ao = tonumber(a.Order) or 100
        local bo = tonumber(b.Order) or 100

        if ao == bo then
            return tostring(a.Name or "") < tostring(b.Name or "")
        end

        return ao < bo
    end)

    local btn = vgui.Create("DButton", self.NavMore)
    btn:Dock(FILL)
    btn:DockMargin(S(6), 0, 0, 0)
    btn:SetText("")
    btn:SetCursor("hand")

    btn.Paint = function(button, w, h)
        if button:IsHovered() then
            surface.SetDrawColor(C.Theme.SurfaceHover)
            surface.DrawRect(0, 0, w, h)
        end

        text(
            tostring(config.Name or SimpleF4.L("More")),
            "SimpleF4.BodyBold",
            w / 2 - S(7),
            h / 2,
            button:IsHovered() and C.Theme.Text or C.Theme.Muted,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )

        text(
            "▼",
            "SimpleF4.Small",
            w - S(17),
            h / 2,
            button:IsHovered() and C.Theme.Accent or C.Theme.Muted,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    btn.DoClick = function()
        if IsValid(SimpleF4.ContextMenu)
        and SimpleF4.ContextMenu.SimpleF4Owner == btn then
            SimpleF4.CloseContextMenu()
            return
        end

        local menuItems = {}

        for _, item in ipairs(items) do
            table.insert(menuItems, {
                Text = tostring(item.Name or "Link"),
                Disabled = item.Disabled == true,

                DoClick = function()
                    SimpleF4.ExecuteLinkAction(item)
                end,
            })
        end

        SimpleF4.OpenContextMenu(
            btn,
            menuItems,
            {
                Width = tonumber(config.Width) or 250,
            }
        )

        if IsValid(SimpleF4.ContextMenu) then
            SimpleF4.ContextMenu.SimpleF4Owner = btn
        end
    end
end


function PANEL:AddLinkButton(label, url)
    if not url or url == "" then return end

    local btn = vgui.Create("DButton", self.NavMore)
    btn:Dock(RIGHT)
    btn:SetWide(S(105))
    btn:SetText("")

    btn.Paint = function(button, w, h)
        if button:IsHovered() then
            surface.SetDrawColor(C.Theme.SurfaceHover)
            surface.DrawRect(0, 0, w, h)
        end

        text(label, "SimpleF4.Small", w / 2, h / 2, button:IsHovered() and C.Theme.Text or C.Theme.Muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.DoClick = function()
        gui.OpenURL(url)
    end
end


function PANEL:AddCustomNavButton(data)
    if not istable(data) then return end
    if not SimpleF4.NavItemAllowed(data, LocalPlayer()) then return end

    local btn = vgui.Create("DButton", self.NavMore)
    btn:Dock(LEFT)
    btn:SetWide(S(105))
    btn:SetText("")
    btn:SetCursor("hand")

    btn.Paint = function(button, w, h)
        text(
            data.Name or "Link",
            "SimpleF4.Small",
            w / 2,
            h / 2,
            button:IsHovered()
                and C.Theme.Text
                or C.Theme.Muted,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    btn.DoClick = function()
        local actionType = string.lower(data.Type or "url")
        local value = tostring(data.Value or "")

        SimpleF4.DebugPrint(
            "Navbar action:",
            data.Name or "Unnamed",
            "type=" .. actionType,
            "value=" .. value
        )

        if actionType == "url" then
            gui.OpenURL(value)
            return
        end

        if actionType == "chat" then
            SimpleF4.Close()
            timer.Simple(0, function()
                RunConsoleCommand("say", value)
            end)
            return
        end

        if actionType == "command" and value ~= "" then
            SimpleF4.Close()
            timer.Simple(0, function()
                LocalPlayer():ConCommand(value)
            end)
        end
    end
end


function PANEL:AddNavDropdown(data)
    if not istable(data) or data.Enabled ~= true then return end
    if not istable(data.Items) or #data.Items == 0 then return end

    local visibleItems = {}

    for _, item in ipairs(data.Items) do
        if SimpleF4.NavItemAllowed(item, LocalPlayer()) then
            table.insert(visibleItems, item)
        end
    end

    if #visibleItems == 0 then return end

    local btn = vgui.Create("DButton", self.NavMore)
    btn:Dock(LEFT)
    btn:SetWide(S(105))
    btn:SetText("")
    btn:SetCursor("hand")

    btn.Paint = function(button, w, h)
        text(
            data.Name or SimpleF4.L("More"),
            "SimpleF4.Small",
            w / 2,
            h / 2,
            button:IsHovered() and C.Theme.Text or C.Theme.Muted,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    btn.DoClick = function()
        local menuItems = {}

        for _, item in ipairs(visibleItems) do
            table.insert(menuItems, {
                Text = item.Name or "Link",

                DoClick = function()
                    local actionType = string.lower(item.Type or "url")
                    local value = tostring(item.Value or "")

                    if actionType == "url" then
                        gui.OpenURL(value)
                    elseif actionType == "chat" then
                        SimpleF4.Close()
                        timer.Simple(0, function()
                            RunConsoleCommand("say", value)
                        end)
                    elseif actionType == "command" and value ~= "" then
                        SimpleF4.Close()
                        timer.Simple(0, function()
                            LocalPlayer():ConCommand(value)
                        end)
                    end
                end,
            })
        end

        SimpleF4.OpenContextMenu(btn, menuItems, {
            Width = 220,
        })
    end
end

function PANEL:OpenPage(pageID, className)
    SimpleF4.DebugPrint("Opening page:", pageID)
    local info = self.PageButtons[pageID]

    if info
    and info.Data
    and info.Data.SimpleF4Locked then
        SimpleF4.Notify(
            info.Data.SimpleF4LockReason or SimpleF4.L("RestrictedPage"),
            "warning"
        )
        return
    end
    className = className or (info and info.ClassName)

    if not info then return end

    self.ActivePage = pageID
    SimpleF4.SetLastPage(pageID)
    hook.Run("SimpleF4_PageOpened", pageID, info)

    local oldPanel = self.CurrentPanel
    local newPanel

    if className and className ~= "" then
        newPanel = vgui.Create(className, self.Content)
    elseif info.Data and isfunction(info.Data.Build) then
        newPanel = vgui.Create("DPanel", self.Content)
        newPanel.Paint = nil
        info.Data.Build(newPanel, self)
    end

    if not IsValid(newPanel) then return end

    newPanel:Dock(FILL)
    if SimpleF4.ReduceMotion() then
        newPanel:SetAlpha(255)
    else
        newPanel:SetAlpha(0)
        newPanel:AlphaTo(255, 0.14, 0)
    end

    self.CurrentPanel = newPanel

    if IsValid(oldPanel) then
        oldPanel:SetMouseInputEnabled(false)

        if SimpleF4.ReduceMotion() then
            oldPanel:Remove()
        else
            oldPanel:AlphaTo(0, 0.10, 0, function()
                if IsValid(oldPanel) then
                    oldPanel:Remove()
                end
            end)
        end
    end
end

function PANEL:OnKeyCodePressed(key)
    if key == KEY_F4 then
        SimpleF4.Close()
    end
end


function PANEL:Think()
    -- "/" focuses the search field on pages that have one.
    local slashDown = input.IsKeyDown(KEY_SLASH)

    if slashDown and not self.SimpleF4SlashWasDown then
        local page = self.CurrentPanel
        local search = IsValid(page) and page.Search or nil

        if IsValid(search) then
            timer.Simple(0, function()
                if IsValid(search) then
                    search:RequestFocus()
                    search:SetCaretPos(#search:GetValue())
                end
            end)
        end
    end

    self.SimpleF4SlashWasDown = slashDown

    -- ESC opens Garry's Mod's pause menu. Detect that engine UI state and
    -- immediately remove SimpleF4. We do not suppress the pause menu itself.
    if gui.IsGameUIVisible and gui.IsGameUIVisible() then
        SimpleF4.Close()
        return
    end
end

function PANEL:PerformLayout(w, h)
    if IsValid(self.Credit) then
        self.Credit:SetPos(S(12), h - self.Credit:GetTall() - S(8))
    end
end

function PANEL:Paint(w, h)
    if SimpleF4.BlurEnabled() then
        Derma_DrawBackgroundBlur(self, self.StartTime)
    end

    surface.SetDrawColor(C.Theme.Background)
    surface.DrawRect(0, 0, w, h)
end



vgui.Register("SimpleF4.Main", PANEL, "EditablePanel")
