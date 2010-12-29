----- FILESYSTEM PATH MANIPULATIONS -----

local path_manip = {}
local strings

path_manip.pathsep = require "package".config:match "^([^\n])\n"

-- Return base, ext from a filename
function path_manip.splitext(fname)
    local base, ext = fname:match("^(.*)(%.[^%.]+)$")
    if not base then return fname;
    else return base, ext; end
end

-- Return fname with extension swapped for newext
-- eg. swapext("foo.c", ".o") == "foo.o"
-- eg. swapext("foo", ".o") == "foo.o"
function path_manip.swapext(fname, newext)
    return path_manip.splitext(fname) .. newext
end

-- Return just the file portion of a path
-- eg. basename("a/b/foo.o") == "foo.o"
function path_manip.basename(path)
    return path:match("[^"..path_manip.pathsep.."]*$")
end

-- Return just the directory portion of a path
-- eg. dirname("a/b/foo.o") == "a/b"
function path_manip.dirname(path)
    local s = path_manip.pathsep
    return path:match("^(.*)"..s.."[^"..s.."]*$")
end

-- Join bits of pathname (like Python's os.path.join)
-- eg. path("a", "b/c") == "a/b/c"
-- eg. path("a", "/b") == "/b"
function path_manip.path(...)
    local s = ""
    local sep = path_manip.pathsep
    for _, v in ipairs({...}) do
        if v:sub(1,1) == sep then s = v -- Start at filesystem root
        else
            if #s > 0 then s = s .. sep; end
            s = s .. v
            if s:sub(-1) == sep then
                s = s:sub(1,-2) -- remove trailing '/'
            end
        end
    end
    return s
end

-- Return true if path is absolute
function path_manip.is_abs(path)
    if not strings then strings = require "charon.strings"; end
    return strings.starts_with(path, path_manip.pathsep) -- POSIX
        or path:sub(2,3) == ":\\" -- Windows
end

return path_manip
