local C = SimpleF4.Config

local PANEL = {}

local function S(value)
    return SimpleF4.S(value)
end

local function text(value, font, x, y, colour, ax, ay)
    draw.SimpleText(
        tostring(value or ""),
        font,
        x,
        y,
        colour,
        ax or TEXT_ALIGN_LEFT,
        ay or TEXT_ALIGN_TOP
    )
end

local STATUS_LABELS = {
    ready = "ModuleStatusReady",
    disabled = "ModuleStatusDisabled",
    missing = "ModuleStatusMissing",
    missing_dependency = "ModuleStatusMissingDependency",
    blocked_dependency = "ModuleStatusBlockedDependency",
    missing_provider = "ModuleStatusMissingProvider",
    waiting = "ModuleStatusWaiting",
    error = "ModuleStatusError",
}

local function statusLabel(state)
    return SimpleF4.L(
        STATUS_LABELS[state]
        or "ModuleStatusReady"
    )
end

local function statusColour(state)
    if state == "ready" then
        return C.Theme.Success
    end

    if state == "disabled" then
        return C.Theme.Muted
    end

    if state == "missing_provider"
    or state == "waiting" then
        return C.Theme.Warning
    end

    return C.Theme.Danger
end

local function sortedModules()
    local output = {}

    for id, module in pairs(
        SimpleF4.GetModules() or {}
    ) do
        table.insert(output, {
            ID = id,
            Data = module,
        })
    end

    table.sort(output, function(a, b)
        return string.lower(
            tostring(a.Data.Name or a.ID)
        ) < string.lower(
            tostring(b.Data.Name or b.ID)
        )
    end)

    return output
end

local function sortedSections()
    local sections = {}

    hook.Run(
        "SimpleF4_PopulateModuleSettingsSections",
        sections,
        LocalPlayer()
    )

    table.sort(sections, function(a, b)
        local ao = tonumber(a.Order) or 100
        local bo = tonumber(b.Order) or 100

        if ao == bo then
            return tostring(a.ID or "")
                < tostring(b.ID or "")
        end

        return ao < bo
    end)

    return sections
end

function PANEL:Init()
    self:Dock(FILL)
    self.SearchQuery = ""
    self.SettingCards = {}

    self.Header = vgui.Create("DPanel", self)
    self.Header:Dock(TOP)
    self.Header:SetTall(S(92))

    self.Header.Paint = function(_, w, h)
        text(
            SimpleF4.L("Modules"),
            "SimpleF4.Heading",
            0,
            S(12),
            C.Theme.Text
        )

        text(
            SimpleF4.L("ModulesSubtitle"),
            "SimpleF4.Small",
            0,
            S(37),
            C.Theme.Muted
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)
    end

    self.Search = vgui.Create(
        "DTextEntry",
        self.Header
    )
    self.Search:SetPos(0, S(58))
    self.Search:SetSize(S(300), S(27))
    self.Search:SetFont("SimpleF4.Small")
    self.Search:SetTextColor(C.Theme.Text)
    self.Search:SetCursorColor(C.Theme.Text)
    self.Search:SetUpdateOnType(true)

    self.Search.Paint = function(entry, w, h)
        surface.SetDrawColor(C.Theme.Surface2)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(
            entry:HasFocus()
            and C.Theme.Accent
            or C.Theme.Line
        )
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        if entry:GetValue() == ""
        and not entry:HasFocus() then
            text(
                SimpleF4.L("SearchModules"),
                "SimpleF4.Small",
                S(9),
                h / 2,
                C.Theme.Muted,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        else
            entry:DrawTextEntryText(
                C.Theme.Text,
                C.Theme.Accent,
                C.Theme.Text
            )
        end
    end

    self.Search.OnValueChange = function(entry)
        self.SearchQuery =
            string.lower(
                string.Trim(
                    entry:GetValue() or ""
                )
            )

        self:ApplySearch()
    end

    self.Scroll = vgui.Create(
        "DScrollPanel",
        self
    )
    self.Scroll:Dock(FILL)
    self.Scroll:DockMargin(
        0,
        S(12),
        0,
        S(8)
    )

    if SimpleF4.StyleScrollPanel then
        SimpleF4.StyleScrollPanel(
            self.Scroll
        )
    end

    local canvas = self.Scroll:GetCanvas()
    canvas:DockPadding(
        0,
        0,
        S(10),
        S(14)
    )

    self:Build()
end

function PANEL:AddSettingRow(parent, item)
    local row = vgui.Create(
        "DPanel",
        parent
    )

    row:Dock(TOP)
    row:SetTall(S(50))
    row:DockMargin(
        S(10),
        0,
        S(10),
        S(6)
    )

    row.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface2)
        surface.DrawRect(0, 0, w, h)

        text(
            SimpleF4.L(item.Label or item.Key),
            "SimpleF4.Small",
            S(10),
            S(8),
            C.Theme.Text
        )

        if item.Description then
            text(
                SimpleF4.L(item.Description),
                "SimpleF4.Small",
                S(10),
                S(28),
                C.Theme.Muted
            )
        end
    end

    if item.Type == "choice" then
        local button = vgui.Create(
            "DButton",
            row
        )

        button:Dock(RIGHT)
        button:SetWide(S(140))
        button:DockMargin(
            0,
            S(10),
            S(8),
            S(10)
        )
        button:SetText("")

        button.Paint = function(_, w, h)
            surface.SetDrawColor(C.Theme.Background)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(C.Theme.Line)
            surface.DrawOutlinedRect(
                0, 0, w, h, 1
            )

            local current =
                tostring(
                    SimpleF4.GetUserChoice(
                        item.Key,
                        item.Values
                        and item.Values[1]
                        or ""
                    )
                )

            local valueText = current

            if istable(item.ValueLabels)
            and item.ValueLabels[current] then
                valueText =
                    SimpleF4.L(
                        item.ValueLabels[current]
                    )
            end

            text(
                valueText,
                "SimpleF4.Small",
                w / 2,
                h / 2,
                C.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        button.DoClick = function()
            local entries = {}

            for _, value in ipairs(
                item.Values or {}
            ) do
                table.insert(entries, {
                    Text =
                        istable(item.ValueLabels)
                        and item.ValueLabels[value]
                        and SimpleF4.L(
                            item.ValueLabels[value]
                        )
                        or tostring(value),

                    DoClick = function()
                        SimpleF4.SetUserChoice(
                            item.Key,
                            value
                        )
                    end,
                })
            end

            SimpleF4.OpenContextMenu(
                button,
                entries,
                {Width = 170}
            )
        end

        return
    end

    local toggle = vgui.Create(
        "DButton",
        row
    )

    toggle:Dock(RIGHT)
    toggle:SetWide(S(68))
    toggle:DockMargin(
        0,
        S(10),
        S(8),
        S(10)
    )
    toggle:SetText("")

    toggle.Paint = function(_, w, h)
        local active =
            SimpleF4.GetUserSetting(
                item.Key
            )

        surface.SetDrawColor(
            active
            and C.Theme.Accent
            or C.Theme.Background
        )
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(
            0, 0, w, h, 1
        )

        text(
            active
            and SimpleF4.L("On")
            or SimpleF4.L("Off"),
            "SimpleF4.Small",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    toggle.DoClick = function()
        SimpleF4.SetUserSetting(
            item.Key,
            not SimpleF4.GetUserSetting(
                item.Key
            )
        )
    end
end

function PANEL:AddSectionCard(section)
    if section.SuperAdminOnly == true
    and not LocalPlayer():IsSuperAdmin() then
        return
    end

    local items = section.Items or {}
    local card = vgui.Create(
        "DPanel",
        self.Scroll
    )

    card:Dock(TOP)
    card:DockMargin(
        0,
        0,
        0,
        S(10)
    )
    card:SetTall(
        S(52)
        + (#items * S(56))
    )

    -- Reserve the top of the card for its section heading.
    -- Without this, Dock(TOP) setting rows start at y=0 and cover the title.
    card:DockPadding(
        0,
        S(48),
        0,
        0
    )

    card.SearchText =
        string.lower(
            tostring(section.ID or "")
            .. " "
            .. SimpleF4.L(
                section.Label or section.ID
            )
        )

    card.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(
            0, 0, w, h, 1
        )

        surface.SetDrawColor(C.Theme.Accent)
        surface.DrawRect(
            0,
            0,
            S(3),
            h
        )

        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(
            S(3),
            0,
            w-S(3),
            S(42)
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(
            S(3),
            S(41),
            w-S(3),
            1
        )

        text(
            SimpleF4.L(
                section.Label or section.ID
            ),
            "SimpleF4.BodyBold",
            S(12),
            S(11),
            C.Theme.Text
        )

        text(
            SimpleF4.L("PlayerModuleSettings"),
            "SimpleF4.Small",
            w-S(12),
            S(12),
            C.Theme.Muted,
            TEXT_ALIGN_RIGHT
        )
    end

    for _, item in ipairs(items) do
        self:AddSettingRow(
            card,
            item
        )
    end

    table.insert(
        self.SettingCards,
        card
    )
end

function PANEL:AddModuleTesting()
    if not LocalPlayer():IsSuperAdmin() then
        return
    end

    local card = vgui.Create(
        "DPanel",
        self.Scroll
    )

    card:Dock(TOP)
    card:DockMargin(
        0,
        0,
        0,
        S(10)
    )
    card:SetTall(S(108))

    -- Keep the test row below the card heading.
    card:DockPadding(
        0,
        S(48),
        0,
        0
    )

    card.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(
            0, 0, w, h, 1
        )

        surface.SetDrawColor(C.Theme.Danger)
        surface.DrawRect(
            0,
            0,
            S(3),
            h
        )

        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(
            S(3),
            0,
            w-S(3),
            S(42)
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(
            S(3),
            S(41),
            w-S(3),
            1
        )

        text(
            SimpleF4.L("ModuleTesting"),
            "SimpleF4.BodyBold",
            S(12),
            S(11),
            C.Theme.Text
        )

        text(
            SimpleF4.L("SuperAdminOnly"),
            "SimpleF4.Small",
            w-S(12),
            S(12),
            C.Theme.Danger,
            TEXT_ALIGN_RIGHT
        )
    end

    self:AddSettingRow(card, {
        Type = "toggle",
        Key = "SuperAdminModuleTestMode",
        Label = "SuperModuleTestMode",
        Description = "SuperModuleTestModeDesc",
    })
end

function PANEL:AddModuleStatus()
    if not LocalPlayer():IsSuperAdmin() then
        return
    end

    local modules = sortedModules()
    local rows =
        math.ceil(#modules / 2)

    local card = vgui.Create(
        "DPanel",
        self.Scroll
    )

    card:Dock(TOP)
    card:DockMargin(
        0,
        0,
        0,
        S(10)
    )
    card:SetTall(
        S(48)
        + rows*S(56)
    )

    card.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(
            0, 0, w, h, 1
        )

        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(
            0,
            0,
            w,
            S(42)
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(
            0,
            S(41),
            w,
            1
        )

        text(
            SimpleF4.L("ModuleStatus"),
            "SimpleF4.BodyBold",
            S(12),
            S(11),
            C.Theme.Text
        )

        text(
            SimpleF4.L("SuperAdminOnly"),
            "SimpleF4.Small",
            w-S(12),
            S(12),
            C.Theme.Danger,
            TEXT_ALIGN_RIGHT
        )
    end

    card.StatusRows = {}

    for _, entry in ipairs(modules) do
        local row = vgui.Create(
            "DPanel",
            card
        )

        row.Entry = entry

        row.Paint = function(panel, w, h)
            local state =
                SimpleF4.GetModuleStatus(
                    panel.Entry.ID
                )

            local colour =
                statusColour(
                    state.State
                )

            surface.SetDrawColor(C.Theme.Surface2)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(colour)
            surface.DrawRect(
                0,
                0,
                S(3),
                h
            )

            text(
                panel.Entry.Data.Name
                or panel.Entry.ID,
                "SimpleF4.Small",
                S(10),
                S(7),
                C.Theme.Text
            )

            text(
                statusLabel(state.State),
                "SimpleF4.Small",
                w-S(8),
                S(7),
                colour,
                TEXT_ALIGN_RIGHT
            )

            text(
                state.Reason
                or (
                    "v"
                    .. tostring(
                        panel.Entry.Data.Version
                        or "?"
                    )
                ),
                "SimpleF4.Small",
                S(10),
                S(27),
                C.Theme.Muted
            )
        end

        table.insert(
            card.StatusRows,
            row
        )
    end

    card.PerformLayout = function(panel, w)
        local innerX = S(10)
        local topY = S(42)
        local gap = S(6)
        local innerW = w - S(20)

        local columns =
            w >= S(900)
            and 2
            or 1

        local itemW =
            columns == 2
            and math.floor(
                (innerW-gap)/2
            )
            or innerW

        local rowsCount =
            math.ceil(
                #panel.StatusRows
                / columns
            )

        for index, row in ipairs(
            panel.StatusRows
        ) do
            local col =
                (index-1)%columns

            local line =
                math.floor(
                    (index-1)/columns
                )

            row:SetPos(
                innerX
                + col*(itemW+gap),
                topY
                + line*S(54)
            )

            row:SetSize(
                itemW,
                S(48)
            )
        end

        panel:SetTall(
            S(48)
            + rowsCount*S(56)
        )
    end
end

function PANEL:Build()
    self.SettingCards = {}

    self:AddModuleTesting()
    self:AddModuleStatus()

    for _, section in ipairs(
        sortedSections()
    ) do
        self:AddSectionCard(section)
    end

    timer.Simple(0, function()
        if not IsValid(self)
        or not IsValid(self.Scroll) then
            return
        end

        local bar = self.Scroll:GetVBar()

        if IsValid(bar) then
            bar:SetScroll(0)
        end
    end)

end

function PANEL:ApplySearch()
    for _, card in ipairs(
        self.SettingCards
    ) do
        if IsValid(card) then
            card:SetVisible(
                self.SearchQuery == ""
                or string.find(
                    card.SearchText or "",
                    self.SearchQuery,
                    1,
                    true
                ) ~= nil
            )
        end
    end

    if IsValid(self.Scroll) then
        self.Scroll:InvalidateLayout(true)
        self.Scroll:GetCanvas():InvalidateLayout(true)
    end
end

vgui.Register(
    "SimpleF4.Modules",
    PANEL,
    "Panel"
)

SimpleF4.RegisterPage("Modules", {
    Label = SimpleF4.L("Modules"),
    ClassName = "SimpleF4.Modules",
    Order = 80,
})
