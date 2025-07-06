# ScroogeLoot
addon for loot management for Epoch WoW

## Player Data

The addon maintains a `PlayerData` table containing raid member information.
Only the master looter is allowed to modify the table. Attendance percentage is
derived from `attended / (attended + absent)`.
