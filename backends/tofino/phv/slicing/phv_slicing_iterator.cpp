#include "backends/tofino/phv/slicing/phv_slicing_iterator.h"

#include "backends/tofino/phv/action_packing_validator_interface.h"
#include "backends/tofino/phv/slicing/phv_slicing_dfs_iterator.h"

namespace PHV {
namespace Slicing {

ItrContext::ItrContext(const PhvInfo& phv,
                       const MapFieldToParserStates& fs,
                       const CollectParserInfo& pi,
                       const SuperCluster* sc,
                       const PHVContainerSizeLayout& pa,
                       const ActionPackingValidatorInterface& action_packing_validator,
                       const ParserPackingValidatorInterface& parser_packing_validator,
                       const PackConflictChecker pack_conflict,
                       const IsReferencedChecker is_referenced)
    : pImpl(new DfsItrContext(phv,
                              fs,
                              pi,
                              sc,
                              pa,
                              action_packing_validator,
                              parser_packing_validator,
                              pack_conflict,
                              is_referenced)) {}

}  // namespace Slicing
}  // namespace PHV
