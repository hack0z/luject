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
import("utils.archive")
import("lib.detect.find_tool")
import("lib.lni.pe")
import("lib.lni.elf")
import("lib.lni.macho")

-- the options
local options =
{
    {'i', "input",     "kv", nil, "Set the input program path."}
,   {'o', "output",    "kv", nil, "Set the output program path."}
,   {'v', "verbose",   "k",  nil, "Enable verbose output."}
,   {nil, "libraries", "vs", nil, "Set all injected dynamic libraries path list."}
}

-- get resources directory
function _get_resources_dir()
    local resourcesdir = path.join(os.scriptdir(), "..", "..", "res")
    if not os.isdir(resourcesdir) then
        resourcesdir = path.join(os.programdir(), "res")
    end
    assert(resourcesdir, "the resources directory not found!")
    return resourcesdir
end

-- do inject for elf program
function _inject_elf(inputfile, outputfile, libraries, opts)
    elf.add_libraries(inputfile, outputfile, libraries)
end

-- do inject for macho program
function _inject_macho(inputfile, outputfile, libraries, opts)
    macho.add_libraries(inputfile, outputfile, libraries)
end

-- do inject for pe program
function _inject_pe(inputfile, outputfile, libraries, opts)
    pe.add_libraries(inputfile, outputfile, libraries)
end

-- do inject for apk program
function _inject_apk(inputfile, outputfile, libraries, opts)

    -- get zip
    local zip = assert(find_tool("zip"), "zip not found!")

    -- get the tmp directory
    local tmpdir = path.join(os.tmpdir(inputfile), path.filename(inputfile) .. ".tmp")
    os.tryrm(tmpdir)

    -- trace
    print("extract %s", path.filename(inputfile))
    if opts.verbose then
        print(" -> %s", tmpdir)
    end

    -- extract apk
    if archive.extract(inputfile, tmpdir, {extension = ".zip"}) then

        -- get arch and library directory
        local arch = "armeabi-v7a"
        local result = try {function () return os.iorunv("file", {inputfile}) end}
        if result and result:find("aarch64", 1, true) then
            arch = "arm64-v8a"
        end
        local libdir = path.join(tmpdir, "lib", arch)
        assert(os.isdir(libdir), "%s not found!", libdir)

        -- inject libraries to 'lib/arch/*.so'
        local libnames = {}
        for _, library in ipairs(libraries) do
            table.insert(libnames, path.filename(library))
        end
        for _, libfile in ipairs(os.files(path.join(libdir, "*.so"))) do
            print("inject to %s", path.filename(libfile))
            elf.add_libraries(libfile, libfile, libnames)
        end

        -- copy libraries to 'lib/arch/'
        for _, library in ipairs(libraries) do
            assert(os.isfile(library), "%s not found!", library)
            print("install %s", path.filename(library))
            os.cp(library, libdir)
        end
    end

    -- archive apk
    local zip_argv = {"-r"}
    local run = (opts.verbose and os.execv or os.runv)
    table.insert(zip_argv, outputfile)
    table.insert(zip_argv, ".")
    os.cd(tmpdir)
    run(zip.program, zip_argv)
    os.cd("-")
end

-- do inject for ipa program
function _inject_ipa(inputfile, outputfile, libraries, opts)
    print("not implement!")
end

-- do inject
function _inject(inputfile, outputfile, libraries, opts)
    if inputfile:endswith(".so") then
        _inject_elf(inputfile, outputfile, libraries, opts)
    elseif inputfile:endswith(".dylib") then
        _inject_macho(inputfile, outputfile, libraries, opts)
    elseif inputfile:endswith(".exe") then
        _inject_pe(inputfile, outputfile, libraries, opts)
    elseif inputfile:endswith(".dll") then
        _inject_pe(inputfile, outputfile, libraries, opts)
    elseif inputfile:endswith(".apk") then
        _inject_apk(inputfile, outputfile, libraries, opts)
    elseif inputfile:endswith(".ipa") then
        _inject_ipa(inputfile, outputfile, libraries, opts)
    else
        local result = try {function () return os.iorunv("file", {inputfile}) end}
        if result and result:find("ELF", 1, true) then
            _inject_elf(inputfile, outputfile, libraries, opts)
        elseif result and result:find("Mach-O", 1, true) then
            _inject_macho(inputfile, outputfile, libraries, opts)
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
    _inject(inputfile, outputfile, libraries, opts)

    -- trace
    cprint("${bright green}inject ok!")
    cprint("${yellow}  -> ${clear bright}%s", outputfile)
end
