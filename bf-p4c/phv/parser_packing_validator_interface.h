#ifndef BF_P4C_PHV_PARSER_PACKING_VALIDATOR_INTERFACE_H_
#define BF_P4C_PHV_PARSER_PACKING_VALIDATOR_INTERFACE_H_

#include "bf-p4c/phv/v2/utils_v2.h"

namespace PHV {

class ParserPackingValidatorInterface {
 public:
    /// @returns an error if we allocated slices in the format of @p alloc.
    /// @p c is optional for 32-bit container half-word extract optimization.
    virtual const v2::AllocError* can_pack(const v2::FieldSliceAllocStartMap& alloc,
                                           const boost::optional<Container>& c) const = 0;
};

}  // namespace PHV

#endif /* BF_P4C_PHV_PARSER_PACKING_VALIDATOR_INTERFACE_H_ */
