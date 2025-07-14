-- PlayerData holds raid member information such as class and attendance.
-- Only the master looter may modify the table.

local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")

addon.PlayerData = addon.PlayerData or {}

-- Creates entry for player if not present
local function EnsurePlayer(name)
    if not addon.PlayerData[name] then
        addon.PlayerData[name] = {
            class = "",
            raiderrank = false,
            SP = 0,
            DP = 0,
            attended = 0,
            absent = 0,
            attendance = 100,
            item1 = nil, item1received = false,
            item2 = nil, item2received = false,
            item3 = nil, item3received = false,
        }
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

