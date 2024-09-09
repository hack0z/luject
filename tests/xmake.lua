target("sub")
    set_default(false)
    add_deps("luject")
    set_kind("shared")
    add_files("sub.c")

target("add")
    set_default(false)
    add_deps("sub", {inherit = false})
    set_kind("shared")
    add_files("add.c")
    after_build(function (target, opt)
        import("utils.progress")
        progress.show(opt.progress, "injecting.$(mode) %s", path.filename(target:dep("sub"):targetfile()))
        local luject = target:dep("luject")
        os.setenv("XMAKE_MODULES_DIR", path.join(luject:scriptdir(), "src"))
        os.setenv("XMAKE_PROGRAM_DIR", path.join(path.directory(luject:pkg("libxmake"):get("linkdirs")), "share", "xmake"))

        -- inject libsub to libadd
        local rpathdir = ""
        if is_plat("linux", "android") then
            rpathdir = "$ORIGIN/"
        elseif is_plat("macosx", "iphoneos") then
            rpathdir = "@loader_path/"
        end
        os.vrunv(luject:targetfile(), {"-i", target:targetfile(), "-o", target:targetfile(), rpathdir .. path.filename(target:dep("sub"):targetfile())})
    end)

target("test")
    set_default(false)
    set_kind("binary")
    add_deps("add")
    add_deps("sub", {inherit = false}) -- we only add libadd/rpath to test
    add_files("test.c")

