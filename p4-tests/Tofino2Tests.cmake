# These are tests for Tofino2 variants (2H, 2M, 2U)
# we run only a the p4-16 example tests (tna_*)
set (jbay_variants "tofino2h" "tofino2m" "tofino2u")

# check for PTF requirements
packet_test_setup_check("jbay")

# set (P16_JNA_INCLUDE_PATTERNS "include.*(t2na).p4" "main")
set (P16_TOFINO_VARIANTS_EXCLUDE "tna_32q_multiprogram")
## P4-16 Programs
set(__p4_16_path "${CMAKE_CURRENT_SOURCE_DIR}/p4-programs/p4_16_programs")
file (GLOB __p4_16_tests RELATIVE ${__p4_16_path} "${__p4_16_path}/tna_*")
list(REMOVE_ITEM __p4_16_tests ${P16_TOFINO_VARIANTS_EXCLUDE})

# P4-16 Programs with PTF tests
foreach(v IN LISTS jbay_variants)
  set (${v}_timeout 600)
  set (__t2na_compile_args "--target ${v} --arch t2na -I${__p4_16_path}")
  foreach(t IN LISTS __p4_16_tests)
    set(__alias "p4_16_programs_${t}")
    if (PTF_REQUIREMENTS_MET AND EXISTS ${__p4_16_path}/${t}/test.py)
      p4c_add_ptf_test_with_ptfdir (${v} ${__alias} "${__p4_16_path}/${t}/${t}.p4"
        "${__t2na_compile_args} -target ${v} -arch t2na -bfrt -to 2000" "${__p4_16_path}/${t}")
      set (ports_json ${__p4_16_path}/${t}/ports.json)
      if (EXISTS ${ports_json})
        bfn_set_ptf_ports_json_file(${v} ${__alias} ${ports_json})
      endif()
      # p4-build does not know about these new targets, so we force the flags on the compiler
      bfn_set_p4_build_flag(${v} ${__alias} "-I${__p4_16_path} --target ${v} --arch t2na")
    else()
      file(RELATIVE_PATH __p ${P4C_SOURCE_DIR} ${__p4_16_path})
      p4c_add_test_with_args (${v} ${P4C_RUNTEST} FALSE ${__alias} "${__p}/${t}/${t}.p4"
        "${__t2na_compile_args}" "-target ${v} -norun")
    endif()
  endforeach()
endforeach()
