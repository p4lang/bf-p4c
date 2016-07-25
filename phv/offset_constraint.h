#ifndef TOFINO_PHV_OFFSET_CONSTRAINT_H_
#define TOFINO_PHV_OFFSET_CONSTRAINT_H_

#include "ir/ir.h"
#include "bit_extractor.h"

class Constraints;
class OffsetConstraint : public Inspector, public BitExtractor {
 public:
    OffsetConstraint(const PhvInfo &phv, Constraints &ec)
    : BitExtractor(phv), equality_constraints_(ec) { }
    bool preorder(const IR::Primitive *prim) override;
 private:
    Constraints &equality_constraints_;
};

#endif /* TOFINO_PHV_OFFSET_CONSTRAINT_H_ */
