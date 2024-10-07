#ifndef BF_P4C_ARCH_FROMV1_0_PARSER_COUNTER_H_
#define BF_P4C_ARCH_FROMV1_0_PARSER_COUNTER_H_

#include "bf-p4c/arch/fromv1.0/v1_converters.h"

namespace BFN {
namespace V1 {

class ParserCounterConverter : public StatementConverter {
    void cannotFit(const IR::AssignmentStatement* stmt, const char* what);

 public:
    explicit ParserCounterConverter(ProgramStructure *structure)
    : StatementConverter(structure) { CHECK_NULL(structure); }
    const IR::Node* postorder(IR::AssignmentStatement *node) override;
};

class ParserCounterSelectionConverter : public PassManager {
 public:
    ParserCounterSelectionConverter();
};

}  // namespace V1
}  // namespace BFN

#endif /* BF_P4C_ARCH_FROMV1_0_PARSER_COUNTER_H_ */
