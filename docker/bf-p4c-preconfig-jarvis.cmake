# This file provides modified defaults for CMake when running in the Jarvis
# develompment image. It is picked up by boostrap_bfn_compilers.sh and passed to
# cmake using the -C option.
# This file must contain only set(... CACHE) entries that correspond to options
# present in the bf-p4c cmake (including its subprojects such as the p4c
# frontend).
set(BUILD_USE_COLOR ON CACHE BOOL "")
