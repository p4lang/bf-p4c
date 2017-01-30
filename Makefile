CC = g++
OPTFLAGS = -O0
CPPFLAGS = -std=gnu++11 $(OPTFLAGS) -Wall -g -MMD -I.
BUILD_OS := $(shell uname -s)
ifeq ($(BUILD_OS), Darwin)
	CPPFLAGS += -DNO_UCONTEXT
endif
YFLAGS = -v
WALLE := $(shell  \
    for f in . $(HOME)/walle ../walle submodules/walle; do \
	if [ -x $$f/walle/walle.py ]; then \
	    echo $$f/walle/walle.py; \
	    exit; \
	fi; \
    done; echo walle)

GEN_TOFINO :=  memories.pipe_addrmap  memories.pipe_top_level  memories.prsr_mem_main_rspec \
	       regs.dprsr_hdr regs.dprsr_inp regs.ebp_rspec regs.ibp_rspec regs.mau_addrmap \
	       regs.pipe_addrmap regs.prsr_reg_merge_rspec regs.tofino
TFAS_OBJS:= action_bus.o action_table.o asm-parse.o asm-types.o bitvec.o \
	    counter.o crash.o deparser.o exact_match.o gateway.o hash_action.o \
	    hash_dist.o hashexpr.o hex.o idletime.o input_xbar.o \
	    instruction.o meter.o p4_table.o parser.o phase0.o phv.o power_ctl.o \
	    selection.o stage.o tables.o ternary_match.o tfas.o top_level.o \
	    ubits.o vector.o
TEST_SRCS:= $(wildcard test_*.cpp)
default: $(GEN_TOFINO:%=gen/tofino/%.h) gen/uptr_sizes.h tfas
all: default reflow json_diff
tfas: $(TFAS_OBJS) json.o $(GEN_TOFINO:%=gen/tofino/%.o) $(TEST_SRCS:%.cpp=%.o)

json2cpp: json.o
json_diff: json.o fdstream.o
hashdump: json.o ubits.o
reflow: reflow.o

asm-parse.o: lex-yaml.c

json_diff.o json.o: OPTFLAGS = -O3

%: %.cpp
$(TFAS_OBJS): | $(GEN_TOFINO:%=gen/tofino/%.h) gen/uptr_sizes.h

$(GEN_TOFINO:%=gen/tofino/%.o): gen/tofino/%.o: gen/tofino/%.cpp gen/tofino/%.h
gen/tofino/memories.prsr_mem_main_rspec.%: JSON_NAME=memories.all.parser.%s
gen/tofino/regs.dprsr_hdr.%: JSON_NAME=regs.all.deparser.header_phase
gen/tofino/regs.dprsr_hdr.%: JSON_GLOBALS=fde_phv
gen/tofino/regs.dprsr_inp.%: JSON_NAME=regs.all.deparser.input_phase
gen/tofino/regs.dprsr_inp.%: JSON_GLOBALS=fde_pov
gen/tofino/regs.mau_addrmap.%: JSON_NAME=regs.match_action_stage.%02x
gen/tofino/regs.ibp_rspec.%: JSON_NAME=regs.all.parser.ingress
gen/tofino/regs.ebp_rspec.%: JSON_NAME=regs.all.parser.egress
gen/tofino/regs.prsr_reg_merge_rspec.%: JSON_NAME=regs.all.parse_merge
gen/tofino/regs.tofino.%: JSON_NAME=regs.top
gen/tofino/regs.pipe_addrmap.%: JSON_NAME=regs.pipe
gen/tofino/regs.pipe_addrmap.%: JSON_EXTRA_ARGS=+E
gen/tofino/memories.pipe_top_level.%: JSON_NAME=memories.top
gen/tofino/memories.pipe_addrmap.%: JSON_NAME=memories.pipe
gen/%.h: templates/%.size.json templates/%.cfg.json json2cpp
	@mkdir -p gen/$(dir $*)
	./json2cpp +ehD $(JSON_GLOBALS:%=-g %) $(JSON_EXTRA_ARGS) -run '$(JSON_NAME)' -c templates/$*.cfg.json $< >$@

gen/disas.%.h: templates/%.size.json json2cpp
	@mkdir -p gen/$(dir $*)
	./json2cpp +hru -en $* $< >$@

gen/%.cpp: templates/%.size.json templates/%.cfg.json json2cpp
	@mkdir -p gen/$(dir $*)
	./json2cpp +ehDD $(JSON_GLOBALS:%=-g %) $(JSON_EXTRA_ARGS) -run '$(JSON_NAME)' -c templates/$*.cfg.json -I $(notdir $*.h) $< >$@

gen/uptr_sizes.h: mksizes
	@mkdir -p gen
	./mksizes > $@

templates/%/.templates-updated: %/chip.schema %/template_objects.yaml
	@mkdir -p templates/$*
	$(WALLE) --schema $*/chip.schema --generate-templates $*/template_objects.yaml -o templates/$*
	@touch $@

echo-walle:
	@echo walle is '"$(WALLE)"'

tofino/chip.schema tofino/template_objects.yaml: %: p4c-templates/%
	# if there's a symlink 'p4c-templates' to somewhere with new reg schema, copy them
	if [ $< -nt $@ ]; then cp $< $@; fi

$(GEN_TOFINO:%=templates/tofino/%.cfg.json) $(GEN_TOFINO:%=templates/tofino/%.size.json): templates/tofino/.templates-updated
	@test -r $@

-include $(wildcard *.d gen/*.d)

.PHONY: default all tags test clean veryclean help
tags:
	ctags -R -I VECTOR --exclude=test --exclude=submodules \
	    --regex-C++='/^DECLARE_(ABSTRACT_)?TABLE_TYPE\(([a-zA-Z0-9_]+)/\2/c/'

test: all
	cd test; ./runtests *.p4 mau/*.p4

ftest: all
	cd test; ./runtests -f

clean:
	rm -f *.o *.d asm-parse.c lex-yaml.c *.json json2cpp tfas y.output

veryclean: clean
	rm -rf gen templates reflow json_diff mksizes test/*.out

help:
	@echo "Tofino assembler makefile -- builds assembler"
	@echo "other targets:"
	@echo "    make all	    build assembler + extra debugging tools"
	@echo "    make clean       cleans up object/dep files"
	@echo "    make veryclean   also cleans up generated templates"
	@echo "    make test        run regression tests"

.SECONDARY:
