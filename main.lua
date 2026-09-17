--[[
    Steal an Egg — Auto Grab (Loader)
    Paste this in Delta Executor.

    Fetches UI, Catalog, and Core modules from GitHub.
    Re-execution safe — running again cleanly restarts.
]]

-- ============================================================
--  🚨 REPLACE THESE WITH YOUR OWN
-- ============================================================
local GITHUB_USER = "Clide01"
local REPO_NAME   = "roblox-sae-autograb"
local BRANCH      = "main"
-- ============================================================

local BASE = "https://raw.githubusercontent.com/" ..
             GITHUB_USER .. "/" .. REPO_NAME .. "/" .. BRANCH .. "/"

print("[AutoGrab] Loader starting...")

-- ============================================================
--  KILL PREVIOUS INSTANCE (re-execution safe)
-- ============================================================
local GENV = getgenv and getgenv() or _G
if GENV.__AutoGrab then
    pcall(function()
        if GENV.__AutoGrab.core and GENV.__AutoGrab.core.cleanup then
            GENV.__AutoGrab.core.cleanup()
        end
        if GENV.__AutoGrab.ui and GENV.__AutoGrab.ui.destroy then
            GENV.__AutoGrab.ui.destroy()
        end
    end)
    print("[AutoGrab] Previous instance stopped.")
end
GENV.__AutoGrab = nil

-- ============================================================
--  HTTP FETCH
-- ============================================================
local function fetch(url)
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok or not res or res == "" then
        return nil, "Fetch failed: " .. url
    end
    return res
end

local function loadModule(src, name)
    if not src then return nil, name .. " source is nil" end
    local fn, err = loadstring(src)
    if not fn then
        return nil, "Syntax error in " .. name .. ": " .. tostring(err)
    end
    local ok, result = pcall(fn)
    if not ok then
        return nil, "Runtime error in " .. name .. ": " .. tostring(result)
    end
    return result
end

-- ============================================================
--  LOAD MODULES
-- ============================================================
print("[AutoGrab] Fetching catalog.lua ...")
local catalogSrc, cerr = fetch(BASE .. "catalog.lua")
if not catalogSrc then
    warn("[AutoGrab] " .. cerr)
    return
end

print("[AutoGrab] Fetching ui.lua ...")
local uiSrc, uerr = fetch(BASE .. "ui.lua")
if not uiSrc then
    warn("[AutoGrab] " .. uerr)
    return
end

print("[AutoGrab] Fetching core.lua ...")
local coreSrc, coerr = fetch(BASE .. "core.lua")
if not coreSrc then
    warn("[AutoGrab] " .. coerr)
    return
end

local catalog, err1 = loadModule(catalogSrc, "catalog")
if not catalog then warn("[AutoGrab] " .. err1); return end

local UI, err2 = loadModule(uiSrc, "ui")
if not UI then warn("[AutoGrab] " .. err2); return end

local Core, err3 = loadModule(coreSrc, "core")
if not Core then warn("[AutoGrab] " .. err3); return end

print(("[AutoGrab] Loaded %d catalog entries"):format(#catalog))

-- ============================================================
--  BUILD + START
-- ============================================================
local ui = UI.new(catalog)
local core = Core.new(ui, catalog)

-- Register for re-execution cleanup
GENV.__AutoGrab = { ui = ui, core = core }

print("[AutoGrab] Ready. Panel is in the top-right.")
