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

-- Enchant lookup table: enchantEffectID -> { name, spellId }
-- The enchant ID in item links is NOT a spell ID, so GetSpellInfo() won't work
local ENCHANT_DATA = {
    -- ============================================
    -- HEAD / HELM ENCHANTS
    -- ============================================
    -- Classic Head/Leg enchants (Librams/Arcanum)
    [1503] = { name = "Arcanum of Rapidity", spellId = 22844 },
    [1504] = { name = "Arcanum of Focus", spellId = 22846 },
    [1505] = { name = "Arcanum of Protection", spellId = 22847 },
    [1506] = { name = "Lesser Arcanum of Voracity", spellId = 22840 },
    [1507] = { name = "Lesser Arcanum of Rumination", spellId = 22841 },
    [1508] = { name = "Lesser Arcanum of Tenacity", spellId = 22842 },
    [1509] = { name = "Lesser Arcanum of Constitution", spellId = 22843 },
    [1510] = { name = "Arcanum of Voracity", spellId = 22870 },
    [2543] = { name = "Arcanum of Voracity", spellId = 24149 },
    [2544] = { name = "Arcanum of Voracity", spellId = 24160 },
    [2545] = { name = "Arcanum of Voracity", spellId = 24161 },
    [2583] = { name = "Arcanum of Voracity", spellId = 24162 },
    [2584] = { name = "Presence of Might", spellId = 24164 },
    [2585] = { name = "Syncretist's Sigil", spellId = 24165 },
    [2586] = { name = "Death's Embrace", spellId = 24167 },
    [2587] = { name = "Falcon's Call", spellId = 24168 },
    [2588] = { name = "Vodouisant's Vigilant Embrace", spellId = 24420 },
    [2589] = { name = "Presence of Sight", spellId = 24421 },
    [2590] = { name = "Hoodoo Hex", spellId = 24163 },
    [2591] = { name = "Animist's Caress", spellId = 24169 },
    -- TBC Head enchants (Glyphs)
    [2999] = { name = "Glyph of the Defender", spellId = 35443 },
    [3001] = { name = "Glyph of Renewal", spellId = 35445 },
    [3002] = { name = "Glyph of Power", spellId = 35447 },
    [3003] = { name = "Glyph of Ferocity", spellId = 35452 },
    [3004] = { name = "Glyph of the Outcast", spellId = 35458 },
    [3006] = { name = "Glyph of the Gladiator", spellId = 35460 },
    [3007] = { name = "Glyph of Chromatic Warding", spellId = 35455 },
    [3008] = { name = "Glyph of Shadow Warding", spellId = 35456 },
    [3009] = { name = "Glyph of Nature Warding", spellId = 35457 },
    [3005] = { name = "Glyph of Fire Warding", spellId = 35453 },
    [3096] = { name = "Glyph of Arcane Warding", spellId = 37888 },
    [3097] = { name = "Glyph of Fire Warding", spellId = 37889 },
    [3098] = { name = "Glyph of Nature Warding", spellId = 37891 },
    [3099] = { name = "Glyph of Frost Warding", spellId = 37893 },
    [3100] = { name = "Glyph of Shadow Warding", spellId = 37894 },

    -- ============================================
    -- SHOULDER ENCHANTS
    -- ============================================
    -- Classic Shoulder enchants (ZG)
    [2604] = { name = "Zandalar Signet of Mojo", spellId = 24421 },
    [2605] = { name = "Zandalar Signet of Might", spellId = 24422 },
    [2606] = { name = "Zandalar Signet of Serenity", spellId = 24423 },
    -- Classic Shoulder enchants (Naxx)
    [2715] = { name = "Fortitude of the Scourge", spellId = 29467 },
    [2716] = { name = "Power of the Scourge", spellId = 29475 },
    [2717] = { name = "Resilience of the Scourge", spellId = 29480 },
    [2721] = { name = "Might of the Scourge", spellId = 29483 },
    -- TBC Shoulder enchants (Aldor)
    [2977] = { name = "Inscription of Warding", spellId = 35400 },
    [2978] = { name = "Greater Inscription of Faith", spellId = 35402 },
    [2979] = { name = "Greater Inscription of Vengeance", spellId = 35403 },
    [2980] = { name = "Greater Inscription of Warding", spellId = 35404 },
    [2981] = { name = "Inscription of Vengeance", spellId = 35405 },
    [2982] = { name = "Greater Inscription of Discipline", spellId = 35406 },
    [2997] = { name = "Inscription of Discipline", spellId = 35437 },
    [2998] = { name = "Inscription of Faith", spellId = 35438 },
    -- TBC Shoulder enchants (Scryer)
    [2983] = { name = "Inscription of the Blade", spellId = 35409 },
    [2986] = { name = "Greater Inscription of the Blade", spellId = 35417 },
    [2987] = { name = "Inscription of the Knight", spellId = 35420 },
    [2990] = { name = "Greater Inscription of the Knight", spellId = 35433 },
    [2991] = { name = "Greater Inscription of the Oracle", spellId = 35436 },
    [2995] = { name = "Inscription of the Oracle", spellId = 35435 },

    -- ============================================
    -- BACK / CLOAK ENCHANTS
    -- ============================================
    -- Classic Cloak enchants
    [247] = { name = "Enchant Cloak - Lesser Agility", spellId = 13419 },
    [249] = { name = "Enchant Cloak - Lesser Protection", spellId = 13421 },
    [256] = { name = "Enchant Cloak - Minor Resistance", spellId = 7771 },
    [783] = { name = "Enchant Cloak - Minor Agility", spellId = 7454 },
    [848] = { name = "Enchant Cloak - Defense", spellId = 13635 },
    [849] = { name = "Enchant Cloak - Lesser Agility", spellId = 13637 },
    [884] = { name = "Enchant Cloak - Fire Resistance", spellId = 13657 },
    [903] = { name = "Enchant Cloak - Lesser Fire Resistance", spellId = 7861 },
    [1257] = { name = "Enchant Cloak - Greater Defense", spellId = 13746 },
    [1441] = { name = "Enchant Cloak - Greater Resistance", spellId = 20014 },
    [2463] = { name = "Enchant Cloak - Fire Resistance", spellId = 25081 },
    [2619] = { name = "Enchant Cloak - Greater Fire Resistance", spellId = 25081 },
    [2620] = { name = "Enchant Cloak - Greater Nature Resistance", spellId = 25082 },
    [910] = { name = "Enchant Cloak - Superior Defense", spellId = 13882 },
    [1889] = { name = "Enchant Cloak - Superior Defense", spellId = 20015 },
    -- TBC Cloak enchants
    [368] = { name = "Enchant Cloak - Dodge", spellId = 25086 },
    [2621] = { name = "Enchant Cloak - Greater Agility", spellId = 25082 },
    [2622] = { name = "Enchant Cloak - Subtlety", spellId = 25084 },
    [2662] = { name = "Enchant Cloak - Major Armor", spellId = 27961 },
    [2664] = { name = "Enchant Cloak - Major Resistance", spellId = 27962 },
    [2938] = { name = "Enchant Cloak - Spell Penetration", spellId = 34003 },
    [1354] = { name = "Enchant Cloak - Stealth", spellId = 25083 },

    -- ============================================
    -- CHEST ENCHANTS
    -- ============================================
    -- Classic Chest enchants
    [41] = { name = "Enchant Chest - Minor Health", spellId = 7420 },
    [44] = { name = "Enchant Chest - Minor Mana", spellId = 7443 },
    [63] = { name = "Enchant Chest - Minor Stats", spellId = 13538 },
    [242] = { name = "Enchant Chest - Lesser Health", spellId = 13607 },
    [246] = { name = "Enchant Chest - Lesser Mana", spellId = 13626 },
    [254] = { name = "Enchant Chest - Minor Absorption", spellId = 7426 },
    [843] = { name = "Enchant Chest - Greater Health", spellId = 13620 },
    [847] = { name = "Enchant Chest - Greater Mana", spellId = 13626 },
    [850] = { name = "Enchant Chest - Health", spellId = 13640 },
    [857] = { name = "Enchant Chest - Superior Health", spellId = 13858 },
    [866] = { name = "Enchant Chest - Lesser Stats", spellId = 13700 },
    [908] = { name = "Enchant Chest - Greater Stats", spellId = 13941 },
    [928] = { name = "Enchant Chest - Stats", spellId = 13941 },
    [1891] = { name = "Enchant Chest - Stats", spellId = 20025 },
    [1892] = { name = "Enchant Chest - Greater Stats", spellId = 20025 },
    [1950] = { name = "Enchant Chest - Major Health", spellId = 20026 },
    -- TBC Chest enchants
    [2659] = { name = "Enchant Chest - Exceptional Health", spellId = 27957 },
    [2661] = { name = "Enchant Chest - Exceptional Health", spellId = 27957 },
    [2933] = { name = "Enchant Chest - Major Resilience", spellId = 33992 },
    [3150] = { name = "Enchant Chest - Exceptional Stats", spellId = 44623 },
    [3233] = { name = "Enchant Chest - Major Spirit", spellId = 33990 },
    [3245] = { name = "Enchant Chest - Defense", spellId = 46594 },
    [1893] = { name = "Enchant Chest - Major Mana", spellId = 27958 },
    [2660] = { name = "Enchant Chest - Exceptional Mana", spellId = 27960 },

    -- ============================================
    -- WRIST / BRACER ENCHANTS
    -- ============================================
    -- Classic Bracer enchants
    [66] = { name = "Enchant Bracer - Minor Stamina", spellId = 7457 },
    [243] = { name = "Enchant Bracer - Minor Strength", spellId = 7782 },
    [247] = { name = "Enchant Bracer - Lesser Stamina", spellId = 13501 },
    [248] = { name = "Enchant Bracer - Minor Deflect", spellId = 7428 },
    [255] = { name = "Enchant Bracer - Lesser Strength", spellId = 13536 },
    [724] = { name = "Enchant Bracer - Minor Intellect", spellId = 7766 },
    [823] = { name = "Enchant Bracer - Stamina", spellId = 13648 },
    [851] = { name = "Enchant Bracer - Spirit", spellId = 13642 },
    [852] = { name = "Enchant Bracer - Strength", spellId = 13661 },
    [856] = { name = "Enchant Bracer - Lesser Intellect", spellId = 13622 },
    [905] = { name = "Enchant Bracer - Greater Stamina", spellId = 13939 },
    [907] = { name = "Enchant Bracer - Greater Strength", spellId = 13945 },
    [923] = { name = "Enchant Bracer - Deflection", spellId = 13931 },
    [924] = { name = "Enchant Bracer - Intellect", spellId = 13822 },
    [927] = { name = "Enchant Bracer - Greater Intellect", spellId = 20008 },
    [929] = { name = "Enchant Bracer - Superior Stamina", spellId = 20011 },
    [931] = { name = "Enchant Bracer - Superior Strength", spellId = 20010 },
    [1147] = { name = "Enchant Bracer - Superior Stamina", spellId = 20011 },
    [1593] = { name = "Enchant Bracer - Mana Regeneration", spellId = 23801 },
    [1600] = { name = "Enchant Bracer - Healing Power", spellId = 23802 },
    -- TBC Bracer enchants
    [369] = { name = "Enchant Bracer - Assault", spellId = 34002 },
    [1891] = { name = "Enchant Bracer - Major Intellect", spellId = 34001 },
    [2617] = { name = "Enchant Bracer - Superior Healing", spellId = 27911 },
    [2647] = { name = "Enchant Bracer - Brawn", spellId = 27899 },
    [2648] = { name = "Enchant Bracer - Fortitude", spellId = 27914 },
    [2649] = { name = "Enchant Bracer - Spellpower", spellId = 27917 },
    [2650] = { name = "Enchant Bracer - Major Defense", spellId = 27906 },
    [2679] = { name = "Enchant Bracer - Stats", spellId = 27905 },

    -- ============================================
    -- HANDS / GLOVES ENCHANTS
    -- ============================================
    -- Classic Glove enchants
    [246] = { name = "Enchant Gloves - Mining", spellId = 13617 },
    [250] = { name = "Enchant Gloves - Skinning", spellId = 13698 },
    [253] = { name = "Enchant Gloves - Herbalism", spellId = 13868 },
    [845] = { name = "Enchant Gloves - Agility", spellId = 13815 },
    [846] = { name = "Enchant Gloves - Strength", spellId = 13887 },
    [856] = { name = "Enchant Gloves - Minor Haste", spellId = 13948 },
    [904] = { name = "Enchant Gloves - Greater Strength", spellId = 20013 },
    [909] = { name = "Enchant Gloves - Greater Agility", spellId = 20012 },
    [927] = { name = "Enchant Gloves - Riding Skill", spellId = 13947 },
    [930] = { name = "Enchant Gloves - Advanced Mining", spellId = 20024 },
    [931] = { name = "Enchant Gloves - Advanced Herbalism", spellId = 20008 },
    [2564] = { name = "Enchant Gloves - Frost Power", spellId = 25073 },
    [2614] = { name = "Enchant Gloves - Fire Power", spellId = 25078 },
    [2615] = { name = "Enchant Gloves - Shadow Power", spellId = 25074 },
    [2616] = { name = "Enchant Gloves - Healing Power", spellId = 25079 },
    -- TBC Glove enchants
    [684] = { name = "Enchant Gloves - Superior Agility", spellId = 25080 },
    [2322] = { name = "Enchant Gloves - Major Strength", spellId = 33995 },
    [2613] = { name = "Enchant Gloves - Threat", spellId = 25072 },
    [2935] = { name = "Enchant Gloves - Major Spellpower", spellId = 33997 },
    [2937] = { name = "Enchant Gloves - Major Healing", spellId = 33999 },
    [2934] = { name = "Enchant Gloves - Blasting", spellId = 33994 },
    [2936] = { name = "Enchant Gloves - Spell Strike", spellId = 33993 },
    [2937] = { name = "Enchant Gloves - Major Healing", spellId = 33999 },
    [1594] = { name = "Enchant Gloves - Assault", spellId = 33996 },

    -- ============================================
    -- LEGS ENCHANTS
    -- ============================================
    -- Classic Leg enchants (same as head - Librams/Arcanum)
    -- (see HEAD section for Classic enchants, they apply to legs too)
    -- TBC Leg enchants (Armor Kits)
    [3010] = { name = "Cobrahide Leg Armor", spellId = 35488 },
    [3011] = { name = "Nethercobra Leg Armor", spellId = 35490 },
    [3012] = { name = "Clefthide Leg Armor", spellId = 35489 },
    [3013] = { name = "Nethercleft Leg Armor", spellId = 35495 },
    -- TBC Leg enchants (Spellthreads)
    [2746] = { name = "Mystic Spellthread", spellId = 31430 },
    [2747] = { name = "Runic Spellthread", spellId = 31431 },
    [2748] = { name = "Silver Spellthread", spellId = 31432 },
    [2749] = { name = "Golden Spellthread", spellId = 31433 },

    -- ============================================
    -- FEET / BOOTS ENCHANTS
    -- ============================================
    -- Classic Boot enchants
    [247] = { name = "Enchant Boots - Minor Stamina", spellId = 7863 },
    [250] = { name = "Enchant Boots - Minor Agility", spellId = 7867 },
    [724] = { name = "Enchant Boots - Lesser Agility", spellId = 13637 },
    [849] = { name = "Enchant Boots - Minor Speed", spellId = 13890 },
    [851] = { name = "Enchant Boots - Stamina", spellId = 13836 },
    [852] = { name = "Enchant Boots - Agility", spellId = 13935 },
    [904] = { name = "Enchant Boots - Greater Agility", spellId = 20023 },
    [911] = { name = "Enchant Boots - Greater Stamina", spellId = 20020 },
    [929] = { name = "Enchant Boots - Spirit", spellId = 20024 },
    [1887] = { name = "Enchant Boots - Run Speed", spellId = 34007 },
    -- TBC Boot enchants
    [2649] = { name = "Enchant Boots - Dexterity", spellId = 27951 },
    [2656] = { name = "Enchant Boots - Vitality", spellId = 27948 },
    [2657] = { name = "Enchant Boots - Fortitude", spellId = 27950 },
    [2658] = { name = "Enchant Boots - Surefooted", spellId = 27954 },
    [2939] = { name = "Enchant Boots - Cat's Swiftness", spellId = 34007 },
    [2940] = { name = "Enchant Boots - Boar's Speed", spellId = 34008 },

    -- ============================================
    -- RING ENCHANTS (Enchanters only)
    -- ============================================
    [2928] = { name = "Enchant Ring - Spellpower", spellId = 27924 },
    [2929] = { name = "Enchant Ring - Striking", spellId = 27920 },
    [2930] = { name = "Enchant Ring - Healing Power", spellId = 27926 },
    [2931] = { name = "Enchant Ring - Stats", spellId = 27927 },

    -- ============================================
    -- WEAPON ENCHANTS
    -- ============================================
    -- Classic Weapon enchants
    [241] = { name = "Enchant Weapon - Minor Beastslayer", spellId = 13653 },
    [249] = { name = "Enchant Weapon - Lesser Beastslayer", spellId = 7786 },
    [250] = { name = "Enchant Weapon - Minor Striking", spellId = 7788 },
    [723] = { name = "Enchant Weapon - Intellect", spellId = 7793 },
    [803] = { name = "Enchant Weapon - Fiery Weapon", spellId = 13898 },
    [805] = { name = "Enchant Weapon - Icy Chill", spellId = 13931 },
    [811] = { name = "Enchant Weapon - Unholy Weapon", spellId = 13915 },
    [853] = { name = "Enchant Weapon - Demonslaying", spellId = 13915 },
    [854] = { name = "Enchant Weapon - Elemental Slayer", spellId = 13915 },
    [856] = { name = "Enchant Weapon - Lifestealing", spellId = 20032 },
    [912] = { name = "Enchant Weapon - Lesser Striking", spellId = 13503 },
    [943] = { name = "Enchant Weapon - Striking", spellId = 13693 },
    [963] = { name = "Enchant Weapon - Major Healing", spellId = 22750 },
    [1894] = { name = "Enchant Weapon - Icy Chill", spellId = 20029 },
    [1896] = { name = "Enchant Weapon - Lifestealing", spellId = 20032 },
    [1897] = { name = "Enchant Weapon - Unholy Weapon", spellId = 20033 },
    [1898] = { name = "Enchant Weapon - Spellpower", spellId = 22749 },
    [1899] = { name = "Enchant Weapon - Healing Power", spellId = 22750 },
    [1900] = { name = "Enchant Weapon - Crusader", spellId = 20034 },
    [1903] = { name = "Enchant Weapon - Spirit", spellId = 20031 },
    [1904] = { name = "Enchant Weapon - Agility", spellId = 20031 },
    [2443] = { name = "Enchant Weapon - Strength", spellId = 20031 },
    [2504] = { name = "Enchant Weapon - Greater Striking", spellId = 23799 },
    [2505] = { name = "Enchant Weapon - Superior Striking", spellId = 23800 },
    [2563] = { name = "Enchant Weapon - Mighty Intellect", spellId = 27968 },
    [2564] = { name = "Enchant Weapon - Mighty Spirit", spellId = 27972 },
    [2567] = { name = "Enchant Weapon - Mighty Spellpower", spellId = 27975 },
    [2568] = { name = "Enchant Weapon - Agility", spellId = 27837 },
    -- TBC Weapon enchants
    [2343] = { name = "Enchant Weapon - Deathfrost", spellId = 46578 },
    [2666] = { name = "Enchant Weapon - Major Striking", spellId = 27967 },
    [2667] = { name = "Enchant Weapon - Savagery", spellId = 27972 },
    [2668] = { name = "Enchant Weapon - Potency", spellId = 27967 },
    [2669] = { name = "Enchant Weapon - Major Spellpower", spellId = 27975 },
    [2670] = { name = "Enchant Weapon - Major Intellect", spellId = 27968 },
    [2671] = { name = "Enchant Weapon - Sunfire", spellId = 27981 },
    [2672] = { name = "Enchant Weapon - Soulfrost", spellId = 27982 },
    [2673] = { name = "Enchant Weapon - Mongoose", spellId = 27984 },
    [2674] = { name = "Enchant Weapon - Spellsurge", spellId = 28003 },
    [2675] = { name = "Enchant Weapon - Battlemaster", spellId = 28004 },
    [3222] = { name = "Enchant Weapon - Greater Agility", spellId = 42620 },
    [3225] = { name = "Enchant Weapon - Executioner", spellId = 42974 },
    [3239] = { name = "Enchant Weapon - Icebane", spellId = 44510 },

    -- ============================================
    -- 2H WEAPON ENCHANTS
    -- ============================================
    -- Classic 2H enchants
    [241] = { name = "Enchant 2H Weapon - Minor Impact", spellId = 7745 },
    [723] = { name = "Enchant 2H Weapon - Lesser Intellect", spellId = 7793 },
    [943] = { name = "Enchant 2H Weapon - Impact", spellId = 13695 },
    [963] = { name = "Enchant 2H Weapon - Superior Impact", spellId = 13937 },
    [1896] = { name = "Enchant 2H Weapon - Major Spirit", spellId = 20035 },
    [1897] = { name = "Enchant 2H Weapon - Major Intellect", spellId = 20036 },
    [1904] = { name = "Enchant 2H Weapon - Agility", spellId = 27837 },
    [2523] = { name = "Enchant 2H Weapon - Greater Impact", spellId = 23800 },
    -- TBC 2H enchants
    [2646] = { name = "Enchant 2H Weapon - Major Agility", spellId = 27977 },
    [2676] = { name = "Enchant 2H Weapon - Savagery", spellId = 28004 },

    -- ============================================
    -- SHIELD ENCHANTS
    -- ============================================
    -- Classic Shield enchants
    [848] = { name = "Enchant Shield - Lesser Block", spellId = 13464 },
    [851] = { name = "Enchant Shield - Stamina", spellId = 13631 },
    [864] = { name = "Enchant Shield - Lesser Stamina", spellId = 13378 },
    [904] = { name = "Enchant Shield - Greater Stamina", spellId = 20017 },
    [926] = { name = "Enchant Shield - Frost Resistance", spellId = 13933 },
    [929] = { name = "Enchant Shield - Greater Spirit", spellId = 13905 },
    [1071] = { name = "Enchant Shield - Greater Stamina", spellId = 20017 },
    [1888] = { name = "Enchant Shield - Superior Stamina", spellId = 34009 },
    [1890] = { name = "Enchant Shield - Vitality", spellId = 34009 },
    -- TBC Shield enchants
    [2653] = { name = "Enchant Shield - Parry", spellId = 27946 },
    [2654] = { name = "Enchant Shield - Resilience", spellId = 27947 },
    [2655] = { name = "Enchant Shield - Intellect", spellId = 27945 },
    [3229] = { name = "Enchant Shield - Defense", spellId = 44489 },

    -- ============================================
    -- RANGED WEAPON ENCHANTS (Scopes)
    -- ============================================
    [30] = { name = "Crude Scope", spellId = 3974 },
    [32] = { name = "Standard Scope", spellId = 3975 },
    [33] = { name = "Accurate Scope", spellId = 3976 },
    [663] = { name = "Deadly Scope", spellId = 12620 },
    [664] = { name = "Sniper Scope", spellId = 22793 },
    [2523] = { name = "Stabilized Eternium Scope", spellId = 30252 },
    [2724] = { name = "Khorium Scope", spellId = 30334 },
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

-- Get enchant info from enchant effect ID
function GearExport:GetEnchantInfo(enchantID)
    if not enchantID or enchantID == 0 then return nil end

    -- Look up enchant in our data table
    local enchantData = ENCHANT_DATA[enchantID]

    if enchantData then
        return {
            name = enchantData.name,
            id = enchantID,
            spellId = enchantData.spellId,
        }
    end

    -- Fallback for unknown enchants - still include it but mark as unknown
    return {
        name = "Unknown Enchant",
        id = enchantID,
        spellId = enchantID,  -- May not be correct but allows tooltip lookup attempt
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

                -- Add enchant if present
                local enchant = self:GetEnchantInfo(parsed.enchantID)
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
