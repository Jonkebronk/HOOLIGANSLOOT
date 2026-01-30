-- Modules/Export.lua
-- Export session data to JSON/CSV for website voting

local ADDON_NAME, NS = ...
local HooligansLoot = NS.addon
local Utils = NS.Utils

local Export = HooligansLoot:NewModule("Export")

-- Export dialog frame
local exportFrame = nil

function Export:OnEnable()
    -- Nothing to do on enable
end

function Export:GetExportData(sessionId)
    local SessionManager = HooligansLoot:GetModule("SessionManager")
    local session = sessionId and SessionManager:GetSession(sessionId) or SessionManager:GetCurrentSession()

    if not session then
        return nil, "No session found"
    end

    local exportData = {
        session = session.name,
        sessionId = session.id,
        guild = "HOOLIGANS",
        exported = Utils.FormatISO8601(time()),
        created = Utils.FormatISO8601(session.created),
        status = session.status,
        items = {},
    }

    for _, item in ipairs(session.items) do
        local itemExport = {
            id = item.id,
            name = item.name,
            link = item.link,
            boss = item.boss,
            quality = item.quality,
            timestamp = item.timestamp,
            tradeable = item.tradeable,
            tradeExpires = item.tradeExpires,
            guid = item.guid,
        }

        -- Include award info if available
        local award = session.awards[item.guid]
        if award then
            itemExport.winner = award.winner
            itemExport.awarded = award.awarded
        end

        table.insert(exportData.items, itemExport)
    end

    return exportData, nil
end

-- Get export data formatted for HOOLIGANS platform import
function Export:GetPlatformExportData(sessionId)
    local SessionManager = HooligansLoot:GetModule("SessionManager")
    local session = sessionId and SessionManager:GetSession(sessionId) or SessionManager:GetCurrentSession()

    if not session then
        return nil, "No session found"
    end

    -- Format for HOOLIGANS platform
    local exportData = {
        teamId = "", -- User fills this in on platform
        sessionId = session.id,
        sessionName = session.name,
        created = session.created,
        items = {},
    }

    for _, item in ipairs(session.items) do
        -- Get item level if available
        local ilvl = 0
        if item.id then
            local _, _, _, itemLevel = GetItemInfo(item.id)
            ilvl = itemLevel or 0
        end

        local itemExport = {
            guid = item.guid,
            itemName = item.name or "Unknown",
            wowheadId = item.id,
            link = item.link,
            quality = item.quality or 4,
            ilvl = ilvl,
            boss = item.boss,
            timestamp = item.timestamp,
        }

        -- Include award if already set (from previous import)
        local award = session.awards[item.guid]
        if award then
            itemExport.winner = award.winner
            itemExport.winnerClass = award.class
        end

        table.insert(exportData.items, itemExport)
    end

    return exportData, nil
end

function Export:ExportToJSON(sessionId)
    local data, err = self:GetPlatformExportData(sessionId)
    if not data then
        return nil, err
    end

    return Utils.ToJSON(data), nil
end

function Export:ExportToJSONFull(sessionId)
    local data, err = self:GetExportData(sessionId)
    if not data then
        return nil, err
    end

    return Utils.ToJSON(data), nil
end

-- Helper to escape CSV fields
local function csvEscape(value)
    if value == nil then return "" end
    value = tostring(value)
    if value:find('[,"\n]') then
        return '"' .. value:gsub('"', '""') .. '"'
    end
    return value
end

function Export:ExportToCSV(sessionId)
    local data, err = self:GetExportData(sessionId)
    if not data then
        return nil, err
    end

    local lines = {}

    -- Header row
    table.insert(lines, "player,date,time,id,item,itemID,itemString,response,votes,class,instance,boss,difficultyID,mapID,groupSize,gear1,gear2,responseID,isAwardReason,subType,equipLoc,note,owner")

    for _, item in ipairs(data.items) do
        local dateStr = item.timestamp and date("%d/%m/%y", item.timestamp) or ""
        local timeStr = item.timestamp and date("%H:%M:%S", item.timestamp) or ""

        local itemLink = item.link or ""
        if item.id and (not itemLink or itemLink == "") then
            local qualityColor = "ffa335ee"
            if item.quality == 5 then
                qualityColor = "ffff8000"
            elseif item.quality == 3 then
                qualityColor = "ff0070dd"
            elseif item.quality == 2 then
                qualityColor = "ff1eff00"
            end
            itemLink = "|c" .. qualityColor .. "|Hitem:" .. item.id .. "::::::::70:::::|h[" .. (item.name or "Unknown") .. "]|h|r"
        end

        local itemString = ""
        if item.id then
            itemString = "item:" .. item.id .. ":0:0:0:0:0:0:0"
        end

        local fields = {
            csvEscape(item.winner or ""),
            csvEscape(dateStr),
            csvEscape(timeStr),
            "",
            csvEscape(itemLink),
            csvEscape(item.id or ""),
            csvEscape(itemString),
            csvEscape(item.winner and "awarded" or "awaiting"),
            "0",
            "",
            csvEscape(data.session or ""),
            csvEscape(item.boss or ""),
            "",
            "",
            "25",
            "",
            "",
            csvEscape(item.winner and "1" or ""),
            "false",
            "",
            "",
            "",
            "",
        }

        table.insert(lines, table.concat(fields, ","))
    end

    return table.concat(lines, "\n"), nil
end

function Export:GetExportString(sessionId, format)
    format = format or HooligansLoot.db.profile.settings.exportFormat

    if format == "csv" then
        return self:ExportToCSV(sessionId)
    else
        return self:ExportToJSON(sessionId)
    end
end

function Export:CreateExportFrame()
    if exportFrame then return exportFrame end

    local frame = CreateFrame("Frame", "HooligansLootExportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(450, 350)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 20,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.1, 0.95)
    frame:SetBackdropBorderColor(0.6, 0.5, 0.3, 1)

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -15)
    frame.title:SetText(HooligansLoot.colors.primary .. "HOOLIGANS|r Loot - Export")

    -- Close button
    local closeX = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeX:SetPoint("TOPRIGHT", -2, -2)
    closeX:SetScript("OnClick", function() frame:Hide() end)

    -- Session info
    frame.sessionInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.sessionInfo:SetPoint("TOP", frame.title, "BOTTOM", 0, -5)
    frame.sessionInfo:SetTextColor(0.7, 0.7, 0.7)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "HooligansLootExportScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -55)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)

    -- Edit box
    local editBox = CreateFrame("EditBox", "HooligansLootExportEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scrollFrame:GetWidth())
    editBox:SetAutoFocus(true)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function() frame:Hide() end)

    scrollFrame:SetScrollChild(editBox)
    frame.editBox = editBox

    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    instructions:SetPoint("BOTTOMLEFT", 15, 15)
    instructions:SetText("Press Ctrl+C to copy")
    instructions:SetTextColor(0.7, 0.7, 0.7)

    tinsert(UISpecialFrames, "HooligansLootExportFrame")

    exportFrame = frame
    return frame
end

function Export:RefreshExport()
    if not exportFrame or not exportFrame:IsShown() then return end

    local exportString, err = self:ExportToJSON()

    if exportString then
        exportFrame.editBox:SetText(exportString)
        exportFrame.editBox:HighlightText()

        local session = HooligansLoot:GetModule("SessionManager"):GetCurrentSession()
        if session then
            exportFrame.sessionInfo:SetText(session.name .. " (" .. #session.items .. " items)")
        end
    else
        exportFrame.editBox:SetText("Error: " .. (err or "Unknown error"))
    end
end

function Export:ShowDialog(sessionId)
    local frame = self:CreateExportFrame()

    local SessionManager = HooligansLoot:GetModule("SessionManager")
    local session = sessionId and SessionManager:GetSession(sessionId) or SessionManager:GetCurrentSession()

    if not session then
        HooligansLoot:Print("No session to export. Create one with /hl start")
        return
    end

    if #session.items == 0 then
        HooligansLoot:Print("Session has no items to export.")
        return
    end

    frame:Show()
    self:RefreshExport()
end

function Export:HideDialog()
    if exportFrame then
        exportFrame:Hide()
    end
end
