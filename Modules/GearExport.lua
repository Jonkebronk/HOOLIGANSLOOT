-- Modules/GearExport.lua
-- Export player's equipped gear in Sixty Upgrades format

local ADDON_NAME, NS = ...
local HooligansLoot = NS.addon
local Utils = NS.Utils

local GearExport = HooligansLoot:NewModule("GearExport")

-- Equipment slots: WoW slot ID -> Sixty Upgrades slot name (uppercase with underscores)
local SLOT_INFO = {
    { wowSlot = 1,  name = "HEAD" },
    { wowSlot = 2,  name = "NECK" },
    { wowSlot = 3,  name = "SHOULDERS" },
    { wowSlot = 15, name = "BACK" },
    { wowSlot = 5,  name = "CHEST" },
    { wowSlot = 9,  name = "WRISTS" },
    { wowSlot = 10, name = "HANDS" },
    { wowSlot = 6,  name = "WAIST" },
    { wowSlot = 7,  name = "LEGS" },
    { wowSlot = 8,  name = "FEET" },
    { wowSlot = 11, name = "FINGER_1" },
    { wowSlot = 12, name = "FINGER_2" },
    { wowSlot = 13, name = "TRINKET_1" },
    { wowSlot = 14, name = "TRINKET_2" },
    { wowSlot = 16, name = "MAIN_HAND" },
    { wowSlot = 17, name = "OFF_HAND" },
    { wowSlot = 18, name = "RANGED" },
}

-- Race name mapping (localized -> Sixty Upgrades format)
local RACE_MAP = {
    ["Human"] = "HUMAN",
    ["Dwarf"] = "DWARF",
    ["Night Elf"] = "NIGHT_ELF",
    ["Gnome"] = "GNOME",
    ["Draenei"] = "DRAENEI",
    ["Orc"] = "ORC",
    ["Undead"] = "UNDEAD",
    ["Tauren"] = "TAUREN",
    ["Troll"] = "TROLL",
    ["Blood Elf"] = "BLOOD_ELF",
}

-- Tooltip scanner for extracting enchant names (fallback)
local scanTooltip = CreateFrame("GameTooltip", "HooligansGearExportScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Enchant ID to full name mapping
-- Each enchant effect ID is UNIQUE - no duplicates allowed
local ENCHANT_NAMES = {
    -- =============================================
    -- WEAPON ENCHANTS
    -- =============================================
    [241] = "Enchant Weapon - Minor Beastslayer",
    [249] = "Enchant Weapon - Minor Intellect",
    [255] = "Enchant Weapon - Minor Impact",
    [723] = "Enchant Weapon - Intellect",
    [803] = "Enchant Weapon - Fiery Weapon",
    [805] = "Enchant Weapon - Icy Chill",
    [811] = "Enchant Weapon - Unholy Weapon",
    [853] = "Enchant Weapon - Demonslaying",
    [854] = "Enchant Weapon - Elemental Slayer",
    [912] = "Enchant Weapon - Lesser Striking",
    [943] = "Enchant Weapon - Striking",
    [963] = "Enchant Weapon - Greater Striking",
    [1894] = "Enchant Weapon - Icy Chill",
    [1896] = "Enchant Weapon - Lifestealing",
    [1897] = "Enchant Weapon - Unholy Weapon",
    [1898] = "Enchant Weapon - Spellpower",
    [1899] = "Enchant Weapon - Healing Power",
    [1900] = "Enchant Weapon - Crusader",
    [1903] = "Enchant Weapon - Spirit",
    [1904] = "Enchant Weapon - Agility",
    [2443] = "Enchant Weapon - Strength",
    [2504] = "Enchant Weapon - Greater Striking",
    [2505] = "Enchant Weapon - Superior Striking",
    [2563] = "Enchant Weapon - Mighty Intellect",
    [2564] = "Enchant Weapon - Mighty Spirit",
    [2567] = "Enchant Weapon - Mighty Spellpower",
    [2568] = "Enchant Weapon - Agility",
    [2646] = "Enchant 2H Weapon - Major Agility",
    [2666] = "Enchant Weapon - Major Striking",
    [2667] = "Enchant Weapon - Savagery",
    [2668] = "Enchant Weapon - Potency",
    [2669] = "Enchant Weapon - Major Spellpower",
    [2670] = "Enchant Weapon - Major Intellect",
    [2671] = "Enchant Weapon - Sunfire",
    [2672] = "Enchant Weapon - Soulfrost",
    [2673] = "Enchant Weapon - Mongoose",
    [2674] = "Enchant Weapon - Spellsurge",
    [2675] = "Enchant Weapon - Battlemaster",
    [2676] = "Enchant 2H Weapon - Savagery",
    [2723] = "Enchant Weapon - Executioner",
    [3222] = "Enchant Weapon - Greater Agility",
    [3225] = "Enchant Weapon - Executioner",
    [3239] = "Enchant Weapon - Icebane",
    [3241] = "Enchant Weapon - Lifeward",
    [3243] = "Enchant Weapon - Giant Slayer",
    [3247] = "Enchant Weapon - Berserking",
    [3251] = "Enchant Weapon - Black Magic",
    [3253] = "Enchant Weapon - Accuracy",
    [3789] = "Enchant Weapon - Blade Ward",
    [3790] = "Enchant Weapon - Blood Draining",
    [3833] = "Enchant Weapon - Superior Potency",
    [3834] = "Enchant Weapon - Titanguard",
    [3844] = "Enchant Weapon - Mighty Spirit",
    [3855] = "Enchant Weapon - Spellpower",

    -- =============================================
    -- HEAD ENCHANTS (Arcanums / Glyphs)
    -- =============================================
    [1503] = "Lesser Arcanum of Constitution",
    [1504] = "Lesser Arcanum of Resilience",
    [1505] = "Lesser Arcanum of Rumination",
    [1506] = "Lesser Arcanum of Voracity",
    [1507] = "Arcanum of Rapidity",
    [1508] = "Arcanum of Focus",
    [1509] = "Arcanum of Protection",
    [1510] = "Arcanum of Voracity",
    [2543] = "Arcanum of Voracity (Strength)",
    [2544] = "Arcanum of Voracity (Agility)",
    [2545] = "Arcanum of Voracity (Stamina)",
    [2583] = "Arcanum of Voracity (Intellect)",
    [2584] = "Presence of Might",
    [2585] = "Syncretist's Sigil",
    [2586] = "Death's Embrace",
    [2587] = "Falcon's Call",
    [2588] = "Vodouisant's Vigilant Embrace",
    [2589] = "Presence of Sight",
    [2590] = "Hoodoo Hex",
    [2591] = "Animist's Caress",
    [2999] = "Glyph of the Defender",
    [3001] = "Glyph of Renewal",
    [3002] = "Glyph of Power",
    [3003] = "Glyph of Ferocity",
    [3004] = "Glyph of the Outcast",
    [3005] = "Glyph of Fire Warding",
    [3006] = "Glyph of the Gladiator",
    [3007] = "Glyph of Chromatic Warding",
    [3008] = "Glyph of Shadow Warding",
    [3009] = "Glyph of Nature Warding",
    [3010] = "Cobrahide Leg Armor",
    [3011] = "Nethercobra Leg Armor",
    [3012] = "Clefthide Leg Armor",
    [3013] = "Nethercleft Leg Armor",
    [3096] = "Glyph of Arcane Warding",
    [3097] = "Glyph of Fire Warding",
    [3098] = "Glyph of Nature Warding",
    [3099] = "Glyph of Frost Warding",
    [3100] = "Glyph of Shadow Warding",

    -- =============================================
    -- SHOULDER ENCHANTS
    -- =============================================
    [2604] = "Zandalar Signet of Mojo",
    [2605] = "Zandalar Signet of Might",
    [2606] = "Zandalar Signet of Serenity",
    [2715] = "Fortitude of the Scourge",
    [2716] = "Power of the Scourge",
    [2717] = "Resilience of the Scourge",
    [2721] = "Might of the Scourge",
    [2977] = "Inscription of Warding",
    [2978] = "Greater Inscription of Faith",
    [2979] = "Greater Inscription of Vengeance",
    [2980] = "Greater Inscription of Warding",
    [2981] = "Inscription of Vengeance",
    [2982] = "Greater Inscription of Discipline",
    [2983] = "Inscription of the Blade",
    [2986] = "Greater Inscription of the Blade",
    [2987] = "Inscription of the Knight",
    [2990] = "Greater Inscription of the Knight",
    [2991] = "Greater Inscription of the Oracle",
    [2995] = "Inscription of the Oracle",
    [2997] = "Inscription of Discipline",
    [2998] = "Inscription of Faith",

    -- =============================================
    -- BACK / CLOAK ENCHANTS
    -- =============================================
    [247] = "Enchant Cloak - Lesser Agility",
    [249] = "Enchant Cloak - Lesser Protection",
    [256] = "Enchant Cloak - Minor Resistance",
    [368] = "Enchant Cloak - Minor Agility",
    [783] = "Enchant Cloak - Minor Agility",
    [848] = "Enchant Cloak - Defense",
    [849] = "Enchant Cloak - Lesser Agility",
    [884] = "Enchant Cloak - Fire Resistance",
    [903] = "Enchant Cloak - Lesser Fire Resistance",
    [910] = "Enchant Cloak - Superior Defense",
    [1257] = "Enchant Cloak - Greater Defense",
    [1354] = "Enchant Cloak - Stealth",
    [1441] = "Enchant Cloak - Greater Resistance",
    [1889] = "Enchant Cloak - Stealth",
    [2463] = "Enchant Cloak - Fire Resistance",
    [2619] = "Enchant Cloak - Greater Fire Resistance",
    [2620] = "Enchant Cloak - Greater Nature Resistance",
    [2621] = "Enchant Cloak - Greater Agility",
    [2622] = "Enchant Cloak - Subtlety",
    [2662] = "Enchant Cloak - Major Armor",
    [2664] = "Enchant Cloak - Major Resistance",
    [2938] = "Enchant Cloak - Spell Penetration",

    -- =============================================
    -- CHEST ENCHANTS
    -- =============================================
    [41] = "Enchant Chest - Minor Health",
    [44] = "Enchant Chest - Minor Mana",
    [63] = "Enchant Chest - Minor Stats",
    [242] = "Enchant Chest - Lesser Health",
    [246] = "Enchant Chest - Lesser Mana",
    [254] = "Enchant Chest - Minor Absorption",
    [843] = "Enchant Chest - Greater Health",
    [847] = "Enchant Chest - Greater Mana",
    [850] = "Enchant Chest - Health",
    [857] = "Enchant Chest - Superior Health",
    [866] = "Enchant Chest - Lesser Stats",
    [908] = "Enchant Chest - Stats",
    [928] = "Enchant Chest - Stats",
    [1891] = "Enchant Chest - Greater Stats",
    [1892] = "Enchant Chest - Greater Stats",
    [1893] = "Enchant Chest - Major Mana",
    [1950] = "Enchant Chest - Major Health",
    [2659] = "Enchant Chest - Exceptional Health",
    [2660] = "Enchant Chest - Exceptional Mana",
    [2661] = "Enchant Chest - Exceptional Stats",
    [2933] = "Enchant Chest - Major Resilience",
    [3150] = "Enchant Chest - Exceptional Stats",
    [3233] = "Enchant Chest - Major Spirit",
    [3245] = "Enchant Chest - Defense",

    -- =============================================
    -- WRIST / BRACER ENCHANTS
    -- =============================================
    [66] = "Enchant Bracer - Minor Stamina",
    [243] = "Enchant Bracer - Minor Strength",
    [248] = "Enchant Bracer - Minor Deflection",
    [255] = "Enchant Bracer - Lesser Strength",
    [369] = "Enchant Bracer - Assault",
    [723] = "Enchant Bracer - Minor Intellect",
    [724] = "Enchant Bracer - Minor Intellect",
    [823] = "Enchant Bracer - Stamina",
    [851] = "Enchant Bracer - Spirit",
    [852] = "Enchant Bracer - Strength",
    [856] = "Enchant Bracer - Lesser Intellect",
    [905] = "Enchant Bracer - Greater Stamina",
    [907] = "Enchant Bracer - Greater Strength",
    [923] = "Enchant Bracer - Deflection",
    [924] = "Enchant Bracer - Intellect",
    [927] = "Enchant Bracer - Greater Intellect",
    [929] = "Enchant Bracer - Superior Stamina",
    [931] = "Enchant Bracer - Superior Strength",
    [1147] = "Enchant Bracer - Superior Stamina",
    [1593] = "Enchant Bracer - Mana Regeneration",
    [1600] = "Enchant Bracer - Healing Power",
    [1886] = "Enchant Bracer - Superior Stamina",
    [2565] = "Enchant Bracer - Brawn",
    [2617] = "Enchant Bracer - Superior Healing",
    [2647] = "Enchant Bracer - Brawn",
    [2648] = "Enchant Bracer - Fortitude",
    [2649] = "Enchant Bracer - Spellpower",
    [2650] = "Enchant Bracer - Major Defense",
    [2679] = "Enchant Bracer - Stats",

    -- =============================================
    -- HANDS / GLOVES ENCHANTS
    -- =============================================
    [684] = "Enchant Gloves - Superior Agility",
    [845] = "Enchant Gloves - Agility",
    [846] = "Enchant Gloves - Strength",
    [904] = "Enchant Gloves - Greater Strength",
    [909] = "Enchant Gloves - Greater Agility",
    [927] = "Enchant Gloves - Riding Skill",
    [930] = "Enchant Gloves - Mining",
    [931] = "Enchant Gloves - Herbalism",
    [1594] = "Enchant Gloves - Assault",
    [2322] = "Enchant Gloves - Major Strength",
    [2564] = "Enchant Gloves - Frost Power",
    [2613] = "Enchant Gloves - Threat",
    [2614] = "Enchant Gloves - Fire Power",
    [2615] = "Enchant Gloves - Shadow Power",
    [2616] = "Enchant Gloves - Healing Power",
    [2934] = "Enchant Gloves - Blasting",
    [2935] = "Enchant Gloves - Major Spellpower",
    [2936] = "Enchant Gloves - Spell Strike",
    [2937] = "Enchant Gloves - Major Healing",

    -- =============================================
    -- LEGS ENCHANTS (Spellthreads / Armor Kits)
    -- =============================================
    [2746] = "Mystic Spellthread",
    [2747] = "Runic Spellthread",
    [2748] = "Silver Spellthread",
    [2749] = "Golden Spellthread",

    -- =============================================
    -- FEET / BOOTS ENCHANTS
    -- =============================================
    [250] = "Enchant Boots - Minor Speed",
    [724] = "Enchant Boots - Lesser Agility",
    [851] = "Enchant Boots - Stamina",
    [852] = "Enchant Boots - Agility",
    [904] = "Enchant Boots - Greater Agility",
    [911] = "Enchant Boots - Minor Speed",
    [929] = "Enchant Boots - Spirit",
    [1887] = "Enchant Boots - Run Speed",
    [2649] = "Enchant Boots - Dexterity",
    [2656] = "Enchant Boots - Vitality",
    [2657] = "Enchant Boots - Fortitude",
    [2658] = "Enchant Boots - Surefooted",
    [2939] = "Enchant Boots - Cat's Swiftness",
    [2940] = "Enchant Boots - Boar's Speed",

    -- =============================================
    -- RING ENCHANTS (Enchanters only)
    -- =============================================
    [2928] = "Enchant Ring - Spellpower",
    [2929] = "Enchant Ring - Striking",
    [2930] = "Enchant Ring - Healing Power",
    [2931] = "Enchant Ring - Stats",

    -- =============================================
    -- SHIELD ENCHANTS
    -- =============================================
    [848] = "Enchant Shield - Lesser Block",
    [851] = "Enchant Shield - Stamina",
    [864] = "Enchant Shield - Lesser Stamina",
    [904] = "Enchant Shield - Greater Stamina",
    [926] = "Enchant Shield - Frost Resistance",
    [929] = "Enchant Shield - Greater Spirit",
    [1071] = "Enchant Shield - Greater Stamina",
    [1888] = "Enchant Shield - Superior Stamina",
    [1890] = "Enchant Shield - Vitality",
    [2653] = "Enchant Shield - Parry",
    [2654] = "Enchant Shield - Resilience",
    [2655] = "Enchant Shield - Intellect",
    [3229] = "Enchant Shield - Defense",

    -- =============================================
    -- RANGED WEAPON ENCHANTS (Scopes)
    -- =============================================
    [30] = "Crude Scope",
    [32] = "Standard Scope",
    [33] = "Accurate Scope",
    [663] = "Deadly Scope",
    [664] = "Sniper Scope",
    [2523] = "Stabilized Eternium Scope",
    [2724] = "Khorium Scope",
}

-- Export dialog frame
local exportFrame = nil

function GearExport:OnEnable()
    -- Nothing to do on enable
end

-- Parse item link to extract itemID, enchantID, and gem IDs
-- Classic/TBC item link format: item:ID:enchant:gem1:gem2:gem3:gem4:suffix:unique
function GearExport:ParseItemLink(itemLink)
    if not itemLink then return nil end

    local itemString = itemLink:match("item:([%-?%d:]+)")
    if not itemString then return nil end

    local parts = {strsplit(":", itemString)}

    return {
        itemID = tonumber(parts[1]) or 0,
        enchantID = tonumber(parts[2]) or 0,
        gem1 = tonumber(parts[3]) or 0,
        gem2 = tonumber(parts[4]) or 0,
        gem3 = tonumber(parts[5]) or 0,
        gem4 = tonumber(parts[6]) or 0,
    }
end

-- Get enchant name from item link by scanning tooltip
-- Enchants appear as green text in the tooltip
function GearExport:GetEnchantFromTooltip(itemLink)
    if not itemLink then return nil end

    scanTooltip:ClearLines()
    scanTooltip:SetHyperlink(itemLink)

    -- Scan tooltip lines for enchant (green text)
    for i = 2, scanTooltip:NumLines() do
        local line = _G["HooligansGearExportScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            local r, g, b = line:GetTextColor()

            -- Green text (enchants are green: r≈0, g≈1, b≈0)
            if text and g > 0.9 and r < 0.2 and b < 0.2 then
                -- Filter out socket bonuses and other green text
                if not text:match("^Socket Bonus:") and
                   not text:match("^Equip:") and
                   not text:match("^Use:") and
                   not text:match("^Requires") and
                   not text:match("^Classes:") and
                   not text:match("^Durability") and
                   not text:match("^<") then
                    return text  -- This is the enchant name
                end
            end
        end
    end

    return nil
end

-- Get enchant info - uses lookup table first, falls back to tooltip scanning
function GearExport:GetEnchantInfo(enchantID, itemLink)
    if not enchantID or enchantID == 0 then return nil end

    -- First try lookup table for full enchant name
    local enchantName = ENCHANT_NAMES[enchantID]

    -- DEBUG: Print missing enchant IDs so we can add them to the table
    if not enchantName then
        local tooltipName = self:GetEnchantFromTooltip(itemLink)
        print("|cffff9900[HooligansLoot]|r Missing enchant ID: |cff00ff00" .. enchantID .. "|r = |cffffffff" .. (tooltipName or "unknown") .. "|r")
        enchantName = tooltipName
    end

    if enchantName then
        return {
            name = enchantName,
            id = enchantID,
        }
    end

    -- Fallback if tooltip scanning fails
    return {
        name = "Enchant",
        id = enchantID,
    }
end

-- Get gem info from gem item ID
function GearExport:GetGemInfo(gemID)
    if not gemID or gemID == 0 then return nil end

    local name = GetItemInfo(gemID)

    return {
        id = gemID,
        name = name or "Gem",
    }
end

-- Get all equipped gear as items array with full info (Sixty Upgrades format)
function GearExport:GetEquippedGear()
    local items = {}

    for _, slotInfo in ipairs(SLOT_INFO) do
        local itemLink = GetInventoryItemLink("player", slotInfo.wowSlot)

        if itemLink then
            local parsed = self:ParseItemLink(itemLink)
            if parsed and parsed.itemID > 0 then
                local itemName = GetItemInfo(parsed.itemID) or Utils.GetItemName(itemLink) or "Unknown"

                local item = {
                    name = itemName,
                    id = parsed.itemID,
                    slot = slotInfo.name,
                    gems = {},
                }

                -- Add enchant if present (pass itemLink for tooltip scanning)
                local enchant = self:GetEnchantInfo(parsed.enchantID, itemLink)
                if enchant then
                    item.enchant = enchant
                end

                -- Add gems if present
                for _, gemID in ipairs({parsed.gem1, parsed.gem2, parsed.gem3, parsed.gem4}) do
                    local gem = self:GetGemInfo(gemID)
                    if gem then
                        table.insert(item.gems, gem)
                    end
                end

                -- Remove empty gems array for cleaner output
                if #item.gems == 0 then
                    item.gems = nil
                end

                table.insert(items, item)
            end
        end
    end

    return items
end

-- Export gear in Sixty Upgrades JSON format
function GearExport:ExportToJSON()
    local playerName = UnitName("player")
    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")
    local race = UnitRace("player")
    local faction = UnitFactionGroup("player")

    local items = self:GetEquippedGear()

    local exportData = {
        character = {
            name = playerName,
            level = level,
            gameClass = classFile,  -- Already uppercase (e.g., "WARRIOR")
            race = RACE_MAP[race] or race:upper():gsub(" ", "_"),
            faction = faction:upper(),
        },
        items = items,
    }

    return Utils.ToJSON(exportData), #items
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
