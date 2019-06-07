#ifndef BF_P4C_ARCH_FROMV1_0_RESUBMIT_H_
#define BF_P4C_ARCH_FROMV1_0_RESUBMIT_H_

#include <utility>
#include <vector>

#include "ir/ir.h"
#include "lib/cstring.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

namespace BFN {

struct FieldPacking;

using ResubmitSources = IR::Vector<IR::Expression>;
using ResubmitExtracts = std::map<unsigned, std::pair<cstring, const ResubmitSources*>>;

class FixupResubmitMetadata : public PassManager {
    ResubmitExtracts fieldExtracts;

 public:
    FixupResubmitMetadata(P4::ReferenceMap *refMap, P4::TypeMap *typeMap);
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_FROMV1_0_RESUBMIT_H_ */
