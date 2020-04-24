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
import("lib.lni.pe")
import("lib.lni.elf")
import("lib.lni.macho")

-- the options
local options =
{
    {'i', "input",     "kv", nil, "Set the input program path."}
,   {'o', "output",    "kv", nil, "Set the output program path."}
,   {nil, "libraries", "vs", nil, "Set all injected dynamic libraries path list."}
}

-- do inject for elf program
function _inject_elf(inputfile, outputfile, libraries)
    elf.add_libraries(inputfile, outputfile, libraries)
end

-- do inject for macho program
function _inject_macho(inputfile, outputfile, libraries)
    macho.add_libraries(inputfile, outputfile, libraries)
end

-- do inject for pe program
function _inject_pe(inputfile, outputfile, libraries)
    pe.add_libraries(inputfile, outputfile, libraries)
end

-- do inject for apk program
function _inject_apk(inputfile, outputfile, libraries)
    print("not implement!")
end

-- do inject for ipa program
function _inject_ipa(inputfile, outputfile, libraries)
    print("not implement!")
end

-- do inject
function _inject(inputfile, outputfile, libraries)
    if inputfile:endswith(".so") then
        _inject_elf(inputfile, outputfile, libraries)
    elseif inputfile:endswith(".dylib") then
        _inject_macho(inputfile, outputfile, libraries)
    elseif inputfile:endswith(".exe") then
        _inject_pe(inputfile, outputfile, libraries)
    elseif inputfile:endswith(".dll") then
        _inject_pe(inputfile, outputfile, libraries)
    elseif inputfile:endswith(".apk") then
        _inject_apk(inputfile, outputfile, libraries)
    elseif inputfile:endswith(".ipa") then
        _inject_ipa(inputfile, outputfile, libraries)
    else
        local result = try {function () return os.iorunv("file", {inputfile}) end}
        if result and result:find("ELF", 1, true) then
            _inject_elf(inputfile, outputfile, libraries)
        elseif result and result:find("Mach-O", 1, true) then
            _inject_macho(inputfile, outputfile, libraries)
        end
    end
end

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

    -- get input file
    local inputfile = opts.input
    assert(os.isfile(inputfile), "%s not found!", inputfile)

    -- get output file
    local outputfile = opts.output
    if not outputfile then
        outputfile = path.join(path.directory(inputfile), path.basename(inputfile) .. "_injected" .. path.extension(inputfile))
    end

    -- get libraries
    local libraries = opts.libraries

    -- do inject
    _inject(inputfile, outputfile, libraries)

    -- trace
    cprint("${bright green}inject ok!")
    cprint("${yellow}  -> ${clear bright}%s", outputfile)
end
