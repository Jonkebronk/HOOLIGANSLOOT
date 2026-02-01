-- Modules/GearExport.lua
-- Export player's equipped gear in WowSims format

local ADDON_NAME, NS = ...
local HooligansLoot = NS.addon
local Utils = NS.Utils

local GearExport = HooligansLoot:NewModule("GearExport")

-- Equipment slots: WoW slot ID -> slot name (capitalized for platform)
local SLOT_INFO = {
    { wowSlot = 1,  name = "Head" },
    { wowSlot = 2,  name = "Neck" },
    { wowSlot = 3,  name = "Shoulder" },
    { wowSlot = 15, name = "Back" },
    { wowSlot = 5,  name = "Chest" },
    { wowSlot = 9,  name = "Wrist" },
    { wowSlot = 10, name = "Hands" },
    { wowSlot = 6,  name = "Waist" },
    { wowSlot = 7,  name = "Legs" },
    { wowSlot = 8,  name = "Feet" },
    { wowSlot = 11, name = "Finger1" },
    { wowSlot = 12, name = "Finger2" },
    { wowSlot = 13, name = "Trinket1" },
    { wowSlot = 14, name = "Trinket2" },
    { wowSlot = 16, name = "MainHand" },
    { wowSlot = 17, name = "OffHand" },
    { wowSlot = 18, name = "Ranged" },
}

-- Class name mapping (localized -> lowercase English)
local CLASS_MAP = {
    ["Warrior"] = "warrior",
    ["Paladin"] = "paladin",
    ["Hunter"] = "hunter",
    ["Rogue"] = "rogue",
    ["Priest"] = "priest",
    ["Shaman"] = "shaman",
    ["Mage"] = "mage",
    ["Warlock"] = "warlock",
    ["Druid"] = "druid",
    ["Death Knight"] = "deathknight",
    -- File names (uppercase)
    ["WARRIOR"] = "warrior",
    ["PALADIN"] = "paladin",
    ["HUNTER"] = "hunter",
    ["ROGUE"] = "rogue",
    ["PRIEST"] = "priest",
    ["SHAMAN"] = "shaman",
    ["MAGE"] = "mage",
    ["WARLOCK"] = "warlock",
    ["DRUID"] = "druid",
    ["DEATHKNIGHT"] = "deathknight",
}

-- Export dialog frame
local exportFrame = nil

function GearExport:OnEnable()
    -- Nothing to do on enable
end

-- Get all equipped gear: slot name -> item ID directly
function GearExport:GetEquippedGear()
    local gear = {}
    local itemCount = 0

    for _, slotInfo in ipairs(SLOT_INFO) do
        local itemLink = GetInventoryItemLink("player", slotInfo.wowSlot)

        if itemLink then
            local itemID = Utils.GetItemID(itemLink)
            if itemID then
                gear[slotInfo.name] = itemID  -- Direct: "Head" = 22478
                itemCount = itemCount + 1
            end
        end
    end

    return gear, itemCount
end

-- Export gear in simple JSON format (flat structure)
function GearExport:ExportToJSON()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")

    local className = CLASS_MAP[classFile] or classFile:lower()

    local gear, itemCount = self:GetEquippedGear()

    -- Build flat export with player info + slots at root level
    local exportData = {
        name = playerName,
        realm = realmName,
        class = className,
        level = level,
    }

    -- Add gear slots directly to root
    for slotName, itemID in pairs(gear) do
        exportData[slotName] = itemID
    end

    return Utils.ToJSON(exportData), itemCount
end

-- Create the export dialog frame
function GearExport:CreateExportFrame()
    if exportFrame then return exportFrame end

    local frame = CreateFrame("Frame", "HooligansLootGearExportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(450, 400)
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
    frame.title:SetText(HooligansLoot.colors.primary .. "HOOLIGANS|r Loot - Gear Export")

    -- Close button
    local closeX = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeX:SetPoint("TOPRIGHT", -2, -2)
    closeX:SetScript("OnClick", function() frame:Hide() end)

    -- Player info
    frame.playerInfo = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.playerInfo:SetPoint("TOP", frame.title, "BOTTOM", 0, -5)
    frame.playerInfo:SetTextColor(0.7, 0.7, 0.7)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "HooligansLootGearExportScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -55)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 45)

    -- Edit box
    local editBox = CreateFrame("EditBox", "HooligansLootGearExportEditBox", scrollFrame)
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

    tinsert(UISpecialFrames, "HooligansLootGearExportFrame")

    exportFrame = frame
    return frame
end

-- Refresh the export data
function GearExport:RefreshExport()
    if not exportFrame or not exportFrame:IsShown() then return end

    local exportString, itemCount = self:ExportToJSON()

    if exportString then
        exportFrame.editBox:SetText(exportString)
        exportFrame.editBox:HighlightText()

        local playerName = UnitName("player")
        local _, className = UnitClass("player")
        exportFrame.playerInfo:SetText(playerName .. " (" .. (className or "?") .. ") - " .. itemCount .. " items")
    else
        exportFrame.editBox:SetText("Error: Unknown error")
    end
end

-- Show the gear export dialog
function GearExport:ShowDialog()
    local frame = self:CreateExportFrame()
    frame:Show()
    self:RefreshExport()
end

-- Hide the dialog
function GearExport:HideDialog()
    if exportFrame then
        exportFrame:Hide()
    end
end
