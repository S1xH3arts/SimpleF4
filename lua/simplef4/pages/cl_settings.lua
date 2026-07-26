local PANEL = {}

local C = SimpleF4.Config

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

local SECTIONS = {
    {
        ID = "Appearance",
        Order = 10,
        Label = "SettingsAppearance",
        Items = {
            {Type = "theme"},
            {
                Type = "language",
                Key = "Language",
                Label = "Language",
                Description = "LanguageDesc",
            },
            {
                Type = "choice",
                Key = "Density",
                Label = "SettingDensity",
                Description = "SettingDensityDesc",
                Values = {"Comfortable", "Compact"},
            },
            {
                Type = "toggle",
                Key = "ReduceMotion",
                Label = "SettingReduceMotion",
                Description = "SettingReduceMotionDesc",
            },
            {
                Type = "toggle",
                Key = "DisableBlur",
                Label = "SettingDisableBlur",
                Description = "SettingDisableBlurDesc",
            },
            {
                Type = "toggle",
                Key = "Tooltips",
                Label = "SettingTooltips",
                Description = "SettingTooltipsDesc",
            },
        },
    },
    {
        ID = "General",
        Order = 20,
        Label = "SettingsGeneral",
        Items = {
            {
                Type = "toggle",
                Key = "RememberLastPage",
                Label = "SettingRememberLastPage",
                Description = "SettingRememberLastPageDesc",
            },
            {
                Type = "toggle",
                Key = "CollapseCategories",
                Label = "SettingCollapseCategories",
                Description = "SettingCollapseCategoriesDesc",
            },
            {
                Type = "toggle",
                Key = "ShowResultCount",
                Label = "SettingShowResultCount",
                Description = "SettingShowResultCountDesc",
            },
            {
                Type = "toggle",
                Key = "ShowPageSubtitles",
                Label = "SettingShowPageSubtitles",
                Description = "SettingShowPageSubtitlesDesc",
            },
        },
    },
    {
        ID = "Jobs",
        Order = 30,
        Label = "SettingsJobs",
        Items = {
            {
                Type = "toggle",
                Key = "JobsShowDescriptions",
                Label = "SettingJobsShowDescriptions",
                Description = "SettingJobsShowDescriptionsDesc",
            },
            {
                Type = "toggle",
                Key = "JobsShowLocked",
                Label = "SettingJobsShowLocked",
                Description = "SettingJobsShowLockedDesc",
            },
            {
                Type = "toggle",
                Key = "JobsQuickJoin",
                Label = "SettingJobsQuickJoin",
                Description = "SettingJobsQuickJoinDesc",
            },
            {
                Type = "toggle",
                Key = "JobsQuickJoinConfirmVote",
                Label = "SettingJobsQuickJoinConfirmVote",
                Description = "SettingJobsQuickJoinConfirmVoteDesc",
            },
        },
    },
    {
        ID = "Entities",
        Order = 40,
        Label = "SettingsEntities",
        Items = {
            {
                Type = "toggle",
                Key = "EntitiesShowLimits",
                Label = "SettingEntitiesShowLimits",
                Description = "SettingEntitiesShowLimitsDesc",
            },
            {
                Type = "toggle",
                Key = "EntitiesShowAffordability",
                Label = "SettingEntitiesShowAffordability",
                Description = "SettingEntitiesShowAffordabilityDesc",
            },
        },
    },
    {
        ID = "Weapons",
        Order = 50,
        Label = "SettingsWeapons",
        Items = {
            {
                Type = "toggle",
                Key = "WeaponsShowLimits",
                Label = "SettingWeaponsShowLimits",
                Description = "SettingWeaponsShowLimitsDesc",
            },
            {
                Type = "toggle",
                Key = "WeaponsShowAffordability",
                Label = "SettingWeaponsShowAffordability",
                Description = "SettingWeaponsShowAffordabilityDesc",
            },
        },
    },
    {
        ID = "SuperAdmin",
        Order = 90,
        Label = "SettingsSuperAdmin",
        SuperAdminOnly = true,
        Items = {
            {
                Type = "toggle",
                Key = "SuperAdminShowHiddenStuff",
                Label = "SuperShowHidden",
                Description = "SuperShowHiddenDesc",
            },
            {
                Type = "toggle",
                Key = "SuperAdminBypassChecks",
                Label = "SuperBypassChecks",
                Description = "SuperBypassChecksDesc",
            },
            {
                Type = "toggle",
                Key = "SuperAdminHideSelfFromStaff",
                Label = "SuperHideStaff",
                Description = "SuperHideStaffDesc",
            },
            {
                Type = "toggle",
                Key = "SuperAdminDeveloperTools",
                Label = "SuperDeveloper",
                Description = "SuperDeveloperDesc",
            },
            {
                Type = "preview",
                Key = "SuperAdminPermissionPreview",
                Label = "SuperPermissionPreview",
                Description = "SuperPermissionPreviewDesc",
            },
        },
    },
}

function PANEL:Init()
    self:Dock(FILL)
    self.SearchText = ""
    self.SearchRows = {}

    self.Top = vgui.Create("DPanel", self)
    self.Top:Dock(TOP)
    self.Top:SetTall(S(64))

    self.Top.Paint = function(_, w, h)
        text(
            SimpleF4.L("Settings"),
            "SimpleF4.Heading",
            0,
            S(14),
            C.Theme.Text
        )

        text(
            SimpleF4.L("SettingsSubtitle"),
            "SimpleF4.Small",
            0,
            S(39),
            C.Theme.Muted
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)
    end

    self.Search = vgui.Create("DTextEntry", self.Top)
    self.Search:Dock(RIGHT)
    self.Search:SetWide(S(310))
    self.Search:DockMargin(0, S(10), 0, S(10))
    self.Search:SetFont("SimpleF4.Small")
    self.Search:SetText("")
    self.Search:SetPlaceholderText(SimpleF4.L("SettingsSearch"))
    self.Search:SetUpdateOnType(true)

    self.Search.Paint = function(entry, w, h)
        surface.SetDrawColor(C.Theme.Surface)
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

    self.Search.OnValueChange = function(_, value)
        self.SearchText = string.lower(value or "")
        self:ApplySearch()
    end

    self.Scroll = vgui.Create("DScrollPanel", self)
    SimpleF4.StyleScrollPanel(self.Scroll)
    self.Scroll:Dock(FILL)
    self.Scroll:DockMargin(0, S(12), 0, 0)

    self:BuildSettings()
end

function PANEL:AddSection(titleKey)
    local header = vgui.Create("DPanel", self.Scroll)
    header:Dock(TOP)
    header:SetTall(S(34))
    header:DockMargin(0, S(6), 0, S(4))

    header.Paint = function(_, w, h)
        text(
            SimpleF4.L(titleKey),
            "SimpleF4.BodyBold",
            S(4),
            h / 2,
            C.Theme.Accent,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(S(125), h / 2, w - S(125), 1)
    end

    return header
end

function PANEL:AddToggle(item)
    local row = self:CreateBaseRow(item)

    local toggle = vgui.Create("DButton", row)
    toggle:Dock(RIGHT)
    toggle:SetWide(S(100))
    toggle:DockMargin(0, S(16), S(14), S(16))
    toggle:SetText("")
    toggle:SetCursor("hand")

    toggle.Paint = function(btn, w, h)
        local enabled = SimpleF4.GetUserSetting(item.Key)

        surface.SetDrawColor(
            enabled
            and C.Theme.Accent
            or (btn:IsHovered() and C.Theme.SurfaceHover or C.Theme.Surface2)
        )
        surface.DrawRect(0, 0, w, h)

        text(
            enabled and SimpleF4.L("Enabled") or SimpleF4.L("Disabled"),
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
            not SimpleF4.GetUserSetting(item.Key)
        )
    end

    return row
end


function PANEL:AddLanguage(item)
    local row = self:CreateBaseRow(item)

    local choose = vgui.Create("DButton", row)
    choose:Dock(RIGHT)
    choose:SetWide(S(180))
    choose:DockMargin(0,S(16),S(14),S(16))
    choose:SetText("")
    choose:SetCursor("hand")

    choose.Paint = function(btn,w,h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface2
        )
        surface.DrawRect(0,0,w,h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(0,0,w,h,1)

        text(
            SimpleF4.GetLanguageLabel(
                SimpleF4.GetLanguage()
            ),
            "SimpleF4.Small",
            w/2,h/2,C.Theme.Text,
            TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER
        )
    end

    choose.DoClick = function()
        local items = {}

        for _, code in ipairs(
            SimpleF4.GetLanguageChoices()
        ) do
            table.insert(items, {
                Text = SimpleF4.GetLanguageLabel(code),
                Selected = code == SimpleF4.GetLanguage(),
                DoClick = function()
                    SimpleF4.SetLanguage(code)
                end,
            })
        end

        SimpleF4.OpenContextMenu(
            choose,
            items,
            {Width = 220}
        )
    end

    return row
end

function PANEL:AddChoice(item)
    local row = self:CreateBaseRow(item)

    local choose = vgui.Create("DButton", row)
    choose:Dock(RIGHT)
    choose:SetWide(S(150))
    choose:DockMargin(0, S(16), S(14), S(16))
    choose:SetText("")
    choose:SetCursor("hand")

    choose.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface2
        )
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        local value = tostring(
            SimpleF4.GetUserChoice(item.Key, item.Values[1])
        )

        local displayValue = value
        if istable(item.ValueLabels)
        and item.ValueLabels[value] then
            displayValue = SimpleF4.L(item.ValueLabels[value])
        end

        text(
            displayValue,
            "SimpleF4.Small",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    choose.DoClick = function()
        local current = SimpleF4.GetUserChoice(
            item.Key,
            item.Values[1]
        )

        if istable(item.ValueLabels) then
            local menuItems = {}

            for _, value in ipairs(item.Values) do
                table.insert(menuItems, {
                    Text = SimpleF4.L(
                        item.ValueLabels[value] or tostring(value)
                    ),
                    Selected = value == current,
                    DoClick = function()
                        SimpleF4.SetUserChoice(item.Key, value)
                    end,
                })
            end

            SimpleF4.OpenContextMenu(
                choose,
                menuItems,
                {Width = 180}
            )
        else
            SimpleF4.OpenChoiceMenu(
                choose,
                item.Values,
                current,
                function(value)
                    SimpleF4.SetUserChoice(item.Key, value)
                end,
                {Width = 180}
            )
        end
    end

    return row
end

function PANEL:AddThemeSetting()
    local item = {
        Label = "SettingTheme",
        Description = "SettingThemeDesc",
    }

    local row = self:CreateBaseRow(item)

    local reset = vgui.Create("DButton", row)
    reset:Dock(RIGHT)
    reset:SetWide(S(150))
    reset:DockMargin(S(6), S(16), S(14), S(16))
    reset:SetText("")
    reset:SetCursor("hand")

    reset.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface2
        )
        surface.DrawRect(0, 0, w, h)

        text(
            SimpleF4.L("UseServerTheme"),
            "SimpleF4.Small",
            w / 2,
            h / 2,
            C.Theme.Muted,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    reset.DoClick = function()
        SimpleF4.ResetThemePreset()
    end

    local choose = vgui.Create("DButton", row)
    choose:Dock(RIGHT)
    choose:SetWide(S(145))
    choose:DockMargin(0, S(16), 0, S(16))
    choose:SetText("")
    choose:SetCursor("hand")

    choose.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface2
        )
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        surface.SetDrawColor(C.Theme.Accent)
        surface.DrawRect(0, 0, S(4), h)
        surface.DrawRect(S(14), h / 2 - S(5), S(10), S(10))

        text(
            SimpleF4.GetThemePreset(),
            "SimpleF4.Small",
            S(34),
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end

    choose.DoClick = function()
        local menuItems = {}
        local current = SimpleF4.GetThemePreset()

        for _, name in ipairs(SimpleF4.GetThemePresetNames()) do
            local preset = C.ThemePresets and C.ThemePresets[name]

            table.insert(menuItems, {
                Text = name,
                Selected = name == current,
                SampleColor = preset and preset.Accent or C.Theme.Accent,
                DoClick = function()
                    SimpleF4.ApplyThemePreset(name, true)
                end,
            })
        end

        SimpleF4.OpenContextMenu(choose, menuItems, {Width = 180})
    end

    return row
end


function PANEL:AddPermissionPreview(item)
    local row = self:CreateBaseRow(item)
    row:SetTall(S(112))

    local toggle = vgui.Create("DButton", row)
    toggle:SetSize(S(82), S(30))
    toggle:SetText("")

    toggle.Paint = function(btn, w, h)
        local enabled =
            SimpleF4.GetUserSetting(
                "SuperAdminPermissionPreview"
            )

        surface.SetDrawColor(
            enabled
            and C.Theme.Warning
            or (
                btn:IsHovered()
                and C.Theme.SurfaceHover
                or C.Theme.Surface2
            )
        )
        surface.DrawRect(0, 0, w, h)

        text(
            enabled and "ON" or "OFF",
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
            "SuperAdminPermissionPreview",
            not SimpleF4.GetUserSetting(
                "SuperAdminPermissionPreview"
            )
        )

        SimpleF4.RefreshPermissionPreview()
    end

    local teamInput = vgui.Create("DTextEntry", row)
    teamInput:SetSize(S(120), S(28))
    teamInput:SetFont("SimpleF4.Small")
    teamInput:SetText(tostring(
        SimpleF4.GetUserChoice(
            "SuperAdminPreviewTeamID",
            "-1"
        )
    ))
    teamInput:SetPlaceholderText(
        SimpleF4.L("SuperPreviewTeam")
    )

    teamInput.Paint = function(entry, w, h)
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

    local function saveTeam()
        local teamID = tonumber(teamInput:GetValue()) or -1
        SimpleF4.SetUserChoice(
            "SuperAdminPreviewTeamID",
            tostring(teamID)
        )

        if SimpleF4.GetUserSetting(
            "SuperAdminPermissionPreview"
        ) then
            SimpleF4.RefreshPermissionPreview()
        end
    end

    teamInput.OnEnter = saveTeam
    teamInput.OnLoseFocus = saveTeam

    local groupInput = vgui.Create("DTextEntry", row)
    groupInput:SetSize(S(130), S(28))
    groupInput:SetFont("SimpleF4.Small")
    groupInput:SetText(tostring(
        SimpleF4.GetUserChoice(
            "SuperAdminPreviewUserGroup",
            "user"
        )
    ))
    groupInput:SetPlaceholderText(
        SimpleF4.L("SuperPreviewGroup")
    )

    groupInput.Paint = function(entry, w, h)
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

    local function saveGroup()
        SimpleF4.SetUserChoice(
            "SuperAdminPreviewUserGroup",
            string.Trim(groupInput:GetValue() or "user")
        )

        if SimpleF4.GetUserSetting(
            "SuperAdminPermissionPreview"
        ) then
            SimpleF4.RefreshPermissionPreview()
        end
    end

    groupInput.OnEnter = saveGroup
    groupInput.OnLoseFocus = saveGroup

    row.PerformLayout = function(_, w, h)
        toggle:SetPos(w - S(96), S(10))
        teamInput:SetPos(w - S(270), S(64))
        groupInput:SetPos(w - S(140), S(64))
    end

    return row
end

function PANEL:CreateBaseRow(item)
    local row = vgui.Create("DPanel", self.Scroll)
    row:Dock(TOP)
    row:SetTall(S(72))
    row:DockMargin(0, 0, 0, S(6))

    row.SimpleF4SearchText = string.lower(
        SimpleF4.L(item.Label or "")
        .. " "
        .. SimpleF4.L(item.Description or "")
    )

    row.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        text(
            SimpleF4.L(item.Label),
            "SimpleF4.BodyBold",
            S(14),
            S(14),
            C.Theme.Text
        )

        text(
            SimpleF4.L(item.Description),
            "SimpleF4.Small",
            S(14),
            S(42),
            C.Theme.Muted
        )
    end

    table.insert(self.SearchRows, row)
    return row
end

function PANEL:BuildSettings()
    local ply = LocalPlayer()
    local isSuperAdmin = IsValid(ply) and ply:IsSuperAdmin()

    local sections = table.Copy(SECTIONS)

    hook.Run(
        "SimpleF4_PopulateSettingsSections",
        sections,
        ply
    )

    table.sort(sections, function(a, b)
        local ao = tonumber(a.Order) or 100
        local bo = tonumber(b.Order) or 100

        if ao == bo then
            return tostring(a.ID or "") < tostring(b.ID or "")
        end

        return ao < bo
    end)

    for _, section in ipairs(sections) do
        -- Never create the Superadmin header or its rows for anybody else.
        -- Because they are not created at all, Dock layout has no empty gap.
        if section.SuperAdminOnly and not isSuperAdmin then
            continue
        end

        local header = self:AddSection(section.Label)
        local sectionRows = {}

        for _, item in ipairs(section.Items) do
            local row

            if item.Type == "toggle" then
                row = self:AddToggle(item)
            elseif item.Type == "choice" then
                row = self:AddChoice(item)
            elseif item.Type == "theme" then
                row = self:AddThemeSetting()
            elseif item.Type == "preview" then
                row = self:AddPermissionPreview(item)
            elseif item.Type == "language" then
                if C.AllowPlayerLanguageSelection ~= false then
                    row = self:AddLanguage(item)
                end
            end

            if IsValid(row) then
                table.insert(sectionRows, row)
            end
        end

        header.SimpleF4SectionRows = sectionRows
        table.insert(self.SearchRows, header)
    end

    if isSuperAdmin then
        local maintenance = vgui.Create("DButton", self.Scroll)
        maintenance:Dock(TOP)
        maintenance:SetTall(S(42))
        maintenance:DockMargin(0, S(8), 0, 0)
        maintenance:SetText("")
        maintenance:SetCursor("hand")

        maintenance.Paint = function(btn, w, h)
            local active = GetGlobalBool(
                "SimpleF4.Maintenance",
                C.Maintenance
                    and C.Maintenance.Enabled == true
                    or false
            )

            surface.SetDrawColor(
                active
                and C.Theme.Warning
                or (
                    btn:IsHovered()
                    and C.Theme.SurfaceHover
                    or C.Theme.Surface
                )
            )
            surface.DrawRect(0, 0, w, h)

            text(
                SimpleF4.L("SuperMaintenance")
                    .. " • "
                    .. (
                        active
                        and SimpleF4.L("On")
                        or SimpleF4.L("Off")
                    ),
                "SimpleF4.BodyBold",
                w / 2,
                h / 2,
                C.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        maintenance.DoClick = function()
            RunConsoleCommand("simplef4_maintenance_toggle")

            timer.Simple(0.15, function()
                if IsValid(self) then
                    RunConsoleCommand("simplef4_reload")
                end
            end)
        end
    end

    if isSuperAdmin then
        local inspector = vgui.Create("DButton", self.Scroll)
        inspector:Dock(TOP)
        inspector:SetTall(S(42))
        inspector:DockMargin(0, S(8), 0, 0)
        inspector:SetText("")
        inspector:SetCursor("hand")

        inspector.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and C.Theme.SurfaceHover
                or C.Theme.Surface
            )
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(C.Theme.Line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            text(
                SimpleF4.L("SuperConfigInspector"),
                "SimpleF4.BodyBold",
                w / 2,
                h / 2,
                C.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        inspector.DoClick = function()
            SimpleF4.OpenConfigInspector("General", nil, nil)
        end
    end

    if isSuperAdmin then
        local refresh = vgui.Create("DButton", self.Scroll)
        refresh:Dock(TOP)
        refresh:SetTall(S(42))
        refresh:DockMargin(0, S(8), 0, 0)
        refresh:SetText("")

        refresh.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and C.Theme.AccentSoft
                or C.Theme.Accent
            )
            surface.DrawRect(0, 0, w, h)

            text(
                SimpleF4.L("SuperRefreshAll"),
                "SimpleF4.BodyBold",
                w / 2,
                h / 2,
                C.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        refresh.DoClick = function()
            RunConsoleCommand("simplef4_reload")
        end
    end

    local reset = vgui.Create("DButton", self.Scroll)
    reset:Dock(TOP)
    reset:SetTall(S(42))
    reset:DockMargin(0, S(8), 0, S(8))
    reset:SetText("")
    reset:SetCursor("hand")

    reset.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface
        )
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        text(
            SimpleF4.L("ResetSettings"),
            "SimpleF4.BodyBold",
            S(14),
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end

    reset.DoClick = function()
        SimpleF4.ResetUserSettings()
        SimpleF4.ResetThemePreset()

        timer.Simple(0, function()
            if IsValid(SimpleF4.Frame) then
                SimpleF4.Close(true)
                timer.Simple(0, SimpleF4.Open)
            end
        end)
    end

    self.ResetButton = reset

    timer.Simple(0, function()
        if not IsValid(self) or not IsValid(self.Scroll) then return end

        self.Scroll:InvalidateLayout(true)

        local canvas = self.Scroll:GetCanvas()
        if IsValid(canvas) then
            canvas:InvalidateLayout(true)
            canvas:SizeToChildren(false, true)
        end
    end)
end

function PANEL:ApplySearch()
    local query = self.SearchText or ""

    for _, panel in ipairs(self.SearchRows) do
        if not IsValid(panel) then continue end

        if panel.SimpleF4SectionRows then
            local anyVisible = false

            for _, row in ipairs(panel.SimpleF4SectionRows) do
                if IsValid(row) and row:IsVisible() then
                    anyVisible = true
                    break
                end
            end

            panel:SetVisible(anyVisible or query == "")
        else
            local haystack = panel.SimpleF4SearchText or ""
            panel:SetVisible(
                query == ""
                or string.find(haystack, query, 1, true) ~= nil
            )
        end
    end

    timer.Simple(0, function()
        if not IsValid(self) or not IsValid(self.Scroll) then return end

        self.Scroll:InvalidateLayout(true)

        local canvas = self.Scroll:GetCanvas()
        if IsValid(canvas) then
            canvas:InvalidateLayout(true)
            canvas:SizeToChildren(false, true)
        end
    end)
end

vgui.Register("SimpleF4.Settings", PANEL, "Panel")

SimpleF4.RegisterPage("Settings", {
    Label = SimpleF4.L("Settings"),
    ClassName = "SimpleF4.Settings",
    Order = 90,
})
