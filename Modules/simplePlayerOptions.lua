local addonName = ...
local panel = CreateFrame("Frame", "ScroogeLootOptionsPanel", InterfaceOptionsFramePanelContainer)
panel.name = "ScroogeLoot"

InterfaceOptions_AddCategory(panel)

-- == Title ==
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("ScroogeLoot - Player Management")

local selectedPlayer = nil

-- == Helper Functions ==
local function CreateInput(labelText, anchorFrame, offsetY)
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, offsetY)
    label:SetText(labelText)

    local editBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    editBox:SetSize(140, 20)
    editBox:SetAutoFocus(false)
    editBox:SetPoint("LEFT", label, "RIGHT", 10, 0)

    return editBox
end

local function CreateCheckbox(labelText, anchorFrame, offsetY)
    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, offsetY)
    checkbox.text:SetText(labelText)
    return checkbox
end

-- == Dropdowns ==
local playerDropdown = CreateFrame("Frame", "ScroogeLootPlayerDropdown", panel, "UIDropDownMenuTemplate")
playerDropdown:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -30)
UIDropDownMenu_SetWidth(playerDropdown, 200)

local classFilterDropdown = CreateFrame("Frame", "ScroogeLootClassFilter", panel, "UIDropDownMenuTemplate")
classFilterDropdown:SetPoint("LEFT", playerDropdown, "RIGHT", 200, 0)
UIDropDownMenu_SetWidth(classFilterDropdown, 100)

local rankFilterCheckbox = CreateCheckbox("Raider Rank Only", classFilterDropdown, -10)

-- == Editable Fields ==
local spBox = CreateInput("SP:", playerDropdown, -20)
local dpBox = CreateInput("DP (Max 200):", spBox, -10)
local attendedBox = CreateInput("Attended:", dpBox, -10)
local absentBox = CreateInput("Absent:", attendedBox, -10)
local raidRankBox = CreateInput("Raider Rank (true/false):", absentBox, -10)

local item1Box = CreateInput("Item 1:", raidRankBox, -20)
local item1Received = CreateCheckbox("Item 1 Received", item1Box, -5)
local item2Box = CreateInput("Item 2:", item1Received, -5)
local item2Received = CreateCheckbox("Item 2 Received", item2Box, -5)
local item3Box = CreateInput("Item 3:", item2Received, -5)
local item3Received = CreateCheckbox("Item 3 Received", item3Box, -5)

-- == Buttons ==
local saveBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
saveBtn:SetSize(120, 24)
saveBtn:SetText("Save Changes")
saveBtn:SetPoint("TOPLEFT", item3Received, "BOTTOMLEFT", 0, -15)

local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
resetBtn:SetSize(100, 24)
resetBtn:SetText("Reset Player")
resetBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)

local removeBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
removeBtn:SetSize(100, 24)
removeBtn:SetText("Remove Player")
removeBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)

-- == Logic ==
local function UpdateFields(playerName)
    local p = scroogelootplayerDB[playerName]
    if not p then return end

    spBox:SetText(p.SP)
    dpBox:SetText(p.DP)
    attendedBox:SetText(p.attended)
    absentBox:SetText(p.absent)
    raidRankBox:SetText(tostring(p.raiderrank))

    item1Box:SetText(p.item1)
    item1Received:SetChecked(p.item1received)
    item2Box:SetText(p.item2)
    item2Received:SetChecked(p.item2received)
    item3Box:SetText(p.item3)
    item3Received:SetChecked(p.item3received)
end

saveBtn:SetScript("OnClick", function()
    if not selectedPlayer then return end
    local p = scroogelootplayerDB[selectedPlayer]

    p.SP = tonumber(spBox:GetText()) or 0
    p.DP = math.min(tonumber(dpBox:GetText()) or 0, 200)
    p.attended = tonumber(attendedBox:GetText()) or 0
    p.absent = tonumber(absentBox:GetText()) or 0
    p.raiderrank = raidRankBox:GetText():lower() == "true"

    p.item1 = item1Box:GetText()
    p.item1received = item1Received:GetChecked()
    p.item2 = item2Box:GetText()
    p.item2received = item2Received:GetChecked()
    p.item3 = item3Box:GetText()
    p.item3received = item3Received:GetChecked()

    local total = p.attended + p.absent
    p.attendance = (total > 0) and math.floor((p.attended / total) * 100) or 0

    print("Saved changes for:", selectedPlayer)
end)

resetBtn:SetScript("OnClick", function()
    if not selectedPlayer then return end
    local class = scroogelootplayerDB[selectedPlayer].class
    local name = selectedPlayer

    scroogelootplayerDB[name] = nil
    RegisterPlayer(name, class)
    UpdatePlayerDropdown()
    UIDropDownMenu_SetSelectedName(playerDropdown, name)
    selectedPlayer = name
    UpdateFields(name)
    print("Reset player:", name)
end)

removeBtn:SetScript("OnClick", function()
    if not selectedPlayer then return end
    scroogelootplayerDB[selectedPlayer] = nil
    print("Removed player:", selectedPlayer)
    selectedPlayer = nil
    UpdatePlayerDropdown()
end)

-- == Filtering & Dropdown Setup ==
local classFilter = nil
local function UpdatePlayerDropdown()
    local items = {}

    for playerName, data in pairs(scroogelootplayerDB) do
        if (not classFilter or data.class == classFilter) and
           (not rankFilterCheckbox:GetChecked() or data.raiderrank) then
            table.insert(items, playerName)
        end
    end

    table.sort(items)

    UIDropDownMenu_Initialize(playerDropdown, function(self, level)
        for i, name in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.value = name
            info.func = function()
                selectedPlayer = name
                UIDropDownMenu_SetSelectedName(playerDropdown, name)
                UpdateFields(name)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(playerDropdown, selectedPlayer or "Select Player")
end

rankFilterCheckbox:SetScript("OnClick", UpdatePlayerDropdown)

-- == Class Filter Dropdown ==
local classList = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
    "MONK", "DEMONHUNTER", "EVOKER"
}

UIDropDownMenu_Initialize(classFilterDropdown, function(self, level)
    local none = UIDropDownMenu_CreateInfo()
    none.text = "All Classes"
    none.func = function()
        classFilter = nil
        UIDropDownMenu_SetText(classFilterDropdown, "All Classes")
        UpdatePlayerDropdown()
    end
    UIDropDownMenu_AddButton(none, level)

    for _, class in ipairs(classList) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = class
        info.func = function()
            classFilter = class
            UIDropDownMenu_SetText(classFilterDropdown, class)
            UpdatePlayerDropdown()
        end
        UIDropDownMenu_AddButton(info, level)
    end
end)

UIDropDownMenu_SetText(classFilterDropdown, "All Classes")

-- Run once on load
C_Timer.After(1, UpdatePlayerDropdown)
