####### Tofino back-end

tofino_ir_SOURCES = \
	backends/tofino/ir/dbprint-tofino.cpp \
	backends/tofino/ir/mau.cpp \
	backends/tofino/ir/parde.cpp \
	backends/tofino/ir/tofino.cpp

ir_SOURCES += $(tofino_ir_SOURCES)

tofino_backend_SOURCES = \
	$(tofino_ir_SOURCES) \
	backends/tofino/common/asm_output.cpp \
	backends/tofino/common/blockmap.h \
	backends/tofino/common/copy_header_eliminator.cpp \
	backends/tofino/common/copy_header_eliminator.h \
	backends/tofino/common/extract_maupipe.cpp \
	backends/tofino/common/extract_maupipe.h \
	backends/tofino/common/field_defuse.cpp \
	backends/tofino/common/field_defuse.h \
	backends/tofino/common/param_binding.cpp \
	backends/tofino/common/param_binding.h \
	backends/tofino/common/phv.cpp \
	backends/tofino/common/phv.h \
	backends/tofino/mau/asm_output.cpp \
	backends/tofino/mau/asm_output.h \
	backends/tofino/mau/default_next.h \
	backends/tofino/mau/field_use.cpp \
	backends/tofino/mau/field_use.h \
	backends/tofino/mau/gateway.cpp \
	backends/tofino/mau/gateway.h \
	backends/tofino/mau/input_xbar.cpp \
	backends/tofino/mau/input_xbar.h \
	backends/tofino/mau/instruction_selection.cpp \
	backends/tofino/mau/instruction_selection.h \
	backends/tofino/mau/memories.cpp \
	backends/tofino/mau/memories.h \
	backends/tofino/mau/phv_constraints.cpp \
	backends/tofino/mau/phv_constraints.h \
	backends/tofino/mau/resource_estimate.cpp \
	backends/tofino/mau/resource_estimate.h \
	backends/tofino/mau/resource.h \
	backends/tofino/mau/split_gateways.cpp \
	backends/tofino/mau/split_gateways.h \
	backends/tofino/mau/table_dependency_graph.cpp \
	backends/tofino/mau/table_dependency_graph.h \
	backends/tofino/mau/table_layout.cpp \
	backends/tofino/mau/table_layout.h \
	backends/tofino/mau/table_mutex.cpp \
	backends/tofino/mau/table_mutex.h \
	backends/tofino/mau/table_placement.cpp \
	backends/tofino/mau/table_placement.h \
	backends/tofino/mau/table_seqdeps.cpp \
	backends/tofino/mau/table_seqdeps.h \
	backends/tofino/mau/table_summary.cpp \
	backends/tofino/mau/table_summary.h \
	backends/tofino/parde/asm_output.h \
	backends/tofino/parde/add_parde_metadata.h \
	backends/tofino/parde/add_parde_metadata.cpp \
	backends/tofino/parde/compute_shifts.h \
	backends/tofino/parde/deparser_output.cpp \
	backends/tofino/parde/extract_parser.cpp \
	backends/tofino/parde/extract_parser.h \
	backends/tofino/parde/gen_deparser.cpp \
	backends/tofino/parde/match_keys.cpp \
	backends/tofino/parde/match_keys.h \
	backends/tofino/parde/parser_output.cpp \
	backends/tofino/parde/split_header.cpp \
	backends/tofino/parde/split_header.h \
	backends/tofino/phv/asm_output.cpp \
	backends/tofino/phv/asm_output.h \
	backends/tofino/phv/create_thread_local_instances.cpp \
	backends/tofino/phv/create_thread_local_instances.h \
	backends/tofino/phv/header_fragment_creator.cpp \
	backends/tofino/phv/header_fragment_creator.h \
	backends/tofino/phv/phv.h \
	backends/tofino/phv/phv_allocate.cpp \
	backends/tofino/phv/phv_allocate.h \
	backends/tofino/phv/phv_fields.cpp \
	backends/tofino/phv/phv_fields.h \
	backends/tofino/phv/split_phv_use.h \
	backends/tofino/phv/split_phv_use.cpp \
	backends/tofino/test-tofino.cpp \
	backends/tofino/tofinoOptions.h \
	backends/tofino/p4c-tofino.cpp

ir_DEF_FILES += \
    $(srcdir)/backends/tofino/ir/tofino.def \
    $(srcdir)/backends/tofino/ir/mau.def \
    $(srcdir)/backends/tofino/ir/parde.def

bin_PROGRAMS += p4c-tofino
p4c_tofino_LDADD = -lgc libfrontend.a libp4ctoolkit.a 
p4c_tofino_SOURCES = $(tofino_backend_SOURCES)

cpplint_FILES += $(tofino_backend_SOURCES)

# Tests

-include $(srcdir)/tofinotests.am
-include $(srcdir)/backends/tofino/v1_2_tests.am
-include $(srcdir)/backends/tofino/v1to12tests.am
-include $(srcdir)/backends/tofino/bmv2tests.am

$(srcdir)/tofinotests.am: \
   $(srcdir)/testdata/v1_samples/*.p4 \
   $(srcdir)/testdata/v1_errors/*.p4 \
   $(srcdir)/backends/tofino/v1_2_test/*.p4 \
   $(srcdir)/backends/tofino/v1_samples/*.p4
	@$(srcdir)/gen-tests.py $(srcdir) tofino $(srcdir)/backends/tofino/run-tofino-sample.py $^ >$@

# We have additional test inputs that are used to test the other (standard) back-ends
# These test input programs depend on Tofino in some way.

# Exercise v12test back-end on Tofino-specific programs
$(srcdir)/backends/tofino/v1to12tests.am: $(srcdir)/backends/tofino/v1_samples/*.p4 
	@$(srcdir)/gen-tests.py $(srcdir) v1to12 $(srcdir)/backends/tofino/test-v12-sample.sh $^ >$@

# Exercise bmv2 back-end on Tofino-specific programs
$(srcdir)/backends/tofino/bmv2tests.am: $(srcdir)/backends/tofino/v1_samples/*.p4 
	@$(srcdir)/gen-tests.py $(srcdir) bmv2 $(srcdir)/backends/tofino/test-bmv2.sh $^ >$@

CLEANFILES += \
	$(srcdir)/tofinotests.am \
	$(srcdir)/backends/tofino/v1_2_tests.am \
	$(srcdir)/backends/tofino/v1to12tests.am \
	$(srcdir)/backends/tofino/bmv2tests.am

# Some of these failures are still P4 v1.0 front-end bugs.
# Others are due to non-standard extensions to P4:
# The *meter* tests use direct meters and execute_meter calls with 4 arguments (not in spec)
# The *stateful* tests use extensions to P4 not in spec
# FlexCounter, action_profile use a non-standard Algorithm
# TwoReferences invokes a table twice - maybe it should become a negative test?
# *range* match type is not supported by BMv2 (used also in error_detection*.p4)
XFAIL_TESTS += \
    tofino/testdata/v1_samples/16-TwoReferences.p4.test \
    tofino/testdata/v1_samples/07-MultiProtocol.p4.test \
    tofino/testdata/v1_samples/02-FullPHV1.p4.test \
    tofino/testdata/v1_samples/03-FullPHV2.p4.test \
    tofino/testdata/v1_samples/truncate.p4.test \
    bmv2/backends/tofino/v1_samples/01-FlexCounter.p4.test \
    bmv2/backends/tofino/v1_samples/03-VlanProfile.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_168_meter_bug.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_124_meter_3.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_123_meter_2.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_125_meter_pre_color.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_126_meter_pre_color_2.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_127_meter_pre_color_3.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_132_meter_pre_color_4.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_152_stateful_simple_cntr.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_153_stateful_simple_cntr_with_output.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_154_stateful_sampling.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_155_stateful_3_alus.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_156_indirect_stateful_cntr.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_157_random_number_generator.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_159_stateful_using_phv_field.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_160_stateful_single_bit_mode.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_161_new_primitives.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_163_stateful_table_math_unit.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_164_stateful_deterministic_sampling.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_165_stateful_bfd_failure_detection.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_166_stateful_generic_counter.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_167_stateful_flowlet_switching.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_169_stateful_sflow_sequence.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_170_stateful_selection_table_update.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_171_stateful_conga.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_172_stateful_heavy_hitter.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_173_stateful_bloom_filter.p4.test \
    bmv2/backends/tofino/v1_samples/02-FlexCounterActionProfile.p4.test \
    bmv2/backends/tofino/v1_samples/action_profile.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_118_tcam_range_2.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_119_tcam_range_3.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_120_tcam_range_4.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_121_tcam_range_5.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_122_tcam_range_6.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_135_tcam_range_7.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_136_tcam_error_detection.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_137_tcam_error_detection_2.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_138_tcam_error_detection_3.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_139_tcam_error_detection_4.p4.test \
    bmv2/backends/tofino/v1_samples/test_config_117_first_tcam_range.p4.test \
    bmv2/backends/tofino/v1_samples/vk_basic_ipv4_20150706.p4.test \
    bmv2/backends/tofino/v1_samples/13-ResubmitMetadataSize.p4.test \
    v1to12/backends/tofino/v1_samples/02-FlexCounterActionProfile.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_123_meter_2.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_125_meter_pre_color.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_124_meter_3.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_126_meter_pre_color_2.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_127_meter_pre_color_3.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_132_meter_pre_color_4.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_152_stateful_simple_cntr.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_153_stateful_simple_cntr_with_output.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_155_stateful_3_alus.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_154_stateful_sampling.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_159_stateful_using_phv_field.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_156_indirect_stateful_cntr.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_163_stateful_table_math_unit.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_160_stateful_single_bit_mode.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_164_stateful_deterministic_sampling.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_165_stateful_bfd_failure_detection.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_167_stateful_flowlet_switching.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_166_stateful_generic_counter.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_168_meter_bug.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_169_stateful_sflow_sequence.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_170_stateful_selection_table_update.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_171_stateful_conga.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_172_stateful_heavy_hitter.p4.test \
    v1to12/backends/tofino/v1_samples/test_config_173_stateful_bloom_filter.p4.test \
    v1to12/backends/tofino/v1_samples/vk_basic_ipv4_subset.p4.test
