CC = g++
CPPFLAGS = -std=gnu++11 -O0 -Wall -g -MMD -I.
YFLAGS = -v

GEN_OBJS := gen/memories.prsr_mem_main_rspec.o \
	    gen/regs.dprsr_hdr.o \
	    gen/regs.dprsr_inp.o \
	    gen/regs.ebp_rspec.o \
	    gen/regs.ibp_rspec.o \
	    gen/regs.mau_addrmap.o \
	    gen/regs.prsr_reg_merge_rspec.o
TFAS_OBJS:= action_table.o asm-parse.o asm-types.o deparser.o exact_match.o \
	    gateway.o hex.o input_xbar.o instruction.o parser.o phv.o stage.o \
	    tables.o ternary_match.o tfas.o ubits.o vector.o
TEST_SRCS:= $(wildcard test_*.cpp)
all: $(GEN_OBJS:%.o=%.h) gen/uptr_sizes.h tfas
tfas: $(TFAS_OBJS) json.o $(GEN_OBJS) $(TEST_SRCS:%.cpp=%.o)

json2cpp: json.o
hashdump: json.o ubits.o

asm-parse.o: lex-yaml.c

%: %.cpp
$(GEN_OBJS) $(TFAS_OBJS): | $(GEN_OBJS:%.o=%.h) gen/uptr_sizes.h

$(GEN_OBJS): gen/%.o: gen/%.cpp gen/%.h
gen/memories.prsr_mem_main_rspec.%: JSON_NAME=memories.all.parser.%s
gen/regs.dprsr_hdr.%: JSON_NAME=regs.all.deparser.header_phase
gen/regs.dprsr_hdr.%: JSON_GLOBALS="fde_phv"
gen/regs.dprsr_inp.%: JSON_NAME=regs.all.deparser.input_phase
gen/regs.dprsr_inp.%: JSON_GLOBALS="fde_pov"
gen/regs.mau_addrmap.%: JSON_NAME=regs.match_action_stage.%02x
gen/regs.ibp_rspec.%: JSON_NAME=regs.all.parser.ingress
gen/regs.ebp_rspec.%: JSON_NAME=regs.all.parser.egress
gen/regs.prsr_reg_merge_rspec.%: JSON_NAME=regs.all.parse_merge
gen/%.h: templates/%.size.json json2cpp
	@mkdir -p gen
	./json2cpp +ehD $(JSON_GLOBALS:%=-g %) -run '$(JSON_NAME)' $< >$@

gen/disas.%.h: templates/%.size.json json2cpp
	@mkdir -p gen
	./json2cpp +hru -en $* $< >$@

gen/%.cpp: templates/%.size.json json2cpp
	@mkdir -p gen
	./json2cpp +ehDDi2 $(JSON_GLOBALS:%=-g %) -run '$(JSON_NAME)' -I $*.h $< >$@

gen/uptr_sizes.h: mksizes
	@mkdir -p gen
	./mksizes > $@

templates/.templates-updated: chip.schema templates-config
	@mkdir -p templates
	walle --generate-templates templates-config
	@touch $@

templates/%.json: templates/.templates-updated
	@test -r $@

-include $(wildcard *.d gen/*.d)

clean:
	rm -f *.o *.d asm-parse.c lex-yaml.c *.json json2cpp tfas

veryclean: clean
	rm -rf gen templates

help:
	@echo "Tofino assembler makefile -- builds assembler"
	@echo "other targets:"
	@echo "    make clean       cleans up object/dep files"
	@echo "    make veryclean   also cleans up generated templates"

.SECONDARY:
