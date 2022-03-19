#ifndef BF_ASM_FLATROCK_PHV_H_
#define BF_ASM_FLATROCK_PHV_H_

#include "../phv.h"

class Target::Flatrock::Phv : public Target::Phv {
    friend class ::Phv;
    struct Register : public ::Phv::Register {
        short parde_id, ixb_id;
        // 'parde_id' will be the byte number of the first (lowest) byte of the PHE in the
        // 256-byte parde vector (which does not include all 320 bytes of PHV)
        // see https://wiki.ith.intel.com/display/ITS51T/Frame+Processing+Pipeline#FrameProcessingPipeline-PHVNumbering    (NOLINT)
        int parser_id() const override { return parde_id; }
        int mau_id() const override { return uid; }
        int ixbar_id() const override { return ixb_id; }
        int deparser_id() const override { return parde_id; }
    };
    void init_regs(::Phv &phv) override;
    target_t type() const override { return FLATROCK; }
    unsigned mau_groupsize() const override { return 320; }  // all in the same group ?
};

#endif /* BF_ASM_FLATROCK_PHV_H_ */
