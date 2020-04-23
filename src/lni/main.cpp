/*!A dynamic library injector for application
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
// elf.add_library("libx.so", "liby.so")
static tb_int_t lni_elf_add_library(lua_State* lua)
{
    lua_pushliteral(lua, "hello xmake!");
    std::unique_ptr<LIEF::ELF::Binary const> elf_binary;
    try 
    {
        elf_binary = std::unique_ptr<const LIEF::ELF::Binary>{LIEF::ELF::Parser::parse("")};
    }
    catch (LIEF::exception const&) 
    {
    }
    return 1;
}
static tb_void_t lni_initalizer(xm_engine_ref_t engine, lua_State* lua)
{
    // register elf module
    static luaL_Reg const lni_elf_funcs[] = 
    {
        {"add_library", lni_elf_add_library}
    ,   {tb_null, tb_null}
    };
    xm_engine_register(engine, "elf", lni_elf_funcs);
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
    return xm_engine_run_lua("app_injector", argc, argv, lni_initalizer, luaopts);
}
