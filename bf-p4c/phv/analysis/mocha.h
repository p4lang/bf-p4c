#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_MOCHA_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_MOCHA_H_

#include "ir/ir.h"
#include "bf-p4c/mau/action_analysis.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/analysis/non_mocha_dark_fields.h"

/** This pass analyzes all fields used in the program and marks the fields suitable for allocation
  * in mocha containers by setting the `is_mocha_candidate()` property of the corresponding
  * PHV::Field object to true.
  * Here are the generic rules for mocha containers:
  * 1. Mocha containers can be used as sources for any ALU operation writing normal PHVs.
  * 2. Mocha containers can be used on the input crossbar.
  * 3. Mocha containers cannot be written using nonset operations.
  * 4. Set operations on mocha containers can only operate on entire containers (so restrictions on
  *    packing).
  */
class CollectMochaCandidates : public Inspector {
 private:
    PhvInfo                  &phv;
    const PhvUse             &uses;
    const NonMochaDarkFields &nonMochaDark;
    bool                      pov_on_mocha;

    /// Number of mocha candidates detected.
    size_t          mochaCount;
    /// Size in bits of mocha candidates.
    size_t          mochaSize;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Action* act) override;
    void end_apply() override;

 public:
    explicit CollectMochaCandidates(PhvInfo& p, const PhvUse& u, const NonMochaDarkFields &nmd) :
        phv(p), uses(u), nonMochaDark(nmd), mochaCount(0), mochaSize(0) { }

    /// @returns true when @p f is a field from a packet (not metadata, pov, or bridged field).
    static bool isPacketField(const PHV::Field* f) {
        return (f && !f->metadata && !f->pov && !f->bridged && !f->overlayable);
    }
};

#endif  /* EXTENSIONS_BF_P4C_PHV_ANALYSIS_MOCHA_H_ */
