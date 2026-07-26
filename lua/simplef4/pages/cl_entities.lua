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

local function drawSearchIcon(x, y, col)
    surface.SetDrawColor(col)
    surface.DrawOutlinedRect(x, y, 11, 11, 1)
    surface.DrawLine(x + 9, y + 10, x + 15, y + 16)
end


local function buildSearchBox(parent, placeholder, onChanged, onCleared)
    local holder = vgui.Create("DPanel", parent)
    holder:Dock(RIGHT)
    holder:SetWide(S(320))
    holder:DockMargin(0, S(10), 0, S(10))
    holder:SetMouseInputEnabled(true)

    holder.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        drawSearchIcon(S(13), S(12), C.Theme.Muted)
    end

    local clearWidth =
        (C.UI and C.UI.ShowSearchClearButton ~= false)
        and S(34)
        or 0

    local entry = vgui.Create("DTextEntry", holder)
    entry:SetPos(S(40), 0)
    entry:SetSize(
        S(320) - S(40) - clearWidth - S(6),
        S(44)
    )
    entry:SetFont("SimpleF4.Body")
    entry:SetTextColor(C.Theme.Text)
    entry:SetCursorColor(C.Theme.Text)
    entry:SetHighlightColor(C.Theme.AccentSoft)
    entry:SetDrawBackground(false)
    entry:SetMouseInputEnabled(true)
    entry:SetKeyboardInputEnabled(true)
    entry:SetTabbingDisabled(false)

    entry.Paint = function(self, w, h)
        if self:GetValue() == "" and not self:HasFocus() then
            text(
                placeholder,
                "SimpleF4.Body",
                0,
                h / 2,
                C.Theme.Muted,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end

        self:DrawTextEntryText(
            C.Theme.Text,
            C.Theme.Accent,
            C.Theme.Text
        )
    end

    -- Force focus when the field is clicked. This avoids other custom
    -- F4 controls swallowing the first mouse press.
    entry.OnMousePressed = function(self, mouseCode)
        if mouseCode == MOUSE_LEFT then
            self:RequestFocus()
            self:SetCaretPos(#self:GetValue())
        end
    end

    entry.OnGetFocus = function(self)
        self:SetKeyboardInputEnabled(true)
    end

    entry.OnChange = function(self)
        if onChanged then
            onChanged(self:GetValue() or "")
        end
    end

    if clearWidth > 0 then
        local clear = vgui.Create("DButton", holder)
        clear:SetPos(S(320) - clearWidth, 0)
        clear:SetSize(clearWidth, S(44))
        clear:SetText("")
        clear:SetCursor("hand")

        clear.Paint = function(btn, w, h)
            if btn:IsHovered() then
                surface.SetDrawColor(C.Theme.SurfaceHover)
                surface.DrawRect(0, 0, w, h)
            end

            text(
                "×",
                "SimpleF4.BodyBold",
                w / 2,
                h / 2,
                btn:IsHovered() and C.Theme.Text or C.Theme.Muted,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        clear.DoClick = function()
            entry:SetText("")
            entry:RequestFocus()

            if onCleared then
                onCleared()
            elseif onChanged then
                onChanged("")
            end
        end
    end

    return holder, entry
end



local function buildClearFiltersButton(parent, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetSize(S(156), S(36))
    btn:SetText("")
    btn:SetCursor("hand")

    btn.Paint = function(button, w, h)
        surface.SetDrawColor(
            button:IsHovered()
            and C.Theme.AccentSoft
            or C.Theme.Accent
        )
        surface.DrawRect(0, 0, w, h)

        text(
            SimpleF4.L("ClearFilters"),
            "SimpleF4.BodyBold",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    btn.DoClick = onClick
    return btn
end


function PANEL:Init()
    self:Dock(FILL)

    self.SearchText = ""
    self.AffordabilityFilter = "All"
    self.SortFilter = "Name"
    self.CollapsedCategories = self.CollapsedCategories or {}

    if SimpleF4.CategoriesStartCollapsed() then
        self.DefaultCollapsed = true
    end

    self.Top = vgui.Create("DPanel", self)
    self.Top:Dock(TOP)
    self.Top:SetTall(S(64))

    self.Top.Paint = function(_, w, h)
        text(SimpleF4.L("Entities"), "SimpleF4.Heading", 0, 14, C.Theme.Text)
        if SimpleF4.ShowPageSubtitles() then
            text(SimpleF4.L("EntitiesPageSubtitle"), "SimpleF4.Small", 0, 39, C.Theme.Muted)
        end

        if SimpleF4.ShowResultCount() then
            text(SimpleF4.L("Results", {count = self.ResultCount or 0}),
                "SimpleF4.Small", w - S(340), S(39), C.Theme.Muted, TEXT_ALIGN_RIGHT)
        end
        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)
    end

    if not C.UI or C.UI.SearchEnabled ~= false then
        self.SearchHolder, self.Search = buildSearchBox(
            self.Top,
            SimpleF4.L("SearchEntities"),
            function(value)
                self.SearchText = string.lower(value or "")
                self:Build()
            end,
            function()
                self.SearchText = ""
                self:Build()
            end
        )
    end

    if not C.Filters or C.Filters.EntitiesAffordableOnly ~= false then
        self.AffordableButton = vgui.Create("DButton", self.Top)
        self.AffordableButton:Dock(RIGHT)
        self.AffordableButton:SetWide(S(155))
        self.AffordableButton:DockMargin(0, S(10), S(8), S(10))
        self.AffordableButton:SetText("")
        self.AffordableButton:SetCursor("hand")

        local affordabilityModes = {
            "All",
            "Affordable",
            "Unaffordable",
        }

        SimpleF4.AttachTooltip(
            self.AffordableButton,
            SimpleF4.L("EntitiesAffordabilityTooltip")
        )

        self.AffordableButton.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and C.Theme.SurfaceHover
                or C.Theme.Surface
            )
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(C.Theme.Line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            text(
                SimpleF4.GetChoiceLabel(self.AffordabilityFilter),
                "SimpleF4.Small",
                w / 2,
                h / 2,
                C.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        self.AffordableButton.DoClick = function()
            SimpleF4.OpenChoiceMenu(
                self.AffordableButton,
                affordabilityModes,
                self.AffordabilityFilter,
                function(value)
                    self.AffordabilityFilter = value
                    self:Build()
                end
            )
        end

        self.SortButton = vgui.Create("DButton", self.Top)
        self.SortButton:Dock(RIGHT)
        self.SortButton:SetWide(S(140))
        self.SortButton:DockMargin(0, S(10), S(8), S(10))
        self.SortButton:SetText("")
        self.SortButton:SetCursor("hand")

        local sortModes = {
            "Name",
            "Price Low",
            "Price High",
        }

        SimpleF4.AttachTooltip(
            self.SortButton,
            SimpleF4.L("EntitiesSortTooltip")
        )

        self.SortButton.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and C.Theme.SurfaceHover
                or C.Theme.Surface
            )
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(C.Theme.Line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            text(
                SimpleF4.GetChoiceLabel(self.SortFilter),
                "SimpleF4.Small",
                w / 2,
                h / 2,
                C.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        self.SortButton.DoClick = function()
            SimpleF4.OpenChoiceMenu(
                self.SortButton,
                sortModes,
                self.SortFilter,
                function(value)
                    self.SortFilter = value
                    self:Build()
                end
            )
        end
    end

    self.Scroll = vgui.Create("DScrollPanel", self)
    SimpleF4.StyleScrollPanel(self.Scroll)
    self.Scroll:Dock(FILL)
    self.Scroll:DockMargin(S(0), S(10), S(0), S(0))

    self:Build()
end

function PANEL:Build()
    local simpleF4BuildStarted = SysTime()

    timer.Simple(0, function()
        if not IsValid(self) then return end

        SimpleF4.RecordPerformance(
            "Entities",
            simpleF4BuildStarted,
            self.ResultCount or 0,
            table.Count(DarkRPEntities or {})
        )
    end)

    self.Scroll:Clear()
    self.ResultCount = 0

    local grouped = {}
    local lockedCategories = {}
    local ply = LocalPlayer()

    for _, ent in pairs(DarkRPEntities or {}) do
        if F.IsEntityHidden(ent, ply) then
            continue
        end

        if not F.EntityAllowed(ent, ply) then continue end

        local displayName = F.GetDisplayName("Entities", ent)
        local haystack = string.lower(
            displayName
            .. " "
            .. (ent.name or "")
            .. " "
            .. (ent.category or "")
            .. " "
            .. F.GetSearchAliases("Entities", ent)
        )

        if self.SearchText ~= ""
        and not string.find(haystack, self.SearchText, 1, true) then
            continue
        end

        local category = ent.category or "Other"

        if F.IsCategoryHidden("Entities", category, ply) then
            continue
        end

        local categoryAllowed, categoryReason =
            F.CategoryAccessState("Entities", category, ply)

        if not categoryAllowed then
            if tostring(C.PermissionDisplay and C.PermissionDisplay.Categories)
                == "locked" then
                lockedCategories[category] =
                    categoryReason or SimpleF4.L("RestrictedCategory")
            end

            continue
        end

        local entityPrice = tonumber(ent.price) or 0
        local affordable = F.GetMoney(ply) >= entityPrice

        if self.AffordabilityFilter == "Affordable"
        and not affordable then
            continue
        elseif self.AffordabilityFilter == "Unaffordable"
        and affordable then
            continue
        end

        grouped[category] = grouped[category] or {}
        self.ResultCount = self.ResultCount + 1
        table.insert(grouped[category], ent)
    end

    local names = {}

    for name in pairs(grouped) do
        table.insert(names, name)
    end

    for name in pairs(lockedCategories) do
        if not table.HasValue(names, name) then
            table.insert(names, name)
        end
    end

    table.sort(names, function(a, b)
        local ao = F.GetCategoryOrder("Entities", a)
        local bo = F.GetCategoryOrder("Entities", b)
        if ao == bo then return a < b end
        return ao < bo
    end)

    if #names == 0 then
        local empty = vgui.Create("DPanel", self.Scroll)
        empty:Dock(TOP)
        empty:SetTall(S(120))

        empty.Paint = function(_, w, h)
            surface.SetDrawColor(C.Theme.Surface)
            surface.DrawRect(0, 0, w, h)

            local fallbackTitle = SimpleF4.L("NoEntitiesFound")
            local fallbackText = SimpleF4.L("TrySearchOrFilters")

            if self.AffordabilityFilter == "Unaffordable"
            and self.SearchText == "" then
                fallbackTitle = SimpleF4.L("NoUnaffordableEntities")
                fallbackText = SimpleF4.L("AllEntitiesAffordable")
            elseif self.AffordabilityFilter == "Affordable"
            and self.SearchText == "" then
                fallbackTitle = SimpleF4.L("NoAffordableEntities")
                fallbackText = SimpleF4.L("NoEntitiesAffordable")
            end

            local title, subtitle = SimpleF4.GetEmptyState(
                "Entities",
                {
                    Search = self.SearchText,
                    Affordability = self.AffordabilityFilter,
                    Sort = self.SortFilter,
                },
                fallbackTitle,
                fallbackText
            )

            text(title, "SimpleF4.BodyBold", S(18), S(30), C.Theme.Text)
            text(subtitle, "SimpleF4.Small", S(18), S(57), C.Theme.Muted)
        end

        local clear = buildClearFiltersButton(empty, function()
            if IsValid(self.Search) then
                self.Search:SetText("")
                self.Search:RequestFocus()
            end

            self.SearchText = ""
            self.AffordabilityFilter = "All"
            self.SortFilter = "Name"
            self:Build()
        end)

        clear:SetPos(S(18), S(78))

        return
    end

    for _, categoryName in ipairs(names) do
        local categoryLockedReason = lockedCategories[categoryName]
        local categoryEntries = grouped[categoryName] or {}

        table.sort(categoryEntries, function(a, b)
            local aio = F.GetItemOrder("Entities", a)
            local bio = F.GetItemOrder("Entities", b)
            if aio ~= bio then return aio < bio end

            local mode = self.SortFilter or "Name"
            local an = string.lower(a.name or "")
            local bn = string.lower(b.name or "")

            if mode == "Price Low" or mode == "Price High" then
                local av = tonumber(a.price) or 0
                local bv = tonumber(b.price) or 0

                if av == bv then
                    return an < bn
                end

                return mode == "Price Low" and av < bv or av > bv
            end

            return an < bn
        end)

        if self.CollapsedCategories[categoryName] == nil and self.DefaultCollapsed then
            self.CollapsedCategories[categoryName] = true
        end

        local collapsed = self.CollapsedCategories[categoryName] == true

        local header = vgui.Create("DButton", self.Scroll)
        header:Dock(TOP)
        local categoryDescription =
            F.GetCategoryDescription("Entities", categoryName)

        header:SetTall(categoryDescription and S(52) or S(40))
        header:DockMargin(S(0), S(4), S(0), S(6))
        header:SetText("")
        header:SetCursor("hand")

        header.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and C.Theme.SurfaceHover
                or C.Theme.Surface2
            )
            surface.DrawRect(0, 0, w, h)

            local categoryColour =
                F.GetCategoryColour(
                    "Entities",
                    categoryName
                ) or C.Theme.Accent

            surface.SetDrawColor(categoryColour)
            surface.DrawRect(0, 0, 3, h)

            text(
                collapsed and ">" or "v",
                "SimpleF4.BodyBold",
                14,
                h / 2,
                C.Theme.Muted,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )

            local categoryX = S(34)
            local iconPath, iconColour, iconSize =
                F.GetCategoryIcon("Entities", categoryName)

            if iconPath and iconPath ~= "" then
                local material = Material(iconPath, "smooth")
                local drawSize = S(iconSize or 16)

                surface.SetDrawColor(iconColour or color_white)
                surface.SetMaterial(material)
                surface.DrawTexturedRect(
                    S(34),
                    h / 2 - drawSize / 2,
                    drawSize,
                    drawSize
                )

                categoryX = S(42) + drawSize
            end

            text(
                F.GetCategoryDisplayName("Entities", categoryName),
                "SimpleF4.BodyBold",
                categoryX,
                categoryDescription and S(15) or h / 2,
                C.Theme.Text,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )

            if categoryDescription then
                text(
                    categoryDescription,
                    "SimpleF4.Small",
                    categoryX,
                    S(31),
                    C.Theme.Muted,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )
            end

            if categoryLockedReason then
                text(
                    SimpleF4.L("LockedCategoryReason", {reason = categoryLockedReason}),
                    "SimpleF4.Small",
                    w - S(14),
                    h / 2,
                    C.Theme.Warning,
                    TEXT_ALIGN_RIGHT,
                    TEXT_ALIGN_CENTER
                )
                return
            end

            if not C.UI or C.UI.ShowCategoryCounts ~= false then
                local availableCount = 0
                local lockedCount = 0

                for _, ent in ipairs(categoryEntries) do
                    local allowed =
                        F.EntityAccessState(
                            ent,
                            LocalPlayer()
                        )

                    if allowed == false then
                        lockedCount = lockedCount + 1
                    else
                        availableCount = availableCount + 1
                    end
                end

                text(
                    SimpleF4.L(
                        "CategoryAvailableLocked",
                        {
                            total = #categoryEntries,
                            available = availableCount,
                            locked = lockedCount,
                        }
                    ),
                    "SimpleF4.Small",
                    w - 14,
                    h / 2,
                    C.Theme.Muted,
                    TEXT_ALIGN_RIGHT,
                    TEXT_ALIGN_CENTER
                )
            end
        end

        if categoryLockedReason then
            SimpleF4.AttachTooltip(header, categoryLockedReason)
        end

        header.DoClick = function()
            if categoryLockedReason then
                SimpleF4.Notify(categoryLockedReason, "warning")
                return
            end

            self.CollapsedCategories[categoryName] =
                not self.CollapsedCategories[categoryName]

            self:Build()
        end

        if not collapsed and not categoryLockedReason then
            for _, ent in ipairs(categoryEntries) do
                self:AddEntityRow(ent)
            end
        end
    end
end



function PANEL:AddEntityRow(ent)
    local compact = SimpleF4.IsCompact()
    local row = vgui.Create("DPanel", self.Scroll)

    row:Dock(TOP)
    row:SetTall(compact and S(80) or S(104))
    row:DockMargin(0, 0, 0, S(6))
    row.HoverAmount = 0
    SimpleF4.AttachDeveloperContext(row, "Entity", ent)
    local rowBadges = F.GetCustomBadges(
        "Entities",
        ent.name,
        ent.cmd,
        ent.ent,
        ent,
        LocalPlayer()
    )
    local badgeTooltips = {}

    for _, badge in ipairs(rowBadges) do
        if badge.Tooltip then
            table.insert(badgeTooltips, tostring(badge.Tooltip))
        end
    end

    if #badgeTooltips > 0 then
        SimpleF4.AttachTooltip(
            row,
            table.concat(badgeTooltips, "\n")
        )
    end

    local unitPrice = tonumber(ent.price) or 0
    local eligible, eligibilityReason, ownedCount, maxCount =
        F.GetPurchaseEligibility("Entities", ent, LocalPlayer())

    row.Paint = function(panel, w, h)
        panel.HoverAmount = Lerp(
            FrameTime() * 12,
            panel.HoverAmount,
            panel:IsHovered() and 1 or 0
        )

        local base = C.Theme.Surface
        local hover = C.Theme.SurfaceHover

        surface.SetDrawColor(
            Lerp(panel.HoverAmount, base.r, hover.r),
            Lerp(panel.HoverAmount, base.g, hover.g),
            Lerp(panel.HoverAmount, base.b, hover.b)
        )

        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)
    end

    local icon = vgui.Create("ModelImage", row)
    icon:SetPos(S(10), compact and S(16) or S(22))
    icon:SetSize(
        compact and S(48) or S(60),
        compact and S(48) or S(60)
    )
    icon:SetModel(ent.model or "models/error.mdl")

    local info = vgui.Create("DPanel", row)
    info:Dock(FILL)
    info:DockMargin(
        compact and S(74) or S(84),
        0,
        S(8),
        0
    )

    info.Paint = function(_, w, h)
        local affordable = F.GetMoney(LocalPlayer()) >= unitPrice
        local showAffordability =
            SimpleF4.GetUserSetting("EntitiesShowAffordability")
            and (not C.Purchases or C.Purchases.ShowAffordability ~= false)

        local priceCol =
            (showAffordability and not affordable)
            and C.Theme.Danger
            or C.Theme.Success

        local cleanName = F.CleanText(F.GetDisplayName("Entities", ent), 72)

        SimpleF4.DrawHighlightedText(
            cleanName,
            self.SearchText,
            "SimpleF4.BodyBold",
            0,
            compact and S(8) or S(12),
            C.Theme.Text,
            C.Theme.Warning
        )

        surface.SetFont("SimpleF4.BodyBold")
        local badgeX = surface.GetTextSize(cleanName) + S(12)

        if F.IsNewEntity(ent) then
            text("NEW", "SimpleF4.Small", badgeX, compact and S(9) or S(13), C.Theme.Warning)
            badgeX = badgeX + S(40)
        end

        for _, badge in ipairs(rowBadges) do
            badgeX = SimpleF4.DrawBadge(
                badge,
                badgeX,
                (compact and S(9) or S(13)) - S(7)
            ) + S(8)

        end

        text(
            F.GetEntityPriceText(ent),
            "SimpleF4.Small",
            0,
            compact and S(31) or S(40),
            priceCol
        )

        local wallet = F.GetMoney(LocalPlayer())

        if not eligible then
            text(
                tostring(eligibilityReason or "Unavailable"),
                "SimpleF4.Small",
                0,
                compact and S(53) or S(64),
                C.Theme.Danger
            )
        elseif SimpleF4.GetUserSetting("EntitiesShowLimits")
        and C.Purchases
        and C.Purchases.ShowPurchaseLimits ~= false
        and maxCount then
            text(
                "Owned: "
                    .. tostring(ownedCount or 0)
                    .. " / "
                    .. tostring(maxCount),
                "SimpleF4.Small",
                0,
                compact and S(53) or S(64),
                (ownedCount or 0) >= maxCount
                    and C.Theme.Danger
                    or C.Theme.Muted
            )
        elseif showAffordability and wallet < unitPrice then
            text(
                SimpleF4.L("NeedMoreMoney", {
                    money = F.FormatMoney(unitPrice - wallet),
                }),
                "SimpleF4.Small",
                0,
                compact and S(53) or S(64),
                C.Theme.Danger
            )
                elseif showAffordability then
            text(
                SimpleF4.L("MoneyAfterPurchase", {
                    money = F.FormatMoney(wallet - unitPrice),
                }),
                "SimpleF4.Small",
                0,
                compact and S(53) or S(64),
                C.Theme.Muted
            )
        end
    end

    local customButtons = SimpleF4.GetEntityButtons(ent)

    if #customButtons > 0 then
        local action = customButtons[1]

        local extra = vgui.Create("DButton", row)
        extra:Dock(RIGHT)
        extra:SetWide(S(130))
        extra:DockMargin(
            0,
            compact and S(18) or S(26),
            S(8),
            compact and S(18) or S(26)
        )
        extra:SetText("")

        extra.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and C.Theme.SurfaceHover
                or C.Theme.Surface2
            )
            surface.DrawRect(0, 0, w, h)

            text(
                action.Text or "ACTION",
                "SimpleF4.Small",
                w / 2,
                h / 2,
                action.Color or C.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        if action.Tooltip then
            SimpleF4.AttachTooltip(extra, action.Tooltip)
        end

        extra.DoClick = function()
            if isfunction(action.DoClick) then
                action.DoClick(LocalPlayer(), ent)
            end
        end
    end

    local buy = vgui.Create("DButton", row)
    buy:Dock(RIGHT)
    buy:SetWide(S(158))
    buy:DockMargin(
        0,
        compact and S(18) or S(26),
        S(14),
        compact and S(18) or S(26)
    )
    buy:SetText("")
    SimpleF4.AttachDeveloperContext(buy, "Entity", ent)

    buy.Paint = function(btn, w, h)
        local affordable = F.GetMoney(LocalPlayer()) >= unitPrice
        local canPurchase =
            F.GetPurchaseEligibility("Entities", ent, LocalPlayer())
        local cooldown = SimpleF4.GetPurchaseCooldown(
            "Entities",
            ent.cmd or ent.name
        )

        local label = SimpleF4.L("Buy")
        local col =
            btn:IsHovered()
            and C.Theme.AccentSoft
            or C.Theme.Accent

        if not canPurchase then
            label = SimpleF4.L("Locked")
            col = C.Theme.Danger
        elseif cooldown > 0 then
            label = SimpleF4.L("WaitShort", {
                seconds = string.format("%.1f", cooldown),
            })
            col = C.Theme.Warning
        elseif SimpleF4.GetUserSetting("EntitiesShowAffordability")
        and C.Purchases
        and C.Purchases.ShowAffordability ~= false
        and not affordable then
            label = SimpleF4.L("CantAfford")
            col = C.Theme.Danger
        end

        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)

        text(
            label,
            "SimpleF4.Small",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    local function performPurchase()
        hook.Run("SimpleF4_BeforeEntityPurchase", ent, LocalPlayer())
        RunConsoleCommand("darkrp", ent.cmd)
        hook.Run("SimpleF4_EntityPurchased", ent, LocalPlayer())

        local cooldownSeconds =
            C.Purchases
            and C.Purchases.Cooldown
            and C.Purchases.Cooldown.Entities
            or 0

        SimpleF4.StartPurchaseCooldown(
            "Entities",
            ent.cmd or ent.name,
            cooldownSeconds
        )

        SimpleF4.Notify(
            SimpleF4.L("PurchasedItem", {
                name = tostring(
                    ent.name or SimpleF4.L("EntityFallbackName")
                ),
            }),
            "success"
        )

        if C.CloseOnPurchase ~= false then
            SimpleF4.Close()
        end
    end

    SimpleF4.AttachTooltip(buy, function()
        local wallet = F.GetMoney(LocalPlayer())
        local needed = math.max(0, unitPrice - wallet)
        local canPurchase, reason, current, limit =
            F.GetPurchaseEligibility("Entities", ent, LocalPlayer())

        if not canPurchase then
            local output = F.GetDisplayName("Entities", ent)
                .. "\n"
                .. tostring(reason or SimpleF4.L("Unavailable"))

            if limit then
                output = output
                    .. "\n"
                    .. SimpleF4.L("OwnedInline", {
                        current = current or 0,
                        maximum = limit,
                    })
            end

            return output
        end

        if needed > 0 then
            return F.GetDisplayName("Entities", ent)
                .. "\n"
                .. SimpleF4.L("PriceInline", {
                    price = F.FormatMoney(unitPrice),
                })
                .. "\n"
                .. SimpleF4.L("NeedMoreInline", {
                    money = F.FormatMoney(needed),
                })
        end

        return F.GetDisplayName("Entities", ent)
            .. "\n"
            .. SimpleF4.L("PriceInline", {
                price = F.FormatMoney(unitPrice),
            })
            .. "\n"
            .. SimpleF4.L("MoneyAfterInline", {
                money = F.FormatMoney(wallet - unitPrice),
            })
    end)

    buy.DoClick = function()
        local canPurchase, reason =
            F.GetPurchaseEligibility("Entities", ent, LocalPlayer())

        if not canPurchase then
            SimpleF4.Notify(
                reason or SimpleF4.L("EntityUnavailable"),
                "error"
            )
            return
        end

        local cooldown = SimpleF4.GetPurchaseCooldown(
            "Entities",
            ent.cmd or ent.name
        )

        if cooldown > 0 then
            SimpleF4.Notify(
                SimpleF4.L("PleaseWaitSeconds", {
                    seconds = string.format("%.1f", cooldown),
                }),
                "warning"
            )
            return
        end

        if not ent.cmd then
            SimpleF4.Notify(SimpleF4.L("InvalidEntityCommand"), "error")
            return
        end

        if C.Purchases
        and C.Purchases.ShowAffordability ~= false
        and F.GetMoney(LocalPlayer()) < unitPrice then
            SimpleF4.Notify(SimpleF4.L("CannotAffordPurchase"), "error")
            return
        end

        if C.Purchases
        and C.Purchases.Confirm
        and C.Purchases.Confirm.Entities ~= false
        and unitPrice >= (C.Purchases.ConfirmAbovePrice or 10000) then
            Derma_Query(
                SimpleF4.L("BuyFor", {
                    name = tostring(
                        ent.name or SimpleF4.L("EntityFallbackName")
                    ),
                    price = F.FormatMoney(unitPrice),
                }),
                SimpleF4.L("ConfirmPurchase"),
                SimpleF4.L("PurchaseAction"),
                performPurchase,
                SimpleF4.L("Cancel")
            )

            return
        end

        performPurchase()
    end
end

vgui.Register("SimpleF4.Entities", PANEL, "Panel")

SimpleF4.RegisterPage("Entities", {
    Label = SimpleF4.L("Entities"),
    ClassName = "SimpleF4.Entities",
    Order = 30,
})
