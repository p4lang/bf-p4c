#ifndef EXTENSIONS_BF_P4C_PHV_ANALYSIS_DARK_H_
#define EXTENSIONS_BF_P4C_PHV_ANALYSIS_DARK_H_

#include "ir/ir.h"
#include "bf-p4c/phv/phv_fields.h"
#include "bf-p4c/phv/analysis/mocha.h"

/** This pass analyzes all fields used in the program and marks fields suitable for allocation in
  * dark containers by setting the `is_dark_candidate()` property of the corresponding PHV::Field
  * object to true. Fields amenable for allocation to dark containers must satisfy all the
  * requirements for allocation to mocha containers, and also the following additional requirements:
  * 1. Dark fields cannot be used in the parser/deparser.
  * 2. Dark fields cannot be used on the input crossbar.
  *
  * This pass must be run after the CollectMochaCandidates pass as we use the fields marked with 
  * is_mocha_candidate() as the starting point for this pass.
  */
class CollectDarkCandidates : public Inspector {
 private:
    PhvInfo&            phv;
    const PhvUse&       uses;

    /// Represents all fields with MAU uses that prevent allocation into dark containers.
    /// E.g. use on input crossbar, participation in meter operations, etc.
    bitvec          nonDarkMauUses;

    /// Number of dark candidates detected.
    size_t          darkCount;
    /// Size in bits of mocha candidates.
    size_t          darkSize;

    profile_t init_apply(const IR::Node* root) override;
    bool preorder(const IR::MAU::Table* tbl) override;
    bool preorder(const IR::MAU::Action* act) override;
    bool preorder(const IR::MAU::InputXBarRead *read) override;
    bool preorder(const IR::MAU::Meter* mtr) override;
    void end_apply() override;

 public:
    explicit CollectDarkCandidates(PhvInfo& p, const PhvUse& u) : phv(p), uses(u) { }
};

#endif  /*  EXTENSIONS_BF_P4C_PHV_ANALYSIS_DARK_H_  */
