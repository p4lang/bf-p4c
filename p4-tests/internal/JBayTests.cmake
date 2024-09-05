set (tofino2_timeout ${default_test_timeout})

# check for PTF requirements
packet_test_setup_check("jbay")
# check for STF requirements
simple_test_setup_check("jbay")

## P4-16 Programs
set (P4FACTORY_P4_16_PROGRAMS
  tna_32q_2pipe
  tna_action_profile
  tna_action_selector
  tna_bridged_md
  tna_counter
  tna_custom_hash
  tna_digest
  tna_dkm
  tna_dyn_hashing
  tna_exact_match
  tna_field_slice
  tna_idletimeout
  tna_lpm_match
  tna_meter_bytecount_adjust
  tna_meter_lpf_wred
  tna_mirror
  tna_multicast
  tna_operations
  tna_port_metadata
  tna_port_metadata_extern
  tna_proxy_hash
  tna_pvs
  tna_random
  tna_range_match
  tna_register
  tna_snapshot
  tna_symmetric_hash
  tna_ternary_match
  tna_timestamp
  t2na_counter_true_egress_accounting
  )

p4c_add_ptf_test_with_ptfdir ("tofino2" "t2na_ghost_dod" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/t2na_ghost_dod/t2na_ghost_dod.p4" "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/t2na_ghost_dod")
bfn_set_ptf_test_spec("tofino2" "t2na_ghost_dod" "test.T2naGhostTestDoD")

p4c_add_ptf_test_with_ptfdir ("tofino2" "t2na_ghost_dod_simpl" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/t2na_ghost_dod_simpl/t2na_ghost_dod_simpl.p4" "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/t2na_ghost_dod_simpl")
bfn_set_ptf_test_spec("tofino2" "t2na_ghost_dod_simpl" "test.T2naGhostSimplTestDoD")

p4c_add_ptf_test_with_ptfdir ("tofino2" "t2na_ghost_dod_2pipe_simpl" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/t2na_ghost_dod_2pipe_simpl/t2na_ghost_dod_2pipe_simpl.p4" "${testExtraArgs} -target tofino2 -arch t2na -bfrt " "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/t2na_ghost_dod_2pipe_simpl")
bfn_set_ptf_test_spec("tofino2" "t2na_ghost_dod_2pipe_simpl" "test.T2naGhost2PipeSimplTestDoD")
# uses multiple pipes so we need to specify ports explicitly
bfn_set_ptf_ports_json_file("tofino2" "t2na_ghost_dod_2pipe_simpl" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/t2na_ghost_dod_2pipe_simpl/ports.json")

p4c_add_ptf_test_with_ptfdir ("tofino2" "large_counter_meter" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/large_counter_meter/large_counter_meter.p4"
  "${testExtraArgs} -target tofino2 -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16 -bfrt -Xp4c=\"--disable_split_attached\" -Xptf=--test-params=pkt_size=100"
  "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/large_counter_meter")
bfn_set_ptf_test_spec("tofino2" "large_counter_meter" "all")
set_tests_properties("tofino2/large_counter_meter" PROPERTIES TIMEOUT ${extended_timeout_3times})

# P4-16 Programs with PTF tests
foreach(t IN LISTS P4FACTORY_P4_16_PROGRAMS)
  p4c_add_ptf_test_with_ptfdir ("tofino2" "p4_16_programs_${t}" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}/${t}.p4"
    "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}")
  bfn_set_p4_build_flag("tofino2" "p4_16_programs_${t}" "-I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs")
  set (ports_json ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/${t}/ports_tof2.json)
  if (EXISTS ${ports_json})
    bfn_set_ptf_ports_json_file("tofino2" "p4_16_programs_${t}" ${ports_json})
  endif()
endforeach()

set (ONOS_FABRIC_P4 ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/bf-onos/pipelines/fabric/src/main/resources/fabric-tofino.p4)
set (ONOS_FABRIC_PTF ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/onf_fabric/tests/onf)
p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=0 -arch v1model"
    ${ONOS_FABRIC_PTF} "all ^spgw ^int")

p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-DWITH_SPGW ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=0 -DWITH_SPGW -arch v1model"
    ${ONOS_FABRIC_PTF} "all ^int")

p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=0 -DWITH_INT_TRANSIT -arch v1model"
    ${ONOS_FABRIC_PTF} "all ^spgw")

p4c_add_ptf_test_with_ptfdir_and_spec (
    "tofino2" fabric-DWITH_SPGW-DWITH_INT_TRANSIT ${ONOS_FABRIC_P4}
    "${testExtraArgs} --auto-init-metadata -DCPU_PORT=0 -DWITH_SPGW -DWITH_INT_TRANSIT -arch v1model"
    ${ONOS_FABRIC_PTF} "all")

bfn_needs_scapy("tofino2" "fabric")
bfn_needs_scapy("tofino2" "fabric-DWITH_SPGW")
bfn_needs_scapy("tofino2" "fabric-DWITH_INT_TRANSIT")
bfn_needs_scapy("tofino2" "fabric-DWITH_SPGW-DWITH_INT_TRANSIT")

set_tests_properties("tofino2/fabric" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino2/fabric-DWITH_SPGW" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino2/fabric-DWITH_INT_TRANSIT" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino2/fabric-DWITH_SPGW-DWITH_INT_TRANSIT" PROPERTIES TIMEOUT ${extended_timeout_2times})

# p4-tests has all the includes at the same level with the programs.
set (BFN_EXCLUDE_PATTERNS "tofino\\.p4")
set (BFN_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/atomic_mod/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/dyn_hash/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/emulation/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/entry_read_from_hw/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/hash_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/incremental_checksum/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/parse480/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/simple_l3_checksum_branched_end/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/simple_l3_checksum_single_end/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/stashes/*.p4"
	       # "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/simple_l3_checksum_taken_default_ingress/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/basic_switching/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/chksum/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/default_entry/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/deparse_zero/*.p4"
               # Hitless doesn't work with tofino2 (it timeouts)
               # "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/ha/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/mirror_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/multicast_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/parse_error/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/pcie_pkt_test/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/resubmit/*.p4"
               # Might need to move this test to nightly if it times out on Travis
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/dkm/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/fast_reconfig/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/hash_driven/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/meters/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/pvs/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/resubmit/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/smoke_large_tbls/*.p4"
               "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/stful/*.p4")
bfn_find_tests ("${BFN_TESTS}" BFN_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
bfn_add_p4factory_tests("tofino2" "tofino2" "${JBAY_P414_TEST_ARCH}" "smoketest_programs" BFN_TESTS_LIST "${testExtraArgs}")
p4c_add_test_label("tofino2" "UNSTABLE" "extensions/p4_tests/internal/p4-programs/programs/multicast_test/multicast_test.p4")

bfn_set_ptf_test_spec("tofino2" "extensions/p4_tests/internal/p4-programs/programs/meters/meters.p4"
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

bfn_set_ptf_test_spec("tofino2" "extensions/p4_tests/internal/p4-programs/programs/smoke_large_tbls/smoke_large_tbls.p4"
       "test.TestAtcam
       test.TestAtcamTernaryValid")

bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/internal/p4-programs/programs/multicast_test/multicast_test.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/multicast_test/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/internal/p4-programs/programs/fast_reconfig/fast_reconfig.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/fast_reconfig/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/internal/p4-programs/programs/mirror_test/mirror_test.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/mirror_test/ports.json")
# bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/internal/p4-programs/programs/ha/ha.p4"
#                             "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/ha/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "extensions/p4_tests/internal/p4-programs/programs/pvs/pvs.p4"
                            "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/ptf-tests/pvs/ports.json")

# bfn_set_pd_build_flag("tofino2" "extensions/p4_tests/internal/p4-programs/programs/ha/ha.p4"
#     "--gen-hitless-ha-test-pd")
file(RELATIVE_PATH ha_ha_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/ha/ha.p4)
bfn_add_test_with_args ("tofino2" "jbay" "extensions/p4_tests/internal/p4-programs/programs/ha/ha.p4"
    ${ha_ha_path} "${testExtraArgs} -arch ${JBAY_P414_TEST_ARCH}" "")

# Add some tests as compile only (if they take too long to run or cannot be run
# in compiler docker env due to port issues or lack of pd-16 support)
set (TOF2_V1MODEL_COMPILE_ONLY_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/action_spec_format/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/basic_ipv4/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct_1/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_direct/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_indirect_1/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/exm_smoke_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/knet_mgr_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/mau_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/mod_field_conditionally/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/multi_device/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/multicast_scale/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/opcode_test_saturating/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/opcode_test_signed_and_saturating/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/opcode_test_signed/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/opcode_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/parser_error/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/parser_intr_md/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/pgrs_tof2/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_14/range/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/alpm_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/iterator/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/perf_test_alpm/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/perf_test/*.p4"
                                     "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/programs/pgrs/*.p4")
bfn_find_tests ("${TOF2_V1MODEL_COMPILE_ONLY_TESTS}" TOF2_V1MODEL_COMPILE_ONLY_TESTS_LIST EXCLUDE "${BFN_EXCLUDE_PATTERNS}")
p4c_add_bf_backend_tests("tofino2" "jbay" "${JBAY_P414_TEST_ARCH}" "smoketest_programs" "${TOF2_V1MODEL_COMPILE_ONLY_TESTS_LIST}")

# No ptf, compile-only
file(RELATIVE_PATH p4_16_programs_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs)

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_32q_multiprogram_a"
    ${p4_16_programs_path}/tna_32q_multiprogram/program_a/tna_32q_multiprogram_a.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_32q_multiprogram" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_32q_multiprogram_b"
    ${p4_16_programs_path}/tna_32q_multiprogram/program_b/tna_32q_multiprogram_b.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_32q_multiprogram" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_resubmit"
    ${p4_16_programs_path}/tna_resubmit/tna_resubmit.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_resubmit" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_pktgen"
    ${p4_16_programs_path}/tna_pktgen/tna_pktgen.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_pktgen" "")
bfn_set_ptf_test_spec("tofino2" "p4_16_programs_tna_pktgen" "all ^test.PortDownPktgenTest")

file(RELATIVE_PATH p4_16_internal_p4_16_path ${P4C_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16)
bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_hwlrn"
    ${p4_16_internal_p4_16_path}/hwlrn/hwlrn.p4 "${testExtraArgs} -arch t2na --no-bf-rt-schema -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")
set_property(TEST "tofino2/extensions/p4_tests/p4_16/jbay/hwlearn1.p4"
  APPEND PROPERTY ENVIRONMENT "CTEST_P4C_ARGS=--no-bf-rt-schema")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_ipv4_checksum"
    ${p4_16_internal_p4_16_path}/ipv4_checksum/ipv4_checksum.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_lrn"
    ${p4_16_internal_p4_16_path}/lrn/lrn.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_emulation"
    ${p4_16_internal_p4_16_path}/t2na_emulation/t2na_emulation.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_fifo"
    ${p4_16_internal_p4_16_path}/t2na_fifo/t2na_fifo.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_pgr"
    ${p4_16_internal_p4_16_path}/t2na_pgr/t2na_pgr.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_static_entry"
    ${p4_16_internal_p4_16_path}/t2na_static_entry/t2na_static_entry.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_tna_pvs_multi_states" ${p4_16_internal_p4_16_path}/tna_pvs_multi_states/tna_pvs_multi_states.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")
bfn_set_ptf_test_spec("tofino2" "p4_16_internal_p4_16_tna_pvs_multi_states" "all")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_t2na_ghost"
    ${p4_16_internal_p4_16_path}/t2na_ghost/t2na_ghost.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")

bfn_add_test_with_args ("tofino2" "jbay" "p4_16_internal_p4_16_mirror"
    ${p4_16_internal_p4_16_path}/mirror/mirror.p4 "${testExtraArgs} -arch t2na -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16" "")

# PTF, disable failing tests
bfn_add_test_with_args ("tofino2" "jbay" "p4_16_programs_tna_checksum"
    ${p4_16_programs_path}/tna_checksum/tna_checksum.p4 "${testExtraArgs} -arch t2na -bfrt -I${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_checksum" "")
bfn_needs_scapy("tofino2" "p4_16_programs_tna_checksum")
bfn_set_ptf_test_spec("tofino2" "p4_16_programs_tna_snapshot"
    "all ^test.SnapshotTest")

# Set ports.json for tna_idletime test
bfn_set_ptf_ports_json_file("tofino2" "p4_16_programs_tna_dkm" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_dkm/ports.json")
bfn_set_ptf_ports_json_file("tofino2" "p4_16_programs_tna_idletimeout" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/p4_16_programs/tna_idletimeout/ports.json")

# 500s timeout is too little for compiling and testing the entire switch, bumping it up
set_tests_properties("tofino2/p4_16_programs_tna_exact_match" PROPERTIES TIMEOUT ${extended_timeout_2times})
set_tests_properties("tofino2/p4_16_programs_tna_ternary_match" PROPERTIES TIMEOUT ${extended_timeout_4times})
set_tests_properties("tofino2/p4_16_programs_tna_register" PROPERTIES TIMEOUT ${extended_timeout_2times})

p4c_add_ptf_test_with_ptfdir ("tofino2" "t2na_misc2" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/misc2/misc2.p4" "${testExtraArgs} -target tofino2 -arch t2na -bfrt" "${CMAKE_CURRENT_SOURCE_DIR}/internal/p4-programs/internal_p4_16/misc2")
bfn_set_ptf_test_spec("tofino2" "t2na_misc2" "^test.Atcam")

set(P4TESTS_NON_PR
    p4_16_programs_tna_action_selector
)

foreach(t IN LISTS P4TESTS_NON_PR)
  p4c_add_test_label("tofino2" "NON_PR_TOFINO" ${t})
endforeach()

include(internal/SwitchJBay.cmake)
include(internal/JBayErrors.cmake)
include(internal/JBayMustPass.cmake)
include(internal/JBayXfail.cmake)
