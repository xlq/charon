-- STRING REPRESENTATION --

-- repr(obj)
-- Return string representation of a Lua object obj.
-- This string representation should be valid Lua code where possible.
-- Functions and recursive tables are not converted.
return function(obj)
    local stack = {}
    local tostring = tostring
    local function visit(obj, doiter, key)
        local typ = type(obj)
        if typ == "table" and not key then
            if stack[obj] then return tostring(obj)
            else
                stack[obj] = true
                local bits = {}
                local highest_ikey = 0
                for k,v in ipairs(obj) do
                    bits[#bits+1] = visit(v, false, false)
                    highest_ikey = k
                end
                for k,v in pairs(obj) do
                    if type(k) == "number"
                      and math.floor(k) == k
                      and k >= 1
                      and k <= highest_ikey
                    then
                        -- Already done this item in loop above
                    else
                        local keystr
                        if type(k) == "string" and k:match("^[_%a][_%w]*$") then
                            -- valid identifier
                            keystr = k
                        else
                            keystr = "[" .. visit(k, false, true) .. "]"
                        end
                        bits[#bits+1] = keystr .. " = " .. visit(v, false, false)
                    end
                end
                stack[obj] = nil
                return "{" .. table.concat(bits, ", ") .. "}"
            end
        elseif typ == "string" then
            return string.format("%q", obj) --"\"" .. obj:gsub("[\"\\]", "\\%0") .. "\""
        elseif doiter and typ == "function" then
            local bits = {}
            for x in obj do
                bits[#bits+1] = visit(x, false, false)
            end
            return "{" .. table.concat(bits, ", ") .. "}"
        else
            return tostring(obj)
        end
    end
    return visit(obj, true, false)
end
