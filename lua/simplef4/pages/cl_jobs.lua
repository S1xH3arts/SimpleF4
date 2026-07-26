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

local function getModels(model)
    if istable(model) then
        return model
    end

    return {model or "models/error.mdl"}
end

local function getJobState(teamID)
    local job = RPExtraTeams and RPExtraTeams[teamID]
    local maxPlayers = tonumber(job and job.max) or 0
    local currentPlayers = team.NumPlayers(teamID)
    local current = IsValid(LocalPlayer()) and LocalPlayer():Team() == teamID
    local full = maxPlayers > 0 and currentPlayers >= maxPlayers

    return currentPlayers, maxPlayers, current, full
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
    self.StatusFilter = "All"
    self.SortFilter = "Name"
    self.CollapsedCategories = self.CollapsedCategories or {}

    if SimpleF4.CategoriesStartCollapsed() then
        self.DefaultCollapsed = true
    end

    ---------------------------------------------------
    -- PAGE HEADER
    ---------------------------------------------------

    self.Top = vgui.Create("DPanel", self)
    self.Top:Dock(TOP)
    self.Top:SetTall(S(64))

    self.Top.Paint = function(_, w, h)
        text(SimpleF4.L("Jobs"), "SimpleF4.Heading", 0, 14, C.Theme.Text)

        if SimpleF4.ShowPageSubtitles() then
            text(SimpleF4.L("ChooseRoleSubtitle"), "SimpleF4.Small", 0, 39, C.Theme.Muted)
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
            SimpleF4.L("SearchJobs"),
            function(value)
                self.SearchText = string.lower(value or "")
                self:BuildList()
            end,
            function()
                self.SearchText = ""
                self:BuildList()
            end
        )
    end

    if not C.Filters or C.Filters.Jobs ~= false then
        self.FilterButton = vgui.Create("DButton", self.Top)
        self.FilterButton:Dock(RIGHT)
        self.FilterButton:SetWide(S(145))
        self.FilterButton:DockMargin(0, S(10), S(8), S(10))
        self.FilterButton:SetText("")
        SimpleF4.AttachTooltip(
            self.FilterButton,
            SimpleF4.L("JobsFilterTooltip")
        )

        local modes = {
            "All",
            "Available",
            "Locked",
            "Full",
            "Current",
            "Occupied",
            "Empty",
            "Vote",
            "No Vote",
        }

        self.FilterButton.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and C.Theme.SurfaceHover
                or C.Theme.Surface
            )
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(C.Theme.Line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            text(
                SimpleF4.GetChoiceLabel(self.StatusFilter),
                "SimpleF4.Small",
                w / 2,
                h / 2,
                C.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        self.FilterButton.DoClick = function()
            SimpleF4.OpenChoiceMenu(
                self.FilterButton,
                modes,
                self.StatusFilter,
                function(value)
                    self.StatusFilter = value
                    self:BuildList()
                end
            )
        end

        self.SortButton = vgui.Create("DButton", self.Top)
        self.SortButton:Dock(RIGHT)
        self.SortButton:SetWide(S(145))
        self.SortButton:DockMargin(0, S(10), S(8), S(10))
        self.SortButton:SetText("")
        self.SortButton:SetCursor("hand")

        local sortModes = {
            "Name",
            "Salary High",
            "Salary Low",
            "Players High",
            "Players Low",
        }

        SimpleF4.AttachTooltip(
            self.SortButton,
            SimpleF4.L("JobsSortTooltip")
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
                    self:BuildList()
                end
            )
        end
    end

    ---------------------------------------------------
    -- JOB LIST
    ---------------------------------------------------

    self.Scroll = vgui.Create("DScrollPanel", self)
    SimpleF4.StyleScrollPanel(self.Scroll)
    self.Scroll:Dock(FILL)
    self.Scroll:DockMargin(S(0), S(10), S(0), S(0))

    self:BuildList()
end

function PANEL:BuildList()
    local simpleF4BuildStarted = SysTime()

    timer.Simple(0, function()
        if not IsValid(self) then return end

        SimpleF4.RecordPerformance(
            "Jobs",
            simpleF4BuildStarted,
            self.ResultCount or 0,
            table.Count(RPExtraTeams or {})
        )
    end)

    self.Scroll:Clear()
    self.ResultCount = 0

    local grouped = {}
    local lockedCategories = {}
    local ply = LocalPlayer()

    for teamID, job in pairs(RPExtraTeams or {}) do
        if not job then continue end

        if F.IsJobHidden(teamID, job, ply) then
            continue
        end

        local visible, allowed = F.JobAccessState(job, teamID, ply)
        if not visible then continue end

        if allowed == false and (
            (C.Jobs and C.Jobs.HideLockedJobs)
            or not SimpleF4.GetUserSetting("JobsShowLocked")
        ) then
            continue
        end

        local displayName = F.GetDisplayName("Jobs", job, teamID)
        local haystack = string.lower(
            displayName
            .. " "
            .. (job.name or "")
            .. " "
            .. (job.category or "")
            .. " "
            .. (job.description or "")
            .. " "
            .. F.GetSearchAliases("Jobs", job, teamID)
        )

        if self.SearchText ~= ""
        and not string.find(haystack, self.SearchText, 1, true) then
            continue
        end

        local category = job.category or "Other"

        if F.IsCategoryHidden("Jobs", category, ply) then
            continue
        end

        local categoryAllowed, categoryReason =
            F.CategoryAccessState("Jobs", category, ply)

        if not categoryAllowed then
            if tostring(C.PermissionDisplay and C.PermissionDisplay.Categories)
                == "locked" then
                lockedCategories[category] =
                    categoryReason or SimpleF4.L("RestrictedCategory")
            end

            continue
        end

        local _, maxPlayers, current, full = getJobState(teamID)

        if self.StatusFilter == "Available"
        and (allowed == false or full or current) then
            continue
        elseif self.StatusFilter == "Locked"
        and allowed ~= false then
            continue
        elseif self.StatusFilter == "Full"
        and not full then
            continue
        elseif self.StatusFilter == "Current"
        and not current then
            continue
        elseif self.StatusFilter == "Occupied"
        and team.NumPlayers(teamID) <= 0 then
            continue
        elseif self.StatusFilter == "Empty"
        and team.NumPlayers(teamID) > 0 then
            continue
        elseif self.StatusFilter == "Vote"
        and not job.vote then
            continue
        elseif self.StatusFilter == "No Vote"
        and job.vote then
            continue
        end

        grouped[category] = grouped[category] or {}
        self.ResultCount = self.ResultCount + 1

        table.insert(grouped[category], {
            teamID = teamID,
            job = job,
            locked = allowed == false,
        })
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
        local ao = F.GetCategoryOrder("Jobs", a)
        local bo = F.GetCategoryOrder("Jobs", b)
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

            text(
                "No jobs found",
                "SimpleF4.BodyBold",
                18,
                30,
                C.Theme.Text
            )

            text(
                "Try another search or clear the current filters.",
                "SimpleF4.Small",
                18,
                57,
                C.Theme.Muted
            )
        end

        local clear = vgui.Create("DButton", empty)
        clear:SetPos(S(18), S(78))
        clear:SetSize(S(150), S(30))
        clear:SetText(SimpleF4.L("ClearFilters"))
        clear.DoClick = function()
            if IsValid(self.Search) then
                self.Search:SetText("")
                self.Search:RequestFocus()
            end
            self.SearchText = ""
            self.StatusFilter = "All"
            self.SortFilter = "Name"
            self:BuildList()
        end

        return
    end

    for _, categoryName in ipairs(names) do
        local categoryLockedReason = lockedCategories[categoryName]
        local categoryEntries = grouped[categoryName] or {}

        if self.CollapsedCategories[categoryName] == nil and self.DefaultCollapsed then
            self.CollapsedCategories[categoryName] = true
        end

        local collapsed = self.CollapsedCategories[categoryName] == true

        local header = vgui.Create("DButton", self.Scroll)

        header:Dock(TOP)
        local categoryDescription =
            F.GetCategoryDescription("Jobs", categoryName)

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
                    "Jobs",
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
                F.GetCategoryIcon("Jobs", categoryName)

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
                F.GetCategoryDisplayName("Jobs", categoryName),
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
                local categoryPlayers = 0

                for _, entry in ipairs(categoryEntries) do
                    categoryPlayers =
                        categoryPlayers
                        + team.NumPlayers(entry.teamID)
                end

                local availableCount = 0
                local lockedCount = 0

                for _, entry in ipairs(categoryEntries) do
                    local _, allowed =
                        F.JobAccessState(
                            entry.job,
                            entry.teamID,
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
                        "JobsAvailableLocked",
                        {
                            total = #categoryEntries,
                            players = categoryPlayers,
                            available = availableCount,
                            locked = lockedCount,
                        }
                    ),
                    "SimpleF4.Small",
                    w - S(14),
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

            self:BuildList()
        end

        if not collapsed and not categoryLockedReason then
            table.sort(categoryEntries, function(a, b)
                local aio = F.GetItemOrder("Jobs", a.job, a.teamID)
                local bio = F.GetItemOrder("Jobs", b.job, b.teamID)

                if aio ~= bio then
                    return aio < bio
                end

                local mode = self.SortFilter or "Name"
                local an = string.lower(
                    F.GetDisplayName("Jobs", a.job, a.teamID)
                )
                local bn = string.lower(
                    F.GetDisplayName("Jobs", b.job, b.teamID)
                )

                local function tieBreak()
                    if an ~= bn then
                        return an < bn
                    end

                    return (tonumber(a.teamID) or 0)
                        < (tonumber(b.teamID) or 0)
                end

                if mode == "Salary High" or mode == "Salary Low" then
                    local av = tonumber(a.job.salary) or 0
                    local bv = tonumber(b.job.salary) or 0

                    if av ~= bv then
                        if mode == "Salary High" then
                            return av > bv
                        end

                        return av < bv
                    end

                    return tieBreak()
                end

                if mode == "Players High" or mode == "Players Low" then
                    local av = team.NumPlayers(a.teamID)
                    local bv = team.NumPlayers(b.teamID)

                    if av ~= bv then
                        if mode == "Players High" then
                            return av > bv
                        end

                        return av < bv
                    end

                    return tieBreak()
                end

                return tieBreak()
            end)

            for _, entry in ipairs(categoryEntries) do
                self:AddJobRow(entry.teamID, entry.job, entry.locked)
            end
        end
    end
end

function PANEL:AttemptBecomeJob(teamID, job, preferredModel)
    local _, _, current, full = getJobState(teamID)
    local _, allowed, reason =
        F.JobAccessState(job, teamID, LocalPlayer())

    -- Quick Job never bypasses the normal SimpleF4 access checks.
    if allowed == false then
        SimpleF4.Notify(
            reason or "You do not meet this job's requirements.",
            "warning"
        )
        return false
    end

    if current then
        return false
    end

    if full then
        SimpleF4.Notify(SimpleF4.L("JobCurrentlyFull"), "warning")
        return false
    end

    if DarkRP
    and DarkRP.setPreferredJobModel
    and isstring(preferredModel)
    and preferredModel ~= "" then
        DarkRP.setPreferredJobModel(teamID, preferredModel)
    end

    hook.Run(
        "SimpleF4_BeforeJobSelected",
        teamID,
        job,
        LocalPlayer()
    )

    if job.vote then
        RunConsoleCommand(
            "darkrp",
            "vote" .. tostring(job.command or "")
        )
    else
        RunConsoleCommand(
            "darkrp",
            tostring(job.command or "")
        )
    end

    hook.Run(
        "SimpleF4_JobSelected",
        teamID,
        job,
        LocalPlayer()
    )

    SimpleF4.Close()
    return true
end

function PANEL:AddJobRow(teamID, job, locked)
    local compact = SimpleF4.IsCompact()
    local row = vgui.Create("DPanel", self.Scroll)

    row:Dock(TOP)
    row:SetTall(compact and S(76) or S(94))
    row:DockMargin(S(0), S(0), S(0), S(6))

    local teamColor =
        job.color
        or team.GetColor(teamID)
        or C.Theme.Accent

    row.HoverAmount = 0
    SimpleF4.AttachDeveloperContext(row, "Job", job, teamID)
    local rowBadges = F.GetCustomBadges(
        "Jobs",
        teamID,
        job.name,
        job.command,
        job,
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

        surface.SetDrawColor(teamColor)
        surface.DrawRect(0, 0, 3, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)
    end

    ---------------------------------------------------
    -- PORTRAIT
    ---------------------------------------------------

    local previewWrap = vgui.Create("DPanel", row)

    previewWrap:Dock(LEFT)
    previewWrap:SetWide(compact and S(76) or S(94))
    previewWrap:DockMargin(
        compact and S(8) or S(10),
        compact and S(6) or S(7),
        compact and S(8) or S(10),
        compact and S(6) or S(7)
    )

    previewWrap.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface2)
        surface.DrawRect(0, 0, w, h)
    end

    local preview = vgui.Create("DModelPanel", previewWrap)

    preview:Dock(FILL)
    preview:DockMargin(S(5), S(5), S(5), S(5))

    SimpleF4.ApplyModelPanel(
        preview,
        getModels(job.model)[1],
        "portrait",
        0
    )

    ---------------------------------------------------
    -- JOB INFO
    ---------------------------------------------------

    local info = vgui.Create("DPanel", row)

    info:Dock(FILL)
    info:DockMargin(S(0), S(0), S(8), S(0))

    info.Paint = function(_, w, h)
        local jobName = F.GetDisplayName("Jobs", job, teamID)

        SimpleF4.DrawHighlightedText(
            jobName,
            self.SearchText,
            "SimpleF4.BodyBold",
            0,
            compact and S(10) or S(15),
            C.Theme.Text,
            C.Theme.Warning
        )

        surface.SetFont("SimpleF4.BodyBold")
        local badgeX = surface.GetTextSize(jobName) + S(12)

        if F.IsNewJob(teamID, job) then
            text("NEW", "SimpleF4.Small", badgeX, compact and S(11) or S(16), C.Theme.Warning)
            badgeX = badgeX + S(40)
        end

        for _, badge in ipairs(rowBadges) do
            badgeX = SimpleF4.DrawBadge(
                badge,
                badgeX,
                (compact and S(11) or S(16)) - S(7)
            ) + S(8)

        end

        text(
            F.FormatMoney(job.salary or 0) .. " salary",
            "SimpleF4.Small",
            0,
            compact and S(34) or S(41),
            C.Theme.Success
        )

        if locked then
            local reason =
                F.GetJobLockReason(
                    job,
                    teamID,
                    LocalPlayer()
                )

            if reason then
                local requirementSummary =
                    F.GetLockedRequirementSummary(
                        job,
                        teamID,
                        LocalPlayer(),
                        reason
                    )

                text(
                    SimpleF4.L(
                        "Requires",
                        {reason = requirementSummary}
                    ),
                    "SimpleF4.Small",
                    0,
                    compact and S(55) or S(66),
                    C.Theme.Warning
                )
            end
        elseif (
            not compact
            and (not C.UI or C.UI.ShowJobDescriptions ~= false)
            and SimpleF4.GetUserSetting("JobsShowDescriptions")
        ) then
            text(
                F.CleanText(job.description, 125),
                "SimpleF4.Small",
                0,
                66,
                C.Theme.Muted
            )
        end
    end

    ---------------------------------------------------
    -- RIGHT SIDE
    ---------------------------------------------------

    local actionArea = vgui.Create("DPanel", row)

    actionArea:Dock(RIGHT)
    actionArea:SetWide(compact and S(190) or S(210))

    actionArea.Paint = function(_, w, h)
        local currentPlayers, maxPlayers =
            getJobState(teamID)

        local slots

        if maxPlayers > 0 then
            slots =
                tostring(currentPlayers)
                .. " / "
                .. tostring(maxPlayers)
        else
            slots =
                tostring(currentPlayers)
                .. " players"
        end

        text(
            slots,
            "SimpleF4.Small",
            w / 2,
            compact and S(17) or S(23),
            C.Theme.Muted,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    local view = vgui.Create("DButton", actionArea)

    view:SetSize(
        compact and S(150) or S(158),
        compact and S(34) or S(40)
    )
    view:SetPos(
        compact and S(20) or S(26),
        compact and S(34) or S(42)
    )
    view:SetText("")
    view:SetCursor("hand")
    SimpleF4.AttachDeveloperContext(view, "Job", job, teamID)

    view.Paint = function(btn, w, h)
        local _, _, current, full =
            getJobState(teamID)

        local _, currentlyAllowed =
            F.JobAccessState(job, teamID, LocalPlayer())

        locked = currentlyAllowed == false

        local col =
            btn:IsHovered()
            and C.Theme.AccentSoft
            or C.Theme.Accent

        local label =
            SimpleF4.GetUserSetting("JobsQuickJoin")
            and SimpleF4.L("QuickBecome")
            or SimpleF4.L("ViewJob")

        if locked then
            col = C.Theme.Warning
            label = SimpleF4.L("Locked")
        elseif current then
            col = C.Theme.Success
            label = SimpleF4.L("CurrentJob")
        elseif full then
            col = C.Theme.Danger
            label = SimpleF4.L("JobFull")
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

    SimpleF4.AttachTooltip(view, function()
        local _, allowedNow, reasonNow =
            F.JobAccessState(job, teamID, LocalPlayer())

        if allowedNow == false then
            return reasonNow or SimpleF4.L("JobCurrentlyLocked")
        end

        -- Do not repeat information already visible on the row.
        return ""
    end)

    view.DoClick = function()
        if SimpleF4.GetUserSetting("JobsQuickJoin") then
            local models = getModels(job.model)
            local preferredModel = models[1]

            if job.vote
            and SimpleF4.GetUserSetting("JobsQuickJoinConfirmVote") then
                Derma_Query(
                    SimpleF4.L("VoteJobPrompt"),
                    SimpleF4.L("QuickJobTitle"),
                    SimpleF4.L("StartVote"),
                    function()
                        self:AttemptBecomeJob(
                            teamID,
                            job,
                            preferredModel
                        )
                    end,
                    SimpleF4.L("Cancel")
                )
                return
            end

            self:AttemptBecomeJob(
                teamID,
                job,
                preferredModel
            )
            return
        end

        self:OpenJobDetail(teamID, job, locked)
    end
end

function PANEL:OpenJobDetail(teamID, job, locked)
    if IsValid(self.Detail) then
        self.Detail:Remove()
    end

    if IsValid(self.Top) then self.Top:SetVisible(false) end
    if IsValid(self.Scroll) then self.Scroll:SetVisible(false) end

    local models = getModels(job.model)
    local modelIndex = 1

    self.Detail = vgui.Create("DPanel", self)
    self.Detail:Dock(FILL)
    self.Detail:MoveToFront()

    self.Detail.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(0, 0, w, h)
    end

    ---------------------------------------------------
    -- DETAIL HEADER
    ---------------------------------------------------

    local topBar = vgui.Create("DPanel", self.Detail)

    topBar:Dock(TOP)
    topBar:SetTall(S(58))

    topBar.Paint = function(_, w, h)
        text(
            "Jobs",
            "SimpleF4.Heading",
            0,
            12,
            C.Theme.Text
        )

        text(
            F.GetDisplayName("Jobs", job, teamID),
            "SimpleF4.Small",
            0,
            38,
            C.Theme.Muted
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(0, h - 1, w, 1)
    end

    local back = vgui.Create("DButton", topBar)

    back:Dock(RIGHT)
    back:SetWide(S(130))
    back:DockMargin(S(0), S(9), S(0), S(9))
    back:SetText("")

    back.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface
        )

        surface.DrawRect(0, 0, w, h)

        text(
            "Back",
            "SimpleF4.BodyBold",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    back.DoClick = function()
        if IsValid(self.Detail) then
            self.Detail:Remove()
        end

        if IsValid(self.Top) then self.Top:SetVisible(true) end
        if IsValid(self.Scroll) then self.Scroll:SetVisible(true) end
    end

    ---------------------------------------------------
    -- BODY
    ---------------------------------------------------

    local body = vgui.Create("DPanel", self.Detail)

    body:Dock(FILL)
    body:DockMargin(S(0), S(14), S(0), S(0))
    body.Paint = nil

    local previewCol = vgui.Create("DPanel", body)

    previewCol:Dock(LEFT)
    previewCol:SetWide(S(430))
    previewCol:DockMargin(S(0), S(0), S(18), S(0))
    previewCol.Paint = nil

    local modelCard = vgui.Create("DPanel", previewCol)

    modelCard:Dock(FILL)
    modelCard:DockMargin(S(0), S(0), S(0), S(10))

    modelCard.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)
    end

    local modelPanel = vgui.Create("DModelPanel", modelCard)

    modelPanel:Dock(FILL)
    modelPanel:DockMargin(S(14), S(14), S(14), S(14))

    ---------------------------------------------------
    -- MODEL CONTROLS
    ---------------------------------------------------

    local actionButton = vgui.Create("DButton", previewCol)

    actionButton:Dock(BOTTOM)
    actionButton:SetTall(S(52))
    actionButton:SetText("")

    local controlBar = vgui.Create("DPanel", previewCol)

    controlBar:Dock(BOTTOM)
    controlBar:SetTall(S(46))
    controlBar:DockMargin(S(0), S(0), S(0), S(8))

    controlBar.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)
    end

    local prev = vgui.Create("DButton", controlBar)

    prev:Dock(LEFT)
    prev:SetWide(S(48))
    prev:SetText("")

    local nextBtn = vgui.Create("DButton", controlBar)

    nextBtn:Dock(RIGHT)
    nextBtn:SetWide(S(48))
    nextBtn:SetText("")

    local indexLabel = vgui.Create("DLabel", controlBar)

    indexLabel:Dock(FILL)
    indexLabel:SetFont("SimpleF4.Small")
    indexLabel:SetTextColor(C.Theme.Text)
    indexLabel:SetContentAlignment(5)

    local function setModel(index)
        modelIndex = index

        if modelIndex > #models then
            modelIndex = 1
        end

        if modelIndex < 1 then
            modelIndex = #models
        end

        SimpleF4.ApplyModelPanel(
            modelPanel,
            models[modelIndex] or "models/error.mdl",
            "full",
            10
        )

        if #models > 1 then
            indexLabel:SetText(
                "Model "
                .. modelIndex
                .. " / "
                .. #models
            )
        else
            indexLabel:SetText(SimpleF4.L("SingleModel"))
        end
    end

    prev.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface2
        )

        surface.DrawRect(0, 0, w, h)

        text(
            "<",
            "SimpleF4.BodyBold",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    prev.DoClick = function()
        if #models > 1 then
            setModel(modelIndex - 1)
        end
    end

    prev:SetEnabled(#models > 1)
    SimpleF4.AttachTooltip(prev, SimpleF4.L("PreviousModel"))

    nextBtn.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface2
        )

        surface.DrawRect(0, 0, w, h)

        text(
            ">",
            "SimpleF4.BodyBold",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    nextBtn.DoClick = function()
        if #models > 1 then
            setModel(modelIndex + 1)
        end
    end

    nextBtn:SetEnabled(#models > 1)
    SimpleF4.AttachTooltip(nextBtn, SimpleF4.L("NextModel"))

    ---------------------------------------------------
    -- RIGHT SIDE INFO
    ---------------------------------------------------

    local infoCol = vgui.Create("DScrollPanel", body)
 SimpleF4.StyleScrollPanel(infoCol)

    infoCol:Dock(FILL)
    infoCol.Paint = nil

    local summary = vgui.Create("DPanel", infoCol)

    summary:Dock(TOP)
    summary:SetTall(S(112))

    local detailJobColor =
        job.color
        or team.GetColor(teamID)
        or C.Theme.Accent

    summary.Paint = function(_, w, h)
        surface.SetDrawColor(detailJobColor)
        surface.DrawRect(0, 0, S(4), h)

        local currentPlayers, maxPlayers =
            getJobState(teamID)

        local slots

        if maxPlayers > 0 then
            slots =
                tostring(currentPlayers)
                .. " / "
                .. tostring(maxPlayers)
                .. " players"
        else
            slots =
                tostring(currentPlayers)
                .. " players"
        end

        text(
            F.GetDisplayName("Jobs", job, teamID),
            "SimpleF4.Title",
            S(14),
            8,
            C.Theme.Text
        )

        text(
            F.FormatMoney(job.salary or 0)
            .. " salary",
            "SimpleF4.BodyBold",
            S(14),
            50,
            C.Theme.Success
        )

        text(
            slots,
            "SimpleF4.Small",
            S(14),
            78,
            C.Theme.Muted
        )

        text(
            F.GetCategoryDisplayName("Jobs", job.category or "Other"),
            "SimpleF4.Small",
            w - S(12),
            S(14),
            detailJobColor,
            TEXT_ALIGN_RIGHT
        )
    end

    local descriptionCard =
        vgui.Create("DPanel", infoCol)

    descriptionCard:Dock(TOP)
    descriptionCard:SetTall(S(220))
    descriptionCard:DockMargin(S(0), S(8), S(0), S(0))

    descriptionCard.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        text(
            "Description",
            "SimpleF4.BodyBold",
            16,
            14,
            C.Theme.Text
        )
    end

    local description =
        vgui.Create("DLabel", descriptionCard)

    description:Dock(FILL)
    description:DockMargin(S(16), S(40), S(16), S(16))
    description:SetFont("SimpleF4.Body")
    description:SetTextColor(C.Theme.Muted)
    description:SetWrap(true)
    description:SetAutoStretchVertical(true)
    description:SetText(
        F.CleanText(job.description, nil)
    )

    local detailsCard =
        vgui.Create("DPanel", infoCol)

    detailsCard:Dock(TOP)
    detailsCard:SetTall(S(140))
    detailsCard:DockMargin(S(0), S(8), S(0), S(0))

    detailsCard.Paint = function(_, w, h)
        local currentPlayers, maxPlayers, current, full =
            getJobState(teamID)

        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        text(
            SimpleF4.L("Details"),
            "SimpleF4.BodyBold",
            16,
            14,
            C.Theme.Text
        )

        text(
            SimpleF4.L("CommandLabel", {
                command = tostring(
                    job.command or SimpleF4.L("Unknown")
                ),
            }),
            "SimpleF4.Small",
            16,
            48,
            C.Theme.Muted
        )

        text(
            SimpleF4.L("VoteRequiredLabel", {
                value = job.vote
                    and SimpleF4.L("Yes")
                    or SimpleF4.L("No"),
            }),
            "SimpleF4.Small",
            16,
            70,
            C.Theme.Muted
        )

        text(
            SimpleF4.L("CurrentPlayersLabel", {
                count = currentPlayers,
            }),
            "SimpleF4.Small",
            16,
            92,
            C.Theme.Muted
        )

        local maxText =
            maxPlayers > 0
            and tostring(maxPlayers)
            or SimpleF4.L("Unlimited")

        text(
            SimpleF4.L("MaxPlayersLabel", {
                count = maxText,
            }),
            "SimpleF4.Small",
            w - 16,
            48,
            C.Theme.Muted,
            TEXT_ALIGN_RIGHT
        )

        text(
            SimpleF4.L("StatusLabel", {
                status = current
                    and SimpleF4.L("CurrentJobStatus")
                    or (
                        full
                        and SimpleF4.L("Full")
                        or SimpleF4.L("Available")
                    ),
            }),
            "SimpleF4.Small",
            w - 16,
            70,
            current
                and C.Theme.Success
                or (
                    full
                    and C.Theme.Danger
                    or C.Theme.Accent
                ),
            TEXT_ALIGN_RIGHT
        )

        text(
            SimpleF4.L("ModelsLabel", {
                count = #models,
            }),
            "SimpleF4.Small",
            w - 16,
            92,
            C.Theme.Muted,
            TEXT_ALIGN_RIGHT
        )
    end


    local playerCard = vgui.Create("DPanel", infoCol)
    playerCard:Dock(TOP)
    playerCard:SetTall(S(90))
    playerCard:DockMargin(0, S(8), 0, 0)

    playerCard.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        text(
            SimpleF4.L("PlayersInJob"),
            "SimpleF4.BodyBold",
            S(16),
            S(14),
            C.Theme.Text
        )

        local names = {}

        for _, ply in ipairs(team.GetPlayers(teamID) or {}) do
            table.insert(names, ply:Nick())
        end

        table.sort(names)

        local label = #names > 0
            and table.concat(names, "   •   ")
            or SimpleF4.L("NobodyInJob")

        text(
            F.CleanText(label, 110),
            "SimpleF4.Small",
            S(16),
            S(49),
            #names > 0 and C.Theme.Accent or C.Theme.Muted
        )
    end

    local weaponClasses = job.weapons or {}

    local loadoutCard = vgui.Create("DPanel", infoCol)
    loadoutCard:Dock(TOP)
    loadoutCard:SetTall(S(#weaponClasses > 0 and 104 or 78))
    loadoutCard:DockMargin(0, S(8), 0, 0)

    loadoutCard.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        text(
            SimpleF4.L("StartingWeapons"),
            "SimpleF4.BodyBold",
            S(16),
            S(14),
            C.Theme.Text
        )

        if #weaponClasses == 0 then
            text(
                SimpleF4.L("NoStartingWeapons"),
                "SimpleF4.Small",
                S(16),
                S(48),
                C.Theme.Muted
            )
            return
        end

        local shown = {}

        for i = 1, math.min(#weaponClasses, 4) do
            table.insert(
                shown,
                F.GetWeaponDisplayName(weaponClasses[i])
            )
        end

        local label = table.concat(shown, "   •   ")

        if #weaponClasses > 4 then
            label = label
                .. "   "
                .. SimpleF4.L("MoreCount", {
                    count = #weaponClasses - 4,
                })
        end

        text(
            label,
            "SimpleF4.Small",
            S(16),
            S(49),
            C.Theme.Accent
        )

    end

    if (not C.Jobs or C.Jobs.ShowRequirements ~= false) then
        local requirements = F.GetJobRequirements(job, teamID, LocalPlayer())

        if #requirements > 0 then
            local reqCard = vgui.Create("DPanel", infoCol)
            reqCard:Dock(TOP)
            reqCard:SetTall(S(44 + (#requirements * 24)))
            reqCard:DockMargin(0, S(8), 0, 0)

            reqCard.Paint = function(_, w, h)
                surface.SetDrawColor(C.Theme.Surface)
                surface.DrawRect(0, 0, w, h)

                text("Requirements", "SimpleF4.BodyBold", S(16), S(14), C.Theme.Text)

                local y = S(43)
                for _, requirement in ipairs(requirements) do
                    local passed = requirement.Passed ~= false
                    local prefix = passed and "✓ " or "✕ "
                    local col = passed and C.Theme.Success or C.Theme.Danger

                    text(
                        prefix .. tostring(requirement.Text or "Requirement"),
                        "SimpleF4.Small",
                        S(16),
                        y,
                        col
                    )

                    y = y + S(24)
                end
            end
        end
    end

    actionButton.Paint = function(btn, w, h)
        local _, _, current, full =
            getJobState(teamID)

        local _, currentlyAllowed =
            F.JobAccessState(job, teamID, LocalPlayer())

        locked = currentlyAllowed == false

        local label = SimpleF4.L("BecomeJob")

        local col =
            btn:IsHovered()
            and C.Theme.AccentSoft
            or C.Theme.Accent

        if locked then
            label = SimpleF4.L("Locked")
            col = C.Theme.Warning
        elseif current then
            label = SimpleF4.L("CurrentJob")
            col = C.Theme.Success
        elseif full then
            label = SimpleF4.L("JobFull")
            col = C.Theme.Danger
        end

        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)

        text(
            label,
            "SimpleF4.BodyBold",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    local customButtons = SimpleF4.GetJobButtons(teamID, LocalPlayer(), job)

    if #customButtons > 0 then
        local customWrap = vgui.Create("DIconLayout", previewCol)
        customWrap:Dock(BOTTOM)
        customWrap:SetTall(S(#customButtons * 46))
        customWrap:SetSpaceY(S(6))
        customWrap:DockMargin(0, 0, 0, S(8))

        for _, data in ipairs(customButtons) do
            local btn = customWrap:Add("DButton")
            btn:SetSize(S(430), S(40))
            btn:SetText("")

            btn.Paint = function(button, w, h)
                surface.SetDrawColor(button:IsHovered() and C.Theme.SurfaceHover or C.Theme.Surface)
                surface.DrawRect(0, 0, w, h)
                text(data.Text or "ACTION", "SimpleF4.BodyBold",
                    w/2, h/2, data.Color or C.Theme.Text,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            if data.Tooltip then
                SimpleF4.AttachTooltip(btn, data.Tooltip)
            end

            btn.DoClick = function()
                if isfunction(data.DoClick) then
                    data.DoClick(LocalPlayer(), job, teamID)
                end
            end
        end
    end

    actionButton.DoClick = function()
        self:AttemptBecomeJob(
            teamID,
            job,
            IsValid(modelPanel) and modelPanel:GetModel() or nil
        )
    end

    setModel(1)
end


function PANEL:Think()
    -- Job slot counts, requirement states and category player totals are
    -- calculated live while the menu remains open.
    self:InvalidateLayout(false)
end

vgui.Register(
    "SimpleF4.Jobs",
    PANEL,
    "Panel"
)

SimpleF4.RegisterPage("Jobs", {
    Label = SimpleF4.L("Jobs"),
    ClassName = "SimpleF4.Jobs",
    Order = 20,
})
