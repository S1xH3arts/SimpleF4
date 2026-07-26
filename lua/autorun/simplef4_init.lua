SimpleF4 = SimpleF4 or {}
SimpleF4.Config = SimpleF4.Config or {}
SimpleF4.Functions = SimpleF4.Functions or {}
SimpleF4.Pages = SimpleF4.Pages or {}
SimpleF4.Modules = SimpleF4.Modules or {}
SimpleF4.Version = "42.0.1"
SimpleF4.Release = "stable"
SimpleF4.ReleaseName = "Release Polish"

local base = "simplef4/"

local shared = {
    "config/sh_config.lua",
    "core/sh_functions.lua",
}

local server = {
    "core/sv_core.lua",
}

local clientCore = {
    "core/cl_core.lua",
}

local clientUI = {
    "derma/cl_main.lua",
    "pages/cl_dashboard.lua",
    "pages/cl_jobs.lua",
    "pages/cl_entities.lua",
    "pages/cl_weapons.lua",
    "pages/cl_settings.lua",
    "pages/cl_modules.lua",
}

local function sortedFiles(pattern)
    local files = file.Find(pattern, "LUA") or {}
    table.sort(files)
    return files
end

local function getLanguageFiles()
    local files = sortedFiles(base .. "languages/*.lua")

    table.sort(files, function(a, b)
        if a == "en.lua" then return true end
        if b == "en.lua" then return false end
        return string.lower(a) < string.lower(b)
    end)

    return files
end

local function getModuleFolders()
    local _, folders = file.Find(
        base .. "modules/*",
        "LUA"
    )

    folders = folders or {}
    table.sort(folders)
    return folders
end

local function moduleFiles(folder, prefix)
    return sortedFiles(
        base
        .. "modules/"
        .. folder
        .. "/"
        .. prefix
        .. "*.lua"
    )
end

local function modulePath(folder, fileName)
    return base
        .. "modules/"
        .. folder
        .. "/"
        .. fileName
end

if SERVER then
    for _, fileName in ipairs(shared) do
        AddCSLuaFile(base .. fileName)
        include(base .. fileName)
    end

    for _, fileName in ipairs(server) do
        include(base .. fileName)
    end

    for _, fileName in ipairs(clientCore) do
        AddCSLuaFile(base .. fileName)
    end

    for _, fileName in ipairs(getLanguageFiles()) do
        AddCSLuaFile(base .. "languages/" .. fileName)
    end

    -- Modules: shared registration/config first.
    for _, folder in ipairs(getModuleFolders()) do
        for _, fileName in ipairs(moduleFiles(folder, "sh_")) do
            local path = modulePath(folder, fileName)
            AddCSLuaFile(path)
            include(path)
        end
    end

    -- Module server/client files.
    for _, folder in ipairs(getModuleFolders()) do
        for _, fileName in ipairs(moduleFiles(folder, "sv_")) do
            include(modulePath(folder, fileName))
        end

        for _, fileName in ipairs(moduleFiles(folder, "cl_")) do
            AddCSLuaFile(modulePath(folder, fileName))
        end
    end

    for _, fileName in ipairs(clientUI) do
        AddCSLuaFile(base .. fileName)
    end
else
    for _, fileName in ipairs(shared) do
        include(base .. fileName)
    end

    for _, fileName in ipairs(clientCore) do
        include(base .. fileName)
    end

    for _, fileName in ipairs(getLanguageFiles()) do
        include(base .. "languages/" .. fileName)
    end

    -- Modules load before the F4 UI pages so they can register settings/hooks.
    for _, folder in ipairs(getModuleFolders()) do
        for _, fileName in ipairs(moduleFiles(folder, "sh_")) do
            include(modulePath(folder, fileName))
        end

        for _, fileName in ipairs(moduleFiles(folder, "cl_")) do
            include(modulePath(folder, fileName))
        end
    end

    for _, fileName in ipairs(clientUI) do
        include(base .. fileName)
    end
end
