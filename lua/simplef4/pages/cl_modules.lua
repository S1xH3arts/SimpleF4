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
    elseif state == "disabled" then
        return C.Theme.Muted
    elseif state == "missing_provider"
    or state == "waiting" then
        return C.Theme.Warning
    end

    return C.Theme.Danger
end

local function moduleSections()
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

local function sortedModules()
    local result = {}

    for id, module in pairs(
        SimpleF4.GetModules() or {}
    ) do
        table.insert(result, {
            ID = id,
            Data = module,
        })
    end

    table.sort(result, function(a, b)
        return string.lower(
            tostring(a.Data.Name or a.ID)
        ) < string.lower(
            tostring(b.Data.Name or b.ID)
        )
    end)

    return result
end

function PANEL:Init()
    self:Dock(FILL)
    self.Cards = {}

    self.Top = vgui.Create("DPanel", self)
    self.Top:Dock(TOP)
    self.Top:SetTall(S(88))

    self.Top.Paint = function(_, w, h)
        text(
            SimpleF4.L("Modules"),
            "SimpleF4.Heading",
            0,
            S(10),
            C.Theme.Text
        )

        text(
            SimpleF4.L("ModulesSubtitle"),
            "SimpleF4.Small",
            0,
            S(35),
            C.Theme.Muted
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)
    end

    self.Search = vgui.Create(
        "DTextEntry",
        self.Top
    )
    self.Search:SetPos(0, S(55))
    self.Search:SetSize(S(280), S(26))
    self.Search:SetFont("SimpleF4.Small")
    self.Search:SetTextColor(C.Theme.Text)
    self.Search:SetPlaceholderText(
        SimpleF4.L("SearchModules")
    )
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

        entry:DrawTextEntryText(
            C.Theme.Text,
            C.Theme.Accent,
            C.Theme.Text
        )
    end

    self.Search.OnValueChange = function()
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
        0
    )

    if SimpleF4.StyleScrollBar then
        SimpleF4.StyleScrollBar(
            self.Scroll
        )
    end

    self.Grid = vgui.Create(
        "DIconLayout",
        self.Scroll
    )
    self.Grid:Dock(TOP)
    self.Grid:SetSpaceX(S(10))
    self.Grid:SetSpaceY(S(10))

    self:Build()
end

function PANEL:AddToggle(parent, item)
    local row = vgui.Create(
        "DPanel",
        parent
    )
    row:Dock(TOP)
    row:SetTall(S(46))
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
            S(9),
            S(7),
            C.Theme.Text
        )

        if item.Description then
            text(
                SimpleF4.L(item.Description),
                "SimpleF4.Small",
                S(9),
                S(25),
                C.Theme.Muted
            )
        end
    end

    local button = vgui.Create(
        "DButton",
        row
    )
    button:Dock(RIGHT)
    button:SetWide(S(70))
    button:DockMargin(
        0,
        S(8),
        S(8),
        S(8)
    )
    button:SetText("")

    button.Paint = function(btn, w, h)
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

    button.DoClick = function()
        SimpleF4.SetUserSetting(
            item.Key,
            not SimpleF4.GetUserSetting(
                item.Key
            )
        )
    end
end

function PANEL:AddChoice(parent, item)
    local row = vgui.Create(
        "DPanel",
        parent
    )
    row:Dock(TOP)
    row:SetTall(S(46))
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
            S(9),
            S(7),
            C.Theme.Text
        )

        if item.Description then
            text(
                SimpleF4.L(item.Description),
                "SimpleF4.Small",
                S(9),
                S(25),
                C.Theme.Muted
            )
        end
    end

    local button = vgui.Create(
        "DButton",
        row
    )
    button:Dock(RIGHT)
    button:SetWide(S(130))
    button:DockMargin(
        0,
        S(8),
        S(8),
        S(8)
    )
    button:SetText("")

    button.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(
            0, 0, w, h, 1
        )

        local current = tostring(
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
            valueText = SimpleF4.L(
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
                Text = istable(item.ValueLabels)
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
end

function PANEL:AddModuleCard(section)
    local items = section.Items or {}

    local card = self.Grid:Add("DPanel")
    card:SetSize(
        S(430),
        S(52) + (#items * S(52))
    )
    card.SearchText = string.lower(
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

        text(
            SimpleF4.L(
                section.Label or section.ID
            ),
            "SimpleF4.BodyBold",
            S(12),
            S(10),
            C.Theme.Text
        )

        text(
            SimpleF4.L("PlayerModuleSettings"),
            "SimpleF4.Small",
            w - S(10),
            S(12),
            C.Theme.Muted,
            TEXT_ALIGN_RIGHT
        )
    end

    for _, item in ipairs(items) do
        if item.Type == "choice" then
            self:AddChoice(card, item)
        else
            self:AddToggle(card, item)
        end
    end

    table.insert(self.Cards, card)
end

function PANEL:AddAdminCard()
    if not LocalPlayer():IsSuperAdmin() then
        return
    end

    local card = self.Grid:Add("DPanel")
    card:SetSize(S(430), S(104))
    card.SearchText = "admin test module testing"

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

        text(
            SimpleF4.L("ModuleTesting"),
            "SimpleF4.BodyBold",
            S(12),
            S(10),
            C.Theme.Text
        )

        text(
            SimpleF4.L("SuperAdminOnly"),
            "SimpleF4.Small",
            w-S(10),
            S(12),
            C.Theme.Danger,
            TEXT_ALIGN_RIGHT
        )
    end

    self:AddToggle(card, {
        Key = "SuperAdminModuleTestMode",
        Label = "SuperModuleTestMode",
        Description = "SuperModuleTestModeDesc",
    })

    table.insert(self.Cards, card)
end

function PANEL:AddStatusCard()
    if not LocalPlayer():IsSuperAdmin() then
        return
    end

    local modules = sortedModules()
    local rows = math.ceil(#modules / 2)

    local card = self.Grid:Add("DPanel")
    card:SetSize(
        S(870),
        S(48) + rows * S(56)
    )
    card.SearchText = "module status admin debug"

    card.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(
            0, 0, w, h, 1
        )

        text(
            SimpleF4.L("ModuleStatus"),
            "SimpleF4.BodyBold",
            S(12),
            S(10),
            C.Theme.Text
        )

        text(
            SimpleF4.L("SuperAdminOnly"),
            "SimpleF4.Small",
            w-S(10),
            S(12),
            C.Theme.Danger,
            TEXT_ALIGN_RIGHT
        )
    end

    card.StatusItems = {}

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

            surface.SetDrawColor(
                C.Theme.Surface2
            )
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
                S(8),
                C.Theme.Text
            )

            text(
                statusLabel(state.State),
                "SimpleF4.Small",
                w-S(8),
                S(8),
                colour,
                TEXT_ALIGN_RIGHT
            )

            if state.Reason then
                text(
                    state.Reason,
                    "SimpleF4.Small",
                    S(10),
                    S(28),
                    C.Theme.Muted
                )
            else
                text(
                    "v"
                    .. tostring(
                        panel.Entry.Data.Version
                        or "?"
                    ),
                    "SimpleF4.Small",
                    S(10),
                    S(28),
                    C.Theme.Muted
                )
            end
        end

        table.insert(
            card.StatusItems,
            row
        )
    end

    card.PerformLayout = function(panel, w)
        local gap = S(6)
        local itemW =
            (w-S(20)-gap)/2

        for index, row in ipairs(
            panel.StatusItems
        ) do
            local col = (index-1)%2
            local line =
                math.floor((index-1)/2)

            row:SetPos(
                S(10)
                + col*(itemW+gap),
                S(42)
                + line*S(56)
            )
            row:SetSize(
                itemW,
                S(50)
            )
        end
    end

    table.insert(self.Cards, card)
end

function PANEL:Build()
    self.Grid:Clear()
    self.Cards = {}

    self:AddAdminCard()
    self:AddStatusCard()

    for _, section in ipairs(
        moduleSections()
    ) do
        self:AddModuleCard(section)
    end

    timer.Simple(0, function()
        if not IsValid(self)
        or not IsValid(self.Grid) then
            return
        end

        self.Grid:SizeToChildren(
            false,
            true
        )
    end)
end

function PANEL:ApplySearch()
    local query = string.lower(
        string.Trim(
            self.Search:GetValue() or ""
        )
    )

    for _, card in ipairs(self.Cards) do
        card:SetVisible(
            query == ""
            or string.find(
                card.SearchText or "",
                query,
                1,
                true
            ) ~= nil
        )
    end

    timer.Simple(0, function()
        if not IsValid(self.Grid) then return end
        self.Grid:InvalidateLayout(true)
        self.Grid:SizeToChildren(false, true)
    end)
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
