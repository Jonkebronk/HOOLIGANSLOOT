# HOOLIGANS Loot Council - Project Notes

## Repository Location

The actual git repository is located at:
```
C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\HooligansLoot
```

GitHub: https://github.com/Jonkebronk/HOOLIGANSLOOT.git

## Git Workflow

- **Branch**: `main`
- **Push**: `git push`

```bash
cd "C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\HooligansLoot"
git add <files>
git commit -m "Description"
git push
```

## Current Version

- **Version**: 2.0.0
- **Interface**: 11503, 11504, 20505 (Classic Anniversary / TBC Anniversary)
- **Author**: Johnny / HOOLIGANS Guild

## Project Structure

This is a World of Warcraft addon for loot tracking with website-based voting.

### Core Files
- `Core.lua` - Main addon initialization, slash commands, minimap button
- `Utils.lua` - Utility functions
- `HooligansLoot.toc` - Addon manifest
- `embeds.xml` - Library loading manifest

### Modules (Modules/)
- `LootTracker.lua` - Tracks looted items and trade timers
- `SessionManager.lua` - Manages loot sessions
- `Export.lua` - Export to JSON for website
- `Import.lua` - Import awards from website
- `TradeManager.lua` - Trade window management
- `Announcer.lua` - Raid announcements

### UI Files (UI/)
- `MainFrame.lua` - Main addon window with item list
- `RaidPopup.lua` - Raid entry popup
- `SettingsFrame.lua` - Settings panel
- `HistoryFrame.lua` - Loot history
- `AwardFrame.lua` - Manual award assignment

### Libraries (Libs/)
- Ace3 framework (AceAddon, AceDB, AceEvent, etc.)
- LibDataBroker-1.1 - Data broker for minimap integration
- LibDBIcon-1.0 - Standard minimap button library

### Textures (Textures/)
- `logo.tga` - Guild logo used in minimap button and main frame header

## Slash Commands

- `/hl` - Show main window
- `/hl start` - Start new session
- `/hl export` - Export session to JSON
- `/hl import` - Import awards from website
- `/hl announce` - Announce awards to raid
- `/hl trade` - Show pending trades
- `/hl history` - Loot history
- `/hl settings` - Settings panel
- `/hl debug` - Toggle debug mode
- `/hl debug session` - Debug session state
- `/hl test kara [n]` - Test with Karazhan items
- `/hl test item` - Add single test item
- `/hl help` - Show all commands

## Key Features

- **ML-Only Mode**: Only Master Looter uses the addon
- **Loot Tracking**: Automatic tracking of epic+ items with 2-hour trade timer
- **Export**: JSON format for HOOLIGANS website voting
- **Import**: Load voting results from website
- **Auto-Trade**: Trade prompts when opening trade with award winner
- **Announcements**: Announce awards to raid chat

## Workflow

1. **Track Loot** - ML loots items, addon tracks automatically
2. **Export** - `/hl export` to get JSON for website
3. **Vote on Website** - Council votes on hooligans.gg
4. **Import Awards** - `/hl import` with results
5. **Distribute** - Trade items to winners

## v2.0.0 Changes

Removed (no longer loaded):
- `Modules/Voting.lua` - In-game voting
- `Modules/Comm.lua` - Raider sync
- `Modules/GearComparison.lua` - Gear comparison
- `UI/LootFrame.lua` - Raider response popup
- `UI/SessionSetupFrame.lua` - Vote setup dialog

## Working Directories

Additional working directories configured:
- `C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\HooligansLoot\UI`
- `C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\HooligansLoot\Modules`
- `C:\Program Files (x86)\World of Warcraft\_anniversary_\Interface\AddOns\HooligansLoot`

## Documentation Files

- `README.md` - User-facing documentation
- `COMMANDS.md` - Complete command reference
