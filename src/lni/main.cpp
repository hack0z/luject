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
    std::unique_ptr<LIEF::PE::Binary const> pe_binary;
    try 
    {
        pe_binary = std::unique_ptr<LIEF::PE::Binary const>{LIEF::PE::Parser::parse("")};
    }
    catch (LIEF::exception const&) 
    {
    }
    lua_pushboolean(lua, tb_true);
    return 1;
}

// elf.add_libraries("libx.so", {"liba.so", "libb.so"})
static tb_int_t lni_elf_add_libraries(lua_State* lua)
{
    std::unique_ptr<LIEF::ELF::Binary const> elf_binary;
    try 
    {
        elf_binary = std::unique_ptr<LIEF::ELF::Binary const>{LIEF::ELF::Parser::parse("")};
    }
    catch (LIEF::exception const&) 
    {
    }
    lua_pushboolean(lua, tb_true);
    return 1;
}

// macho.add_libraries("libx.so", {"liba.dylib", "libb.dylib"})
static tb_int_t lni_macho_add_libraries(lua_State* lua)
{
    std::unique_ptr<LIEF::MachO::FatBinary const> macho_binary;
    try 
    {
        macho_binary = std::unique_ptr<LIEF::MachO::FatBinary const>{LIEF::MachO::Parser::parse("")};
    }
    catch (LIEF::exception const&) 
    {
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
