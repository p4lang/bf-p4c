####### Tofino back-end

tofino_ir_UNIFIED = \
	%reldir%/ir/dbprint-tofino.cpp \
	%reldir%/ir/mau.cpp \
	%reldir%/ir/parde.cpp \
	%reldir%/ir/thread_visitor.cpp \
	%reldir%/ir/tofino.cpp

noinst_HEADERS += \
	%reldir%/ir/thread_visitor.h

cpplint_FILES += $(tofino_ir_UNIFIED) $(tofino_ir_NONUNIFIED)
extension_frontend_SOURCES += $(tofino_ir_SOURCES)

tofino_backend_common_UNIFIED = \
	%reldir%/common/asm_output.cpp \
	%reldir%/common/copy_header_eliminator.cpp \
	%reldir%/common/elim_unused.cpp \
	%reldir%/common/extract_maupipe.cpp \
	%reldir%/common/field_defuse.cpp \
	%reldir%/common/header_stack.cpp \
	%reldir%/common/live_at_entry.cpp \
	%reldir%/common/remap_intrin.cpp \
	%reldir%/common/param_binding.cpp \
	%reldir%/common/phv.cpp

noinst_HEADERS += \
	%reldir%/common/blockmap.h \
	%reldir%/common/copy_header_eliminator.h \
	%reldir%/common/elim_unused.h \
	%reldir%/common/extract_maupipe.h \
	%reldir%/common/field_defuse.h \
	%reldir%/common/header_stack.h \
	%reldir%/common/live_at_entry.h \
	%reldir%/common/remap_intrin.h \
	%reldir%/common/param_binding.h \
	%reldir%/common/phv.h

cpplint_FILES += $(tofino_backend_common_UNIFIED) $(tofino_backend_common_NONUNIFIED)

tofino_backend_mau_UNIFIED = \
	%reldir%/mau/asm_output.cpp \
	%reldir%/mau/field_use.cpp \
	%reldir%/mau/db-gateway.cpp \
	%reldir%/mau/gateway.cpp \
	%reldir%/mau/input_xbar.cpp \
	%reldir%/mau/instruction_selection.cpp \
	%reldir%/mau/ixbar_realign.cpp \
	%reldir%/mau/memories.cpp \
	%reldir%/mau/phv_constraints.cpp \
	%reldir%/mau/resource_estimate.cpp \
	%reldir%/mau/split_gateways.cpp \
	%reldir%/mau/table_dependency_graph.cpp \
	%reldir%/mau/table_layout.cpp \
	%reldir%/mau/table_mutex.cpp \
	%reldir%/mau/table_placement.cpp \
	%reldir%/mau/table_seqdeps.cpp \
	%reldir%/mau/table_summary.cpp

noinst_HEADERS += \
	%reldir%/mau/asm_output.h \
	%reldir%/mau/default_next.h \
	%reldir%/mau/field_use.h \
	%reldir%/mau/gateway.h \
	%reldir%/mau/input_xbar.h \
	%reldir%/mau/instruction_selection.h \
	%reldir%/mau/ixbar_realign.h \
	%reldir%/mau/memories.h \
	%reldir%/mau/phv_constraints.h \
	%reldir%/mau/push_pop.h \
	%reldir%/mau/resource_estimate.h \
	%reldir%/mau/resource.h \
	%reldir%/mau/split_gateways.h \
	%reldir%/mau/table_dependency_graph.h \
	%reldir%/mau/table_layout.h \
	%reldir%/mau/table_mutex.h \
	%reldir%/mau/table_placement.h \
	%reldir%/mau/table_seqdeps.h \
	%reldir%/mau/table_summary.h

cpplint_FILES += $(tofino_backend_mau_UNIFIED) $(tofino_backend_mau_NONUNIFIED)

tofino_backend_parde_UNIFIED = \
	%reldir%/parde/add_parde_metadata.cpp \
	%reldir%/parde/bridge_metadata.cpp \
	%reldir%/parde/deparser_output.cpp \
	%reldir%/parde/extract_parser.cpp \
	%reldir%/parde/gen_deparser.cpp \
	%reldir%/parde/match_keys.cpp \
	%reldir%/parde/parser_output.cpp \
	%reldir%/parde/split_big_states.cpp \
	%reldir%/parde/split_header.cpp

noinst_HEADERS += \
	%reldir%/parde/add_parde_metadata.h \
	%reldir%/parde/asm_output.h \
	%reldir%/parde/bridge_metadata.h \
	%reldir%/parde/compute_shifts.h \
	%reldir%/parde/extract_parser.h \
	%reldir%/parde/match_keys.h \
	%reldir%/parde/split_big_states.h \
	%reldir%/parde/split_header.h

cpplint_FILES += $(tofino_backend_parde_UNIFIED) $(tofino_backend_parde_NONUNIFIED)

tofino_backend_phv_UNIFIED = \
	%reldir%/phv/asm_output.cpp \
	%reldir%/phv/bit_extractor.cpp \
	%reldir%/phv/byte_constraint.cpp \
	%reldir%/phv/cluster.cpp \
	%reldir%/phv/cluster_phv_bind.cpp \
	%reldir%/phv/cluster_phv_container.cpp \
	%reldir%/phv/cluster_phv_mau.cpp \
	%reldir%/phv/cluster_phv_req.cpp \
	%reldir%/phv/constraints.cpp \
	%reldir%/phv/container_constraint.cpp \
	%reldir%/phv/match_xbar_constraint.cpp \
	%reldir%/phv/mau_group_constraint.cpp \
	%reldir%/phv/offset_constraint.cpp \
	%reldir%/phv/parse_graph_constraint.cpp \
	%reldir%/phv/phv_fields.cpp \
	%reldir%/phv/repack_metadata.cpp \
	%reldir%/phv/source_container_constraint.cpp \
	%reldir%/phv/split_phv_use.cpp \
	%reldir%/phv/thread_constraint.cpp \
	%reldir%/phv/trivial_alloc.cpp

noinst_HEADERS += \
	%reldir%/phv/asm_output.h \
	%reldir%/phv/bit_extractor.h \
	%reldir%/phv/byte_constraint.h \
	%reldir%/phv/cluster.h \
	%reldir%/phv/cluster_phv_bind.h \
	%reldir%/phv/cluster_phv_container.h \
	%reldir%/phv/cluster_phv_mau.h \
	%reldir%/phv/cluster_phv_req.h \
	%reldir%/phv/constraints.h \
	%reldir%/phv/container_constraint.h \
	%reldir%/phv/create_thread_local_instances.h \
	%reldir%/phv/match_xbar_constraint.h \
	%reldir%/phv/mau_group_constraint.h \
	%reldir%/phv/offset_constraint.h \
	%reldir%/phv/parse_graph_constraint.h \
	%reldir%/phv/phv_allocator.h \
	%reldir%/phv/phv_fields.h \
	%reldir%/phv/phv.h \
	%reldir%/phv/source_container_constraint.h \
	%reldir%/phv/split_phv_use.h \
	%reldir%/phv/thread_constraint.h \
	%reldir%/phv/trivial_alloc.h \
	%reldir%/phv/t_phv_constraint.h

cpplint_FILES += $(tofino_backend_phv_UNIFIED) $(tofino_backend_phv_NONUNIFIED)

# OR Tools uses Protobuf, which includes this wonderful hack:
#   https://github.com/google/protobuf/blob/master/src/google/protobuf/stubs/common.h#L223
#
# We unfortunately have our own hack that puts |vector| in the global namespace
# in |ir/std.h|. Until at least one of these hacks is removed, files that use OR
# Tools need to be built separately from files that interact with our IR.

tofino_backend_phv_or_tools_UNIFIED = \
	%reldir%/phv/phv_allocator.cpp \
	%reldir%/phv/or_tools/bit.cpp \
	%reldir%/phv/or_tools/solver.cpp

# These ones have to be built totally non-unified because in some of the files
# that use OR Tools, the |Solver| in the global namespace is Google's
# |operations_research::Solver|, and in some it's our own |or_tools::Solver|. We
# should fix that.

tofino_backend_phv_or_tools_NONUNIFIED = \
	%reldir%/phv/or_tools/container.cpp \
	%reldir%/phv/or_tools/mau_group.cpp

noinst_HEADERS += \
	%reldir%/phv/or_tools/bit.h \
	%reldir%/phv/or_tools/container.h \
	%reldir%/phv/or_tools/mau_group.h \
	%reldir%/phv/or_tools/min_value_solver.h \
	%reldir%/phv/or_tools/random_value_solver.h \
	%reldir%/phv/or_tools/solver.h

cpplint_FILES += $(tofino_backend_phv_or_tools_UNIFIED) $(tofino_backend_phv_or_tools_NONUNIFIED)

tofino_backend_main_UNIFIED = \
	%reldir%/midend.cpp \
	%reldir%/p4c-tofino.cpp \
	%reldir%/test-tofino.cpp

noinst_HEADERS += \
	%reldir%/midend.h \
	%reldir%/tofinoOptions.h

cpplint_FILES += $(tofino_backend_main_UNIFIED) $(tofino_backend_main_NONUNIFIED)

ir_DEF_FILES += \
    $(srcdir)/%reldir%/ir/tofino.def \
    $(srcdir)/%reldir%/ir/mau.def \
    $(srcdir)/%reldir%/ir/parde.def

bin_PROGRAMS += p4c-tofino
p4c_tofino_LDADD = libfrontend.a libp4ctoolkit.a

p4c_tofino_SOURCES = \
	$(tofino_ir_SOURCES) \
	$(tofino_backend_common_SOURCES) \
	$(tofino_backend_mau_SOURCES) \
	$(tofino_backend_parde_SOURCES) \
	$(tofino_backend_phv_SOURCES) \
	$(tofino_backend_phv_or_tools_SOURCES) \
	$(tofino_backend_main_SOURCES)

# Tests

-include tofinotests.mk
#-include p4-16-tofinotests.mk
-include tofino-p14_to_16_tests.mk
-include tofino-p4tests.mk
-include tofino-bmv2tests.mk
-include ortools-tofinotests.mk


tofinotests.mk: $(GENTESTS) $(srcdir)/%reldir%/Makefile.am $(wildcard \
   $(srcdir)/testdata/p4_14_samples/*.p4 \
   $(srcdir)/testdata/p4_14_samples/switch_*/switch.p4 \
   $(srcdir)/%reldir%/v1_2_test/*.p4 \
   $(srcdir)/%reldir%/v1_samples/*.p4 \
   $(srcdir)/%reldir%/v1_samples/switch_*/switch.p4) \
   $(srcdir)/testdata/p4_14_samples \
   $(srcdir)/%reldir%/v1_2_test \
   $(srcdir)/%reldir%/v1_samples
	@$(GENTESTS) $(srcdir) tofino $(srcdir)/%reldir%/runtest $^ >$@ || ( rm $@ && false )

#p4-16-tofinotests.mk: $(wildcard $(srcdir)/testdata/p4_16_samples/*.stf)
#	@$(GENTESTS) $(srcdir) tofino $(srcdir)/%reldir%/runtest $(^:%.stf=%.p4) >$@ || ( rm $@ && false )

ortools-tofinotests.mk: $(GENTESTS) $(srcdir)/%reldir%/Makefile.am $(wildcard \
   $(srcdir)/testdata/p4_14_samples/*.stf \
   $(srcdir)/%reldir%/v1_2_test/*.stf \
   $(srcdir)/%reldir%/v1_samples/*.stf)
	@$(GENTESTS) $(srcdir) tofino-ortools $(srcdir)/%reldir%/runtest --ortools $(^:%.stf=%.p4) >$@ || ( rm $@ && false )

# We have additional test inputs that are used to test the other (standard) back-ends
# These test input programs depend on Tofino in some way.

# Exercise v12test back-end on Tofino-specific programs
tofino-p14_to_16_tests.mk: $(GENTESTS) $(srcdir)/%reldir%/Makefile.am $(wildcard \
    $(srcdir)/%reldir%/v1_samples/*.p4 \
    $(srcdir)/%reldir%/v1_samples/switch_*/switch.p4) \
    $(srcdir)/%reldir%/v1_samples
	@$(GENTESTS) $(srcdir) p14_to_16 $(srcdir)/%reldir%/test-v12-sample.sh $^ >$@ || ( rm $@ && false )

tofino-p4tests.mk: $(GENTESTS) $(srcdir)/%reldir%/Makefile.am $(wildcard \
   $(srcdir)/%reldir%/v1_2_test/*.p4) \
   $(srcdir)/%reldir%/v1_2_test
	@$(GENTESTS) $(srcdir) p4 $(srcdir)/backends/p4test/run-p4-sample.py $^ >$@ || ( rm $@ && false )

# Exercise bmv2 back-end on Tofino-specific programs
tofino-bmv2tests.mk: $(GENTESTS) $(srcdir)/%reldir%/Makefile.am $(wildcard \
    $(srcdir)/%reldir%/v1_samples/*.p4 \
    $(srcdir)/%reldir%/v1_samples/switch_*/switch.p4) \
    $(srcdir)/%reldir%/v1_samples
	@$(GENTESTS) $(srcdir) bmv2 $(srcdir)/%reldir%/test-bmv2.sh $^ >$@ || ( rm $@ && false )

check-tofino-all:
	@$(MAKE) check TESTS="$(filter tofino%, $(TESTS) $(EXTRA_TESTS))"
recheck-tofino-all:
	@$(MAKE) recheck TESTS="$(filter tofino%, $(TESTS) $(EXTRA_TESTS))"

CLEANFILES += \
	tofinotests.mk \
	tofino-p14_to_16_tests.mk \
	tofino-p4tests.mk \
	tofino-bmv2tests.mk \
	p4-16-tofinotests.mk \
	ortools-tofinotests.mk

# Some of these failures are still P4 v1.0 front-end bugs.
# Others are due to non-standard extensions to P4:
# The *meter* tests use direct meters and execute_meter calls with 4 arguments (not in spec)
# The *stateful* tests use extensions to P4 not in spec
# FlexCounter, action_profile use a non-standard Algorithm
# TwoReferences invokes a table twice - maybe it should become a negative test?
# *range* match type is not supported by BMv2 (used also in error_detection*.p4)
XFAIL_TESTS += \
    tofino/testdata/p4_14_samples/16-TwoReferences.p4.test \
    tofino/%reldir%/v1_2_test/flowlet_switching.p4.test \
    tofino/%reldir%/v1_2_test/bfd_offload.p4.test \
    tofino/%reldir%/v1_2_test/bloom_filter.p4.test \
    tofino/%reldir%/v1_2_test/stateful_alu.p4.test \
    bmv2/%reldir%/v1_samples/02-FlexCounterActionProfile.p4.test \
    bmv2/%reldir%/v1_samples/action_profile.p4.test \
    bmv2/%reldir%/v1_samples/switch_l2_profile_tofino.p4.test \
    bmv2/%reldir%/v1_samples/test_config_125_meter_pre_color.p4.test \
    bmv2/%reldir%/v1_samples/test_config_126_meter_pre_color_2.p4.test \
    bmv2/%reldir%/v1_samples/test_config_127_meter_pre_color_3.p4.test \
    bmv2/%reldir%/v1_samples/test_config_132_meter_pre_color_4.p4.test \
    bmv2/%reldir%/v1_samples/test_config_144_recirculate.p4.test \
    bmv2/%reldir%/v1_samples/test_config_152_stateful_simple_cntr.p4.test \
    bmv2/%reldir%/v1_samples/test_config_153_stateful_simple_cntr_with_output.p4.test \
    bmv2/%reldir%/v1_samples/test_config_154_stateful_sampling.p4.test \
    bmv2/%reldir%/v1_samples/test_config_155_stateful_3_alus.p4.test \
    bmv2/%reldir%/v1_samples/test_config_156_indirect_stateful_cntr.p4.test \
    bmv2/%reldir%/v1_samples/test_config_159_stateful_using_phv_field.p4.test \
    bmv2/%reldir%/v1_samples/test_config_160_stateful_single_bit_mode.p4.test \
    bmv2/%reldir%/v1_samples/test_config_163_stateful_table_math_unit.p4.test \
    bmv2/%reldir%/v1_samples/test_config_164_stateful_deterministic_sampling.p4.test \
    bmv2/%reldir%/v1_samples/test_config_165_stateful_bfd_failure_detection.p4.test \
    bmv2/%reldir%/v1_samples/test_config_166_stateful_generic_counter.p4.test \
    bmv2/%reldir%/v1_samples/test_config_167_stateful_flowlet_switching.p4.test \
    bmv2/%reldir%/v1_samples/test_config_169_stateful_sflow_sequence.p4.test \
    bmv2/%reldir%/v1_samples/test_config_170_stateful_selection_table_update.p4.test \
    bmv2/%reldir%/v1_samples/test_config_171_stateful_conga.p4.test \
    bmv2/%reldir%/v1_samples/test_config_172_stateful_heavy_hitter.p4.test \
    bmv2/%reldir%/v1_samples/test_config_173_stateful_bloom_filter.p4.test \
    p14_to_16/%reldir%/v1_samples/02-FlexCounterActionProfile.p4.test \
    p14_to_16/%reldir%/v1_samples/switch_20160602/switch.p4.test \
    p14_to_16/%reldir%/v1_samples/switch_l2_profile_tofino.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_125_meter_pre_color.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_126_meter_pre_color_2.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_127_meter_pre_color_3.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_132_meter_pre_color_4.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_144_recirculate.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_152_stateful_simple_cntr.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_153_stateful_simple_cntr_with_output.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_154_stateful_sampling.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_155_stateful_3_alus.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_156_indirect_stateful_cntr.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_159_stateful_using_phv_field.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_160_stateful_single_bit_mode.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_163_stateful_table_math_unit.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_164_stateful_deterministic_sampling.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_165_stateful_bfd_failure_detection.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_166_stateful_generic_counter.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_167_stateful_flowlet_switching.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_169_stateful_sflow_sequence.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_170_stateful_selection_table_update.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_171_stateful_conga.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_172_stateful_heavy_hitter.p4.test \
    p14_to_16/%reldir%/v1_samples/test_config_173_stateful_bloom_filter.p4.test

# These currently fail gateway check with 'expression too complex'
XFAIL_TESTS += \
    tofino/testdata/p4_14_samples/flowlet_switching.p4.test \
    tofino/testdata/p4_14_samples/switch.p4.test \
    tofino/%reldir%/v1_samples/07-MacAddrCheck.p4.test \
    tofino/%reldir%/v1_samples/08-MacAddrCheck1.p4.test

# gateway doesn't yet support range match
XFAIL_TESTS += \
    tofino/testdata/p4_14_samples/gateway7.p4.test \
    tofino-ortools/testdata/p4_14_samples/gateway7.p4.test

# Parser failure.
XFAIL_TESTS += \
    tofino/testdata/p4_14_samples/parser_dc_full.p4.test \
    tofino-ortools/testdata/p4_14_samples/parser_dc_full.p4.test

# Generates broken PHV alloc (regs used by both ingress & egress)
XFAIL_TESTS += tofino-ortools/testdata/p4_14_samples/basic_routing.p4.test

# Missing constraints for header stack POV bits.
XFAIL_TESTS += tofino-ortools/testdata/p4_14_samples/instruct5.p4.test

# Layout Constraints from gateway allocation
XFAIL_TESTS += tofino/extensions/tofino/v1_samples/gateway_bus2.p4.test
XFAIL_TESTS += tofino-ortools/extensions/tofino/v1_samples/gateway_bus1.p4.test
XFAIL_TESTS += tofino-ortools/extensions/tofino/v1_samples/gateway_bus2.p4.test

# Multiple calculations per action
XFAIL_TESTS += tofino-ortools/extensions/tofino/v1_samples/counter_test1.p4.test
XFAIL_TESTS += tofino-ortools/extensions/tofino/v1_samples/counter_test2.p4.test
XFAIL_TESTS += tofino-ortools/extensions/tofino/v1_samples/meter_test1.p4.test

# Incorrect data layour in ixbar -- fails to get entire 128-bit value in one group.
# intermittent failure?
IFAIL_TESTS += tofino-ortools/testdata/p4_14_samples/07-MultiProtocol.p4.test

# Sometimes splits ternary match data across two groups when it shouldn't
IFAIL_TESTS += tofino-ortools/testdata/p4_14_samples/hitmiss.p4.test

# These fail (or pass) intermittently on Jenkins; not sure why
IFAIL_TESTS += tofino-ortools/extensions/tofino/v1_samples/simple_counter.p4.test \
	       tofino-ortools/extensions/tofino/v1_samples/max_counters.p4.test \
	       tofino-ortools/extensions/tofino/v1_samples/gateway_bus2.p4.test \
	       tofino-ortools/testdata/p4_14_samples/bigfield1.p4.test
