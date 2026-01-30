# HOOLIGANS Loot - Command Reference

Complete reference for all slash commands available in the HooligansLoot addon (v2.0.0).

## Quick Reference

| Command | Description |
|---------|-------------|
| `/hl` | Open main window |
| `/hl start` | Start new session |
| `/hl export` | Export session to JSON |
| `/hl import` | Import awards |
| `/hl announce` | Announce awards to chat |
| `/hl trade` | Show pending trades |
| `/hl history` | View loot history |
| `/hl settings` | Open settings panel |
| `/hl help` | Show command list |

## General Commands

### `/hl` or `/hl show`
Opens the main addon window showing the current session, tracked items, and action buttons.

### `/hl start`
Creates a new loot session (auto-named with zone and timestamp) and opens the main window. Equivalent to clicking "New" in the session bar.

### `/hl help`
Displays a list of all available commands in chat.

---

## Session Management

### `/hl session new [name]`
Creates a new loot session. If no name is provided, auto-generates one using the current zone and timestamp.

**Examples:**
```
/hl session new                    # Auto-name: "Karazhan - 2025-01-30 20:30"
/hl session new Tuesday Kara Run   # Custom name
```

### `/hl session end`
Ends the current active session. Items can still be viewed and exported, but new loot won't be added.

### `/hl session list`
Lists all sessions with their names, item counts, and award status.

**Output example:**
```
Sessions:
  Karazhan - 2025-01-30 20:30 [ACTIVE] - 12 items (8/10 awarded)
  Gruul's Lair - 2025-01-29 - 5 items (5/5 awarded)
```

---

## Data Management

### `/hl export`
Opens the export dialog to save session data in JSON format for the HOOLIGANS website.

The exported JSON includes:
- Session ID and name
- All tracked items with GUIDs
- Item details (name, ID, boss, quality, ilvl)
- Any existing awards

### `/hl import`
Opens the import dialog to load award decisions from the HOOLIGANS website after voting.

Supports JSON format with item GUID to winner mappings.

### `/hl announce`
Announces all pending awards to the configured chat channel (RAID, RAID_WARNING, etc.).

### `/hl trade`
Lists all pending trades (items awarded but not yet traded) in chat.

**Output example:**
```
Pending trades:
  [Tier Token] -> PlayerName
  [Epic Weapon] -> OtherPlayer
```

---

## User Interface

### `/hl settings` or `/hl options`
Opens the settings panel to configure:
- Loot tracking options (minimum quality)
- Announcement channels
- Trade automation
- Debug settings

### `/hl history`
Opens the history frame to view awarded items across all sessions.

---

## Testing & Debug Commands

### `/hl test kara [count]`
Simulates Karazhan boss drops for testing. Adds realistic test items to the current session.

**Examples:**
```
/hl test kara        # Add 8 random Karazhan drops
/hl test kara 5      # Add 5 random Karazhan drops
```

### `/hl test item`
Adds a single random test item to the current session.

### `/hl debug`
Toggles debug mode on/off. When enabled, detailed logging appears in chat for troubleshooting.

### `/hl debug session`
Prints detailed information about the current session:
- Session ID and name
- Item count
- Award count
- First few items with award status

### `/hl debug scan`
Manually triggers a bag scan to find tradeable items.

---

## Alternative Slash Command

All commands can also be accessed via `/hooligans` instead of `/hl`:
```
/hooligans
/hooligans start
/hooligans settings
```

---

## Typical Raid Workflow

1. **Start of Raid**
   ```
   /hl start
   ```
   Creates session, opens main window.

2. **During Raid**
   - Items tracked automatically when looted
   - Main window shows all drops with trade timers

3. **After Bosses / End of Raid**
   ```
   /hl export
   ```
   Copy JSON, paste into HOOLIGANS website for voting.

4. **After Voting on Website**
   ```
   /hl import
   ```
   Paste award results from website.

5. **Distribute Loot**
   - Trade items to winners (auto-trade prompts when opening trade)
   - Or right-click items to see award info
   ```
   /hl announce
   ```
   Announce winners to raid chat.

6. **End Session**
   ```
   /hl session end
   ```

---

## Tips

1. **Quick Start**: Use `/hl start` at the beginning of a raid to create a session and open the UI in one command.

2. **Keep Window Open**: Leave the main window open during raid to see items as they drop.

3. **Export Early**: You can export multiple times - export after each boss if needed.

4. **Check Timers**: Watch the trade timer column - items become non-tradeable after 2 hours.

5. **Troubleshooting**: Enable debug mode with `/hl debug` to see detailed logging.
