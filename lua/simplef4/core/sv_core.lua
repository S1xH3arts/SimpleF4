util.AddNetworkString("SimpleF4_RequestOpen")

net.Receive("SimpleF4_RequestOpen", function(_, ply)
    if not IsValid(ply) then return end
    net.Start("SimpleF4_RequestOpen")
    net.Send(ply)
end)

concommand.Add("simplef4_open", function(ply)
    if not IsValid(ply) then return end

    net.Start("SimpleF4_RequestOpen")
    net.Send(ply)
end)

util.AddNetworkString("SimpleF4.Reload")
util.AddNetworkString("SimpleF4.MenuState")
util.AddNetworkString("SimpleF4.ReloadResult")

local openMenus = {}


--=====================================================
-- SHARED LUA AUTO REFRESH
--=====================================================

util.AddNetworkString("SimpleF4.SharedHotReload")

local sharedWatchCRC = {}
local sharedWatchPrimed = false

local function getSharedWatchFiles()
    local files = {
        "simplef4/config/sh_config.lua",
        "simplef4/core/sh_functions.lua",
    }

    local _, folders = file.Find(
        "simplef4/modules/*",
        "LUA"
    )

    folders = folders or {}
    table.sort(folders)

    for _, folder in ipairs(folders) do
        local moduleFiles =
            file.Find(
                "simplef4/modules/"
                .. folder
                .. "/sh_*.lua",
                "LUA"
            ) or {}

        table.sort(moduleFiles)

        for _, fileName in ipairs(moduleFiles) do
            table.insert(
                files,
                "simplef4/modules/"
                .. folder
                .. "/"
                .. fileName
            )
        end
    end

    return files
end

local function readSharedFile(path)
    local contents = file.Read(path, "LUA")

    if not isstring(contents) then
        return nil
    end

    return contents
end

local function primeSharedWatch()
    sharedWatchCRC = {}

    for _, path in ipairs(getSharedWatchFiles()) do
        local contents = readSharedFile(path)

        if contents then
            sharedWatchCRC[path] = util.CRC(contents)
        end
    end

    sharedWatchPrimed = true
end

local function sendSharedFilesToClients(files, changedPaths)
    local json = util.TableToJSON({
        Files = files,
        Changed = changedPaths,
    })

    if not json then return false end

    local compressed = util.Compress(json)
    if not compressed then return false end

    net.Start("SimpleF4.SharedHotReload")
    net.WriteUInt(#compressed, 32)
    net.WriteData(compressed, #compressed)
    net.Broadcast()

    return true
end

local function refreshOpenMenusFromSharedReload()
    local recipients = {}

    for ply in pairs(openMenus) do
        if IsValid(ply) then
            table.insert(recipients, ply)
        else
            openMenus[ply] = nil
        end
    end

    if #recipients > 0 then
        net.Start("SimpleF4.Reload")
        net.WriteString("Auto Refresh")
        net.Send(recipients)
    end
end

function SimpleF4.ReloadSharedFiles(changedPaths)
    local files = {}
    local debugEnabled =
        SimpleF4.Config.AutoRefresh
        and SimpleF4.Config.AutoRefresh.Debug == true

    -- Always reload every shared file in startup order. This is important
    -- when sh_config.lua replaces tables which module sh_ files then extend.
    for _, path in ipairs(getSharedWatchFiles()) do
        local contents = readSharedFile(path)

        if contents then
            local ok, err = pcall(include, path)

            if not ok then
                ErrorNoHalt(
                    "[SimpleF4] Shared auto refresh failed for "
                    .. path
                    .. ": "
                    .. tostring(err)
                    .. "\\n"
                )

                return false
            end

            table.insert(files, {
                Path = path,
                Code = contents,
            })
        end
    end

    -- Re-prime after includes so this reload does not trigger itself again.
    primeSharedWatch()

    sendSharedFilesToClients(
        files,
        changedPaths or {}
    )

    refreshOpenMenusFromSharedReload()

    hook.Run(
        "SimpleF4_SharedFilesReloaded",
        changedPaths or {}
    )

    if debugEnabled then
        print(
            "[SimpleF4] Shared files live-refreshed."
        )

        for _, path in ipairs(changedPaths or {}) do
            print("  changed: " .. path)
        end
    end

    return true
end

local function checkSharedFiles()
    local config =
        SimpleF4.Config.AutoRefresh or {}

    if config.Enabled == false then
        return
    end

    if not sharedWatchPrimed then
        primeSharedWatch()
        return
    end

    local changed = {}

    for _, path in ipairs(getSharedWatchFiles()) do
        local contents = readSharedFile(path)

        if contents then
            local crc = util.CRC(contents)
            local previous = sharedWatchCRC[path]

            if previous ~= nil
            and previous ~= crc then
                table.insert(changed, path)
            elseif previous == nil then
                -- Newly added sh_ module file.
                table.insert(changed, path)
            end
        end
    end

    if #changed > 0 then
        SimpleF4.ReloadSharedFiles(changed)
    end
end

hook.Add(
    "Initialize",
    "SimpleF4.PrimeSharedAutoRefresh",
    function()
        timer.Simple(0, primeSharedWatch)
    end
)

timer.Create(
    "SimpleF4.SharedAutoRefresh",
    1,
    0,
    function()
        local config =
            SimpleF4.Config.AutoRefresh or {}

        local interval =
            math.max(
                0.25,
                tonumber(config.Interval) or 1
            )

        local timerData =
            timer.TimeLeft(
                "SimpleF4.SharedAutoRefresh"
            )

        -- Recreate only when the configured interval changed.
        if SimpleF4.SharedRefreshInterval ~= interval then
            SimpleF4.SharedRefreshInterval = interval

            timer.Adjust(
                "SimpleF4.SharedAutoRefresh",
                interval,
                0,
                checkSharedFiles
            )

            return
        end

        checkSharedFiles()
    end
)

concommand.Add(
    "simplef4_refresh_shared",
    function(ply)
        if IsValid(ply)
        and not ply:IsSuperAdmin() then
            ply:ChatPrint(
                "[SimpleF4] Superadmin permission required."
            )
            return
        end

        SimpleF4.ReloadSharedFiles({
            "manual refresh",
        })
    end
)


net.Receive("SimpleF4.MenuState", function(_, ply)
    if not IsValid(ply) then return end

    local open = net.ReadBool()

    if open then
        openMenus[ply] = true
    else
        openMenus[ply] = nil
    end
end)

hook.Add("PlayerDisconnected", "SimpleF4.ClearMenuState", function(ply)
    openMenus[ply] = nil
end)

local function canCommand(ply, permissionKey)
    if not IsValid(ply) then
        return true
    end

    local permissions =
        SimpleF4.Config.CommandPermissions
        or {}

    local groups =
        permissions[permissionKey]
        or {}

    if groups[ply:GetUserGroup()] == true then
        return true
    end

    return false
end

local function denyCommand(ply, permissionKey)
    if not IsValid(ply) then return end

    ply:ChatPrint(
        "[SimpleF4] You do not have permission for this command ("
        .. tostring(permissionKey)
        .. ")."
    )
end

local function outputLine(ply, message)
    message = tostring(message or "")

    if IsValid(ply) then
        ply:PrintMessage(
            HUD_PRINTCONSOLE,
            message
        )
    else
        print(message)
    end
end

local function addSimpleF4Command(name, permissionKey, callback)
    concommand.Add(name, function(ply, cmd, args, argStr)
        if not canCommand(ply, permissionKey) then
            denyCommand(ply, permissionKey)
            return
        end

        callback(ply, cmd, args, argStr)
    end)
end

addSimpleF4Command("simplef4_reload", "reload", function(ply)
    print("[SimpleF4] Live reload requested by "
        .. (IsValid(ply) and ply:Nick() or "server console")
        .. ".")

    local recipients = {}

    for target in pairs(openMenus) do
        if IsValid(target) then
            table.insert(recipients, target)
        else
            openMenus[target] = nil
        end
    end

    if #recipients > 0 then
        net.Start("SimpleF4.Reload")
        net.WriteString(IsValid(ply) and ply:Nick() or "Server")
        net.Send(recipients)
    end

    if IsValid(ply) then
        net.Start("SimpleF4.ReloadResult")
        net.WriteUInt(#recipients, 16)
        net.Send(ply)
    end

    print(
        "[SimpleF4] Refreshed "
        .. tostring(#recipients)
        .. " currently-open menu(s)."
    )
end)



--=====================================================
-- RUNTIME MAINTENANCE MODE
--=====================================================

hook.Add("Initialize", "SimpleF4.InitialMaintenanceState", function()
    SetGlobalBool(
        "SimpleF4.Maintenance",
        SimpleF4.Config.Maintenance
            and SimpleF4.Config.Maintenance.Enabled == true
            or false
    )
end)

addSimpleF4Command("simplef4_maintenance_toggle", "maintenance", function(ply)

    local current = GetGlobalBool(
        "SimpleF4.Maintenance",
        SimpleF4.Config.Maintenance
            and SimpleF4.Config.Maintenance.Enabled == true
            or false
    )

    local nextState = not current
    SetGlobalBool("SimpleF4.Maintenance", nextState)

    local actor =
        IsValid(ply) and ply:Nick() or "server console"

    print(
        "[SimpleF4] Maintenance mode "
        .. (nextState and "enabled" or "disabled")
        .. " by "
        .. actor
        .. "."
    )

    if IsValid(ply) then
        ply:ChatPrint(
            "[SimpleF4] Maintenance mode "
            .. (nextState and "enabled." or "disabled.")
        )
    end
end)


--=====================================================
-- VERSION / RELEASE / UPDATE CHECK
--=====================================================


local function printStartupVersion()
    print("========================================")
    print(
        "[SimpleF4] Installed version: v"
        .. tostring(SimpleF4.Version or "unknown")
    )
    print(
        "[SimpleF4] Release channel: "
        .. tostring(SimpleF4.Release or "unknown")
    )
    print(
        "[SimpleF4] Release name: "
        .. tostring(SimpleF4.ReleaseName or "unknown")
    )

    local settings =
        SimpleF4.Config.UpdateCheck or {}

    local provider =
        string.lower(
            tostring(
                settings.Provider
                or "github"
            )
        )

    print(
        "[SimpleF4] Update provider: "
        .. provider
    )

    if settings.Enabled == true then
        print(
            "[SimpleF4] GitHub update check: enabled"
        )
    else
        print(
            "[SimpleF4] GitHub update check: disabled"
        )
    end

    print("========================================")
end


local function parseSimpleF4Version(value)
    value = string.Trim(tostring(value or ""))
    value = string.gsub(value, "^[vV]", "")

    local major, minor, patch =
        string.match(value, "^(%d+)%.(%d+)%.(%d+)")

    if not major then return nil end

    return {
        tonumber(major) or 0,
        tonumber(minor) or 0,
        tonumber(patch) or 0,
    }
end

local function isNewerSimpleF4Version(remote, installed)
    local a = parseSimpleF4Version(remote)
    local b = parseSimpleF4Version(installed)

    if not a or not b then return false end

    for i = 1, 3 do
        if a[i] ~= b[i] then
            return a[i] > b[i]
        end
    end

    return false
end

SimpleF4.LatestRelease = SimpleF4.LatestRelease or nil

local function updateResult(remote, releaseData)
    if not remote or remote == "" then
        print("[SimpleF4] Update check returned no version.")
        return
    end

    SimpleF4.LatestRelease = releaseData or {
        Version = remote,
    }

    print(
        "[SimpleF4] Latest GitHub version: v"
        .. tostring(remote)
    )

    if releaseData
    and releaseData.Name
    and releaseData.Name ~= "" then
        print(
            "[SimpleF4] Latest release: "
            .. tostring(releaseData.Name)
        )
    end

    if isNewerSimpleF4Version(
        remote,
        SimpleF4.Version
    ) then
        print(
            "[SimpleF4] Update available: v"
            .. tostring(remote)
            .. " (installed v"
            .. tostring(SimpleF4.Version)
            .. ")"
        )

        if releaseData
        and releaseData.URL
        and releaseData.URL ~= "" then
            print(
                "[SimpleF4] Release: "
                .. releaseData.URL
            )
        end

        hook.Run(
            "SimpleF4_UpdateAvailable",
            remote,
            SimpleF4.Version,
            releaseData
        )
    else
        print(
            "[SimpleF4] v"
            .. tostring(SimpleF4.Version)
            .. " is up to date."
        )
    end
end

local function checkGitHubUpdates(settings)
    local github = settings.GitHub or {}
    local owner = string.Trim(
        tostring(github.Owner or "")
    )
    local repository = string.Trim(
        tostring(github.Repository or "")
    )

    if owner == "" or repository == "" then
        print(
            "[SimpleF4] GitHub update check is enabled but Owner/Repository is blank."
        )
        return
    end

    local url =
        "https://api.github.com/repos/"
        .. owner
        .. "/"
        .. repository
        .. "/releases/latest"

    http.Fetch(
        url,
        function(body, size, headers, code)
            if tonumber(code) ~= 200 then
                print(
                    "[SimpleF4] GitHub update check returned HTTP "
                    .. tostring(code)
                    .. "."
                )
                return
            end

            local decoded =
                util.JSONToTable(
                    tostring(body or "")
                )

            if not istable(decoded) then
                print(
                    "[SimpleF4] GitHub update check returned invalid JSON."
                )
                return
            end

            local tag =
                tostring(decoded.tag_name or "")

            local remote =
                string.gsub(tag, "^[vV]", "")

            updateResult(remote, {
                Version = remote,
                Tag = tag,
                Name = tostring(
                    decoded.name or tag
                ),
                URL = tostring(
                    decoded.html_url
                    or github.ReleasesURL
                    or ""
                ),
                PublishedAt = tostring(
                    decoded.published_at or ""
                ),
                Body = tostring(
                    decoded.body or ""
                ),
                Provider = "github",
            })
        end,
        function(errorMessage)
            print(
                "[SimpleF4] GitHub update check failed: "
                .. tostring(errorMessage)
            )
        end,
        {
            ["Accept"] =
                "application/vnd.github+json",
            ["User-Agent"] =
                "SimpleF4/"
                .. tostring(SimpleF4.Version),
        }
    )
end

local function checkRawUpdates(settings)
    local url =
        tostring(
            settings.RawURL
            or settings.URL
            or ""
        )

    if url == "" then
        print(
            "[SimpleF4] Raw update URL is blank."
        )
        return
    end

    http.Fetch(
        url,
        function(body)
            local remote =
                string.Trim(
                    tostring(body or "")
                )

            updateResult(remote, {
                Version = remote,
                URL = url,
                Provider = "raw",
            })
        end,
        function(errorMessage)
            print(
                "[SimpleF4] Raw update check failed: "
                .. tostring(errorMessage)
            )
        end
    )
end

function SimpleF4.CheckForUpdates(force)
    local settings =
        SimpleF4.Config.UpdateCheck
        or {}

    if settings.Enabled ~= true
    and force ~= true then
        return
    end

    local provider =
        string.lower(
            tostring(
                settings.Provider
                or "github"
            )
        )

    print(
        "[SimpleF4] Checking for updates using "
        .. provider
        .. "..."
    )

    if provider == "raw" then
        checkRawUpdates(settings)
    else
        checkGitHubUpdates(settings)
    end
end

local function moduleStateSummary()
    local counts = {
        ready = 0,
        disabled = 0,
        other = 0,
    }

    for id in pairs(
        SimpleF4.GetModules() or {}
    ) do
        local state =
            SimpleF4.GetModuleStatus(id)

        if state.State == "ready" then
            counts.ready = counts.ready + 1
        elseif state.State == "disabled" then
            counts.disabled =
                counts.disabled + 1
        else
            counts.other =
                counts.other + 1
        end
    end

    return counts
end

addSimpleF4Command("simplef4_version", "version", function(ply)
    outputLine(
        ply,
        "[SimpleF4] v"
        .. tostring(SimpleF4.Version or "unknown")
        .. " "
        .. tostring(SimpleF4.Release or "unknown")
        .. " — "
        .. tostring(SimpleF4.ReleaseName or "")
    )
end)

addSimpleF4Command("simplef4_status", "status", function(ply)
    local counts = moduleStateSummary()

    outputLine(
        ply,
        "[SimpleF4] v"
        .. tostring(SimpleF4.Version)
        .. " "
        .. tostring(SimpleF4.Release)
    )
    outputLine(
        ply,
        "[SimpleF4] Modules: "
        .. counts.ready
        .. " ready, "
        .. counts.disabled
        .. " disabled, "
        .. counts.other
        .. " attention."
    )

    local latest = SimpleF4.LatestRelease

    if latest and latest.Version then
        outputLine(
            ply,
            "[SimpleF4] Latest known release: v"
            .. tostring(latest.Version)
        )
    end
end)

addSimpleF4Command("simplef4_modules", "modules", function(ply)
    outputLine(ply, "[SimpleF4] Module status:")

    local ids = {}
    for id in pairs(SimpleF4.GetModules() or {}) do
        table.insert(ids, id)
    end
    table.sort(ids)

    for _, id in ipairs(ids) do
        local status =
            SimpleF4.GetModuleStatus(id)

        outputLine(
            ply,
            "  "
            .. id
            .. " : "
            .. string.upper(
                tostring(status.State or "unknown")
            )
            .. (
                status.Reason
                and (" — " .. status.Reason)
                or ""
            )
        )
    end
end)

addSimpleF4Command("simplef4_updatecheck", "update", function(ply)
    outputLine(
        ply,
        "[SimpleF4] Manual update check started."
    )
    SimpleF4.CheckForUpdates(true)
end)

local function runRegressionChecks()
    local checks = {}

    local function add(name, ok, detail)
        table.insert(checks, {
            Name = name,
            OK = ok == true,
            Detail = detail,
        })
    end

    add(
        "DarkRP loaded",
        DarkRP ~= nil,
        "DarkRP global"
    )

    add(
        "SimpleF4 version",
        parseSimpleF4Version(SimpleF4.Version) ~= nil,
        tostring(SimpleF4.Version)
    )

    add(
        "Pages registered",
        table.Count(SimpleF4.Pages or {}) > 0,
        tostring(table.Count(SimpleF4.Pages or {}))
    )

    add(
        "Modules registered",
        table.Count(SimpleF4.GetModules() or {}) > 0,
        tostring(table.Count(SimpleF4.GetModules() or {}))
    )

    add(
        "Theme configured",
        istable(SimpleF4.Config.Theme),
        "C.Theme"
    )

    add(
        "Command permissions",
        istable(SimpleF4.Config.CommandPermissions),
        "C.CommandPermissions"
    )

    add(
        "Update settings",
        istable(SimpleF4.Config.UpdateCheck),
        "C.UpdateCheck"
    )

    return checks
end

addSimpleF4Command("simplef4_regression", "regression", function(ply)
    local checks = runRegressionChecks()
    local passed = 0

    outputLine(
        ply,
        "[SimpleF4] Regression self-check:"
    )

    for _, check in ipairs(checks) do
        if check.OK then
            passed = passed + 1
        end

        outputLine(
            ply,
            "  ["
            .. (check.OK and "PASS" or "FAIL")
            .. "] "
            .. check.Name
            .. (
                check.Detail
                and (" — " .. check.Detail)
                or ""
            )
        )
    end

    outputLine(
        ply,
        "[SimpleF4] "
        .. passed
        .. "/"
        .. #checks
        .. " checks passed."
    )
end)

addSimpleF4Command("simplef4_commands", "commands", function(ply)
    outputLine(ply, "[SimpleF4] Available commands:")

    local commands = {
        {"simplef4_version", "version"},
        {"simplef4_status", "status"},
        {"simplef4_reload", "reload"},
        {"simplef4_refresh_shared", "refresh_shared"},
        {"simplef4_modules", "modules"},
        {"simplef4_updatecheck", "update"},
        {"simplef4_regression", "regression"},
        {"simplef4_maintenance_toggle", "maintenance"},
        {"simplef4_commands", "commands"},
    }

    for _, info in ipairs(commands) do
        if canCommand(ply, info[2]) then
            outputLine(
                ply,
                "  "
                .. info[1]
            )
        end
    end
end)

timer.Simple(0, function()
    printStartupVersion()
end)

timer.Simple(3, function()
    SimpleF4.CheckForUpdates(false)
end)

timer.Create(
    "SimpleF4.UpdateCheck",
    math.max(
        3600,
        tonumber(
            SimpleF4.Config.UpdateCheck
            and SimpleF4.Config.UpdateCheck.Interval
        )
        or 21600
    ),
    0,
    function()
        SimpleF4.CheckForUpdates(false)
    end
)
