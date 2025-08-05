-- Simple player registration and attendance update

local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")

PlayerDB = PlayerDB or {}

local function InitializePlayerData(playerName, class)
    if not PlayerDB[playerName] then
        PlayerDB[playerName] = {
            name = playerName,
            class = class,
            raiderrank = false,
            SP = 0,
            DP = 0,
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
    if not addon.isMasterLooter then return end
    InitializePlayerData(name, class)
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

