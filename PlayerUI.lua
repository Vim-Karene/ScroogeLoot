-- PlayerUI.lua
-- Handles the UI for players in the Scrooge Loot addon

-- Addon namespace
local ScroogeLoot = ScroogeLoot or {}

-- Create Player Window Frame
local PlayerUI = CreateFrame("Frame", "ScroogeLoot_PlayerFrame", UIParent, "BackdropTemplate")
PlayerUI:SetSize(400, 300)
PlayerUI:SetPoint("CENTER")
PlayerUI:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
PlayerUI:SetMovable(true)
PlayerUI:EnableMouse(true)
PlayerUI:RegisterForDrag("LeftButton")
PlayerUI:SetScript("OnDragStart", PlayerUI.StartMoving)
PlayerUI:SetScript("OnDragStop", PlayerUI.StopMovingOrSizing)
PlayerUI:Hide()

-- Title
local title = PlayerUI:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("Scrooge Loot - Player Window")

-- Timer Display
local timerText = PlayerUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
timerText:SetPoint("TOP", 0, -40)
timerText:SetText("Time Remaining: 5:00")

-- Token and Debt Points Display
local pointsText = PlayerUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
pointsText:SetPoint("TOP", 0, -70)
pointsText:SetText("Token Points: 0 | Debt Points: 0")

-- Attendance Display
local attendanceText = PlayerUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
attendanceText:SetPoint("TOP", 0, -100)
attendanceText:SetText("Attendance: 0%")

-- Loot Item Display
local lootItemText = PlayerUI:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lootItemText:SetPoint("TOP", 0, -130)
lootItemText:SetText("Rolling on: [No Item]")

-- Roll Buttons
local buttonWidth, buttonHeight = 100, 24

local function CreateRollButton(name, label, point, relativeTo, offsetX)
    local button = CreateFrame("Button", name, PlayerUI, "UIPanelButtonTemplate")
    button:SetSize(buttonWidth, buttonHeight)
    button:SetPoint("TOP", relativeTo, "BOTTOM", offsetX, -10)
    button:SetText(label)
    button:Disable()
    return button
end

-- Token Roll Button
local tokenRollButton = CreateRollButton("ScroogeLoot_TokenRollButton", "Token Roll", "TOP", lootItemText, -120)

-- Raider Roll Button
local raiderRollButton = CreateRollButton("ScroogeLoot_RaiderRollButton", "Raider Roll", "TOP", lootItemText, 0)

-- Main-Spec Roll Button
local mainSpecButton = CreateRollButton("ScroogeLoot_MainSpecButton", "Main-Spec", "TOP", lootItemText, 120)

-- Off-Spec Roll Button
local offSpecButton = CreateRollButton("ScroogeLoot_OffSpecButton", "Off-Spec", "TOP", raiderRollButton, 0)

-- Roll Buttons Enable/Disable Logic
function ScroogeLoot.UpdatePlayerRollButtons(rollOptions)
    -- rollOptions is a table: { token = true/false, raider = true/false, mainSpec = true/false, offSpec = true/false }
    tokenRollButton:SetEnabled(rollOptions.token)
    raiderRollButton:SetEnabled(rollOptions.raider)
    mainSpecButton:SetEnabled(rollOptions.mainSpec)
    offSpecButton:SetEnabled(rollOptions.offSpec)
end

-- Set Player Info
function ScroogeLoot.SetPlayerInfo(timer, tokenPoints, debtPoints, attendance, item)
    timerText:SetText("Time Remaining: " .. timer)
    pointsText:SetText("Token Points: " .. tokenPoints .. " | Debt Points: " .. debtPoints)
    attendanceText:SetText("Attendance: " .. attendance .. "%")
    lootItemText:SetText("Rolling on: " .. item)
end

-- Show the Player UI
function ScroogeLoot.ShowPlayerUI(timer, tokenPoints, debtPoints, attendance, item, rollOptions)
    ScroogeLoot.SetPlayerInfo(timer, tokenPoints, debtPoints, attendance, item)
    ScroogeLoot.UpdatePlayerRollButtons(rollOptions)
    PlayerUI:Show()
end

-- Hide the Player UI
function ScroogeLoot.HidePlayerUI()
    PlayerUI:Hide()
end

-- Example Usage (Remove before release)
--[[ Uncomment for testing
ScroogeLoot.ShowPlayerUI("3:45", 50, 10, 85, "[Awesome Sword of Power]", {
    token = true,
    raider = false,
    mainSpec = true,
    offSpec = true
})
]]--
