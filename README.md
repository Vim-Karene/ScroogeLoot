# ScroogeLoot
addon for loot management for Epoch WoW

## Player Data

The addon maintains a `PlayerData` table containing raid member information.
Only the master looter is allowed to modify the table. Attendance percentage is
derived from `attended / (attended + absent)`. This table is saved to your
profile so information persists between game sessions.

### Syncing PlayerData

The master looter's copy is the source of truth. Whenever the master updates
`PlayerData`, the new table is broadcast to the group using AceComm so that all
clients stay in sync.

### Editing PlayerData

Use `/sl pm` in game to open the **Player Management** window. The window edits
the persistent `PlayerDB` saved variables and updates the in-memory
`PlayerData` table. Saving your changes broadcasts the new `PlayerData` to the
group and persists them between sessions.

The saved data is written to `PlayerDB` which lives in its own file
`WTF/Account/<ACCOUNT>/SavedVariables/PlayerDB.lua`. If the file or
your character entry does not exist, the addon will create it the first time you
log in and automatically add your character to the table.

Each player entry in `PlayerData` contains the following fields:

```
name, class, raiderrank, DP, SP,
item1, item1received, item2, item2received,
item3, item3received, attended, absent, attendance
```
