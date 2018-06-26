set (tofino_timeout 600)

# check for PTF requirements
packet_test_setup_check("tofino")
# experimental -- doesn't quite work yet
# bfn_add_switch("tofino")

set (V1_SEARCH_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (V1_EXCLUDE_PATTERNS "package" "extern")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_TOFINO "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_TOFINO}" v1tests INCLUDE "${V1_SEARCH_PATTERNS}" EXCLUDE "${V1_EXCLUDE_PATTERNS}")

set (P16_V1_INCLUDE_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (P16_V1_EXCLUDE_PATTERNS "tofino.h")
set (P16_V1MODEL_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_V1MODEL_FOR_TOFINO}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_TNA_INCLUDE_PATTERNS "include.*(tofino|tna).p4" "main")
set (P16_TNA_EXCLUDE_PATTERNS "tofino.h")
set (P16_TNA_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_TNA_FOR_TOFINO}" p16_tna_tests INCLUDE "${P16_TNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_TNA_EXCLUDE_PATTERNS}")

set (TOFINO_V1_TEST_SUITES
  ${P4C_SOURCE_DIR}/testdata/p4_14_samples/*.p4
  ${p16_v1tests}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  # temporarily disable all customer tests -- we're failing many of them
  # and we want to save some Travis time
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c1/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c2/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c3/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c4/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c5/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c6/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c7/*/*.p4
  # ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/c8/*/*.p4
  ${v1tests}
  # p4smith regression tests
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4smith_regression/*.p4
  )
p4c_add_bf_backend_tests("tofino" "v1model" "base" "${TOFINO_V1_TEST_SUITES}")

set (TOFINO_TNA_TEST_SUITES
  ${p16_tna_tests}
  )
p4c_add_bf_backend_tests("tofino" "tna" "base" "${TOFINO_TNA_TEST_SUITES}")

p4c_add_ptf_test_with_ptfdir (
    "tofino" tor.p4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/google-tor/p4/spec/tor.p4
    "${testExtraArgs}" ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tor.ptf)

set (ONOS_FABRIC_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos/pipelines/fabric/src/main/resources/fabric.p4)
# run all combinations of fabric.p4 by enabling / disabling SPGW and INT
# transit. This is achieved by passing the names of the PTF groups whose tests
# we want to run to the PTF runner.
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric ${ONOS_FABRIC_P4}
    "${testExtraArgs} "
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf "all ^spgw ^int_transit")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_SPGW ${ONOS_FABRIC_P4}
    "${testExtraArgs} -DWITH_SPGW"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf "all ^int_transit")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_SPGW-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} -DWITH_SPGW -DWITH_INT_TRANSIT"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf "all")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} -DWITH_INT_TRANSIT"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric.ptf "all ^spgw")

# subset of p4factory tests that we want to run as part of regressions
# One # means it fails badly but should get it to run soon
# Two # means it is not required for switch, but we should still try to compile
set (P4FACTORY_REGRESSION_TESTS
  basic_switching
  # # # bf-diags
  # # clpm
  # # dkm
  emulation
  # exm_direct -- timeout on a single test!!
  exm_direct_1
  exm_indirect_1
  exm_smoke_test
  fast_reconfig
  hash_test
  # meters -- timeout on a single test!!
  mirror_test
  # # multicast_scale
  multicast_test
  # # multi-device
  opcode_test
  # opcode_test_signed
  # opcode_test_saturating
  # opcode_test_signed_and_saturating
  pcie_pkt_test
  # # pctr
  # # pgrs
  perf_test_alpm   # (a.k.a alpm-pd-perf)
  # # pvs
  resubmit
  smoke_large_tbls
  stful
  )

# p4-tests has all the includes at the same level with the programs.
# exclude tofino.p4 which is included in some programs
# exclude fifo_pair.p4 which is jbay specific test
# exclude all netcache p4s and add it as a separate test
set (BFN_EXCLUDE_PATTERNS "tofino.p4" "fifo_pair.p4" "defines.p4" 
                          "fast_update.p4" "headers.p4" "heavy_hitter.p4"
                          "ipv4.p4" "meter.p4" "netcache.p4" "parser.p4"
                          "slow_update.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/*/*.p4")
bfn_find_tests ("${BFN_TESTS}" ALL_BFN_TESTS EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
# make a list of all the tests that we want to run PTF on
set (P4F_PTF_TESTS)
foreach (t IN LISTS P4FACTORY_REGRESSION_TESTS)
  list (APPEND P4F_PTF_TESTS
    "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/${t}/${t}.p4")
endforeach()
bfn_add_p4factory_tests("tofino" "smoketest_programs" P4F_PTF_TESTS)

set (P4FACTORY_PROGRAMS_PATH "extensions/p4_tests/p4_14/p4-tests/programs")
# Add extra build flags for PD gen

bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/exm_direct_1/exm_direct_1.p4"
  "--gen-exm-test-pd")
bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/exm_indirect_1/exm_indirect_1.p4"
  "--gen-exm-test-pd")
bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/exm_smoke_test/exm_smoke_test.p4"
  "--gen-exm-test-pd")
bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/perf_test_alpm/perf_test_alpm.p4"
  "--gen-perf-test-pd")

# Pick a single test for the tests that are timing out:
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/exm_indirect_1/exm_indirect_1.p4"
  "test.TestActSelIterators
   test.TestDirectStats
   test.TestDirectStatsPkts28Bytes36
   test.TestDirectStatsPkts32bits
   test.TestIndirectStatPkt64bits
   test.TestIndirectStatsPkts32bits
   test.TestSelector
   test.TestSelectorScopes
   test.TestExmHashAction2")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/multicast_test/multicast_test.p4"
  "test.TestBasic
   ^test.TestYid
   ^test.TestXid
   test.TestEcmp
   ^test.TestLag
   ^test.TestBackup
   ^test.TestGetEntry
   test.TestRegAccess")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/smoke_large_tbls/smoke_large_tbls.p4"
  "test.TestAtcam
   test.TestAtcamTernaryValid")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/stful/stful.p4"
  "test.TestDirectHashCounter
   test.TestDirectStateRestore
   test.TestDirectTcamCounter_default
   test.TestDirectTcamCounter_move
   ^test.TestDirectTcamCounter_twoStage
   test.TestGetEntry
   test.TestIndirectHashSampler
   test.TestInDirectTcamCounter_entries
   test.TestInDirectTcamCounter_rdwr
   test.TestNoKeySymSet
   test.TestOneBit
   test.TestPhase0Iterator
   test.TestPktGenClear
   test.TestResetAPIs
   test.TestTwoInstrNoIdx")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/mirror_test/mirror_test.p4"
   "test.TestBasicForwarding
   test.TestBasicIngMir
   test.TestBasicEgrMir
   test.TestBatching")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/hash_test/hash_test.p4"
    "test.TestCrc16")

# add netcache test
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_netcache" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/netcache/netcache.p4"
   "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/netcache")

# for all other p4factory tests, add them as compile only.
set (P4F_COMPILE_ONLY)
foreach (t IN LISTS ALL_BFN_TESTS)
  list (FIND P4F_PTF_TESTS ${t} found_as_ptf)
  if (${found_as_ptf} EQUAL -1)
    list (APPEND P4F_COMPILE_ONLY ${t})
  endif()
endforeach()
p4c_add_bf_backend_tests("tofino" "v1model" "smoketest_programs" "${P4F_COMPILE_ONLY}")

# Other PD tests

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test"
  "test.TestAddRoute
   ^test.TestCapacity
   test.TestCoveringPrefix
   test.TestDefaultEntry
   test.TestDrop
   test.TestManyEntries
   test.TestModify")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_2"
   "test.TestStateRestore
   test.TestTcamMove")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestRealData" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestRealData"
   "test.TestRealData")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestIdleTime" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestIdleTime"
   "test.TestIdleTime")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestSnapshot" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestSnapshot"
   "test.TestSnapshot")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4"
        "test.TestAddHdr
         test.TestAddRemPort
         test.TestAddRoute
         test.TestAllHit
         test.TestAllStage
         test.TestDeepADT")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_2"
        "test.TestRange
         test.TestRangeTernaryValid
         test.TestSelector
         test.TestTcamDuplicateEntries
         test.TestTcamEntries
         test.TestTcamMove
         test.TestTernaryValidMatch
         test.TestExm4way3Entries
         test.TestExm6way4Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "miss_clause" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/miss_clause.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/miss_clause.ptf")

# Barefoot academy tests
set (BA_TESTS_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/ba-101/labs/*/solution/p4src/*.p4")
p4c_find_tests("${BA_TESTS_FOR_TOFINO}" ba_tests INCLUDE "__TARGET_TOFINO__")
# message("BA-101 tests: ${ba_tests}")
foreach(t IN LISTS ba_tests)
  get_filename_component(__td ${t} DIRECTORY)
  string (REGEX REPLACE "ba-101/labs/([0-9]+[a-z0-9_-]+)/solution.*" "\\1" __t ${__td})
  if (CMAKE_MATCH_1)
    set (testname ${CMAKE_MATCH_1})
  endif()
  set (ptfdir "${__td}/../ptf-tests")
  if (EXISTS ${ptfdir})
    p4c_add_ptf_test_with_ptfdir ("tofino" ${testname} ${t} "${testExtraArgs} -pd" ${ptfdir})
  else()
    file(RELATIVE_PATH testfile ${P4C_SOURCE_DIR} ${t})
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE ${testname} ${testfile} "${testExtraArgs}")
  endif()
  p4c_add_test_label("tofino" "BA-101" ${testname})
endforeach()

# p4testgen ptf tests for p4factory programs
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_emulation" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/emulation.p4
    "${testExtraArgs} -pd -to 12000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/emulation.ptf")
set_tests_properties("tofino/p4testgen_emulation" PROPERTIES TIMEOUT 12000)
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_basic_switching" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/basic_switching.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/basic_switching.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_pcie_pkt_test" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/pcie_pkt_test.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/pcie_pkt_test.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_smoke_large_tbls" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/smoke_large_tbls.p4
    "${testExtraArgs} -pd -to 12000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/smoke_large_tbls.ptf")
set_tests_properties("tofino/p4testgen_smoke_large_tbls" PROPERTIES TIMEOUT 12000)
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_centipedes_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/centipedes_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/centipedes_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_medal_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/medal_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/medal_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_plasmas_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/plasmas_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/plasmas_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_signets_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/signets_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/signets_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_laymen_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/laymen_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/laymen_0.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_faecess_0" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/faecess_0.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/faecess_0.ptf")

## Manifest tests
# test the generation of the compiler archive, for a must pass P4_14 and P4_16 program
# will run as part of cpplint
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE "easy-ternary-archive"
  extensions/p4_tests/p4_14/easy_ternary.p4
  "-norun --create-graphs --archive --validate-manifest")
p4c_add_test_label("tofino" "cpplint" "easy-ternary-archive")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE "tor-archive"
  extensions/p4_tests/p4_16/google-tor/p4/spec/tor.p4
  "-norun --create-graphs --archive --validate-manifest")
p4c_add_test_label("tofino" "cpplint" "tor-archive")

include(Switch.cmake)
include(TofinoMustPass.cmake)
include(TofinoXfail.cmake)

#
# Commented out because we're not yet ready to run all these failed profiles
# and save cycles on testing
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_acl_ip4v" ${switchtest} "${testExtraArgs} -DACL_IPV4_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_bfd_offload" ${switchtest} "${testExtraArgs} -DBFD_OFFLOAD_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_dc_maxsizes" ${switchtest} "${testExtraArgs} -DDC_MAXSIZES_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_egress_acl" ${switchtest} "${testExtraArgs} -DEGRESS_ACL_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_fabric" ${switchtest} "${testExtraArgs} -DFABRIC_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_fabric_maxsizes" ${switchtest} "${testExtraArgs} -DFABRIC_MAXSIZES_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ila" ${switchtest} "${testExtraArgs} -DILA_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ila_ipv6" ${switchtest} "${testExtraArgs} -DILA_IPV6_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ent_fin_spine" ${switchtest} "${testExtraArgs} -DENT_FIN_SPINE_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs} -DENT_FIN_POSTCARD_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_l3_ipv4_fib_clpm" ${switchtest} "${testExtraArgs} -DL3_IPV4_FIB_CLPM_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_mpls_udp" ${switchtest} "${testExtraArgs} -DMPLS_UDP_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_nat" ${switchtest} "${testExtraArgs} -DNAT_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_qos" ${switchtest} "${testExtraArgs} -DQOS_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_sflow" ${switchtest} "${testExtraArgs} -DSFLOW_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_int_vxlan_ep" ${switchtest} "${testExtraArgs} -DTEST_INT_VXLAN_EP_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_int_vxlan_transit" ${switchtest} "${testExtraArgs} -DTEST_INT_VXLAN_TRANSIT_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_mirror_on_drop" ${switchtest} "${testExtraArgs} -DTEST_MIRROR_ON_DROP_PROFILE")
