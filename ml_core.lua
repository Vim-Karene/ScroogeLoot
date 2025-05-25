-- ScroogeLootML: ml_core.lua additions

local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")
ScroogeLootML = addon:NewModule("ScroogeLootML", "AceEvent-3.0", "AceBucket-3.0", "AceComm-3.0", "AceTimer-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ScroogeLoot")
local LibDialog = LibStub("LibDialog-1.0")
local Deflate = LibStub("LibDeflate")

local raidActive = false
local presentPlayers = {}

function ScroogeLootML:StartRaid()
  if not IsMasterLooter() then return end
  raidActive = true
  presentPlayers = {}
  for i = 1, GetNumGroupMembers() do
    local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
    if online then
      presentPlayers[name] = true
    end
  end
  SendChatMessage("Raid Started", "RAID_WARNING")
end

function ScroogeLootML:ConcludeRaid()
  if not IsMasterLooter() then return end
  raidActive = false
  for name in pairs(presentPlayers) do
    local p = addon:GetOrCreatePlayer(name)
    p.attendance = p.attendance + 1
    p.TP = p.TP + 10
    p.DP = math.min(0, p.DP + 25)
  end
  SendChatMessage("Raid Concluded", "RAID_WARNING")
end

function ScroogeLootML:AdjustRolls(rolls)
  for _, roll in ipairs(rolls) do
    local p = addon:GetOrCreatePlayer(roll.name)
    if roll.type == "Duck Roll" or roll.type == "MS Roll" or roll.type == "OS Roll" then
      roll.value = roll.value + p.DP
    elseif roll.type == "Token Roll" then
      roll.value = roll.value + p.TP
    end
  end
end

function ScroogeLootML:AwardItem(winner, rollType, item)
  local p = addon:GetOrCreatePlayer(winner)
  if rollType == "Duck Roll" or rollType == "MS Roll" or rollType == "OS Roll" then
    p.DP = p.DP - 50
  elseif rollType == "Token Roll" then
    local match = false
    for _, token in ipairs(p.tokens) do
      if token == item then match = true break end
    end
    if not match then
      print("Cannot award this item to " .. winner .. ": not in their tokens.")
      return false
    end
    p.TP = 0
    for _, r in ipairs(self.lastRolls or {}) do
      if r.name ~= winner and r.type == "Token Roll" then
        local loser = addon:GetOrCreatePlayer(r.name)
        loser.TP = loser.TP + 20
      end
    end
  end
  return true
end
-- /slroster — Attendance Summary Window
function SL:ShowAttendanceSummary()
  local frame = CreateFrame("Frame", "SLSummaryFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(300, 400)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame.title = frame:CreateFontString(nil, "OVERLAY")
  frame.title:SetFontObject("GameFontHighlight")
  frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
  frame.title:SetText("Attendance Summary")

  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(260, 1000)
  scrollFrame:SetScrollChild(content)

  local y = -10
  for name, data in pairs(ScroogeLoot.playerData) do
    local present = data.attendance or 0
    local absent = data["not-present"] or 0
    local percent = (present + absent) > 0 and math.floor((present / (present + absent)) * 100) or 0

    local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 10, y)
    label:SetText(name .. ": " .. present .. "✓ / " .. absent .. "✗  (" .. percent .. "%)")
    y = y - 20
  end
end

SLASH_SCROOGEROSTER1 = "/slroster"
SlashCmdList["SCROOGEROSTER"] = function() SL:ShowAttendanceSummary() end

-- Import/Export Buttons (attachable to any frame)
function SL:AddExportImportButtons(parent)
  local exportBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  exportBtn:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 10, 10)
  exportBtn:SetSize(120, 25)
  exportBtn:SetText("Export XML")
  exportBtn:SetScript("OnClick", function()
    ScroogeLoot:ExportPlayerDataToXML()
  end)

  local importBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
  importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
  importBtn:SetSize(120, 25)
  importBtn:SetText("Import XML")
  importBtn:SetScript("OnClick", function()
    print("Use /sl import [filename] in the future.")
  end)
end

-- Mini Statistics Dashboard
function SL:ShowDashboard()
  local f = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
  f:SetSize(260, 160)
  f:SetPoint("CENTER")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
  f.title:SetText("Scrooge Stats")

  local total, raiders, attending = 0, 0, 0
  for name, data in pairs(ScroogeLoot.playerData) do
    total = total + 1
    if data.raider then
      raiders = raiders + 1
      if data.attendance and data.attendance > 0 then
        attending = attending + 1
      end
    end
  end

  local percent = raiders > 0 and math.floor((attending / raiders) * 100) or 0

  local info = {
    "Total Players: " .. total,
    "Raiders: " .. raiders,
    "Active Raiders: " .. attending,
    "Avg. Attendance: " .. percent .. "%"
  }

  for i, line in ipairs(info) do
    local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t:SetPoint("TOPLEFT", 15, -30 - (i - 1) * 20)
    t:SetText(line)
  end
end

SLASH_SCROOGESTATS1 = "/slstats"
SlashCmdList["SCROOGESTATS"] = function() SL:ShowDashboard() end

-- (Optional) Roll restriction printout (commented out)
/*
hooksecurefunc("RCLootCouncil", "HandleRollClick", function(rollType, player)
  if rollType == "Token Roll" or rollType == "Duck Roll" then
    local p = ScroogeLoot:GetOrCreatePlayer(player)
    if not p.raider then
      print(player .. " is not a raider and cannot roll on " .. rollType)
    end
  end
end)
*/

-- Add buttons to Loot Master UI window
function SL:AddButtonsToLootMasterUI()
  if not RCLootCouncilFrame then return end
  if self.buttonsAdded then return end
  self.buttonsAdded = true

  local startButton = CreateFrame("Button", nil, RCLootCouncilFrame, "GameMenuButtonTemplate")
  startButton:SetPoint("TOPLEFT", RCLootCouncilFrame, "TOPRIGHT", 10, -10)
  startButton:SetSize(120, 25)
  startButton:SetText("Start Raid")
  startButton:SetScript("OnClick", function() SL:StartRaid() end)

  local endButton = CreateFrame("Button", nil, RCLootCouncilFrame, "GameMenuButtonTemplate")
  endButton:SetPoint("TOPLEFT", startButton, "BOTTOMLEFT", 0, -5)
  endButton:SetSize(120, 25)
  endButton:SetText("End Raid")
  endButton:SetScript("OnClick", function() SL:ConcludeRaid() end)

  local managerButton = CreateFrame("Button", nil, RCLootCouncilFrame, "GameMenuButtonTemplate")
  managerButton:SetPoint("TOPLEFT", endButton, "BOTTOMLEFT", 0, -5)
  managerButton:SetSize(120, 25)
  managerButton:SetText("Player Manager")
  managerButton:SetScript("OnClick", function() SL:CreatePlayerManagerUI() end)
end

-- Hook to automatically add buttons when loot session starts
hooksecurefunc("RCLootCouncilML", "StartSession", function()
  
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self, elapsed)
      self.t = (self.t or 0) + elapsed
      if self.t > 1 then
        SL:AddButtonsToLootMasterUI()
        self:SetScript("OnUpdate", nil)
      end
    end)
    
end)

-- Hook to restrict Duck/Token rolls to raiders only with message feedback
hooksecurefunc("RCLootCouncil", "HandleRollClick", function(rollType, player)
  if rollType == "Duck Roll" or rollType == "Token Roll" then
    local p = ScroogeLoot:GetOrCreatePlayer(player)
    if not p.raider then
      SendChatMessage("[Scrooge Loot] " .. player .. " is not marked as a raider and cannot use " .. rollType .. ".", "RAID_WARNING")
    elseif rollType == "Token Roll" then
      local valid = false
      for _, token in ipairs(p.tokens or {}) do
        if token and token ~= "" then
          valid = true
          break
        end
      end
      if not valid then
        SendChatMessage("[Scrooge Loot] " .. player .. " has no token items selected and cannot use Token Roll.", "RAID_WARNING")
      end
    end
  end
end)

-- Hook to restrict Duck/Token rolls to raiders only with whisper feedback
hooksecurefunc("RCLootCouncil", "HandleRollClick", function(rollType, player)
  if rollType == "Duck Roll" or rollType == "Token Roll" then
    local p = ScroogeLoot:GetOrCreatePlayer(player)
    if not p.raider then
      SendChatMessage("[Scrooge Loot] You are not marked as a raider and cannot use " .. rollType .. ".", "WHISPER", nil, player)
    elseif rollType == "Token Roll" then
      local valid = false
      for _, token in ipairs(p.tokens or {}) do
        if token and token ~= "" then
          valid = true
          break
        end
      end
      if not valid then
        SendChatMessage("[Scrooge Loot] You have no token items selected and cannot use Token Roll.", "WHISPER", nil, player)
      end
    end
  end
end)

-- Sort rolls by type priority and roll value
local rollPriority = {
  ["Token Roll"] = 1,
  ["Duck Roll"] = 2,
  ["MS Roll"] = 3,
  ["OS Roll"] = 4
}

function SL:SortRolls(rolls)
  table.sort(rolls, function(a, b)
    local ap = rollPriority[a.type] or 99
    local bp = rollPriority[b.type] or 99
    if ap == bp then
      return a.value > b.value
    else
      return ap < bp
    end
  end)
end

-- Call SL:SortRolls before awarding an item
-- Wrap existing AwardItem function to use sorting
local originalAwardItem = SL.AwardItem
function SL:AwardItemWithSorting(winner, rollType, item)
  if self.lastRolls then
    self:SortRolls(self.lastRolls)
  end
  return originalAwardItem(self, winner, rollType, item)
end
SL.AwardItem = SL.AwardItemWithSorting

-- Add priority indicator to roll display rows
function SL:GetRollPriorityLabel(rollType)
  local labels = {
    ["Token Roll"] = "|cffffd700[Token]|r",
    ["Duck Roll"] = "|cffa335ee[Duck]|r",
    ["MS Roll"]   = "|cff00ff00[MS]|r",
    ["OS Roll"]   = "|cffff8000[OS]|r"
  }
  return labels[rollType] or ""
end

-- Hook to modify roll list rows (assumes roll display uses some frame list)
-- This must be connected to whatever RCLootCouncil uses to render rolls
hooksecurefunc("RCLootCouncil", "AddRollEntry", function(roll)
  if roll.frame and roll.type then
    local label = SL:GetRollPriorityLabel(roll.type)
    if not roll.frame.priorityTag then
      roll.frame.priorityTag = roll.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      roll.frame.priorityTag:SetPoint("LEFT", roll.frame, "LEFT", 5, 0)
    end
    roll.frame.priorityTag:SetText(label)
  end
end)

-- Extend roll priority to include Transmog Roll
local rollPriority = {
  ["Token Roll"] = 1,
  ["Duck Roll"] = 2,
  ["MS Roll"]   = 3,
  ["OS Roll"]   = 4,
  ["Transmog Roll"] = 5
}

-- Extend GetRollPriorityLabel to include Transmog
function SL:GetRollPriorityLabel(rollType)
  local labels = {
    ["Token Roll"] = "|cffffd700[Token]|r",
    ["Duck Roll"] = "|cffa335ee[Duck]|r",
    ["MS Roll"]   = "|cff00ff00[MS]|r",
    ["OS Roll"]   = "|cffff8000[OS]|r",
    ["Transmog Roll"] = "|cff999999[TM]|r"
  }
  return labels[rollType] or ""
end

-- Add Transmog Roll Button to RCLootCouncil UI if supported
hooksecurefunc("RCLootCouncil", "CreateRollButtons", function(self)
  if not self.TransmogRollButton then
    local btn = CreateFrame("Button", nil, self, "GameMenuButtonTemplate")
    btn:SetSize(100, 25)
    btn:SetText("Transmog Roll")
    btn:SetPoint("TOP", self, "BOTTOM", 0, -10)
    btn:SetScript("OnClick", function()
      SendChatMessage("!roll TM", "RAID")
    end)
    self.TransmogRollButton = btn
  end
end)
