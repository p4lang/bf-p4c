#ifndef BF_P4C_PARDE_CHECKSUM_H_
#define BF_P4C_PARDE_CHECKSUM_H_

#include "ir/ir.h"

namespace IR {
namespace BFN {
class Pipe;
}  // namespace BFN
class P4Control;
}  // namespace IR

namespace BFN {

/**
 * Attempts to convert the P4 code in the provided control into deparser
 * EmitChecksum primitives. The control is expected to follow the pattern of
 * tofino.p4's IngressDeparser and EgressDeparser control.
 *
 *   if (header.isValid()) {
 *     checksumExternInstance.update({
 *        header.sourceField1,
 *        header.sourceField2
 *     }, header.destField);
 *   }
 */
IR::BFN::Pipe*
extractChecksumFromDeparser(const IR::BFN::TranslatedP4Deparser* deparser,
                            IR::BFN::Pipe* pipe);
}  // namespace BFN
#endif /* BF_P4C_PARDE_CHECKSUM_H_ */
