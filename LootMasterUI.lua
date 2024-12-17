-- LootMasterUI.lua
-- Handles the UI for the Loot Master in Scrooge Loot addon

-- Addon namespace
local ScroogeLoot = ScroogeLoot or {}

-- Create Loot Master Window Frame
local LootMasterUI = CreateFrame("Frame", "ScroogeLoot_LootMasterFrame", UIParent, "BackdropTemplate")
LootMasterUI:SetSize(500, 400)
LootMasterUI:SetPoint("CENTER")
LootMasterUI:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
LootMasterUI:SetMovable(true)
LootMasterUI:EnableMouse(true)
LootMasterUI:RegisterForDrag("LeftButton")
LootMasterUI:SetScript("OnDragStart", LootMasterUI.StartMoving)
LootMasterUI:SetScript("OnDragStop", LootMasterUI.StopMovingOrSizing)
LootMasterUI:Hide()

-- Title
local title = LootMasterUI:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("Scrooge Loot - Loot Master Window")

-- Close Button
local closeButton = CreateFrame("Button", nil, LootMasterUI, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function() LootMasterUI:Hide() end)

-- Loot Table Display
local lootList = CreateFrame("ScrollFrame", "ScroogeLoot_LootScrollFrame", LootMasterUI, "UIPanelScrollFrameTemplate")
lootList:SetPoint("TOPLEFT", 20, -50)
lootList:SetSize(460, 200)

local lootContent = CreateFrame("Frame", "ScroogeLoot_LootContentFrame", lootList)
lootContent:SetSize(460, 200)
lootList:SetScrollChild(lootContent)

-- Function to Populate Loot List
function ScroogeLoot.PopulateLootList(lootData)
    -- Clear previous content
    if lootContent.buttons then
        for _, button in pairs(lootContent.buttons) do
            button:Hide()
        end
    end
    lootContent.buttons = {}

    local offsetY = -10
    for index, loot in ipairs(lootData) do
        local button = CreateFrame("Button", nil, lootContent, "UIPanelButtonTemplate")
        button:SetSize(440, 24)
        button:SetPoint("TOPLEFT", 10, offsetY)
        button:SetText(loot.itemName .. " - Top Roll: " .. (loot.topRoll or "N/A"))
        button:SetScript("OnClick", function()
            ScroogeLoot.ShowLootDetails(loot)
        end)
        table.insert(lootContent.buttons, button)
        offsetY = offsetY - 30
    end
    lootContent:SetSize(460, math.abs(offsetY))
end

-- Show Loot Details
function ScroogeLoot.ShowLootDetails(loot)
    print("Showing details for:", loot.itemName)
    -- TODO: Implement detailed loot information display
end

-- Attendance Percentage Display
local attendanceText = LootMasterUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
attendanceText:SetPoint("BOTTOMLEFT", 20, 20)
attendanceText:SetText("Attendance Percentage: Loading...")

function ScroogeLoot.UpdateAttendance(attendance)
    attendanceText:SetText("Attendance Percentage: " .. attendance .. "%")
end

-- Show the Loot Master UI
function ScroogeLoot.ShowLootMasterUI(lootData, attendance)
    ScroogeLoot.PopulateLootList(lootData)
    ScroogeLoot.UpdateAttendance(attendance)
    LootMasterUI:Show()
end

-- Hide the Loot Master UI
function ScroogeLoot.HideLootMasterUI()
    LootMasterUI:Hide()
end

-- Example Usage (Remove before release)
--[[ Uncomment for testing
ScroogeLoot.ShowLootMasterUI({
    { itemName = "[Example Item 1]", topRoll = 98 },
    { itemName = "[Example Item 2]", topRoll = 92 },
    { itemName = "[Example Item 3]", topRoll = 87 },
}, 85)
]]--
