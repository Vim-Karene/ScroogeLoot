local Type, Version = "SLPlayerManager", 1
local AceGUI = LibStub("AceGUI-3.0")
local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")

local function OnAcquire(self)
    if not self.created then
        local pm = addon:GetModule("SLPlayerManager", true)
        if pm then
            pm:CreateOptionsUI(self.frame)
            self.created = true
        end
    end
    local pm = addon:GetModule("SLPlayerManager", true)
    if pm then
        pm:LoadData(self.frame)
        if self.frame.st then
            self.frame.st:SetData(self.frame.rows)
        end
    end
end

local function OnRelease(self)
end

local methods = {
    ["OnAcquire"] = OnAcquire,
    ["OnRelease"] = OnRelease,
}

local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    local widget = { frame = frame, type = Type }
    for method, func in pairs(methods) do
        widget[method] = func
    end
    return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
