-- RCLootCouncilML: ml_core.lua additions

local addon = LibStub("AceAddon-3.0"):GetAddon("RCLootCouncil")
RCLootCouncilML = addon:NewModule("RCLootCouncilML", "AceEvent-3.0", "AceBucket-3.0", "AceComm-3.0", "AceTimer-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("RCLootCouncil")
local LibDialog = LibStub("LibDialog-1.0")
local Deflate = LibStub("LibDeflate")

local raidActive = false
local presentPlayers = {}

function RCLootCouncilML:StartRaid()
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

function RCLootCouncilML:ConcludeRaid()
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

function RCLootCouncilML:AdjustRolls(rolls)
  for _, roll in ipairs(rolls) do
    local p = addon:GetOrCreatePlayer(roll.name)
    if roll.type == "Duck Roll" or roll.type == "MS Roll" or roll.type == "OS Roll" then
      roll.value = roll.value + p.DP
    elseif roll.type == "Token Roll" then
      roll.value = roll.value + p.TP
    end
  end
end

function RCLootCouncilML:AwardItem(winner, rollType, item)
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