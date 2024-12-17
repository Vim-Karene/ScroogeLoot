-- Core.lua
-- Initializes the Scrooge Loot addon, registers events, and manages the addon lifecycle

-- Addon namespace
ScroogeLoot = {}

-- Saved variables
local db

-- Event frame
local frame = CreateFrame("Frame")

-- Event registration
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("CHAT_MSG_LOOT")

-- Function to initialize the addon
local function InitializeAddon()
    -- Initialize the saved variables
    if not ScroogeLootDB then
        ScroogeLootDB = {
            players = {},
            lootsheets = {},
            activeLootsheet = nil,
        }
    end
    db = ScroogeLootDB

    print("|cff00ff00Scrooge Loot Loaded|r - Version 1.0")
end

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == "Scrooge Loot" then
        InitializeAddon()
    elseif event == "LOOT_OPENED" then
        ScroogeLoot.HandleLootOpened()
    elseif event == "CHAT_MSG_LOOT" then
        local message = ...
        ScroogeLoot.HandleLootMessage(message)
    end
end)

-- Function to handle LOOT_OPENED event
function ScroogeLoot.HandleLootOpened()
    print("Loot window opened. Preparing to manage loot.")
    -- TODO: Call LootManager to manage the loot items
end

-- Function to handle CHAT_MSG_LOOT event
function ScroogeLoot.HandleLootMessage(message)
    -- Process loot messages here
    print("Loot message received:", message)
    -- TODO: Add logic to track loot messages
end

-- Addon Utility Functions
function ScroogeLoot.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Scrooge Loot]: |r" .. msg)
end
