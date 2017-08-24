/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#ifndef _TOFINO_PARDE_CHECKSUM_H_
#define _TOFINO_PARDE_CHECKSUM_H_

namespace IR {
namespace Tofino {
class Pipe;
}  // namespace Tofino
class P4Control;
}  // namespace IR

namespace Tofino {

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
IR::Tofino::Pipe*
extractComputeChecksum(const IR::P4Control* computeChecksumControl,
                       IR::Tofino::Pipe* pipe);

}  // namespace Tofino
#endif /* _TOFINO_PARDE_CHECKSUM_H_ */
