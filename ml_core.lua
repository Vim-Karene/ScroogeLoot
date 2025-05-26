SL = SL or {}
ScroogeLoot = ScroogeLoot or {}

function SL:AdjustRolls(rolls)
  for _, roll in ipairs(rolls) do
    local p = ScroogeLoot:GetOrCreatePlayer(roll.name)
    if roll.type == "Duck Roll" and p.raider then
      roll.value = roll.value + (p.DP or 0)
    elseif (roll.type == "MS Roll" or roll.type == "OS Roll") and p.raider then
      roll.value = roll.value + (p.DP or 0)
    elseif roll.type == "Token Roll" then
      roll.value = roll.value + (p.TP or 0)
    end
  end
end

-- /slhelp command to list all available Scrooge Loot commands
function SL:ShowHelp()
  print("|cffffff00/sl|r - Open the Loot Master session window")
  print("|cffffff00Scrooge Loot Commands:")
  print("|cffffff00/sl start|r - Start tracking attendance")
  print("|cffffff00/sl conclude|r - Conclude raid and apply attendance rewards")
  print("|cffffff00/slpm|r - Open Player Manager UI")
  print("|cffffff00/slroster|r - View attendance summary")
  print("|cffffff00/slstats|r - Show statistics dashboard")
  print("|cffffff00/slhelp|r - Show this help message")
end

SLASH_SCROOGEHELP1 = "/slhelp"
SlashCmdList["SCROOGEHELP"] = function() SL:ShowHelp() end
-- Add custom roll buttons to RCLootCouncil vote frame
hooksecurefunc("RCLootCouncil", "StartSession", function()
  if not RCLootCouncilFrame then return end
  if SL.rollButtonsAdded then return end
  SL.rollButtonsAdded = true

  local rollTypes = {
    {name = "Token Roll", label = "Token", color = {1.0, 0.84, 0.0}},
    {name = "Duck Roll", label = "Duck", color = {0.64, 0.21, 0.93}},
    {name = "MS Roll", label = "MS", color = {0.1, 1.0, 0.1}},
    {name = "OS Roll", label = "OS", color = {1.0, 0.5, 0.0}},
    {name = "Transmog Roll", label = "TM", color = {0.7, 0.7, 0.7}}
  }

  local lastButton
  for i, roll in ipairs(rollTypes) do
    local btn = CreateFrame("Button", "SL_" .. roll.name:gsub(" ", ""), RCLootCouncilFrame, "GameMenuButtonTemplate")
    btn:SetSize(100, 24)
    btn:SetText(roll.label)
    btn:SetNormalFontObject("GameFontNormal")
    btn:SetHighlightFontObject("GameFontHighlight")
    btn:SetScript("OnClick", function()
      SendChatMessage("!roll " .. roll.label, "RAID")
    end)

    if i == 1 then
      btn:SetPoint("TOPRIGHT", RCLootCouncilFrame, "TOPLEFT", -10, 0)
    else
      btn:SetPoint("TOP", lastButton, "BOTTOM", 0, -5)
    end
    lastButton = btn

    -- Tint text color for flavor
    btn:GetFontString():SetTextColor(unpack(roll.color))
  end
end)

-- Extended Player Manager UI with TP/DP editing and token management
function SL:CreatePlayerManagerUI()
  if self.playerManagerFrame then
    self.playerManagerFrame:Show()
    return
  end

  local frame = CreateFrame("Frame", "SLPlayerManagerFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(500, 500)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame.title = frame:CreateFontString(nil, "OVERLAY")
  frame.title:SetFontObject("GameFontHighlight")
  frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
  frame.title:SetText("Scrooge Loot - Player Manager")

  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(460, 2000)
  scrollFrame:SetScrollChild(content)

  local yOffset = -10
  for name, data in pairs(ScroogeLoot.playerData) do
    local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", 10, yOffset)
    label:SetText(name)

    local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 120, yOffset)
    checkbox:SetChecked(data.raider)
    checkbox:SetScript("OnClick", function(self)
      ScroogeLoot:GetOrCreatePlayer(name).raider = self:GetChecked()
    end)

    local fields = {"TP", "DP", "attendance", "not-present"}
    for i, field in ipairs(fields) do
      local box = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
      box:SetSize(30, 20)
      box:SetPoint("TOPLEFT", 200 + (i - 1) * 40, yOffset)
      box:SetText(data[field] or 0)
      box:SetAutoFocus(false)
      box:SetNumeric(true)
      box:SetScript("OnEnterPressed", function(self)
        local val = tonumber(self:GetText()) or 0
        ScroogeLoot:GetOrCreatePlayer(name)[field] = val
        self:ClearFocus()
      end)
    end

    -- Token inputs
    for t = 1, 3 do
      local tokenBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
      tokenBox:SetSize(80, 20)
      tokenBox:SetPoint("TOPLEFT", 380 + (t - 1) * 85, yOffset)
      tokenBox:SetText((data.tokens and data.tokens[t]) or "")
      tokenBox:SetAutoFocus(false)
      tokenBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        local p = ScroogeLoot:GetOrCreatePlayer(name)
        p.tokens = p.tokens or {"", "", ""}
        p.tokens[t] = text
        self:ClearFocus()
      end)
    end

    yOffset = yOffset - 30
  end
end

-- Extend Player Manager with search, export/import, and a log viewer
function SL:CreatePlayerManagerUI()
  if self.playerManagerFrame then
    self.playerManagerFrame:Show()
    return
  end

  local frame = CreateFrame("Frame", "SLPlayerManagerFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(800, 600)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame.title = frame:CreateFontString(nil, "OVERLAY")
  frame.title:SetFontObject("GameFontHighlight")
  frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
  frame.title:SetText("Scrooge Loot - Player Manager")

  -- Search box
  local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  searchBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -10)
  searchBox:SetSize(150, 20)
  searchBox:SetAutoFocus(false)
  searchBox:SetScript("OnTextChanged", function(self)
    SL:UpdatePlayerManagerUI(self:GetText())
  end)

  -- Scroll area
  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -40)
  scrollFrame:SetPoint("BOTTOMRIGHT", -250, 10)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(600, 4000)
  scrollFrame:SetScrollChild(content)
  frame.content = content
  frame.searchBox = searchBox
  SL.playerManagerFrame = frame

  -- Export/Import buttons
  local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
  exportBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 620, -40)
  exportBtn:SetSize(140, 25)
  exportBtn:SetText("Export XML")
  exportBtn:SetScript("OnClick", function()
    ScroogeLoot:ExportPlayerDataToXML()
  end)

  local importBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
  importBtn:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -5)
  importBtn:SetSize(140, 25)
  importBtn:SetText("Import XML")
  importBtn:SetScript("OnClick", function()
    print("Use /sl import [filename] to import player data.")
  end)

  -- Placeholder loot log (simulated)
  local logBox = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  logBox:SetPoint("TOPLEFT", 620, -100)
  logBox:SetSize(160, 400)

  local logContent = CreateFrame("Frame", nil, logBox)
  logContent:SetSize(140, 800)
  logBox:SetScrollChild(logContent)

  local logText = logContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  logText:SetPoint("TOPLEFT")
  logText:SetJustifyH("LEFT")
  logText:SetText("Token Roll Log:
- Baba won [Shoulders of Duck]
- Hjördis lost [Belt of Sass]
...")
end

-- Refresh function with filter
function SL:UpdatePlayerManagerUI(filter)
  local frame = self.playerManagerFrame
  if not frame then return end
  local content = frame.content
  local yOffset = -10
  for name, data in pairs(ScroogeLoot.playerData) do
    if not filter or name:lower():find(filter:lower()) then
      local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      label:SetPoint("TOPLEFT", 10, yOffset)
      label:SetText(name)

      local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
      checkbox:SetPoint("TOPLEFT", 120, yOffset)
      checkbox:SetChecked(data.raider)
      checkbox:SetScript("OnClick", function(self)
        ScroogeLoot:GetOrCreatePlayer(name).raider = self:GetChecked()
      end)

      local fields = {"TP", "DP", "attendance", "not-present"}
      for i, field in ipairs(fields) do
        local box = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        box:SetSize(30, 20)
        box:SetPoint("TOPLEFT", 200 + (i - 1) * 40, yOffset)
        box:SetText(data[field] or 0)
        box:SetAutoFocus(false)
        box:SetNumeric(true)
        box:SetScript("OnEnterPressed", function(self)
          local val = tonumber(self:GetText()) or 0
          ScroogeLoot:GetOrCreatePlayer(name)[field] = val
          self:ClearFocus()
        end)
      end

      for t = 1, 3 do
        local tokenBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
        tokenBox:SetSize(80, 20)
        tokenBox:SetPoint("TOPLEFT", 380 + (t - 1) * 85, yOffset)
        tokenBox:SetText((data.tokens and data.tokens[t]) or "")
        tokenBox:SetAutoFocus(false)
        tokenBox:SetScript("OnEnterPressed", function(self)
          local text = self:GetText()
          local p = ScroogeLoot:GetOrCreatePlayer(name)
          p.tokens = p.tokens or {"", "", ""}
          p.tokens[t] = text
          self:ClearFocus()
        end)
      end
      yOffset = yOffset - 30
    end
  end
end

-- Token Roll Log Window
function SL:ShowTokenRollLog()
  if self.tokenLogFrame then
    self.tokenLogFrame:Show()
    return
  end

  local frame = CreateFrame("Frame", "SLTokenLogFrame", UIParent, "BasicFrameTemplateWithInset")
  frame:SetSize(400, 300)
  frame:SetPoint("CENTER")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame.title = frame:CreateFontString(nil, "OVERLAY")
  frame.title:SetFontObject("GameFontHighlight")
  frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
  frame.title:SetText("Token Roll Log")

  local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 10, -30)
  scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetSize(360, 1000)
  scrollFrame:SetScrollChild(content)

  local logText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  logText:SetPoint("TOPLEFT", 0, 0)
  logText:SetJustifyH("LEFT")
  logText:SetWidth(340)
  logText:SetText("Token Roll Log:
- Baba won [Shoulders of Duck]
- Hjördis lost [Belt of Sass]
(placeholder entries)")

  self.tokenLogFrame = frame
end

-- Add button to Player Manager UI to open Token Log
hooksecurefunc(SL, "CreatePlayerManagerUI", function()
  local f = SL.playerManagerFrame
  if not f then return end
  local logBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
  logBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 620, -80)
  logBtn:SetSize(140, 25)
  logBtn:SetText("Token Roll Log")
  logBtn:SetScript("OnClick", function()
    SL:ShowTokenRollLog()
  end)
end)
