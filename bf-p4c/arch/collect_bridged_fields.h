#ifndef BF_P4C_ARCH_COLLECT_BRIDGED_FIELDS_H_
#define BF_P4C_ARCH_COLLECT_BRIDGED_FIELDS_H_

#include <boost/optional.hpp>
#include <utility>
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/ordered_map.h"
#include "lib/ordered_set.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

namespace BFN {

using FieldRef = std::pair<cstring, cstring>;

struct BridgedFieldInfo {
    const IR::Type* type;
    const IR::Expression* refTemplate;
};

struct CollectBridgedFields : public Inspector,
                              protected ControlFlowVisitor,
                              protected P4WriteContext {
    using TnaParams = ordered_map<cstring, cstring>;
    using TnaContext = std::pair<gress_t, const TnaParams&>;

    CollectBridgedFields(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);

    ordered_set<FieldRef> mayReadUninitialized[2];
    ordered_set<FieldRef> mayWrite[2];
    ordered_set<FieldRef> mustWrite[2];  // XXX(seth): Not much use testing this...

    ordered_map<FieldRef, BridgedFieldInfo> fieldInfo;
    ordered_set<FieldRef> fieldsToBridge;
    ordered_set<cstring> doNotBridge;

 private:
    CollectBridgedFields* clone() const override;
    void flow_merge(Visitor& otherVisitor) override;

    boost::optional<TnaContext> findTnaContext() const;
    bool analyzePathlikeExpression(const IR::Expression* expr);

    bool preorder(const IR::Annotation* annot) override;
    bool preorder(const IR::Member* member) override;
    bool preorder(const IR::PathExpression* path) override;
    void end_apply() override;

    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

}  // namespace BFN

#endif  /* BF_P4C_ARCH_COLLECT_BRIDGED_FIELDS_H_ */
