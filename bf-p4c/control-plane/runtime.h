#ifndef EXTENSIONS_BF_P4C_CONTROL_PLANE_RUNTIME_H_
#define EXTENSIONS_BF_P4C_CONTROL_PLANE_RUNTIME_H_

#include "ir/ir.h"

namespace IR {
class P4Program;
}  // namespace IR

class BFN_Options;

namespace BFN {


/**
 * \ingroup midend
 * \brief Pass that sets default table size to 512 entries.
 */
class SetDefaultSize : public Modifier {
    bool warn = false;
    bool preorder(IR::P4Table *table) override;

 public:
     explicit SetDefaultSize(bool warn) : warn(warn) {}
};

/// A convenience wrapper for P4::generateP4Runtime(). This must be called
/// before the translation pass and will generate the correct P4Info message
/// based on the original architecture (v1model, PSA, TNA or JNA).
void generateRuntime(const IR::P4Program* program,
                       const BFN_Options& options);

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_CONTROL_PLANE_RUNTIME_H_ */
