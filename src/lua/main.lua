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
import("core.project.config")
import("utils.archive")
import("utils.ipa.resign", {alias = "ipa_resign"})
import("private.tools.codesign")
import("detect.sdks.find_xcode")
import("lib.detect.find_tool")
import("lib.detect.find_program")
import("lib.detect.find_directory")
import("lib.lni.pe")
import("lib.lni.elf")
import("lib.lni.macho")

-- the options
local options =
{
    {'i', "input",     "kv", nil, "Set the input program path."}
,   {'o', "output",    "kv", nil, "Set the output program path."}
,   {'p', "pattern",   "kv", nil, "Inject to the libraries given pattern (only for apk).",
                                  "  e.g. ",
                                  "    - luject -i app.apk -p libtest liba.so",
                                  "    - luject -i app.apk -p 'libtest_*' liba.so"}

,   {nil, "bundle_identifier", "kv", nil, "Set the bundle identifier of app/ipa"}
,   {nil, "codesign_identity", "kv", nil, "Set the codesign identity for app/ipa"}
,   {nil, "mobile_provision",  "kv", nil, "Set the mobile provision for app/ipa"}
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

-- get jarsigner
function _get_jarsigner()
    local java_home = assert(os.getenv("JAVA_HOME"), "$JAVA_HOME not found!")
    local jarsigner = path.join(java_home, "bin", "jarsigner" .. (is_host("windows") and ".exe" or ""))
    assert(os.isfile(jarsigner), "%s not found!", jarsigner)
    return jarsigner
end

-- get zipalign
function _get_zipalign(apkfile)
    return find_program("zipalign", {check = function (program) assert(os.execv(program, {"-c", "4", apkfile}, {try = true}) ~= nil) end})
end

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

-- resign apk
function _resign_apk(inputfile, outputfile)

    -- trace
    cprint("${magenta}resign %s", path.filename(inputfile))

    -- do resign
    local jarsigner = _get_jarsigner()
    local alias = "test"
    local storepass = "1234567890"
    local argv = {"-keystore", path.join(_get_resources_dir(), "sign.keystore"), "-signedjar", outputfile, "-digestalg", "SHA1", "-sigalg", "MD5withRSA", inputfile, alias, "--storepass", storepass}
    if option.get("verbose") then
        table.insert(argv, "-verbose")
    end
    os.vrunv(jarsigner, argv)
end

-- resign app
function _resign_app(appdir)

    -- trace
    cprint("${magenta}resign %s", path.filename(appdir))

    -- find xcode for codesign_allocate
    local xcode = find_xcode(nil, {verbose = option.get("verbose")})
    if xcode then
        config.set("xcode", xcode.sdkdir, {force = true, readonly = true})
    end

    -- do resign
    ipa_resign(appdir, option.get("codesign_identity"), option.get("mobile_provision"), option.get("bundle_identifier"))
end 

-- optimize apk
function _optimize_apk(apkfile)
    local zipalign = _get_zipalign(apkfile)
    if zipalign then

        -- trace
        cprint("${magenta}optimize %s", path.filename(apkfile))

        -- do optimize
        local tmpfile = os.tmpfile()
        os.vrunv(zipalign, {"-f", "-v", "4", apkfile, tmpfile})
        os.cp(tmpfile, apkfile)
        os.tryrm(tmpfile)
    end
end

-- do inject for apk program
function _inject_apk(inputfile, outputfile, libraries)

    -- get zip
    local zip = assert(find_tool("zip"), "zip not found!")

    -- get the tmp directory
    local tmpdir = path.join(os.tmpdir(inputfile), path.basename(inputfile) .. ".tmp")
    local tmpapk = path.join(os.tmpdir(inputfile), path.basename(inputfile) .. ".apk")
    os.tryrm(tmpdir)
    os.tryrm(tmpapk)

    -- trace
    print("extract %s", path.filename(inputfile))
    vprint(" -> %s", tmpdir)

    -- extract apk
    if not archive.extract(inputfile, tmpdir, {extension = ".zip"}) then
        raise("extract failed!")
    end

    -- remove META-INF
    os.tryrm(path.join(tmpdir, "META-INF"))

    -- get arch and library directory
    local arch = "armeabi-v7a"
    local result = try {function () return os.iorunv("file", {inputfile}) end}
    if result and result:find("aarch64", 1, true) then
        arch = "arm64-v8a"
    end
    local libdir = path.join(tmpdir, "lib", arch)
    if not os.isdir(libdir) then
        arch = "armeabi"
        libdir = path.join(tmpdir, "lib", arch)
    end
    assert(os.isdir(libdir), "%s not found!", libdir)

    -- inject libraries to 'lib/arch/*.so'
    local libnames = {}
    for _, library in ipairs(libraries) do
        table.insert(libnames, path.filename(library))
    end
    for _, libfile in ipairs(os.files(path.join(libdir, (option.get("pattern") or "*") .. ".so"))) do
        print("inject to %s", path.filename(libfile))
        elf.add_libraries(libfile, libfile, libnames)
    end

    -- copy libraries to 'lib/arch/'
    for _, library in ipairs(libraries) do
        assert(os.isfile(library), "%s not found!", library)
        print("install %s", path.filename(library))
        os.cp(library, libdir)
    end

    -- archive apk
    local zip_argv = {"-r"}
    table.insert(zip_argv, tmpapk)
    table.insert(zip_argv, ".")
    os.cd(tmpdir)
    os.vrunv(zip.program, zip_argv)
    os.cd("-")

    -- resign apk
    _resign_apk(tmpapk, outputfile)

    -- optimize apk
    _optimize_apk(outputfile)
end

-- do inject for app program
function _inject_app(inputfile, outputfile, libraries)

    -- check
    assert(is_host("macosx"), "inject ipa only support for macOS!")

    -- get .app directory
    os.tryrm(outputfile)
    os.cp(inputfile, outputfile)
    local appdir = outputfile

    -- @note remove code signature first
    codesign.unsign(appdir)

    -- get binary
    local binaryfile
    for _, filepath in ipairs(os.files(path.join(appdir, "**"))) do
        local results = try { function () return os.iorunv("file", {filepath}) end}
        if results and results:find("Mach-O", 1, true) then
            binaryfile = filepath
            break
        end
    end
    assert(binaryfile, "image file not found!")

    -- inject libraries to the image file
    local libnames = {}
    for _, library in ipairs(libraries) do
        table.insert(libnames, "@loader_path/" .. path.filename(library))
    end
    print("inject to %s", path.filename(binaryfile))
    macho.add_libraries(binaryfile, binaryfile, libnames)

    -- resign app
    _resign_app(appdir)

    -- copy libraries to .app directory
    for _, library in ipairs(libraries) do
        assert(os.isfile(library), "%s not found!", library)
        print("install %s", path.filename(library))
        os.cp(library, path.directory(binaryfile))
    end
end

-- do inject for ipa program
function _inject_ipa(inputfile, outputfile, libraries)

    -- check
    assert(is_host("macosx"), "inject ipa only support for macOS!")

    -- get zip
    local zip = assert(find_tool("zip"), "zip not found!")

    -- get the tmp directory
    local tmpdir = path.join(os.tmpdir(inputfile), path.basename(inputfile) .. ".tmp")
    local tmpipa = path.join(os.tmpdir(inputfile), path.basename(inputfile) .. ".ipa")
    os.tryrm(tmpdir)
    os.tryrm(tmpipa)

    -- trace
    print("extract %s", path.filename(inputfile))
    vprint(" -> %s", tmpdir)

    -- extract ipa
    if not archive.extract(inputfile, tmpdir, {extension = ".zip"}) then
        raise("extract failed!")
    end

    -- get .app directory
    local appdir = find_directory("Payload/*.app", tmpdir)

    -- @note remove code signature first
    codesign.unsign(appdir)

    -- get binary
    local binaryfile
    for _, filepath in ipairs(os.files(path.join(appdir, "*"))) do
        local results = try { function () return os.iorunv("file", {filepath}) end}
        if results and results:find("Mach-O", 1, true) then
            binaryfile = filepath
            break
        end
    end
    assert(binaryfile, "image file not found!")

    -- inject libraries to the image file
    local libnames = {}
    for _, library in ipairs(libraries) do
        table.insert(libnames, "@loader_path/" .. path.filename(library))
    end
    print("inject to %s", path.filename(binaryfile))
    macho.add_libraries(binaryfile, binaryfile, libnames)

    -- copy libraries to .app directory
    for _, library in ipairs(libraries) do
        assert(os.isfile(library), "%s not found!", library)
        print("install %s", path.filename(library))
        os.cp(library, path.directory(binaryfile))
    end

    -- resign app
    _resign_app(appdir)

    -- archive ipa
    local zip_argv = {"-r"}
    table.insert(zip_argv, outputfile)
    table.insert(zip_argv, ".")
    os.cd(tmpdir)
    os.vrunv(zip.program, zip_argv)
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
    elseif inputfile:endswith(".app") then
        _inject_app(inputfile, outputfile, libraries)
    else
        local result = try {function () return os.iorunv("file", {inputfile}) end}
        if result and result:find("ELF", 1, true) then
            _inject_elf(inputfile, outputfile, libraries)
        elseif result and result:find("Mach-O", 1, true) then
            _inject_macho(inputfile, outputfile, libraries)
        end
    end
end

-- init options
function _init_options()

    -- parse arguments
    local argv = option.get("arguments") or {}
    option.save()
    local opts = option.parse(argv, options, "Statically inject dynamic library to the given program."
                                           , ""
                                           , "Usage: luject [options] libraries")

    -- save options
    for name, value in pairs(opts) do
        option.set(name, value)
    end
end

-- the main entry
function main ()

    -- init options
    _init_options()

    -- show help
    local help = option.get("help")
    local inputfile = option.get("input")
    local libraries = option.get("libraries")
    if not inputfile or not libraries then
        return help()
    end

    -- get input file
    assert(os.exists(inputfile), "%s not found!", inputfile)

    -- get output file
    local outputfile = option.get("output")
    if not outputfile then
        outputfile = path.join(path.directory(inputfile), path.basename(inputfile) .. "_injected" .. path.extension(inputfile))
    end

    -- do inject
    _inject(inputfile, outputfile, libraries)

    -- trace
    cprint("${bright green}inject ok!")
    cprint("${yellow}  -> ${clear bright}%s", outputfile)
end
