-- SpreadsheetHandler.lua
-- Handles importing, parsing, and managing the lootsheet for the Scrooge Loot addon

-- Addon namespace
local ScroogeLoot = ScroogeLoot or {}

-- Table to store the active lootsheet data
local LootsheetData = {
    Players = {}, -- Format: { [playerName] = { class, guild, rank, tokenPoints, debtPoints, attendance } }
    Attendance = {}, -- Format: { [date] = { player1, player2, ... } }
}

-- Utility: Parse CSV content
local function ParseCSV(content)
    local rows = {}
    for line in content:gmatch("[^
\n]+") do
        local row = {}
        for value in line:gmatch("[^,]+") do
            table.insert(row, value:match("^%s*(.-)%s*$")) -- Trim spaces
        end
        table.insert(rows, row)
    end
    return rows
end

-- Function: Import Lootsheet from File Content
function ScroogeLoot.ImportLootsheet(content)
    local rows = ParseCSV(content)
    if not rows or #rows == 0 then
        print("ScroogeLoot: Invalid lootsheet file format.")
        return false
    end

    -- Process Players page
    LootsheetData.Players = {}
    local headers = rows[1] -- Assume first row is headers
    for i = 2, #rows do
        local row = rows[i]
        if #row >= 7 then
            local playerName = row[1]
            LootsheetData.Players[playerName] = {
                class = row[2],
                guild = row[3],
                rank = row[4],
                tokenPoints = tonumber(row[5]) or 0,
                debtPoints = tonumber(row[6]) or 0,
                attendance = tonumber(row[7]) or 0,
            }
        end
    end

    print("ScroogeLoot: Lootsheet successfully imported.")
    return true
end

-- Function: Update Attendance Data
function ScroogeLoot.UpdateAttendance(date, attendingPlayers)
    LootsheetData.Attendance[date] = attendingPlayers
    print("ScroogeLoot: Attendance updated for date " .. date)
end

-- Function: Get Player Info
function ScroogeLoot.GetPlayerInfo(playerName)
    return LootsheetData.Players[playerName]
end

-- Function: Update Player Points (Token/Debt)
function ScroogeLoot.UpdatePlayerPoints(playerName, tokenChange, debtChange)
    local player = LootsheetData.Players[playerName]
    if not player then return end

    player.tokenPoints = math.max(0, player.tokenPoints + (tokenChange or 0))
    player.debtPoints = math.max(0, player.debtPoints + (debtChange or 0))
    print("ScroogeLoot: Updated points for " .. playerName .. ". Token: " .. player.tokenPoints .. ", Debt: " .. player.debtPoints)
end

-- Function: Switch Active Lootsheet
function ScroogeLoot.SwitchLootsheet(newContent)
    if ScroogeLoot.ImportLootsheet(newContent) then
        print("ScroogeLoot: Active lootsheet switched successfully.")
    else
        print("ScroogeLoot: Failed to switch lootsheet.")
    end
end

-- Function: List All Players (Debugging/Testing)
function ScroogeLoot.DebugListPlayers()
    print("--- ScroogeLoot: Player List ---")
    for playerName, info in pairs(LootsheetData.Players) do
        print(playerName .. " | Class: " .. info.class .. " | Token: " .. info.tokenPoints .. " | Debt: " .. info.debtPoints .. " | Attendance: " .. info.attendance .. "%")
    end
end

-- Example Usage (Testing Only)
--[[ Uncomment to test
local exampleCSV = [[
Name,Class,Guild,Rank,Token Points,Debt Points,Attendance
Player1,Warrior,GuildA,Raider,50,25,85
Player2,Mage,GuildB,Member,30,10,75
Player3,Rogue,GuildA,Officer,0,50,95
]]

ScroogeLoot.ImportLootsheet(exampleCSV)
ScroogeLoot.DebugListPlayers()
ScroogeLoot.UpdatePlayerPoints("Player1", 10, -5)
ScroogeLoot.UpdateAttendance("2024-06-15", {"Player1", "Player3"})
]]--
