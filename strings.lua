----- STRINGS -----
--
--  These functions provide extra string functionality
--

local strings = {}
local iters

-- xsplit(str, [sep=" "], [nmax])
-- Break a string into pieces, Python-style (returns iterator)
function strings.xsplit(str, sep, nmax)
    sep = sep or " "
    local pos = 1
    local nmatch = 0
    return function ()
        if pos == -1 then return nil
        elseif nmatch == nmax then
            local r = str:sub(pos)
            pos = -1
            return r, nmatch + 1
        else
            local a, b = str:find(sep, pos, true)
            if a then
                -- next match
                local r = str:sub(pos, a - 1)
                pos = b + 1
                nmatch = nmatch + 1
                return r, nmatch
            else
                -- no more matches
                local r
                if pos <= #str then r = str:sub(pos) end
                pos = -1
                return r, nmatch + 1
            end
        end
    end
end

-- split(str, [sep=" "], [nmax])
-- Break a string into pieces, Python-style (returns table)
function strings.split(str, sep, nmax)
    if not iters then iters = require "charon.iters"; end
    return iters.totable(strings.xsplit(str, sep, nmax))
end

-- True if s starts with s2
function strings.starts_with(s, s2)
    return s:sub(1, #s2) == s2
end

-- True if s ends with s2
function strings.ends_with(s, s2)
    return s:sub(-#s2) == s2
end

----- IO -----

function strings.printf(fmt, ...)
    return strings.fprintf(io.stdout, fmt, ...)
end

function strings.printfln(fmt, ...)
    return strings.fprintf(io.stdout, fmt.."\n", ...)
end

function strings.fprintf(f, fmt, ...)
    f:write(string.format(fmt, ...))
end

function strings.errorf(fmt, ...)
    return error(string.format(fmt, ...))
end

return strings
