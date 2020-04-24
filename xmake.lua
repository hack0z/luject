set_xmakever("2.3.2")

add_rules("mode.debug", "mode.release")
add_requires("libxmake", "lief")

target("luject")
    add_rules("xmake.cli")
    add_files("src/lni/*.cpp")
    set_languages("c++11")
    add_packages("libxmake", "lief")

includes("tests")
