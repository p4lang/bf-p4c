CC = g++
OPTFLAGS = -O0
CPPFLAGS = -std=gnu++11 $(OPTFLAGS) -Wall -g -MMD -I.
YFLAGS = -v
WALLE = submodules/walle/walle/walle.py

GEN_OBJS := gen/memories.prsr_mem_main_rspec.o \
	    gen/regs.dprsr_hdr.o \
	    gen/regs.dprsr_inp.o \
	    gen/regs.ebp_rspec.o \
	    gen/regs.ibp_rspec.o \
	    gen/regs.mau_addrmap.o \
	    gen/regs.prsr_reg_merge_rspec.o \
	    gen/regs.tofino.o \
	    gen/regs.pipe_addrmap.o \
	    gen/memories.pipe_top_level.o \
	    gen/memories.pipe_addrmap.o
TFAS_OBJS:= action_bus.o action_table.o asm-parse.o asm-types.o bitvec.o \
	    counter.o deparser.o exact_match.o gateway.o hex.o input_xbar.o \
	    instruction.o p4_table.o parser.o phv.o selection.o stage.o tables.o \
	    ternary_match.o tfas.o top_level.o ubits.o vector.o
TEST_SRCS:= $(wildcard test_*.cpp)
all: $(GEN_OBJS:%.o=%.h) gen/uptr_sizes.h tfas
tfas: $(TFAS_OBJS) json.o $(GEN_OBJS) $(TEST_SRCS:%.cpp=%.o)

json2cpp: json.o
json_diff: json.o
hashdump: json.o ubits.o
reflow: reflow.o

asm-parse.o: lex-yaml.c

json_diff.o json.o: OPTFLAGS = -O3

%: %.cpp
$(GEN_OBJS) $(TFAS_OBJS): | $(GEN_OBJS:%.o=%.h) gen/uptr_sizes.h

$(GEN_OBJS): gen/%.o: gen/%.cpp gen/%.h
gen/memories.prsr_mem_main_rspec.%: JSON_NAME=memories.all.parser.%s
gen/regs.dprsr_hdr.%: JSON_NAME=regs.all.deparser.header_phase
gen/regs.dprsr_hdr.%: JSON_GLOBALS=fde_phv
gen/regs.dprsr_inp.%: JSON_NAME=regs.all.deparser.input_phase
gen/regs.dprsr_inp.%: JSON_GLOBALS=fde_pov
gen/regs.mau_addrmap.%: JSON_NAME=regs.match_action_stage.%02x
gen/regs.ibp_rspec.%: JSON_NAME=regs.all.parser.ingress
gen/regs.ebp_rspec.%: JSON_NAME=regs.all.parser.egress
gen/regs.prsr_reg_merge_rspec.%: JSON_NAME=regs.all.parse_merge
gen/regs.tofino.%: JSON_NAME=regs.top
gen/regs.pipe_addrmap.%: JSON_NAME=regs.pipe
gen/memories.pipe_top_level.%: JSON_NAME=memories.top
gen/memories.pipe_addrmap.%: JSON_NAME=memories.pipe
gen/%.h: templates/%.size.json templates/%.cfg.json json2cpp
	@mkdir -p gen
	./json2cpp +ehD $(JSON_GLOBALS:%=-g %) -run '$(JSON_NAME)' -c templates/$*.cfg.json $< >$@

gen/disas.%.h: templates/%.size.json json2cpp
	@mkdir -p gen
	./json2cpp +hru -en $* $< >$@

gen/%.cpp: templates/%.size.json templates/%.cfg.json json2cpp
	@mkdir -p gen
	./json2cpp +ehDD $(JSON_GLOBALS:%=-g %) -run '$(JSON_NAME)' -c templates/$*.cfg.json -I $*.h $< >$@

gen/uptr_sizes.h: mksizes
	@mkdir -p gen
	./mksizes > $@

templates/.templates-updated: $(WALLE) chip.schema template_objects.yaml
	@mkdir -p templates
	$(WALLE) --generate-templates template_objects.yaml
	@touch $@

$(WALLE):
	git submodule update --init

templates/%.json: templates/.templates-updated
	@test -r $@

-include $(wildcard *.d gen/*.d)

.PHONY: all tags test clean veryclean help
tags:
	ctags -R -I VECTOR --exclude=test --exclude=submodules

test: all reflow json_diff
	cd test; ./runtests

ftest: all reflow json_diff
	cd test; ./runtests -f

clean:
	rm -f *.o *.d asm-parse.c lex-yaml.c *.json json2cpp tfas y.output

veryclean: clean
	rm -rf gen templates reflow json_diff mksizes test/*.out

help:
	@echo "Tofino assembler makefile -- builds assembler"
	@echo "other targets:"
	@echo "    make clean       cleans up object/dep files"
	@echo "    make veryclean   also cleans up generated templates"
	@echo "    make test        run regression tests"

.SECONDARY:
