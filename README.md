# ScroogeLoot
addon for loot management for Epoch WoW

## Player Data

The addon maintains a `PlayerData` table containing raid member information.
Only the master looter is allowed to modify the table. Attendance percentage is
derived from `attended / (attended + absent)`.

### Syncing PlayerData

The master looter's copy is the source of truth. Whenever the master updates
`PlayerData`, the new table is broadcast to the group using AceComm so that all
clients stay in sync.
