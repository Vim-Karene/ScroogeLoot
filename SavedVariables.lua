
-- Toggle between global or per-character data
-- Default: use per-character
ScroogeLoot_UseGlobal = ScroogeLoot_UseGlobal or false

ScroogeLootDB = ScroogeLootDB or {}
ScroogeLootCharDB = ScroogeLootCharDB or {}

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    ScroogeLoot = ScroogeLoot or {}
    if ScroogeLoot_UseGlobal then
      ScroogeLoot.playerData = ScroogeLootDB.playerData or {}
    else
      ScroogeLoot.playerData = ScroogeLootCharDB.playerData or {}
    end
  elseif event == "PLAYER_LOGOUT" then
    if ScroogeLoot_UseGlobal then
      ScroogeLootDB.playerData = ScroogeLoot.playerData or {}
    else
      ScroogeLootCharDB.playerData = ScroogeLoot.playerData or {}
    end
  end
end)
