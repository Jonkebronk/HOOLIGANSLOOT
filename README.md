# HOOLIGANS Loot Council

A loot tracking addon for World of Warcraft Classic Anniversary Edition, designed for the HOOLIGANS guild. Tracks raid loot and integrates with the HOOLIGANS website for loot council voting.

## Overview

HooligansLoot provides a streamlined loot management workflow:

1. **Track Loot** - Automatically captures boss drops with 2-hour trade timers
2. **Export** - Send loot data to the HOOLIGANS website for voting
3. **Vote on Website** - Council votes on the platform (not in-game)
4. **Import Awards** - Bring voting results back into the addon
5. **Distribute** - Trade items to winners with auto-trade assistance

## Features

### Loot Tracking
- Automatically detects and tracks epic+ items from raid encounters
- Configurable minimum quality threshold (default: Epic)
- Tracks 2-hour trade window expiration
- Boss attribution for each drop
- Manual item adding support

### Session Management
- Create sessions per raid instance
- Track multiple items per session
- View session history
- Resume or review past sessions

### Export/Import Workflow
- **Export**: JSON format for HOOLIGANS website integration
- **Import**: Load award decisions from website after voting
- Item GUID matching for accurate award assignment

### Trade Management
- Auto-detect trade targets
- Prompt with pending items for that player
- Mark items as awarded after successful trade

### Announcements
- Announce awards to raid chat
- Configurable channel (RAID, RAID_WARNING, etc.)

### Minimap Button
- Quick access via minimap icon
- Left-click to open main window
- Right-click to open settings
- Draggable position

## Installation

1. Download or clone this repository
2. Copy the `HooligansLoot` folder to:
   ```
   World of Warcraft\_anniversary_\Interface\AddOns\
   ```
3. Restart WoW or `/reload`

## Quick Start

1. **Start a Session**: `/hl start` when entering raid
2. **Track Loot**: Items are captured automatically from boss kills
3. **Export**: `/hl export` to get JSON for the website
4. **Vote on Website**: Council votes on hooligans.gg
5. **Import Awards**: `/hl import` with results from website
6. **Trade Items**: Right-click items or use auto-trade prompts

## Commands

| Command | Description |
|---------|-------------|
| `/hl` | Open main window |
| `/hl start` | Start new session and open window |
| `/hl export` | Export session to JSON |
| `/hl import` | Import awards from website |
| `/hl announce` | Announce awards to raid |
| `/hl trade` | Show pending trades |
| `/hl history` | View loot history |
| `/hl settings` | Open settings panel |
| `/hl help` | Show all commands |

### Testing Commands
| Command | Description |
|---------|-------------|
| `/hl test kara [n]` | Add simulated Karazhan drops (default 8) |
| `/hl test item` | Add a single random test item |
| `/hl debug` | Toggle debug mode |

See [COMMANDS.md](COMMANDS.md) for complete command reference.

## Configuration

Access settings via `/hl settings`:

### Loot Tracking
- **Minimum Quality**: Filter items by quality (Uncommon -> Legendary)

### Announcements
- **Channel**: RAID, RAID_WARNING, PARTY
- **Auto-Announce**: Announce when awards are imported

### Trading
- **Auto-Trade**: Automatically prompt trades
- **Trade Prompt**: Confirm before initiating trades

## User Interface

### Main Window (`/hl`)

- **Header**: History, Settings buttons + version display
- **Session Bar**: Session name, New/Rename buttons, status
- **Item List**: Tracked items with icon, name, boss, timer, award status
- **Button Bar**: Export, Import, Announce, Add, Refresh, Test, End
- **Stats**: Items tracked, awards pending, expired timers

### Item Actions (Right-click)
- Set winner manually
- Remove item from session
- View item details

## Architecture

```
HooligansLoot/
|-- Core.lua              # Addon initialization, slash commands
|-- Utils.lua             # Utility functions
|-- Modules/
|   |-- Announcer.lua     # Chat announcements
|   |-- Export.lua        # JSON export for website
|   |-- Import.lua        # Import awards from website
|   |-- LootTracker.lua   # Loot detection and tracking
|   |-- SessionManager.lua # Session handling
|   +-- TradeManager.lua  # Trade automation
|-- UI/
|   |-- AwardFrame.lua    # Manual award assignment
|   |-- HistoryFrame.lua  # Loot history viewer
|   |-- MainFrame.lua     # Main addon window
|   |-- RaidPopup.lua     # Raid entry prompt
|   +-- SettingsFrame.lua # Configuration
|-- Textures/
|   +-- logo.tga          # Guild logo
+-- Libs/                 # Libraries (Ace3, LibDBIcon)
```

## Workflow Integration

### Export Format (JSON)
```json
{
  "teamId": "",
  "sessionId": "session_1234567890",
  "sessionName": "Karazhan - 2025-01-30 20:00",
  "items": [
    {
      "guid": "item_12345_1234567890_1234",
      "itemName": "Tier Token",
      "wowheadId": 29760,
      "link": "|cffa335ee|Hitem:29760...|h[Helm of the Fallen Champion]|h|r",
      "quality": 4,
      "ilvl": 120,
      "boss": "Prince Malchezaar"
    }
  ]
}
```

### Import Format (JSON)
```json
{
  "awards": [
    {
      "itemGuid": "item_12345_1234567890_1234",
      "winner": "PlayerName",
      "class": "Warrior"
    }
  ]
}
```

## Troubleshooting

### Items not tracking
- Ensure minimum quality is set appropriately
- Check that you're in a raid instance
- Verify you have an active session (`/hl start`)
- Use `/hl debug` to enable logging

### Export issues
- Ensure session has items before exporting
- Check that items have valid GUIDs

### Trade window issues
- Ensure auto-trade is enabled in settings
- Check that items are still tradeable (2-hour window)
- Manually trade if automation fails

## Version

- **Version**: 2.0.0
- **Interface**: 11503, 11504, 20505 (Classic Anniversary / TBC Anniversary)
- **Author**: Johnny / HOOLIGANS Guild
- **GitHub**: https://github.com/Jonkebronk/HOOLIGANSLOOT

## Changelog

### v2.0.0 (Major Update)
- **ML-Only Mode**: Removed in-game voting system
- **Website Integration**: Voting now done on HOOLIGANS website
- **Simplified UI**: Cleaner interface without raider sync panels
- **Export/Import Workflow**: New JSON format for website integration
- **Removed**: In-game voting, raider sync, council management
- **Removed**: LootFrame, SessionSetupFrame, Voting, Comm, GearComparison modules

### v1.2.0
- Version display in header
- Player version tracking
- Vote confirmation system

### v1.1.0
- MainFrame item display fixes
- Vote UX improvements
- Role-based UI

## License

MIT License - Feel free to modify for your guild!
