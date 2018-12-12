set (tofino_timeout 600)

# check for PTF requirements
packet_test_setup_check("tofino")
# experimental -- doesn't quite work yet
# bfn_add_switch("tofino")

set (V1_SEARCH_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (V1_EXCLUDE_PATTERNS "package" "extern")
# Exclude some bmv2 p4s with conditional checksum updates that are not needed for backend
set (V1_EXCLUDE_FILES "issue461-bmv2\\.p4" "issue1079-bmv2\\.p4")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P4TESTS_FOR_TOFINO "${P4TESTDATA}/p4_16_samples/*.p4")
p4c_find_tests("${P4TESTS_FOR_TOFINO}" P4_16_V1_TESTS INCLUDE "${V1_SEARCH_PATTERNS}" EXCLUDE "${V1_EXCLUDE_PATTERNS}")
bfn_find_tests("${P4_16_V1_TESTS}" v1tests EXCLUDE "${V1_EXCLUDE_FILES}")

set (P16_V1_INCLUDE_PATTERNS "include.*v1model.p4" "main|common_v1_test")
set (P16_V1_EXCLUDE_PATTERNS "tofino\\.h")
set (P16_V1MODEL_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_V1MODEL_FOR_TOFINO}" p16_v1tests INCLUDE "${P16_V1_INCLUDE_PATTERNS}" EXCLUDE "${P16_V1_EXCLUDE_PATTERNS}")

set (P16_TNA_INCLUDE_PATTERNS "include.*(tofino|tna).p4" "main")
set (P16_TNA_EXCLUDE_PATTERNS "tofino\\.h")
set (P16_TNA_FOR_TOFINO "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_TNA_FOR_TOFINO}" p16_tna_tests INCLUDE "${P16_TNA_INCLUDE_PATTERNS}" EXCLUDE "${P16_TNA_EXCLUDE_PATTERNS}")

set (PSA_SEARCH_PATTERNS "include.*psa.p4")
set (PSA_EXCLUDE_PATTERNS "package" "extern")
set (P4TESTDATA ${P4C_SOURCE_DIR}/testdata)
set (P16_PSA_FOR_TOFINO "${P4TESTDATA}/p4_16_samples/*.p4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_16/*.p4")
p4c_find_tests("${P16_PSA_FOR_TOFINO}" p16_psa_tests INCLUDE "${PSA_SEARCH_PATTERNS}" EXCLUDE "${PSA_EXCLUDE_PATTERNS}")


# Exclude some p4s with conditional checksum updates that are added separately
set (P4_14_EXCLUDE_FILES "parser_dc_full\\.p4" "sai_p4\\.p4"
                            "checksum_pragma\\.p4" "port_vlan_mapping\\.p4"
                            "checksum\\.p4")
set (P4_14_SAMPLES "${P4TESTDATA}/p4_14_samples/*.p4")
bfn_find_tests("${P4_14_SAMPLES}" p4_14_samples EXCLUDE "${P4_14_EXCLUDE_FILES}")

set (TOFINO_V1_TEST_SUITES
  ${p4_14_samples}
  ${p16_v1tests}
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/*.p4
  ${v1tests}
  # p4smith regression tests
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4smith_regression/*.p4
  # p4_14_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/bf_p4c_samples/*.p4
  # p4_16_samples
  ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf_p4c_samples/*.p4
  )
p4c_add_bf_backend_tests("tofino" "tofino" "v1model" "base" "${TOFINO_V1_TEST_SUITES}")

set (TOFINO_TNA_TEST_SUITES
  ${p16_tna_tests}
  )
p4c_add_bf_backend_tests("tofino" "tofino" "tna" "base" "${TOFINO_TNA_TEST_SUITES}")

set (TOFINO_PSA_TEST_SUITES
  ${p16_psa_tests}
  )
p4c_add_bf_backend_tests("tofino" "tofino" "psa" "base" "${TOFINO_PSA_TEST_SUITES}")

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

# newer version of fabric; the old one (above) can be removed once we reach
# feature parity.
set (ONOS_FABRIC_NEW_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-new/pipelines/fabric/src/main/resources/fabric-tofino.p4)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-new ${ONOS_FABRIC_NEW_P4}
    "${testExtraArgs} "
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric-new.ptf "all ^spgw ^int")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-new-DWITH_SPGW ${ONOS_FABRIC_NEW_P4}
    "${testExtraArgs} -DWITH_SPGW"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric-new.ptf "all ^int")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-new-DWITH_INT_TRANSIT ${ONOS_FABRIC_NEW_P4}
    "${testExtraArgs} -DWITH_INT_TRANSIT"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric-new.ptf "all ^spgw")
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" fabric-new-DWITH_SPGW-DWITH_INT_TRANSIT ${ONOS_FABRIC_NEW_P4}
    "${testExtraArgs} -DWITH_SPGW -DWITH_INT_TRANSIT"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/bf-onos-ptf/fabric-new.ptf "all")

set (TOFINO_32Q_3PIPE_P4 ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tofino32q-3pipe/sfc.p4)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino" tofino32q-3pipe ${TOFINO_32Q_3PIPE_P4}
    "${testExtraArgs} -tofino -arch tna"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_16/tofino32q-3pipe-ptf/sfc.ptf "all")

# subset of p4factory tests that we want to run as part of regressions
# One # means it fails badly but should get it to run soon
# Two # means it is not required for switch, but we should still try to compile
# Remove opcode tests to avoid timeout, these are run as part of nightly
# opcode_test_signed
# opcode_test_saturating
# opcode_test_signed_and_saturating
set (P4FACTORY_REGRESSION_TESTS
  basic_switching
  # # # bf-diags
  # # clpm
  emulation
  fast_reconfig
  hash_test
  mirror_test
  # # multicast_scale
  multicast_test
  # # multi-device
  opcode_test
  pcie_pkt_test
  # # pctr
  pgrs
  perf_test_alpm   # (a.k.a alpm-pd-perf)
  # # pvs
  resubmit
  smoke_large_tbls
  )

# p4-tests has all the includes at the same level with the programs.
# exclude tofino.p4 which is included in some programs
# exclude fifo_pair.p4 which is jbay specific test
# exclude all netcache p4s and add it as a separate test
# exclude ipv4_checksum.p4 (include it in JBay tests)
set (BFN_EXCLUDE_PATTERNS "tofino\\.p4" "fifo_pair\\.p4" "defines\\.p4"
                          "fast_update\\.p4" "headers\\.p4" "heavy_hitter\\.p4"
                          "ipv4\\.p4" "meter\\.p4" "netcache\\.p4" "parser\\.p4"
                          "slow_update\\.p4" "ipv4_checksum\\.p4" "lookup\\.p4")
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

bfn_set_pd_build_flag("tofino" "${P4FACTORY_PROGRAMS_PATH}/perf_test_alpm/perf_test_alpm.p4"
  "\"--gen-perf-test-pd\"")

# Pick a set of tests for the tests that are timing out:
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
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/mirror_test/mirror_test.p4"
   "test.TestBasicForwarding
   test.TestBasicIngMir
   test.TestBasicEgrMir
   test.TestBatching")
bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/hash_test/hash_test.p4"
    "test.TestCrc16")

bfn_set_ptf_test_spec("tofino" "${P4FACTORY_PROGRAMS_PATH}/pgrs/pgrs.p4"
    "test.TestTxn
     test.TestAddrOverride
     test.TestTimerAllPipe
     test.TestRecircAll
     test.TestTimerOneShot
     test.TestPattern
     test.TestBatch")

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
p4c_add_bf_backend_tests("tofino" "tofino" "v1model" "smoketest_programs" "${P4F_COMPILE_ONLY}")

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
   "test.TestIdleTime
   test.TestSnapshot
   test.TestStateRestore
   test.TestTcamMove")

p4c_add_ptf_test_with_ptfdir("tofino" "smoketest_programs_alpm_test_TestRealData" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/alpm_test/alpm_test.p4"
  "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/alpm_test")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_alpm_test_TestRealData"
   "test.TestRealData")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4"
         "test.TestExm6way4Entries
          test.TestDeepADT
          test.TestExm5way4Entries
          test.TestTcamStateRestoreLarge
          test.TestExm4way3Entries
          test.TestAddRemPort
          test.TestSelectorActions
          test.TestExm4way4Entries
          test.TestRange3
          test.TestMacRW
          test.TestExm3way4Entries
          test.TestTcamScopesMax")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_2"
         "test.TestTblPropSymmetricEntries
          test.TestExm5way3Entries
          test.TestSelectorStateRestore
          test.TestIndirectActionStateRestore
          test.TestTblDbgCountersStage
          test.TestTblPropSymmetric
          test.TestExm4way7Entries
          test.TestExmStateRestore
          test.TestNoKeyNoParamTables
          test.TestAddRoute
          test.TestDefaultEntriesAllStage")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_3" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_3"
         "test.TestExm4way5Entries
          test.TestTcamEntries
          test.TestTcamScopes
          test.TestHeadPtrMove
          test.TestDrop
          test.TestMatchSpecApi
          test.TestSnapshotWithTimer
          test.TestExm3way5Entries
          test.TestTernaryValidMatch
          test.TestRmHdr
          test.TestTcamScopes1")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_4" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_4"
         "test.TestSelector
          test.TestAllHit
          test.TestAddHdr
          test.TestExmStateRestoreLarge
          test.TestTcamSnapshot
          test.TestTcamMove
          test.TestExm6way3Entries
          test.TestTcamStateRestore
          test.TestUdpDstPort
          test.TestRangeTernaryValid
          test.TestTcamDuplicateEntries")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_5" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_5"
         "test.TestIndirectAction
          test.TestSelectorIterator
          test.TestExmScopes
          test.TestRange
          test.TestRange2
          test.TestExm3way3Entries
          test.TestAllStage
          test.TestTblDbgCounters
          test.TestLogTblCounter
          test.TestExmSnapshot")
p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_basic_ipv4_TestLearning" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/basic_ipv4/basic_ipv4.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/basic_ipv4")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_basic_ipv4_TestLearning"
         "test.TestLearning")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_basic_ipv4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_2" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_3" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_4" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_5" PROPERTIES TIMEOUT 3600)
set_tests_properties("tofino/smoketest_programs_basic_ipv4_TestLearning" PROPERTIES TIMEOUT 3600)

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_dkm" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/dkm/dkm.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/dkm")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/exm_direct/exm_direct.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/exm_direct")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct"
    "\"--gen-exm-test-pd\"")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct"
        "^test.TestIdleTimeTCAM
        test.TestExm4way8Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/exm_direct/exm_direct.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/exm_direct")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct_2"
    "\"--gen-exm-test-pd\"")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct_2"
        "^test.TestIdleTimeStateRestore
        test.TestExm5way5Entries
        test.TestExmMoveReg
        test.TestExm4way6Entries
        ^test.TestIdleTimeMovereg
        ^test.TestIdleTimeEXM
        test.TestExm6way5Entries
        test.TestExm6way6Entries
        test.TestExm3way7Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/exm_direct_1/exm_direct_1.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/exm_direct_1")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct_1"
    "\"--gen-exm-test-pd\"")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct_1"
        "^test.TestExm5way8Entries
        ^test.TestExmdeep64k
        test.TestExm4way2Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_direct_1_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/exm_direct_1/exm_direct_1.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/exm_direct_1")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_direct_1_2"
    "\"--gen-exm-test-pd\"")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_direct_1_2"
        "test.TestExm6way2Entries
        test.TestExm5way7Entries
        test.TestExm3way2Entries
        ^test.TestExmdeep32k
        ^test.TestExm6way8Entries
        test.TestExm4way1Entries
        test.TestExm6way1Entries
        ^test.TestExmwidekey
        test.TestExm3way1Entries
        test.TestExm5way2Entries
        test.TestExm6way7Entries
        test.TestExm5way1Entries
        test.TestExm5way7EntriesDefaultEntry")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_indirect_1" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/exm_indirect_1/exm_indirect_1.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/exm_indirect_1")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_indirect_1"
        "\"--gen-exm-test-pd\"")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_indirect_1"
        "test.TestActSelIterators
        test.TestDirectStats")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_indirect_1_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/exm_indirect_1/exm_indirect_1.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/exm_indirect_1")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_indirect_1_2"
        "\"--gen-exm-test-pd\"")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_indirect_1_2"
        "test.TestDirectStatsPkts28Bytes36
        test.TestDirectStatsPkts32bits
        test.TestExmProxyHash
        test.TestIndirectStatPkt64bits
        test.TestIndirectStatsPkts32bits
        test.TestSelector
        test.TestSelectorScopes
        test.TestExm4way6Entries
        test.TestExmHashAction
        test.TestExmHashAction2")


p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_smoke_test" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/exm_smoke_test/exm_smoke_test.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/exm_smoke_test")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_smoke_test"
        "\"--gen-exm-test-pd\"")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_smoke_test"
        "^test.TestExmdeep64k
        test.TestExm4way2Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_exm_smoke_test_2" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/exm_smoke_test/exm_smoke_test.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/exm_smoke_test")
bfn_set_pd_build_flag("tofino" "smoketest_programs_exm_smoke_test_2"
        "\"--gen-exm-test-pd\"")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_exm_smoke_test_2"
        "test.TestExm6way2Entries
        test.TestExm3way2Entries
        ^test.TestExmdeep32k
        test.TestExm6way8Entries
        test.TestExm4way1Entries
        test.TestExm6way1Entries
        ^test.TestExmwidekey
        test.TestExm3way1Entries
        test.TestExm5way2Entries
        test.TestExm6way7Entries
        test.TestExm5way1Entries")

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_stful" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/stful/stful.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/stful")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_stful"
        "all
         ^test.TestStfulSelTbl
         ^test.TestStfulSelTbl2")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_stful" PROPERTIES TIMEOUT 3600)

p4c_add_ptf_test_with_ptfdir ("tofino" "smoketest_programs_meters" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/programs/meters/meters.p4"
    "${testExtraArgs} -pd -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/meters")
bfn_set_ptf_test_spec("tofino" "smoketest_programs_meters"
        "^test.TestMeterOmnet
        test.TestTCAMLpfIndirect
        test.TestExmLpfIndirect
        test.TestExmLpfdirect
        test.TestByteAdj
        test.TestMeterIndirectStateRestore
        test.TestMeterScopes
        test.TestExmMeterIndirect
        test.TestMeterDirectStateRestore
        test.TestExmMeterColorAwareIndirect
        test.TestTCAMLpfdirect
        test.TestExmMeterDirect")
bfn_set_ptf_ports_json_file("tofino" "smoketest_programs_meters" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/ptf-tests/meters/ports.json")

# 500s timeout is too little for compiling and testing the entire test, bumping it up
set_tests_properties("tofino/smoketest_programs_meters" PROPERTIES TIMEOUT 3600)

p4c_add_ptf_test_with_ptfdir ("tofino" "miss_clause" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/miss_clause.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/miss_clause.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "brig_569"
    ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/BRIG-569/brig_569.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/BRIG-569/brig_569.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "case6684" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/BRIG-847/case6684.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/BRIG-847/case6684.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "simple_l3_checksum" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/COMPILER-1008/simple_l3_checksum.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/COMPILER-1008/simple_l3_checksum.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "basic_switching" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/COMPILER-980/basic_switching.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/COMPILER-980/basic_switching.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "case6738" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/BRIG-879/case6738.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/BRIG-879/case6738.ptf")

p4c_add_ptf_test_with_ptfdir ("tofino" "simple_l3_mirror" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/BRIG-879/simple_l3_mirror.p4
     "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/PD/BRIG-879/simple_l3_mirror.ptf")

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
    p4c_add_test_with_args("tofino" ${P4C_RUNTEST} FALSE ${testname} ${testfile} "${testExtraArgs}" "")
  endif()
  p4c_add_test_label("tofino" "BA-101" ${testname})
endforeach()

# p4testgen ptf tests for p4factory programs
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_emulation" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/emulation.p4
    "${testExtraArgs} -pd -to 3600" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/emulation.ptf")
set_tests_properties("tofino/p4testgen_emulation" PROPERTIES TIMEOUT 3600)
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_basic_switching" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/basic_switching.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/basic_switching.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_pcie_pkt_test" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/pcie_pkt_test.p4
    "${testExtraArgs} -pd" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/pcie_pkt_test.ptf")
p4c_add_ptf_test_with_ptfdir ("tofino" "p4testgen_smoke_large_tbls" ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/smoke_large_tbls.p4
    "${testExtraArgs} -pd -to 3600" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4testgen_regression/smoke_large_tbls.ptf")
set_tests_properties("tofino/p4testgen_smoke_large_tbls" PROPERTIES TIMEOUT 3600)
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
  "-norun --create-graphs --archive --validate-manifest" "")
p4c_add_test_label("tofino" "cpplint" "easy-ternary-archive")

p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE "tor-archive"
  extensions/p4_tests/p4_16/google-tor/p4/spec/tor.p4
  "-norun --create-graphs --archive --validate-manifest" "")
p4c_add_test_label("tofino" "cpplint" "tor-archive")

## P4-16 Programs
set (P4FACTORY_P4_16_PROGRAMS
  tna_32q_2pipe
  tna_action_profile
  tna_action_selector
  tna_counter
  tna_digest
  tna_exact_match
  tna_idletimeout
  tna_lpm_match
  tna_meter_lpf_wred
  tna_operations
  tna_range_match
  tna_register
  tna_ternary_match
  )

# No ptf, compile-only
file(RELATIVE_PATH p4_16_programs_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/p4_16_programs)
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "p4_16_programs_simple_switch" ${p4_16_programs_path}/simple_switch/simple_switch.p4 "${testExtraArgs} -tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/p4_16_programs" "")
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "p4_16_programs_tna_32q_multiprogram_a" ${p4_16_programs_path}/tna_32q_multiprogram/program_a/tna_32q_multiprogram_a.p4 "${testExtraArgs} -tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/p4_16_programs/tna_32q_multiprogram" "")
p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} FALSE
  "p4_16_programs_tna_32q_multiprogram_b" ${p4_16_programs_path}/tna_32q_multiprogram/program_b/tna_32q_multiprogram_b.p4 "${testExtraArgs} -tofino -arch tna -I${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/p4_16_programs/tna_32q_multiprogram" "")

# P4-16 Programs with PTF tests
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS)
  p4c_add_ptf_test_with_ptfdir ("tofino" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/p4_16_programs/${t}/${t}.p4"
    "${testExtraArgs} -ptf -bfrt -to 2000" "${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/p4_16_programs/${t}")
  bfn_set_p4_build_flag("tofino" "p4_16_programs_${t}" "-I${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/p4_16_programs")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/p4_14/p4-tests/p4_16_programs/${t}/ports.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino" "p4_16_programs_${t}" ${ports_json})
  endif()
endforeach()

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino/p4_16_programs_tna_exact_match" PROPERTIES TIMEOUT 1200)
set_tests_properties("tofino/p4_16_programs_tna_ternary_match" PROPERTIES TIMEOUT 2400)

include(Switch.cmake)

include(Customer.cmake)
# Set a small timeout since these are running into an infinite loop in slicing
# -to 60 should be removed when Deep merges the fix.
p4c_add_bf_backend_tests("tofino" "tofino" "v1model" "arista" "${ARISTA_P4_14_TESTS}"
  "--backward-compatible -to 600 -Xp4c=\"--disable-pragma=pa_container_size\"")

include(TofinoMustPass.cmake)
include(TofinoXfail.cmake)

#
# Commented out because we're not yet ready to run all these failed profiles
# and save cycles on testing
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_acl_ip4v" ${switchtest} "${testExtraArgs}" "-DACL_IPV4_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_bfd_offload" ${switchtest} "${testExtraArgs}" "-DBFD_OFFLOAD_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_dc_maxsizes" ${switchtest} "${testExtraArgs}" "-DDC_MAXSIZES_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_egress_acl" ${switchtest} "${testExtraArgs}" "-DEGRESS_ACL_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_fabric" ${switchtest} "${testExtraArgs}" "-DFABRIC_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_fabric_maxsizes" ${switchtest} "${testExtraArgs}" "-DFABRIC_MAXSIZES_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ila" ${switchtest} "${testExtraArgs}" "-DILA_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ila_ipv6" ${switchtest} "${testExtraArgs}" "-DILA_IPV6_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ent_fin_spine" ${switchtest} "${testExtraArgs}" "-DENT_FIN_SPINE_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_ent_fin_postcard" ${switchtest} "${testExtraArgs}" "-DENT_FIN_POSTCARD_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_l3_ipv4_fib_clpm" ${switchtest} "${testExtraArgs}" "-DL3_IPV4_FIB_CLPM_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_mpls_udp" ${switchtest} "${testExtraArgs}" "-DMPLS_UDP_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_nat" ${switchtest} "${testExtraArgs}" "-DNAT_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_qos" ${switchtest} "${testExtraArgs}" "-DQOS_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_sflow" ${switchtest} "${testExtraArgs}" "-DSFLOW_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_int_vxlan_ep" ${switchtest} "${testExtraArgs}" "-DTEST_INT_VXLAN_EP_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_int_vxlan_transit" ${switchtest} "${testExtraArgs}" "-DTEST_INT_VXLAN_TRANSIT_PROFILE")
# p4c_add_test_with_args ("tofino" ${P4C_RUNTEST} ${isXFail}
#   "switch_test_mirror_on_drop" ${switchtest} "${testExtraArgs}" "-DTEST_MIRROR_ON_DROP_PROFILE")
