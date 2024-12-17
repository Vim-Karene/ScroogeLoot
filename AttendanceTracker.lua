-- AttendanceTracker.lua
-- Handles tracking and updating raid attendance for the Scrooge Loot addon

-- Addon namespace
local ScroogeLoot = ScroogeLoot or {}

local AttendanceTracker = {}
ScroogeLoot.AttendanceTracker = AttendanceTracker

-- Table to store attendance data
local attendanceData = {
    -- Format: [date] = { player1 = true, player2 = true, ... }
}

-- Function: Mark player attendance for a specific date
function AttendanceTracker.MarkAttendance(date, playerName)
    if not attendanceData[date] then
        attendanceData[date] = {}
    end
    attendanceData[date][playerName] = true
    print("ScroogeLoot: Marked attendance for " .. playerName .. " on " .. date)
end

-- Function: Get attendance for a specific player
function AttendanceTracker.GetPlayerAttendance(playerName)
    local totalRaids = 0
    local attendedRaids = 0
    for date, players in pairs(attendanceData) do
        totalRaids = totalRaids + 1
        if players[playerName] then
            attendedRaids = attendedRaids + 1
        end
    end
    local attendancePercentage = totalRaids > 0 and (attendedRaids / totalRaids) * 100 or 0
    return ScroogeLoot.Utilities.Round(attendancePercentage, 2)
end

-- Function: Get attendance data for all players
function AttendanceTracker.GetAllAttendance()
    local attendanceSummary = {}
    for date, players in pairs(attendanceData) do
        for playerName, _ in pairs(players) do
            if not attendanceSummary[playerName] then
                attendanceSummary[playerName] = 0
            end
            attendanceSummary[playerName] = attendanceSummary[playerName] + 1
        end
    end
    return attendanceSummary
end

-- Function: Update attendance for a raid group
function AttendanceTracker.UpdateRaidAttendance(date, playerList)
    if not date or not playerList then return end
    attendanceData[date] = {}
    for _, playerName in ipairs(playerList) do
        attendanceData[date][playerName] = true
    end
    print("ScroogeLoot: Attendance updated for raid on " .. date)
end

-- Function: Debug attendance data
function AttendanceTracker.DebugAttendance()
    print("--- Attendance Data ---")
    for date, players in pairs(attendanceData) do
        print("Date: " .. date)
        for playerName, _ in pairs(players) do
            print("  - " .. playerName)
        end
    end
end

-- Example Usage (Testing Only)
--[[ Uncomment to test
AttendanceTracker.MarkAttendance("2024-06-15", "Player1")
AttendanceTracker.MarkAttendance("2024-06-15", "Player2")
AttendanceTracker.MarkAttendance("2024-06-16", "Player1")

print("Player1 Attendance: " .. AttendanceTracker.GetPlayerAttendance("Player1") .. "%")
print("Player2 Attendance: " .. AttendanceTracker.GetPlayerAttendance("Player2") .. "%")
AttendanceTracker.DebugAttendance()
]]--