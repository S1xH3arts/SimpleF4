local C = SimpleF4.Config
local F = SimpleF4.Functions

local function S(v)
    return SimpleF4.S(v)
end

SimpleF4.Frame = SimpleF4.Frame or nil


--=====================================================
-- SHARED LUA AUTO REFRESH
--=====================================================

net.Receive("SimpleF4.SharedHotReload", function()
    local length = net.ReadUInt(32)

    if length <= 0 then return end

    local compressed = net.ReadData(length)
    if not compressed then return end

    local json = util.Decompress(compressed)
    if not json then return end

    local payload = util.JSONToTable(json)
    if not istable(payload)
    or not istable(payload.Files) then
        return
    end

    for _, data in ipairs(payload.Files) do
        if not istable(data) then continue end

        local path = tostring(data.Path or "")
        local code = tostring(data.Code or "")

        -- Only execute SimpleF4 shared files from the server's approved
        -- refresh payload.
        local validPath =
            path == "simplef4/config/sh_config.lua"
            or path == "simplef4/core/sh_functions.lua"
            or string.match(
                path,
                "^simplef4/modules/[^/]+/sh_[^/]+%.lua$"
            ) ~= nil

        if validPath and code ~= "" then
            local ok, err = pcall(
                RunString,
                code,
                "@" .. path,
                false
            )

            if not ok then
                ErrorNoHalt(
                    "[SimpleF4] Client shared refresh failed for "
                    .. path
                    .. ": "
                    .. tostring(err)
                    .. "\\n"
                )
            end
        end
    end

    hook.Run(
        "SimpleF4_SharedFilesReloaded",
        payload.Changed or {}
    )
end)




--=====================================================
-- LOCALISATION
--=====================================================

SimpleF4.Languages = SimpleF4.Languages or {}
SimpleF4.Language = SimpleF4.Language or {}
SimpleF4.LanguageMeta = SimpleF4.LanguageMeta or {}

function SimpleF4.RegisterLanguage(code, phrases, displayName)
    if not isstring(code) or code == "" or not istable(phrases) then
        return false
    end

    SimpleF4.Languages[code] = phrases
    SimpleF4.LanguageMeta[code] = {
        Name = tostring(displayName or code),
    }

    hook.Run("SimpleF4_LanguageRegistered", code, phrases)
    return true
end

function SimpleF4.GetLanguage()
    if SimpleF4.Config.AllowPlayerLanguageSelection ~= false then
        local saved = cookie.GetString(
            "simplef4_language",
            ""
        )

        if saved ~= ""
        and SimpleF4.Languages[saved] then
            return saved
        end
    end

    return tostring(SimpleF4.Config.Language or "en")
end

function SimpleF4.SetLanguage(code)
    code = tostring(code or "")

    if not SimpleF4.Languages[code] then
        return false
    end

    cookie.Set("simplef4_language", code)
    hook.Run("SimpleF4_LanguageChanged", code)

    if SimpleF4.RefreshPermissionPreview then
        SimpleF4.RefreshPermissionPreview()
    end

    return true
end

function SimpleF4.GetLanguageChoices()
    local out = {}

    for code in pairs(SimpleF4.Languages) do
        table.insert(out, code)
    end

    table.sort(out, function(a, b)
        local an = SimpleF4.LanguageMeta[a]
            and SimpleF4.LanguageMeta[a].Name
            or a
        local bn = SimpleF4.LanguageMeta[b]
            and SimpleF4.LanguageMeta[b].Name
            or b

        return string.lower(an) < string.lower(bn)
    end)

    return out
end

function SimpleF4.GetLanguageLabel(code)
    return SimpleF4.LanguageMeta[code]
        and SimpleF4.LanguageMeta[code].Name
        or tostring(code)
end


function SimpleF4.GetMissingLanguageKeys(code)
    code = tostring(code or SimpleF4.GetLanguage())

    local english = SimpleF4.Languages.en or {}
    local language = SimpleF4.Languages[code] or {}
    local missing = {}

    for key in pairs(english) do
        if language[key] == nil then
            table.insert(missing, key)
        end
    end

    table.sort(missing)
    return missing
end

concommand.Add("simplef4_language_missing", function(_, _, args)
    local code = tostring(args[1] or SimpleF4.GetLanguage())
    local missing = SimpleF4.GetMissingLanguageKeys(code)

    print(
        "[SimpleF4] Language '"
        .. code
        .. "' is missing "
        .. tostring(#missing)
        .. " phrase(s)."
    )

    for _, key in ipairs(missing) do
        print("  " .. key)
    end
end)

function SimpleF4.L(key, replacements)
    local code = SimpleF4.GetLanguage()
    local lang = SimpleF4.Languages[code]
        or SimpleF4.Languages.en
        or {}

    local value = lang[key]
        or (SimpleF4.Languages.en and SimpleF4.Languages.en[key])
        or key

    value = tostring(value)

    if istable(replacements) then
        for token, replacement in pairs(replacements) do
            value = string.Replace(
                value,
                "{" .. tostring(token) .. "}",
                tostring(replacement)
            )
        end
    end

    return value
end

-- Language files are loaded dynamically from:
-- lua/simplef4/languages/*.lua
--
-- en.lua is the fallback language and is loaded first.




--=====================================================
-- CLIENT PLAYER SETTINGS
--=====================================================

SimpleF4.UserSettings = SimpleF4.UserSettings or {}

local function settingCookieKey(key)
    return "simplef4_setting_" .. string.lower(tostring(key))
end

function SimpleF4.GetUserSetting(key)
    local defaults = SimpleF4.Config.PlayerSettings or {}
    local defaultValue = defaults[key]

    local superDefaults = SimpleF4.Config.SuperAdmin or {}
    local superKeyMap = {
        SuperAdminShowHiddenStuff = "ShowHiddenStuff",
        SuperAdminBypassChecks = "BypassSimpleF4Checks",
        SuperAdminHideSelfFromStaff = "HideSelfFromStaffOnline",
        SuperAdminDeveloperTools = "DeveloperTools",
        SuperAdminModuleTestMode = "ModuleTestMode",
    }

    if superKeyMap[key]
    and superDefaults[superKeyMap[key]] ~= nil then
        defaultValue = superDefaults[superKeyMap[key]]
    end

    if defaultValue == nil then
        defaultValue = false
    end

    local stored = cookie.GetString(settingCookieKey(key), "")

    if stored == "" then
        return defaultValue
    end

    return stored == "1"
end

function SimpleF4.SetUserSetting(key, value)
    value = value == true
    SimpleF4.UserSettings[key] = value
    cookie.Set(settingCookieKey(key), value and "1" or "0")
    hook.Run("SimpleF4_UserSettingChanged", key, value)
end


function SimpleF4.IsModuleTestMode()
    local ply = LocalPlayer()

    return IsValid(ply)
        and ply:IsSuperAdmin()
        and SimpleF4.GetUserSetting(
            "SuperAdminModuleTestMode"
        ) == true
end


function SimpleF4.GetUserChoice(key, defaultValue)
    local defaults = SimpleF4.Config.PlayerSettings or {}
    local fallback = defaults[key]

    if fallback == nil then
        fallback = defaultValue
    end

    local stored = cookie.GetString(settingCookieKey(key), "")
    if stored == "" then
        return fallback
    end

    return stored
end

function SimpleF4.SetUserChoice(key, value)
    cookie.Set(settingCookieKey(key), tostring(value or ""))
    hook.Run("SimpleF4_UserSettingChanged", key, value)
end

function SimpleF4.GetDensity()
    local value = tostring(
        SimpleF4.GetUserChoice(SimpleF4.L("InspectorDensity"), "Comfortable")
    )

    if value ~= "Compact" then
        value = "Comfortable"
    end

    return value
end

function SimpleF4.IsCompact()
    return SimpleF4.GetDensity() == "Compact"
end

function SimpleF4.GetDensityScale()
    return SimpleF4.IsCompact() and 0.82 or 1
end

function SimpleF4.GetRowHeight(base)
    return S(base * SimpleF4.GetDensityScale())
end


function SimpleF4.ResetUserSettings()
    local defaults = SimpleF4.Config.PlayerSettings or {}

    for key in pairs(defaults) do
        cookie.Delete(settingCookieKey(key))
        SimpleF4.UserSettings[key] = nil
    end

    hook.Run("SimpleF4_UserSettingsReset")
end

function SimpleF4.ShowResultCount()
    if SimpleF4.GetUserSetting("ShowResultCount") == false then
        return false
    end

    return not SimpleF4.Config.UI
        or SimpleF4.Config.UI.ShowSearchResultCount ~= false
end

function SimpleF4.ShowPageSubtitles()
    if SimpleF4.GetUserSetting("ShowPageSubtitles") == false then
        return false
    end

    return not SimpleF4.Config.UI
        or SimpleF4.Config.UI.ShowPageSubtitles ~= false
end

function SimpleF4.CategoriesStartCollapsed()
    if SimpleF4.GetUserSetting("CollapseCategories") then
        return true
    end

    return SimpleF4.Config.UI
        and SimpleF4.Config.UI.CategoriesDefaultCollapsed == true
end

function SimpleF4.GetLastPage()
    if not SimpleF4.GetUserSetting("RememberLastPage") then
        return nil
    end

    local value = cookie.GetString("simplef4_last_page", "")
    return value ~= "" and value or nil
end

function SimpleF4.SetLastPage(pageID)
    if not SimpleF4.GetUserSetting("RememberLastPage") then
        return
    end

    cookie.Set("simplef4_last_page", tostring(pageID or ""))
end

function SimpleF4.BlurEnabled()
    if SimpleF4.GetUserSetting("DisableBlur") then
        return false
    end

    local accessibility = SimpleF4.Config.Accessibility or {}
    if accessibility.DisableBlur == true then
        return false
    end

    return SimpleF4.Config.EnableBlur == true
end



SimpleF4.ChoiceLanguageKeys = {
    ["All"] = "FilterAll",
    ["Available"] = "FilterAvailable",
    ["Locked"] = "FilterLocked",
    ["Full"] = "FilterFull",
    ["Current"] = "FilterCurrent",
    ["Occupied"] = "FilterOccupied",
    ["Empty"] = "FilterEmpty",
    ["Vote"] = "FilterVote",
    ["No Vote"] = "FilterNoVote",
    ["Affordable"] = "FilterAffordable",
    ["Unaffordable"] = "FilterUnaffordable",
    ["Single"] = "FilterSingle",
    ["Shipments"] = "FilterShipments",
    ["Name"] = "SortName",
    ["Salary High"] = "SortSalaryHigh",
    ["Salary Low"] = "SortSalaryLow",
    ["Players High"] = "SortPlayersHigh",
    ["Players Low"] = "SortPlayersLow",
    ["Price Low"] = "SortPriceLow",
    ["Price High"] = "SortPriceHigh",
}

function SimpleF4.GetChoiceLabel(value)
    local key = SimpleF4.ChoiceLanguageKeys[tostring(value)]
    return key and SimpleF4.L(key) or tostring(value)
end



--=====================================================
-- CLIENT THEME SELECTION
--=====================================================

function SimpleF4.GetThemePreset()
    local stored = cookie.GetString("simplef4_theme_preset", "")

    if stored ~= ""
    and (
        stored == "Custom"
        or (SimpleF4.Config.ThemePresets and SimpleF4.Config.ThemePresets[stored])
    ) then
        return stored
    end

    return tostring(SimpleF4.Config.ThemePreset or "Blue")
end

function SimpleF4.GetThemePresetNames()
    local names = {}

    for name in pairs(SimpleF4.Config.ThemePresets or {}) do
        if tostring(name) ~= "Custom" then
            table.insert(names, tostring(name))
        end
    end

    table.sort(names)
    return names
end

function SimpleF4.ApplyThemePreset(name, save)
    name = tostring(name or SimpleF4.Config.ThemePreset or "Blue")

    local base = SimpleF4.Config.ThemeBase or {}
    local theme = SimpleF4.Config.Theme

    for key, value in pairs(base) do
        theme[key] = value
    end

    if name ~= "Custom" then
        local preset =
            SimpleF4.Config.ThemePresets
            and SimpleF4.Config.ThemePresets[name]

        if preset then
            for key, value in pairs(preset) do
                theme[key] = value
            end
        else
            name = tostring(SimpleF4.Config.ThemePreset or "Blue")
        end
    end

    if save ~= false then
        cookie.Set("simplef4_theme_preset", name)
    end

    hook.Run("SimpleF4_ThemeChanged", name)
    return name
end


function SimpleF4.ResetThemePreset()
    cookie.Delete("simplef4_theme_preset")
    return SimpleF4.ApplyThemePreset(
        tostring(SimpleF4.Config.ThemePreset or "Blue"),
        false
    )
end



timer.Simple(0, function()
    SimpleF4.ApplyThemePreset(
        SimpleF4.GetThemePreset(),
        false
    )
end)

--=====================================================
-- ACCESSIBILITY HELPERS
--=====================================================

function SimpleF4.GetTextScale()
    local accessibility = SimpleF4.Config.Accessibility or {}
    local scale = tonumber(accessibility.TextScale) or 1
    return math.Clamp(scale, 0.75, 1.5)
end

function SimpleF4.ReduceMotion()
    local accessibility = SimpleF4.Config.Accessibility or {}

    return accessibility.ReduceMotion == true
        or SimpleF4.GetUserSetting("ReduceMotion")
end

function SimpleF4.HighContrast()
    local accessibility = SimpleF4.Config.Accessibility or {}
    return accessibility.HighContrast == true
end

--=====================================================
-- ENTITY / WEAPON CUSTOM ACTION API
--=====================================================

SimpleF4.EntityButtons = SimpleF4.EntityButtons or {}
SimpleF4.WeaponButtons = SimpleF4.WeaponButtons or {}

local function addContentButton(store, target, data)
    if target == nil or not istable(data) then
        return false
    end

    table.insert(store, {
        Target = target,
        Data = data,
    })

    return true
end

function SimpleF4.AddEntityButton(target, data)
    return addContentButton(SimpleF4.EntityButtons, target, data)
end

function SimpleF4.AddWeaponButton(target, data)
    return addContentButton(SimpleF4.WeaponButtons, target, data)
end

local function matchesActionTarget(target, data)
    if isfunction(target) then
        local ok, result = pcall(target, data)
        return ok and result == true
    end

    return target == data
end

local function collectContentButtons(store, data, keys)
    local out = {}

    for _, entry in ipairs(store) do
        local matched = false

        for _, key in ipairs(keys) do
            if key ~= nil and matchesActionTarget(entry.Target, key) then
                matched = true
                break
            end
        end

        if matched then
            local item = entry.Data
            local visible = true

            if isfunction(item.CanSee) then
                local ok, result = pcall(item.CanSee, LocalPlayer(), data)
                visible = ok and result ~= false
            end

            if visible then
                table.insert(out, item)
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

function SimpleF4.GetEntityButtons(entData)
    return collectContentButtons(
        SimpleF4.EntityButtons,
        entData,
        {
            entData and entData.name,
            entData and entData.cmd,
            entData and entData.ent,
        }
    )
end

function SimpleF4.GetWeaponButtons(shipment)
    return collectContentButtons(
        SimpleF4.WeaponButtons,
        shipment,
        {
            shipment and shipment.name,
            shipment and shipment.weapon,
            shipment and shipment.entity,
        }
    )
end



--=====================================================
-- CUSTOM EMPTY STATES
--=====================================================

SimpleF4.EmptyStates = SimpleF4.EmptyStates or {}

function SimpleF4.RegisterEmptyState(pageID, data)
    if not isstring(pageID) or pageID == "" or not istable(data) then
        return false
    end

    SimpleF4.EmptyStates[pageID] =
        SimpleF4.EmptyStates[pageID] or {}

    table.insert(SimpleF4.EmptyStates[pageID], data)
    return true
end

function SimpleF4.GetEmptyState(pageID, context, fallbackTitle, fallbackText)
    local states = SimpleF4.EmptyStates[pageID] or {}

    for _, data in ipairs(states) do
        local visible = true

        if isfunction(data.CanShow) then
            local ok, result = pcall(
                data.CanShow,
                LocalPlayer(),
                context or {}
            )

            visible = ok and result == true
        end

        if visible then
            local title = isfunction(data.Title)
                and data.Title(LocalPlayer(), context or {})
                or data.Title

            local body = isfunction(data.Text)
                and data.Text(LocalPlayer(), context or {})
                or data.Text

            return tostring(title or fallbackTitle or ""),
                tostring(body or fallbackText or "")
        end
    end

    return tostring(fallbackTitle or ""), tostring(fallbackText or "")
end

--=====================================================
-- NAVBAR PERMISSIONS
--=====================================================

function SimpleF4.NavItemAllowed(data, ply)
    if not istable(data) or not IsValid(ply) then
        return false
    end

    if SimpleF4.Functions
    and SimpleF4.Functions.ShouldBypassChecks
    and SimpleF4.Functions.ShouldBypassChecks(ply) then
        return true
    end

    if data.SuperAdminOnly == true
    and not SimpleF4.Functions.IsPermissionSuperAdmin(ply) then
        return false
    end

    if data.AdminOnly == true
    and not SimpleF4.Functions.IsPermissionAdmin(ply) then
        return false
    end

    if istable(data.UserGroups)
    and next(data.UserGroups) ~= nil then
        local group = SimpleF4.Functions.GetPermissionUserGroup(ply)

        if data.UserGroups[group] ~= true
        and not table.HasValue(data.UserGroups, group) then
            return false
        end
    end

    if istable(data.Teams)
    and #data.Teams > 0
    and not table.HasValue(data.Teams, SimpleF4.Functions.GetPermissionTeamID(ply)) then
        return false
    end

    if istable(data.Categories)
    and next(data.Categories) ~= nil then
        local previewTeam =
            SimpleF4.Functions.GetPermissionTeamID(ply)

        local job =
            RPExtraTeams and RPExtraTeams[previewTeam]
        local category = job and job.category or ""

        if data.Categories[category] ~= true
        and not table.HasValue(data.Categories, category) then
            return false
        end
    end

    if istable(data.JobNames)
    and next(data.JobNames) ~= nil then
        local name = SimpleF4.Functions.GetPermissionJobName(ply)

        if data.JobNames[name] ~= true
        and not table.HasValue(data.JobNames, name) then
            return false
        end
    end

    if istable(data.SteamIDs)
    and next(data.SteamIDs) ~= nil then
        local id = ply:SteamID()

        if data.SteamIDs[id] ~= true
        and not table.HasValue(data.SteamIDs, id) then
            return false
        end
    end

    if istable(data.SteamID64s)
    and next(data.SteamID64s) ~= nil then
        local id64 = ply:SteamID64()

        if data.SteamID64s[id64] ~= true
        and not table.HasValue(data.SteamID64s, id64) then
            return false
        end
    end

    local minPlaytime = tonumber(data.MinPlaytimeSeconds) or 0

    if minPlaytime > 0 then
        local playtime = SimpleF4.Functions.GetPlaytime(ply)

        if not isnumber(playtime) or playtime < minPlaytime then
            return false
        end
    end

    local permissionCheck = data.CustomCheck or data.CanSee

    if isfunction(permissionCheck) then
        local ok, result = pcall(permissionCheck, ply)

        if not ok or result == false then
            return false
        end
    end

    return true
end


--=====================================================
-- CUSTOM PAGE API
--=====================================================

SimpleF4.Pages = SimpleF4.Pages or {}

function SimpleF4.RegisterPage(id, data)
    if not isstring(id) or id == "" or not istable(data) then
        return false
    end

    data.ID = id
    data.Label = data.Label or id
    data.Order = tonumber(data.Order) or 100

    SimpleF4.Pages[id] = data
    return true
end

function SimpleF4.GetPages()
    local pages = {}

    for id, data in pairs(SimpleF4.Pages or {}) do
        if data.Enabled ~= false then
            table.insert(pages, data)
        end
    end

    table.sort(pages, function(a, b)
        if a.Order == b.Order then
            return tostring(a.Label) < tostring(b.Label)
        end

        return a.Order < b.Order
    end)

    return pages
end


local F4_REF_W, F4_REF_H = 1920, 1080
local f4Scale = 1

local function ComputeF4Scale()
    return math.min(
        ScrW() / F4_REF_W,
        ScrH() / F4_REF_H,
        1
    )
end

function SimpleF4.Scale()
    return f4Scale
end

-- Convenience helper for all fixed UI measurements.
-- Example: SimpleF4.S(50) becomes 50px at 1080p,
-- 33px at 720p, and never scales above 1x.
function SimpleF4.S(value)
    return math.max(1, math.Round((tonumber(value) or 0) * f4Scale))
end

local function BuildFonts()
    local s = f4Scale * SimpleF4.GetTextScale()

    surface.CreateFont("SimpleF4.Title", {
        font = "Roboto",
        size = math.max(14, math.Round(28 * s)),
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("SimpleF4.Heading", {
        font = "Roboto",
        size = math.max(13, math.Round(22 * s)),
        weight = 700,
        antialias = true,
    })

    surface.CreateFont("SimpleF4.Body", {
        font = "Roboto",
        size = math.max(11, math.Round(16 * s)),
        weight = 400,
        antialias = true,
    })

    surface.CreateFont("SimpleF4.BodyBold", {
        font = "Roboto",
        size = math.max(11, math.Round(16 * s)),
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("SimpleF4.Small", {
        font = "Roboto",
        size = math.max(10, math.Round(14 * s)),
        weight = 400,
        antialias = true,
    })

    surface.CreateFont("SimpleF4.CardNumber", {
        font = "Roboto",
        size = math.max(16, math.Round(30 * s)),
        weight = 700,
        antialias = true,
    })
end

function SimpleF4.RebuildFonts()
    BuildFonts()
end

f4Scale = ComputeF4Scale()
BuildFonts()

hook.Add("OnScreenSizeChanged", "SimpleF4.ScreenScale", function()
    f4Scale = ComputeF4Scale()
    BuildFonts()
end)

local function getHeadPosition(ent)
    if not IsValid(ent) then return nil end

    local bone = ent:LookupBone("ValveBiped.Bip01_Head1")
        or ent:LookupBone("Bip01 Head")
        or ent:LookupBone("Head")

    if bone then
        local matrix = ent:GetBoneMatrix(bone)
        if matrix then
            return matrix:GetTranslation()
        end

        local pos = ent:GetBonePosition(bone)
        if pos and pos ~= vector_origin then
            return pos
        end
    end

    return nil
end

function SimpleF4.FitModelPanel(modelPanel, mode)
    if not IsValid(modelPanel) then return end

    local ent = modelPanel.Entity or modelPanel:GetEntity()
    if not IsValid(ent) then return end

    ent:SetIK(false)

    local mins, maxs = ent:GetRenderBounds()
    local width = math.max(math.abs(mins.x) + math.abs(maxs.x), math.abs(mins.y) + math.abs(maxs.y))
    local height = math.max(1, maxs.z - mins.z)
    local size = math.max(width, height)

    if mode == "portrait" then
        local headPos = getHeadPosition(ent)

        if not headPos then
            headPos = Vector(
                (mins.x + maxs.x) * 0.5,
                (mins.y + maxs.y) * 0.5,
                mins.z + height * 0.82
            )
        end

        -- Pull the list portrait camera back far enough to keep the whole
        -- head visible while still showing the shoulders/chest area.
        -- Pull the list portrait back a little so unusual/tall heads are not clipped.
        local lookAt = headPos + Vector(0, 0, -5)
        local camDist = math.max(50, height * 0.70)

        modelPanel:SetLookAt(lookAt)
        modelPanel:SetCamPos(lookAt + Vector(camDist, camDist * 0.10, 0))
        modelPanel:SetFOV(30)
    else
        -- Full-body preview: centre on the rendered bounds and leave generous
        -- vertical padding so the head and feet remain visible on different models.
        local lookAt = Vector(
            (mins.x + maxs.x) * 0.5,
            (mins.y + maxs.y) * 0.5,
            mins.z + height * 0.50
        )

        local camDist = math.max(size * 2.15, height * 1.18)

        modelPanel:SetLookAt(lookAt)
        modelPanel:SetCamPos(lookAt + Vector(camDist, camDist * 0.22, 0))
        modelPanel:SetFOV(28)
    end
end

function SimpleF4.ApplyModelPanel(modelPanel, modelPath, mode, yaw)
    if not IsValid(modelPanel) then return end

    modelPath = modelPath or "models/error.mdl"
    mode = mode or "portrait"
    yaw = yaw or (mode == "full" and 18 or 0)

    modelPanel:SetModel(modelPath)
    modelPanel:SetAnimated(false)
    modelPanel.LayoutEntity = function(_, ent)
        if not IsValid(ent) then return end
        ent:SetAngles(Angle(0, yaw, 0))
    end

    timer.Simple(0, function()
        if not IsValid(modelPanel) then return end
        SimpleF4.FitModelPanel(modelPanel, mode)
    end)
end



--=====================================================
-- SHARED HUD MODULE STYLE
--=====================================================

SimpleF4.HUDStyle = SimpleF4.HUDStyle or {}
local HUDStyle = SimpleF4.HUDStyle

function HUDStyle.Get()
    return SimpleF4.Config.ModuleUI or {}
end

function HUDStyle.DrawPanel(x, y, w, h, accent, alpha)
    local style = HUDStyle.Get()
    alpha = tonumber(alpha) or 255

    surface.SetDrawColor(
        SimpleF4.Config.Theme.Background.r,
        SimpleF4.Config.Theme.Background.g,
        SimpleF4.Config.Theme.Background.b,
        alpha
    )
    surface.DrawRect(x, y, w, h)

    if style.Border ~= false then
        surface.SetDrawColor(
            SimpleF4.Config.Theme.Line.r,
            SimpleF4.Config.Theme.Line.g,
            SimpleF4.Config.Theme.Line.b,
            alpha
        )
        surface.DrawOutlinedRect(x, y, w, h, 1)
    end

    local accentColour =
        accent or SimpleF4.Config.Theme.Accent

    surface.SetDrawColor(
        accentColour.r,
        accentColour.g,
        accentColour.b,
        alpha
    )
    surface.DrawRect(
        x,
        y,
        SimpleF4.S(
            tonumber(style.AccentWidth) or 3
        ),
        h
    )
end

function HUDStyle.DrawIcon(material, x, y, size, colour, shadow)
    local style = HUDStyle.Get()
    size = size or SimpleF4.S(
        tonumber(style.IconSize) or 16
    )

    surface.SetMaterial(material)

    if shadow ~= false then
        surface.SetDrawColor(
            0,
            0,
            0,
            tonumber(style.ShadowAlpha) or 190
        )
        surface.DrawTexturedRect(
            x + 1,
            y + 1,
            size,
            size
        )
    end

    surface.SetDrawColor(
        colour or color_white
    )
    surface.DrawTexturedRect(
        x,
        y,
        size,
        size
    )
end

function HUDStyle.DrawValueBar(
    x,
    y,
    w,
    h,
    fraction,
    colour
)
    fraction = math.Clamp(
        tonumber(fraction) or 0,
        0,
        1
    )

    surface.SetDrawColor(
        SimpleF4.Config.Theme.Surface2
    )
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(
        colour
        or SimpleF4.Config.Theme.Accent
    )
    surface.DrawRect(
        x,
        y,
        math.floor(w * fraction),
        h
    )
end


function SimpleF4.Notify(message, kind, duration)
    local payload

    if istable(message) then
        payload = table.Copy(message)
        payload.Text =
            tostring(
                payload.Text
                or payload.Message
                or ""
            )
        payload.Type =
            tostring(
                payload.Type
                or payload.Kind
                or "info"
            )
        payload.Duration =
            tonumber(
                payload.Duration
            ) or 4
    else
        payload = {
            Text = tostring(message or ""),
            Type = tostring(
                kind or "info"
            ),
            Duration =
                tonumber(duration) or 4,
        }
    end

    local override = hook.Run(
        "SimpleF4_Notification",
        payload,
        payload.Text,
        payload.Type,
        payload.Duration
    )

    if override == false then
        return
    end

    if SimpleF4.PushNotification then
        return SimpleF4.PushNotification(
            payload
        )
    end

    local notificationType = 0

    if payload.Type == "error" then
        notificationType = 1
    elseif payload.Type == "warning" then
        notificationType = 3
    end

    if DarkRP and DarkRP.notify then
        DarkRP.notify(
            LocalPlayer(),
            notificationType,
            payload.Duration,
            payload.Title
                and (
                    tostring(payload.Title)
                    .. ": "
                    .. payload.Text
                )
                or payload.Text
        )
        return
    end

    if notification
    and notification.AddLegacy then
        notification.AddLegacy(
            payload.Text,
            notificationType == 1
                and NOTIFY_ERROR
                or NOTIFY_GENERIC,
            payload.Duration
        )
        return
    end

    chat.AddText(
        notificationType == 1
            and Color(220, 80, 80)
            or Color(220, 220, 220),
        "[SimpleF4] ",
        color_white,
        payload.Text
    )
end


--=====================================================
-- KEYBOARD SHORTCUTS
--=====================================================



function SimpleF4.Close(instant)
    SimpleF4.DebugPrint("Closing menu.")

    net.Start("SimpleF4.MenuState")
    net.WriteBool(false)
    net.SendToServer()

    if SimpleF4.CloseContextMenu then
        SimpleF4.CloseContextMenu()
    end

    local frame = SimpleF4.Frame

    if not IsValid(frame) then
        SimpleF4.Frame = nil
        gui.EnableScreenClicker(false)
        return
    end

    if frame.SimpleF4Closing then return end
    frame.SimpleF4Closing = true

    gui.EnableScreenClicker(false)
    frame:SetMouseInputEnabled(false)
    frame:SetKeyboardInputEnabled(false)

    if instant == true or SimpleF4.ReduceMotion() then
        frame:Remove()
        SimpleF4.Frame = nil
        return
    end

    local x, y = frame:GetPos()

    frame:AlphaTo(0, 0.13, 0)
    frame:MoveTo(x, y + S(14), 0.13, 0, 0.2, function()
        if IsValid(frame) then
            frame:Remove()
        end

        if SimpleF4.Frame == frame then
            SimpleF4.Frame = nil
        end
    end)
end

function SimpleF4.Open()
    SimpleF4.DebugPrint("Opening menu.")
    if IsValid(SimpleF4.Frame) then
        SimpleF4.Close()
        return
    end

    SimpleF4.Frame = vgui.Create("SimpleF4.Main")
    SimpleF4.Frame:MakePopup()

    net.Start("SimpleF4.MenuState")
    net.WriteBool(true)
    net.SendToServer()
    SimpleF4.Frame:SetKeyboardInputEnabled(true)
    SimpleF4.Frame:SetMouseInputEnabled(true)
    gui.EnableScreenClicker(true)
end

net.Receive("SimpleF4_RequestOpen", function()
    SimpleF4.Open()
end)

hook.Add("ShowSpare2", "SimpleF4.OverrideF4", function()
    SimpleF4.Open()
    return true
end)

hook.Add("DarkRPFinishedLoading", "SimpleF4.OverrideDarkRPMethod", function()
    timer.Simple(0, function()
        if not GAMEMODE then return end

        function GAMEMODE:ShowSpare2()
            SimpleF4.Open()
        end
    end)
end)

if C.CloseOnJobChange then
    hook.Add("OnPlayerChangedTeam", "SimpleF4.CloseOnJobChange", function(ply)
        if ply == LocalPlayer() then
            SimpleF4.Close()
        end
    end)
end

--=====================================================
-- UI HELPERS
--=====================================================

function SimpleF4.DrawHighlightedText(value, query, font, x, y, normalCol, highlightCol)
    value = tostring(value or "")
    query = tostring(query or "")

    if query == "" then
        draw.SimpleText(value, font, x, y, normalCol)
        return
    end

    local lowerValue = string.lower(value)
    local lowerQuery = string.lower(query)
    local from = 1
    local drawX = x

    surface.SetFont(font)

    while true do
        local foundStart, foundEnd = string.find(
            lowerValue,
            lowerQuery,
            from,
            true
        )

        if not foundStart then
            local tail = string.sub(value, from)

            if tail ~= "" then
                draw.SimpleText(tail, font, drawX, y, normalCol)
            end

            break
        end

        local before = string.sub(value, from, foundStart - 1)

        if before ~= "" then
            draw.SimpleText(before, font, drawX, y, normalCol)
            drawX = drawX + surface.GetTextSize(before)
        end

        local matched = string.sub(value, foundStart, foundEnd)
        draw.SimpleText(matched, font, drawX, y, highlightCol)
        drawX = drawX + surface.GetTextSize(matched)

        from = foundEnd + 1
    end
end



function SimpleF4.AttachTooltip(panel, textOrFunction)
    if not SimpleF4.GetUserSetting("Tooltips") then
        return
    end

    if not IsValid(panel) then return end

    local function removeTooltip(pnl)
        if IsValid(pnl.SimpleF4Tooltip) then
            pnl.SimpleF4Tooltip:Remove()
        end
    end

    local function wrapLine(line, maxTextWidth)
        surface.SetFont("SimpleF4.Small")

        if surface.GetTextSize(line) <= maxTextWidth then
            return {line}
        end

        local words = string.Explode(" ", line, false)
        local rows = {}
        local current = ""

        for _, word in ipairs(words) do
            local candidate =
                current == ""
                and word
                or (current .. " " .. word)

            if surface.GetTextSize(candidate) <= maxTextWidth then
                current = candidate
            else
                if current ~= "" then
                    table.insert(rows, current)
                end

                current = word
            end
        end

        if current ~= "" then
            table.insert(rows, current)
        end

        return rows
    end

    panel.OnCursorEntered = function(pnl)
        removeTooltip(pnl)

        local value = isfunction(textOrFunction)
            and textOrFunction()
            or textOrFunction

        value = string.Trim(tostring(value or ""))

        if value == "" then return end

        local maxWidth = S(390)
        local minWidth = S(190)
        local padX = S(14)
        local padY = S(11)
        local maxTextWidth = maxWidth - (padX * 2)

        local rawLines = string.Explode("\n", value, false)
        local lines = {}

        for _, rawLine in ipairs(rawLines) do
            local wrapped = wrapLine(rawLine, maxTextWidth)

            for _, wrappedLine in ipairs(wrapped) do
                table.insert(lines, wrappedLine)
            end
        end

        surface.SetFont("SimpleF4.Small")

        local widest = 0

        for _, line in ipairs(lines) do
            widest = math.max(widest, surface.GetTextSize(line))
        end

        local width = math.Clamp(
            widest + (padX * 2),
            minWidth,
            maxWidth
        )

        local lineHeight = S(19)
        local height = math.max(
            S(42),
            padY * 2 + (#lines * lineHeight)
        )

        local tip = vgui.Create("DPanel")
        pnl.SimpleF4Tooltip = tip

        tip:SetDrawOnTop(true)
        tip:SetMouseInputEnabled(false)
        tip:SetKeyboardInputEnabled(false)
        tip:SetSize(width, height)
        tip:SetAlpha(0)
        tip:AlphaTo(255, 0.08, 0)

        tip.Paint = function(_, w, h)
            surface.SetDrawColor(SimpleF4.Config.Theme.Surface2)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(SimpleF4.Config.Theme.Line)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            surface.SetDrawColor(SimpleF4.Config.Theme.Accent)
            surface.DrawRect(0, 0, S(3), h)

            local y = padY

            for _, line in ipairs(lines) do
                draw.SimpleText(
                    line,
                    "SimpleF4.Small",
                    padX,
                    y,
                    SimpleF4.Config.Theme.Text,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_TOP
                )

                y = y + lineHeight
            end
        end

        tip.Think = function(self)
            if not IsValid(pnl) or not pnl:IsHovered() then
                self:Remove()
                return
            end

            local mx, my = gui.MousePos()

            local x = math.min(
                mx + S(14),
                ScrW() - self:GetWide() - S(8)
            )

            local y = math.min(
                my + S(16),
                ScrH() - self:GetTall() - S(8)
            )

            x = math.max(S(8), x)
            y = math.max(S(8), y)

            self:SetPos(x, y)
            self:MoveToFront()
        end
    end

    local oldExit = panel.OnCursorExited

    panel.OnCursorExited = function(pnl)
        if oldExit then oldExit(pnl) end
        removeTooltip(pnl)
    end
end

function SimpleF4.OpenInputPrompt(title, prompt, placeholder, callback)
    local frame = vgui.Create("DFrame")
    frame:SetSize(S(440), S(190))
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)

    frame.Paint = function(_, w, h)
        surface.SetDrawColor(SimpleF4.Config.Theme.Surface)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(SimpleF4.Config.Theme.Accent)
        surface.DrawRect(0, 0, w, S(3))

        draw.SimpleText(
            tostring(title or "Input"),
            "SimpleF4.Heading",
            S(18),
            S(16),
            SimpleF4.Config.Theme.Text
        )

        draw.SimpleText(
            tostring(prompt or ""),
            "SimpleF4.Small",
            S(18),
            S(51),
            SimpleF4.Config.Theme.Muted
        )
    end

    local input = vgui.Create("DTextEntry", frame)
    input:SetPos(S(18), S(82))
    input:SetSize(S(404), S(38))
    input:SetFont("SimpleF4.Body")
    input:SetPlaceholderText(placeholder or "")
    input:RequestFocus()

    local cancel = vgui.Create("DButton", frame)
    cancel:SetPos(S(18), S(134))
    cancel:SetSize(S(122), S(38))
    cancel:SetText("Cancel")
    cancel.DoClick = function()
        frame:Remove()
    end

    local confirm = vgui.Create("DButton", frame)
    confirm:SetPos(S(300), S(134))
    confirm:SetSize(S(122), S(38))
    confirm:SetText("Confirm")

    local function submit()
        local value = string.Trim(input:GetValue() or "")
        if value == "" then return end

        if callback then callback(value) end
        frame:Remove()
    end

    confirm.DoClick = submit
    input.OnEnter = submit
end


function SimpleF4.ExecuteQuickAction(action, inputValue)
    if not istable(action) then return end

    local actionType = string.lower(action.Type or "command")
    local value = tostring(action.Value or "")

    if action.Input then
        value = tostring(action.Prefix or "")
            .. tostring(inputValue or "")
    end

    if actionType == "url" then
        gui.OpenURL(value)
        return
    end

    if actionType == "chat" then
        RunConsoleCommand("say", value)
        SimpleF4.Notify(
            (action.Name or "Action") .. " used.",
            "success"
        )
        return
    end

    if actionType == "command" and value ~= "" then
        LocalPlayer():ConCommand(value)

        SimpleF4.Notify(
            (action.Name or "Action") .. " used.",
            "success"
        )
    end
end

function SimpleF4.OpenQuickAction(action)
    if not istable(action) then return end

    -- Keep the action UI separate from the F4 menu.
    SimpleF4.Close()

    timer.Simple(0, function()
        local frame = vgui.Create("DFrame")
        frame:SetSize(S(460), action.Input and S(220) or S(178))
        frame:Center()
        frame:MakePopup()
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:SetDraggable(false)

        frame.Paint = function(_, w, h)
            surface.SetDrawColor(SimpleF4.Config.Theme.Background)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(SimpleF4.Config.Theme.Surface)
            surface.DrawRect(0, 0, w, S(60))

            surface.SetDrawColor(SimpleF4.Config.Theme.Accent)
            surface.DrawRect(0, 0, S(4), S(60))

            draw.SimpleText(
                tostring(action.Name or SimpleF4.L("QuickActionTitle")),
                "SimpleF4.Heading",
                S(18),
                S(18),
                SimpleF4.Config.Theme.Text
            )

            draw.SimpleText(
                tostring(
                    action.Prompt
                    or action.Description
                    or SimpleF4.L("QuickActionDefaultPrompt")
                ),
                "SimpleF4.Small",
                S(18),
                S(75),
                SimpleF4.Config.Theme.Muted
            )
        end

        local input

        if action.Input then
            input = vgui.Create("DTextEntry", frame)
            input:SetPos(S(18), S(106))
            input:SetSize(S(424), S(40))
            input:SetFont("SimpleF4.Body")
            input:SetTextColor(SimpleF4.Config.Theme.Text)
            input:SetPlaceholderColor(SimpleF4.Config.Theme.Muted)
            input:SetPlaceholderText(action.Placeholder or "")
            input:SetDrawBackground(false)

            input.Paint = function(entry, w, h)
                surface.SetDrawColor(SimpleF4.Config.Theme.Surface)
                surface.DrawRect(0, 0, w, h)

                surface.SetDrawColor(SimpleF4.Config.Theme.Line)
                surface.DrawOutlinedRect(0, 0, w, h, 1)

                entry:DrawTextEntryText(
                    SimpleF4.Config.Theme.Text,
                    SimpleF4.Config.Theme.Accent,
                    SimpleF4.Config.Theme.Text
                )
            end

            input:RequestFocus()
        end

        local cancel = vgui.Create("DButton", frame)
        cancel:SetPos(
            S(18),
            action.Input and S(162) or S(120)
        )
        cancel:SetSize(S(150), S(40))
        cancel:SetText("")

        cancel.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and SimpleF4.Config.Theme.SurfaceHover
                or SimpleF4.Config.Theme.Surface
            )
            surface.DrawRect(0, 0, w, h)

            draw.SimpleText(
                "CANCEL",
                "SimpleF4.BodyBold",
                w / 2,
                h / 2,
                SimpleF4.Config.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        cancel.DoClick = function()
            frame:Remove()
        end

        local confirm = vgui.Create("DButton", frame)
        confirm:SetPos(
            S(292),
            action.Input and S(162) or S(120)
        )
        confirm:SetSize(S(150), S(40))
        confirm:SetText("")

        confirm.Paint = function(btn, w, h)
            surface.SetDrawColor(
                btn:IsHovered()
                and SimpleF4.Config.Theme.AccentSoft
                or SimpleF4.Config.Theme.Accent
            )
            surface.DrawRect(0, 0, w, h)

            draw.SimpleText(
                action.ConfirmText or "CONFIRM",
                "SimpleF4.BodyBold",
                w / 2,
                h / 2,
                SimpleF4.Config.Theme.Text,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER
            )
        end

        local function submit()
            local inputValue = nil

            if action.Input then
                inputValue = string.Trim(input:GetValue() or "")
                if inputValue == "" then
                    SimpleF4.Notify(
                        SimpleF4.L("PleaseEnterValue"),
                        "warning"
                    )
                    return
                end
            end

            SimpleF4.ExecuteQuickAction(action, inputValue)
            frame:Remove()
        end

        confirm.DoClick = submit

        if IsValid(input) then
            input.OnEnter = submit
        end
    end)
end


SimpleF4.PurchaseCooldowns = SimpleF4.PurchaseCooldowns or {}

function SimpleF4.StartPurchaseCooldown(kind, key, seconds)
    seconds = tonumber(seconds) or 0
    if seconds <= 0 then return end

    SimpleF4.PurchaseCooldowns[kind .. ":" .. tostring(key)] =
        CurTime() + seconds
end

function SimpleF4.GetPurchaseCooldown(kind, key)
    local expires = SimpleF4.PurchaseCooldowns[
        kind .. ":" .. tostring(key)
    ]

    if not expires then return 0 end

    local remaining = expires - CurTime()

    if remaining <= 0 then
        SimpleF4.PurchaseCooldowns[
            kind .. ":" .. tostring(key)
        ] = nil
        return 0
    end

    return remaining
end






function SimpleF4.RefreshPermissionPreview()
    if not IsValid(SimpleF4.Frame) then return end

    local activePage = SimpleF4.Frame.ActivePage

    SimpleF4.Frame:Remove()
    SimpleF4.Frame = nil
    gui.EnableScreenClicker(false)

    timer.Simple(0, function()
        SimpleF4.Frame = vgui.Create("SimpleF4.Main")
        SimpleF4.Frame:MakePopup()
        SimpleF4.Frame:SetKeyboardInputEnabled(true)
        SimpleF4.Frame:SetMouseInputEnabled(true)
        gui.EnableScreenClicker(true)

        if activePage
        and SimpleF4.Frame.PageButtons
        and SimpleF4.Frame.PageButtons[activePage]
        and not (
            SimpleF4.Frame.PageButtons[activePage].Data
            and SimpleF4.Frame.PageButtons[activePage].Data.SimpleF4Locked
        ) then
            SimpleF4.Frame:OpenPage(activePage)
        end
    end)
end



function SimpleF4.ExecuteLinkAction(data)
    if not istable(data) then return end
    if not SimpleF4.NavItemAllowed(data, LocalPlayer()) then return end

    local actionType = string.lower(data.Type or "url")
    local value = tostring(data.Value or "")

    if actionType == "url" then
        if value ~= "" then gui.OpenURL(value) end
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


function SimpleF4.IsAnnouncementRead(item)
    if not istable(item) then return true end

    local id = tostring(item.SimpleF4ID or item.ID or "")
    if id == "" then return true end

    return cookie.GetString(
        "simplef4_announcement_read_" .. id,
        "0"
    ) == "1"
end

function SimpleF4.MarkAnnouncementRead(item)
    if not istable(item) then return end

    local id = tostring(item.SimpleF4ID or item.ID or "")
    if id == "" then return end

    cookie.Set(
        "simplef4_announcement_read_" .. id,
        "1"
    )

    hook.Run("SimpleF4_AnnouncementRead", id, item)
end

function SimpleF4.MarkAllAnnouncementsRead()
    for _, item in ipairs(
        F.GetVisibleAnnouncements(LocalPlayer(), true)
    ) do
        SimpleF4.MarkAnnouncementRead(item)
    end
end

function SimpleF4.GetUnreadAnnouncementCount(includeDismissed)
    local count = 0

    for _, item in ipairs(
        F.GetVisibleAnnouncements(
            LocalPlayer(),
            includeDismissed == true
        )
    ) do
        if not SimpleF4.IsAnnouncementRead(item) then
            count = count + 1
        end
    end

    return count
end

local function announcementDateBucket(timestamp)
    timestamp = tonumber(timestamp) or 0

    if timestamp <= 0 then
        return SimpleF4.L("Earlier"), 0
    end

    local now = os.time()
    local today = os.date("*t", now)
    local itemDate = os.date("*t", timestamp)

    local todayStart = os.time({
        year = today.year,
        month = today.month,
        day = today.day,
        hour = 0,
        min = 0,
        sec = 0,
    })

    local itemStart = os.time({
        year = itemDate.year,
        month = itemDate.month,
        day = itemDate.day,
        hour = 0,
        min = 0,
        sec = 0,
    })

    local dayDiff = math.floor((todayStart - itemStart) / 86400)

    if dayDiff == 0 then
        return SimpleF4.L("Today"), itemStart
    elseif dayDiff == 1 then
        return SimpleF4.L("Yesterday"), itemStart
    end

    return os.date("%d %B %Y", timestamp), itemStart
end

function SimpleF4.DismissAnnouncement(item)
    if not istable(item) or item.Dismissible ~= true then return end

    local id = tostring(item.SimpleF4ID or item.ID or "")
    if id == "" then return end

    cookie.Set("simplef4_announcement_" .. id, "1")
    hook.Run("SimpleF4_AnnouncementDismissed", id, item)
end

function SimpleF4.OpenAnnouncementHistory(skipClose)
    if skipClose ~= true and IsValid(SimpleF4.Frame) then
        SimpleF4.Close(true)

        timer.Simple(0, function()
            SimpleF4.OpenAnnouncementHistory(true)
        end)

        return
    end

    if IsValid(SimpleF4.AnnouncementHistory) then
        SimpleF4.AnnouncementHistory:Remove()
    end

    local frame = vgui.Create("DFrame")
    SimpleF4.AnnouncementHistory = frame
    frame:SetSize(S(780), S(620))
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()

    local items = F.GetVisibleAnnouncements(
        LocalPlayer(),
        true
    )

    local unreadCount =
        SimpleF4.GetUnreadAnnouncementCount(true)

    frame.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Accent)
        surface.DrawRect(0, 0, S(4), h)

        draw.SimpleText(
            SimpleF4.L("AnnouncementHistory"),
            "SimpleF4.Heading",
            S(20),
            S(16),
            C.Theme.Text
        )

        draw.SimpleText(
            tostring(#items)
                .. " announcements"
                .. "  •  "
                .. tostring(unreadCount)
                .. " unread",
            "SimpleF4.Small",
            S(20),
            S(43),
            C.Theme.Muted
        )

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawRect(
            S(18),
            S(66),
            w - S(36),
            1
        )
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(S(40), S(32))
    close:SetPos(frame:GetWide() - S(52), S(14))
    close:SetText("")

    close.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.Danger
            or C.Theme.Surface2
        )
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText(
            "X",
            "SimpleF4.BodyBold",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    close.DoClick = function()
        frame:Remove()
    end

    local markAll = vgui.Create("DButton", frame)
    markAll:SetSize(S(130), S(30))
    markAll:SetPos(
        frame:GetWide() - S(196),
        S(15)
    )
    markAll:SetText("")
    markAll:SetCursor("hand")
    markAll:SetVisible(unreadCount > 0)

    markAll.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered()
            and C.Theme.SurfaceHover
            or C.Theme.Surface2
        )
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText(
            SimpleF4.L("MarkAllRead"),
            "SimpleF4.Small",
            w / 2,
            h / 2,
            btn:IsHovered()
                and C.Theme.Text
                or C.Theme.Muted,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    markAll.DoClick = function()
        SimpleF4.MarkAllAnnouncementsRead()
        frame:Remove()

        timer.Simple(0, function()
            SimpleF4.OpenAnnouncementHistory(true)
        end)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    SimpleF4.StyleScrollPanel(scroll)
    scroll:SetPos(S(18), S(78))
    scroll:SetSize(
        frame:GetWide() - S(36),
        frame:GetTall() - S(96)
    )

    if #items == 0 then
        local empty = vgui.Create("DPanel", scroll)
        empty:Dock(TOP)
        empty:SetTall(S(90))

        empty.Paint = function(_, w, h)
            draw.SimpleText(
                SimpleF4.L("NoAnnouncements"),
                "SimpleF4.Body",
                S(14),
                h / 2,
                C.Theme.Muted,
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end

        return
    end

    local lastBucket

    for _, item in ipairs(items) do
        local bucket =
            announcementDateBucket(
                item.SimpleF4PublishedAt
            )

        if bucket ~= lastBucket then
            lastBucket = bucket

            local header = vgui.Create("DPanel", scroll)
            header:Dock(TOP)
            header:SetTall(S(34))
            header:DockMargin(0, S(6), 0, S(4))

            header.Paint = function(_, w, h)
                draw.SimpleText(
                    bucket,
                    "SimpleF4.BodyBold",
                    S(4),
                    h / 2,
                    C.Theme.Accent,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )

                surface.SetDrawColor(C.Theme.Line)
                surface.DrawRect(
                    S(120),
                    h / 2,
                    w - S(120),
                    1
                )
            end
        end

        local unread =
            not SimpleF4.IsAnnouncementRead(item)

        local row = vgui.Create("DButton", scroll)
        row:Dock(TOP)
        row:SetTall(S(118))
        row:DockMargin(0, 0, 0, S(8))
        row:SetText("")
        row:SetCursor("hand")

        row.Paint = function(btn, w, h)
            local accent =
                item.Color or C.Theme.Accent

            surface.SetDrawColor(
                btn:IsHovered()
                and C.Theme.SurfaceHover
                or C.Theme.Surface
            )
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(
                unread and accent or C.Theme.Line
            )
            surface.DrawRect(
                0,
                0,
                unread and S(4) or S(2),
                h
            )

            local badgeText =
                tostring(item.Badge or "NEWS")

            draw.SimpleText(
                badgeText,
                "SimpleF4.Small",
                S(16),
                S(13),
                accent
            )

            local badgeX = S(18)
            surface.SetFont("SimpleF4.Small")
            badgeX = badgeX
                + surface.GetTextSize(badgeText)
                + S(14)

            if item.Pinned == true then
                draw.SimpleText(
                    SimpleF4.L("Pinned"),
                    "SimpleF4.Small",
                    badgeX,
                    S(13),
                    C.Theme.Warning
                )

                surface.SetFont("SimpleF4.Small")
                badgeX = badgeX
                    + surface.GetTextSize(SimpleF4.L("Pinned"))
                    + S(14)
            end

            if unread then
                draw.SimpleText(
                    SimpleF4.L("New"),
                    "SimpleF4.Small",
                    badgeX,
                    S(13),
                    C.Theme.Success
                )
            end

            local timestamp =
                tonumber(item.SimpleF4PublishedAt) or 0

            if timestamp > 0 then
                draw.SimpleText(
                    os.date("%d/%m/%Y  %H:%M", timestamp),
                    "SimpleF4.Small",
                    w - S(16),
                    S(13),
                    C.Theme.Muted,
                    TEXT_ALIGN_RIGHT
                )
            end

            draw.SimpleText(
                tostring(
                    item.Title
                    or "Announcement"
                ),
                "SimpleF4.BodyBold",
                S(16),
                S(39),
                C.Theme.Text
            )

            draw.SimpleText(
                F.CleanText(
                    tostring(item.Text or ""),
                    112
                ),
                "SimpleF4.Small",
                S(16),
                S(68),
                C.Theme.Muted
            )

            if item.SimpleF4Dismissed then
                draw.SimpleText(
                    SimpleF4.L("HiddenLabel"),
                    "SimpleF4.Small",
                    w - S(16),
                    h - S(18),
                    C.Theme.Warning,
                    TEXT_ALIGN_RIGHT,
                    TEXT_ALIGN_CENTER
                )
            elseif item.Dismissible == true then
                draw.SimpleText(
                    SimpleF4.L("ClickToMarkRead"),
                    "SimpleF4.Small",
                    S(16),
                    h - S(18),
                    C.Theme.Muted,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )
            end
        end

        row.DoClick = function()
            if unread then
                SimpleF4.MarkAnnouncementRead(item)
                frame:Remove()

                timer.Simple(0, function()
                    SimpleF4.OpenAnnouncementHistory(true)
                end)
            end
        end

        if item.Dismissible == true
        and not item.SimpleF4Dismissed then
            local hide = vgui.Create("DButton", row)
            hide:Dock(RIGHT)
            hide:SetWide(S(86))
            hide:DockMargin(
                0,
                S(72),
                S(12),
                S(14)
            )
            hide:SetText("")
            hide:SetCursor("hand")

            hide.Paint = function(btn, w, h)
                surface.SetDrawColor(
                    btn:IsHovered()
                    and C.Theme.SurfaceHover
                    or C.Theme.Surface2
                )
                surface.DrawRect(0, 0, w, h)

                draw.SimpleText(
                    SimpleF4.L("Dismiss"),
                    "SimpleF4.Small",
                    w / 2,
                    h / 2,
                    C.Theme.Text,
                    TEXT_ALIGN_CENTER,
                    TEXT_ALIGN_CENTER
                )
            end

            hide.DoClick = function()
                SimpleF4.MarkAnnouncementRead(item)
                SimpleF4.DismissAnnouncement(item)
                frame:Remove()

                timer.Simple(0, function()
                    SimpleF4.OpenAnnouncementHistory(true)
                end)
            end
        end
    end
end


--=====================================================
-- PERFORMANCE / DEBUG STATS
--=====================================================

SimpleF4.PerformanceStats = SimpleF4.PerformanceStats or {}

function SimpleF4.RecordPerformance(pageID, startedAt, visibleCount, totalCount)
    SimpleF4.PerformanceStats[pageID] = {
        Milliseconds = math.max(
            0,
            (SysTime() - startedAt) * 1000
        ),
        Visible = tonumber(visibleCount) or 0,
        Total = tonumber(totalCount) or 0,
        RecordedAt = RealTime(),
    }
end


--=====================================================
-- CONFIG INSPECTOR
--=====================================================

function SimpleF4.OpenConfigInspector(kind, data, id)
    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:IsSuperAdmin() then
        return
    end

    if IsValid(SimpleF4.ConfigInspector) then
        SimpleF4.ConfigInspector:Remove()
    end

    local frame = vgui.Create("DFrame")
    SimpleF4.ConfigInspector = frame
    frame:SetSize(S(700), S(600))
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()

    frame.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Background)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Accent)
        surface.DrawRect(0, 0, S(4), h)

        draw.SimpleText(
            SimpleF4.L("ConfigInspectorTitle"),
            "SimpleF4.Heading",
            S(18),
            S(16),
            C.Theme.Text
        )
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(S(40), S(32))
    close:SetPos(frame:GetWide() - S(52), S(12))
    close:SetText("")

    close.Paint = function(btn, w, h)
        surface.SetDrawColor(
            btn:IsHovered() and C.Theme.Danger or C.Theme.Surface2
        )
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText(
            "X",
            "SimpleF4.BodyBold",
            w / 2,
            h / 2,
            C.Theme.Text,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
    end

    close.DoClick = function()
        frame:Remove()
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    SimpleF4.StyleScrollPanel(scroll)
    scroll:SetPos(S(18), S(60))
    scroll:SetSize(
        frame:GetWide() - S(36),
        frame:GetTall() - S(78)
    )

    local rows = {}

    local function section(title)
        table.insert(rows, {
            Section = tostring(title),
        })
    end

    local function push(label, value, colour)
        table.insert(rows, {
            Label = tostring(label),
            Value = tostring(value),
            Colour = colour or C.Theme.Text,
        })
    end

    kind = tostring(kind or "General")

    local configKind =
        kind == "Job" and "Jobs"
        or kind == "Entity" and "Entities"
        or kind == "Weapon" and "Weapons"
        or kind

    section(SimpleF4.L("InspectorOverview"))
    push(SimpleF4.L("InspectorKind"), kind)

    local preview = F.GetPermissionPreview(ply)

    if preview then
        push(
            SimpleF4.L("InspectorPermissionPreview"),
            "ON • Team "
                .. tostring(preview.TeamID)
                .. " • "
                .. tostring(preview.UserGroup),
            C.Theme.Warning
        )
    else
        push(SimpleF4.L("InspectorPermissionPreview"), "OFF", C.Theme.Muted)
    end

    local maintenanceBlocked, maintenanceReason =
        F.IsMaintenanceBlocked(ply)

    push(
        SimpleF4.L("InspectorMaintenance"),
        maintenanceBlocked
            and ("BLOCKED • " .. tostring(maintenanceReason or ""))
            or (
                C.Maintenance
                and C.Maintenance.Enabled
                and "ENABLED • superadmin bypass"
                or "OFF"
            ),
        maintenanceBlocked and C.Theme.Warning or C.Theme.Muted
    )

    if kind == "General" then
        push("Version", SimpleF4.Version or "unknown")
        push(SimpleF4.L("InspectorServerTheme"), C.ThemePreset or "Custom")
        push(SimpleF4.L("InspectorYourTheme"), SimpleF4.GetThemePreset())
        push(SimpleF4.L("InspectorDensity"), SimpleF4.GetDensity())
        push(SimpleF4.L("InspectorJobsConfigured"), table.Count(RPExtraTeams or {}))
        push(SimpleF4.L("InspectorEntitiesConfigured"), table.Count(DarkRPEntities or {}))
        push(SimpleF4.L("InspectorShipmentsConfigured"), table.Count(CustomShipments or {}))

        section(SimpleF4.L("InspectorPerformance"))

        for _, pageID in ipairs({
            "Jobs",
            "Entities",
            "Weapons",
        }) do
            local stat = SimpleF4.PerformanceStats[pageID]

            if stat then
                push(
                    pageID,
                    string.format(
                        "%.2f ms • %d / %d visible",
                        stat.Milliseconds or 0,
                        stat.Visible or 0,
                        stat.Total or 0
                    )
                )
            else
                push(pageID, SimpleF4.L("InspectorNoBuild"), C.Theme.Muted)
            end
        end
    else
        push(SimpleF4.L("InspectorDisplayName"), F.GetDisplayName(configKind, data, id))
        push(SimpleF4.L("InspectorOriginalName"), data and data.name or "-")
        push(SimpleF4.L("InspectorIdentifier"), id or "-")
        push(SimpleF4.L("InspectorCategory"), data and data.category or "-")

        section(SimpleF4.L("InspectorPermissions"))

        if configKind == "Jobs" then
            local hidden = F.IsJobHidden(id, data, ply)
            local visible, allowed, reason =
                F.JobAccessState(data, id, ply)

            push(SimpleF4.L("InspectorHidden"), hidden and "YES" or "NO")
            push(SimpleF4.L("InspectorVisible"), visible and "YES" or "NO")
            push(SimpleF4.L("InspectorAllowed"), allowed and "YES" or "NO")
            push(SimpleF4.L("InspectorReason"), reason or "-")
        elseif configKind == "Entities" then
            local hidden = F.IsEntityHidden(data, ply)
            local allowed, reason = F.EntityAccessState(data, ply)

            push(SimpleF4.L("InspectorHidden"), hidden and "YES" or "NO")
            push(SimpleF4.L("InspectorAllowed"), allowed and "YES" or "NO")
            push(SimpleF4.L("InspectorReason"), reason or "-")
        elseif configKind == "Weapons" then
            local hidden = F.IsWeaponHidden(data, ply)
            local allowed, reason = F.ShipmentAccessState(data, ply)

            push(SimpleF4.L("InspectorHidden"), hidden and "YES" or "NO")
            push(SimpleF4.L("InspectorAllowed"), allowed and "YES" or "NO")
            push(SimpleF4.L("InspectorReason"), reason or "-")
        end

        if data and data.category then
            local ca, cr = F.CategoryAccessState(
                configKind,
                data.category,
                ply
            )

            push(
                SimpleF4.L("InspectorCategoryPermission"),
                ca and "ALLOWED" or "LOCKED",
                ca and C.Theme.Success or C.Theme.Warning
            )
            push(SimpleF4.L("InspectorCategoryReason"), cr or "-")

            section(SimpleF4.L("InspectorCategory"))
            push(
                SimpleF4.L("InspectorDisplayedCategory"),
                F.GetCategoryDisplayName(
                    configKind,
                    data.category
                )
            )
            push(
                SimpleF4.L("InspectorCategoryOrder"),
                F.GetCategoryOrder(
                    configKind,
                    data.category
                )
            )
            push(
                SimpleF4.L("InspectorDescription"),
                F.GetCategoryDescription(
                    configKind,
                    data.category
                ) or "-"
            )

            local icon, _, iconSize =
                F.GetCategoryIcon(
                    configKind,
                    data.category
                )

            push(SimpleF4.L("InspectorIcon"), icon or "-")
            push(SimpleF4.L("InspectorIconSize"), iconSize or 16)
        end

        section(SimpleF4.L("InspectorDisplaySearch"))
        push(
            SimpleF4.L("InspectorItemOrder"),
            F.GetItemOrder(configKind, data, id)
        )
        push(
            SimpleF4.L("InspectorSearchAliases"),
            F.GetSearchAliases(configKind, data, id)
        )

        local explanation =
            F.GetPermissionExplanation(
                configKind,
                data,
                id,
                ply
            )

        if #explanation > 0 then
            section(SimpleF4.L("InspectorExplanation"))

            for index, line in ipairs(explanation) do
                push(
                    "Requirement " .. tostring(index),
                    line,
                    string.StartWith(line, "OK")
                        and C.Theme.Success
                        or C.Theme.Warning
                )
            end
        end
    end

    for _, info in ipairs(rows) do
        local row = vgui.Create("DPanel", scroll)
        row:Dock(TOP)

        if info.Section then
            row:SetTall(S(36))
            row:DockMargin(0, S(8), 0, S(4))

            row.Paint = function(_, w, h)
                draw.SimpleText(
                    info.Section,
                    "SimpleF4.BodyBold",
                    S(4),
                    h / 2,
                    C.Theme.Accent,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )

                surface.SetDrawColor(C.Theme.Line)
                surface.DrawRect(S(190), h / 2, w - S(190), 1)
            end
        else
            row:SetTall(S(38))
            row:DockMargin(0, 0, 0, S(4))

            row.Paint = function(_, w, h)
                surface.SetDrawColor(C.Theme.Surface)
                surface.DrawRect(0, 0, w, h)

                draw.SimpleText(
                    info.Label,
                    "SimpleF4.Small",
                    S(12),
                    h / 2,
                    C.Theme.Muted,
                    TEXT_ALIGN_LEFT,
                    TEXT_ALIGN_CENTER
                )

                draw.SimpleText(
                    info.Value,
                    "SimpleF4.BodyBold",
                    w - S(12),
                    h / 2,
                    info.Colour,
                    TEXT_ALIGN_RIGHT,
                    TEXT_ALIGN_CENTER
                )
            end
        end
    end
end

function SimpleF4.GetBadgeWidth(badge)
    local width = S(8)

    if badge.Icon and badge.Icon ~= "" then
        width = width + S(18)
    end

    surface.SetFont("SimpleF4.Small")
    width = width + surface.GetTextSize(tostring(badge.Text or ""))
    return width
end

function SimpleF4.DrawBadge(badge, x, y)
    local startX = x

    if badge.Icon and badge.Icon ~= "" then
        local mat = Material(badge.Icon, "smooth")
        surface.SetDrawColor(badge.Color or C.Theme.Accent)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(x, y, S(14), S(14))
        x = x + S(18)
    end

    draw.SimpleText(
        tostring(badge.Text or "BADGE"),
        "SimpleF4.Small",
        x,
        y + S(7),
        badge.Color or C.Theme.Accent,
        TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER
    )

    return startX + SimpleF4.GetBadgeWidth(badge)
end


--=====================================================
-- SUPERADMIN / DEVELOPER CLIENT HELPERS
--=====================================================

function SimpleF4.IsDeveloperToolsEnabled()
    local ply = LocalPlayer()

    return IsValid(ply)
        and ply:IsSuperAdmin()
        and (
            SimpleF4.Config.Debug == true
            or SimpleF4.GetUserSetting("SuperAdminDeveloperTools")
        )
end

function SimpleF4.AttachDeveloperContext(panel, kind, data, id)
    if not IsValid(panel) then return end

    panel:SetMouseInputEnabled(true)

    local oldPressed = panel.OnMousePressed

    panel.OnMousePressed = function(self, mouseCode)
        if isfunction(oldPressed) then
            oldPressed(self, mouseCode)
        end

        if mouseCode ~= MOUSE_RIGHT
        or not SimpleF4.IsDeveloperToolsEnabled() then
            return
        end

        local rows = {}
        local function add(label, value)
            if value == nil or tostring(value) == "" then return end
            table.insert(rows, {
                Text = label .. ": " .. tostring(value),
                DoClick = function()
                    SetClipboardText(tostring(value))
                end,
            })
        end

        add("Name", data and data.name)
        add("ID", id)
        add("Command", data and (data.command or data.cmd))
        add("Class", data and (data.weapon or data.ent or data.entity))
        add(SimpleF4.L("InspectorCategory"), data and data.category)

        table.insert(rows, {
            Text = SimpleF4.L("DevInspectConfig"),
            DoClick = function()
                SimpleF4.OpenConfigInspector(kind, data, id)
            end,
        })

        table.insert(rows, {
            Text = SimpleF4.L("DevPrintTable"),
            DoClick = function()
                print("[SimpleF4 Debug] " .. tostring(kind))
                PrintTable(data or {})
            end,
        })

        SimpleF4.OpenContextMenu(self, rows, {Width = 300})
    end
end


--=====================================================
-- CUSTOM CONTEXT / DROPDOWN MENU
--=====================================================

function SimpleF4.CloseContextMenu()
    if IsValid(SimpleF4.ActiveContextOverlay) then
        SimpleF4.ActiveContextOverlay:Remove()
    elseif IsValid(SimpleF4.ActiveContextMenu) then
        SimpleF4.ActiveContextMenu:Remove()
    end

    SimpleF4.ActiveContextOverlay = nil
    SimpleF4.ActiveContextMenu = nil
    SimpleF4.ActiveContextAnchor = nil
end

function SimpleF4.OpenContextMenu(anchor, items, options)
    if not IsValid(anchor) or not istable(items) or #items == 0 then
        return
    end

    -- Clicking the same filter box again closes its open dropdown.
    if IsValid(SimpleF4.ActiveContextMenu)
    and SimpleF4.ActiveContextAnchor == anchor then
        SimpleF4.CloseContextMenu()
        return
    end

    SimpleF4.CloseContextMenu()

    options = options or {}

    local parent = IsValid(SimpleF4.Frame)
        and SimpleF4.Frame
        or vgui.GetWorldPanel()

    -- Full-size transparent click catcher.
    -- This makes clicking anywhere outside the dropdown close it,
    -- including clicking the original filter box again.
    local overlay = vgui.Create("DButton", parent)
    SimpleF4.ActiveContextOverlay = overlay
    SimpleF4.ActiveContextAnchor = anchor

    overlay:SetText("")
    overlay:SetCursor("arrow")
    overlay:SetZPos(32000)

    if parent == vgui.GetWorldPanel() then
        overlay:SetPos(0, 0)
        overlay:SetSize(ScrW(), ScrH())
    else
        overlay:SetPos(0, 0)
        overlay:SetSize(parent:GetWide(), parent:GetTall())
    end

    overlay.Paint = nil

    overlay.DoClick = function()
        SimpleF4.CloseContextMenu()
    end

    local width = S(options.Width or 210)
    local rowHeight = S(options.RowHeight or 38)
    local pad = S(4)

    local menu = vgui.Create("DPanel", overlay)
    SimpleF4.ActiveContextMenu = menu

    menu:SetZPos(32001)
    menu:SetMouseInputEnabled(true)
    menu:SetKeyboardInputEnabled(false)
    menu:SetSize(width, pad * 2 + rowHeight * #items)

    local anchorX, anchorY = anchor:LocalToScreen(0, anchor:GetTall())
    local localX, localY

    if parent == vgui.GetWorldPanel() then
        localX = anchorX
        localY = anchorY
    else
        localX, localY = parent:ScreenToLocal(anchorX, anchorY)
    end

    local maxX = overlay:GetWide() - menu:GetWide() - S(8)
    local maxY = overlay:GetTall() - menu:GetTall() - S(8)

    menu:SetPos(
        math.Clamp(localX, S(8), math.max(S(8), maxX)),
        math.Clamp(localY + S(4), S(8), math.max(S(8), maxY))
    )

    menu.Paint = function(_, w, h)
        surface.SetDrawColor(C.Theme.Surface2)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(C.Theme.Line)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        surface.SetDrawColor(C.Theme.Accent)
        surface.DrawRect(0, 0, S(3), h)
    end

    local y = pad

    for _, item in ipairs(items) do
        local button = vgui.Create("DButton", menu)
        button:SetPos(pad, y)
        button:SetSize(width - pad * 2, rowHeight)
        button:SetText("")
        button:SetCursor(item.Disabled and "arrow" or "hand")
        button:SetZPos(1)

        button.Paint = function(btn, w, h)
            if item.Selected then
                surface.SetDrawColor(C.Theme.AccentSoft)
                surface.DrawRect(0, 0, w, h)
            elseif btn:IsHovered() and not item.Disabled then
                surface.SetDrawColor(C.Theme.SurfaceHover)
                surface.DrawRect(0, 0, w, h)
            end

            local textX = S(12)

            if IsColor(item.SampleColor) then
                surface.SetDrawColor(item.SampleColor)
                surface.DrawRect(0, 0, S(4), h)

                surface.SetDrawColor(item.SampleColor)
                surface.DrawRect(S(12), h / 2 - S(5), S(10), S(10))

                textX = S(30)
            end

            draw.SimpleText(
                tostring(item.Text or "Option"),
                "SimpleF4.Small",
                textX,
                h / 2,
                item.Disabled and C.Theme.Muted
                    or (item.Selected and C.Theme.Accent or C.Theme.Text),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )

            if item.Selected then
                draw.SimpleText(
                    "✓",
                    "SimpleF4.Small",
                    w - S(12),
                    h / 2,
                    item.SampleColor or C.Theme.Accent,
                    TEXT_ALIGN_RIGHT,
                    TEXT_ALIGN_CENTER
                )
            end
        end

        if item.Tooltip then
            SimpleF4.AttachTooltip(button, item.Tooltip)
        end

        button.DoClick = function()
            if item.Disabled then return end

            if isfunction(item.DoClick) then
                item.DoClick(item)
            end

            SimpleF4.CloseContextMenu()
        end

        y = y + rowHeight
    end

    overlay.Think = function(self)
        if not IsValid(anchor) then
            SimpleF4.CloseContextMenu()
            return
        end

        if IsValid(SimpleF4.Frame)
        and not SimpleF4.Frame:IsVisible() then
            SimpleF4.CloseContextMenu()
        end
    end

    return menu
end

function SimpleF4.OpenChoiceMenu(
    anchor,
    values,
    currentValue,
    onSelected,
    options
)
    local items = {}

    for _, value in ipairs(values or {}) do
        table.insert(items, {
            Text = SimpleF4.GetChoiceLabel(value),
            Selected = value == currentValue,
            DoClick = function()
                if isfunction(onSelected) then
                    onSelected(value)
                end
            end,
        })
    end

    return SimpleF4.OpenContextMenu(anchor, items, options)
end

--=====================================================
-- CUSTOM SCROLLBARS
--=====================================================

function SimpleF4.StyleScrollPanel(scrollPanel)
    if not IsValid(scrollPanel) then return end

    local bar = scrollPanel:GetVBar()
    if not IsValid(bar) then return end

    bar:SetWide(S(8))

    bar.Paint = function(_, w, h)
        surface.SetDrawColor(SimpleF4.Config.Theme.Background)
        surface.DrawRect(0, 0, w, h)
    end

    bar.btnUp:SetTall(0)
    bar.btnUp.Paint = nil

    bar.btnDown:SetTall(0)
    bar.btnDown.Paint = nil

    bar.btnGrip.Paint = function(grip, w, h)
        local col =
            grip:IsHovered()
            and SimpleF4.Config.Theme.Accent
            or SimpleF4.Config.Theme.Line

        surface.SetDrawColor(col)
        surface.DrawRect(S(2), 0, math.max(1, w - S(4)), h)
    end
end



--=====================================================
-- RESTORE CLIENT PREFERENCES AFTER LUA / CONFIG RELOAD
--=====================================================

function SimpleF4.RestoreClientPreferences()
    -- Boolean/choice settings are read directly from cookies every time,
    -- so they naturally survive config reloads. Theme colours are mutable,
    -- however, so re-apply the player's saved theme after auto-refresh.
    if SimpleF4.ApplyThemePreset
    and SimpleF4.GetThemePreset then
        SimpleF4.ApplyThemePreset(
            SimpleF4.GetThemePreset(),
            false
        )
    end

    hook.Run("SimpleF4_ClientPreferencesRestored")
end

hook.Add("OnReloaded", "SimpleF4.RestoreClientPreferences", function()
    timer.Simple(0, function()
        if SimpleF4.RestoreClientPreferences then
            SimpleF4.RestoreClientPreferences()
        end
    end)
end)


--=====================================================
-- DEBUG / LIVE RELOAD
--=====================================================

function SimpleF4.DebugPrint(...)
    if not SimpleF4.Config.Debug then return end

    local parts = {}

    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end

    MsgC(
        Color(47, 132, 225),
        "[SimpleF4] ",
        color_white,
        table.concat(parts, " "),
        "\n"
    )
end

net.Receive("SimpleF4.Reload", function()
    local requestedBy = net.ReadString()
    SimpleF4.DebugPrint(
        "Received live reload request from",
        requestedBy
    )

    if not IsValid(SimpleF4.Frame) then return end

    local activePage = SimpleF4.Frame.ActivePage

    if SimpleF4.RestoreClientPreferences then
        SimpleF4.RestoreClientPreferences()
    end

    SimpleF4.Frame:Remove()
    SimpleF4.Frame = nil
    gui.EnableScreenClicker(false)

    timer.Simple(0, function()
        if SimpleF4.RestoreClientPreferences then
            SimpleF4.RestoreClientPreferences()
        end

        SimpleF4.Frame = vgui.Create("SimpleF4.Main")
        SimpleF4.Frame:MakePopup()
        SimpleF4.Frame:SetKeyboardInputEnabled(true)
        SimpleF4.Frame:SetMouseInputEnabled(true)
        gui.EnableScreenClicker(true)

        if activePage
        and SimpleF4.Frame.PageButtons
        and SimpleF4.Frame.PageButtons[activePage] then
            SimpleF4.Frame:OpenPage(activePage)
        end

        SimpleF4.Notify(
            SimpleF4.L("ReloadClient"),
            "success",
            4
        )
    end)
end)

net.Receive("SimpleF4.ReloadResult", function()
    local count = net.ReadUInt(16)

    SimpleF4.Notify(
        SimpleF4.L("ReloadSuccess", {
            count = count,
        }),
        "success",
        5
    )
end)

concommand.Add("simplef4_debug_info", function()
    if not SimpleF4.Config.Debug then
        print("[SimpleF4] Debug mode is disabled in sh_config.lua")
        return
    end

    print("[SimpleF4] ----- Debug Info -----")
    print("[SimpleF4] Theme preset:", SimpleF4.Config.ThemePreset or "nil")
    print("[SimpleF4] Current page:", IsValid(SimpleF4.Frame) and (SimpleF4.Frame.ActivePage or "unknown") or "menu closed")
    print("[SimpleF4] Resolution:", ScrW() .. "x" .. ScrH())
    print("[SimpleF4] Scale:", SimpleF4.Scale())
    print("[SimpleF4] Jobs:", table.Count(RPExtraTeams or {}))
    print("[SimpleF4] Entities:", table.Count(DarkRPEntities or {}))
    print("[SimpleF4] Shipments:", table.Count(CustomShipments or {}))
end)


SimpleF4.JobButtons = SimpleF4.JobButtons or {}
SimpleF4.DashboardCards = SimpleF4.DashboardCards or {}

function SimpleF4.AddJobButton(teamID, data)
    if teamID == nil or not istable(data) then return false end
    SimpleF4.JobButtons[teamID] = SimpleF4.JobButtons[teamID] or {}
    table.insert(SimpleF4.JobButtons[teamID], data)
    return true
end

function SimpleF4.GetJobButtons(teamID, ply, job)
    local out = {}
    for _, data in ipairs(SimpleF4.JobButtons[teamID] or {}) do
        local visible = true
        if isfunction(data.CanSee) then
            local ok, result = pcall(data.CanSee, ply, job, teamID)
            visible = ok and result ~= false
        end
        if visible then table.insert(out, data) end
    end
    table.sort(out, function(a,b)
        return (tonumber(a.Order) or 100) < (tonumber(b.Order) or 100)
    end)
    return out
end

function SimpleF4.RegisterDashboardCard(id, data)
    if not isstring(id) or id == "" or not istable(data) then return false end
    data.ID = id
    SimpleF4.DashboardCards[id] = data
    return true
end

function SimpleF4.GetDashboardCards()
    local out = {}
    for _, data in pairs(SimpleF4.DashboardCards) do
        if data.Enabled ~= false then table.insert(out, data) end
    end
    table.sort(out, function(a,b)
        return (tonumber(a.Order) or 100) < (tonumber(b.Order) or 100)
    end)
    return out
end
