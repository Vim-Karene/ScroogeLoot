-- Utilities.lua
-- General utility functions for the Scrooge Loot addon

-- Addon namespace
local ScroogeLoot = ScroogeLoot or {}

local Utilities = {}
ScroogeLoot.Utilities = Utilities

-- Function: Trim whitespace from a string
function Utilities.Trim(str)
    return str:match("^%s*(.-)%s*$")
end

-- Function: Split a string by a delimiter
function Utilities.Split(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-- Function: Round a number to a given number of decimal places
function Utilities.Round(num, decimals)
    local mult = 10^(decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Function: Check if a table contains a value
function Utilities.TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Function: Deep copy a table
function Utilities.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utilities.DeepCopy(orig_key)] = Utilities.DeepCopy(orig_value)
        end
        setmetatable(copy, Utilities.DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Function: Print table contents (for debugging)
function Utilities.PrintTable(tbl, indent)
    indent = indent or 0
    for k, v in pairs(tbl) do
        local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
        if type(v) == "table" then
            print(formatting)
            Utilities.PrintTable(v, indent + 1)
        else
            print(formatting .. tostring(v))
        end
    end
end

-- Function: Merge two tables
function Utilities.MergeTables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            Utilities.MergeTables(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

-- Function: Generate a random number within a range (inclusive)
function Utilities.RandomRange(min, max)
    return math.random(min, max)
end

-- Function: Safe tonumber that returns 0 if invalid
function Utilities.SafeNumber(value)
    local num = tonumber(value)
    return num or 0
end

-- Example Usage (Testing)
--[[ Uncomment to test
print("Testing Utilities Module")
print("Trim:", Utilities.Trim("   Hello World  "))
print("Split:", table.concat(Utilities.Split("one,two,three", ","), "|"))
print("Round:", Utilities.Round(3.14159, 2))
print("TableContains:", Utilities.TableContains({"a", "b", "c"}, "b"))

local testTable = {
    name = "Player1",
    stats = {
        tokenPoints = 50,
        debtPoints = 25
    }
}
local copyTable = Utilities.DeepCopy(testTable)
copyTable.stats.tokenPoints = 100
Utilities.PrintTable(testTable)
Utilities.PrintTable(copyTable)
]]--