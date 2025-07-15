local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")
local AceGUI = LibStub("AceGUI-3.0")

local Type, Version = "SLPlayerManager", 1

local methods = {}

function methods:OnAcquire()
    if not self.created then
        local pm = addon:GetModule("SLPlayerManager", true)
        if pm then
            pm:CreateOptionsUI(self.content)
            pm:LoadData(self.content)
            self.content.st:SetData(self.content.rows)
        end
        self.created = true
    end
end

function methods:OnRelease()
    local pm = addon:GetModule("SLPlayerManager", true)
    if pm and pm.optionsFrame == self.content then
        pm.optionsFrame = nil
    end
    self.created = nil
end

local function Constructor()
    local frame = CreateFrame("Frame")
    local content = CreateFrame("Frame", nil, frame)
    content:SetAllPoints()

    local widget = {
        frame = frame,
        content = content,
        type = Type,
    }
    for k, v in pairs(methods) do
        widget[k] = v
    end
    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
