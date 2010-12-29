#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

static int inner(lua_State *L)
{
    int i, nup, narg;
    narg = lua_gettop(L); /* Number of arguments passed. */
    nup = lua_tointeger(L, lua_upvalueindex(1)); /* Number of arguments already got, plus the function. */
    /* Upvalue 1 is count of remaining upvalues.
       Upvalue 2 is the function.
       Upvalues 3..nup+1 are arguments. */
    luaL_checkstack(L, narg+nup, NULL);
    for (i=2; i<=nup+1; ++i){
        lua_pushvalue(L, lua_upvalueindex(i));
        lua_insert(L, i-1);
    }
    lua_call(L, lua_gettop(L)-1, LUA_MULTRET);
    return lua_gettop(L);
}

static int partial(lua_State *L)
{
    lua_pushinteger(L, lua_gettop(L));
    lua_insert(L, 1);
    lua_pushcclosure(L, inner, lua_gettop(L));
    return 1;
}

LUALIB_API int luaopen_charon_partial(lua_State *L)
{
    lua_pushcfunction(L, partial);
    return 1;
}
