----- ITERATORS -----
--
--  The following functions provide or manipulate iterators or iterables.
--  The iterators provided here are closures that can be called
--  repeatedly until they return nil.
--  Lua's pairs and ipairs functions are not compatible with these
--  sorts of iterators, but the for..in statement works with them.
--

-- Get an iterator for x
-- If x is:
--     table with __iter metamethod - __iter(x) is returned
--     table - ivalues(x) is returned
--     string - chars(x) is returned
--     otherwise - returns x

local iters = {}

function iters.iter(x)
    local t = type(x)
    if t == "table" then
        local mt = getmetatable(x)
        if mt then
            local __iter = mt.__iter
            if __iter then return __iter(x) end
        end
        return iters.ivalues(x)
    elseif t == "string" then
        return iters.chars(x)
    else
        return x
    end
end

-- Iterate over a table's key/value pairs.
-- This differs from Lua's pairs because it returns just one function.
function iters.pairs(t)
    local k = nil
    return function()
        local v
        k, v = next(t, k)
        return k, v
    end
end

-- Iterate over a table's array index/value pairs.
function iters.ipairs(t)
    local i = 0
    return function()
        i = i + 1
        local v = t[i]
        if v == nil then return nil
        else return i, v end
    end
end

-- Iterate over just a table's values.
function iters.values(t)
    local k = nil
    return function()
        local v
        k, v = next(t, k)
        return v
    end
end

-- Iterate over a table's array values.
function iters.ivalues(t)
    local i = 0
    return function()
        i = i + 1
        return t[i]
    end
end

-- Iterate over a string's characters.
function iters.chars(s)
    local i, len = 0, #s
    return function()
        i = i + 1
        if i <= len then return s:sub(i,i) end
    end
end

-- Make a table (with keys 1, 2, ...) from an iterable.
-- TODO: handle k,v pairs?
function iters.totable(x)
    local x = iters.iter(x)
    local t = {}
    local i = 0
    for v in x do
        i = i + 1
        t[i] = v
    end
    return t
end

-- Like table.concat but better :D
function iters.concat(iterable, delim)
    return table.concat(iters.totable(iterable), delim)
end

function iters.map(f, iterable)
    iterable = iters.iter(iterable)
    return function()
        local x = iterable()
        if x ~= nil then return f(x) end
    end
end

function iters.mapm(f, iterable)
    iterable = iters.iter(iterable)
    return function()
        local x = {iterable()}
        if next(x) then return f(unpack(x)) end
    end
end

-- Iterate over an iterable, skipping elements for which the
-- predicate f evaluates to false.
function iters.filter(f, iterable)
    iterable = iters.iter(iterable)
    return function()
        local x
        repeat x = iterable()
        until x == nil or f(x)
        return x
    end
end

-- Return number of items from an iterable.
-- If iterable is an iterator, it will consume all the items!
function iters.count(iterable)
    iterable = iters.iter(iterable)
    local i = 0
    for junk in iterable do i = i + 1; end
    return i
end

-- Return true if any item evaluates to true
-- May not exhaust iterable
function iters.any(iterable)
    iterable = iters.iter(iterable)
    for x in iterable do if x then return true; end end
    return false
end

-- Return true if all items evaluate to true
-- May not exhaust iterable
function iters.all(iterable)
    iterable = iters.iter(iterable)
    for x in iterable do if not x then return false; end end
    return true
end

-- range(a,b): Return iterator for a range of numbers [a,b]
-- range(n): Return iterator for a range of numbers [1,n]
function iters.range(a,b)
    local i
    if b then i = a - 1
    else i, b = 0, a end
    return function()
        i = i + 1
        if i <= b then return i end
    end
end

-- Return a function f(x) -> x[k]
-- Useful with map
function iters.getter(k)
    return function(x)
        return x[k]
    end
end

return iters
