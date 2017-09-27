#ifndef EXTENSIONS_BF_P4C_CONTROL_PLANE_TOFINO_P4RUNTIME_H_
#define EXTENSIONS_BF_P4C_CONTROL_PLANE_TOFINO_P4RUNTIME_H_

namespace IR {
class P4Program;
}  // namespace IR

class BFN_Options;

namespace BFN {

/// A convenience wrapper for P4::generateP4Runtime().
void generateP4Runtime(const IR::P4Program* program,
                       const BFN_Options& options);

}  // namespace BFN

#endif /* EXTENSIONS_BF_P4C_CONTROL_PLANE_TOFINO_P4RUNTIME_H_ */
