GEN_JBAY := memories.jbay_mem memories.pipe_addrmap memories.prsr_mem_main_rspec \
	    regs.epb_regs regs.ipb_csr_regs regs.prsr_reg_main_rspec \
	    regs.pipe_addrmap regs.pmerge_reg \
	    regs.mau_addrmap \
	    regs.dprsr_reg regs.jbay_reg
default: $(GEN_JBAY:%=gen/jbay/%.h)

JBAY_OBJS=$(GEN_JBAY:%=gen/jbay/%.o)

GEN_HEADERS += $(GEN_JBAY:%=gen/jbay/%.h)

$(GEN_JBAY:%=gen/jbay/%.o): gen/jbay/%.o: gen/jbay/%.cpp gen/jbay/%.h

gen/jbay/%: JSON_EXTRA_ARGS=-N JBay

$(GEN_JBAY:%=templates/jbay/%.cfg.json) $(GEN_JBAY:%=templates/jbay/%.size.json): templates/jbay/.templates-updated
	@test -r $@
