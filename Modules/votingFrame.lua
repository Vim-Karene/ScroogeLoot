-- Author      : Potdisc
-- Create Date : 12/15/2014 8:54:35 PM
-- DefaultModule
--	votingFrame.lua	Displays everything related to handling loot for all members.
--		Will only show certain aspects depending on addon.isMasterLooter, addon.isCouncil and addon.mldb.observe

local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")
local SLVotingFrame = addon:NewModule("SLVotingFrame", "AceComm-3.0", "AceTimer-3.0")
local LibDialog = LibStub("LibDialog-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ScroogeLoot")
local Deflate = LibStub("LibDeflate")

local ROW_HEIGHT = 20;
local NUM_ROWS = 15;
local db
local session = 1 -- The session we're viewing
local lootTable = {} -- lib-st compatible, extracted from addon's lootTable
local sessionButtons = {}
local moreInfo = false -- Show more info frame?
local active = false -- Are we currently in session?
local candidates = {} -- Candidates for the loot, initial data from the ML
local councilInGroup = {}
local keys = {} -- Lookup table for cols TODO implement this
local menuFrame -- Right click menu frame
local filterMenu -- Filter drop down menu
local enchanters -- Enchanters drop down menu frame
-- Map the text sent with ROLL messages to the numeric response index so
-- the voting frame can show the correct button label even on WotLK (3.3.5a)
local RESPONSE_MAP = {
    ["Scrooge"] = 1,
    ["Drool"] = 2,
    ["Deducktion"] = 3,
    ["Main-Spec"] = 4,
    ["Off-Spec"] = 5,
    ["Transmog"] = 6,
}
local guildRanks = {} -- returned from addon:GetGuildRanks()
local GuildRankSort, ResponseSort -- Initialize now to avoid errors

-- Handle incoming addon messages
local function OnAddonMessage(prefix, msg, channel, sender)
    if prefix ~= "ScroogeLoot" then return end

    if strsub(msg, 1, 5) == "ROLL:" then
        local _, ses, name, rollType, base, sp, dp = strsplit(":", msg)
        ses = tonumber(ses)
        base = tonumber(base)
        sp = tonumber(sp)
        dp = tonumber(dp)
        local final = base
        local reason
        if rollType == "Scrooge" then
            final = base + sp
            reason = "+SP"
        elseif rollType == "Deducktion" or rollType == "Main-Spec" or rollType == "Off-Spec" then
            final = base + dp
            reason = "+DP"
        end
        local response = RESPONSE_MAP[rollType] or rollType
        if SLVotingFrame then
            SLVotingFrame:SetCandidateData(ses, name, "response", response)
            SLVotingFrame:SetCandidateData(ses, name, "responseName", rollType)
            SLVotingFrame:SetCandidateData(ses, name, "roll", final)
            SLVotingFrame:SetCandidateData(ses, name, "rollInfo", {
                base = base,
                final = final,
                SP = sp,
                DP = dp,
                reason = reason,
            })
            SLVotingFrame:Update()
        end
    end
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_ADDON", function(_, ...)
    local prefix, msg, channel, sender = ...
    OnAddonMessage(prefix, msg, channel, sender)
    return false
end)

-- Calculate a player's attendance percentage
local function CalculateAttendance(attended, absent)
    local total = (attended or 0) + (absent or 0)
    if total == 0 then return 0 end
    return math.floor((attended / total) * 100)
end

-- Update a single voting row using PlayerDB data
local function UpdateVotingRow(playerName)
    local data = PlayerDB and PlayerDB[playerName]
    if not data then
        local _, class = UnitClass(playerName)
        if RegisterPlayer then
            RegisterPlayer(playerName, class)
        end
        data = PlayerDB and PlayerDB[playerName]
    end
    if not data or not SLVotingFrame.frame then return end

    local attendance = CalculateAttendance(data.attended, data.absent)

    local st = SLVotingFrame.frame.st
    if not st then return end
    for i, row in ipairs(st.data or {}) do
        if row.name == playerName then
            local displayName = PlayerDB and PlayerDB[playerName] and PlayerDB[playerName].name or playerName
            row.cols[1].value = displayName
            row.cols[2].value = data.raiderrank and 1 or 0
            row.cols[4].value = attendance
            row.cols[7].value = lootTable[session].candidates[playerName].roll
            row.roll = lootTable[session].candidates[playerName].roll
            row.rollInfo = lootTable[session].candidates[playerName].rollInfo
            st:Refresh()
            break
        end
    end
end

-- Master looter only: handle an incoming roll choice and update the table
local function HandleRollChoice(sessionID, playerName, rollType)
    local playerData = PlayerDB and PlayerDB[playerName]
    if not playerData then
        local _, class = UnitClass(playerName)
        if RegisterPlayer then
            RegisterPlayer(playerName, class)
        end
        playerData = PlayerDB and PlayerDB[playerName]
    end
    if not playerData or not sessionID then return end

    local baseRoll = math.random(1, 100)
    local modifiedRoll = baseRoll
    local reason

    if rollType == "Scrooge" then
        modifiedRoll = baseRoll + (playerData.SP or 0)
        reason = "+SP"
    elseif rollType == "Deducktion" or rollType == "Main-Spec" or rollType == "Off-Spec" then
        modifiedRoll = baseRoll + (playerData.DP or 0)
        reason = "+DP"
    end

    SLVotingFrame:SetCandidateData(sessionID, playerName, "roll", modifiedRoll)
    SLVotingFrame:SetCandidateData(sessionID, playerName, "rollInfo", {
        base = baseRoll,
        final = modifiedRoll,
        SP = playerData.SP,
        DP = playerData.DP,
        reason = reason,
    })
    if SLVotingFrame.frame and SLVotingFrame.frame.st then
        SLVotingFrame.frame.st:Refresh()
    end
    UpdateVotingRow(playerName)
    SLVotingFrame:Update()
end

function SLVotingFrame:OnInitialize()
        self.scrollCols = {
                { name = "Name",       width = 100, DoCellUpdate = self.SetCellName },
                { name = "Rank",       width = 50,  DoCellUpdate = self.SetCellRank },
                { name = "Response",   width = 100, DoCellUpdate = self.SetCellResponse },
                { name = "Attendance", width = 70,  DoCellUpdate = self.SetCellAttendance },
                { name = "Gear 1",     width = 120, DoCellUpdate = self.SetCellGear1 },
                { name = "Gear 2",     width = 120, DoCellUpdate = self.SetCellGear2 },
                { name = "Roll",       width = 60,  DoCellUpdate = self.SetCellRoll },
        }
	menuFrame = CreateFrame("Frame", "ScroogeLoot_VotingFrame_RightclickMenu", UIParent, "Lib_UIDropDownMenuTemplate")
	filterMenu = CreateFrame("Frame", "ScroogeLoot_VotingFrame_FilterMenu", UIParent, "Lib_UIDropDownMenuTemplate")
	enchanters = CreateFrame("Frame", "ScroogeLoot_VotingFrame_EnchantersMenu", UIParent, "Lib_UIDropDownMenuTemplate")
	Lib_UIDropDownMenu_Initialize(menuFrame, self.RightClickMenu, "MENU")
	Lib_UIDropDownMenu_Initialize(filterMenu, self.FilterMenu)
	Lib_UIDropDownMenu_Initialize(enchanters, self.EnchantersMenu)
end

function SLVotingFrame:OnEnable()
	self:RegisterComm("ScroogeLoot")
	db = addon:Getdb()
	active = true
	moreInfo = db.modules["SLVotingFrame"].moreInfo
	self.frame = self:GetFrame()
end

function SLVotingFrame:OnDisable() -- We never really call this
	self:Hide()
	self.frame:SetParent(nil)
	self.frame = nil
	wipe(lootTable)
	active = false
	session = 1
	self:UnregisterAllComm()
end

function SLVotingFrame:Hide()
	addon:Debug("Hide VotingFrame")
	self.frame.moreInfo:Hide()
	self.frame:Hide()
end

function SLVotingFrame:Show()
	if self.frame then
		councilInGroup = addon:GetCouncilInGroup()
		self.frame:Show()
		self:SwitchSession(session)
	else
		addon:Print(L["No session running"])
	end
end

function SLVotingFrame:EndSession(hide)
	active = false -- The session has ended, so deactivate
	self:Update()
	if hide then self:Hide() end -- Hide if need be
end

function SLVotingFrame:OnCommReceived(prefix, serializedMsg, distri, sender)
	if prefix == "ScroogeLoot" then
		-- data is always a table to be unpacked
		local decoded = Deflate:DecodeForPrint(serializedMsg)
		if not decoded then 
			return -- probably an old version or somehow a bad message idk just throw this away
		end 
		local decompressed = Deflate:DecompressDeflate(decoded)
		local test, command, data = addon:Deserialize(decompressed)
		if addon:HandleXRealmComms(self, command, data, sender) then return end

		addon:DebugLog("VotingComm received:", command, "from:", sender, "distri:", distri)

		if test then
			if command == "vote" then
				if addon:IsCouncil(sender) or addon:UnitIsUnit(sender, addon.masterLooter) then
					local s, name, vote = unpack(data)
					self:HandleVote(s, name, vote, sender)
				else
					addon:Debug("Non-council member (".. tostring(sender) .. ") sent a vote!")
				end
			
			elseif command == "history_request" and addon.isMasterLooter then 
				local requested_name = unpack(data)
				if addon.successful_history_requests[requested_name] and addon.successful_history_requests[requested_name].ts + 20 > time() then 
					return
				end
				if addon.successful_history_requests[requested_name] and addon.successful_history_requests[requested_name][sender] then 
					return
				end
				addon.successful_history_requests[requested_name] = addon.successful_history_requests[requested_name] or {}
				addon.successful_history_requests[requested_name].ts = time()
				addon.successful_history_requests[requested_name][sender] = true 

				local playerDB = addon:GetHistoryDB()[requested_name] or {}
				local response = {}
				local count = 0

				for i = 1, #playerDB do 
					local entry = playerDB[i] 
					-- respond with only max rolls and the players last 5 roll wins
					if entry.responseID == 1 then 
						tinsert(response, entry)
					elseif not entry.isAwardReason and count < 5 then 
						tinsert(response, entry)
						count = count + 1
					end
				end

				addon:SendCommand("group", "update_history", requested_name, response) -- tell everyone so we don't have to send this a bunch
			
			elseif command == "update_history" and addon:UnitIsUnit(sender, addon.masterLooter) then
				local entry_name, data = unpack(data) 
				addon.mlhistory[entry_name] = data
			
                     elseif command == "change_response" and addon:UnitIsUnit(sender, addon.masterLooter) then
                               local ses, name, response = unpack(data)
                               self:SetCandidateData(ses, name, "response", response)
                               self:SetCandidateData(ses, name, "responseName", addon:GetButtonText(response))
                               self:Update()

                     elseif command == "roll_choice" then
                               local ses, name, rType = unpack(data)
                               local response = RESPONSE_MAP[rType] or rType
                               self:SetCandidateData(ses, name, "response", response)
                               self:SetCandidateData(ses, name, "responseName", rType)
                               if addon.isMasterLooter then
                                       HandleRollChoice(ses, name, rType)
                               end
                               self:Update()

                       elseif command == "lootAck" then
				local name = unpack(data)
                                for i = 1, #lootTable do
                                        self:SetCandidateData(i, name, "response", "WAIT")
                                        self:SetCandidateData(i, name, "responseName", addon:GetResponseText("WAIT"))
                                end
				self:Update()

			elseif command == "awarded" and addon:UnitIsUnit(sender, addon.masterLooter) then
				lootTable[unpack(data)].awarded = true
				if addon.isMasterLooter and session ~= #lootTable then -- ML should move to the next item on award
					self:SwitchSession(session + 1)
				else
					self:SwitchSession(session) -- Use switch session to update awardstring
				end

			elseif command == "candidates" and addon:UnitIsUnit(sender, addon.masterLooter) then
				candidates = unpack(data)

			elseif command == "offline_timer" and addon:UnitIsUnit(sender, addon.masterLooter) then
				for i = 1, #lootTable do
					for name in pairs(lootTable[i].candidates) do
                                                if self:GetCandidateData(i, name, "response") == "ANNOUNCED" then
                                                        addon:DebugLog("No response from:", name)
                                                        self:SetCandidateData(i, name, "response", "NOTHING")
                                                        self:SetCandidateData(i, name, "responseName", addon:GetResponseText("NOTHING"))
                                                end
					end
				end
				self:Update()

                        elseif command == "lootTable" and addon:UnitIsUnit(sender, addon.masterLooter) then
                                print("Voting frame received lootTable session")
                                active = true
                                self:Setup(unpack(data))
                                if not addon.enabled then return end -- We just want things ready
                                if db.autoOpen then
                                        self:Show()
                                else
                                       addon:Print(L['A new session has begun, type "/sl open" to open the voting frame.'])
                                end
                                guildRanks = addon:GetGuildRanks() -- Just update it on every session

                        elseif command == "response" then
                                local session, name, t = unpack(data)
                                for k,v in pairs(t) do
                                        self:SetCandidateData(session, name, k, v)
                                end
                                if t.response then
                                        self:SetCandidateData(session, name, "responseName", addon:GetResponseText(t.response))
                                end
                                self:Update()
			end
		end
	end
end

-- Getter/Setter for candidate data
-- Handles errors
function SLVotingFrame:SetCandidateData(sessionID, candidate, data, val)
        local function Set(sessionID, candidate, data, val)
                local ses = sessionID or session
                if lootTable[ses] and lootTable[ses].candidates[candidate] then
                        lootTable[ses].candidates[candidate][data] = val
                end
        end
        local ok, arg = pcall(Set, sessionID, candidate, data, val)
        if not ok then addon:Debug("Error in 'SetCandidateData':", arg, sessionID, candidate, data, val) end
end

function SLVotingFrame:GetCandidateData(sessionID, candidate, data)
        local function Get(sessionID, candidate, data)
                local ses = sessionID or session
                if lootTable[ses] and lootTable[ses].candidates[candidate] then
                        return lootTable[ses].candidates[candidate][data]
                end
        end
        local ok, arg = pcall(Get, sessionID, candidate, data)
        if not ok then addon:Debug("Error in 'GetCandidateData':", arg, sessionID, candidate, data)
        else return arg end
end

function SLVotingFrame:Setup(table)
	--lootTable[session] = {bagged, lootSlot, awarded, name, link, quality, ilvl, type, subType, equipLoc, texture, boe}
	lootTable = table -- Extract all the data we get
	for session, t in ipairs(lootTable) do -- and build the rest (candidates)
		lootTable[session].haveVoted = false -- Have we voted for ANY candidate in this session?
		t.candidates = {}
		for name, v in pairs(candidates) do
			t.candidates[name] = {
                               class = v.class,
                               rank = v.rank,
                               role = v.role,
                               raiderrank = PlayerDB[name] and PlayerDB[name].raiderrank,
                               attendance = CalculateAttendance(PlayerDB[name] and PlayerDB[name].attended or 0,
                                                            PlayerDB[name] and PlayerDB[name].absent or 0),
                               response = "ANNOUNCED",
                               responseName = addon:GetResponseText("ANNOUNCED"),
                               gear1 = nil,
                               gear2 = nil,
                               votes = 0,
				note = nil,
				roll = "",
				voters = {},
				haveVoted = false, -- Have we voted for this particular candidate in this session?
			}
		end
		-- Init session toggle
		sessionButtons[session] = self:UpdateSessionButton(session, t.texture, t.link, t.awarded)
		sessionButtons[session]:Show()
	end
	-- Hide unused session buttons
	for i = #lootTable+1, #sessionButtons do
		sessionButtons[i]:Hide()
	end
	session = 1
	-- Check if we have enchanters
	for name, v in pairs(candidates) do

	end
	self:BuildST()
	self:SwitchSession(session)
end

function SLVotingFrame:HandleVote(session, name, vote, voter)
	-- Do the vote
	if not lootTable or not lootTable[session] or not lootTable[session].candidates or not lootTable[session].candidates[name] then 
		return 
	end
	
	lootTable[session].candidates[name].votes = (lootTable[session].candidates[name].votes or 0) + vote
	-- And update voters names
	if vote == 1 then
		tinsert(lootTable[session].candidates[name].voters, voter)
	else
		for i, n in ipairs(lootTable[session].candidates[name].voters) do
			if addon:UnitIsUnit(voter, n) then
				tremove(lootTable[session].candidates[name].voters, i)
				break
			end
		end
	end
	self.frame.st:Refresh()
	self:UpdatePeopleToVote()
end



------------------------------------------------------------------
--	Visuals														--
------------------------------------------------------------------
function SLVotingFrame:Update()
	self.frame.st:SortData()
	-- update awardString
	if lootTable[session] and lootTable[session].awarded then
		self.frame.awardString:Show()
	else
		self.frame.awardString:Hide()
	end
	-- This only applies to the ML
	if addon.isMasterLooter then
		-- Update close button text
		if active then
			self.frame.abortBtn:SetText(L["Abort"])
		else
			self.frame.abortBtn:SetText(L["Close"])
		end
                self.frame.disenchant:Show()
                if self.frame.attendance then
                        self.frame.attendance:Show()
                end
        else -- Non-MLs:
                self.frame.abortBtn:SetText(L["Close"])
                self.frame.disenchant:Hide()
                if self.frame.attendance then
                        self.frame.attendance:Hide()
                end
        end
end

function SLVotingFrame:SwitchSession(s)
	addon:Debug("SwitchSession", s)
	-- Start with setting up some statics
	local old = session
	session = s
	local t = lootTable[s] -- Shortcut
	self.frame.itemIcon:SetNormalTexture(t.texture)
	self.frame.itemText:SetText(t.link)
	self.frame.iState:SetText(self:GetItemStatus(t.link))
	self.frame.itemLvl:SetText(format(L["ilvl: x"], t.ilvl))
	-- Set a proper item type text
	if t.subType and t.subType ~= "Miscellaneous" and t.subType ~= "Junk" and t.equipLoc ~= "" then
		self.frame.itemType:SetText(getglobal(t.equipLoc)..", "..t.subType); -- getGlobal to translate from global constant to localized name
	elseif t.subType ~= "Miscellaneous" and t.subType ~= "Junk" then
		self.frame.itemType:SetText(t.subType)
	else
		self.frame.itemType:SetText(getglobal(t.equipLoc));
	end

	-- Update the session buttons
	sessionButtons[s] = self:UpdateSessionButton(s, t.texture, t.link, t.awarded)
	sessionButtons[old] = self:UpdateSessionButton(old, lootTable[old].texture, lootTable[old].link, lootTable[old].awarded)

	-- Since we switched sessions, we want to sort by response
	for i in ipairs(self.frame.st.cols) do
		self.frame.st.cols[i].sort = nil
	end
	self.frame.st.cols[4].sort = "asc"
	FauxScrollFrame_OnVerticalScroll(self.frame.st.scrollframe, 0, self.frame.st.rowHeight, function() self.frame.st:Refresh() end) -- Reset scrolling to 0
	self:Update()
	self:UpdatePeopleToVote()
end

function SLVotingFrame:BuildST()
        local rows = {}
        if lootTable[session] and lootTable[session].candidates then
                for name, cand in pairs(lootTable[session].candidates) do
                        local pdata = PlayerDB and PlayerDB[name] or {}
                        local attendance = CalculateAttendance(pdata.attended, pdata.absent)
                        local row = {
                                name = name,
                                raiderrank = pdata.raiderrank,
                                response = cand.response,
                                responseName = cand.responseName,
                                attendance = attendance,
                                gear1 = cand.gear1,
                                gear2 = cand.gear2,
                                roll = cand.roll,
                                rollInfo = cand.rollInfo,
                                cols = {
                                        { value = pdata.name or name },
                                        { value = pdata.raiderrank and 1 or 0 },
                                        { value = cand.response },
                                        { value = attendance },
                                        { name = "gear1" },
                                        { name = "gear2" },
                                        { value = cand.roll },
                                }
                        }
                        table.insert(rows, row)
                end
        end
        self.frame.st:SetData(rows)
end

function SLVotingFrame:AddVotingRow(rowData)
        if not self.frame or not self.frame.st or not rowData then return end
        local row = {
                name = rowData.name,
                raiderrank = rowData.raiderrank,
                response = rowData.response,
                responseName = rowData.responseName,
                attendance = rowData.attendance,
                gear1 = rowData.gear1,
                gear2 = rowData.gear2,
                roll = rowData.roll,
                rollInfo = rowData.rollInfo,
                cols = {
                        { value = (PlayerDB and PlayerDB[rowData.name] and PlayerDB[rowData.name].name) or rowData.name },
                        { value = rowData.raiderrank and 1 or 0 },
                        { value = rowData.response },
                        { value = rowData.attendance },
                        { name = "gear1" },
                        { name = "gear2" },
                        { value = rowData.roll },
                }
        }
        local st = self.frame.st
        st.data = st.data or {}
        table.insert(st.data, row)
        st:SortData()
end

-- Add a new row to the voting table using roll information
function SLVotingFrame:AddVotingRowFromPlayer(name, rollType, rollValue)
    local pdata = PlayerDB and PlayerDB[name]
    if not pdata then
        print("No PlayerDB entry for", name)
        return
    end
    local sp = pdata.SP or 0
    local dp = pdata.DP or 0
    local adjusted = rollValue
    local reason
    if rollType == "sp" then
        adjusted = adjusted + sp
        reason = "+SP"
    elseif rollType == "dp" then
        adjusted = adjusted + dp
        reason = "+DP"
    end
    if not self.frame or not self.frame.st then return end

    local attendance = CalculateAttendance(pdata.attended, pdata.absent)
    local candidate = lootTable[session] and lootTable[session].candidates[name] or {}
    local st = self.frame.st
    st.data = st.data or {}

    local existing
    for _, r in ipairs(st.data) do
        if r.name == name then existing = r break end
    end

    local row = existing or {
        name = name,
        cols = {
            { value = pdata.name or name },
            { value = pdata.raiderrank and 1 or 0 },
            { value = candidate.response },
            { value = attendance },
            { name = "gear1" },
            { name = "gear2" },
            { value = adjusted },
        }
    }
    row.raiderrank = pdata.raiderrank
    row.response = candidate.response
    row.responseName = candidate.responseName
    row.attendance = attendance
    row.gear1 = candidate.gear1
    row.gear2 = candidate.gear2
    row.roll = adjusted
    row.rollInfo = { base = rollValue, SP = sp, DP = dp, final = adjusted, reason = reason }
    row.cols[1].value = pdata.name or name
    row.cols[2].value = pdata.raiderrank and 1 or 0
    row.cols[3].value = candidate.response
    row.cols[4].value = attendance
    row.cols[7].value = adjusted

    if not existing then table.insert(st.data, row) end
    st:SortData()
end

function SLVotingFrame:UpdateMoreInfo(row, data)
	addon:Debug("MoreInfo:", moreInfo)
	local name
	if data then
		name  = data[row].name
	else -- Try to extract the name from the selected row
		name = self.frame.st:GetSelection() and self.frame.st:GetRow(self.frame.st:GetSelection()).name or nil
	end

	if not moreInfo or not name then -- Hide the frame
		return self.frame.moreInfo:Hide()
	end

	local color = addon:GetClassColor(self:GetCandidateData(session, name, "class"))
	tip = self.frame.moreInfo -- shortening
	local count = {} -- Number of loot received
	tip:SetOwner(self.frame, "ANCHOR_RIGHT")

	--Extract loot history for that name
	local lootDB = addon:GetHistoryDB()
	local hasWonMainspec, entry = false, nil
	local nameCheck
	if lootDB[name] then
		nameCheck = true
	end

	tip:AddLine(name, color.r, color.g, color.b)
	color = {} -- Color of the response
	if nameCheck and #lootDB[name] > 0 then -- they're in the DB!
		tip:AddLine("")
		local nonMainspecEntries = {}
		for i = #lootDB[name], 1, -1 do -- Start from the end
			entry = lootDB[name][i]
			-- check if we have won an item in this slot for a max roll
			-- self.lootTable[session] = {	bagged, lootSlot, awarded, name, link, quality, ilvl, type, subType, equipLoc, texture, boe	}
			local item_slot = lootTable[session].equipLoc
			local itemid = tonumber(select(3, strfind(entry.lootWon, "item:(%d+)"))) or 0
			local historical_item_slot = select(9, GetItemInfo(itemid))

			if not historical_item_slot or historical_item_slot == "" then 
				historical_item_slot = SLTokenTable[itemid]

				if not addon.Slots_INVTYPE[item_slot] then -- when we are comparing a normal item with a token we won previously
					local original = item_slot
					item_slot = addon.INVTYPE_Slots[original] and addon.INVTYPE_Slots[original][1] or addon.INVTYPE_Slots[original] or "INVTYPE_NONE"
					if historic_item_slot ~= item_slot and addon.INVTYPE_Slots[original] and addon.INVTYPE_Slots[original]["or"] then
						item_slot = addon.INVTYPE_Slots[original]["or"]
					end 
				end
			end

			if entry.responseID == addon.db.profile.checkID or 1 and not entry.isAwardReason and item_slot == historical_item_slot and not hasWonMainspec then -- Won MS roll for this slot
				tip:AddDoubleLine(format(L["Item won for 'roll':"], addon:GetResponseText(entry.responseID)), "", 1,1,1, 1,1,1)
				tip:AddLine(entry.lootWon)
				tip:AddDoubleLine(entry.time .. " " ..entry.date, format(L["'n days' ago"], addon:ConvertDateToString(addon:GetNumberOfDaysFromNow(entry.date))), 1,1,1, 1,1,1)
				tip:AddLine(" ") -- Spacer
				hasWonMainspec = true
			else
				if #nonMainspecEntries < 5 then -- only save last 5 items won
					tinsert(nonMainspecEntries, entry)
				end
			end

			-- count overall responses
			count[entry.response] = count[entry.response] and count[entry.response] + 1 or 1
			if not color[entry.response] then -- If it's not already added
				color[entry.response] = entry.color and #entry.color == 4 and entry.color or addon:GetResponseColorTable(entry.responseID) or {1, 1, 1, 1}
			end

		end -- end counting

		if not hasWonMainspec then -- list non mainspec entries if we havent won a mainspec item
			tip:AddLine(" ")
			tip:AddLine("Last 5 items won:")
			for _, entry in ipairs(nonMainspecEntries) do 
				local r, g, b = unpack(addon:GetResponseColorTable(entry.responseID))
				tip:AddDoubleLine(format(L["Won 'item'"], entry.lootWon), addon:GetResponseText(entry.responseID), 1,1,1, r, g, b)
				tip:AddDoubleLine(entry.time .. " " ..entry.date, format(L["'n days' ago"], addon:ConvertDateToString(addon:GetNumberOfDaysFromNow(entry.date))), 1,1,1, 1,1,1)
			end
			tip:AddLine(" ")
		end

		local totalNum = 0
		for response, num in pairs(count) do
			local r,g,b = unpack(color[response])
			tip:AddDoubleLine(response, num, r,g,b, r,g,b) -- Make sure we don't add the alpha value
			totalNum = totalNum + num
		end
		tip:AddDoubleLine(L["Total items received:"], totalNum, 0,1,1, 0,1,1)
	elseif not nameCheck and not addon.isMasterLooter then
		--request history for this specific guy
		addon:SendCommand(addon.masterLooter, "history_request", name)
		tip:AddLine("Requesting loot history from Master Looter...")
		self:ScheduleTimer("UpdateMoreInfo", 1, row, data)
	else 
		tip:AddLine(L["No entries in the Loot History"])
	end
	tip:SetScale(max(0.5, db.UI.votingframe.scale-0.1)) -- Make it a bit smaller, as it's too wide otherwise
	tip:Show()
	tip:SetAnchorType("ANCHOR_RIGHT", 0, -tip:GetHeight())
end


function SLVotingFrame:GetFrame()
	if self.frame then return self.frame end

	-- Container and title
	local f = addon:CreateFrame("DefaultScroogeLootFrame", "votingframe", L["ScroogeLoot Voting Frame"], 250, 420)
	-- Scrolling table
	local st = LibStub("ScrollingTable"):CreateST(self.scrollCols, NUM_ROWS, ROW_HEIGHT, { ["r"] = 1.0, ["g"] = 0.9, ["b"] = 0.0, ["a"] = 0.5 }, f.content)
	st.frame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
	st:RegisterEvents({
		["OnClick"] = function(rowFrame, cellFrame, data, cols, row, realrow, column, table, button, ...)
			if button == "RightButton" and row then
				if active then
					menuFrame.name = data[realrow].name
					Lib_ToggleDropDownMenu(1, nil, menuFrame, cellFrame, 0, 0);
				else
					addon:Print(L["You cannot use the menu when the session has ended."])
				end
			elseif button == "LeftButton" and row then -- Update more info
				self:UpdateMoreInfo(realrow, data)
			end
			-- Return false to have the default OnClick handler take care of left clicks
			return false
		end,
	})
	st:SetFilter(SLVotingFrame.filterFunc)
	st:EnableSelection(true)
        st:SetData({})
	f.st = st
	--[[------------------------------
		Session item icon and strings
	    ------------------------------]]
	local item = CreateFrame("Button", nil, f.content)
	item:EnableMouse()
    item:SetNormalTexture("Interface/ICONS/INV_Misc_QuestionMark")
    item:SetScript("OnEnter", function()
		if not lootTable then return; end
		addon:CreateHypertip(lootTable[session].link)
	end)
	item:SetScript("OnLeave", addon.HideTooltip)
	item:SetScript("OnClick", function()
		if not lootTable then return; end
	    if ( IsModifiedClick() ) then
		    HandleModifiedItemClick(lootTable[session].link);
        end
    end);
	item:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -20)
	item:SetSize(50,50)
	f.itemIcon = item

	local iTxt = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	iTxt:SetPoint("TOPLEFT", item, "TOPRIGHT", 10, 0)
       -- Display a clearer message when no session is active
       iTxt:SetText(L["No session running"]) -- Set text for reasons
	f.itemText = iTxt

	local ilvl = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ilvl:SetPoint("TOPLEFT", iTxt, "BOTTOMLEFT", 0, -4)
	ilvl:SetTextColor(1, 1, 1) -- White
	ilvl:SetText("")
	f.itemLvl = ilvl

	local iState = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	iState:SetPoint("LEFT", ilvl, "RIGHT", 5, 0)
	iState:SetTextColor(0,1,0,1) -- Green
	iState:SetText("")
	f.iState = iState

	local iType = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	iType:SetPoint("TOPLEFT", ilvl, "BOTTOMLEFT", 0, -4)
	iType:SetTextColor(0.5, 1, 1) -- Turqouise
	iType:SetText("")
	f.itemType = iType
	--#end----------------------------

	-- Abort button
	local b1 = addon:CreateButton(L["Close"], f.content)
	b1:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -50)
	if addon.isMasterLooter then
		b1:SetScript("OnClick", function() if active then LibDialog:Spawn("SLLOOTCOUNCIL_CONFIRM_ABORT") else self:Hide() end end)
	else
		b1:SetScript("OnClick", function() self:Hide() end)
	end
	f.abortBtn = b1

	-- More info button
	local b2 = CreateFrame("Button", nil, f.content, "UIPanelButtonTemplate")
	b2:SetSize(25,25)
	b2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -20)
	if moreInfo then
		b2:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
		b2:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
	else
		b2:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		b2:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
	end
	b2:SetScript("OnClick", function(button)
		moreInfo = not moreInfo
		db.modules["SLVotingFrame"].moreInfo = moreInfo
		if moreInfo then -- show the more info frame
			button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
			button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
		else -- hide it
			button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
			button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
		end
		self:UpdateMoreInfo()
	end)
	b2:SetScript("OnEnter", function() addon:CreateTooltip(L["Click to expand/collapse more info"]) end)
	b2:SetScript("OnLeave", addon.HideTooltip)
	f.moreInfoBtn = b2

	f.moreInfo = CreateFrame( "GameTooltip", "SLVotingFrameMoreInfo", nil, "GameTooltipTemplate" )

	-- Filter
	local b3 = addon:CreateButton(L["Filter"], f.content)
	b3:SetPoint("RIGHT", b1, "LEFT", -10, 0)
	b3:SetScript("OnClick", function(self) Lib_ToggleDropDownMenu(1, nil, filterMenu, self, 0, 0) end )
	b3:SetScript("OnEnter", function() addon:CreateTooltip(L["Deselect responses to filter them"]) end)
	b3:SetScript("OnLeave", addon.HideTooltip)
	f.filter = b3

	-- Disenchant button
	local b4 = addon:CreateButton(L["Disenchant"], f.content)
	b4:SetPoint("RIGHT", b3, "LEFT", -10, 0)
	b4:SetScript("OnClick", function(self) Lib_ToggleDropDownMenu(1, nil, enchanters, self, 0, 0) end )
	--b4:SetNormalTexture("Interface\\Icons\\INV_Enchant_Disenchant")
--	b4:Hide() -- hidden by default
	f.disenchant = b4
        -- Attendance Check button
        local b5 = addon:CreateButton(L["Attendance Check"], f.content)
        b5:SetPoint("RIGHT", b4, "LEFT", -10, 0)
        b5:SetScript("OnClick", function()
                if not addon.isMasterLooter then
                        return addon:Print(L["You cannot use this command without being the Master Looter"])
                end
                PlayerDB = PlayerDB or {}
                local inRaid = {}

                if addon:IsInRaid() then
                        for i = 1, addon:GetNumGroupMembers() do
                                local name = UnitName("raid" .. i)
                                if name then
                                        inRaid[name] = true
                                end
                        end
                elseif addon:IsInGroup() then
                        for i = 0, addon:GetNumGroupMembers() do
                                local unit = i == 0 and "player" or ("party" .. i)
                                local name = UnitName(unit)
                                if name then
                                        inRaid[name] = true
                                end
                        end
                else
                        local name = UnitName("player")
                        if name then
                                inRaid[name] = true
                        end
                end

                for name, data in pairs(PlayerDB) do
                        data.attended = data.attended or 0
                        data.absent = data.absent or 0
                        if inRaid[name] then
                                data.attended = data.attended + 1
                        else
                                data.absent = data.absent + 1
                        end
                        local total = data.attended + data.absent
                        data.attendance = total > 0 and math.floor((data.attended / total) * 100) or 0

                        -- Award SP for raiders on attendance check
                        if data.raiderrank then
                                data.SP = (data.SP or 0) + 5
                        end
                end

                if addon.playerDB and addon.playerDB.global then
                        addon.playerDB.global.playerData = PlayerDB
                end

                if SLVotingFrame.frame and SLVotingFrame.frame.st and SLVotingFrame.frame.st.data then
                        for _, row in ipairs(SLVotingFrame.frame.st.data) do
                                UpdateVotingRow(row.name)
                        end
                end

                addon:Print("Attendance updated")
        end)
        f.attendance = b5

	-- Number of votes
	local rf = CreateFrame("Frame", nil, f.content)
	rf:SetWidth(100)
	rf:SetHeight(20)
	if b2 then rf:SetPoint("RIGHT", b2, "LEFT", -10, 0) else rf:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -20) end
	rf:SetScript("OnLeave", function()
		addon:HideTooltip()
	end)
	local rft = rf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	rft:SetPoint("CENTER", rf, "CENTER")
	rft:SetText(" ")
	rft:SetTextColor(0,1,0,1) -- Green
	rf.text = rft
	rf:SetWidth(rft:GetStringWidth())
	f.rollResult = rf

	-- Award string
	local awdstr = f.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	awdstr:SetPoint("CENTER", f.content, "TOP", 0, -60)
	awdstr:SetText(L["Item has been awarded"])
	awdstr:SetTextColor(1, 1, 0, 1) -- Yellow
	awdstr:Hide()
	f.awardString = awdstr

	-- Session toggle
	local stgl = CreateFrame("Frame", nil, f.content)
	stgl:SetWidth(40)
	stgl:SetHeight(f:GetHeight())
	stgl:SetPoint("TOPRIGHT", f, "TOPLEFT", -2, 0)
	f.sessionToggleFrame = stgl

	-- Set a proper width
	f:SetWidth(st.frame:GetWidth() + 20)
	return f;
end

function SLVotingFrame:UpdatePeopleToVote()
	local voters = {}
	-- Find out who have voted
	for name in pairs(lootTable[session].candidates) do
		for _, voter in pairs(lootTable[session].candidates[name].voters) do
			if not tContains(voters, voter) then
				tinsert(voters, voter)
			end
		end
	end
	if #councilInGroup == 0 then
		self.frame.rollResult.text:SetText(L["Couldn't find any councilmembers in the group"])
		self.frame.rollResult.text:SetTextColor(1,0,0,1) -- Red
	elseif #voters == #councilInGroup then
		self.frame.rollResult.text:SetText(L["Everyone have voted"])
		self.frame.rollResult.text:SetTextColor(0,1,0,1) -- Green
	elseif #voters < #councilInGroup then
		self.frame.rollResult.text:SetText(format(L["x out of x have voted"], #voters, #councilInGroup))
		self.frame.rollResult.text:SetTextColor(1,1,0,1) -- Yellow
	else
		addon:Debug("#voters > #councilInGroup ?")
	end
	self.frame.rollResult:SetScript("OnEnter", function()
		addon:CreateTooltip(L["The following council members have voted"], unpack(voters))
	end)
	self.frame.rollResult:SetWidth(self.frame.rollResult.text:GetStringWidth())
end

function SLVotingFrame:UpdateSessionButton(i, texture, link, awarded)
	local btn = sessionButtons[i]
	if not btn then -- create the button
		btn = CreateFrame("Button", "SLButton"..i, self.frame.sessionToggleFrame)
		btn:SetSize(40,40)
		--btn:SetText(i)
		if i == 1 then
			btn:SetPoint("TOPRIGHT", self.frame.sessionToggleFrame)
		elseif mod(i,10) == 1 then
			btn:SetPoint("TOPRIGHT", sessionButtons[i-10], "TOPLEFT", -2, 0)
		else
			btn:SetPoint("TOP", sessionButtons[i-1], "BOTTOM", 0, -2)
		end
                btn:SetScript("OnClick", function() SLVotingFrame:SwitchSession(i); end)
		btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		btn:GetHighlightTexture():SetBlendMode("ADD")
		btn:SetNormalTexture(texture or "Interface\\InventoryItems\\WoWUnknownItem01")
		btn:GetNormalTexture():SetDrawLayer("BACKGROUND")
	end
	-- then update it
	btn:SetNormalTexture(texture or "Interface\\InventoryItems\\WoWUnknownItem01")
	-- Set the colored border and tooltips
	btn:SetBackdrop({
		bgFile = "",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 18,
		--insets = { left = -4, right = -4, top = -4, bottom = -4 }
	})
	local lines = { format(L["Click to switch to 'item'"], link) }
	if i == session then
		btn:SetBackdropBorderColor(1,1,0,1) -- yellow
		--btn:SetBackdropColor(1,1,1,1)
		btn:GetNormalTexture():SetVertexColor(1,1,1)
	elseif awarded then
		btn:SetBackdropBorderColor(0,1,0,1) -- green
		--btn:SetBackdropColor(1,1,1,0.8)
		btn:GetNormalTexture():SetVertexColor(0.8,0.8,0.8)
		tinsert(lines, L["This item has been awarded"])
	else
		btn:SetBackdropBorderColor(1,1,1,1) -- white
		--btn:SetBackdropColor(0.5,0.5,0.5,0.8)
		btn:GetNormalTexture():SetVertexColor(0.5,0.5,0.5)
	end
	btn:SetScript("OnEnter", function() addon:CreateTooltip(unpack(lines)) end)
	btn:SetScript("OnLeave", function() addon:HideTooltip() end)
	return btn
end


----------------------------------------------------------
--	Lib-st data functions (not particular pretty, I know)
----------------------------------------------------------
-- Display boolean raiderrank as Yes/No
local function RaiderText(flag)
       return flag and L["Yes"] or L["No"]
end

function SLVotingFrame.SetCellClass(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	local name = data[realrow].name
	addon.SetCellClassIcon(rowFrame, frame, data, cols, row, realrow, column, fShow, table, lootTable[session].candidates[name].class)
end

function SLVotingFrame.SetCellName(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
        local name = data[realrow].name
        local displayName = name
        if PlayerDB and PlayerDB[name] and PlayerDB[name].name then
                displayName = PlayerDB[name].name
        end
        frame.text:SetText(displayName)
        local c = addon:GetClassColor(lootTable[session].candidates[name].class)
        frame.text:SetTextColor(c.r, c.g, c.b, c.a)
        data[realrow].cols[column].value = displayName
end

function SLVotingFrame.SetCellRank(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
        local name = data[realrow].name
        local db = PlayerDB and PlayerDB[name]
        local val = db and db.raiderrank
        frame.text:SetText(RaiderText(val))
        data[realrow].cols[column].value = val and 1 or 0
end

function SLVotingFrame.SetCellResponse(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
        local name = data[realrow].name
        local cand = lootTable[session].candidates[name]
        local text = cand.responseName or addon:GetResponseText(cand.response)
        frame.text:SetText(text)
        frame.text:SetTextColor(addon:GetResponseColor(cand.response))
end

function SLVotingFrame.SetCellRaider(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
       local name = data[realrow].name
       local db = PlayerDB and PlayerDB[name]
       local val = db and db.raiderrank
       frame.text:SetText(RaiderText(val))
       data[realrow].cols[column].value = val and 1 or 0
end

function SLVotingFrame.SetCellAttendance(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
       local name = data[realrow].name
       local db = PlayerDB and PlayerDB[name]
       local val = db and CalculateAttendance(db.attended, db.absent) or 0
       frame.text:SetText(tostring(val))
       data[realrow].cols[column].value = tonumber(val) or 0
end

function SLVotingFrame.SetCellGear(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	local gear = data[realrow].cols[column].name -- gear1 or gear2
	local name = data[realrow].name
	gear = lootTable[session].candidates[name][gear] -- Get the actual gear
	if gear then
		local texture = select(10, GetItemInfo(gear))
		frame:SetNormalTexture(texture)
		frame:SetScript("OnEnter", function() addon:CreateHypertip(gear) end)
		frame:SetScript("OnLeave", function() addon:HideTooltip() end)
		frame:Show()
        else
                frame:Hide()
        end
end

function SLVotingFrame.SetCellGear1(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
        data[realrow].cols[column].name = "gear1"
        SLVotingFrame.SetCellGear(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
end

function SLVotingFrame.SetCellGear2(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
        data[realrow].cols[column].name = "gear2"
        SLVotingFrame.SetCellGear(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
end

function SLVotingFrame.SetCellVotes(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	local name = data[realrow].name
	frame:SetScript("OnEnter", function()
		if not addon.mldb.anonymousVoting or (db.showForML and addon.isMasterLooter) then
			if not addon.mldb.hideVotes or (addon.mldb.hideVotes and lootTable[session].haveVoted) then
				addon:CreateTooltip(L["Voters"], unpack(lootTable[session].candidates[name].voters))
			end
		end
	end)
	frame:SetScript("OnLeave", function() addon:HideTooltip() end)
	local val = lootTable[session].candidates[name].votes
	data[realrow].cols[column].value = val -- Set the value for sorting reasons
	frame.text:SetText(val)

	if addon.mldb.hideVotes then
		if not lootTable[session].haveVoted then frame.text:SetText(0) end
	end
end

function SLVotingFrame.SetCellVote(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	local name = data[realrow].name
	if not active or lootTable[session].awarded then -- Don't show the vote button if awarded or not active
		if frame.voteBtn then
			frame.voteBtn:Hide()
		end
		return
	end
	if addon.isCouncil or addon.isMasterLooter then -- Only let the right people vote
		if not frame.voteBtn then -- create it
			frame.voteBtn = addon:CreateButton(L["Vote"], frame)
			frame.voteBtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
			frame.voteBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
		end
		frame.voteBtn:SetScript("OnClick", function(btn)
			addon:Debug("Vote button pressed")
			if lootTable[session].candidates[name].haveVoted then -- unvote
				addon:SendCommand("group", "vote", session, name, -1)
				lootTable[session].candidates[name].haveVoted = false

				-- Check if that was our only vote
				local haveVoted = false
				for _, v in pairs(lootTable[session].candidates) do
					if v.haveVoted then haveVoted = true end
				end
				lootTable[session].haveVoted = haveVoted

			else -- vote
				-- Test if they may vote for themselves
				if not addon.mldb.selfVote and addon:UnitIsUnit("player", name) then
					return addon:Print(L["The Master Looter doesn't allow votes for yourself."])
				end
				-- Test if they're allowed to cast multiple votes
				if not addon.mldb.multiVote then
					if lootTable[session].haveVoted then
						return addon:Print(L["The Master Looter doesn't allow multiple votes."])
					end
				end
				-- Do the vote
				addon:SendCommand("group", "vote", session, name, 1)
				lootTable[session].candidates[name].haveVoted = true
				lootTable[session].haveVoted = true
			end
		end)
		frame.voteBtn:Show()
		if lootTable[session].candidates[name].haveVoted then
			frame.voteBtn:SetText(L["Unvote"])
		else
			frame.voteBtn:SetText(L["Vote"])
		end
	end
end

function SLVotingFrame.SetCellNote(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	local name = data[realrow].name
	local note = lootTable[session].candidates[name].note
	local f = frame.noteBtn or CreateFrame("Button", nil, frame)
	f:SetSize(ROW_HEIGHT, ROW_HEIGHT)
	f:SetPoint("CENTER", frame, "CENTER")
	if note then
		f:SetNormalTexture("Interface/BUTTONS/UI-GuildButton-PublicNote-Up.png")
		f:SetScript("OnEnter", function() addon:CreateTooltip(L["Note"], note)	end)
		f:SetScript("OnLeave", function() addon:HideTooltip() end)
		data[realrow].cols[column].value = 1 -- Set value for sorting compability
	else
		f:SetScript("OnEnter", nil)
		f:SetNormalTexture("Interface/BUTTONS/UI-GuildButton-PublicNote-Disabled.png")
		data[realrow].cols[column].value = 0
	end
	frame.noteBtn = f
end

function SLVotingFrame.SetCellRoll(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
       local name = data[realrow].name
       local info = lootTable[session].candidates[name].rollInfo or {}
       frame.text:SetText(lootTable[session].candidates[name].roll)
       frame:SetScript("OnEnter", function()
               local lines = {}
               local base = info.base or 0
               tinsert(lines, "Base: " .. tostring(base))
               if info.reason == "+SP" and info.SP then
                       tinsert(lines, "SP: +" .. tostring(info.SP))
               elseif info.reason == "+DP" and info.DP then
                       tinsert(lines, "DP: +" .. tostring(info.DP))
               end
               local final = info.final or base
               tinsert(lines, "Final: " .. tostring(final))
               addon:CreateTooltip(unpack(lines))
       end)
       frame:SetScript("OnLeave", addon.HideTooltip)
       data[realrow].cols[column].value = lootTable[session].candidates[name].roll
end

function SLVotingFrame.filterFunc(table, row)
	if not db.modules["SLVotingFrame"].filters then return true end -- db hasn't been initialized, so just show it
	local response = lootTable[session].candidates[row.name].response
	if response == "AUTOPASS" or response == "PASS" or type(response) == "number" then
		return db.modules["SLVotingFrame"].filters[response]
	else -- Filter out the status texts
		return db.modules["SLVotingFrame"].filters["STATUS"]
	end
end

function ResponseSort(table, rowa, rowb, sortbycol)
	if type(rowa) == "table" then printtable(rowa) end
	local column = table.cols[sortbycol]
	local a, b = table:GetRow(rowa), table:GetRow(rowb);
	a, b = addon:GetResponseSort(lootTable[session].candidates[a.name].response), addon:GetResponseSort(lootTable[session].candidates[b.name].response)
	if a == b then
		if column.sortnext then
			local nextcol = table.cols[column.sortnext];
			if not(nextcol.sort) then
				if nextcol.comparesort then
					return nextcol.comparesort(table, rowa, rowb, column.sortnext);
				else
					return table:CompareSort(rowa, rowb, column.sortnext);
				end
			end
		end
		return false
	else
		local direction = column.sort or column.defaultsort or "asc";
		if direction:lower() == "asc" then
			return a < b;
		else
			return a > b;
		end
	end
end

function GuildRankSort(table, rowa, rowb, sortbycol)
	local column = table.cols[sortbycol]
	local a, b = table:GetRow(rowa), table:GetRow(rowb);
	-- Extract the rank index from the name, fallback to 100 if not found
	a = guildRanks[lootTable[session].candidates[a.name].rank] or 100
	b = guildRanks[lootTable[session].candidates[b.name].rank] or 100
	if a == b then
		if column.sortnext then
			local nextcol = table.cols[column.sortnext];
			if not(nextcol.sort) then
				if nextcol.comparesort then
					return nextcol.comparesort(table, rowa, rowb, column.sortnext);
				else
					return table:CompareSort(rowa, rowb, column.sortnext);
				end
			end
		end
		return false
	else
		local direction = column.sort or column.defaultsort or "asc";
		if direction:lower() == "asc" then
			return a > b;
		else
			return a < b;
		end
	end
end

----------------------------------------------------
--	Dropdowns
----------------------------------------------------
do
	local info = Lib_UIDropDownMenu_CreateInfo() -- Efficiency :)
	-- NOTE Take care of info[] values when inserting new buttons
	function SLVotingFrame.RightClickMenu(menu, level)
		if not addon.isMasterLooter then return end

		local candidateName = menu.name
		local data = lootTable[session].candidates[candidateName] -- Shorthand

		if level == 1 then
			info.text = candidateName
			info.isTitle = true
			info.notCheckable = true
			info.disabled = true
			Lib_UIDropDownMenu_AddButton(info, level)

			info.text = ""
			info.isTitle = false
			Lib_UIDropDownMenu_AddButton(info, level)

			info.text = L["Award"]
			info.func = function()
				LibDialog:Spawn("SLLOOTCOUNCIL_CONFIRM_AWARD", {
					session,
				  	candidateName,
					data.response,
					nil,
					data.votes,
					data.gear1,
					data.gear2,
			}) end
			info.disabled = false
			Lib_UIDropDownMenu_AddButton(info, level)
			info = Lib_UIDropDownMenu_CreateInfo()

			info.text = L["Award for ..."]
			info.value = "AWARD_FOR"
			info.notCheckable = true
			info.hasArrow = true
			Lib_UIDropDownMenu_AddButton(info, level)
			info = Lib_UIDropDownMenu_CreateInfo()

			info.text = ""
			info.notCheckable = true
			info.disabled = true
			Lib_UIDropDownMenu_AddButton(info, level)

			info.text = L["Change Response"]
			info.value = "CHANGE_RESPONSE"
			info.hasArrow = true
			info.disabled = false
			Lib_UIDropDownMenu_AddButton(info, level)

			info.text = L["Reannounce ..."]
			info.value = "REANNOUNCE"
			Lib_UIDropDownMenu_AddButton(info, level)
			info = Lib_UIDropDownMenu_CreateInfo()

			info.text = L["Remove from consideration"]
			info.notCheckable = true
			info.func = function()
				addon:SendCommand("group", "change_response", session, candidateName, "REMOVED")
			end
			Lib_UIDropDownMenu_AddButton(info, level)



		elseif level == 2 then
			local value = LIB_UIDROPDOWNMENU_MENU_VALUE
			info = Lib_UIDropDownMenu_CreateInfo()
			if value == "AWARD_FOR" then
				for k,v in ipairs(db.awardReasons) do
					if k > db.numAwardReasons then break end
					info.text = v.text
					info.notCheckable = true
					info.func = function()
						LibDialog:Spawn("SLLOOTCOUNCIL_CONFIRM_AWARD", {
							session,
						  	candidateName,
							nil,
							v,
							data.votes,
							data.gear1,
							data.gear2,
				}) end
					Lib_UIDropDownMenu_AddButton(info, level)
				end

			elseif value == "CHANGE_RESPONSE" then
				for i = 1, db.numButtons do
					local v = db.responses[i]
					info.text = v.text
					info.colorCode = "|cff"..addon:RGBToHex(unpack(v.color))
					info.notCheckable = true
					info.func = function()
							addon:SendCommand("group", "change_response", session, candidateName, i)
					end
					Lib_UIDropDownMenu_AddButton(info, level)
				end

			elseif value == "REANNOUNCE" then
				info.text = candidateName
				info.isTitle = true
				info.notCheckable = true
				info.disabled = true
				Lib_UIDropDownMenu_AddButton(info, level)
				info = Lib_UIDropDownMenu_CreateInfo()

				info.text = L["This item"]
				info.notCheckable = true
				info.func = function()
					local t = {
						{	name = lootTable[session].name,
							link = lootTable[session].link,
							ilvl = lootTable[session].ilvl,
							texture = lootTable[session].texture,
							session = session,
							equipLoc = lootTable[session].equipLoc,
						}
					}
					addon:SendCommand(candidateName, "reroll", t)
				end
				Lib_UIDropDownMenu_AddButton(info, level);
				info = Lib_UIDropDownMenu_CreateInfo()

				info.text = L["All items"]
				info.notCheckable = true
				info.func = function()
					local t = {}
					for k,v in ipairs(lootTable) do
						if not v.awarded then
							tinsert(t, {
								name = v.name,
								link = v.link,
								ilvl = v.ilvl,
								texture = v.texture,
								session = k,
								equipLoc = v.equipLoc,
							})
						end
					end
					addon:SendCommand(candidateName, "reroll", t)
				end
				Lib_UIDropDownMenu_AddButton(info, level);
			end
		end
	end

	function SLVotingFrame.FilterMenu(menu, level)
		if level == 1 then -- Redundant
			-- Build the data table:
			local data = {["STATUS"] = true, ["PASS"] = true, ["AUTOPASS"] = true}
			for i = 1, addon.mldb.numButtons or db.numButtons do
				data[i] = i
			end
			if not db.modules["SLVotingFrame"].filters then -- Create the db entry
				addon:DebugLog("Created VotingFrame filters")
				db.modules["SLVotingFrame"].filters = {}
			end
			for k in pairs(data) do -- Update the db entry to make sure we have all buttons in it
				if type(db.modules["SLVotingFrame"].filters[k]) ~= "boolean" then
					addon:Debug("Didn't contain "..k)
					db.modules["SLVotingFrame"].filters[k] = true -- Default as true
				end
			end
			info.text = L["Filter"]
			info.isTitle = true
			info.notCheckable = true
			info.disabled = true
			Lib_UIDropDownMenu_AddButton(info, level)
			info = Lib_UIDropDownMenu_CreateInfo()

			for k in ipairs(data) do -- Make sure normal responses are on top
				info.text = addon:GetResponseText(k)
				info.colorCode = "|cff"..addon:RGBToHex(addon:GetResponseColor(k))
				info.func = function()
					addon:Debug("Update Filter")
					db.modules["SLVotingFrame"].filters[k] = not db.modules["SLVotingFrame"].filters[k]
					SLVotingFrame:Update()
				end
				info.checked = db.modules["SLVotingFrame"].filters[k]
				Lib_UIDropDownMenu_AddButton(info, level)
			end
			for k in pairs(data) do -- A bit redundency, but it makes sure these "specials" comes last
				if type(k) == "string" then
					if k == "STATUS" then
						info.text = L["Status texts"]
						info.colorCode = "|cffde34e2" -- purpleish
					else
						info.text = addon:GetResponseText(k)
						info.colorCode = "|cff"..addon:RGBToHex(addon:GetResponseColor(k))
					end
					info.func = function()
						addon:Debug("Update Filter")
						db.modules["SLVotingFrame"].filters[k] = not db.modules["SLVotingFrame"].filters[k]
						SLVotingFrame:Update()
					end
					info.checked = db.modules["SLVotingFrame"].filters[k]
					Lib_UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	end

	function SLVotingFrame.EnchantersMenu(menu, level)
		if level == 1 then
			local added = false
			info = Lib_UIDropDownMenu_CreateInfo()
			if not db.disenchant then
				return addon:Print("You haven't selected an award reason to use for disenchanting!")
			end
			for name, v in pairs(candidates) do
				if v.enchanter then
					local c = addon:GetClassColor(v.class)
					info.text = "|cff"..addon:RGBToHex(c.r, c.g, c.b)..name.."|r "..tostring(v.enchant_lvl)
					info.notCheckable = true
					info.func = function()
						for k,v in ipairs(db.awardReasons) do
							if v.disenchant then
								LibDialog:Spawn("SLLOOTCOUNCIL_CONFIRM_AWARD", {
									session,
								  	name,
									nil,
									v,
								})
								return
							end
						end
					end
					added = true
					Lib_UIDropDownMenu_AddButton(info, level)
				end
			end
			if not added then -- No enchanters available
				info.text = L["No (dis)enchanters found"]
				info.notCheckable = true
				info.isTitle = true
				Lib_UIDropDownMenu_AddButton(info, level)
			end
		end
	end
end

function SLVotingFrame:GetItemStatus(item)
	--addon:DebugLog("GetitemStatus", item)
	if not item then return "" end
	GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	GameTooltip:SetHyperlink(item)
	local text = ""
	if GameTooltip:NumLines() > 1 then -- check that there is something here
		local line = getglobal('GameTooltipTextLeft2') -- Should always be line 2
		-- The following color string should be there if we have a green status text
		if strfind(line:GetText(), "cFF 0FF 0") then
			text = line:GetText()
		end
	end
	GameTooltip:Hide()
	return text
end
