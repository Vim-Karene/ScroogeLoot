# ScroogeLoot
addon for loot management for Epoch WoW

## Candidate Data

The addon maintains a `candidateData` table containing raid member information.
Only the master looter is allowed to modify the table. Attendance percentage is
derived from `attended / (attended + absent)`. This table is saved to your
profile so information persists between game sessions.

### Syncing candidateData

The master looter's copy is the source of truth. Whenever the master updates
`candidateData`, the new table is broadcast to the group using AceComm so that all
clients stay in sync.

### Editing candidateData

Use `/sl pm` in game to open the **Player Management** window. All fields of the
`candidateData` table can be edited directly in this window. Saving will broadcast
the updated table to the raid. Player data is stored in saved variables so any
changes persist between sessions.
