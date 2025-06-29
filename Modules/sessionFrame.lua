-- Author      : Potdisc
-- Create Date : 1/20/2015 3:48:38 AM
-- DefaultModule - Requires ml_core.lua or similary functionality.
-- sessionFrame.lua	Adds a frame listing the items to start a session with.

local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")
local SLSessionFrame = addon:NewModule("SLSessionFrame", "AceTimer-3.0")
local ST = LibStub("ScrollingTable")
local L = LibStub("AceLocale-3.0"):GetLocale("ScroogeLoot")

local ml;
local ROW_HEIGHT = 40
local awardLater = false
local loadingItems = false

function SLSessionFrame:OnInitialize()
	self.scrollCols = {
		{ name = "", sortnext = 3,	width = 30 }, 			-- remove item
		{ name = "", sortnext = 3,	width = ROW_HEIGHT },-- item icon
		{ name = L["Item"],			width = 150}, 			-- item link
	}
end

function SLSessionFrame:OnEnable()
	ml = addon:GetActiveModule("masterlooter")
end

function SLSessionFrame:OnDisable()
	self.frame:Hide()
	self.frame.rows = {}
	awardLater = false
end

function SLSessionFrame:Show(data)
	self.frame = self:GetFrame()
	self.frame:Show()
	if data then
		loadingItems = false
		self:ExtractData(data)
		self.frame.st:SetData(self.frame.rows)
		self:Update()
	end
end

function SLSessionFrame:Hide()
	self.frame:Hide()
end

-- Data should be unmodified lootTable from ml_core
function SLSessionFrame:ExtractData(data)
	-- We could get an empty table if we haven't got GetItemInfo() from ml_core, so make sure we can handle it
	--if not data or #data == 0 then data = {{link = false}} end
	-- Clear any rowdata
	self.frame.rows = {}
	-- And set the new
	for k,v in ipairs(data) do
		self.frame.rows[k] = {
			texture = v.texture or nil,
			link = v.link,
			cols = {
				{ value = "",	DoCellUpdate = self.SetCellDeleteBtn, },
				{ value = "",	DoCellUpdate = self.SetCellItemIcon},
				{ value = v.link,	DoCellUpdate = self.SetCellText },
			},
		}
	end
end

function SLSessionFrame:Update()
	self.frame.toggle:SetChecked(awardLater)
end

function SLSessionFrame:DeleteItem(index)
	addon:Debug("Delete row:", index)
	ml:RemoveItem(index) -- remove the item from MLs lootTable
	self:Show(ml.lootTable)
end

function SLSessionFrame.SetCellText(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	if frame.text:GetFontObject() ~= GameFontNormal then
		frame.text:SetFontObject("GameFontNormal") -- We want bigger font
	end
	if not data[realrow].link then
		frame.text:SetText("--"..L["Waiting for item info"].."--")
		loadingItems = true
		SLSessionFrame:ScheduleTimer("Show", 1, ml.lootTable) -- Expect data to be available in 1 sec and then recreate the frame
	else
		frame.text:SetText(data[realrow].link)
	end
end

function SLSessionFrame.SetCellDeleteBtn(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	frame:SetNormalTexture("Interface/BUTTONS/UI-GroupLoot-Pass-Up.png")
	frame:SetScript("OnClick", function() SLSessionFrame:DeleteItem(realrow) end)
	frame:SetSize(20,20)
end

function SLSessionFrame.SetCellItemIcon(rowFrame, frame, data, cols, row, realrow, column, fShow, table, ...)
	local texture = data[realrow].texture or "Interface/ICONS/INV_Sigil_Thorim.png"
	local link = data[realrow].link
	frame:SetNormalTexture(texture)
	frame:SetScript("OnEnter", function() addon:CreateHypertip(link) end)
	frame:SetScript("OnLeave", function() addon:HideTooltip() end)
	frame:SetScript("OnClick", function()
		if IsModifiedClick() then
		   HandleModifiedItemClick(link);
      end
	end)
end

function SLSessionFrame:GetFrame()
	if self.frame then return self.frame end

	local f = addon:CreateFrame("DefaultSLSessionSetupFrame", "sessionframe", L["ScroogeLoot Session Setup"], 250)

	local tgl = CreateFrame("CheckButton", f:GetName().."Toggle", f.content, "ChatConfigCheckButtonTemplate")
	getglobal(tgl:GetName().."Text"):SetText(L["Award later?"])
	tgl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 40)
	tgl.tooltip = L["Check this to loot the items and distribute them later."]
	tgl:SetChecked(awardLater)
	tgl:SetScript("OnClick", function() awardLater = not awardLater; end )
	f.toggle = tgl

	-- Start button
	local b1 = addon:CreateButton(L["Start"], f.content)
	b1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 10, 10)
	b1:SetScript("OnClick", function()
		if loadingItems then
			return addon:Print(L["You can't start a session before all items are loaded!"])
		end
		if awardLater then
			for session in ipairs(ml.lootTable) do ml:Award(session) end
			addon:Print(L["Looted items to award later"])
			ml:EndSession()
		else
			ml:StartSession()
		end
		self:Disable()
	end)
	f.guildBtn = b1

	-- Cancel button
	local b2 = addon:CreateButton(L["Cancel"], f.content)
	b2:SetPoint("LEFT", b1, "RIGHT", 15, 0)
	b2:SetScript("OnClick", function()
		ml.lootTable = {}
		self:Disable()
	end)
	f.guildBtn = b2

	local st = ST:CreateST(self.scrollCols, 5, ROW_HEIGHT, nil, f.content)
	st.frame:SetPoint("TOPLEFT",f,"TOPLEFT",10,-40)
	f:SetWidth(st.frame:GetWidth()+20)
	f.rows = {} -- the row data
	f.st = st
	return f
end
