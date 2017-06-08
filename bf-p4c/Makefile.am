####### Tofino back-end

BOOST_CPPFLAGS = -DBOOST_NO_ARGUMENT_DEPENDENT_LOOKUP
AM_CPPFLAGS += $(BOOST_CPPFLAGS)

tofino_ir_UNIFIED = \
	%reldir%/ir/dbprint-tofino.cpp \
	%reldir%/ir/gress.cpp \
	%reldir%/ir/mau.cpp \
	%reldir%/ir/parde.cpp \
	%reldir%/ir/thread_visitor.cpp \
	%reldir%/ir/tofino.cpp

noinst_HEADERS += \
	%reldir%/ir/gress.h \
	%reldir%/ir/thread_visitor.h

cpplint_FILES += $(tofino_ir_UNIFIED) $(tofino_ir_NONUNIFIED)
extension_frontend_SOURCES += $(tofino_ir_SOURCES)

tofino_backend_common_UNIFIED = \
	%reldir%/common/asm_output.cpp \
	%reldir%/common/copy_header_eliminator.cpp \
	%reldir%/common/elim_unused.cpp \
	%reldir%/common/extract_maupipe.cpp \
	%reldir%/common/field_defuse.cpp \
	%reldir%/common/frontend.cpp \
	%reldir%/common/header_stack.cpp \
	%reldir%/common/live_at_entry.cpp \
	%reldir%/common/remap_intrin.cpp \
	%reldir%/common/param_binding.cpp \
	%reldir%/common/parser_overlay.cpp \
	%reldir%/common/slice.cpp

noinst_HEADERS += \
	%reldir%/common/blockmap.h \
	%reldir%/common/copy_header_eliminator.h \
	%reldir%/common/elim_unused.h \
	%reldir%/common/extract_maupipe.h \
	%reldir%/common/field_defuse.h \
	%reldir%/common/frontend.h \
	%reldir%/common/header_stack.h \
	%reldir%/common/live_at_entry.h \
	%reldir%/common/remap_intrin.h \
	%reldir%/common/param_binding.h \
	%reldir%/common/parser_overlay.h \
	%reldir%/common/slice.h

cpplint_FILES += $(tofino_backend_common_UNIFIED) $(tofino_backend_common_NONUNIFIED)

tofino_backend_mau_UNIFIED = \
	%reldir%/mau/action_data_bus.cpp \
	%reldir%/mau/action_format.cpp \
	%reldir%/mau/asm_output.cpp \
	%reldir%/mau/field_use.cpp \
	%reldir%/mau/db-gateway.cpp \
	%reldir%/mau/gateway.cpp \
	%reldir%/mau/input_xbar.cpp \
	%reldir%/mau/instruction_adjustment.cpp \
	%reldir%/mau/instruction_selection.cpp \
	%reldir%/mau/ixbar_realign.cpp \
	%reldir%/mau/memories.cpp \
	%reldir%/mau/resource_estimate.cpp \
	%reldir%/mau/split_gateways.cpp \
	%reldir%/mau/stateful_alu.cpp \
	%reldir%/mau/table_dependency_graph.cpp \
	%reldir%/mau/table_format.cpp \
	%reldir%/mau/table_layout.cpp \
	%reldir%/mau/table_mutex.cpp \
	%reldir%/mau/table_placement.cpp \
	%reldir%/mau/table_seqdeps.cpp \
	%reldir%/mau/table_summary.cpp

noinst_HEADERS += \
	%reldir%/mau/action_data_bus.h \
	%reldir%/mau/action_format.h \
	%reldir%/mau/asm_output.h \
	%reldir%/mau/default_next.h \
	%reldir%/mau/field_use.h \
	%reldir%/mau/gateway.h \
	%reldir%/mau/input_xbar.h \
	%reldir%/mau/instruction_adjustment.h \
	%reldir%/mau/instruction_selection.h \
	%reldir%/mau/ixbar_realign.h \
	%reldir%/mau/memories.h \
	%reldir%/mau/push_pop.h \
	%reldir%/mau/resource_estimate.h \
	%reldir%/mau/resource.h \
	%reldir%/mau/split_gateways.h \
	%reldir%/mau/stateful_alu.h \
	%reldir%/mau/table_dependency_graph.h \
	%reldir%/mau/table_format.h \
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
	%reldir%/phv/cluster.cpp \
	%reldir%/phv/cluster_phv_bind.cpp \
	%reldir%/phv/cluster_phv_container.cpp \
	%reldir%/phv/cluster_phv_interference.cpp \
	%reldir%/phv/cluster_phv_mau.cpp \
	%reldir%/phv/cluster_phv_operations.cpp \
	%reldir%/phv/cluster_phv_overlay.cpp \
	%reldir%/phv/cluster_phv_req.cpp \
	%reldir%/phv/cluster_phv_slicing.cpp \
	%reldir%/phv/phv.cpp \
	%reldir%/phv/phv_analysis_api.cpp \
	%reldir%/phv/phv_fields.cpp \
	%reldir%/phv/repack_metadata.cpp \
	%reldir%/phv/split_phv_use.cpp \
	%reldir%/phv/trivial_alloc.cpp \
	%reldir%/phv/validate_allocation.cpp

noinst_HEADERS += \
	%reldir%/phv/asm_output.h \
	%reldir%/phv/cluster.h \
	%reldir%/phv/cluster_phv_bind.h \
	%reldir%/phv/cluster_phv_container.h \
	%reldir%/phv/cluster_phv_interference.h \
	%reldir%/phv/cluster_phv_mau.h \
	%reldir%/phv/cluster_phv_operations.h \
	%reldir%/phv/cluster_phv_overlay.h \
	%reldir%/phv/cluster_phv_req.h \
	%reldir%/phv/cluster_phv_slicing.h \
	%reldir%/phv/phv_analysis_api.h \
	%reldir%/phv/phv_fields.h \
	%reldir%/phv/phv.h \
	%reldir%/phv/split_phv_use.h \
	%reldir%/phv/trivial_alloc.h \
	%reldir%/phv/validate_allocation.h

cpplint_FILES += $(tofino_backend_phv_UNIFIED) $(tofino_backend_phv_NONUNIFIED)

tofino_backend_main_UNIFIED = \
	%reldir%/backend.cpp \
	%reldir%/midend.cpp

noinst_HEADERS += \
	%reldir%/backend.h \
	%reldir%/midend.h \
	%reldir%/tofinoOptions.h

cpplint_FILES += $(tofino_backend_main_UNIFIED) $(tofino_backend_main_NONUNIFIED)

ir_DEF_FILES += \
    $(srcdir)/%reldir%/ir/tofino.def \
    $(srcdir)/%reldir%/ir/mau.def \
    $(srcdir)/%reldir%/ir/parde.def

p4include_HEADERS += $(srcdir)/%reldir%/p4include/tofino_model.p4
p4include_tofinodir = $(p4includedir)/tofino
p4include_tofino_HEADERS = \
    $(srcdir)/%reldir%/p4include/tofino/stateful_alu.p4
p4_14include_tofinodir = $(p4_14includedir)/tofino
p4_14include_tofino_HEADERS = \
    $(srcdir)/%reldir%/p4_14include/tofino/constants.p4 \
    $(srcdir)/%reldir%/p4_14include/tofino/intrinsic_metadata.p4 \
    $(srcdir)/%reldir%/p4_14include/tofino/lpf_blackbox.p4 \
    $(srcdir)/%reldir%/p4_14include/tofino/meter_blackbox.p4 \
    $(srcdir)/%reldir%/p4_14include/tofino/pktgen_headers.p4 \
    $(srcdir)/%reldir%/p4_14include/tofino/primitives.p4 \
    $(srcdir)/%reldir%/p4_14include/tofino/stateful_alu_blackbox.p4 \
    $(srcdir)/%reldir%/p4_14include/tofino/wred_blackbox.p4

installed-data.stamp: $(p4include_tofino_HEADERS) $(p4_14include_tofino_HEADERS)

noinst_LTLIBRARIES += libtofinobackend.la
libtofinobackend_la_LIBADD = libfrontend.la
libtofinobackend_la_SOURCES = \
	$(tofino_backend_common_SOURCES) \
	$(tofino_backend_main_SOURCES) \
	$(tofino_backend_mau_SOURCES) \
	$(tofino_backend_parde_SOURCES) \
	$(tofino_backend_phv_SOURCES)

bin_PROGRAMS += p4c-tofino
p4c_tofino_LDADD = \
	libtofinobackend.la \
        $(BOOST_FILESYSTEM_LIB) \
	$(BOOST_SYSTEM_LIB)
p4c_tofino_SOURCES = \
	%reldir%/p4c-tofino.cpp

cpplint_FILES += $(p4c_tofino_SOURCES)

p4c_PYTHON += $(srcdir)/%reldir%/driver/p4c.tofino.cfg

################ Testing

# Tofino-specific GTests.
gtest_tofino_UNIFIED = \
	%reldir%/test/gtest/phv.cpp \
	%reldir%/test/gtest/trivial_alloc.cpp

cpplint_FILES += $(gtest_tofino_UNIFIED) $(gtest_tofino_NONUNIFIED)
gtest_SOURCES += $(gtest_tofino_SOURCES)
gtest_LDADD += libtofinobackend.la
