--!A static injector of dynamic library for application
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2020-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        main.lua
--
import("core.base.option")
import("lib.lni.elf")

-- the options
local options =
{
    {'i', "input",     "kv", nil, "Set the input program path."}
,   {'o', "output",    "kv", nil, "Set the output program path."}
,   {nil, "libraries", "v",  nil, "Set all injected dynamic libraries path list."}
}

-- the main entry
function main ()

    -- parse arguments
    local argv = option.get("arguments") or {}
    local opts = option.parse(argv, options, "Statically inject dynamic library to the given program."
                                           , ""
                                           , "Usage: luject [options] libraries")
    if not opts.input or not opts.libraries then
        opts.help()
        return
    end
end
