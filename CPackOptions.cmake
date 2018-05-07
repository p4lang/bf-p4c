
if (CPACK_GENERATOR MATCHES "TBZ2")
  set (CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}")
endif()


if (CPACK_GENERATOR MATCHES "DEB")
  # Debian packages
  execute_process (COMMAND uname -m OUTPUT_VARIABLE __machine_arch
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE rc)
  if (${__machine_arch} STREQUAL "x86_64")
    set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
  else()
    set (CPACK_DEBIAN_PACKAGE_ARCHITECTURE "i386")
  endif()
  set (CPACK_DEBIAN_PACKAGE_DEPENDS "cpp (>= 4.8), libboost-iostreams1.58.0, libgmp10, libgmpxx4ldbl, libgc1c2, libstdc++6, libc6, libbz2-1.0, libssl1.0.0, python (>= 2.7)")
endif()
