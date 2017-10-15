#ifndef _jbay_phv_h_
#define _jbay_phv_h_

#include "../phv.h"

class Target::JBay::Phv : public Target::Phv {
    friend class ::Phv;
    struct Register : public ::Phv::Register {
        short     parser_id_, deparser_id_;
        int parser_id() const override { return parser_id_; } 
        int mau_id() const override { return uid < 280 ? uid : -1; }
        int ixbar_id() const override { return deparser_id_; }
        int deparser_id() const override { return deparser_id_; }
    };
    void init_regs(::Phv &phv) override;
    target_t type() const override { return JBAY; }
    unsigned mau_groupsize() const override { return 20; }
};

#endif /* _jbay_phv_h_ */
