-- PlayerData holds raid member information such as class and attendance.
-- Only the master looter may modify the table.

local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")

addon.PlayerData = addon.PlayerData or {}

-- Creates entry for player if not present
local function EnsurePlayer(name)
    if not addon.PlayerData[name] then
        addon.PlayerData[name] = {
            name = name,
            class = "",
            raiderrank = false,
            SP = 0,
            DP = 0, -- capped at 200 when updated
            attended = 0,
            absent = 0,
            attendance = 100,
            item1 = nil, item1received = false,
            item2 = nil, item2received = false,
            item3 = nil, item3received = false,
        }
    elseif not addon.PlayerData[name].name then
        addon.PlayerData[name].name = name
    end
end

-- Ensure all entries have their name field set
function addon:EnsureNameFields()
    for n, data in pairs(self.PlayerData) do
        if not data.name then
            data.name = n
        end
    end
end

-- expose helper
addon.EnsurePlayer = EnsurePlayer

--- Populate PlayerData with members of the current group/raid
function addon:PopulatePlayerDataFromGroup()
    local changed = false

    local function addUnit(unit)
        local name = UnitName(unit)
        if name then
            local _, class = UnitClass(unit)
            if not self.PlayerData[name] then
                EnsurePlayer(name)
                changed = true
            end
            self.PlayerData[name].class = class
        end
    end

    if self:IsInRaid() then
        for i = 1, self:GetNumGroupMembers() do
            addUnit("raid" .. i)
        end
    elseif self:IsInGroup() then
        for i = 1, self:GetNumGroupMembers() do
            addUnit("party" .. i)
        end
    end

    addUnit("player")

    return changed
end

-- Update an arbitrary field on a player. Only works for the master looter.
function addon:SetPlayerField(name, field, value)
    if not self.isMasterLooter then return end
    EnsurePlayer(name)
    if field == "DP" then
        value = math.min(200, tonumber(value) or 0)
    end
    self.PlayerData[name][field] = value
    self:BroadcastPlayerData()
end

-- Increment attendance values and update derived attendance field.
function addon:ModifyAttendance(name, attendedInc, absentInc)
    if not self.isMasterLooter then return end
    EnsurePlayer(name)
    local data = self.PlayerData[name]
    data.attended = (data.attended or 0) + (attendedInc or 0)
    data.absent = (data.absent or 0) + (absentInc or 0)
    local total = data.attended + data.absent
    if total > 0 then
        data.attendance = math.floor((data.attended / total) * 100)
    else
        data.attendance = 100
    end
    self:BroadcastPlayerData()
end

-- Retrieve a player's data table (read only)
function addon:GetPlayerData(name)
    EnsurePlayer(name)
    return self.PlayerData[name]
end

-- Broadcast the complete PlayerData table to the raid.
function addon:BroadcastPlayerData()
    if self.playerDB and self.playerDB.global then
        self.playerDB.global.playerData = self.PlayerData
    end
    if not self.isMasterLooter then return end
    -- Send to everyone in the current group/raid
    self:SendCommand("group", "playerData", self.PlayerData)
end


-- Simple player registration and attendance update
local addonName = ...
PlayerDB = PlayerDB or {}

local function ClampDP(v)
    v = tonumber(v) or 0
    if v > 200 then v = 200 end
    if v < 0 then v = 0 end
    return v
end

local function InitializePlayerData(playerName, class)
    if not PlayerDB[playerName] then
        PlayerDB[playerName] = {
            name = playerName,
            class = class,
            raiderrank = false,
            SP = 0,
            DP = ClampDP(0),
            attended = 0,
            absent = 0,
            attendance = 0,
            item1 = "",
            item1received = false,
            item2 = "",
            item2received = false,
            item3 = "",
            item3received = false,
        }
    else
        local player = PlayerDB[playerName]
        local keepFields = {
            name = true, class = true, raiderrank = true,
            SP = true, DP = true, attended = true, absent = true, attendance = true,
            item1 = true, item1received = true,
            item2 = true, item2received = true,
            item3 = true, item3received = true,
        }
        for k in pairs(player) do
            if not keepFields[k] then
                player[k] = nil
            end
        end
        player.DP = ClampDP(player.DP)
        -- Fill missing fields
        for k in pairs(keepFields) do
            if player[k] == nil then
                InitializePlayerData(playerName, class)
                return
            end
        end
    end
end

local function UpdateAttendance(playerName)
    local player = PlayerDB[playerName]
    if not player then return end
    local total = player.attended + player.absent
    player.attendance = (total > 0) and math.floor((player.attended / total) * 100) or 0
end

function RegisterPlayer(name, class)
    InitializePlayerData(name, class)
    if PlayerDB[name] then
        PlayerDB[name].DP = ClampDP(PlayerDB[name].DP)
    end
    UpdateAttendance(name)
end

-- Command for testing
SLASH_SCROOGELOOT1 = "/scrooge"
SlashCmdList["SCROOGELOOT"] = function(msg)
    local name, class = UnitName("player"), select(2, UnitClass("player"))
    RegisterPlayer(name, class)
    print("Registered:", name)
    print("Attendance:", PlayerDB[name].attendance .. "%")
end

