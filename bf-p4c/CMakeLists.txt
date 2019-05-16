####### Barefoot back-end

MESSAGE("-- Adding p4c-barefoot")

# An option to configure the chunk size we use for unified builds in bf-p4c. By
# default, this is tuned to use smaller chunks than the p4c repo uses. The goal
# is to gain most of the benefit of unified builds when many files change, while
# keeping the impact on recompilation time for individual files to a minimum.
set(BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE "5" CACHE STRING
    "Target unified compilation chunk size for bf-p4c (an integer or ALL)")

# add_cxx_compiler_option ("-Werror")

set(OPENSSL_ROOT_DIR "/usr/local/opt/openssl")
if(ENABLE_STATIC_LIBS)
  set (OPENSSL_USE_STATIC_LIBS TRUE)
endif()
find_package (OpenSSL REQUIRED)
find_package (Boost REQUIRED COMPONENTS graph)
add_definitions("-DBOOST_NO_ARGUMENT_DEPENDENT_LOOKUP")
if (ENABLE_JBAY)
  add_definitions("-DHAVE_JBAY=1")
endif()
if (ENABLE_BAREFOOT_INTERNAL)
  add_definitions("-DBAREFOOT_INTERNAL=1")
endif()
include_directories(${BFN_P4C_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${Boost_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIR} ${LIBDYNHASH_INCLUDE_DIR} )
# The generated code for protobuf has an excessive number of warnings so we
# include the build directory as a system directory
include_directories(SYSTEM ${P4C_BINARY_DIR}/control-plane)
set (HAVE_LIBBOOST_GRAPH 1)
set (P4C_LIB_DEPS "${P4C_LIB_DEPS};${Boost_GRAPH_LIBRARY};${OPENSSL_LIBRARIES};${LIBDYNHASH_LIBRARY}")
set (P4C_LIB_DEPS ${P4C_LIB_DEPS} PARENT_SCOPE)

add_subdirectory(logging)
include_directories(logging)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/logging)

set (BF_P4C_IR_SRCS
  midend/path_linearizer.cpp
  ir/dbprint-tofino.cpp
  ir/bitrange.cpp
  ir/ir_enums.cpp
  ir/gress.cpp
  ir/mau.cpp
  ir/thread_visitor.cpp
  ir/tofino.cpp
  ir/tofino_write_context.cpp
  ir/unique_id.cpp
  mau/hash_function.cpp
  parde/clot.cpp
  parde/marshal.cpp
  parde/match_register.cpp
  phv/phv.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_IR_SRCS}")
set_source_files_properties(${BF_P4C_IR_SRCS} PROPERTIES
  COMPILE_FLAGS "-I${LIBDYNHASH_INCLUDE_DIR}")

set (BF_P4C_IR_HDRS
  midend/path_linearizer.h
  ir/bitrange.h
  ir/control_flow_visitor.h
  ir/gress.h
  ir/ir_enums.h
  ir/thread_visitor.h
  ir/tofino_write_context.h
  ir/unique_id.h
  mau/hash_function.h
  parde/clot.h
  parde/marshal.h
  parde/match_register.h
  phv/phv.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_IR_HDRS}")

set (BF_P4C_MIDEND_SRCS
  midend/check_header_alignment.cpp
  midend/check_unsupported.cpp
  midend/copy_block_pragmas.cpp
  midend/elim_cast.cpp
  midend/elim_typedef.cpp
  midend/desugar_varbit_extract.cpp
  midend/normalize_params.cpp
  midend/param_binding.cpp
  midend/simplify_emit_args.cpp
  midend/simplify_nested_if.cpp
  midend/simplify_references.cpp
  midend/type_categories.cpp
  midend/type_checker.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_MIDEND_SRCS}")
build_unified(BF_P4C_MIDEND_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_MIDEND_HDRS
  midend/blockmap.h
  midend/check_header_alignment.h
  midend/check_unsupported.h
  midend/copy_block_pragmas.h
  midend/elim_cast.h
  midend/desugar_varbit_extract.h
  midend/elim_typedef.h
  midend/normalize_params.h
  midend/param_binding.h
  midend/parser_graph.h
  midend/rewrite_egress_intrinsic_metadata_header.h
  midend/simplify_emit_args.h
  midend/simplify_nested_if.h
  midend/simplify_references.h
  midend/type_categories.h
  midend/type_checker.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_MIDEND_HDRS}")

set (BF_P4C_BACKEND_CONV_SRCS
  arch/fromv1.0/field_list.cpp
  arch/fromv1.0/lpf.cpp
  arch/fromv1.0/meter.cpp
  arch/fromv1.0/primitives.cpp
  arch/fromv1.0/programStructure.cpp
  arch/fromv1.0/stateful_alu.cpp
  arch/fromv1.0/wred.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_CONV_SRCS}")

set (BF_P4C_BACKEND_CONV_HDRS
  arch/fromv1.0/checksum.h
  arch/fromv1.0/field_list.h
  arch/fromv1.0/lpf.h
  arch/fromv1.0/meter.h
  arch/fromv1.0/programStructure.h
  arch/fromv1.0/stateful_alu.h
  arch/fromv1.0/wred.h
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
  common/alias.cpp
  common/asm_output.cpp
  common/bridged_metadata_replacement.cpp
  common/check_for_unimplemented_features.cpp
  common/collect_global_pragma.cpp
  common/copy_header_eliminator.cpp
  common/elim_unused.cpp
  common/extract_maupipe.cpp
  common/field_defuse.cpp
  common/flexible_packing.cpp
  common/header_stack.cpp
  common/ir_utils.cpp
  common/map_tables_to_actions.cpp
  common/multiple_apply.cpp
  common/run_id.cpp
  common/rewrite_flexible_struct.cpp
  common/slice.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_COMMON_SRCS}")
build_unified(BF_P4C_BACKEND_COMMON_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_COMMON_HDRS
  common/alias.h
  common/autoindent.h
  common/bridged_metadata_replacement.h
  common/check_for_unimplemented_features.h
  common/check_header_refs.h
  common/collect_global_pragma.h
  common/copy_header_eliminator.h
  common/debug_info.h
  common/elim_unused.h
  common/extract_maupipe.h
  common/field_defuse.h
  common/flexible_packing.h
  common/header_stack.h
  common/ir_utils.h
  common/map_tables_to_actions.h
  common/multiple_apply.h
  common/parse_annotations.h
  common/run_id.h
  common/rewrite_flexible_struct.h
  common/slice.h
  common/table_printer.h
  common/utils.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_COMMON_HDRS}")

set (BF_P4C_BACKEND_CONTROL_PLANE_SRCS
  control-plane/bfruntime.cpp
  control-plane/p4runtime_force_std.cpp
  control-plane/tofino_p4runtime.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_CONTROL_PLANE_SRCS}")
build_unified(BF_P4C_BACKEND_CONTROL_PLANE_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_CONTROL_PLANE_HDRS
  control-plane/bfruntime.h
  control-plane/p4runtime_force_std.h
  control-plane/tofino_p4runtime.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_CONTROL_PLANE_HDRS}")

set (BF_P4C_BACKEND_LIB_HDRS
  lib/cmp.h
  lib/error_type.h
  lib/union_find.hpp
  lib/vertex_weighted_coloring.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_LIB_HDRS}")

set (BF_P4C_BACKEND_MAU_SRCS
  mau/action_analysis.cpp
  mau/action_data_bus.cpp
  mau/action_format.cpp
  mau/action_format_2.cpp
  mau/action_mutex.cpp
  mau/asm_output.cpp
  mau/attached_output.cpp
  mau/characterize_power.cpp
  mau/dynhash.cpp
  mau/field_use.cpp
  mau/db-gateway.cpp
  mau/gateway.cpp
  mau/handle_assign.cpp
  mau/input_xbar.cpp
  mau/instruction_adjustment.cpp
  mau/instruction_memory.cpp
  mau/instruction_selection.cpp
  mau/ixbar_expr.cpp
  mau/ixbar_info.cpp
  mau/ixbar_realign.cpp
  mau/mau_alloc.cpp
  mau/memories.cpp
  mau/reduction_or.cpp
  mau/resource_estimate.cpp
  mau/resource.cpp
  mau/selector_update.cpp
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
  mau/table_injected_deps.cpp
  mau/upward_downward_prop.cpp
  mau/table_flow_graph.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_MAU_SRCS}")
build_unified(BF_P4C_BACKEND_MAU_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_MAU_HDRS
  mau/action_analysis.h
  mau/action_data_bus.h
  mau/action_format.h
  mau/action_format_2.h
  mau/action_mutex.h
  mau/asm_output.h
  mau/attached_output.h
  mau/characterize_power.h
  mau/dynhash.h
  mau/default_next.h
  mau/field_use.h
  mau/gateway.h
  mau/handle_assign.h
  mau/input_xbar.h
  mau/instruction_adjustment.h
  mau/instruction_memory.h
  mau/instruction_selection.h
  mau/ixbar_expr.h
  mau/ixbar_info.h
  mau/ixbar_realign.h
  mau/mau_alloc.h
  mau/memories.h
  mau/push_pop.h
  mau/reduction_or.h
  mau/remove_noop_gateway.h
  mau/resource_estimate.h
  mau/resource.h
  mau/selector_update.h
  mau/split_alpm.h
  mau/split_gateways.h
  mau/stateful_alu.h
  mau/static_entries_const_prop.h
  mau/table_dependency_graph.h
  mau/table_format.h
  mau/table_layout.h
  mau/table_mutex.h
  mau/table_placement.h
  mau/table_seqdeps.h
  mau/table_summary.h
  mau/table_injected_deps.h
  mau/upward_downward_prop.h
  mau/table_flow_graph.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_MAU_HDRS}")

set (BF_P4C_BACKEND_PARDE_SRCS
  parde/add_parde_metadata.cpp
  parde/adjust_extract.cpp
  parde/allocate_parser_match_register.cpp
  parde/checksum.cpp
  parde/clot_info.cpp
  parde/decaf.cpp
  parde/deparser_output.cpp
  parde/extract_parser.cpp
  parde/field_packing.cpp
  parde/gen_deparser.cpp
  parde/lower_parser.cpp
  parde/merge_parser_state.cpp
  parde/mirror.cpp
  parde/parser_output.cpp
  parde/infer_payload_offset.cpp
  parde/phase0.cpp
  parde/resolve_parser_values.cpp
  parde/resubmit.cpp
  parde/split_big_state.cpp
  parde/p4i/gen_parser_json.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_PARDE_SRCS}")
build_unified(BF_P4C_BACKEND_PARDE_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_PARDE_HDRS
  parde/add_parde_metadata.h
  parde/allocate_parser_checksum.h
  parde/allocate_parser_match_register.h
  parde/adjust_extract.h
  parde/asm_output.h
  parde/characterize_parser.h
  parde/checksum.h
  parde/clot_info.h
  parde/decaf.h
  parde/egress_packet_length.h
  parde/extract_parser.h
  parde/field_packing.h
  parde/gen_deparser.h
  parde/lower_parser.h
  parde/marshal.h
  parde/match_register.h
  parde/merge_parser_state.h
  parde/mirror.h
  parde/parde_spec.h
  parde/infer_payload_offset.h
  parde/phase0.h
  parde/resolve_parser_values.h
  parde/resubmit.h
  parde/parde_utils.h
  parde/parser_info.h
  parde/split_big_state.h
  parde/p4i/gen_parser_json.h
  parde/p4i/p4i_json_types.h
  parde/reset_invalidated_checksum_headers.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_PARDE_HDRS}")

set (BF_P4C_BACKEND_PHV_SRCS
  phv/action_phv_constraints.cpp
  phv/add_initialization.cpp
  phv/add_special_constraints.cpp
  phv/allocate_phv.cpp
  phv/asm_output.cpp
  phv/cluster_phv_operations.cpp
  phv/create_thread_local_instances.cpp
  phv/make_clusters.cpp
  phv/mau_backtracker.cpp
  phv/parde_phv_constraints.cpp
  phv/phv_analysis.cpp
  phv/phv_fields.cpp
  phv/phv_parde_mau_use.cpp
  phv/phv_spec.cpp
  phv/privatization.cpp
  phv/table_phv_constraints.cpp
  phv/trivial_alloc.cpp
  phv/validate_allocation.cpp
  phv/analysis/critical_path_clusters.cpp
  phv/analysis/dark_live_range.cpp
  phv/analysis/deparser_zero.cpp
  phv/analysis/dominator_tree.cpp
  phv/analysis/meta_live_range.cpp
  phv/analysis/mutex_overlay.cpp
  phv/analysis/live_range_shrinking.cpp
  phv/analysis/pack_conflicts.cpp
  phv/analysis/parser_critical_path.cpp
  phv/pragma/pa_alias.cpp
  phv/pragma/pa_atomic.cpp
  phv/pragma/pa_container_size.cpp
  phv/pragma/pa_container_type.cpp
  phv/pragma/pa_deparser_zero.cpp
  phv/pragma/pa_mutually_exclusive.cpp
  phv/pragma/pa_no_init.cpp
  phv/pragma/pa_no_overlay.cpp
  phv/pragma/pa_solitary.cpp
  phv/utils/live_range_report.cpp
  phv/utils/report.cpp
  phv/utils/slicing_iterator.cpp
  phv/utils/utils.cpp
  )
if (ENABLE_JBAY)
  list (APPEND BF_P4C_BACKEND_PHV_SRCS
    phv/analysis/dark.cpp
    phv/analysis/jbay_phv_analysis.cpp
    phv/analysis/mocha.cpp)
endif()

add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_PHV_SRCS}")
build_unified(BF_P4C_BACKEND_PHV_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_PHV_HDRS
  phv/action_phv_constraints.h
  phv/add_initialization.h
  phv/add_special_constraints.h
  phv/allocate_phv.h
  phv/asm_output.h
  phv/check_unallocated.h
  phv/cluster_phv_operations.h
  phv/create_thread_local_instances.h
  phv/parser_extract_balance_score.h
  phv/make_clusters.h
  phv/mau_backtracker.h
  phv/parde_phv_constraints.h
  phv/phv_analysis.h
  phv/phv_fields.h
  phv/phv_parde_mau_use.h
  phv/phv_spec.h
  phv/privatization.h
  phv/table_phv_constraints.h
  phv/trivial_alloc.h
  phv/validate_allocation.h
  phv/analysis/critical_path_clusters.h
  phv/analysis/dark_live_range.h
  phv/analysis/deparser_zero.h
  phv/analysis/dominator_tree.h
  phv/analysis/meta_live_range.h
  phv/analysis/mutex_overlay.h
  phv/analysis/live_range_shrinking.h
  phv/analysis/pack_conflicts.h
  phv/analysis/parser_critical_path.h
  phv/pragma/pa_alias.h
  phv/pragma/pa_atomic.h
  phv/pragma/pa_container_size.h
  phv/pragma/pa_container_type.h
  phv/pragma/pa_deparser_zero.h
  phv/pragma/pa_mutually_exclusive.h
  phv/pragma/pa_no_init.h
  phv/pragma/pa_no_overlay.h
  phv/pragma/pa_solitary.h
  phv/pragma/phv_pragmas.h
  phv/utils/live_range_report.h
  phv/utils/report.h
  phv/utils/slicing_iterator.h
  phv/utils/utils.h
  )
if (ENABLE_JBAY)
  list (APPEND BF_P4C_BACKEND_PHV_HDRS
    phv/analysis/dark.h
    phv/analysis/jbay_phv_analysis.h
    phv/analysis/mocha.h)
endif ()
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_PHV_HDRS}")

set (BF_P4C_BACKEND_ARCH_SRCS
  arch/arch.cpp
  arch/bridge_metadata.cpp
  arch/check_extern_invocation.cpp
  arch/collect_bridged_fields.cpp
  arch/program_structure.cpp
  arch/psa.cpp
  arch/psa_converters.cpp
  arch/psa_model.cpp
  arch/psa_program_structure.cpp
  arch/remove_set_metadata.cpp
  arch/rewrite_packet_path.cpp
  arch/tna.cpp
  arch/v1model.cpp
  arch/fromv1.0/phase0.cpp
  arch/fromv1.0/v1_converters.cpp
  arch/fromv1.0/v1_program_structure.cpp
  )
if (ENABLE_JBAY)
  list (APPEND BF_P4C_BACKEND_ARCH_SRCS
  arch/t2na.cpp)
endif ()
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_ARCH_SRCS}")
build_unified(BF_P4C_BACKEND_ARCH_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_ARCH_HDRS
  arch/arch.h
  arch/intrinsic_metadata.h
  arch/bridge_metadata.h
  arch/check_extern_invocation.h
  arch/collect_bridged_fields.h
  arch/program_structure.h
  arch/psa.h
  arch/psa_converters.h
  arch/psa_model.h
  arch/psa_program_structure.h
  arch/remove_set_metadata.h
  arch/rewrite_packet_path.h
  arch/tna.h
  arch/v1model.h
  arch/fromv1.0/phase0.h
  arch/fromv1.0/v1_converters.h
  arch/fromv1.0/v1_program_structure.h
  )
if (ENABLE_JBAY)
  list (APPEND BF_P4C_BACKEND_ARCH_HDRS
  arch/t2na.h)
endif ()
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_ARCH_HDRS}")

set (BF_P4C_BACKEND_LOGGING_HDRS
  logging/filelog.h
  logging/logging.h
  logging/manifest.h
  logging/pass_manager.h
  logging/phv_logging.h
  logging/resources.h
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_LOGGING_HDRS}")
set (BF_P4C_BACKEND_LOGGING_SRCS
  logging/filelog.cpp
  logging/manifest.cpp
  logging/phv_logging.cpp
  logging/resources.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_LOGGING_SRCS}")

set (BF_P4C_BACKEND_MAIN_SRCS
  backend.cpp
  bf-p4c-options.cpp
  device.cpp
  midend.cpp
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${BF_P4C_BACKEND_MAIN_SRCS}")
build_unified(BF_P4C_BACKEND_MAIN_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

set (BF_P4C_BACKEND_MAIN_HDRS
  asm.h
  backend.h
  bf-p4c-options.h
  device.h
  midend.h
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

# do not add to cpp lint. They are added as part of the p4c-graphs backend
set (BF_P4C_GRAPHS_HDRS
  ${P4C_SOURCE_DIR}/backends/graphs/controls.h
  ${P4C_SOURCE_DIR}/backends/graphs/graphs.h
  ${P4C_SOURCE_DIR}/backends/graphs/parsers.h
  )
set (BF_P4C_GRAPHS_SRCS
  ${P4C_SOURCE_DIR}/backends/graphs/controls.cpp
  ${P4C_SOURCE_DIR}/backends/graphs/graphs.cpp
  ${P4C_SOURCE_DIR}/backends/graphs/parsers.cpp
  )

set (p4include_HEADERS
  p4include/tofino.p4
  p4include/tna.p4
  p4include/tofino/lpf.p4
  p4include/tofino/meter.p4
  p4include/tofino/stratum.p4
  p4include/tofino/p4_14_prim.p4
  p4include/tofino/stateful_alu.p4
  p4include/tofino/wred.p4
  p4include/psa.p4
  )

if (ENABLE_JBAY)
set (p4include_HEADERS
  ${p4include_HEADERS}
  p4include/tofino2.p4
  p4include/t2na.p4
  )
endif (ENABLE_JBAY)

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

# hack to support jbay clone metadata in p4-14.
# used by mirror_test.p4 which should be rewritten to p4-16.
if (ENABLE_JBAY)
set (hack_p4_14include_HEADERS
  p4_14include/tofino2/intrinsic_metadata.p4
  )
endif (ENABLE_JBAY)

set (BF_P4C_SOURCES
  ${BF_P4C_MIDEND_SRCS}
  ${BF_P4C_BACKEND_COMMON_SRCS}
  ${BF_P4C_BACKEND_CONTROL_PLANE_SRCS}
  ${BF_P4C_BACKEND_LOGGING_SRCS}
  ${BF_P4C_BACKEND_MAU_SRCS}
  ${BF_P4C_BACKEND_PARDE_SRCS}
  ${BF_P4C_BACKEND_PHV_SRCS}
  ${BF_P4C_BACKEND_ARCH_SRCS}
  ${BF_P4C_BACKEND_MIDEND_SRCS}
  ${BF_P4C_BACKEND_MAIN_SRCS}
  )

set (P4C_BAREFOOT_SRCS
  p4c-barefoot.cpp
  ${BF_P4C_BACKEND_CONV_SRCS}
  ${BF_P4C_GRAPHS_SRCS}
  )
add_cpplint_files(${CMAKE_CURRENT_SOURCE_DIR} "${P4C_BAREFOOT_SRCS}")
build_unified(P4C_BAREFOOT_SRCS ${BF_P4C_UNIFIED_SOURCE_CHUNK_SIZE})

add_library(tofinobackend ${BF_P4C_SOURCES})
add_dependencies(tofinobackend genIR genLogging bfn_p4runtime)

add_executable(p4c-barefoot ${P4C_BAREFOOT_SRCS})
target_link_libraries (p4c-barefoot tofinobackend bfn_p4runtime
  ${P4C_LIBRARIES} ${P4C_LIB_DEPS} ${CMAKE_THREAD_LIBS_INIT})

install (TARGETS p4c-barefoot
  RUNTIME DESTINATION ${P4C_RUNTIME_OUTPUT_DIRECTORY})
if (NOT ENABLE_JBAY)
  install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/p4include
    DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY}
    REGEX "tofino2|t2na" EXCLUDE)
  install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/p4_14include
    DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY}
    REGEX "tofino2|t2na" EXCLUDE)
else()
  install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/p4include
    DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY})
  install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/p4_14include
    DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY})
endif()
install (PROGRAMS ${BFN_P4C_SOURCE_DIR}/scripts/p4_14-to-p4_16
  DESTINATION ${P4C_RUNTIME_OUTPUT_DIRECTORY})

set (MANIFEST_CONFIG ${BFN_P4C_SOURCE_DIR}/scripts/p4c-manifest-config
  CACHE FILEPATH "Path to p4c-manifest-config")
set (GEN_DRIVER_CONF ${BFN_P4C_SOURCE_DIR}/scripts/p4c-gen-conf
  CACHE FILEPATH "Path to p4c-gen-conf")
set (GEN_BFRT_CONF ${BFN_P4C_SOURCE_DIR}/scripts/p4c-gen-bfrt-conf
  CACHE FILEPATH "Path to p4c-gen-bfrt-conf")
set (GEN_BFRT_SCHEMA ${CMAKE_CURRENT_SOURCE_DIR}/control-plane/p4c-gen-bfrt-schema
  CACHE FILEPATH "Path to p4c-gen-bfrt-schema")

install (PROGRAMS ${GEN_BFRT_SCHEMA} ${GEN_BFRT_CONF} ${MANIFEST_CONFIG} ${GEN_DRIVER_CONF}
  DESTINATION ${P4C_RUNTIME_OUTPUT_DIRECTORY})

set (P4C_DRIVER_MACROS ${P4C_BINARY_DIR}/p4c_src/bfn_version.py)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/driver/bfn_version.in
  ${P4C_DRIVER_MACROS} @ONLY)

set (DRIVER_FILES
  ${CMAKE_CURRENT_SOURCE_DIR}/driver/barefoot.py
  ${CMAKE_CURRENT_SOURCE_DIR}/driver/p4c.tofino.cfg
  )
if (ENABLE_JBAY)
  set (JBAY_TARGET_CFG_FILE ${P4C_BINARY_DIR}/p4c_src/p4c.tofino2.cfg)
  set_source_files_properties (${JBAY_TARGET_CFG_FILE} PROPERTIES GENERATED TRUE)
  # hack used to compile p4-14 program to JBay, we should not develop anything
  # significant with P4-14, it is only used to support existing programs.
  add_custom_target(jbay_hack
    COMMAND ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/p4_14include/tofino2
    COMMAND for h in ${hack_p4_14include_HEADERS} \; do
      ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/\$$h ${P4C_BINARY_DIR}/\$$h \;
    done
    )
  add_dependencies(p4c_driver jbay_hack)
  if (NOT ENABLE_BAREFOOT_INTERNAL)
    # Remove the P4-14 support for JBay
    add_custom_command(OUTPUT ${JBAY_TARGET_CFG_FILE}
      COMMAND sed -e '/v1model/d' ${CMAKE_CURRENT_SOURCE_DIR}/driver/p4c.tofino2.cfg > ${JBAY_TARGET_CFG_FILE}
      COMMENT "Removing P4-14 support for Tofino2"
      )
  else()
    add_custom_command(OUTPUT ${JBAY_TARGET_CFG_FILE}
      COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_CURRENT_SOURCE_DIR}/driver/p4c.tofino2.cfg ${JBAY_TARGET_CFG_FILE}
      COMMENT "Copying Tofino2 config"
      )
  endif()
  add_custom_target(remove_p4_14_for_jbay ALL DEPENDS ${JBAY_TARGET_CFG_FILE})
  add_dependencies(p4c_driver remove_p4_14_for_jbay)
endif (ENABLE_JBAY)

install (FILES ${DRIVER_FILES} ${JBAY_TARGET_CFG_FILE} ${P4C_DRIVER_MACROS}
  DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY}/p4c_src)

# install the tools that generate logging
set (INTERFACES_DIR ${BFN_P4C_SOURCE_DIR}/compiler_interfaces)
set (LOGGING_FILES
  ${INTERFACES_DIR}/p4c-build-logs
  ${INTERFACES_DIR}/tools/create_mau_json.py
  ${INTERFACES_DIR}/tools/create_phv_json.py
  ${INTERFACES_DIR}/tools/create_mau_characterize.py
  ${INTERFACES_DIR}/tools/create_mau_resources.py
  ${INTERFACES_DIR}/tools/create_pa_characterize.py
  ${INTERFACES_DIR}/tools/create_pa_results.py
  ${INTERFACES_DIR}/tools/utils.py
  ${INTERFACES_DIR}/tools/__init__.py
  )
set (SCHEMA_FILES
  ${INTERFACES_DIR}/schemas/context_schema.py
  ${INTERFACES_DIR}/schemas/manifest_schema.py
  ${INTERFACES_DIR}/schemas/mau_schema.py
  ${INTERFACES_DIR}/schemas/phv_schema.py
  ${INTERFACES_DIR}/schemas/power_schema.py
  ${INTERFACES_DIR}/schemas/resources_schema.py
  ${INTERFACES_DIR}/schemas/schema_enum_values.py
  ${INTERFACES_DIR}/schemas/schema_keys.py
  ${INTERFACES_DIR}/schemas/__init__.py
  )

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/dist/p4c-build-logs
  POST_BUILD
  COMMAND PYTHONPATH=${INTERFACES_DIR} pyinstaller --onefile --workpath=${CMAKE_CURRENT_BINARY_DIR}/build --distpath=${CMAKE_CURRENT_BINARY_DIR}/dist ${INTERFACES_DIR}/p4c-build-logs.spec
  DEPENDS ${LOGGING_FILES} ${SCHEMA_FILES} ${INTERFACES_DIR}/p4c-build-logs.spec
  WORKING_DIRECTORY ${INTERFACES_DIR}
  COMMENT "Package logging tools")

add_custom_target(p4c-build-logs
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/dist/p4c-build-logs)
add_dependencies(p4c_driver p4c-build-logs)

install (PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/dist/p4c-build-logs
  DESTINATION bin)

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
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${MANIFEST_CONFIG} ${P4C_BINARY_DIR}/p4c-manifest-config
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${GEN_BFRT_CONF} ${P4C_BINARY_DIR}/p4c-gen-bfrt-conf
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${GEN_DRIVER_CONF} ${P4C_BINARY_DIR}/p4c-gen-conf
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${GEN_BFRT_SCHEMA} ${P4C_BINARY_DIR}/p4c-gen-bfrt-schema
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${P4C_BINARY_DIR}/p4include ${CMAKE_CURRENT_BINARY_DIR}/p4include
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${P4C_BINARY_DIR}/p4_14include ${CMAKE_CURRENT_BINARY_DIR}/p4_14include
  )
add_dependencies(p4c_driver linkp4cbarefoot)



# Set default target and architecture to tofino-tna
add_custom_command(OUTPUT ${P4C_BINARY_DIR}/bf-p4c
  # should cythonify bf-p4c
  COMMAND ${CMAKE_COMMAND} -E copy_if_different ${P4C_BINARY_DIR}/p4c ${P4C_BINARY_DIR}/bf-p4c
  COMMAND sed -i'' -e 's/bmv2/tofino/g' ${P4C_BINARY_DIR}/p4c_src/main.py
  COMMAND sed -i'' -e 's/v1model/default/g' ${P4C_BINARY_DIR}/p4c_src/main.py
  COMMENT "Set default target and architecture to tofino-default"
  WORKING_DIRECTORY ${P4C_BINARY_DIR}
  DEPENDS p4c_driver ${P4C_BINARY_DIR}/p4c_src/main.py
  )
# force the generation of the bf-p4c package
add_custom_target(bf-p4c ALL DEPENDS ${P4C_BINARY_DIR}/bf-p4c)
install (PROGRAMS ${P4C_BINARY_DIR}/bf-p4c DESTINATION bin)
install (FILES ${P4C_BINARY_DIR}/p4c_src/main.py
  DESTINATION ${P4C_ARTIFACTS_OUTPUT_DIRECTORY}/p4c_src)

################ Proto
set (BFN_P4RUNTIME_DIR ${CMAKE_CURRENT_SOURCE_DIR}/control-plane/proto)
set (BFN_P4RUNTIME_INFO_PROTO ${BFN_P4RUNTIME_DIR}/barefoot/p4info.proto)
set (BFN_P4RUNTIME_INFO_GEN_SRCS ${P4C_BINARY_DIR}/control-plane/barefoot/p4info.pb.cc)
set (BFN_P4RUNTIME_INFO_GEN_HDRS ${P4C_BINARY_DIR}/control-plane/barefoot/p4info.pb.h)
# The generated code for protobuf has an excessive number of warnings
set_source_files_properties(${BFN_P4RUNTIME_INFO_GEN_SRCS} PROPERTIES
  COMPILE_FLAGS "-Wno-unused-parameter")

add_custom_target (barefootdir
  ${CMAKE_COMMAND} -E make_directory ${P4C_BINARY_DIR}/control-plane/barefoot)
# Generate source code from .proto using protoc. The output is
# placed in the build directory inside `control-plane` directory
add_custom_command(
  OUTPUT ${BFN_P4RUNTIME_INFO_GEN_SRCS} ${BFN_P4RUNTIME_INFO_GEN_HDRS}
  COMMAND ${PROTOBUF_PROTOC_EXECUTABLE}
          --proto_path ${BFN_P4RUNTIME_DIR}
          --proto_path ${P4C_SOURCE_DIR}/control-plane/p4runtime/proto
          --cpp_out ${P4C_BINARY_DIR}/control-plane
          --python_out ${P4C_BINARY_DIR}/control-plane
          ${BFN_P4RUNTIME_INFO_PROTO}
  DEPENDS ${BFN_P4RUNTIME_INFO_PROTO}
  COMMENT "Generating protobuf files for p4info."
  )

add_library(bfn_p4runtime STATIC ${BFN_P4RUNTIME_INFO_GEN_SRCS})
set_source_files_properties (${BFN_P4RUNTIME_INFO_GEN_SRCS} PROPERTIES GENERATED TRUE)
add_dependencies(bfn_p4runtime barefootdir controlplane)

################ Testing

if (ENABLE_TESTING)
  # # Tofino-specific GTests.
  set (GTEST_BF_P4C_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/action_format_helper.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/action_mutex.cpp
    # ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/action_phv.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/bitrange.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/checksum.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/critical_path_clusters.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/dominator_tree.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/field_alignment.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/field_packing.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/meta_live_range.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/mocha_dark.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/no_co_pack.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/multiple_apply.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/pa_atomic.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/pa_mutually_exclusive_pragma.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/pa_no_overlay.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/pa_container_size.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/pa_container_type.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/pa_solitary.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/parser_critical_path.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/parser_constant_extract.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv_crush.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv_field.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/path_linearizer.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv_tofino.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/phv_jbay.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/resolve_parser_values.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/table_dependency_graph.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/tofino_write_context.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/tofino_gtest_utils.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/tphv_slice.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/trivial_alloc.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/type_categories.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/union_find.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/v1model_translate.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/vertex_weighted_coloring.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/gtest/table_flow_graph.cpp
    ${BF_P4C_GRAPHS_SRCS}
    )

  set (GTEST_SOURCES ${GTEST_SOURCES} ${GTEST_BF_P4C_SOURCES} PARENT_SCOPE)
  set (GTEST_LDADD ${GTEST_LDADD} "tofinobackend;${OPENSSL_LIBRARIES};${LIBDYNHASH_LIBRARY}" PARENT_SCOPE)

  add_test(NAME test_p4c_driver
    COMMAND ${BFN_P4C_SOURCE_DIR}/scripts/test_p4c_driver.py -j 4 --print-on-failure --compiler ${P4C_BINARY_DIR}/bf-p4c
    WORKING_DIRECTORY ${P4C_BINARY_DIR})
  set_tests_properties(test_p4c_driver PROPERTIES LABELS lint)
endif(ENABLE_TESTING)
