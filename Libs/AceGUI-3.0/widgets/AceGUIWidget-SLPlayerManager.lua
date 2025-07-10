local Type, Version = "SLPlayerManager", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- WoW API
local CreateFrame = CreateFrame

local addon = ScroogeLoot
local SLPlayerManager = addon and addon:GetModule("SLPlayerManager", true)

local methods = {
    ["OnAcquire"] = function(self)
        self:SetWidth(900)
        self:SetHeight(400)
        if SLPlayerManager and not self.created then
            SLPlayerManager:CreateOptionsUI(self.frame)
            self.created = true
        end
        if SLPlayerManager then
            SLPlayerManager:LoadData(self.frame)
        end
    end,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:Hide()
    local widget = {
        frame = frame,
        type = Type,
    }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
