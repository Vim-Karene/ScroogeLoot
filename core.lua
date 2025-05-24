-- RCLootCouncil: core.lua additions

RCLootCouncil = LibStub("AceAddon-3.0"):NewAddon("RCLootCouncil", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0")
local LibDialog = LibStub("LibDialog-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RCLootCouncil")
local lwin = LibStub("LibWindow-1.1")
local Deflate = LibStub("LibDeflate")
local LibGroupTalents = LibStub("LibGroupTalents-1.0")

-- Player variable sheet for loot master only
RCLootCouncil.playerData = {}

function RCLootCouncil:GetOrCreatePlayer(name)
  if not self.playerData[name] then
    self.playerData[name] = {DP = 0, TP = 0, attendance = 0, tokens = {"", "", ""}}
  end
  return self.playerData[name]
end

function RCLootCouncil:ExportPlayerDataToXML()
  local xml = "<PlayerData>\n"
  for name, data in pairs(self.playerData) do
    xml = xml .. string.format("  <Player name=\"%s\" DP=\"%d\" TP=\"%d\" attendance=\"%d\">\n", name, data.DP, data.TP, data.attendance)
    for i, token in ipairs(data.tokens) do
      xml = xml .. string.format("    <Token%d>%s</Token%d>\n", i, token, i)
    end
    xml = xml .. "  </Player>\n"
  end
  xml = xml .. "</PlayerData>"

  local path = "Interface/AddOns/RCLootCouncil/Exports/PlayerData.xml"
  local file = io.open(path, "w")
  if file then
    file:write(xml)
    file:close()
    print("Player data exported to " .. path)
  else
    print("Failed to export player data.")
  end
end

SLASH_RCLOOTCOUNCIL1 = "/rclc"
SlashCmdList["RCLOOTCOUNCIL"] = function(msg)
  local cmd = msg:lower()
  if cmd == "start" then
    RCLootCouncilML:StartRaid()
  elseif cmd == "conclude" then
    RCLootCouncilML:ConcludeRaid()
  elseif cmd == "export" then
    RCLootCouncil:ExportPlayerDataToXML()
  else
    print("Usage: /rclc start | conclude | export")
  end
end