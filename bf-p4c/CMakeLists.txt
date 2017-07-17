# Copyright 2013-present Barefoot Networks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####### Tofino back-end

MESSAGE("-- Adding p4c-tofino")

find_package (Boost REQUIRED COMPONENTS graph)
add_definitions("-DBOOST_NO_ARGUMENT_DEPENDENT_LOOKUP")
include_directories(${Boost_INCLUDE_DIRS})
set (HAVE_LIBBOOST_GRAPH 1)
set (P4C_LIB_DEPS "${P4C_LIB_DEPS};${Boost_GRAPH_LIBRARY}")

set (TOFINO_IR_SRCS
  ir/dbprint-tofino.cpp
  ir/gress.cpp
  ir/mau.cpp
  ir/parde.cpp
  ir/thread_visitor.cpp
  ir/tofino.cpp
  ir/tofino_write_context.cpp
  )

set (TOFINO_IR_HDRS
  ir/gress.h
  ir/thread_visitor.h
  ir/tofino_write_context.h
  )

set (TOFINO_BACKEND_CONV_SRCS
  fromv1.0/stateful_alu.cpp
  )

set (TOFINO_BACKEND_CONV_HDRS
  fromv1.0/stateful_alu.h
  )

# IR sources that need to go into the frontend library
set(QUAL_TOFINO_IR_SRCS)
foreach(src IN LISTS TOFINO_IR_SRCS)
  set(QUAL_TOFINO_IR_SRCS ${QUAL_TOFINO_IR_SRCS} ${CMAKE_CURRENT_SOURCE_DIR}/${src})
endforeach()
set(EXTENSION_FRONTEND_SOURCES ${EXTENSION_FRONTEND_SOURCES} ${QUAL_TOFINO_IR_SRCS} PARENT_SCOPE)

# sources that need to be linked directly in p4test to properly handle
# p4 14 to 16 conversion
set(QUAL_TOFINO_P4_14_CONV_SRCS)
foreach(src IN LISTS TOFINO_BACKEND_CONV_SRCS)
  set(QUAL_TOFINO_P4_14_CONV_SRCS ${QUAL_TOFINO_P4_14_CONV_SRCS} ${CMAKE_CURRENT_SOURCE_DIR}/${src})
endforeach()
set(EXTENSION_P4_14_CONV_SOURCES ${EXTENSION_P4_14_CONV_SOURCES} ${QUAL_TOFINO_P4_14_CONV_SRCS} PARENT_SCOPE)


set (TOFINO_BACKEND_COMMON_SRCS
  common/asm_output.cpp
  common/copy_header_eliminator.cpp
  common/elim_unused.cpp
  common/extract_maupipe.cpp
  common/field_defuse.cpp
  common/header_stack.cpp
  common/live_at_entry.cpp
  common/live_range_overlay.cpp
  common/metadata_constant_propagation.cpp
  common/remap_intrin.cpp
  common/param_binding.cpp
  common/parser_overlay.cpp
  common/slice.cpp
  )

set (TOFINO_BACKEND_COMMON_HDRS
  common/blockmap.h
  common/copy_header_eliminator.h
  common/elim_unused.h
  common/extract_maupipe.h
  common/field_defuse.h
  common/header_stack.h
  common/live_at_entry.h
  common/live_range_overlay.h
  common/metadata_constant_propagation.h
  common/remap_intrin.h
  common/param_binding.h
  common/parser_overlay.h
  common/slice.h
  )

set (TOFINO_BACKEND_MAU_SRCS
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

set (TOFINO_BACKEND_MAU_HDRS
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

set (TOFINO_BACKEND_PARDE_SRCS
  parde/add_parde_metadata.cpp
  parde/bridge_metadata.cpp
  parde/deparser_output.cpp
  parde/extract_parser.cpp
  parde/field_packing.cpp
  parde/gen_deparser.cpp
  parde/match_keys.cpp
  parde/parser_output.cpp
  parde/phase0.cpp
  parde/split_big_states.cpp
  )

set (TOFINO_BACKEND_PARDE_HDRS
  parde/add_parde_metadata.h
  parde/asm_output.h
  parde/bridge_metadata.h
  parde/compute_shifts.h
  parde/extract_parser.h
  parde/field_packing.h
  parde/match_keys.h
  parde/phase0.h
  parde/split_big_states.h
  )

set (TOFINO_BACKEND_PHV_SRCS
  phv/asm_output.cpp
  phv/cluster.cpp
  phv/cluster_phv_bind.cpp
  phv/cluster_phv_container.cpp
  phv/cluster_phv_interference.cpp
  phv/cluster_phv_mau.cpp
  phv/cluster_phv_operations.cpp
  phv/cluster_phv_overlay.cpp
  phv/cluster_phv_req.cpp
  phv/cluster_phv_slicing.cpp
  phv/phv.cpp
  phv/phv_analysis_api.cpp
  phv/phv_analysis_validate.cpp
  phv/phv_assignment_api.cpp
  phv/phv_assignment_validate.cpp
  phv/phv_fields.cpp
  phv/repack_metadata.cpp
  phv/split_phv_use.cpp
  phv/trivial_alloc.cpp
  phv/validate_allocation.cpp
  )

set (TOFINO_BACKEND_PHV_HDRS
  phv/asm_output.h
  phv/cluster.h
  phv/cluster_phv_bind.h
  phv/cluster_phv_container.h
  phv/cluster_phv_interference.h
  phv/cluster_phv_mau.h
  phv/cluster_phv_operations.h
  phv/cluster_phv_overlay.h
  phv/cluster_phv_req.h
  phv/cluster_phv_slicing.h
  phv/phv_analysis_api.h
  phv/phv_assignment_api.h
  phv/phv_assignment_validate.h
  phv/phv_fields.h
  phv/phv.h
  phv/split_phv_use.h
  phv/trivial_alloc.h
  phv/validate_allocation.h
  )

set (TOFINO_BACKEND_ARCH_SRCS
  arch/simple_switch.cpp
  )

set (TOFINO_BACKEND_ARCH_HDRS
  arch/simple_switch.h
  )

set (TOFINO_BACKEND_MAIN_SRCS
  backend.cpp
  midend.cpp
  )

set (TOFINO_BACKEND_MAIN_HDRS
  backend.h
  midend.h
  tofinoOptions.h
  )

set (TOFINO_IR_DEF_FILES
  ${CMAKE_CURRENT_SOURCE_DIR}/ir/tofino.def
  ${CMAKE_CURRENT_SOURCE_DIR}/ir/mau.def
  ${CMAKE_CURRENT_SOURCE_DIR}/ir/parde.def
  )
# publish IR_DEF_FILES upstream
set (IR_DEF_FILES ${IR_DEF_FILES} ${TOFINO_IR_DEF_FILES} PARENT_SCOPE)

set (p4include_HEADERS
  p4include/tofino_model.p4
  p4include/tofino.p4
  p4include/tofino/stateful_alu.p4
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

set (TOFINO_SOURCES
  ${TOFINO_BACKEND_COMMON_SRCS}
  ${TOFINO_BACKEND_MAU_SRCS}
  ${TOFINO_BACKEND_PARDE_SRCS}
  ${TOFINO_BACKEND_PHV_SRCS}
  ${TOFINO_BACKEND_ARCH_SRCS}
  ${TOFINO_BACKEND_MAIN_SRCS}
  )
set (TOFINO_HEADERS
  ${TOFINO_IR_HDRS}
  ${TOFINO_BACKEND_COMMON_HDRS}
  ${TOFINO_BACKEND_MAU_HDRS}
  ${TOFINO_BACKEND_PARDE_HDRS}
  ${TOFINO_BACKEND_PHV_HDRS}
  ${TOFINO_BACKEND_ARCH_HDRS}
  ${TOFINO_BACKEND_MAIN_HDRS}
  )

set (P4C_TOFINO_SRCS
  p4c-tofino.cpp
  ${TOFINO_BACKEND_CONV_SRCS}
  )


set (tofino_cpplint ${TOFINO_IR_SRCS} ${TOFINO_SOURCES} ${TOFINO_HEADERS} ${P4C_TOFINO_SRCS})
add_cpplint_files( ${CMAKE_CURRENT_SOURCE_DIR} "${tofino_cpplint}")

add_library(tofinobackend ${TOFINO_SOURCES})
add_dependencies(tofinobackend genIR)

add_executable(p4c-tofino ${P4C_TOFINO_SRCS})
target_link_libraries (p4c-tofino tofinobackend ${P4C_LIBRARIES} ${P4C_LIB_DEPS})

# hack to get around the fact that the test scripts expect the backend
# binary to be in the top level directory. This should go away when we
# remove automake and fix the scripts.
add_custom_target(linktofino
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_CURRENT_BINARY_DIR}/p4c-tofino ${P4C_BINARY_DIR}/p4c-tofino
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4include
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4include/tofino
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4_14include
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4_14include/tofino
  COMMAND for h in ${p4include_HEADERS} ${p4_14include_HEADERS} \; do
     ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/\$$h ${P4C_BINARY_DIR}/\$$h \;
  done
  COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4c_src
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/driver/p4c.tofino.cfg ${P4C_BINARY_DIR}/p4c_src
  )
add_dependencies(p4c_driver linktofino)

################ Testing

# # Tofino-specific GTests.
set (GTEST_TOFINO_SOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/tofino_write_context.cpp
  ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/trivial_alloc.cpp
  )

set (GTEST_SOURCES ${GTEST_SOURCES} ${GTEST_TOFINO_SOURCES} PARENT_SCOPE)
set (GTEST_LDADD ${GTEST_LDADD} tofinobackend PARENT_SCOPE)
