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
 * v1model.p4's ComputeChecksum control.
 *
 * Only a very specific pattern is permitted. Each checksum computation must be
 * defined as either:
 * ```
 *   if (header.isValid()) {
 *     header.destField = checksumExternInstance.get({
 *        header.sourceField1,
 *        header.sourceField2
 *     });
 *   }
 * ```
 * or (a bit less cleanly):
 * ```
 *   header.destField = checksumExternInstance.get({
 *      header.sourceField1,
 *      header.sourceField2
 *   });
 * ```
 *
 * This pattern reflects the actual behavior of the hardware. Any deviation will
 * result in a warning and the computation will be ignored.
 *
 * It's enforced that the `isValid()` call (if any), the destination field, and
 * the list of source fields all reference the same header instance.
 * XXX(seth): This doesn't reflect a real hardware restriction - it's just
 * that ideally, we'd want to generate a warning or an error if the
 * programmer doesn't check if all the headers involved are valid, and right
 * now we can't compile that check, so there'd be no way to get rid of the
 * warning. To make this work, we need to be able to generate a new POV bit
 * field and MAU or parser code to set it in a way that matches the complex
 * condition. Once we have that, we should remove this restriction.
 *
 * @param computeChecksumControl  The P4 control which should be analyzed. May
 *                                be null, in which case the original pipe will
 *                                just be returned unaltered.
 * @param pipe  The pipe which should hold the generated deparser primitives.
 * @return a modified pipe in which both the ingress and egress deparser have
 *         been modified to include the discovered checksum computations. If no
 *         checksum computations were discovered, the original pipe is returned
 *         unaltered.
 */
IR::BFN::Pipe*
extractComputeChecksum(const IR::P4Control* computeChecksumControl,
                       IR::BFN::Pipe* pipe);

/**
 * Attempts to convert the P4 code in the provided control into deparser
 * EmitChecksum primitives. The control is expected to follow the pattern of
 * tofino.p4's IngressDeparser and EgressDeparser control.
 *
 * Only a very specific pattern is permitted. Each checksum computation must be
 * defined as either:
 * ```
 *   if (header.isValid()) {
 *     checksumExternInstance.update({
 *        header.sourceField1,
 *        header.sourceField2
 *     }, header.destField);
 *   }
 * ```
 * or (a bit less cleanly):
 * ```
 *   checksumExternInstance.update({
 *      header.sourceField1,
 *      header.sourceField2
 *   }, header.destField);
 * ```
 *
 * This pattern reflects the actual behavior of the hardware. Any deviation will
 * result in a warning and the computation will be ignored.
 *
 * XXX(hanw): this function does not handle the incremental checksum yet. The analysis
 * we have to do on deparser control block to support incremental is more involved.
 *
 * @param deparserControl The P4 control to be analyzed.
 * @param pipe The pipe which should hold the generated deparser primitives.
 * @return a modified pipe in which the deparser have been modified to include
 *         the discovered checksum computations. If no checksum computations
 *         were discovered, the original pipe is returned
 *         unaltered.
 */
IR::BFN::Pipe*
extractChecksumFromDeparser(const IR::P4Control* deparserControl,
                            IR::BFN::Pipe* pipe);

}  // namespace BFN
#endif /* BF_P4C_PARDE_CHECKSUM_H_ */
