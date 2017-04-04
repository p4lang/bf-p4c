GEN_TOFINO = memories.pipe_addrmap  memories.pipe_top_level  memories.prsr_mem_main_rspec \
	     regs.dprsr_hdr regs.dprsr_inp regs.ebp_rspec regs.ibp_rspec regs.mau_addrmap \
	     regs.pipe_addrmap regs.prsr_reg_merge_rspec regs.tofino

TOFINO_OBJS=$(GEN_TOFINO:%=gen/tofino/%.$(OBJEXT))
TOFINO_SRCS=$(GEN_TOFINO:%=gen/tofino/%.cpp)
TOFINO_HDRS=$(GEN_TOFINO:%=gen/tofino/%.h)

nodist_tfas_SOURCES += $(TOFINO_SRCS)
tfas_LDADD += $(TOFINO_OBJS)
BUILT_SOURCES += $(TOFINO_HDRS) $(TOFINO_SRCS)

$(GEN_TOFINO:%=gen/tofino/%.$(OBJEXT)): gen/tofino/%.$(OBJEXT): gen/tofino/%.cpp gen/tofino/%.h
gen/tofino/%: JSON_EXTRA_ARGS=-N Tofino
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
gen/tofino/regs.pipe_addrmap.%: JSON_EXTRA_ARGS+=+E
gen/tofino/memories.pipe_top_level.%: JSON_NAME=memories.top
gen/tofino/memories.pipe_addrmap.%: JSON_NAME=memories.pipe

# FIXME -- figure out how to make this work with automake:
#tofino/chip.schema tofino/template_objects.yaml: tofino/%: p4c-templates/%
#	@: if there's a symlink 'p4c-templates' to somewhere with new reg schema, copy them
#	if [ $< -nt $@ ]; then cp $< $@; fi

$(GEN_TOFINO:%=templates/tofino/%.cfg.json) $(GEN_TOFINO:%=templates/tofino/%.size.json): templates/tofino/.templates-updated
	@test -r $@
