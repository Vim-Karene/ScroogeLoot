-- playerManagerWindow.lua
local addonName, addon = ...
local AceGUI = LibStub("AceGUI-3.0")

-- Opens a standalone AceGUI window for editing PlayerData
function addon:OpenPlayerManager()
    if addon.pmFrame then
        addon.pmFrame:ReleaseChildren()
        addon.pmFrame:Hide()
    end

    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Player Management")
    frame:SetWidth(700)
    frame:SetHeight(600)
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        addon.pmFrame = nil
    end)

    addon.pmFrame = frame

    local editors = {}

    local function CreateEditBox(label, value)
        local eb = AceGUI:Create("EditBox")
        eb:SetLabel(label)
        eb:SetText(value or "")
        eb:SetWidth(120)
        return eb
    end

    local function CreateCheckBox(label, value)
        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel(label)
        cb:SetValue(value or false)
        return cb
    end

    for name, data in pairs(PlayerData or {}) do
        local group = AceGUI:Create("InlineGroup")
        group:SetTitle(name)
        group:SetFullWidth(true)
        group:SetLayout("Flow")

        local e = {}

        e.name = CreateEditBox("Name", data.name)
        group:AddChild(e.name)

        e.class = CreateEditBox("Class", data.class)
        group:AddChild(e.class)

        e.SP = CreateEditBox("SP", data.SP)
        group:AddChild(e.SP)

        e.DP = CreateEditBox("DP", data.DP)
        group:AddChild(e.DP)

        e.attended = CreateEditBox("Attended", data.attended)
        group:AddChild(e.attended)

        e.absent = CreateEditBox("Absent", data.absent)
        group:AddChild(e.absent)

        e.item1 = CreateEditBox("Item 1", data.item1)
        group:AddChild(e.item1)

        e.item1received = CreateCheckBox("Item 1 Received", data.item1received)
        group:AddChild(e.item1received)

        e.item2 = CreateEditBox("Item 2", data.item2)
        group:AddChild(e.item2)

        e.item2received = CreateCheckBox("Item 2 Received", data.item2received)
        group:AddChild(e.item2received)

        e.item3 = CreateEditBox("Item 3", data.item3)
        group:AddChild(e.item3)

        e.item3received = CreateCheckBox("Item 3 Received", data.item3received)
        group:AddChild(e.item3received)

        editors[name] = e
        frame:AddChild(group)
    end

    local saveBtn = AceGUI:Create("Button")
    saveBtn:SetText("Save Changes")
    saveBtn:SetWidth(200)
    saveBtn:SetCallback("OnClick", function()
        for name, e in pairs(editors) do
            local d = PlayerData[name]
            if d then
                d.name = e.name:GetText()
                d.class = e.class:GetText()
                d.SP = tonumber(e.SP:GetText()) or 0
                d.DP = tonumber(e.DP:GetText()) or 0
                d.attended = tonumber(e.attended:GetText()) or 0
                d.absent = tonumber(e.absent:GetText()) or 0
                d.item1 = e.item1:GetText()
                d.item1received = e.item1received:GetValue()
                d.item2 = e.item2:GetText()
                d.item2received = e.item2received:GetValue()
                d.item3 = e.item3:GetText()
                d.item3received = e.item3received:GetValue()
                d.attendance = (d.attended + d.absent > 0) and math.floor(d.attended / (d.attended + d.absent) * 100) or 0
            end
        end
        print("Saved changes to PlayerData.")
    end)

    frame:AddChild(saveBtn)
end

return addon
