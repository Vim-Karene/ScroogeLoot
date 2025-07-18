-- Initialize PlayerDB on login
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
    if not PlayerDB then
        PlayerDB = {}
    end

    local name, realm = UnitName("player")
    realm = GetRealmName()
    local fullName = name .. "-" .. realm

    if not PlayerDB[fullName] then
        PlayerDB[fullName] = {
            name = name,
            class = select(2, UnitClass("player")),
            raiderrank = false,
            SP = 0,
            DP = 0,
            attended = 0,
            absent = 0,
            attendance = 0,
            item1 = "",
            item1received = false,
            item2 = "",
            item2received = false,
            item3 = "",
            item3received = false,
        }
    end
end)
