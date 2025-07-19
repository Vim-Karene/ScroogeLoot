local AceGUI = LibStub("AceGUI-3.0")

--[[ SLPlayerManager widget for editing PlayerDB entries.
     Provides Save and Reset buttons to persist or discard edits. ]]

do
    local Type = "SLPlayerManager"
    local Version = 2

    local function OnAcquire(self)
        self:SetHeight(400)
        self:SetWidth(600)
    end

    local function CreateEditBox(parent, label, value, width)
        local eb = AceGUI:Create("EditBox")
        eb:SetLabel(label)
        eb:SetText(value or "")
        eb:SetWidth(width or 100)
        parent:AddChild(eb)
        return eb
    end

    local function CreatePlayerGroup(frame, name, data)
        local group = AceGUI:Create("InlineGroup")
        group:SetTitle(name)
        group:SetFullWidth(true)
        group:SetLayout("Flow")

        local editors = {}

        editors.SP = CreateEditBox(group, "SP", data.SP or 0)
        editors.DP = CreateEditBox(group, "DP", data.DP or 0)
        editors.attended = CreateEditBox(group, "Attended", data.attended or 0)
        editors.absent = CreateEditBox(group, "Absent", data.absent or 0)

        local cb = AceGUI:Create("CheckBox")
        cb:SetLabel("Raider Rank")
        cb:SetValue(data.raiderrank or false)
        group:AddChild(cb)
        editors.raiderrank = cb

        frame:AddChild(group)
        frame.editors[name] = editors
        return group
    end

    local function Constructor()
        local frame = AceGUI:Create("SimpleGroup")
        frame:SetLayout("Flow")
        frame.OnAcquire = OnAcquire
        frame.editors = {}

        -- Load data
        for name, data in pairs(PlayerDB or {}) do
            CreatePlayerGroup(frame, name, data)
        end

        -- Save Button
        local saveBtn = AceGUI:Create("Button")
        saveBtn:SetText("Save Changes")
        saveBtn:SetCallback("OnClick", function()
            for name, edits in pairs(frame.editors) do
                local data = PlayerDB[name]
                if data then
                    data.SP = tonumber(edits.SP:GetText()) or 0
                    data.DP = tonumber(edits.DP:GetText()) or 0
                    data.attended = tonumber(edits.attended:GetText()) or 0
                    data.absent = tonumber(edits.absent:GetText()) or 0
                    data.raiderrank = edits.raiderrank:GetValue()
                    local total = data.attended + data.absent
                    data.attendance = (total > 0) and math.floor((data.attended / total) * 100) or 0
                end
            end
            print("PlayerDB saved.")
        end)
        frame:AddChild(saveBtn)

        -- Reset Button
        local resetBtn = AceGUI:Create("Button")
        resetBtn:SetText("Reset Changes")
        resetBtn:SetCallback("OnClick", function()
            frame:ReleaseChildren()
            frame.editors = {}
            for name, data in pairs(PlayerDB or {}) do
                CreatePlayerGroup(frame, name, data)
            end
            frame:AddChild(saveBtn)
            frame:AddChild(resetBtn)
            print("PlayerDB edits reset.")
        end)
        frame:AddChild(resetBtn)

        AceGUI:RegisterAsContainer(frame)
        return frame
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

