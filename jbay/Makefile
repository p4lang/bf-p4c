GEN_JBAY := memories.jbay_mem memories.pipe_addrmap memories.prsr_mem_main_rspec \
	    regs.dprsr_reg regs.jbay_reg regs.mau_addrmap regs.parde_glue_stn_reg \
	    regs.pipe_addrmap
default: $(GEN_JBAY:%=gen/jbay/%.h)

JBAY_OBJS=$(GEN_TOFINO:%=gen/jbay/%.o)

$(TFAS_OBJS): | $(GEN_JBAY:%=gen/tofino/%.h)

$(GEN_JBAY:%=gen/jbay/%.o): gen/jbay/%.o: gen/jbay/%.cpp gen/jbay/%.h

$(GEN_JBAY:%=templates/jbay/%.cfg.json) $(GEN_JBAY:%=templates/jbay/%.size.json): templates/jbay/.templates-updated
	@test -r $@
