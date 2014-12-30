CC = g++
CPPFLAGS = -std=gnu++11 -Og -Wall -g -MMD -I.
YFLAGS = -v

GEN_HEADERS = gen/regs.mau_addrmap.h

all: $(GEN_HEADERS) tfas
tfas: asm-parse.o asm-types.o instruction.o phv.o stage.o tables.o ubits.o vector.o \
      gen/regs.mau_addrmap.o
json2cpp: json.o

asm-parse.o: lex-yaml.c

%: %.cpp

gen/regs.mau_addrmap.%: JSON_NAME=regs.match_action_stage.%02x
gen/%.h: templates/%.size.json json2cpp
	@mkdir -p gen
	./json2cpp +ehD -run '$(JSON_NAME)' $< >$@

gen/%.cpp: templates/%.size.json json2cpp
	@mkdir -p gen
	./json2cpp +ehDD -run '$(JSON_NAME)' -I $*.h $< >$@

templates/.templates-updated: chip.schema
	@mkdir -p templates
	walle --generate-templates
	@touch $@

templates/%.json: templates/.templates-updated
	@true

-include *.d gen/*.d

clean:
	rm -f *.o *.d asm-parse.c lex-yaml.c *.json

veryclean: clean
	rm -rf gen templates

help:
	@echo "Tofino assembler makefile -- builds assembler"
	@echo "other targets:"
	@echo "    make clean       cleans up object/dep files"
	@echo "    make veryclean   also cleans up generated templates"
