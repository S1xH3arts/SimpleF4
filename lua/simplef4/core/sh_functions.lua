local F = SimpleF4.Functions

function F.FormatMoney(amount)
    amount = math.floor(tonumber(amount) or 0)

    if DarkRP and DarkRP.formatMoney then
        return DarkRP.formatMoney(amount)
    end

    return "£" .. string.Comma(amount)
end

function F.GetMoney(ply)
    if not IsValid(ply) or not ply.getDarkRPVar then return 0 end
    return tonumber(ply:getDarkRPVar("money")) or 0
end

function F.GetJobName(ply)
    if not IsValid(ply) then return "Unknown" end
    local hooked = hook.Run("SimpleF4_GetJobName", ply)
    if isstring(hooked) and hooked ~= "" then return hooked end

    if ply.getDarkRPVar then
        local job = ply:getDarkRPVar("job")
        if job and job ~= "" then return job end
    end

    return team.GetName(ply:Team()) or "Unknown"
end

function F.CleanText(str, maxLen)
    str = tostring(str or "")
    str = string.gsub(str, "\n", " ")
    str = string.gsub(str, "%s+", " ")
    str = string.Trim(str)

    if maxLen and #str > maxLen then
        str = string.sub(str, 1, maxLen) .. "..."
    end

    return str
end


function F.GetStaffRole(ply)
    if not IsValid(ply) then
        return nil, nil, false
    end

    local hookName, hookColour = hook.Run("SimpleF4_GetStaffRole", ply)
    if isstring(hookName) and hookName ~= "" then
        return hookName, hookColour or SimpleF4.Config.DefaultStaffColour, true
    end

    local special = SimpleF4.Config.SpecialRoles[ply:SteamID()]

    if special ~= nil then
        if istable(special) then
            return
                special.Name or special.name or "Special Role",
                special.Color or special.color or SimpleF4.Config.DefaultStaffColour,
                true
        end

        return
            tostring(special),
            SimpleF4.Config.DefaultStaffColour,
            true
    end

    local group = ply:GetUserGroup()
    local name = SimpleF4.Config.StaffGroups[group]

    if not name then
        return nil, nil, false
    end

    local colour =
        SimpleF4.Config.StaffGroupColours[group]
        or SimpleF4.Config.DefaultStaffColour

    return name, colour, false
end

function F.IsStaffVisible(ply, viewer)
    local hooked = hook.Run("SimpleF4_IsStaffVisible", ply, viewer)
    if hooked ~= nil then return hooked == true end
    if not IsValid(ply) then return false end

    -- Personal superadmin privacy setting.
    -- This affects the viewer's own Staff Online card AND staff list.
    if CLIENT
    and IsValid(viewer)
    and ply == viewer
    and viewer:IsSuperAdmin()
    and SimpleF4.GetUserSetting
    and SimpleF4.GetUserSetting("SuperAdminHideSelfFromStaff") then
        return false
    end

    local role = F.GetStaffRole(ply)

    if not role then return false end

    local stealthKey = SimpleF4.Config.StaffStealthNWBool
    if stealthKey and stealthKey ~= "" and ply:GetNWBool(stealthKey, false) then
        if not IsValid(viewer) or not viewer:IsSuperAdmin() then
            return false
        end
    end

    return true
end

function F.GetOnlineStaff()
    local count = 0
    local viewer = CLIENT and LocalPlayer() or nil

    for _, ply in ipairs(player.GetAll()) do
        if F.IsStaffVisible(ply, viewer) then
            count = count + 1
        end
    end

    return count
end

function F.GetRichestPlayer()
    local best, bestMoney

    for _, ply in ipairs(player.GetAll()) do
        local money = F.GetMoney(ply)
        if not best or money > bestMoney then
            best = ply
            bestMoney = money
        end
    end

    if not IsValid(best) then return "None", 0 end
    return best:Nick(), bestMoney or 0
end

function F.GetPoorestPlayer()
    local best, bestMoney

    for _, ply in ipairs(player.GetAll()) do
        local money = F.GetMoney(ply)
        if not best or money < bestMoney then
            best = ply
            bestMoney = money
        end
    end

    if not IsValid(best) then return "None", 0 end
    return best:Nick(), bestMoney or 0
end

function F.GetMostKills()
    local best

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(best) or ply:Frags() > best:Frags() then
            best = ply
        end
    end

    if not IsValid(best) then return "None", 0 end
    return best:Nick(), best:Frags()
end

function F.JobAllowed(job, teamID, ply)
    if not job or not IsValid(ply) then return false end

    if SimpleF4.Config.JobFilter and SimpleF4.Config.JobFilter(job, teamID, ply) == false then
        return false
    end

    if job.allowed and not table.HasValue(job.allowed, F.GetPermissionTeamID(ply)) then
        return false
    end

    if job.customCheck then
        local ok, allowed = pcall(job.customCheck, ply)
        if ok and allowed == false then
            return false
        end
    end

    return true
end


--=====================================================
-- HIDDEN ENTITY HELPERS
--=====================================================

local function configuredValueExists(collection, value)
    if not istable(collection) then return false end
    value = tostring(value or "")
    if value == "" then return false end

    if collection[value] == true then
        return true
    end

    for _, configured in pairs(collection) do
        if tostring(configured or "") == value then
            return true
        end
    end

    return false
end

function F.IsEntityHidden(entData, ply)
    if F.ShouldShowHidden(ply) then return false end
    if not istable(entData) then return false end

    local hookResult = hook.Run(
        "SimpleF4_HideEntity",
        entData,
        ply
    )

    if hookResult ~= nil then
        return hookResult == true
    end

    local hidden = SimpleF4.Config.HiddenEntities or {}

    return configuredValueExists(hidden.Names, entData.name)
        or configuredValueExists(hidden.Commands, entData.cmd)
        or configuredValueExists(hidden.Classes, entData.ent or entData.entity)
end


function F.IsJobHidden(teamID, job, ply)
    if F.ShouldShowHidden(ply) then return false end
    if not istable(job) then return false end

    local hookResult = hook.Run(
        "SimpleF4_HideJob",
        teamID,
        job,
        ply
    )

    if hookResult ~= nil then
        return hookResult == true
    end

    local hidden = SimpleF4.Config.HiddenJobs or {}

    return configuredValueExists(hidden.Names, job.name)
        or configuredValueExists(hidden.Commands, job.command)
        or (
            istable(hidden.TeamIDs)
            and hidden.TeamIDs[teamID] == true
        )
end

function F.IsWeaponHidden(shipment, ply)
    if F.ShouldShowHidden(ply) then return false end
    if not istable(shipment) then return false end

    local hookResult = hook.Run(
        "SimpleF4_HideWeapon",
        shipment,
        ply
    )

    if hookResult ~= nil then
        return hookResult == true
    end

    local hidden = SimpleF4.Config.HiddenWeapons or {}

    return configuredValueExists(hidden.Names, shipment.name)
        or configuredValueExists(
            hidden.WeaponClasses,
            shipment.weapon
        )
        or configuredValueExists(
            hidden.EntityClasses,
            shipment.entity
        )
end



--=====================================================
-- PURCHASE ACCESS / LIMIT HELPERS
--=====================================================

local function purchaseFailMessage(data, fallback)
    if not istable(data) then return fallback end

    return data.CustomCheckFailMsg
        or data.customCheckFailMsg
        or data.customCheckFailMessage
        or data.CustomCheckFailMessage
        or fallback
end

function F.EntityAccessState(entData, ply)
    local maintenanceBlocked, maintenanceReason =
        F.IsMaintenanceBlocked(ply)

    if maintenanceBlocked then
        return false, maintenanceReason
    end

    if F.ShouldBypassChecks(ply) then return true, nil end
    if not entData or not IsValid(ply) then
        return false, "Unavailable"
    end

    if SimpleF4.Config.EntityFilter
    and SimpleF4.Config.EntityFilter(entData, ply) == false then
        return false, purchaseFailMessage(entData, SimpleF4.L and SimpleF4.L("UnavailableForJob") or "Unavailable for your job")
    end

    if entData.allowed
    and not table.HasValue(entData.allowed, ply:Team()) then
        return false, SimpleF4.L and SimpleF4.L("NotAvailableCurrentJob") or "Not available for your current job"
    end

    if isfunction(entData.customCheck) then
        local ok, allowed = pcall(entData.customCheck, ply)

        if not ok or allowed == false then
            return false, purchaseFailMessage(
                entData,
                SimpleF4.L and SimpleF4.L("RequirementsNotMetLong") or "You do not meet the requirements"
            )
        end
    end

    local hooked = hook.Run(
        "SimpleF4_EntityEligibility",
        entData,
        ply
    )

    if hooked == false then
        return false, "Unavailable"
    elseif isstring(hooked) and hooked ~= "" then
        return false, hooked
    end

    return true, nil
end

function F.ShipmentAccessState(shipment, ply)
    local maintenanceBlocked, maintenanceReason =
        F.IsMaintenanceBlocked(ply)

    if maintenanceBlocked then
        return false, maintenanceReason
    end

    if F.ShouldBypassChecks(ply) then return true, nil end
    if not shipment or not IsValid(ply) then
        return false, "Unavailable"
    end

    if SimpleF4.Config.ShipmentFilter
    and SimpleF4.Config.ShipmentFilter(shipment, ply) == false then
        return false, purchaseFailMessage(
            shipment,
            SimpleF4.L and SimpleF4.L("UnavailableForJob") or "Unavailable for your job"
        )
    end

    if shipment.allowed
    and not table.HasValue(shipment.allowed, ply:Team()) then
        return false, SimpleF4.L and SimpleF4.L("NotAvailableCurrentJob") or "Not available for your current job"
    end

    if isfunction(shipment.customCheck) then
        local ok, allowed = pcall(shipment.customCheck, ply)

        if not ok or allowed == false then
            return false, purchaseFailMessage(
                shipment,
                SimpleF4.L and SimpleF4.L("RequirementsNotMetLong") or "You do not meet the requirements"
            )
        end
    end

    local hooked = hook.Run(
        "SimpleF4_WeaponEligibility",
        shipment,
        ply
    )

    if hooked == false then
        return false, "Unavailable"
    elseif isstring(hooked) and hooked ~= "" then
        return false, hooked
    end

    return true, nil
end

function F.EntityAllowed(entData, ply)
    local allowed = F.EntityAccessState(entData, ply)
    return allowed == true
end

function F.ShipmentAllowed(shipment, ply)
    local allowed = F.ShipmentAccessState(shipment, ply)
    return allowed == true
end

local function getEntityOwner(entity)
    if not IsValid(entity) then return nil end

    if entity.CPPIGetOwner then
        local owner = entity:CPPIGetOwner()
        if IsValid(owner) then return owner end
    end

    if entity.Getowning_ent then
        local owner = entity:Getowning_ent()
        if IsValid(owner) then return owner end
    end

    return nil
end


SimpleF4.PurchaseLimitProviders =
    SimpleF4.PurchaseLimitProviders or {}

function SimpleF4.RegisterPurchaseLimitProvider(name, callback, priority)
    if not isstring(name) or name == "" or not isfunction(callback) then
        return false
    end

    SimpleF4.PurchaseLimitProviders[name] = {
        Callback = callback,
        Priority = tonumber(priority) or 100,
    }

    return true
end

local function runPurchaseLimitProviders(kind, data, ply)
    local providers = {}

    for name, provider in pairs(SimpleF4.PurchaseLimitProviders) do
        table.insert(providers, {
            Name = name,
            Callback = provider.Callback,
            Priority = provider.Priority,
        })
    end

    table.sort(providers, function(a, b)
        if a.Priority == b.Priority then
            return a.Name < b.Name
        end

        return a.Priority < b.Priority
    end)

    for _, provider in ipairs(providers) do
        local ok, current, maximum =
            pcall(provider.Callback, kind, data, ply)

        if ok and (current ~= nil or maximum ~= nil) then
            return tonumber(current), tonumber(maximum)
        end
    end

    return nil, nil
end


function F.GetPurchaseLimit(kind, data, ply)
    local hookCurrent, hookMax = hook.Run(
        "SimpleF4_GetPurchaseLimit",
        kind,
        data,
        ply
    )

    if hookCurrent ~= nil or hookMax ~= nil then
        local current =
            hookCurrent ~= nil
            and tonumber(hookCurrent)
            or nil

        return current, tonumber(hookMax)
    end

    local providerCurrent, providerMax =
        runPurchaseLimitProviders(kind, data, ply)

    if providerCurrent ~= nil or providerMax ~= nil then
        return providerCurrent, providerMax
    end

    if not istable(data) or not IsValid(ply) then
        return 0, nil
    end

    local maxCount = tonumber(data.max or data.Max or data.maxCount or data.limit)
    if not maxCount or maxCount <= 0 then
        return 0, nil
    end

    if kind == "Entities" then
        local class = data.ent or data.entity

        if isstring(class) and class ~= "" then
            local current = 0

            for _, entity in ipairs(ents.FindByClass(class)) do
                if getEntityOwner(entity) == ply then
                    current = current + 1
                end
            end

            return current, maxCount
        end
    end

    return nil, maxCount
end

function F.GetPurchaseEligibility(kind, data, ply)
    local allowed, reason

    if kind == "Entities" then
        allowed, reason = F.EntityAccessState(data, ply)
    else
        allowed, reason = F.ShipmentAccessState(data, ply)
    end

    local current, maxCount = F.GetPurchaseLimit(kind, data, ply)

    if not allowed then
        return false, reason, current, maxCount
    end

    if maxCount and current ~= nil and current >= maxCount then
        return false, "Purchase limit reached", current, maxCount
    end

    return true, nil, current, maxCount
end


-- Extension point for custom currencies.
-- Another addon may return:
--   "250 Tokens"
-- from:
--   hook.Add("SimpleF4_EntityPriceText", "...", function(entData) ... end)
function F.GetEntityPriceText(entData)
    local custom = hook.Run("SimpleF4_EntityPriceText", entData)
    if custom ~= nil then
        return tostring(custom)
    end

    return F.FormatMoney(entData and entData.price or 0)
end


local function normalizeRequiredTeams(value)
    if value == nil then return {} end

    if istable(value) then
        return value
    end

    return {value}
end

function F.GetJobRequirements(job, teamID, ply)
    local out = {}

    local registered =
        SimpleF4.CustomJobRequirements
        and SimpleF4.CustomJobRequirements[teamID]

    if istable(registered) then
        for _, requirement in ipairs(registered) do
            local passed = requirement.Passed

            if isfunction(requirement.Check) then
                local ok, result = pcall(requirement.Check, ply, job, teamID)
                passed = ok and result ~= false
            end

            table.insert(out, {
                Text = requirement.Text or SimpleF4.L and SimpleF4.L("CustomRequirement") or "Custom requirement",
                Passed = passed ~= false,
            })
        end
    end

    if SimpleF4.Config.GetJobRequirements then
        local ok, result = pcall(
            SimpleF4.Config.GetJobRequirements,
            job,
            teamID,
            ply
        )

        if ok and istable(result) then
            for _, requirement in ipairs(result) do
                table.insert(out, requirement)
            end
        end
    end

    local hookResult = hook.Run(
        "SimpleF4_GetJobRequirements",
        job,
        teamID,
        ply
    )

    if istable(hookResult) then
        for _, requirement in ipairs(hookResult) do
            table.insert(out, requirement)
        end
    end

    local requiredTeams = F.GetRequiredPreviousTeams(job)

    if #requiredTeams > 0 then
        table.insert(out, {
            Text = SimpleF4.L
                and SimpleF4.L("MustCurrentlyBe", {
                    job = F.GetRequiredTeamText(job)
                        or SimpleF4.L("RequiredJobFallback"),
                })
                or (
                    "Must currently be "
                    .. (
                        F.GetRequiredTeamText(job)
                        or "the required job"
                    )
                ),
            Passed = table.HasValue(requiredTeams, F.GetPermissionTeamID(ply)),
        })
    end

    if job.allowed then
        table.insert(out, {
            Text = SimpleF4.L and SimpleF4.L("AllowedJobRequirement") or "Allowed-job requirement",
            Passed = table.HasValue(job.allowed, F.GetPermissionTeamID(ply)),
        })
    end

    if job.customCheck then
        local ok, passed = pcall(job.customCheck, ply)

        table.insert(out, {
            Text = job.CustomCheckFailMsg
                or job.customCheckFailMsg
                or SimpleF4.L and SimpleF4.L("CustomJobRequirement") or "Custom job requirement",
            Passed = ok and passed ~= false,
        })
    end

    return out
end


function F.JobAccessState(job, teamID, ply)
    local maintenanceBlocked, maintenanceReason =
        F.IsMaintenanceBlocked(ply)

    if maintenanceBlocked then
        return true, false, maintenanceReason
    end

    if F.ShouldBypassChecks(ply) then return true, true, nil end
    if not job or not IsValid(ply) then
        return false, false,
            SimpleF4.L
            and SimpleF4.L("Unavailable")
            or "Unavailable"
    end

    local visible = true

    if SimpleF4.Config.JobFilter
    and SimpleF4.Config.JobFilter(job, teamID, ply) == false then
        visible = false
    end

    local requiredTeams = F.GetRequiredPreviousTeams(job)

    if #requiredTeams > 0
    and not table.HasValue(requiredTeams, F.GetPermissionTeamID(ply)) then
        return
            visible,
            false,
            SimpleF4.L
                and SimpleF4.L("MustCurrentlyBeFirst", {
                    job = F.GetRequiredTeamText(job)
                        or SimpleF4.L("RequiredJobFallback"),
                })
                or (
                    "You must currently be "
                    .. (
                        F.GetRequiredTeamText(job)
                        or "the required job"
                    )
                    .. " first."
                )
    end

    if job.allowed
    and not table.HasValue(job.allowed, F.GetPermissionTeamID(ply)) then
        return
            visible,
            false,
            SimpleF4.L
                and SimpleF4.L("AllowedJobRequirementFailed")
                or "You do not meet this job's allowed-job requirement."
    end

    if job.customCheck then
        local ok, passed = pcall(job.customCheck, ply)

        if ok and passed == false then
            return
                visible,
                false,
                job.CustomCheckFailMsg
                    or job.customCheckFailMsg
                    or (
                        SimpleF4.L
                        and SimpleF4.L("JobRequirementsFailedLong")
                        or "You do not meet this job's requirements."
                    )
        end
    end

    return visible, true, nil
end


function F.GetRequiredPreviousTeams(job)
    if not job then return {} end

    return normalizeRequiredTeams(
        job.NeedToChangeFrom
        or job.needToChangeFrom
        or job.needtochangefrom
    )
end

function F.GetRequiredTeamText(job)
    local required = F.GetRequiredPreviousTeams(job)

    if #required == 0 then
        return nil
    end

    local names = {}

    for _, teamID in ipairs(required) do
        table.insert(
            names,
            team.GetName(teamID) or ("Team " .. tostring(teamID))
        )
    end

    return table.concat(names, " or ")
end

--=====================================================
-- EXTENSION API
--=====================================================

SimpleF4.CustomJobRequirements = SimpleF4.CustomJobRequirements or {}

function SimpleF4.AddJobRequirement(teamID, requirement)
    if teamID == nil or not istable(requirement) then return false end

    SimpleF4.CustomJobRequirements[teamID] =
        SimpleF4.CustomJobRequirements[teamID] or {}

    table.insert(SimpleF4.CustomJobRequirements[teamID], requirement)
    return true
end

function SimpleF4.ClearJobRequirements(teamID)
    SimpleF4.CustomJobRequirements[teamID] = nil
end

local function tableMatchesValue(tbl, value)
    if not istable(tbl) then return false end

    if tbl[value] == true then
        return true
    end

    return table.HasValue(tbl, value)
end

function F.CategoryAllowed(kind, category, ply)
    local allowed = F.CategoryAccessState(kind, category, ply)
    return allowed == true
end

local function isMarkedNew(tbl, ...)
    if not istable(tbl) then return false end

    local values = {...}

    for _, value in ipairs(values) do
        if value ~= nil then
            if tbl[value] == true or table.HasValue(tbl, value) then
                return true
            end
        end
    end

    return false
end

function F.IsNewJob(teamID, job)
    local tbl = SimpleF4.Config.NewContent
        and SimpleF4.Config.NewContent.Jobs

    return isMarkedNew(
        tbl,
        teamID,
        job and job.name,
        job and job.command
    )
end

function F.IsNewEntity(ent)
    local tbl = SimpleF4.Config.NewContent
        and SimpleF4.Config.NewContent.Entities

    return isMarkedNew(
        tbl,
        ent and ent.name,
        ent and ent.cmd,
        ent and ent.ent
    )
end

function F.IsNewShipment(shipment)
    local tbl = SimpleF4.Config.NewContent
        and SimpleF4.Config.NewContent.Weapons

    return isMarkedNew(
        tbl,
        shipment and shipment.name,
        shipment and shipment.entity,
        shipment and shipment.weapon
    )
end



--=====================================================
-- MAINTENANCE / PREVIEW / CATEGORY COLOUR
--=====================================================

function F.GetCategoryColour(kind, category)
    local all = SimpleF4.Config.CategoryColours or {}
    local list = all[kind]
    return istable(list) and list[category] or nil
end

function F.IsMaintenanceBlocked(ply)
    local maintenance = SimpleF4.Config.Maintenance or {}

    local enabled = maintenance.Enabled == true

    if GetGlobalBool then
        enabled = GetGlobalBool(
            "SimpleF4.Maintenance",
            enabled
        )
    end

    if not enabled then
        return false, nil
    end

    -- Maintenance applies to everybody, including superadmins.
    -- The only SimpleF4-side bypass is the superadmin personal
    -- "Bypass SimpleF4 checks" option.
    if F.ShouldBypassChecks
    and F.ShouldBypassChecks(ply) then
        return false, nil
    end

    return true,
        maintenance.Message
        or SimpleF4.L and SimpleF4.L("MaintenanceDefault") or "SimpleF4 is currently in maintenance mode."
end

function F.GetPermissionPreview(ply)
    if not CLIENT
    or not IsValid(ply)
    or not ply:IsSuperAdmin()
    or not SimpleF4.GetUserSetting
    or not SimpleF4.GetUserSetting("SuperAdminPermissionPreview") then
        return nil
    end

    return {
        TeamID = tonumber(
            SimpleF4.GetUserChoice(
                "SuperAdminPreviewTeamID",
                "-1"
            )
        ) or -1,

        UserGroup = tostring(
            SimpleF4.GetUserChoice(
                "SuperAdminPreviewUserGroup",
                "user"
            )
        ),
    }
end

function F.IsPermissionPreviewActive(ply)
    return F.GetPermissionPreview(ply) ~= nil
end

function F.IsPermissionSuperAdmin(ply)
    local preview = F.GetPermissionPreview(ply)

    if preview then
        return string.lower(preview.UserGroup or "") == "superadmin"
    end

    return IsValid(ply) and ply:IsSuperAdmin() or false
end

function F.IsPermissionAdmin(ply)
    local preview = F.GetPermissionPreview(ply)

    if preview then
        local group = string.lower(preview.UserGroup or "")
        return group == "admin" or group == "superadmin"
    end

    return IsValid(ply) and ply:IsAdmin() or false
end

function F.GetPermissionTeamID(ply)
    local preview = F.GetPermissionPreview(ply)

    if preview and preview.TeamID >= 0 then
        return preview.TeamID
    end

    return IsValid(ply) and ply:Team() or -1
end

function F.GetPermissionUserGroup(ply)
    local preview = F.GetPermissionPreview(ply)

    if preview and preview.UserGroup ~= "" then
        return preview.UserGroup
    end

    return IsValid(ply) and ply:GetUserGroup() or ""
end

function F.GetPermissionJobName(ply)
    local teamID = F.GetPermissionTeamID(ply)
    local job = RPExtraTeams and RPExtraTeams[teamID]

    return job and job.name
        or (IsValid(ply) and F.GetJobName(ply) or "")
end

function F.GetPermissionExplanation(kind, data, id, ply)
    local out = {}

    if kind == "Jobs" then
        for _, requirement in ipairs(
            F.GetJobRequirements(data, id, ply)
        ) do
            table.insert(
                out,
                (requirement.Passed == false and "NO  " or "OK  ")
                .. tostring(requirement.Text or "Requirement")
            )
        end

        local _, allowed, reason =
            F.JobAccessState(data, id, ply)

        if allowed == false and #out == 0 then
            table.insert(out, "NO  " .. tostring(reason or "Unavailable"))
        end
    elseif kind == "Entities" then
        local allowed, reason = F.EntityAccessState(data, ply)

        table.insert(
            out,
            allowed
                and "OK  Available"
                or ("NO  " .. tostring(reason or "Unavailable"))
        )
    elseif kind == "Weapons" then
        local allowed, reason = F.ShipmentAccessState(data, ply)

        table.insert(
            out,
            allowed
                and "OK  Available"
                or ("NO  " .. tostring(reason or "Unavailable"))
        )
    end

    return out
end



function F.GetVisibleAnnouncements(ply, includeDismissed)
    local config = SimpleF4.Config.Announcements or {}
    local out = {}

    if config.Enabled ~= true or not istable(config.Items) then
        return out
    end

    local now = os.time()

    for index, item in ipairs(config.Items) do
        if not istable(item) then continue end

        local startTime = tonumber(item.StartTime) or 0
        local endTime = tonumber(item.EndTime) or 0

        if startTime > 0 and now < startTime then continue end
        if endTime > 0 and now > endTime then continue end

        if CLIENT
        and SimpleF4.NavItemAllowed
        and not SimpleF4.NavItemAllowed(item, ply) then
            continue
        end

        local id = tostring(item.ID or ("announcement_" .. index))
        local dismissed = false

        if CLIENT
        and cookie
        and item.Dismissible == true then
            dismissed =
                cookie.GetString(
                    "simplef4_announcement_" .. id,
                    "0"
                ) == "1"
        end

        if includeDismissed or not dismissed then
            local copy = table.Copy(item)
            copy.SimpleF4ID = id
            copy.SimpleF4Dismissed = dismissed
            copy.SimpleF4PublishedAt =
                tonumber(item.PublishedAt)
                or tonumber(item.StartTime)
                or 0

            table.insert(out, copy)
        end
    end

    table.sort(out, function(a, b)
        local ap = a.Pinned == true
        local bp = b.Pinned == true

        if ap ~= bp then
            return ap
        end

        local at = tonumber(a.SimpleF4PublishedAt) or 0
        local bt = tonumber(b.SimpleF4PublishedAt) or 0

        if at ~= bt then
            return at > bt
        end

        return tostring(a.Title or "") < tostring(b.Title or "")
    end)

    return out
end

function F.GetFailedJobRequirements(job, teamID, ply)
    local failed = {}

    for _, requirement in ipairs(
        F.GetJobRequirements(job, teamID, ply)
    ) do
        if requirement.Passed == false then
            table.insert(
                failed,
                tostring(requirement.Text or "Requirement")
            )
        end
    end

    return failed
end

function F.GetLockedRequirementSummary(job, teamID, ply, fallback)
    local failed = F.GetFailedJobRequirements(job, teamID, ply)

    if #failed == 0 then
        return tostring(fallback or SimpleF4.L and SimpleF4.L("RequirementsNotMetShort") or "Requirements not met")
    end

    local shown = {}

    for index = 1, math.min(2, #failed) do
        table.insert(shown, failed[index])
    end

    local value = table.concat(shown, " • ")

    if #failed > #shown then
        value = value
            .. " • +"
            .. tostring(#failed - #shown)
            .. " more"
    end

    return value
end


--=====================================================
-- DISPLAY / ORDER / SEARCH / SUPERADMIN HELPERS
--=====================================================

local function sf4MatchesConfigValue(tbl, ...)
    if not istable(tbl) then return false end

    for _, value in ipairs({...}) do
        if value ~= nil then
            if tbl[value] == true or table.HasValue(tbl, value) then
                return true
            end
        end
    end

    return false
end

function F.IsSuperAdminOverrideEnabled(key, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return false end
    if not SimpleF4.GetUserSetting then return false end
    return SimpleF4.GetUserSetting("SuperAdmin" .. tostring(key)) == true
end

function F.ShouldShowHidden(ply)
    return F.IsSuperAdminOverrideEnabled("ShowHiddenStuff", ply)
end

function F.ShouldBypassChecks(ply)
    -- Permission Preview must always evaluate the selected preview context.
    -- Otherwise a real superadmin with bypass enabled would see everything
    -- and the preview would be useless.
    if F.IsPermissionPreviewActive
    and F.IsPermissionPreviewActive(ply) then
        return false
    end

    return F.IsSuperAdminOverrideEnabled("BypassChecks", ply)
end

function F.IsCategoryHidden(kind, category, ply)
    if F.ShouldShowHidden(ply) then return false end

    local all = SimpleF4.Config.HiddenCategories or {}
    local list = all[kind]

    return sf4MatchesConfigValue(list, category)
end

function F.GetPageDisplayName(pageID, fallback)
    local pages = SimpleF4.Config.DisplayNames
        and SimpleF4.Config.DisplayNames.Pages

    if istable(pages) and pages[pageID] ~= nil then
        return tostring(pages[pageID])
    end

    return tostring(fallback or pageID)
end

function F.GetCategoryIcon(kind, category)
    local icons = SimpleF4.Config.CategoryIcons or {}
    local value

    if istable(icons[kind]) and icons[kind][category] then
        value = icons[kind][category]
    else
        -- Backwards compatibility with the older flat table.
        value = icons[category]
    end

    if isstring(value) then
        return value, color_white, 16
    end

    if istable(value) then
        return value.Icon or value.Material or value.Path,
            value.Color or color_white,
            tonumber(value.Size) or 16
    end

    return nil, color_white, 16
end

function F.GetCategoryDescription(kind, category)
    local descriptions = SimpleF4.Config.CategoryDescriptions or {}
    local list = descriptions[kind]

    if not istable(list) then return nil end

    local value = list[category]
    return isstring(value) and value ~= "" and value or nil
end

local function permissionReason(rule, fallback)
    if istable(rule) then
        return rule.Reason
            or rule.LockReason
            or rule.FailMessage
            or fallback
    end

    return fallback
end

function F.CategoryAccessState(kind, category, ply)
    if F.ShouldBypassChecks(ply) then
        return true, nil
    end

    if F.IsCategoryHidden(kind, category, ply) then
        return false, SimpleF4.L and SimpleF4.L("HiddenByConfig") or "Hidden by server configuration"
    end

    local permissions = SimpleF4.Config.CategoryPermissions
    local kindRules = permissions and permissions[kind]
    local rule = istable(kindRules) and kindRules[category] or nil

    if rule == nil then
        return true, nil
    end

    if isbool(rule) then
        return rule, rule and nil or SimpleF4.L and SimpleF4.L("RestrictedCategory") or "Restricted category"
    end

    if isfunction(rule) then
        local ok, allowed, reason = pcall(rule, ply, category, kind)

        if not ok or allowed == false then
            return false, isstring(reason) and reason or SimpleF4.L and SimpleF4.L("RestrictedCategory") or "Restricted category"
        end

        return true, nil
    end

    if not istable(rule) then
        return true, nil
    end

    if rule.SuperAdminOnly == true
    and not F.IsPermissionSuperAdmin(ply) then
        return false, permissionReason(rule, SimpleF4.L and SimpleF4.L("SuperadminOnly") or "Superadmin only")
    end

    if rule.AdminOnly == true
    and not F.IsPermissionAdmin(ply) then
        return false, permissionReason(rule, SimpleF4.L and SimpleF4.L("AdminOnly") or "Admin only")
    end

    if istable(rule.UserGroups) then
        local group = F.GetPermissionUserGroup(ply)

        if not tableMatchesValue(rule.UserGroups, group) then
            return false, permissionReason(rule, SimpleF4.L and SimpleF4.L("RestrictedUsergroup") or "Restricted usergroup")
        end
    end

    if istable(rule.Teams) then
        local teamID = F.GetPermissionTeamID(ply)

        if not tableMatchesValue(rule.Teams, teamID) then
            return false, permissionReason(rule, SimpleF4.L and SimpleF4.L("RestrictedJob") or "Restricted job")
        end
    end

    if istable(rule.JobNames) then
        local name = F.GetPermissionJobName(ply)

        if not tableMatchesValue(rule.JobNames, name) then
            return false, permissionReason(rule, SimpleF4.L and SimpleF4.L("RestrictedJob") or "Restricted job")
        end
    end

    if istable(rule.SteamIDs) then
        local id = IsValid(ply) and ply:SteamID() or ""

        if not tableMatchesValue(rule.SteamIDs, id) then
            return false, permissionReason(rule, SimpleF4.L and SimpleF4.L("RestrictedAccount") or "Restricted account")
        end
    end

    if istable(rule.SteamID64s) then
        local id64 = IsValid(ply) and ply:SteamID64() or ""

        if not tableMatchesValue(rule.SteamID64s, id64) then
            return false, permissionReason(rule, SimpleF4.L and SimpleF4.L("RestrictedAccount") or "Restricted account")
        end
    end

    local minPlaytime = tonumber(rule.MinPlaytimeSeconds) or 0

    if minPlaytime > 0 then
        local playtime = F.GetPlaytime and F.GetPlaytime(ply) or nil

        if not isnumber(playtime) or playtime < minPlaytime then
            return false, permissionReason(
                rule,
                SimpleF4.L and SimpleF4.L("RequiresMorePlaytime") or "Requires more server playtime"
            )
        end
    end

    if isfunction(rule.CustomCheck) then
        local ok, allowed, reason =
            pcall(rule.CustomCheck, ply, category, kind)

        if not ok or allowed == false then
            return false,
                isstring(reason)
                and reason
                or permissionReason(rule, SimpleF4.L and SimpleF4.L("RestrictedCategory") or "Restricted category")
        end
    end

    return true, nil
end

function F.PageAccessState(pageID, ply)
    local blocked, reason = F.IsMaintenanceBlocked(ply)

    if blocked
    and pageID ~= "Dashboard"
    and pageID ~= "Settings" then
        return false, reason
    end

    local rules = SimpleF4.Config.PagePermissions or {}
    local rule = rules[pageID]

    if rule == nil or F.ShouldBypassChecks(ply) then
        return true, nil
    end

    if isbool(rule) then
        return rule, rule and nil or SimpleF4.L and SimpleF4.L("RestrictedPage") or "Restricted page"
    end

    if isfunction(rule) then
        local ok, allowed, reason = pcall(rule, ply, pageID)

        if not ok or allowed == false then
            return false, isstring(reason) and reason or SimpleF4.L and SimpleF4.L("RestrictedPage") or "Restricted page"
        end

        return true, nil
    end

    if not istable(rule) then return true, nil end

    local allowed = SimpleF4.NavItemAllowed
        and SimpleF4.NavItemAllowed(rule, ply)
        or true

    return allowed,
        allowed and nil or permissionReason(rule, SimpleF4.L and SimpleF4.L("RestrictedPage") or "Restricted page")
end

function F.GetCategoryDisplayName(kind, category)
    local categories = SimpleF4.Config.DisplayNames
        and SimpleF4.Config.DisplayNames.Categories
    local list = categories and categories[kind]
    return (istable(list) and list[category]) or category
end

function F.GetCategoryOrder(kind, category)
    local list = SimpleF4.Config.CategoryOrder
        and SimpleF4.Config.CategoryOrder[kind]
    return tonumber(istable(list) and list[category]) or 100
end

function F.GetDisplayName(kind, data, id)
    local list = SimpleF4.Config.DisplayNames
        and SimpleF4.Config.DisplayNames[kind]

    if not istable(list) then
        return tostring(data and data.name or id or "")
    end

    local candidates = {
        id,
        data and data.name,
        data and data.command,
        data and data.cmd,
        data and data.ent,
        data and data.entity,
        data and data.weapon,
    }

    for _, key in ipairs(candidates) do
        if key ~= nil and list[key] ~= nil then
            return tostring(list[key])
        end
    end

    return tostring(data and data.name or id or "")
end

function F.GetItemOrder(kind, data, id)
    local list = SimpleF4.Config.ItemOrder
        and SimpleF4.Config.ItemOrder[kind]

    if not istable(list) then return 100 end

    local candidates = {
        id,
        data and data.name,
        data and data.command,
        data and data.cmd,
        data and data.ent,
        data and data.entity,
        data and data.weapon,
    }

    for _, key in ipairs(candidates) do
        if key ~= nil and list[key] ~= nil then
            return tonumber(list[key]) or 100
        end
    end

    return 100
end

function F.GetSearchAliases(kind, data, id)
    local list = SimpleF4.Config.SearchAliases
        and SimpleF4.Config.SearchAliases[kind]

    if not istable(list) then return "" end

    local candidates = {
        id,
        data and data.name,
        data and data.command,
        data and data.cmd,
        data and data.ent,
        data and data.entity,
        data and data.weapon,
    }

    for _, key in ipairs(candidates) do
        local aliases = key ~= nil and list[key] or nil

        if isstring(aliases) then
            return aliases
        elseif istable(aliases) then
            return table.concat(aliases, " ")
        end
    end

    return ""
end

function F.GetConfiguredBadges(kind, data, id)
    local list = SimpleF4.Config.Badges
        and SimpleF4.Config.Badges[kind]

    if not istable(list) then return {} end

    local candidates = {
        id,
        data and data.name,
        data and data.command,
        data and data.cmd,
        data and data.ent,
        data and data.entity,
        data and data.weapon,
    }

    for _, key in ipairs(candidates) do
        local badges = key ~= nil and list[key] or nil

        if istable(badges) then
            if badges.Text then
                return {badges}
            end

            return badges
        end
    end

    return {}
end

function F.PageAllowed(pageID, ply)
    local allowed = F.PageAccessState(pageID, ply)
    return allowed == true
end


--=====================================================
-- DISPLAY HELPERS / BADGES
--=====================================================

function F.GetWeaponDisplayName(className)
    className = tostring(className or "")
    if className == "" then return "Unknown Weapon" end

    local stored = weapons.GetStored and weapons.GetStored(className)
    local printName = stored and stored.PrintName

    if isstring(printName) and printName ~= "" then
        local translated = language.GetPhrase(printName)
        if translated and translated ~= printName then
            return translated
        end

        return printName
    end

    local phrase = language.GetPhrase(className)

    if phrase and phrase ~= className then
        return phrase
    end

    -- Fall back to a readable class name instead of exposing raw IDs.
    local readable = string.gsub(className, "^weapon_", "")
    readable = string.gsub(readable, "^cw_", "")
    readable = string.gsub(readable, "_", " ")
    readable = string.Trim(readable)

    if readable == "" then
        return className
    end

    return string.upper(string.sub(readable, 1, 1)) .. string.sub(readable, 2)
end

SimpleF4.CustomBadges = SimpleF4.CustomBadges or {
    Jobs = {},
    Entities = {},
    Weapons = {},
}

function SimpleF4.AddBadge(kind, target, badge)
    if not SimpleF4.CustomBadges[kind] or not istable(badge) then
        return false
    end

    table.insert(SimpleF4.CustomBadges[kind], {
        Target = target,
        Badge = badge,
    })

    return true
end

local function badgeTargetMatches(target, ...)
    if isfunction(target) then
        local ok, result = pcall(target, ...)
        return ok and result == true
    end

    for _, value in ipairs({...}) do
        if value ~= nil and target == value then
            return true
        end
    end

    return false
end

function F.GetCustomBadges(kind, ...)
    local out = {}

    local args = {...}
    local data
    local id

    for _, value in ipairs(args) do
        if istable(value) and (value.name or value.command or value.cmd) then
            data = value
        elseif id == nil and (isnumber(value) or isstring(value)) then
            id = value
        end
    end

    for _, badge in ipairs(F.GetConfiguredBadges(kind, data, id)) do
        table.insert(out, badge)
    end
    local list = SimpleF4.CustomBadges
        and SimpleF4.CustomBadges[kind]

    if not istable(list) then return out end

    for _, entry in ipairs(list) do
        if badgeTargetMatches(entry.Target, ...) then
            local badge = entry.Badge

            if not isfunction(badge.Check)
            or badge.Check(...) ~= false then
                table.insert(out, badge)
            end
        end
    end

    table.sort(out, function(a, b)
        local ao = tonumber(a.Order) or 100
        local bo = tonumber(b.Order) or 100

        if ao == bo then
            return tostring(a.Text or "") < tostring(b.Text or "")
        end

        return ao < bo
    end)

    return out
end


-- Compatibility hooks:
-- SimpleF4_GetMoney, SimpleF4_GetJobName, SimpleF4_GetStaffRole,
-- SimpleF4_IsStaffVisible, SimpleF4_GetPlaytime, SimpleF4_EntityPriceText.
function F.GetPlaytime(ply)
    local result = hook.Run("SimpleF4_GetPlaytime", ply)
    return isnumber(result) and result or nil
end


function F.GetJobLockReason(job, teamID, ply)
    local _, allowed, reason =
        F.JobAccessState(job, teamID, ply)

    if allowed == false then
        return reason or "Locked"
    end

    return nil
end


--=====================================================
-- MODULE API
--=====================================================

SimpleF4.Modules = SimpleF4.Modules or {}
SimpleF4.ModuleRuntimeStatus =
    SimpleF4.ModuleRuntimeStatus or {}

local function normaliseDependencyList(value)
    local output = {}

    if isstring(value) and value ~= "" then
        table.insert(output, value)
    elseif istable(value) then
        for _, id in ipairs(value) do
            id = tostring(id or "")

            if id ~= "" then
                table.insert(output, id)
            end
        end
    end

    return output
end

function SimpleF4.RegisterModule(id, data)
    id = tostring(id or "")

    if id == ""
    or not istable(data) then
        return false
    end

    data.ID = id
    data.Name = tostring(data.Name or id)
    data.Version =
        tostring(data.Version or "1.0.0")

    data.Depends =
        normaliseDependencyList(data.Depends)

    data.OptionalDepends =
        normaliseDependencyList(
            data.OptionalDepends
        )

    SimpleF4.Modules[id] = data

    hook.Run(
        "SimpleF4_ModuleRegistered",
        id,
        data
    )

    return true
end

function SimpleF4.GetModule(id)
    return SimpleF4.Modules[
        tostring(id or "")
    ]
end

function SimpleF4.GetModules()
    return SimpleF4.Modules
end

function SimpleF4.GetModuleDependencies(id)
    local module =
        SimpleF4.GetModule(id)

    if not module then
        return {}, {}
    end

    return table.Copy(module.Depends or {}),
        table.Copy(
            module.OptionalDepends or {}
        )
end

function SimpleF4.SetModuleRuntimeStatus(
    id,
    status,
    detail
)
    id = tostring(id or "")

    if id == "" then return false end

    SimpleF4.ModuleRuntimeStatus[id] = {
        Status = tostring(
            status or "ready"
        ),
        Detail = detail ~= nil
            and tostring(detail)
            or nil,
        Updated = CurTime
            and CurTime()
            or 0,
    }

    hook.Run(
        "SimpleF4_ModuleStatusChanged",
        id,
        SimpleF4.ModuleRuntimeStatus[id]
    )

    return true
end

function SimpleF4.GetModuleRuntimeStatus(id)
    return SimpleF4.ModuleRuntimeStatus[
        tostring(id or "")
    ]
end

function SimpleF4.GetModuleStatus(id)
    id = tostring(id or "")

    local module =
        SimpleF4.GetModule(id)

    if not module then
        return {
            ID = id,
            State = "missing",
            Ready = false,
            Reason = "Module is not registered.",
        }
    end

    local config =
        SimpleF4.Config.Modules
        and SimpleF4.Config.Modules[id]

    if istable(config)
    and config.Enabled == false then
        return {
            ID = id,
            State = "disabled",
            Ready = false,
            Reason = "Disabled in configuration.",
            Module = module,
        }
    end

    if isbool(config)
    and config == false then
        return {
            ID = id,
            State = "disabled",
            Ready = false,
            Reason = "Disabled in configuration.",
            Module = module,
        }
    end

    if module.EnabledByDefault == false
    and config == nil then
        return {
            ID = id,
            State = "disabled",
            Ready = false,
            Reason = "Disabled by default.",
            Module = module,
        }
    end

    for _, dependency in ipairs(
        module.Depends or {}
    ) do
        local dependencyModule =
            SimpleF4.GetModule(dependency)

        if not dependencyModule then
            return {
                ID = id,
                State = "missing_dependency",
                Ready = false,
                Reason =
                    "Missing dependency: "
                    .. dependency,
                Dependency = dependency,
                Module = module,
            }
        end

        local dependencyStatus =
            SimpleF4.GetModuleStatus(
                dependency
            )

        if not dependencyStatus.Ready then
            return {
                ID = id,
                State = "blocked_dependency",
                Ready = false,
                Reason =
                    "Dependency unavailable: "
                    .. dependency,
                Dependency = dependency,
                Module = module,
            }
        end
    end

    local runtime =
        SimpleF4.GetModuleRuntimeStatus(id)

    if runtime
    and runtime.Status ~= "ready" then
        return {
            ID = id,
            State = runtime.Status,
            Ready = runtime.Status
                ~= "error"
                and runtime.Status
                    ~= "missing_provider",
            Reason = runtime.Detail,
            Runtime = runtime,
            Module = module,
        }
    end

    return {
        ID = id,
        State = "ready",
        Ready = true,
        Reason = runtime
            and runtime.Detail
            or nil,
        Runtime = runtime,
        Module = module,
    }
end

function SimpleF4.IsModuleEnabled(id)
    return SimpleF4.GetModuleStatus(id).Ready
end

