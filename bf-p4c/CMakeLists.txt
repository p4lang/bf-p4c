####### Barefoot back-end

MESSAGE("-- Adding p4c-barefoot")

# An option to configure the chunk size we use for unified builds in bf-p4c. By
# default, this is tuned to use smaller chunks than the p4c repo uses. The goal
# is to gain most of the benefit of unified builds when many files change, while
# keeping the impact on recompilation time for individual files to a minimum.
set(BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE "5" CACHE STRING
    "Target unified compilation chunk size for bf-p4c (an integer or ALL)")

find_package (Boost REQUIRED COMPONENTS graph)
add_definitions("-DBOOST_NO_ARGUMENT_DEPENDENT_LOOKUP")
if (ENABLE_JBAY)
  add_definitions("-DHAVE_JBAY=1")
endif()
include_directories(${Boost_INCLUDE_DIRS})
set (HAVE_LIBBOOST_GRAPH 1)
set (P4C_LIB_DEPS "${P4C_LIB_DEPS};${Boost_GRAPH_LIBRARY}")



set (BF_P4C_IR_SRCS
  ir/dbprint-tofino.cpp
  ir/bitrange.cpp
  ir/gress.cpp
  ir/mau.cpp
  ir/thread_visitor.cpp
  ir/tofino.cpp
  ir/tofino_write_context.cpp
  parde/clot.cpp
  phv/phv.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_IR_SRCS}")

set (BF_P4C_IR_HDRS
  ir/bitrange.h
  ir/control_flow_visitor.h
  ir/gress.h
  ir/thread_visitor.h
  ir/tofino_write_context.h
  parde/clot.h
  phv/phv.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_IR_HDRS}")

set (BF_P4C_BACKEND_CONV_SRCS
  fromv1.0/lpf.cpp
  fromv1.0/primitives.cpp
  fromv1.0/stateful_alu.cpp
  fromv1.0/wred.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_CONV_SRCS}")

set (BF_P4C_BACKEND_CONV_HDRS
  fromv1.0/lpf.h
  fromv1.0/stateful_alu.h
  fromv1.0/wred.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_CONV_HDRS}")

# IR sources that need to go into the frontend library
set(QUAL_BF_P4C_IR_SRCS)
foreach(src IN LISTS BF_P4C_IR_SRCS)
  set(QUAL_BF_P4C_IR_SRCS ${QUAL_BF_P4C_IR_SRCS} ${CMAKE_CURRENT_SOURCE_DIR}/${src})
endforeach()
set(EXTENSION_FRONTEND_SOURCES ${EXTENSION_FRONTEND_SOURCES} ${QUAL_BF_P4C_IR_SRCS} PARENT_SCOPE)

# sources that need to be linked directly in p4test to properly handle
# p4 14 to 16 conversion
set(QUAL_BF_P4C_P4_14_CONV_SRCS)
foreach(src IN LISTS BF_P4C_BACKEND_CONV_SRCS)
  set(QUAL_BF_P4C_P4_14_CONV_SRCS ${QUAL_BF_P4C_P4_14_CONV_SRCS} ${CMAKE_CURRENT_SOURCE_DIR}/${src})
endforeach()
set(EXTENSION_P4_14_CONV_SOURCES ${EXTENSION_P4_14_CONV_SOURCES} ${QUAL_BF_P4C_P4_14_CONV_SRCS} PARENT_SCOPE)


set (BF_P4C_BACKEND_COMMON_SRCS
  common/asm_output.cpp
  common/check_header_alignment.cpp
  common/copy_header_eliminator.cpp
  common/elim_unused.cpp
  common/extract_maupipe.cpp
  common/field_defuse.cpp
  common/header_stack.cpp
  common/live_range_overlay.cpp
  common/multiple_apply.cpp
  common/rewrite.cpp
  common/param_binding.cpp
  common/parser_overlay.cpp
  common/parser_critical_path.cpp
  common/linear_path.cpp
  common/simplify_references.cpp
  common/slice.cpp
  common/type_categories.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_COMMON_SRCS}")
build_unified(BF_P4C_BACKEND_COMMON_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_COMMON_HDRS
  common/autoindent.h
  common/blockmap.h
  common/check_header_alignment.h
  common/check_header_refs.h
  common/copy_header_eliminator.h
  common/debug_info.h
  common/elim_unused.h
  common/extract_maupipe.h
  common/field_defuse.h
  common/header_stack.h
  common/live_range_overlay.h
  common/multiple_apply.h
  common/rewrite.h
  common/param_binding.h
  common/parser_overlay.h
  common/parser_critical_path.h
  common/linear_path.h
  common/simplify_references.h
  common/slice.h
  common/type_categories.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_COMMON_HDRS}")

set (BF_P4C_BACKEND_CONTROL_PLANE_SRCS
  control-plane/tofino_p4runtime.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_CONTROL_PLANE_SRCS}")
build_unified(BF_P4C_BACKEND_CONTROL_PLANE_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_CONTROL_PLANE_HDRS
  control-plane/tofino_p4runtime.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_CONTROL_PLANE_HDRS}")

set (BF_P4C_BACKEND_LIB_HDRS
  lib/union_find.hpp
  lib/vertex_weighted_coloring.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_LIB_HDRS}")

set (BF_P4C_BACKEND_MAU_SRCS
  mau/action_analysis.cpp
  mau/action_data_bus.cpp
  mau/action_format.cpp
  mau/asm_output.cpp
  mau/field_use.cpp
  mau/db-gateway.cpp
  mau/gateway.cpp
  mau/input_xbar.cpp
  mau/instruction_adjustment.cpp
  mau/instruction_selection.cpp
  mau/ixbar_realign.cpp
  mau/memories.cpp
  mau/resource_estimate.cpp
  mau/resource.cpp
  mau/split_alpm.cpp
  mau/split_gateways.cpp
  mau/stateful_alu.cpp
  mau/table_dependency_graph.cpp
  mau/table_format.cpp
  mau/table_layout.cpp
  mau/table_mutex.cpp
  mau/table_placement.cpp
  mau/table_seqdeps.cpp
  mau/table_summary.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_MAU_SRCS}")
build_unified(BF_P4C_BACKEND_MAU_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_MAU_HDRS
  mau/action_analysis.h
  mau/action_data_bus.h
  mau/action_format.h
  mau/asm_output.h
  mau/default_next.h
  mau/field_use.h
  mau/gateway.h
  mau/input_xbar.h
  mau/instruction_adjustment.h
  mau/instruction_selection.h
  mau/ixbar_realign.h
  mau/memories.h
  mau/push_pop.h
  mau/resource_estimate.h
  mau/resource.h
  mau/split_alpm.h
  mau/split_gateways.h
  mau/stateful_alu.h
  mau/table_dependency_graph.h
  mau/table_format.h
  mau/table_layout.h
  mau/table_mutex.h
  mau/table_placement.h
  mau/table_seqdeps.h
  mau/table_summary.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_MAU_HDRS}")

set (BF_P4C_BACKEND_PARDE_SRCS
  parde/add_parde_metadata.cpp
  parde/bridge_metadata.cpp
  parde/checksum.cpp
  parde/clot_info.cpp
  parde/deparser_output.cpp
  parde/extract_parser.cpp
  parde/field_packing.cpp
  parde/gen_deparser.cpp
  parde/lower_parser.cpp
  parde/mirror.cpp
  parde/parde_spec.cpp
  parde/parser_output.cpp
  parde/phase0.cpp
  parde/resolve_computed.cpp
  parde/resubmit.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_PARDE_SRCS}")
build_unified(BF_P4C_BACKEND_PARDE_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_PARDE_HDRS
  parde/add_parde_metadata.h
  parde/asm_output.h
  parde/bridge_metadata.h
  parde/checksum.h
  parde/clot_info.h
  parde/epb_config.h
  parde/extract_parser.h
  parde/field_packing.h
  parde/lower_parser.h
  parde/mirror.h
  parde/parde_spec.h
  parde/phase0.h
  parde/resolve_computed.h
  parde/resubmit.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_PARDE_HDRS}")

set (BF_P4C_BACKEND_PHV_SRCS
  phv/action_phv_constraints.cpp
  phv/allocate_phv.cpp
  phv/asm_output.cpp
  phv/cluster_phv_operations.cpp
  phv/create_thread_local_instances.cpp
  phv/cluster_to_cluster_interference.cpp
  phv/field_alignment.cpp
  phv/make_clusters.cpp
  phv/phv_analysis.cpp
  phv/phv_fields.cpp
  phv/phv_parde_mau_use.cpp
  phv/phv_spec.cpp
  phv/trivial_alloc.cpp
  phv/utils.cpp
  phv/validate_allocation.cpp
  phv/analysis/field_interference.cpp
  phv/analysis/critical_path_clusters.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_PHV_SRCS}")
build_unified(BF_P4C_BACKEND_PHV_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_PHV_HDRS
  phv/action_phv_constraints.h
  phv/allocate_phv.h
  phv/asm_output.h
  phv/check_unallocated.h
  phv/cluster_phv_operations.h
  phv/constraints.h
  phv/create_thread_local_instances.h
  phv/cluster_to_cluster_interference.h
  phv/field_alignment.h
  phv/make_clusters.h
  phv/phv_analysis.h
  phv/phv_fields.h
  phv/phv_parde_mau_use.h
  phv/phv_spec.h
  phv/trivial_alloc.h
  phv/utils.h
  phv/validate_allocation.h
  phv/analysis/field_interference.h
  phv/analysis/critical_path_clusters.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_PHV_HDRS}")

set (BF_P4C_BACKEND_ARCH_SRCS
  arch/converters.cpp
  arch/native.cpp
  arch/phase0.cpp
  arch/program_structure.cpp
  arch/remove_set_metadata.cpp
  arch/simple_switch.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_ARCH_SRCS}")
build_unified(BF_P4C_BACKEND_ARCH_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_ARCH_HDRS
  arch/converters.h
  arch/native.h
  arch/phase0.h
  arch/program_structure.h
  arch/remove_set_metadata.h
  arch/simple_switch.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_ARCH_HDRS}")

set (BF_P4C_BACKEND_MAIN_SRCS
  backend.cpp
  device.cpp
  midend.cpp
  bf-p4c-options.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_MAIN_SRCS}")
build_unified(BF_P4C_BACKEND_MAIN_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_MAIN_HDRS
  backend.h
  device.h
  midend.h
  bf-p4c-options.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_MAIN_HDRS}")

set (BF_P4C_IR_DEF_FILES
  ${CMAKE_CURRENT_SOURCE_DIR}/ir/tofino.def
  ${CMAKE_CURRENT_SOURCE_DIR}/ir/arch.def
  ${CMAKE_CURRENT_SOURCE_DIR}/ir/mau.def
  ${CMAKE_CURRENT_SOURCE_DIR}/ir/parde.def
  ${CMAKE_CURRENT_SOURCE_DIR}/ir/parde-lowered.def
  )
# publish IR_DEF_FILES upstream
set (IR_DEF_FILES ${IR_DEF_FILES} ${BF_P4C_IR_DEF_FILES} PARENT_SCOPE)

set (p4include_HEADERS
  p4include/tofino.p4
  p4include/tofino/lpf.p4
  p4include/tofino/stratum.p4
  p4include/tofino/p4_14_prim.p4
  p4include/tofino/p4_14_types.p4
  p4include/tofino/p4_16_prim.p4
  p4include/tofino/stateful_alu.p4
  p4include/tofino/wred.p4
  )

set (p4_14include_HEADERS
  p4_14include/tofino/constants.p4
  p4_14include/tofino/intrinsic_metadata.p4
  p4_14include/tofino/lpf_blackbox.p4
  p4_14include/tofino/meter_blackbox.p4
  p4_14include/tofino/pktgen_headers.p4
  p4_14include/tofino/primitives.p4
  p4_14include/tofino/stateful_alu_blackbox.p4
  p4_14include/tofino/wred_blackbox.p4
  )

set (BF_P4C_SOURCES
  ${BF_P4C_BACKEND_COMMON_SRCS}
  ${BF_P4C_BACKEND_CONTROL_PLANE_SRCS}
  ${BF_P4C_BACKEND_MAU_SRCS}
  ${BF_P4C_BACKEND_PARDE_SRCS}
  ${BF_P4C_BACKEND_PHV_SRCS}
  ${BF_P4C_BACKEND_ARCH_SRCS}
  ${BF_P4C_BACKEND_MAIN_SRCS}
  )

set (P4C_BAREFOOT_SRCS
  p4c-barefoot.cpp
  ${BF_P4C_BACKEND_CONV_SRCS}
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${P4C_BAREFOOT_SRCS}")
build_unified(P4C_BAREFOOT_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

add_library(tofinobackend ${BF_P4C_SOURCES})
add_dependencies(tofinobackend genIR)

add_executable(p4c-barefoot ${P4C_BAREFOOT_SRCS})
target_link_libraries (p4c-barefoot tofinobackend ${P4C_LIBRARIES} ${P4C_LIB_DEPS})

install (TARGETS p4c-barefoot
  RUNTIME DESTINATION ${P4C_RUNTIME_OUTPUT_DIRECTORY})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/p4include
  DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/p4_14include
  DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY})

set (P4C_DRIVER_MACROS ${P4C_BINARY_DIR}/p4c_src/bfn_version.py)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/driver/bfn_version.in
  ${P4C_DRIVER_MACROS} @ONLY)

set (DRIVER_FILES
  ${CMAKE_CURRENT_SOURCE_DIR}/driver/barefoot.py
  ${CMAKE_CURRENT_SOURCE_DIR}/driver/p4c.tofino.cfg
  )
if (ENABLE_JBAY)
  set (DRIVER_FILES ${DRIVER_FILES}
    ${CMAKE_CURRENT_SOURCE_DIR}/driver/p4c.jbay.cfg)
endif (ENABLE_JBAY)

install (FILES ${DRIVER_FILES} ${P4C_DRIVER_MACROS}
  DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY}/p4c_src)

# hack to get around the fact that the test scripts expect the backend
# binary to be in the top level directory. This should go away when we
# fix the scripts.
add_custom_target(linkp4cbarefoot
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_BINARY_DIR}/p4c-barefoot ${P4C_BINARY_DIR}/p4c-barefoot
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4include
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4include/tofino
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4_14include
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4_14include/tofino
  COMMAND for h in ${p4include_HEADERS} ${p4_14include_HEADERS} \; do
     ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/\$$h ${P4C_BINARY_DIR}/\$$h \;
  done
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4c_src
  COMMAND ${CMAKE_COMMAND} -E copy ${DRIVER_FILES} ${P4C_BINARY_DIR}/p4c_src
  COMMAND ${CMAKE_COMMAND} -E copy ${P4C_DRIVER_MACROS} ${P4C_BINARY_DIR}/p4c_src
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${P4C_BINARY_DIR}/p4include ${CMAKE_CURRENT_BINARY_DIR}/p4include
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${P4C_BINARY_DIR}/p4_14include ${CMAKE_CURRENT_BINARY_DIR}/p4_14include
  )
add_dependencies(p4c_driver linkp4cbarefoot)

################ Testing

# # Tofino-specific GTests.
set (GTEST_BF_P4C_SOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/action_phv.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/bitrange.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/checksum.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/critical_path_clusters.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/field_alignment.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/field_packing.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/linear_path.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/multiple_apply.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/parser_critical_path.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv_constraints.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv_crush.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv_tofino.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv_jbay.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/tofino_write_context.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/tofino_gtest_utils.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/trivial_alloc.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/type_categories.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/union_find.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/vertex_weighted_coloring.cpp
  )

set (GTEST_SOURCES ${GTEST_SOURCES} ${GTEST_BF_P4C_SOURCES} PARENT_SCOPE)
set (GTEST_LDADD ${GTEST_LDADD} tofinobackend PARENT_SCOPE)
