--[[
    Steal an Egg — Auto Grab UI module
    Returns a table with .new(catalog) that builds the panel and
    exposes methods for the core to update.
]]

local Players   = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local COLORS = {
    bg       = Color3.fromRGB(15, 15, 22),
    bgAlt    = Color3.fromRGB(22, 22, 32),
    accent   = Color3.fromRGB(120, 255, 160),
    warn     = Color3.fromRGB(255, 180, 100),
    err      = Color3.fromRGB(255, 120, 120),
    text     = Color3.fromRGB(220, 220, 235),
    textDim  = Color3.fromRGB(140, 140, 160),
    border   = Color3.fromRGB(60, 80, 70),
}

local UI = {}

function UI.new(catalog)
    local self = {
        _connections = {},
        _destroyed = false,
        _selected = nil,
        _enabled = false,
        _onToggle = nil,
        _onSafeZone = nil,
    }

    ----------------------------------------------------------------
    -- ROOT
    ----------------------------------------------------------------
    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoGrabUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 99999
    gui.Parent = PlayerGui
    self.gui = gui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.new(1, -20, 0, 20)
    panel.Size = UDim2.fromOffset(300, 440)
    panel.BackgroundColor3 = COLORS.bg
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = true
    panel.Parent = gui
    self.panel = panel

    local pc = Instance.new("UICorner", panel)
    pc.CornerRadius = UDim.new(0, 14)

    local ps = Instance.new("UIStroke", panel)
    ps.Color = COLORS.accent
    ps.Thickness = 1
    ps.Transparency = 0.6

    ----------------------------------------------------------------
    -- HEADER
    ----------------------------------------------------------------
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = COLORS.bgAlt
    header.BorderSizePixel = 0
    header.Parent = panel

    local hc = Instance.new("UICorner", header)
    hc.CornerRadius = UDim.new(0, 14)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.fromOffset(14, 0)
    titleLbl.Size = UDim2.new(1, -60, 1, 0)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14
    titleLbl.TextColor3 = COLORS.accent
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = "🥚  AUTO GRAB"
    titleLbl.Parent = header

    local minBtn = Instance.new("TextButton")
    minBtn.AnchorPoint = Vector2.new(1, 0.5)
    minBtn.Position = UDim2.new(1, -10, 0.5, 0)
    minBtn.Size = UDim2.fromOffset(22, 22)
    minBtn.BackgroundColor3 = COLORS.bg
    minBtn.BackgroundTransparency = 0.3
    minBtn.BorderSizePixel = 0
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 14
    minBtn.TextColor3 = COLORS.accent
    minBtn.Text = "−"
    minBtn.Parent = header

    local mc = Instance.new("UICorner", minBtn)
    mc.CornerRadius = UDim.new(0, 6)

    local content = Instance.new("Frame")
    content.Position = UDim2.fromOffset(0, 36)
    content.Size = UDim2.new(1, 0, 1, -36)
    content.BackgroundTransparency = 1
    content.Parent = panel

    local minimized = false
    table.insert(self._connections, minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        content.Visible = not minimized
        panel.Size = minimized and UDim2.fromOffset(300, 36) or UDim2.fromOffset(300, 440)
        minBtn.Text = minimized and "+" or "−"
    end))

    ----------------------------------------------------------------
    -- TARGET DROPDOWN
    ----------------------------------------------------------------
    local targetLbl = Instance.new("TextLabel")
    targetLbl.BackgroundTransparency = 1
    targetLbl.Position = UDim2.fromOffset(14, 8)
    targetLbl.Size = UDim2.new(1, -28, 0, 16)
    targetLbl.Font = Enum.Font.GothamBold
    targetLbl.TextSize = 11
    targetLbl.TextColor3 = COLORS.textDim
    targetLbl.TextXAlignment = Enum.TextXAlignment.Left
    targetLbl.Text = "TARGET EGG"
    targetLbl.Parent = content

    local ddBtn = Instance.new("TextButton")
    ddBtn.Position = UDim2.fromOffset(14, 26)
    ddBtn.Size = UDim2.new(1, -28, 0, 32)
    ddBtn.BackgroundColor3 = COLORS.bgAlt
    ddBtn.BorderSizePixel = 0
    ddBtn.Font = Enum.Font.Gotham
    ddBtn.TextSize = 13
    ddBtn.TextColor3 = COLORS.text
    ddBtn.TextXAlignment = Enum.TextXAlignment.Left
    ddBtn.Text = "  Any (default)"
    ddBtn.Parent = content

    local dc = Instance.new("UICorner", ddBtn)
    dc.CornerRadius = UDim.new(0, 8)

    local ds = Instance.new("UIStroke", ddBtn)
    ds.Color = COLORS.border
    ds.Thickness = 1

    local ddArrow = Instance.new("TextLabel")
    ddArrow.BackgroundTransparency = 1
    ddArrow.AnchorPoint = Vector2.new(1, 0.5)
    ddArrow.Position = UDim2.new(1, -10, 0.5, 0)
    ddArrow.Size = UDim2.fromOffset(16, 16)
    ddArrow.Font = Enum.Font.GothamBold
    ddArrow.TextSize = 12
    ddArrow.TextColor3 = COLORS.accent
    ddArrow.Text = "▼"
    ddArrow.Parent = ddBtn

    local searchBox = Instance.new("TextBox")
    searchBox.Position = UDim2.fromOffset(14, 62)
    searchBox.Size = UDim2.new(1, -28, 0, 26)
    searchBox.BackgroundColor3 = COLORS.bgAlt
    searchBox.BorderSizePixel = 0
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 12
    searchBox.TextColor3 = COLORS.text
    searchBox.PlaceholderText = "  Search..."
    searchBox.PlaceholderColor3 = COLORS.textDim
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.Visible = false
    searchBox.ZIndex = 6
    searchBox.Parent = content

    local sbc = Instance.new("UICorner", searchBox)
    sbc.CornerRadius = UDim.new(0, 8)

    local ddList = Instance.new("ScrollingFrame")
    ddList.Position = UDim2.fromOffset(14, 62)
    ddList.Size = UDim2.new(1, -28, 0, 170)
    ddList.BackgroundColor3 = COLORS.bgAlt
    ddList.BorderSizePixel = 0
    ddList.ScrollBarThickness = 6
    ddList.ScrollBarImageColor3 = COLORS.accent
    ddList.CanvasSize = UDim2.new(0, 0, 0, 0)
    ddList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ddList.Visible = false
    ddList.ZIndex = 5
    ddList.Parent = content

    local dlc = Instance.new("UICorner", ddList)
    dlc.CornerRadius = UDim.new(0, 8)

    local dls = Instance.new("UIStroke", ddList)
    dls.Color = COLORS.accent
    dls.Thickness = 1
    dls.Transparency = 0.4

    local dlLayout = Instance.new("UIListLayout", ddList)
    dlLayout.Padding = UDim.new(0, 2)
    dlLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local dlPad = Instance.new("UIPadding", ddList)
    dlPad.PaddingTop = UDim.new(0, 4)
    dlPad.PaddingBottom = UDim.new(0, 4)
    dlPad.PaddingLeft = UDim.new(0, 4)
    dlPad.PaddingRight = UDim.new(0, 4)

    -- Sort catalog by rarity then name
    local sorted = {}
    for _, e in ipairs(catalog) do table.insert(sorted, e) end
    table.sort(sorted, function(a, b)
        if a.rarityNum ~= b.rarityNum then return a.rarityNum > b.rarityNum end
        return string.lower(a.displayName) < string.lower(b.displayName)
    end)

    local currentFilter = ""

    local function rebuildList()
        for _, c in ipairs(ddList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        local items = { { category = nil, displayName = "Any (default)", rarity = nil } }
        for _, e in ipairs(sorted) do table.insert(items, e) end

        local lf = string.lower(currentFilter)
        local shown = 0
        for i, e in ipairs(items) do
            local name = e.displayName
            if lf == "" or string.find(string.lower(name), lf, 1, true) then
                shown = shown + 1
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 26)
                item.BackgroundColor3 = COLORS.bg
                item.BackgroundTransparency = 1
                item.BorderSizePixel = 0
                item.Font = Enum.Font.Gotham
                item.TextSize = 12
                item.TextColor3 = COLORS.text
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.Text = "  " .. name .. (e.rarity and ("  ·  " .. e.rarity) or "")
                item.LayoutOrder = i
                item.Parent = ddList

                table.insert(self._connections, item.MouseEnter:Connect(function()
                    item.BackgroundTransparency = 0.7
                end))
                table.insert(self._connections, item.MouseLeave:Connect(function()
                    item.BackgroundTransparency = 1
                end))
                table.insert(self._connections, item.MouseButton1Click:Connect(function()
                    self._selected = e.category
                    ddBtn.Text = "  " .. name
                    ddList.Visible = false
                    searchBox.Visible = false
                    ddArrow.Text = "▼"
                end))
            end
        end

        if shown == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 30)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.TextColor3 = COLORS.textDim
            empty.Text = "  No matching eggs"
            empty.Parent = ddList
        end
    end

    rebuildList()

    table.insert(self._connections, searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentFilter = searchBox.Text or ""
        rebuildList()
    end))

    table.insert(self._connections, ddBtn.MouseButton1Click:Connect(function()
        local open = not ddList.Visible
        ddList.Visible = open
        searchBox.Visible = open
        ddArrow.Text = open and "▲" or "▼"
        if open then
            currentFilter = ""
            searchBox.Text = ""
            rebuildList()
        end
    end))

    ----------------------------------------------------------------
    -- SAFE ZONE
    ----------------------------------------------------------------
    local safeBtn = Instance.new("TextButton")
    safeBtn.Position = UDim2.fromOffset(14, 240)
    safeBtn.Size = UDim2.new(1, -28, 0, 30)
    safeBtn.BackgroundColor3 = COLORS.bgAlt
    safeBtn.BorderSizePixel = 0
    safeBtn.Font = Enum.Font.GothamBold
    safeBtn.TextSize = 12
    safeBtn.TextColor3 = COLORS.accent
    safeBtn.Text = "📍  Set Safe Zone"
    safeBtn.Parent = content

    local sc = Instance.new("UICorner", safeBtn)
    sc.CornerRadius = UDim.new(0, 8)

    local ss = Instance.new("UIStroke", safeBtn)
    ss.Color = COLORS.accent
    ss.Thickness = 1
    ss.Transparency = 0.5

    local safeStatus = Instance.new("TextLabel")
    safeStatus.BackgroundTransparency = 1
    safeStatus.Position = UDim2.fromOffset(14, 274)
    safeStatus.Size = UDim2.new(1, -28, 0, 16)
    safeStatus.Font = Enum.Font.Code
    safeStatus.TextSize = 11
    safeStatus.TextColor3 = COLORS.textDim
    safeStatus.TextXAlignment = Enum.TextXAlignment.Left
    safeStatus.Text = "Safe Zone: NOT SET"
    safeStatus.Parent = content

    table.insert(self._connections, safeBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            safeStatus.Text = "Safe Zone: SET"
            safeStatus.TextColor3 = COLORS.accent
            if self._onSafeZone then
                self._onSafeZone(hrp.CFrame)
            end
        end
    end))

    ----------------------------------------------------------------
    -- START / STOP
    ----------------------------------------------------------------
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Position = UDim2.fromOffset(14, 298)
    toggleBtn.Size = UDim2.new(1, -28, 0, 38)
    toggleBtn.BackgroundColor3 = COLORS.accent
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    toggleBtn.TextColor3 = COLORS.bg
    toggleBtn.Text = "▶  START"
    toggleBtn.Parent = content

    local tc = Instance.new("UICorner", toggleBtn)
    tc.CornerRadius = UDim.new(0, 10)

    table.insert(self._connections, toggleBtn.MouseButton1Click:Connect(function()
        self._enabled = not self._enabled
        if self._onToggle then
            self._onToggle(self._enabled)
        end
    end))

    ----------------------------------------------------------------
    -- STATUS LABELS
    ----------------------------------------------------------------
    local statusLbl = Instance.new("TextLabel")
    statusLbl.BackgroundTransparency = 1
    statusLbl.Position = UDim2.fromOffset(14, 344)
    statusLbl.Size = UDim2.new(1, -28, 0, 14)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 11
    statusLbl.TextColor3 = COLORS.text
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Text = "Status: Idle"
    statusLbl.Parent = content

    local lastLbl = Instance.new("TextLabel")
    lastLbl.BackgroundTransparency = 1
    lastLbl.Position = UDim2.fromOffset(14, 360)
    lastLbl.Size = UDim2.new(1, -28, 0, 14)
    lastLbl.Font = Enum.Font.Gotham
    lastLbl.TextSize = 11
    lastLbl.TextColor3 = COLORS.text
    lastLbl.TextXAlignment = Enum.TextXAlignment.Left
    lastLbl.Text = "Last: —"
    lastLbl.Parent = content

    local statsLbl = Instance.new("TextLabel")
    statsLbl.BackgroundTransparency = 1
    statsLbl.Position = UDim2.fromOffset(14, 376)
    statsLbl.Size = UDim2.new(1, -28, 0, 14)
    statsLbl.Font = Enum.Font.Code
    statsLbl.TextSize = 10
    statsLbl.TextColor3 = COLORS.accent
    statsLbl.TextXAlignment = Enum.TextXAlignment.Left
    statsLbl.Text = "Grabbed: 0 · Failed: 0 · Returns: 0"
    statsLbl.Parent = content

    local fieldLbl = Instance.new("TextLabel")
    fieldLbl.BackgroundTransparency = 1
    fieldLbl.Position = UDim2.fromOffset(14, 392)
    fieldLbl.Size = UDim2.new(1, -28, 0, 14)
    fieldLbl.Font = Enum.Font.Code
    fieldLbl.TextSize = 10
    fieldLbl.TextColor3 = COLORS.textDim
    fieldLbl.TextXAlignment = Enum.TextXAlignment.Left
    fieldLbl.Text = "Field eggs: 0"
    fieldLbl.Parent = content

    local catalogLbl = Instance.new("TextLabel")
    catalogLbl.BackgroundTransparency = 1
    catalogLbl.Position = UDim2.fromOffset(14, 408)
    catalogLbl.Size = UDim2.new(1, -28, 0, 14)
    catalogLbl.Font = Enum.Font.Code
    catalogLbl.TextSize = 10
    catalogLbl.TextColor3 = COLORS.textDim
    catalogLbl.TextXAlignment = Enum.TextXAlignment.Left
    catalogLbl.Text = "Catalog: 0 entries"
    catalogLbl.Parent = content

    ----------------------------------------------------------------
    -- EXPOSED METHODS
    ----------------------------------------------------------------
    function self.setStatus(text)
        statusLbl.Text = "Status: " .. text
    end

    function self.setLast(text)
        lastLbl.Text = "Last: " .. text
    end

    function self.setStats(stats)
        statsLbl.Text = string.format(
            "Grabbed: %d · Failed: %d · Returns: %d",
            stats.grabbed or 0, stats.failed or 0, stats.returned or 0
        )
    end

    function self.setFieldCount(n)
        fieldLbl.Text = "Field eggs: " .. n
    end

    function self.setCatalogCount(n)
        catalogLbl.Text = "Catalog: " .. n .. " entries"
    end

    function self.getSelected()
        return self._selected
    end

    function self.setSafeZoneText(text, color)
        safeStatus.Text = text
        safeStatus.TextColor3 = color or COLORS.textDim
    end

    function self.onToggle(cb)
        self._onToggle = cb
    end

    function self.onSafeZone(cb)
        self._onSafeZone = cb
    end

    function self.refreshToggleVisual()
        if self._enabled then
            toggleBtn.Text = "■  STOP"
            toggleBtn.BackgroundColor3 = COLORS.warn
            statusLbl.TextColor3 = COLORS.accent
        else
            toggleBtn.Text = "▶  START"
            toggleBtn.BackgroundColor3 = COLORS.accent
            statusLbl.TextColor3 = COLORS.textDim
        end
    end

    function self.destroy()
        self._destroyed = true
        for _, c in ipairs(self._connections) do
            pcall(function() c:Disconnect() end)
        end
        self._connections = {}
        if self.gui then
            pcall(function() self.gui:Destroy() end)
        end
    end

    self.setCatalogCount(#catalog)
    self.refreshToggleVisual()

    return self
end

return UI
