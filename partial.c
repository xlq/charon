#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

static int inner(lua_State *L)
{
    /* Stack: b[1] b[2] b[3] ... b[bn]
       Upvalues: an f a[1] a[2] a[3] ... a[an] */
    int an = lua_tointeger(L, lua_upvalueindex(1));
    int bn = lua_gettop(L);
    int i;

    /* We need space for all the arguments, and the function. */
    luaL_checkstack(L, an + bn + 1, NULL);
    lua_settop(L, an + bn + 1);

    /* Copy b[1..bn] to the correct places. */
    for (i=bn; i>=1; --i)
        lua_copy(L, i, i + an + 1);

    /* Copy f, a[1..an]. */
    for (i=0; i<=an; ++i)
        lua_copy(L, lua_upvalueindex(i + 2), i + 1);

    /* Call f, passing the entire stack (except f itself). */
    lua_call(L, lua_gettop(L) - 1, LUA_MULTRET);

    /* Return everything f returned. */
    return lua_gettop(L);
}

static int partial(lua_State *L)
{
    lua_pushinteger(L, lua_gettop(L)-1);
    lua_insert(L, 1);
    lua_pushcclosure(L, inner, lua_gettop(L));
    return 1;
}

LUALIB_API int luaopen_charon_partial(lua_State *L)
{
    lua_pushcfunction(L, partial);
    return 1;
}
