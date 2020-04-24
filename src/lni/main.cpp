/*!A static injector of dynamic library for application
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2020-present, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        main.cpp
 *
 */
/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include <xmake/xmake.h>
#include <LIEF/LIEF.hpp>

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implemention
 */

// pe.add_libraries("x.dll", {"a.dll", "b.dll"})
static tb_int_t lni_pe_add_libraries(lua_State* lua)
{
    try 
    {
        // get arguments
        tb_char_t const* inputfile = luaL_checkstring(lua, 1);
        tb_char_t const* outputfile = luaL_checkstring(lua, 2);
        if (!inputfile || !outputfile || !lua_istable(lua, 3)) throw "invalid arguments!";

        // add libraries 
        tb_size_t n = lua_objlen(lua, 3);
        if (n > 0)
        {
            auto pe_binary = std::unique_ptr<LIEF::PE::Binary>{LIEF::PE::Parser::parse(inputfile)};
            for (tb_size_t i = 1; i <= n; i++)
            {
                lua_pushnumber(lua, (tb_int_t)i);
                lua_rawget(lua, 3);
                tb_char_t const* library = luaL_checkstring(lua, -1);
                if (library) pe_binary->add_library(library);
                lua_pop(lua, 1);
            }
            pe_binary->write(outputfile);
        }
    }
    catch (std::exception const& e) 
    {
        lua_pushboolean(lua, tb_false);
        lua_pushstring(lua, e.what());
        return 2;
    }
    lua_pushboolean(lua, tb_true);
    return 1;
}

// elf.add_libraries("libx.so", {"liba.so", "libb.so"})
static tb_int_t lni_elf_add_libraries(lua_State* lua)
{
    try 
    {
        // get arguments
        tb_char_t const* inputfile = luaL_checkstring(lua, 1);
        tb_char_t const* outputfile = luaL_checkstring(lua, 2);
        if (!inputfile || !outputfile || !lua_istable(lua, 3)) throw "invalid arguments!";

        // add libraries 
        tb_size_t n = lua_objlen(lua, 3);
        if (n > 0)
        {
            auto elf_binary = std::unique_ptr<LIEF::ELF::Binary>{LIEF::ELF::Parser::parse(inputfile)};
            for (tb_size_t i = 1; i <= n; i++)
            {
                lua_pushnumber(lua, (tb_int_t)i);
                lua_rawget(lua, 3);
                tb_char_t const* library = luaL_checkstring(lua, -1);
                if (library) elf_binary->add_library(library);
                lua_pop(lua, 1);
            }
            elf_binary->write(outputfile);
        }
    }
    catch (std::exception const& e) 
    {
        lua_pushboolean(lua, tb_false);
        lua_pushstring(lua, e.what());
        return 2;
    }
    lua_pushboolean(lua, tb_true);
    return 1;
}

// macho.add_libraries("libx.so", {"liba.dylib", "libb.dylib"})
static tb_int_t lni_macho_add_libraries(lua_State* lua)
{
    try 
    {
        // get arguments
        tb_char_t const* inputfile = luaL_checkstring(lua, 1);
        tb_char_t const* outputfile = luaL_checkstring(lua, 2);
        if (!inputfile || !outputfile || !lua_istable(lua, 3)) throw "invalid arguments!";

        // add libraries 
        tb_size_t n = lua_objlen(lua, 3);
        if (n > 0)
        {
            auto macho_binary = std::unique_ptr<LIEF::MachO::FatBinary>{LIEF::MachO::Parser::parse(inputfile)};
            for (auto it = macho_binary->begin(); it != macho_binary->end(); ++it)
            {
                for (tb_size_t i = 1; i <= n; i++)
                {
                    lua_pushnumber(lua, (tb_int_t)i);
                    lua_rawget(lua, 3);
                    tb_char_t const* library = luaL_checkstring(lua, -1);
                    if (library) it->add_library(library);
                    lua_pop(lua, 1);
                }
            }
            macho_binary->write(outputfile);
        }
    }
    catch (std::exception const& e) 
    {
        lua_pushboolean(lua, tb_false);
        lua_pushstring(lua, e.what());
        return 2;
    }
    lua_pushboolean(lua, tb_true);
    return 1;
}

// lni initalizer
static tb_void_t lni_initalizer(xm_engine_ref_t engine, lua_State* lua)
{
    // register pe module
    static luaL_Reg const lni_pe_funcs[] = 
    {
        {"add_libraries", lni_pe_add_libraries}
    ,   {tb_null, tb_null}
    };
    xm_engine_register(engine, "pe", lni_pe_funcs);

    // register elf module
    static luaL_Reg const lni_elf_funcs[] = 
    {
        {"add_libraries", lni_elf_add_libraries}
    ,   {tb_null, tb_null}
    };
    xm_engine_register(engine, "elf", lni_elf_funcs);

    // register macho module
    static luaL_Reg const lni_macho_funcs[] = 
    {
        {"add_libraries", lni_macho_add_libraries}
    ,   {tb_null, tb_null}
    };
    xm_engine_register(engine, "macho", lni_macho_funcs);
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implemention
 */
tb_int_t main(tb_int_t argc, tb_char_t** argv)
{
#ifdef __tb_debug__
    tb_char_t const* luaopts = "-vD";
#else
    tb_char_t const* luaopts = "-D";
#endif
    return xm_engine_run_lua("luject", argc, argv, lni_initalizer, luaopts);
}
