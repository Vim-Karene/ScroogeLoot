local addonName = ...

-- Basic options panel for editing scroogelootplayerDB
local panel = CreateFrame("Frame", "ScroogeLootOptionsPanel", InterfaceOptionsFramePanelContainer)
panel.name = "ScroogeLoot"

-- Title
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ScroogeLoot - Player Management")

-- Dropdown for player selection
local playerDropdown = CreateFrame("Frame", "ScroogeLootPlayerDropdown", panel, "UIDropDownMenuTemplate")
playerDropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -30)

local selectedPlayer

local function CreateInput(labelText, offsetY)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", playerDropdown, "BOTTOMLEFT", 16, offsetY)
    label:SetText(labelText)

    local editBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    editBox:SetSize(100, 20)
    editBox:SetAutoFocus(false)
    editBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
    return editBox
end

local spBox = CreateInput("SP:", -20)
local dpBox = CreateInput("DP (Max 200):", -50)
local attendedBox = CreateInput("Attended:", -80)
local absentBox = CreateInput("Absent:", -110)
local raidRankBox = CreateInput("Raider Rank (true/false):", -140)

local saveBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
saveBtn:SetSize(100, 25)
saveBtn:SetText("Save Changes")
saveBtn:SetPoint("TOPLEFT", raidRankBox, "BOTTOMLEFT", -10, -20)

saveBtn:SetScript("OnClick", function()
    if not selectedPlayer then return end
    local p = scroogelootplayerDB[selectedPlayer]
    if not p then return end
    p.SP = tonumber(spBox:GetText()) or 0
    p.DP = math.min(tonumber(dpBox:GetText()) or 0, 200)
    p.attended = tonumber(attendedBox:GetText()) or 0
    p.absent = tonumber(absentBox:GetText()) or 0
    p.raiderrank = raidRankBox:GetText():lower() == "true"

    local total = p.attended + p.absent
    p.attendance = (total > 0) and math.floor((p.attended / total) * 100) or 0

    print("Updated:", selectedPlayer)
end)

local function Dropdown_OnClick(self)
    UIDropDownMenu_SetSelectedID(playerDropdown, self:GetID())
    selectedPlayer = self.value

    local p = scroogelootplayerDB[selectedPlayer]
    if not p then return end
    spBox:SetText(p.SP)
    dpBox:SetText(p.DP)
    attendedBox:SetText(p.attended)
    absentBox:SetText(p.absent)
    raidRankBox:SetText(tostring(p.raiderrank))
end

local function InitializeDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo()

    for playerName in pairs(scroogelootplayerDB or {}) do
        info = UIDropDownMenu_CreateInfo()
        info.text = playerName
        info.value = playerName
        info.func = Dropdown_OnClick
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_Initialize(playerDropdown, InitializeDropdown)
UIDropDownMenu_SetWidth(playerDropdown, 150)
UIDropDownMenu_SetButtonWidth(playerDropdown, 160)
UIDropDownMenu_JustifyText(playerDropdown, "LEFT")

InterfaceOptions_AddCategory(panel)
