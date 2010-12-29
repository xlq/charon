-- I actually wrote some tests!

local repr = require "charon.repr"

local ntests = 0
local nfail = 0
local function test(msg, fun)
    io.stdout:write("Testing ", msg, ": ")
    io.stdout:flush()
    local err
    if not xpcall(fun,
        function(e)
            err = debug.traceback(e, 2)
        end)
    then
        io.stdout:write("fail\n", err, "\n")
        nfail = nfail + 1
    else
        io.stdout:write("ok\n")
    end
    ntests = ntests + 1
end

-- Test equality of two values.
local function equal(a, b)
    if a ~= b then
        error("Expected \""..tostring(b).."\", got \""..tostring(a).."\"", 2)
    end
end

-- Test equality of two tables.
local function equal_tab(a, b)
    for k,v in pairs(a) do
        if b[k] ~= v then
            error("Expeted "..repr(b).."; got "..repr(a), 2)
        end
    end
    for k,v in pairs(b) do
        if a[k] == nil then
            error("Expeted "..repr(b).."; got "..repr(a), 2)
        end
    end
end

-- Test an iterator.
local function equal_iter(iter, ...)
    local t = {...}
    local i = 0
    for x in iter do
        i = i + 1
        if x ~= t[i] then
            error("At value "..i..", expected "..repr(t[i]).."; got "..repr(x), 2)
        end
    end
    assert(#t == i, "Iterator stopped too soon.")
end
        
do
    local partial = require "charon.partial"
    local function f(...)
        assert(select("#", ...) == 5, "Wrong number of values.")
        local a, b, c, d, e = ...
        assert(a == 1 and b == 2 and c == 3 and d == 4 and e == 5, "Wrong values.")
    end
    test("partial function application (1)", function() partial(f)(1, 2, 3, 4, 5)          end)
    test("partial function application (2)", function() partial(f, 1, 2)(3, 4, 5)          end)
    test("partial function application (3)", function() partial(partial(f, 1, 2), 3)(4, 5) end)
    test("partial function application (4)", function() partial(f, 1, 2, 3, 4, 5)()        end)
    test("partial function application, repeated", function()
        local p1 = partial(f, 1, 2, 3)
        p1(4, 5); p1(4, 5); p1(4, 5)
    end)
end

do
    local strings = require "charon.strings"
    test("strings.xsplit (1)", function()
        local bits = strings.xsplit("hello")
        equal(bits(), "hello")
        equal(bits(), nil)
    end)
    test("strings.xsplit (2)", function()
        local bits = strings.xsplit("hello   world test")
        equal(bits(), "hello")
        equal(bits(), "")
        equal(bits(), "")
        equal(bits(), "world")
        equal(bits(), "test")
        equal(bits(), nil)
    end)
    test("strings.xsplit (3)", function()
        local bits = strings.xsplit("hello   world test", " ", 2)
        equal(bits(), "hello")
        equal(bits(), "")
        equal(bits(), " world test")
        equal(bits(), nil)
    end)
    test("strings.starts_with", function()
        equal(strings.starts_with("lollipop", "lol"), true)
        equal(strings.starts_with("roflcopter", "lol"), false)
        equal(strings.starts_with("lollipop", "LOL"), false)
    end)
    test("strings.ends_with", function()
        equal(strings.ends_with("manslaughter", "laughter"), true)
        equal(strings.ends_with("Everybody watch this!", "success"), false)
        equal(strings.ends_with("manslaughter", "LAUGHTER"), false)
    end)
end

do
    local tables = require "charon.tables"
    test("tables.search with array", function()
        equal(tables.search({"a", "b", "c"}, "b"), 2)
        equal(tables.search({"a", false, true, 132.5}, 132.5), 4)
        equal(tables.search({"a", false, true, 132.5}, false), 2)
        equal(tables.search({"a", false, true, 132.5}, 132), nil)
    end)
    test("tables.search with hash", function()
        equal(tables.search({a=123, b=456}, 456), "b")
        equal(tables.search({[false]=150, [true]=false}, 150), false)
        equal(tables.search({[false]=150, [true]=false}, false), true)
        equal(tables.search({[false]=150, [true]=false}, true), nil)
        equal(tables.search({[false]=150, [true]=false}, nil), nil)
    end)
    test("tables.isearch with array", function()
        equal(tables.isearch({"a", "b", "c"}, "b"), 2)
        equal(tables.isearch({"a", false, true, 132.5}, 132.5), 4)
        equal(tables.isearch({"a", false, true, 132.5}, false), 2)
        equal(tables.isearch({"a", false, true, 132.5, useless=true}, 132), nil)
    end)
    test("tables.isearch with hash", function()
        equal(tables.isearch({a=123, b=456}, 456), nil)
        equal(tables.isearch({[false]=150, [true]=false}, 150), nil)
        equal(tables.isearch({[false]=150, [true]=false}, false), nil)
        equal(tables.isearch({[false]=150, [true]=false}, true), nil)
        equal(tables.isearch({[false]=150, [true]=false}, nil), nil)
    end)
    test("tables.copy", function()
        local a = {1, 2, 3, points="prizes"}
        local b = tables.copy(a)
        assert(a ~= b)
        equal_tab(a, b)
    end)
    test("tables.copy (deep)", function()
        local a = {1, 2, 3, points="prizes", next={}}
        local b = tables.copy(a)
        assert(a ~= b)
        equal_tab(b, a)
        assert(a.next == b.next)
    end)
    test("tables.icopy", function()
        local a = {1, 2, 3, h={}}
        local b = tables.icopy(a)
        assert(a ~= b)
        assert(#a == #b)
        assert(b.h == nil)
        a.h = nil
        equal_tab(b, a)
    end)
    test("tables.hcopy", function()
        local a = {1, 2, 3, {}, h=132}
        local b = tables.hcopy(a)
        assert(a ~= b)
        equal(#b, 0)
        equal(b.h, a.h)
    end)
    test("tables.compare", function()
        equal(tables.compare({1,2,3}, {1,2,3}), true)
        equal(tables.compare({1,2,3}, {1,2,4}), false)
        equal(tables.compare({h=4, 1,2,3}, {1,2,3, h=4}), true)
        do
            local a = {1, 2, nil, nil, 5}
            local b = {}
            b[1] = 1; b[2] = 2; b[5] = 5
            equal(tables.compare(a, b), true)
        end
    end)
    test("tables.is_empty", function()
        equal(tables.is_empty {}, true)
        equal(tables.is_empty {1}, false)
        equal(tables.is_empty {a=1}, false)
    end)
    test("tables.merge", function()
        do
            local a = {1, 2, 3, a=1, b=2}
            local b = {4, 5, 6, a=999, c=3}
            local c, cn = tables.merge(a, b, false, "LOL")
            assert(cn == #c)
            assert(c == a)
            equal_tab(a, {1, 2, 3, 4, 5, 6, false, "LOL", a=999, b=2, c=3})
        end
    end)
    test("tables.append", function()
        do
            local a = {1, 2, 3, a=1, b=2}
            local b = {4, 5, 6, a=999, c=3}
            local c = tables.append(a, b, false, "LOL")
            assert(c == a)
            equal_tab(a, {1, 2, 3, b, false, "LOL", a=1, b=2})
        end
    end)
end

do
    local repr = require "charon.repr"
    test("repr", function()
        local function try(x)
            equal_tab(loadstring("return " .. repr(x))(), x)
        end
        try {a=1, b=2, c=3}
        try {4, 5, nil, false}
        try {[false]=false, "lol", x=42}
    end)
end

do
    local path_manip = require "charon.path_manip"
    -- Force "/" pathsep for testing
    local old_pathsep = path_manip.pathsep
    path_manip.pathsep = "/"

    test("path_manip.splitext", function()
        equal_tab({path_manip.splitext("hello")}, {"hello", nil})
        equal_tab({path_manip.splitext("hello.c")}, {"hello", ".c"})
        equal_tab({path_manip.splitext("hello.c.o")}, {"hello.c", ".o"})
    end)

    test("path_manip.swapext", function()
        equal(path_manip.swapext("verboseware.ads", ".adb"), "verboseware.adb")
        equal(path_manip.swapext("tarbomb.tar.bz2", ".gz"), "tarbomb.tar.gz")
    end)

    test("path_manip.basename", function()
        equal(path_manip.basename("/usr/bin/fgfs"), "fgfs")
        equal(path_manip.basename("/usr/bin/fgfs.exe"), "fgfs.exe")
        equal(path_manip.basename("foo/bar.bletch"), "bar.bletch")
    end)

    test("path_manip.dirname", function()
        equal(path_manip.dirname("/usr/bin/fgfs"), "/usr/bin")
        equal(path_manip.dirname("/usr/bin/fgfs.exe"), "/usr/bin")
        equal(path_manip.dirname("foo/bar.bletch"), "foo")
        equal(path_manip.dirname("foo/foobl/urgh/bar.bletch"), "foo/foobl/urgh")
    end)

    test("path_manip.path", function()
        equal(path_manip.path("/usr", "bin", "fgfs.exe"), "/usr/bin/fgfs.exe")
        equal(path_manip.path("/usr", "/usr/bin", "fgfs.exe"), "/usr/bin/fgfs.exe")
        equal(path_manip.path("foo", "..", "bar"), "foo/../bar")
        equal(path_manip.path("foo/", "bar/", "a/b/"), "foo/bar/a/b")
    end)

    test("path_manip.is_abs", function()
        equal(path_manip.is_abs("/usr/bin/vim"), true)
        equal(path_manip.is_abs("rubbish/bin/emacs"), false)
    end)

    path_manip.pathsep = old_pathsep
end

do
    local iters = require "charon.iters"
    test("iters.iter", function()
        equal_iter(iters.iter{1,2,3}, 1,2,3)
        equal_iter(iters.iter{1,2,3,useless=true}, 1,2,3)
        equal_iter(iters.iter{1,2,3,useless=true}, 1,2,3)
        equal_iter(iters.iter(setmetatable({}, {__iter=function() return iters.iter{3,2,1}; end})), 3,2,1)
        equal_iter(iters.iter "Hello", "H","e","l","l","o")
    end)

    test("iters iterators", function()
        equal_iter(iters.ipairs {9,8,7,6}, 1,2,3,4)
        -- TODO: test pairs with unordered keys
        equal_iter(iters.ivalues {9,8,7,6}, 9,8,7,6)
        equal_iter(iters.chars "Oh no!", "O","h"," ","n","o","!")
        equal(iters.concat(iters.chars "Hello, world!"), "Hello, world!")
    end)

    test("iters.map", function()
        equal_iter(iters.map(function(x) return x*2; end, {9,8,7,6}), 18,16,14,12)
    end)

    test("iters.filter", function()
        equal_iter(iters.filter(function(x) return x%2==0; end, {9,8,7,6}), 8,6)
    end)

    test("iters.count", function()
        local i = 5
        equal(iters.count(function() i=i-1; return i>0 or nil; end), 4)
    end)

    test("iters.any", function()
        equal(iters.any {false, false, false, false}, false)
        equal(iters.any {false, false, true,  false}, true )
        equal(iters.any {true,  true,  true,  true }, true )
    end)

    test("iters.all", function()
        equal(iters.all {false, false, false, false}, false)
        equal(iters.all {false, false, true,  false}, false)
        equal(iters.all {true,  true,  true,  true }, true )
    end)

    test("iters.range", function()
        equal_iter(iters.range(5), 1,2,3,4,5)
        equal_iter(iters.range(9,5))
        equal_iter(iters.range(5,9), 5,6,7,8,9)
    end)

    test("iters.getter", function()
        equal_iter(iters.map(iters.getter("a"), {{a=1,b=2},{5,4,b=1,a=2},{}}), 1,2)
    end)
end

do
    local class = require "charon.class"

    test("method", function()
        local done
        local C = class()
        function C:moo() done = true; end
        done=false; C:moo(); assert(done)
        done=false; C:new():moo(); assert(done)
    end)

    test("constructor", function()
        local res
        local C = class()
        function C:__init() self.sound = "Moo!"; end
        function C:moo() res = self.sound; end
        res=nil; C:moo(); assert(res == nil)
        C:new():moo(); assert(res == "Moo!")
    end)

    test("inheritance (1)", function()
        local done
        local B = class()
        function B:doo() done = true; end
        local C = class(B)
        assert(C.doo == nil) -- This isn't implemented, it's too complicated ;)
        done=false; C:new():doo(); assert(done)
    end)

    test("inheritance (2)", function()
        local done
        local B = class()
        local C = class(B)
        function B:doo() done = true; end
        done=false; C:new():doo(); assert(done)
    end)

    test("overriding", function()
        local done
        local B = class()
        local C = class(B)
        function B:doo() done = 1; end
        function C:doo() done = 2; end
        done=nil; B:new():doo(); assert(done==1)
        done=nil; C:new():doo(); assert(done==2)
    end)

    test("overriding constructor", function()
        local doneB, doneC
        local B = class()
        local C = class(B)
        function B:__init(x) doneB = x; end
        function C:__init(x) doneC = x*2; end
        doneB=nil; doneC=nil; B:new(5); assert(doneB==5 and doneC==nil)
        doneB=nil; doneC=nil; C:new(5); assert(doneB==5 and doneC==10)
    end)

    test("metamethods", function()
        local B = class()
        function B:__tostring() return "Worked!"; end
        equal(tostring(B:new()), "Worked!")
    end)

    test("getters", function()
        local B = class()
        function B:get_greeting() return "hello"; end
        equal(B:new().greeting, "hello")
    end)

    test("setters", function()
        local done
        local B = class()
        function B:set_greeting(x) done = x; end
        B:new().greeting = "good afternoon"
        equal(done, "good afternoon")
    end)

    test("inherited getters", function()
        local B = class()
        function B:get_greeting() return "hello"; end
        equal(class(B):new().greeting, "hello")
    end)

    test("inherited setters", function()
        local done
        local B = class()
        function B:set_greeting(x) done = x; end
        class(B):new().greeting = "good afternoon"
        equal(done, "good afternoon")
    end)
end


print(string.format("Summary: %d/%d tests succeeded.", ntests-nfail, ntests))
