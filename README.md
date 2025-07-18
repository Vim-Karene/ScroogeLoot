# ScroogeLoot
addon for loot management for Epoch WoW

## Player Data

The addon maintains a `PlayerDB` table containing raid member information.
Only the master looter is allowed to modify the table. Attendance percentage is
derived from `attended / (attended + absent)`. This table is saved to your
profile so information persists between game sessions.

### Syncing PlayerDB

The master looter's copy is the source of truth. Whenever the master updates
`PlayerDB`, the new table is broadcast to the group using AceComm so that all
clients stay in sync.

### Editing PlayerDB

Use `/sl pm` in game to open the **Player Management** window. All fields of the
`PlayerDB` table can be edited directly in this window. Saving will broadcast
the updated table to the raid. Player data is stored in saved variables so any
changes persist between sessions.

The saved data is written to `PlayerDB` which lives in its own file
`WTF/Account/<ACCOUNT>/SavedVariables/PlayerDB.lua`. If the file or
your character entry does not exist, the addon will create it the first time you
log in and automatically add your character to the table.

Each player entry in `PlayerDB` contains the following fields:

```
name, class, raiderrank, DP, SP,
item1, item1received, item2, item2received,
item3, item3received, attended, absent, attendance
```
