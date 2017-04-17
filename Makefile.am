
bin_PROGRAMS = tfas
noinst_PROGRAMS = json2cpp json_diff reflow mksizes
BUILT_SOURCES = lex-yaml.c gen/uptr_sizes.h
nodist_tfas_SOURCES =
common_SOURCES = \
    action_bus.cpp  \
    action_table.cpp  \
    asm-parse.ypp \
    asm-types.cpp  \
    bitvec.cpp  \
    counter.cpp  \
    crash.cpp  \
    deparser.cpp  \
    exact_match.cpp \
    gateway.cpp \
    hash_action.cpp \
    hash_dist.cpp  \
    hashexpr.cpp  \
    hex.cpp  \
    idletime.cpp \
    input_xbar.cpp  \
    instruction.cpp  \
    meter.cpp \
    p4_table.cpp  \
    parser.cpp  \
    phase0.cpp \
    phv.cpp  \
    power_ctl.cpp \
    salu_inst.cpp \
    selection.cpp \
    stage.cpp  \
    stateful.cpp  \
    synth2port.cpp \
    tables.cpp  \
    target.cpp \
    ternary_match.cpp \
    tfas.cpp  \
    top_level.cpp \
    ubits.cpp  \
    vector.c \
    widereg.cpp
tfas_SOURCES = $(common_SOURCES) json.cpp
tfas_LDADD =

json_diff_SOURCES = json_diff.cpp json.cpp fdstream.cpp
json2cpp_SOURCES = json2cpp.cpp json.cpp
#hashdump_SOURCES = hashdump.cpp json.cpp ubits.cpp
reflow_SOURCES = reflow.cpp
mksizes_SOURCES = mksizes.cpp

asm-parse.$(OBJEXT): lex-yaml.c gen/uptr_sizes.h

include tofino/Makefile.am
include jbay/Makefile.am

CLEANFILES = asm-parse.cpp lex-yaml.c $(BUILT_SOURCES)
clean-local:
	-rm -rf templates gen

veryclean: distclean
	-rm -rf Makefile.in aclocal.m4 autom4te.cache config.h.in configure \
		install-sh m4 missing ylwrap

##############################################################################
######  Autogenerate templates and C++ code from register schema        ######
##############################################################################
WALLE = $(srcdir)/walle/walle.py

gen/%.h: templates/%.size.json templates/%.cfg.json json2cpp
	@mkdir -p gen/$(dir $*)/.deps
	$(AM_V_GEN) ./json2cpp +ehD $(JSON_GLOBALS:%=-g %) $(JSON_EXTRA_ARGS) -run '$(JSON_NAME)' -c templates/$*.cfg.json $< >$@ || { rm $@; false; }

gen/disas.%.h: templates/%.size.json json2cpp
	@mkdir -p gen/$(dir $*)/.deps
	$(AM_V_GEN) ./json2cpp +hru -en $* $< >$@ || { rm $@; false; }

gen/%.cpp: templates/%.size.json templates/%.cfg.json json2cpp
	@mkdir -p gen/$(dir $*)/.deps
	$(AM_V_GEN) ./json2cpp +ehDD $(JSON_GLOBALS:%=-g %) $(JSON_EXTRA_ARGS) -run '$(JSON_NAME)' -c templates/$*.cfg.json -I $(notdir $*.h) $< >$@ || { rm $@; false; }

gen/uptr_sizes.h: mksizes
	@mkdir -p gen
	$(AM_V_GEN) ./mksizes > $@

templates/%/.templates-updated: $(srcdir)/%/chip.schema $(srcdir)/%/template_objects.yaml
	@mkdir -p templates/$*
	$(WALLE) --schema $(srcdir)/$*/chip.schema --generate-templates $(srcdir)/$*/template_objects.yaml -o templates/$*
	@touch $@

AM_YFLAGS = -v

# FIXME -- get automake to generate these automatcially...
AM_V_LEX = $(am__v_LEX_$(V))
am__v_LEX_ = $(am__v_LEX_$(AM_DEFAULT_VERBOSITY))
am__v_LEX_0 = @echo "  LEX     " $@;
am__v_LEX_1 =
%.c: $(srcdir)/%.l
	@$(RM) $@
	$(AM_V_LEX) $(LEX) -t $< > $@

check-local:
	export BUILDDIR=$$(pwd); cd $(srcdir)/test; ./runtests -f *.p4 */*.p4

ctags:
	cd $(srcdir); ctags -R -I VECTOR --exclude=test --exclude=submodules \
	    --regex-C++='/^DECLARE_(ABSTRACT_)?TABLE_TYPE\(([a-zA-Z0-9_]+)/\2/c/'
