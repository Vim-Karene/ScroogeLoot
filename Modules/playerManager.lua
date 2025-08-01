-- PlayerManager module for editing PlayerData
local addon = LibStub("AceAddon-3.0"):GetAddon("ScroogeLoot")
local SLPlayerManager = addon:NewModule("SLPlayerManager")
local ST = LibStub("ScrollingTable")
local L = LibStub("AceLocale-3.0"):GetLocale("ScroogeLoot")

local ROW_HEIGHT = 20

function SLPlayerManager:OnInitialize()
    self.scrollCols = {
        {name=L["Name"], width=100, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"name") end},
        {name=L["Class"], width=70, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"class") end},
        {name=L["Raider"], width=60, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellCheck(row,frame,data,cols,rowI,realrow,col,fShow,table,"raiderrank") end},
        {name="SP", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"SP") end},
        {name="DP", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"DP") end},
        {name=L["Attended"], width=60, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"attended") end},
        {name=L["Absent"], width=60, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"absent") end},
        {name="Item1", width=120, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"item1") end},
        {name="Rec1", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellCheck(row,frame,data,cols,rowI,realrow,col,fShow,table,"item1received") end},
        {name="Item2", width=120, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"item2") end},
        {name="Rec2", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellCheck(row,frame,data,cols,rowI,realrow,col,fShow,table,"item2received") end},
        {name="Item3", width=120, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellEdit(row,frame,data,cols,rowI,realrow,col,fShow,table,"item3") end},
        {name="Rec3", width=40, DoCellUpdate=function(row,frame,data,cols,rowI,realrow,col,fShow,table,...) SLPlayerManager:SetCellCheck(row,frame,data,cols,rowI,realrow,col,fShow,table,"item3received") end},
    }

    StaticPopupDialogs["SLPLAYERMANAGER_EXPORT"] = {
        text = L["Player Management"],
        button1 = OKAY,
        hasEditBox = true,
        editBoxWidth = 350,
        OnShow = function(self, data)
            self.editBox:SetText(data)
            self.editBox:HighlightText()
        end,
        timeout = 0,
        whileDead = true,
    }

    StaticPopupDialogs["SLPLAYERMANAGER_IMPORT"] = {
        text = L["Paste XML"],
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = true,
        editBoxWidth = 350,
        OnAccept = function(self, data)
            SLPlayerManager:ImportData(self.editBox:GetText())
        end,
        timeout = 0,
        whileDead = true,
    }
end

function SLPlayerManager:CreateUI(parent)
    if parent.st then return end
    local st = ST:CreateST(self.scrollCols, 10, ROW_HEIGHT, nil, parent)
    st.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    parent.st = st
    parent.rows = {}

    local saveBtn = addon:CreateButton(L["Save"], parent)
    saveBtn:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
    saveBtn:SetScript("OnClick", function() SLPlayerManager:Save(parent) end)

    local exportBtn = addon:CreateButton(L["Export"], parent)
    exportBtn:SetPoint("RIGHT", saveBtn, "LEFT", -10, 0)
    exportBtn:SetScript("OnClick", function() SLPlayerManager:Export() end)

    local importBtn = addon:CreateButton(L["Import"], parent)
    importBtn:SetPoint("RIGHT", exportBtn, "LEFT", -10, 0)
    importBtn:SetScript("OnClick", function() SLPlayerManager:ImportPrompt() end)

    parent.saveBtn = saveBtn
    parent.exportBtn = exportBtn
    parent.importBtn = importBtn
end

function SLPlayerManager:GetFrame()
    if self.frame then return self.frame end
    -- Slightly larger defaults so columns and title fit without overlap
    local f = addon:CreateFrame("SLPlayerManagerFrame", "playerManager", L["Player Management"], 950, 450)
    self:CreateUI(f.content)
    -- Resize to match the scrolling table and keep the title aligned
    f:SetWidth(f.content.st.frame:GetWidth()+20)
    f.title:SetWidth(f:GetWidth())

    -- Add a close button and move existing buttons to make room
    local closeBtn = addon:CreateButton(L["Close"], f.content)
    closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    closeBtn:SetScript("OnClick", function() self:Hide() end)
    f.closeBtn = closeBtn

    local content = f.content
    content.saveBtn:ClearAllPoints()
    content.saveBtn:SetPoint("RIGHT", closeBtn, "LEFT", -10, 0)
    content.exportBtn:ClearAllPoints()
    content.exportBtn:SetPoint("RIGHT", content.saveBtn, "LEFT", -10, 0)
    content.importBtn:ClearAllPoints()
    content.importBtn:SetPoint("RIGHT", content.exportBtn, "LEFT", -10, 0)

    return f
end

function SLPlayerManager:CreateOptionsUI(parent)
    self.optionsFrame = parent
    self:CreateUI(parent)
end

function SLPlayerManager:Show()
    if not next(addon.PlayerData) then
        addon:PopulatePlayerDataFromGroup()
    end
    self.frame = self:GetFrame()
    self:LoadData(self.frame.content)
    self.frame:Show()
    self.frame.content.st:SetData(self.frame.content.rows)
end

function SLPlayerManager:Hide()
    if self.frame then self.frame:Hide() end
end

function SLPlayerManager:LoadData(target)
    local t = target or self.frame.content
    t.rows = {}
    for name,data in pairs(addon.PlayerData) do
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

function SLPlayerManager:SetCellEdit(rowFrame, frame, data, cols, row, realrow, column, fShow, table, field)
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

function SLPlayerManager:SetCellCheck(rowFrame, frame, data, cols, row, realrow, column, fShow, table, field)
    local rowData = data[realrow].data
    if not frame.check then
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetAllPoints(frame)
        cb:SetScript("OnClick", function(self) rowData[field] = self:GetChecked() end)
        frame.check = cb
    end
    frame.check:SetChecked(rowData[field])
end

function SLPlayerManager:Save(target)
    local t = target or self.frame.content
    wipe(addon.PlayerData)
    for _,row in ipairs(t.rows) do
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
        addon.PlayerData[name] = pd
        row.name = name
    end
    addon:BroadcastPlayerData()
    addon:Print(L["Player Management"]..": "..L["Save"].."!")
end

local function Escape(str)
    if not str then return "" end
    str = str:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
    str = str:gsub('"','&quot;')
    return str
end

function SLPlayerManager:Export()
    local xml = "<PlayerData>\n"
    for name,data in pairs(addon.PlayerData) do
        local n = data.name or name
        xml = xml .. string.format('<Player name="%s" class="%s" raider="%s" SP="%s" DP="%s" attended="%s" absent="%s" item1="%s" item1received="%s" item2="%s" item2received="%s" item3="%s" item3received="%s"/>\n',
            Escape(n), Escape(data.class), tostring(data.raiderrank or false), tostring(data.SP or 0), tostring(data.DP or 0), tostring(data.attended or 0), tostring(data.absent or 0), Escape(data.item1), tostring(data.item1received or false), Escape(data.item2), tostring(data.item2received or false), Escape(data.item3), tostring(data.item3received or false))
    end
    xml = xml .. "</PlayerData>"
    StaticPopup_Show("SLPLAYERMANAGER_EXPORT", nil, nil, xml)
end

function SLPlayerManager:ImportPrompt()
    StaticPopup_Show("SLPLAYERMANAGER_IMPORT")
end

function SLPlayerManager:ImportData(text)
    if not addon.isMasterLooter then return end
    local newData = {}
    for entry in string.gmatch(text, "<Player%s+([^/>]+)/?>") do
        local name = entry:match('name="([^"]*)"')
        if name then
            local d = {}
            d.name = name
            d.class = entry:match('class="([^"]*)"') or ""
            d.raiderrank = entry:match('raider="([^"]*)"') == "true"
            d.SP = tonumber(entry:match('SP="([^"]*)"') or 0)
            d.DP = tonumber(entry:match('DP="([^"]*)"') or 0)
            d.attended = tonumber(entry:match('attended="([^"]*)"') or 0)
            d.absent = tonumber(entry:match('absent="([^"]*)"') or 0)
            d.item1 = entry:match('item1="([^"]*)"')
            d.item1received = entry:match('item1received="([^"]*)"') == "true"
            d.item2 = entry:match('item2="([^"]*)"')
            d.item2received = entry:match('item2received="([^"]*)"') == "true"
            d.item3 = entry:match('item3="([^"]*)"')
            d.item3received = entry:match('item3received="([^"]*)"') == "true"
            local total = d.attended + d.absent
            if total > 0 then
                d.attendance = math.floor((d.attended / total) * 100)
            else
                d.attendance = 100
            end
            newData[name] = d
        end
    end
    if next(newData) then
        addon.PlayerData = newData
        if addon.EnsureNameFields then
            addon:EnsureNameFields()
        end
        addon:BroadcastPlayerData()
        if self.frame and self.frame.content then
            self:LoadData(self.frame.content)
            self.frame.content.st:SetData(self.frame.content.rows)
        end
        if self.optionsFrame then
            self:LoadData(self.optionsFrame)
            self.optionsFrame.st:SetData(self.optionsFrame.rows)
        end
    end
end

return SLPlayerManager

