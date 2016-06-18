#ifndef TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#define TOFINO_PHV_CONTAINER_CONSTRAINT_H_
#include <set>
#include "ir/ir.h"
#include "bit_extractor.h"
#include "phv_fields.h"

class Constraints;
class ContainerConstraint : public Inspector, public BitExtractor {
 public:
    ContainerConstraint(const PhvInfo &phv,
        std::function<bool(const IR::MAU::Table *, const IR::MAU::Table *)> m,
        Constraints &ec) : phv(phv), mutex(m), constraints_(ec) { }

 private:
    void end_apply() { uses.clear(); }
    bool preorder(const IR::Primitive *prim) override;
    bool preorder(const IR::MAU::Instruction *inst) override;
    bool preorder(const IR::Tofino::Deparser *dp) override;
    void postorder(const IR::MAU::Table *tbl) override;
    const PhvInfo &phv;
    std::function<bool(const IR::MAU::Table *, const IR::MAU::Table *)> mutex;
    vector<std::map<const IR::MAU::Table *, std::set<const PhvInfo::Info *>>> uses;
    Constraints &constraints_;
};
#endif /* TOFINO_PHV_CONTAINER_CONSTRAINT_H_ */
