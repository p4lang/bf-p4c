#ifndef BF_ASM_FLATROCK_PHV_H_
#define BF_ASM_FLATROCK_PHV_H_

#include "../phv.h"

class Target::Flatrock::Phv : public Target::Phv {
    friend class ::Phv;
    struct Register : public ::Phv::Register {
        short   byte;
        // 'byte' will be the flatrock PHE address of the first (lowest) byte of the PHE.
        // see https://wiki.ith.intel.com/display/ITS51T/Frame+Processing+Pipeline#FrameProcessingPipeline-PHVNumbering    (NOLINT)
        int parser_id() const override { return byte; }
        int mau_id() const override { return uid; }
        int ixbar_id() const override { return byte; }
        int deparser_id() const override { return byte; }
    };
    void init_regs(::Phv &phv) override;
    target_t type() const override { return FLATROCK; }
    unsigned mau_groupsize() const override { return 256; }  // all in the same group
};

#endif /* BF_ASM_FLATROCK_PHV_H_ */
