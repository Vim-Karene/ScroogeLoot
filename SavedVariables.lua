-- SavedVariables.lua
-- Manages persistent storage for Scrooge Loot addon data

-- Addon namespace
local ScroogeLoot = ScroogeLoot or {}

local SavedVariables = {}
ScroogeLoot.SavedVariables = SavedVariables

-- Default data structure
local defaultData = {
    lootSheets = {},       -- Stored lootsheets, indexed by name
    attendance = {},       -- Player attendance data
    tokenPoints = {},      -- Token points for each player
    debtPoints = {},       -- Debt points for each player
}

-- Table to hold saved data in memory
local savedData = nil

-- Function: Initialize saved variables
function SavedVariables.Initialize()
    if not ScroogeLootDB then
        ScroogeLootDB = defaultData
        print("ScroogeLoot: Initialized new saved variables.")
    else
        print("ScroogeLoot: Loaded saved variables.")
    end
    savedData = ScroogeLootDB
end

-- Function: Get active saved data
function SavedVariables.GetData()
    return savedData
end

-- Function: Save a new lootsheet
function SavedVariables.SaveLootSheet(sheetName, sheetData)
    savedData.lootSheets[sheetName] = sheetData
    print("ScroogeLoot: Lootsheet '" .. sheetName .. "' saved.")
end

-- Function: Load a specific lootsheet
function SavedVariables.LoadLootSheet(sheetName)
    return savedData.lootSheets[sheetName] or nil
end

-- Function: Delete a lootsheet
function SavedVariables.DeleteLootSheet(sheetName)
    if savedData.lootSheets[sheetName] then
        savedData.lootSheets[sheetName] = nil
        print("ScroogeLoot: Lootsheet '" .. sheetName .. "' deleted.")
    else
        print("ScroogeLoot: Lootsheet '" .. sheetName .. "' not found.")
    end
end

-- Function: Update token points for a player
function SavedVariables.UpdateTokenPoints(playerName, points)
    savedData.tokenPoints[playerName] = (savedData.tokenPoints[playerName] or 0) + points
    print("ScroogeLoot: Updated token points for " .. playerName .. " to " .. savedData.tokenPoints[playerName])
end

-- Function: Update debt points for a player
function SavedVariables.UpdateDebtPoints(playerName, points)
    savedData.debtPoints[playerName] = (savedData.debtPoints[playerName] or 0) + points
    print("ScroogeLoot: Updated debt points for " .. playerName .. " to " .. savedData.debtPoints[playerName])
end

-- Function: Get token points for a player
function SavedVariables.GetTokenPoints(playerName)
    return savedData.tokenPoints[playerName] or 0
end

-- Function: Get debt points for a player
function SavedVariables.GetDebtPoints(playerName)
    return savedData.debtPoints[playerName] or 0
end

-- Function: Save attendance data
function SavedVariables.SaveAttendance(date, playerList)
    savedData.attendance[date] = playerList
    print("ScroogeLoot: Attendance for " .. date .. " saved.")
end

-- Function: Get attendance data for a specific date
function SavedVariables.GetAttendance(date)
    return savedData.attendance[date] or {}
end

-- Function: Reset all saved variables
function SavedVariables.Reset()
    ScroogeLootDB = defaultData
    savedData = ScroogeLootDB
    print("ScroogeLoot: All saved data has been reset.")
end

-- Example Usage (Testing)
--[[ Uncomment for testing
SavedVariables.Initialize()
SavedVariables.SaveLootSheet("Raid1", { player1 = { token = 50 }, player2 = { token = 30 } })
local sheet = SavedVariables.LoadLootSheet("Raid1")
print("Loaded Lootsheet:", sheet)

SavedVariables.UpdateTokenPoints("Player1", 25)
SavedVariables.UpdateDebtPoints("Player1", 10)
print("Player1 Token Points:", SavedVariables.GetTokenPoints("Player1"))
print("Player1 Debt Points:", SavedVariables.GetDebtPoints("Player1"))

SavedVariables.SaveAttendance("2024-06-17", { "Player1", "Player2" })
local attendance = SavedVariables.GetAttendance("2024-06-17")
print("Attendance on 2024-06-17:", table.concat(attendance, ", "))
]]--