#ifndef BF_P4C_PARDE_RESUBMIT_H_
#define BF_P4C_PARDE_RESUBMIT_H_

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

std::pair<const IR::P4Control*, IR::BFN::Pipe*>
extractResubmit(const IR::P4Control* ingress, IR::BFN::Pipe* pipe,
                P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

}  // namespace BFN

#endif /* BF_P4C_PARDE_RESUBMIT_H_ */
