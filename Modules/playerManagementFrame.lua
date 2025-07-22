-- PlayerManagementFrame module for editing PlayerDB and PlayerData
local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")
local SLPlayerManagementFrame = addon:NewModule("SLPlayerManagementFrame")
local ST = LibStub("ScrollingTable")
local L = LibStub("AceLocale-3.0"):GetLocale("ScroogeLoot")

local ROW_HEIGHT = 20

function SLPlayerManagementFrame:OnInitialize()
    self.scrollCols = {
        {name=L["Name"], width=100, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"name") end},
        {name=L["Class"], width=70, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"class") end},
        {name=L["Raider"], width=60, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellCheck(row,frame,data,cols,rowI,realrow,col,fShow,table,"raiderrank") end},
        {name="SP", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"SP") end},
        {name="DP", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"DP") end},
        {name=L["Attended"], width=60, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"attended") end},
        {name=L["Absent"], width=60, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"absent") end},
        {name="Item1", width=120, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"item1") end},
        {name="Rec1", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellCheck(row,frame,data,cols,rowI,realrow,col,fShow,table,"item1received") end},
        {name="Item2", width=120, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"item2") end},
        {name="Rec2", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellCheck(row,frame,data,cols,rowI,realrow,col,fShow,table,"item2received") end},
        {name="Item3", width=120, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"item3") end},
        {name="Rec3", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManagementFrame:SetCellCheck(row,frame,data,cols,rowI,realrow,col,fShow,table,"item3received") end},
    }
end

function SLPlayerManagementFrame:CreateUI(parent)
    if parent.st then return end
    local st = ST:CreateST(self.scrollCols, 10, ROW_HEIGHT, nil, parent)
    st.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    parent.st = st
    parent.rows = {}

    local saveBtn = addon:CreateButton(L["Save"], parent)
    saveBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
    saveBtn:SetScript("OnClick", function() SLPlayerManagementFrame:Save(parent) end)

    local resetBtn = addon:CreateButton(L["Reset"], parent)
    resetBtn:SetPoint("RIGHT", saveBtn, "LEFT", -10, 0)
    resetBtn:SetScript("OnClick", function() SLPlayerManagementFrame:LoadData(parent); parent.st:SetData(parent.rows) end)

    parent.saveBtn = saveBtn
    parent.resetBtn = resetBtn
end

function SLPlayerManagementFrame:GetFrame()
    if self.frame then return self.frame end
    local f = addon:CreateFrame("SLPlayerManagementFrame", "playermanagement", L["Player Management"], 1000, 350)
    self:CreateUI(f.content)
    f:SetWidth(f.content.st.frame:GetWidth()+120)

    local closeBtn = addon:CreateButton(L["Close"], f.content)
    closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    closeBtn:SetScript("OnClick", function() self:Hide() end)
    f.closeBtn = closeBtn

    -- Reposition save and reset buttons next to the close button
    local content = f.content
    content.saveBtn:ClearAllPoints()
    content.saveBtn:SetPoint("RIGHT", closeBtn, "LEFT", -10, 0)
    content.resetBtn:ClearAllPoints()
    content.resetBtn:SetPoint("RIGHT", content.saveBtn, "LEFT", -10, 0)

    -- Move the title slightly above the frame
    f.title:ClearAllPoints()
    f.title:SetPoint("BOTTOM", f, "TOP", 0, 5)

    return f
end

function SLPlayerManagementFrame:Show()
    self.frame = self:GetFrame()
    self:LoadData(self.frame.content)
    self.frame:Show()
    self.frame.content.st:SetData(self.frame.content.rows)
end

function SLPlayerManagementFrame:Hide()
    if self.frame then self.frame:Hide() end
end

function SLPlayerManagementFrame:LoadData(target)
    local t = target or self.frame.content
    t.rows = {}
    if not PlayerDB then return end
    for name, data in pairs(PlayerDB) do
        local copy = {}
        for k,v in pairs(data) do copy[k] = v end
        copy.name = name
        local row = {name=name, data=copy}
        row.cols = {
            {value=copy.name},
            {value=copy.class},
            {value=copy.raiderrank},
            {value=copy.SP},
            {value=copy.DP},
            {value=copy.attended},
            {value=copy.absent},
            {value=copy.item1},
            {value=copy.item1received},
            {value=copy.item2},
            {value=copy.item2received},
            {value=copy.item3},
            {value=copy.item3received},
        }
        tinsert(t.rows, row)
    end
end

function SLPlayerManagementFrame:SetCellEdit(rowFrame, frame, data, cols, row, realrow, column, fShow, table, field)
    local rowData = data[realrow].data
    if not frame.edit then
        local eb = CreateFrame("EditBox", nil, frame)
        eb:SetAutoFocus(false)
        eb:SetAllPoints(frame)
        eb:SetFontObject(GameFontHighlightSmall)
        eb:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=12, insets={left=2,right=2,top=2,bottom=2}})
        eb:SetBackdropColor(0,0,0,0.5)
        eb:SetBackdropBorderColor(0.3,0.3,0.3,1)
        eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnTextChanged", function(self, user)
            if user then rowData[field] = self:GetText() end
        end)
        frame.edit = eb
    end
    frame.edit:SetText(rowData[field] or "")
end

function SLPlayerManagementFrame:SetCellCheck(rowFrame, frame, data, cols, row, realrow, column, fShow, table, field)
    local rowData = data[realrow].data
    if not frame.check then
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetAllPoints(frame)
        cb:SetScript("OnClick", function(self) rowData[field] = self:GetChecked() end)
        frame.check = cb
    end
    frame.check:SetChecked(rowData[field])
end

function SLPlayerManagementFrame:Save(target)
    local t = target or self.frame.content
    PlayerDB = PlayerDB or {}
    wipe(PlayerDB)
    wipe(addon.PlayerData)
    for _, row in ipairs(t.rows) do
        local d = row.data
        local pd = {
            name = d.name or row.name,
            class = d.class,
            raiderrank = d.raiderrank,
            SP = tonumber(d.SP) or 0,
            DP = tonumber(d.DP) or 0,
            attended = tonumber(d.attended) or 0,
            absent = tonumber(d.absent) or 0,
            item1 = d.item1,
            item1received = not not d.item1received,
            item2 = d.item2,
            item2received = not not d.item2received,
            item3 = d.item3,
            item3received = not not d.item3received,
        }
        local total = pd.attended + pd.absent
        if total > 0 then
            pd.attendance = math.floor((pd.attended / total) * 100)
        else
            pd.attendance = 100
        end
        local name = pd.name
        PlayerDB[name] = pd
        addon.PlayerData[name] = pd
        row.name = name
    end
    addon:BroadcastPlayerData()
    addon:Print(L["Player Management"]..": "..L["Save"].."!")
end

return SLPlayerManagementFrame
