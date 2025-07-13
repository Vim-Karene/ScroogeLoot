
-- candidateData holds raid member information used when evaluating loot
-- candidates. Only the master looter may modify the table.

local SL = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")

SL.candidateData = SL.candidateData or {}

-- Creates entry for player if not present
local function EnsureCandidate(name)
    if not SL.candidateData[name] then
        SL.candidateData[name] = {
            name = name,
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
SL.EnsureCandidate = EnsureCandidate

--- Populate candidateData with members of the current group/raid
function SL:PopulateCandidateDataFromGroup()
    local function addUnit(unit)
        local name = UnitName(unit)
        if name then
            local _, class = UnitClass(unit)
            EnsureCandidate(name)
            self.candidateData[name].class = class
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
end

-- Update an arbitrary field on a player. Only works for the master looter.
function SL:SetCandidateField(name, field, value)
    if not self.isMasterLooter then return end
    EnsureCandidate(name)
    self.candidateData[name][field] = value
    self:BroadcastCandidateData()
end

-- Increment attendance values and update derived attendance field.
function SL:ModifyAttendance(name, attendedInc, absentInc)
    if not self.isMasterLooter then return end
    EnsureCandidate(name)
    local data = self.candidateData[name]
    data.attended = (data.attended or 0) + (attendedInc or 0)
    data.absent = (data.absent or 0) + (absentInc or 0)
    local total = data.attended + data.absent
    if total > 0 then
        data.attendance = math.floor((data.attended / total) * 100)
    else
        data.attendance = 100
    end
    self:BroadcastCandidateData()
end

-- Retrieve a player's data table (read only)
function SL:GetCandidateData(name)
    EnsureCandidate(name)
    return self.candidateData[name]
end

-- Broadcast the complete candidateData table to the raid.
function SL:BroadcastCandidateData()
    if self.db and self.db.global then
        self.db.global.candidateData = self.candidateData
    end
    if not self.isMasterLooter then return end
    -- Send to everyone in the current group/raid
    self:SendCommand("group", "candidateData", self.candidateData)
end

