-- A simple object system.
-- Create a class with:
--   animal = class()
-- You can specify parent classes:
--   cat = class(animal)
-- You can create instances with the "new" method:
--   my_cat = cat:new()
-- Metamethods, except __index and __newindex, can be put directly
-- into the class:
--   function animal:__call() ...
-- __init for each class is called at object construction, with
-- the arguments to "new" forwarded:
--   function cat:__init(a) print(a); end
--   cat:new("foo") -- will print "foo"
-- Getters and setters are handled automatically.
--   function cat:get_sound()
--       if self.hungry then
--           return "Meowoooww!"
--       else
--           return "Meow!"
--   end
--   print(cat:new().sound) -- will print "Meow!"
-- Methods can be changed at run-time:
--   function cat:mew() print("Wow"); end
--   my_cat = cat:new()
--   function cat:mew() print("Meow!"); end
--   my_cat:mew() -- will print "Meow!", not "Wow"
-- That's about it, really.

local rawget, rawset
    = rawget, rawset

-- This is the implementation for __index for class instances.
local function clsget(cls, k, inst)
    -- Look in the class table.
    local v = rawget(cls, k)
    if v then return v; end
    -- Look for getter function.
    if type(k) == "string" then
        v = rawget(cls, "get_"..k)
        if v then return v(inst); end
    end
    -- Look in parent classes.
    for i, x in ipairs(cls.__super) do
        v = clsget(x, k, inst)
        if v then return v; end
    end
end

-- This implements the "new" method for classes.
local function class_new(cls, ...)
    -- Create the instance.
    local inst = {}
    -- NOTE: creating closures means the metatable can't be transplanted.
    setmetatable(inst,
      setmetatable({
        -- The __index metamethod for instances.
        __index = function(self, k)
            return clsget(cls, k, self)
        end,
        -- The __newindex metamethod for instances.
        __newindex = function(self, k, v)
            -- Look for a setter function.
            if type(k) == "string" then
                local f = self["set_"..k]
                if f then return f(self, v) end
            end
            return rawset(self, k, v)
        end,
      }, {
        -- Look for metamethods in the class.
        -- This __index is for the metatable, so that metamethods
        -- are "inherited" from parent classes.

        -- XXX: THIS DOESN'T WORK!
        __index = function(meta, k)
            return clsget(cls, k, inst)
        end,
      }))
    -- Call all the constructors.
    local function construct(cls, ...)
        for i, sup in ipairs(cls.__super) do construct(sup, ...) end
        local f = cls.__init
        if f then f(inst, ...) end
    end
    construct(cls, ...)
    return inst
end

-- class([parent1, [parent2, ...]]) -> class object
-- Create a new class, inheriting from the given parent classes.
local function class(...)
    local cls = {
        __super = {...}
    }
    cls.new = class_new
    --setmetatable(cls, class_meta)
    return cls
end

return class
