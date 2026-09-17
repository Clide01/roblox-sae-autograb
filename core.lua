--[[
    Steal an Egg — Auto Grab Core module
    Handles: event hooks, grab logic, teleport return
    Receives a UI instance and a catalog table.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local Core = {}

-- Tunables
local GRAB_COOLDOWN      = 2.0
local TELEPORT_DELAY     = 0.35
local RETURN_DELAY       = 0.55
local EGG_ARRIVE_OFFSET  = Vector3.new(0, 3, 0)
local RESCAN_INTERVAL    = 30

local function getHRP()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
end

function Core.new(ui, catalog)
    local self = {
        _connections  = {},
        _destroyed    = false,
        _enabled      = false,
        _selected     = nil,
        _safeZone     = nil,
        _eggList      = {},
        _carrying     = false,
        _lastGrab     = 0,
        _stats        = { grabbed = 0, failed = 0, returned = 0 },
        _lastGrabbed  = "—",
    }

    -- Build a set of valid categories from catalog
    local validCategories = {}
    for _, e in ipairs(catalog) do
        validCategories[e.category] = true
    end

    ----------------------------------------------------------------
    -- REMOTES
    ----------------------------------------------------------------
    local ok, Remotes = pcall(function()
        return require(ReplicatedStorage.Shared.Remotes)
    end)
    if not ok or not Remotes or not Remotes.EggWorld then
        warn("[Core] Could not load Remotes.EggWorld")
        return self
    end
    local E = Remotes.EggWorld

    ----------------------------------------------------------------
    -- HELPERS
    ----------------------------------------------------------------
    local function track(conn)
        if conn then table.insert(self._connections, conn) end
        return conn
    end

    local function teleportBack()
        if not self._safeZone then return end
        local hrp = getHRP()
        if not hrp then return end
        hrp.CFrame = self._safeZone
        self._stats.returned = self._stats.returned + 1
        ui.setStats(self._stats)
    end

    local function matchesFilter(egg)
        if type(egg) ~= "table" then return false end
        if egg.State ~= "Slot" then return false end
        if not egg.Uid then return false end
        if not self._selected then return true end
        return egg.AssetCategory == self._selected
    end

    local function tryGrab(egg)
        if self._destroyed then return end
        if not self._enabled then return end
        if self._carrying then return end
        if not matchesFilter(egg) then return end

        local now = tick()
        if now - self._lastGrab < GRAB_COOLDOWN then return end
        self._lastGrab = now

        local cframe = egg.BottomCFrame or egg.BoundsCFrame
        if not cframe then return end
        local position = cframe.Position or cframe

        ui.setStatus("Grabbing " .. (egg.AssetCategory or "?"))

        local hrp = getHRP()
        if hrp then
            hrp.CFrame = CFrame.new(position + EGG_ARRIVE_OFFSET)
            task.wait(TELEPORT_DELAY)
        end

        if self._destroyed then return end

        local args = { Uid = egg.Uid }
        if type(egg.Uid) == "string" and string.find(egg.Uid, "^FirstAreaEgg_") then
            args.FirstAreaSlotKey = (egg.AreaId or "") .. ":" .. (egg.NestId or "")
        end

        local success = pcall(function()
            E.AskFieldEggCarry:InvokeServer(args)
        end)

        if success then
            self._stats.grabbed = self._stats.grabbed + 1
            self._lastGrabbed = (egg.AssetCategory or "?") .. " @ " .. (egg.AreaId or "?")
            ui.setLast(self._lastGrabbed)
        else
            self._stats.failed = self._stats.failed + 1
        end
        ui.setStats(self._stats)

        task.wait(RETURN_DELAY)
        if self._destroyed then return end
        teleportBack()
        ui.setStatus("Running")
    end

    ----------------------------------------------------------------
    -- SNAPSHOT
    ----------------------------------------------------------------
    local function fetchSnapshot()
        if self._destroyed then return end
        local okSnap, snapshot = pcall(function()
            return E.AskFieldEggSnapshot:InvokeServer()
        end)
        if okSnap and snapshot and snapshot.Records then
            local count = 0
            for _, egg in ipairs(snapshot.Records) do
                if egg.Uid then
                    self._eggList[egg.Uid] = egg
                    count = count + 1
                end
            end
            ui.setFieldCount(count)
            if self._enabled then
                for _, egg in ipairs(snapshot.Records) do
                    if self._destroyed then return end
                    tryGrab(egg)
                end
            end
        end
    end

    ----------------------------------------------------------------
    -- EVENT HOOKS
    ----------------------------------------------------------------
    track(E.FieldEggShifted.OnClientEvent:Connect(function(egg)
        if self._destroyed then return end
        if type(egg) ~= "table" or not egg.Uid then return end
        self._eggList[egg.Uid] = egg
        if egg.State == "Slot" then tryGrab(egg) end
    end))

    track(E.FieldEggBatchShifted.OnClientEvent:Connect(function(batch)
        if self._destroyed then return end
        if type(batch) ~= "table" then return end
        for _, egg in ipairs(batch) do
            if type(egg) == "table" and egg.Uid then
                self._eggList[egg.Uid] = egg
                if egg.State == "Slot" then tryGrab(egg) end
            end
        end
    end))

    track(E.FieldEggGone.OnClientEvent:Connect(function(uid)
        if type(uid) == "string" then self._eggList[uid] = nil end
    end))

    track(E.FieldEggCarry.OnClientEvent:Connect(function(info)
        if type(info) == "table" then
            self._carrying = info.IsCarrying == true
            ui.setStatus(self._carrying and "Carrying" or "Running")
        end
    end))

    ----------------------------------------------------------------
    -- UI WIRING
    ----------------------------------------------------------------
    ui.onToggle(function(enabled)
        self._enabled = enabled
        ui.refreshToggleVisual()
        if enabled then
            if not self._safeZone then
                local hrp = getHRP()
                if hrp then
                    self._safeZone = hrp.CFrame
                    ui.setSafeZoneText("Safe Zone: AUTO-SET", Color3.fromRGB(255, 180, 100))
                end
            end
            ui.setStatus("Running")
            task.spawn(fetchSnapshot)
        else
            ui.setStatus("Paused")
        end
    end)

    ui.onSafeZone(function(cframe)
        self._safeZone = cframe
    end)

    ----------------------------------------------------------------
    -- PERIODIC RESCAN
    ----------------------------------------------------------------
    track(task.spawn(function()
        task.wait(2)
        if self._destroyed then return end
        fetchSnapshot()
        while not self._destroyed do
            task.wait(RESCAN_INTERVAL)
            if self._enabled then fetchSnapshot() end
        end
    end))

    ----------------------------------------------------------------
    -- CLEANUP
    ----------------------------------------------------------------
    function self.cleanup()
        if self._destroyed then return end
        self._destroyed = true
        self._enabled = false
        for _, c in ipairs(self._connections) do
            pcall(function() c:Disconnect() end)
        end
        self._connections = {}
    end

    return self
end

return Core
