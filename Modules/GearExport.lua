-- Modules/GearExport.lua
-- Export player's equipped gear in WowSims format

local ADDON_NAME, NS = ...
local HooligansLoot = NS.addon
local Utils = NS.Utils

local GearExport = HooligansLoot:NewModule("GearExport")

-- Equipment slot mapping (slotId -> WowSims name)
local SLOT_IDS = {
    { slot = 1,  name = "Head" },
    { slot = 2,  name = "Neck" },
    { slot = 3,  name = "Shoulder" },
    { slot = 5,  name = "Chest" },
    { slot = 6,  name = "Waist" },
    { slot = 7,  name = "Legs" },
    { slot = 8,  name = "Feet" },
    { slot = 9,  name = "Wrist" },
    { slot = 10, name = "Hands" },
    { slot = 15, name = "Back" },
    { slot = 11, name = "Finger1" },
    { slot = 12, name = "Finger2" },
    { slot = 13, name = "Trinket1" },
    { slot = 14, name = "Trinket2" },
    { slot = 16, name = "MainHand" },
    { slot = 17, name = "OffHand" },
    { slot = 18, name = "Ranged" },
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

-- Get enchant ID from item link
function GearExport:GetEnchantID(itemLink)
    if not itemLink then return nil end
    -- Item link format: |cff...|Hitem:itemID:enchantID:...|h[Name]|h|r
    local enchantID = select(2, strsplit(":", itemLink:match("item:([^|]+)")))
    enchantID = tonumber(enchantID)
    return (enchantID and enchantID > 0) and enchantID or nil
end

-- Get all equipped gear
function GearExport:GetEquippedGear()
    local gear = {}

    for _, slotInfo in ipairs(SLOT_IDS) do
        local itemLink = GetInventoryItemLink("player", slotInfo.slot)
        if itemLink then
            local itemID = Utils.GetItemID(itemLink)
            local enchantID = self:GetEnchantID(itemLink)

            if itemID then
                local gearPiece = {
                    id = itemID,
                    slot = slotInfo.name,
                }
                if enchantID then
                    gearPiece.enchant = enchantID
                end
                table.insert(gear, gearPiece)
            end
        end
    end

    return gear
end

-- Export gear in WowSims JSON format
function GearExport:ExportToWowSims()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")

    local className = CLASS_MAP[classFile] or classFile:lower()

    local gear = self:GetEquippedGear()

    -- Build gear array for WowSims format (just id and enchant)
    local gearArray = {}
    for _, piece in ipairs(gear) do
        local gearEntry = { id = piece.id }
        if piece.enchant then
            gearEntry.enchant = piece.enchant
        end
        table.insert(gearArray, gearEntry)
    end

    local exportData = {
        name = playerName,
        realm = realmName,
        class = className,
        level = level,
        gear = gearArray,
    }

    return Utils.ToJSON(exportData), nil
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
    instructions:SetText("Kopiera och klistra in pa voting-sidan (Ctrl+C)")
    instructions:SetTextColor(0.7, 0.7, 0.7)

    tinsert(UISpecialFrames, "HooligansLootGearExportFrame")

    exportFrame = frame
    return frame
end

-- Refresh the export data
function GearExport:RefreshExport()
    if not exportFrame or not exportFrame:IsShown() then return end

    local exportString, err = self:ExportToWowSims()

    if exportString then
        exportFrame.editBox:SetText(exportString)
        exportFrame.editBox:HighlightText()

        local playerName = UnitName("player")
        local _, className = UnitClass("player")
        local gear = self:GetEquippedGear()
        exportFrame.playerInfo:SetText(playerName .. " (" .. (className or "?") .. ") - " .. #gear .. " items")
    else
        exportFrame.editBox:SetText("Error: " .. (err or "Unknown error"))
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
