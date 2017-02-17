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

default: tfas

GEN_HEADERS := gen/uptr_sizes.h

include tofino/Makefile
include jbay/Makefile

TFAS_OBJS:= action_bus.o action_table.o asm-parse.o asm-types.o bitvec.o \
	    counter.o crash.o deparser.o exact_match.o gateway.o hash_action.o \
	    hash_dist.o hashexpr.o hex.o idletime.o input_xbar.o \
	    instruction.o meter.o p4_table.o parser.o phase0.o phv.o power_ctl.o \
	    selection.o stage.o stateful.o synth2port.o tables.o ternary_match.o \
	    tfas.o top_level.o ubits.o vector.o widereg.o
TEST_SRCS:= $(wildcard test_*.cpp)
all: default reflow json_diff
tfas: $(TFAS_OBJS) json.o $(TOFINO_OBJS) $(JBAY_OBJS) $(TEST_SRCS:%.cpp=%.o)

json2cpp: json.o
json_diff: json.o fdstream.o
hashdump: json.o ubits.o
reflow: reflow.o

asm-parse.o: lex-yaml.c gen/uptr_sizes.h

json_diff.o json.o: OPTFLAGS = -O3

%: %.cpp
$(TFAS_OBJS): | $(GEN_HEADERS)

gen/%.h: templates/%.size.json templates/%.cfg.json json2cpp
	@mkdir -p gen/$(dir $*)
	./json2cpp +ehD $(JSON_GLOBALS:%=-g %) $(JSON_EXTRA_ARGS) -run '$(JSON_NAME)' -c templates/$*.cfg.json $< >$@ || { rm $@; false; }

gen/disas.%.h: templates/%.size.json json2cpp
	@mkdir -p gen/$(dir $*)
	./json2cpp +hru -en $* $< >$@ || { rm $@; false; }

gen/%.cpp: templates/%.size.json templates/%.cfg.json json2cpp
	@mkdir -p gen/$(dir $*)
	./json2cpp +ehDD $(JSON_GLOBALS:%=-g %) $(JSON_EXTRA_ARGS) -run '$(JSON_NAME)' -c templates/$*.cfg.json -I $(notdir $*.h) $< >$@ || { rm $@; false; }

gen/uptr_sizes.h: mksizes
	@mkdir -p gen
	./mksizes > $@

templates/%/.templates-updated: %/chip.schema %/template_objects.yaml
	@mkdir -p templates/$*
	$(WALLE) --schema $*/chip.schema --generate-templates $*/template_objects.yaml -o templates/$*
	@touch $@

echo-walle:
	@echo walle is '"$(WALLE)"'

-include $(wildcard *.d gen/*.d gen/*/*.d)

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
	rm -rf gen templates reflow json_diff mksizes

help:
	@echo "Tofino assembler makefile -- builds assembler"
	@echo "other targets:"
	@echo "    make all	    build assembler + extra debugging tools"
	@echo "    make clean       cleans up object/dep files"
	@echo "    make veryclean   also cleans up generated templates"
	@echo "    make test        run regression tests"

.SECONDARY:
