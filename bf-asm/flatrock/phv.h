#ifndef BF_ASM_FLATROCK_PHV_H_
#define BF_ASM_FLATROCK_PHV_H_

#include "../phv.h"

class Target::Flatrock::Phv : public Target::Phv {
    friend class ::Phv;
    struct Register : public ::Phv::Register {
        int parser_id() const override { return uid; }
        int mau_id() const override { return uid; }
        int ixbar_id() const override { return uid; }
        int deparser_id() const override { return uid; }
    };
    void init_regs(::Phv &phv) override;
    target_t type() const override { return FLATROCK; }
    unsigned mau_groupsize() const override { return 1; }
};

#endif /* BF_ASM_FLATROCK_PHV_H_ */
