#ifndef _jbay_phv_h_
#define _jbay_phv_h_

#include "../phv.h"

class Target::JBay::Phv : public Target::Phv {
    friend class ::Phv;
    struct Register : public ::Phv::Register {
        int parser_id() const override;
        int mau_id() const override { return uid; }
        int deparser_id() const override;
    };
    void init_regs(::Phv &phv) override;
    target_t type() const override { return JBAY; }
    unsigned mau_groupsize() const override { return 20; }
};

#endif /* _jbay_phv_h_ */
