#ifndef BF_P4C_PHV_ASM_OUTPUT_H_
#define BF_P4C_PHV_ASM_OUTPUT_H_

#include <iosfwd>

class PhvInfo;
class FieldDefUse;

class PhvAsmOutput {
    const PhvInfo     &phv;
    const FieldDefUse &defuse;
    bool have_ghost;

    struct LiveRange {
        const IR::BFN::Unit* first;
        const IR::BFN::Unit* last;
        LiveRange operator|=(const LiveRange& other);
    };

    /// Tracks the first/last unit in which each field is live.
    /// XXX(cole): This is conservative in the case where a field is live then
    /// dead then live again.
    std::map<const PHV::Field*, LiveRange> liveRanges;

    /// Populate liveRanges.
    void getLiveRanges();

    void emit_phv_field_info(std::ostream& out, PHV::Field& f) const;
    void emit_gress(std::ostream& out, gress_t gress) const;
    friend std::ostream &operator<<(std::ostream &, const PhvAsmOutput &);

 public:
    explicit PhvAsmOutput(const PhvInfo &p, const FieldDefUse& defuse, bool have_ghost = false);
};

#endif /* BF_P4C_PHV_ASM_OUTPUT_H_ */
