----- TABLES -----
--
--  These functions provide functionality for tables that
--  isn't present in Lua.
--

local tables = {}

-- Return true if k is an integer key
local function is_ikey(k)
    return type(k) == "number" and k >= 1 and k % 1 == 0
end

-- Linear search
-- Return key for a value in the given table, or nil if not found
function tables.search(t, value)
    for k, v in pairs(t) do
        if v == value then
            return k
        end
    end
end

-- Same as search but only for ipairs
function tables.isearch(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
end

-- Make a shallow copy of a table
function tables.copy(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return setmetatable(t2, getmetatable(t))
end

-- Make a shallow copy of a table (integer keys only)
function tables.icopy(t)
    local t2 = {}
    for i, v in ipairs(t) do
        t2[i] = v
    end
    return setmetatable(t2, getmetatable(t))
end

-- Make a shallow copy of a table (non-integer keys only)
function tables.hcopy(t)
    local t2 = {}
    for k, v in pairs(t) do
        if not is_ikey(k) then t2[k] = v end
    end
    return setmetatable(t2, getmetatable(t))
end

-- Compare keys and values of a table (shallow)
function tables.compare(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] ~= v then return false end
    end
    for k, v in pairs(t2) do
        if t1[k] ~= v then return false end
    end
    return true
end

-- tabrepli(t, [a, b, ...])
-- Copy a table t and replace its integer items with a, b, ...
--function tabrepli(t, ...)
--    local t2 = {...}
--    for k,v in pairs(t) do
--        if t2[k] == nil then
--            t2[k] = v
--        end
--    end
--    return t2
--end

function tables.is_empty(table)
    return next(table) == nil
end

-- merge(t, src, [src2, [src3 ...]] )
-- Mutate table t with values from src
-- If src is:
--   table: concatenate positional items to the end of t and
--          copy the other items, with values from src replacing
--          values in t.
--   function: concatenate items from iterator src to end of t
--   anything else: src is appended to table
-- This function doesn't work very well with holey tables.
-- Repeats for src2, src3 ...
-- Returns t, #t
function tables.merge(t, ...)
    local args = {...}
    local n = #t
    for _, src in ipairs(args) do
        local typ = type(src)
        if typ == "table" then
            for k, v in pairs(src) do
                if is_ikey(k) then t[n+k] = v
                else t[k] = v end
            end
            n = #t
        elseif typ == "function" then
            for x in src do
                n = n + 1
                t[n] = x
            end
        else
            n = n + 1
            t[n] = src
        end
    end
    return t, n
end

-- append(t, x1, [x2, ...] )
-- Mutate table t by appending each item x1, x2, ...
-- Return t
function tables.append(t, ...)
    local args = {...}
    local n = #t
    for k, v in ipairs(args) do
        t[n+k] = v
    end
    return t
end

return tables
