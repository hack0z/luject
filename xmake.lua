set_xmakever("2.3.2")

add_rules("mode.debug", "mode.release")
add_requires("libxmake", "lief")

if is_plat("windows") then 
    if is_mode("release") then
        add_cxflags("-MT") 
    elseif is_mode("debug") then
        add_cxflags("-MTd") 
    end
    add_cxxflags("-EHsc", "-FIiso646.h")
    add_ldflags("-nodefaultlib:msvcrt.lib")
end

target("luject")
    add_rules("xmake.cli")
    add_files("src/lni/*.cpp")
    set_languages("c++14")
    add_packages("libxmake", "lief")
    add_installfiles("res/*", {prefixdir = "share/luject/res"})

includes("tests")
