#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_INIT_ZERO_CONTAINERS_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_INIT_ZERO_CONTAINERS_H_

#include "bf-p4c/parde/parde_visitor.h"
#include "bf-p4c/common/field_defuse.h"

namespace Parde::Lowered {

/// Compute containers that have fields relying on parser zero initialization, these containers
/// will be marked as valid coming out of the parser (Tofino only). In Tofino2, all containers
/// are valid coming out of the parser.
class ComputeInitZeroContainers : public ParserModifier {
    void postorder(IR::BFN::LoweredParser* parser) override;

 public:
    ComputeInitZeroContainers(
            const PhvInfo& phv,
            const FieldDefUse& defuse,
            const ordered_set<const PHV::Field*>& no_init,
            const std::map<gress_t, std::set<PHV::Container>>& origParserZeroInitContainers)
        : phv(phv), defuse(defuse), no_init_fields(no_init),
          origParserZeroInitContainers(origParserZeroInitContainers) {}

    const PhvInfo& phv;
    const FieldDefUse& defuse;
    const ordered_set<const PHV::Field*>& no_init_fields;
    const std::map<gress_t, std::set<PHV::Container>>& origParserZeroInitContainers;
};

}  // namespace Parde::Lowered

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_INIT_ZERO_CONTAINERS_H_ */
