-- LootManager.lua
-- Core logic for managing loot distribution and rolls in the Scrooge Loot addon

-- Addon namespace
local ScroogeLoot = ScroogeLoot or {}

-- Tables to store roll data and loot information
local rollData = {}  -- Format: { [itemName] = { token = {}, raider = {}, mainSpec = {}, offSpec = {}, scrooge = {} } }
local activeLoot = nil -- Currently active loot item
local lootTimer = 300 -- Default loot timer in seconds
local timerRunning = false

-- Utility: Reset rolls for a given item
local function ResetRolls(itemName)
    rollData[itemName] = {
        token = {},
        scrooge = {},
        raider = {},
        mainSpec = {},
        offSpec = {},
    }
end

-- Utility: Sort rolls
local function SortRolls(rolls)
    table.sort(rolls, function(a, b) return a.roll > b.roll end)
end

-- Function: Start Loot Roll Timer
local function StartLootTimer(duration, onComplete)
    lootTimer = duration or 300
    timerRunning = true
    C_Timer.NewTicker(1, function()
        if lootTimer > 0 then
            lootTimer = lootTimer - 1
            if activeLoot then
                ScroogeLoot.UpdateLootTimer(lootTimer)
            end
        else
            timerRunning = false
            if onComplete then
                onComplete()
            end
        end
    end, duration or 300)
end

-- Function: Handle Player Roll
function ScroogeLoot.PlayerRoll(playerName, rollType, rollValue)
    if not activeLoot then return end
    local rolls = rollData[activeLoot][rollType]
    table.insert(rolls, { name = playerName, roll = rollValue })
    SortRolls(rolls)
    ScroogeLoot.BroadcastRollUpdate(activeLoot)
end

-- Function: Determine Loot Winner
function ScroogeLoot.DetermineWinner()
    if not activeLoot then return end

    local winner = nil
    local rollTypes = { "token", "scrooge", "raider", "mainSpec", "offSpec" }

    for _, rollType in ipairs(rollTypes) do
        local rolls = rollData[activeLoot][rollType]
        if #rolls > 0 then
            winner = rolls[1]  -- Highest roll
            print("Winner for " .. activeLoot .. " is: " .. winner.name .. " with a " .. rollType .. " roll!")
            break
        end
    end

    if not winner then
        print("No valid rolls for: " .. activeLoot)
    end

    return winner
end

-- Function: Set Active Loot Item
function ScroogeLoot.SetActiveLoot(itemName)
    activeLoot = itemName
    ResetRolls(itemName)
    ScroogeLoot.BroadcastActiveLoot(itemName)
    StartLootTimer(300, function()
        print("Time's up for: " .. activeLoot)
        ScroogeLoot.DetermineWinner()
        ScroogeLoot.ClearActiveLoot()
    end)
end

-- Function: Clear Active Loot Item
function ScroogeLoot.ClearActiveLoot()
    activeLoot = nil
    timerRunning = false
    ScroogeLoot.BroadcastClearLoot()
end

-- Function: Update Timer UI (Placeholder)
function ScroogeLoot.UpdateLootTimer(timeRemaining)
    -- Broadcast timer update to Player UI
    print("Loot timer updated: " .. timeRemaining .. " seconds left")
end

-- Function: Broadcast Roll Updates
function ScroogeLoot.BroadcastRollUpdate(itemName)
    -- Placeholder for sending roll updates to all players
    print("Broadcasting updated rolls for: " .. itemName)
end

-- Function: Broadcast Active Loot to Players
function ScroogeLoot.BroadcastActiveLoot(itemName)
    -- Placeholder for informing players about the active loot
    print("Broadcasting active loot: " .. itemName)
end

-- Function: Broadcast Clear Loot
function ScroogeLoot.BroadcastClearLoot()
    -- Placeholder for clearing loot info in player UIs
    print("Clearing active loot information.")
end

-- Example Usage (Remove before release)
--[[ Uncomment for testing
ScroogeLoot.SetActiveLoot("[Legendary Sword of Awesomeness]")
C_Timer.After(5, function()
    ScroogeLoot.PlayerRoll("Player1", "token", 95)
    ScroogeLoot.PlayerRoll("Player2", "raider", 88)
    ScroogeLoot.PlayerRoll("Player3", "mainSpec", 90)
end)
]]--
