ACLOCAL_AMFLAGS = $(ACLOCAL_FLAGS) -I m4

AM_CPPFLAGS = -I$(FULL_INC_DIR)

# the p4c compiler
# the p4c compiler defines these flags, however, we compile the control plane
# APIs with a native C compiler, and this tells it which compiler was used
# to compile the P4 program
AM_CPPFLAGS += -D__p4c__=1 -D__p4c_major__=$(P4C_VERSION_MAJOR)

AM_P4FLAGS  = --std p4-16
AM_P4FLAGS += --target tofino
AM_P4FLAGS += --arch tna
AM_P4FLAGS += -o $(builddir)/$(P4_NAME)
AM_P4FLAGS += --bf-rt-schema $(builddir)/$(P4_NAME)/bf-rt.json
AM_P4FLAGS += $(P4FLAGS)

MANIFEST_FILE = $(builddir)/$(P4_NAME)/manifest.json
PROGRAM_BINARY = $(wildcard @P4_NAME@/*/tofino.bin)
COMPILER_CONTEXT = $(wildcard @P4_NAME@/*/context.json)
COMPILER_OUTPUT_FILES = $(PROGRAM_BINARY) $(COMPILER_CONTEXT)

COMPILER_OUTPUT_FILES += @P4_NAME@/bf-rt.json
BFRT_CONF_FILE = @P4_NAME@/@P4_NAME@.conf
COMPILER_OUTPUT_FILES += $(BFRT_CONF_FILE)

# Don't install the compiler generated switch.conf file
#bfrtdatadir = $(datadir)/p4/targets/tofino
#bfrtdata_DATA = $(BFRT_CONF_FILE)

# tofino or tofino2
pddatadir = $(datadir)/tofinopd
# Tofino multipipe requires multiple contexts and binaries, so we do not
# strip the directory path
nobase_pddata_DATA = $(COMPILER_OUTPUT_FILES)

AM_P4PPFLAGS = $(P4PPFLAGS)

# Adding all compiler output files here so that they are cleaned up with make
# clean.
BUILT_SOURCES = \
	$(COMPILER_OUTPUT_FILES)

# The recipe to invoke the p4c-tofino compiler is copied from:
# http://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html
p4c.ts : $(P4_PATH)
	@rm -f p4c.tmp
	@touch p4c.tmp
	$(P4C) $(AM_P4FLAGS) $(AM_P4PPFLAGS) $(P4_PATH)
	$(GEN_BFRT_CONF) --name $(P4_NAME) --device tofino --testdir $(builddir)/$(P4_NAME) \
			 --installdir $(pddatadir)/$(P4_NAME) \
	                 --pipe `$(MANIFEST_CONFIG) --pipe $(MANIFEST_FILE)`
	@mv -f p4c.tmp $@

$(BUILT_SOURCES) : p4c.ts
## Recover from the removal of $@
	@if test -f $@; then :; else \
	  trap 'rm -rf p4c.lock p4c.ts' 1 2 13 15; \
## mkdir is a portable test-and-set
	if mkdir p4c.lock 2>/dev/null; then \
## This code is being executed by the first process.
	  rm -f p4c.ts; \
	  $(MAKE) $(AM_MAKEFLAGS) p4c.ts; \
	  result=$$?; rm -rf p4c.lock; exit $$result; \
	else \
## This code is being executed by the follower processes.
## Wait until the first process is done.
	  while test -d p4c.lock; do sleep 1; done; \
## Succeed if and only if the first process succeeded.
	    test -f p4c.ts; \
	  fi; \
	fi

CLEANFILES = $(BUILT_SOURCES) p4c.ts
