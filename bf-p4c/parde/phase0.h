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

#ifndef BF_P4C_PARDE_PHASE0_H_
#define BF_P4C_PARDE_PHASE0_H_

#include <utility>
#include <vector>

#include "lib/cstring.h"

namespace IR {
namespace BFN {
class Pipe;
}  // namespace BFN
class P4Control;
class P4Table;
}  // namespace IR

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

namespace BFN {

struct FieldPacking;

/// Phase 0 metadata; used to generate phase 0 assembly.
struct Phase0Info {
    const IR::P4Table* table;     /// The phase 0 table.
    const FieldPacking* packing;  /// How the phase 0 fields should be packed.
};

/**
 * Searches for a phase 0 table. If one is found, it's removed from the program,
 * and parser code implementing its behavior is patched into the parser program.
 * The metadata needed to generate the assembly output for phase 0 is also
 * attached to the pipe.
 *
 * @param ingress  The control to search for the phase 0 table. As the name
 *                 implies, this only makes sense for the ingress control.
 * @param pipe     The pipe to which any generated phase 0 parser should be
 *                 attached.
 * @return a new ingress control without the phase 0 table, and a new pipe which
 *         includes the phase 0 parser. If there is no phase 0 table, the
 *         original ingress control and pipe are returned unaltered.
 */
std::pair<const IR::P4Control*, IR::BFN::Pipe*>
extractPhase0(const IR::P4Control* ingress, IR::BFN::Pipe* pipe,
              P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

}  // namespace BFN

std::ostream& operator<<(std::ostream& out, const BFN::Phase0Info* info);

#endif /* BF_P4C_PARDE_PHASE0_H_ */
