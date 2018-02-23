#ifndef BF_P4C_PARDE_RESUBMIT_H_
#define BF_P4C_PARDE_RESUBMIT_H_

#include <utility>
#include <vector>

#include "ir/ir.h"
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

using ResubmitSources = IR::Vector<IR::Expression>;
using ResubmitExtracts = std::map<unsigned, const ResubmitSources*>;
using ResubmitPacking = std::map<unsigned, const FieldPacking*>;

std::pair<const IR::P4Control*, IR::BFN::Pipe*>
extractResubmit(const IR::P4Control* ingress, IR::BFN::Pipe* pipe,
                P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

// This pass must be applied to IR::P4Program
class ExtractResubmitFieldPackings : public PassManager {
 public:
    ExtractResubmitFieldPackings(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                                 ResubmitPacking* fieldPackings);

    ResubmitPacking* fieldPackings;
};

// This pass must be applied to IR::BFN::Pipe
class PopulateResubmitStateWithFieldPackings : public PassManager {
 public:
    explicit PopulateResubmitStateWithFieldPackings(const ResubmitPacking* fieldPackings);
    const ResubmitPacking* fieldPackings;
};

}  // namespace BFN

#endif /* BF_P4C_PARDE_RESUBMIT_H_ */
