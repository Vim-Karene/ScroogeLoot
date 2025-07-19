local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")
local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ScroogeLoot")

-- SLPlayerManager AceGUI widget

local function CreateEditBox(parent, label, value)
    local eb = AceGUI:Create("EditBox")
    eb:SetLabel(label)
    eb:SetText(value or "")
    eb:SetWidth(150)
    parent:AddChild(eb)
    return eb
end

local function CreateCheckBox(parent, label, value)
    local cb = AceGUI:Create("CheckBox")
    cb:SetLabel(label)
    cb:SetValue(value or false)
    parent:AddChild(cb)
    return cb
end

local function AddPlayerRow(frame, name, data)
    local group = AceGUI:Create("InlineGroup")
    group:SetTitle(name)
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    local editors = {}
    editors.name = CreateEditBox(group, L["Name"], data.name)
    editors.class = CreateEditBox(group, L["Class"], data.class)
    editors.SP = CreateEditBox(group, "SP", data.SP)
    editors.DP = CreateEditBox(group, "DP", data.DP)
    editors.attended = CreateEditBox(group, L["Attended"], data.attended)
    editors.absent = CreateEditBox(group, L["Absent"], data.absent)
    editors.item1 = CreateEditBox(group, "Item 1", data.item1)
    editors.item1received = CreateCheckBox(group, "Item 1 Received", data.item1received)
    editors.item2 = CreateEditBox(group, "Item 2", data.item2)
    editors.item2received = CreateCheckBox(group, "Item 2 Received", data.item2received)
    editors.item3 = CreateEditBox(group, "Item 3", data.item3)
    editors.item3received = CreateCheckBox(group, "Item 3 Received", data.item3received)
    frame:AddChild(group)
    frame.editors[name] = editors
end

local function BuildOptions(frame)
    frame:ReleaseChildren()
    frame.editors = {}
    for name, data in pairs(addon.PlayerData or {}) do
        AddPlayerRow(frame, name, data)
    end

    local saveBtn = AceGUI:Create("Button")
    saveBtn:SetText("Save Changes")
    saveBtn:SetWidth(160)
    saveBtn:SetCallback("OnClick", function()
        for name, editors in pairs(frame.editors) do
            local d = addon.PlayerData[name]
            if d then
                d.name = editors.name:GetText()
                d.class = editors.class:GetText()
                d.SP = tonumber(editors.SP:GetText()) or 0
                d.DP = tonumber(editors.DP:GetText()) or 0
                d.attended = tonumber(editors.attended:GetText()) or 0
                d.absent = tonumber(editors.absent:GetText()) or 0
                d.item1 = editors.item1:GetText()
                d.item1received = editors.item1received:GetValue()
                d.item2 = editors.item2:GetText()
                d.item2received = editors.item2received:GetValue()
                d.item3 = editors.item3:GetText()
                d.item3received = editors.item3received:GetValue()
                local a,b = d.attended, d.absent
                d.attendance = (a + b > 0) and math.floor((a / (a+b)) * 100) or 0
            end
        end
        addon:BroadcastPlayerData()
        addon:Print(L["Player Management"]..": "..L["Save"].."!")
    end)
    frame:AddChild(saveBtn)

    local resetBtn = AceGUI:Create("Button")
    resetBtn:SetText("Reset Changes")
    resetBtn:SetWidth(160)
    resetBtn:SetCallback("OnClick", function()
        BuildOptions(frame)
    end)
    frame:AddChild(resetBtn)
end

local Type = "SLPlayerManager"
local Version = 1

local methods = {
    ["OnAcquire"] = function(self)
        self:SetLayout("Flow")
        BuildOptions(self)
    end,
    ["OnRelease"] = function(self)
        self:ReleaseChildren()
    end,
}

local function Constructor()
    local frame = AceGUI:Create("ScrollFrame")
    frame:SetLayout("Flow")
    for k, v in pairs(methods) do
        frame[k] = v
    end
    return AceGUI:RegisterAsContainer(frame)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
