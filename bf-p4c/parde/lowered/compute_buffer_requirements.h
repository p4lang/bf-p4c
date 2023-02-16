#ifndef EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_BUFFER_REQUIREMENTS_H_
#define EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_BUFFER_REQUIREMENTS_H_

#include "bf-p4c/parde/parde_visitor.h"

namespace Parde::Lowered {

/**
 * @ingroup LowerParser
 * @brief Computes the number of bytes which must be available for each parser match
 *        to avoid a stall.
 */
class ComputeBufferRequirements : public ParserModifier {
    void postorder(IR::BFN::LoweredParserMatch* match) override;
};

}  // namespace Parde::Lowered

#endif /* EXTENSIONS_BF_P4C_PARDE_LOWERED_COMPUTE_BUFFER_REQUIREMENTS_H_ */
