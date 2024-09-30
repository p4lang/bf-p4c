#ifndef BF_P4C_PARDE_EXTRACT_DEPARSER_H_
#define BF_P4C_PARDE_EXTRACT_DEPARSER_H_

#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/exceptions.h"
#include "frontends/p4/typeMap.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/arch/bridge_metadata.h"
#include "bf-p4c/common/ir_utils.h"
#include "bf-p4c/common/pragma/all_pragmas.h"
#include "bf-p4c/common/pragma/collect_global_pragma.h"
#include "bf-p4c/device.h"
#include "bf-p4c/ir/gress.h"
#include "bf-p4c/parde/parde_visitor.h"

namespace P4 {
namespace IR {

namespace BFN {
class Pipe;
}  // namespace BFN

class P4Control;

}  // namespace IR
}  // namespace P4

namespace BFN {

/**
 * @ingroup parde
 * @brief Transforms midend deparser P4::IR::BFN::TnaDeparser into backend deparser P4::IR::BFN::Deparser
 *
 * @pre Assume the nested if statements are already canonicalized to a
 *      single if statement enclosing any emit/pack method calls.
 */
class ExtractDeparser : public DeparserInspector {
    P4::TypeMap                                 *typeMap;
    P4::ReferenceMap                            *refMap;
    P4::IR::BFN::Pipe                               *rv;
    P4::IR::BFN::Deparser                           *dprsr = nullptr;
    ordered_map<cstring, P4::IR::BFN::Digest *>     digests;

    ordered_map<cstring, std::vector<const P4::IR::BFN::EmitField*>> headerToEmits;

    std::set<ordered_set<cstring>*>             userEnforcedHeaderOrdering;

    void generateEmits(const P4::IR::MethodCallExpression* mc);
    void generateDigest(P4::IR::BFN::Digest *&digest, cstring name, const P4::IR::Expression *list,
                        const P4::IR::Expression* select, int digest_index,
                        cstring controlPlaneName = nullptr);
    void convertConcatToList(std::vector<const P4::IR::Expression*>& slices, const P4::IR::Concat* expr);
    void processConcat(P4::IR::Vector<P4::IR::BFN::FieldLVal>& vec, const P4::IR::Concat* expr);

    std::tuple<int, const P4::IR::Expression*>
        getDigestIndex(const P4::IR::IfStatement*, cstring name, bool singleEntry = false);
    int getDigestIndex(const P4::IR::Declaration_Instance*);
    void processMirrorEmit(const P4::IR::MethodCallExpression*, const P4::IR::Expression*, int idx);
    void processMirrorEmit(const P4::IR::MethodCallExpression*, int idx);
    void processResubmitEmit(const P4::IR::MethodCallExpression*, const P4::IR::Expression*, int idx);
    void processResubmitEmit(const P4::IR::MethodCallExpression*, int idx);
    void processDigestPack(const P4::IR::MethodCallExpression*, int, cstring);
    void enforceHeaderOrdering();

    /// Get the standard TNA parameter name corresponding to the paramater name used in the P4
    P4::IR::ID getTnaParamName(const P4::IR::BFN::TnaDeparser *deparser, P4::IR::ID orig_name);

    bool preorder(const P4::IR::Annotation* annot) override;
    bool preorder(const P4::IR::AssignmentStatement* stmt) override;
    void postorder(const P4::IR::MethodCallExpression* mc) override;
    void end_apply() override;

 public:
    explicit ExtractDeparser(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                            P4::IR::BFN::Pipe *rv) :
            typeMap(typeMap), refMap(refMap), rv(rv) {
        setName("ExtractDeparser");
    }

    bool preorder(const P4::IR::BFN::TnaDeparser* deparser) override {
        gress_t thread = deparser->thread;
        dprsr = new P4::IR::BFN::Deparser(thread);
        digests.clear();
        return true;
    }

    void postorder(const P4::IR::BFN::TnaDeparser* deparser) override {
        for (const auto& kv : digests) {
            auto name = kv.first;
            auto digest = kv.second;
            if (!digest)
                continue;
            for (auto fieldList : digest->fieldLists) {
                if (fieldList->idx < 0 ||
                    fieldList->idx > static_cast<int>(Device::maxCloneId(deparser->thread))) {
                    ::P4::error("Invalid %1% index %2% in %3%", name, fieldList->idx,
                            int(deparser->thread));
                }
            }
        }
        rv->thread[deparser->thread].deparser = dprsr; }
};
//// check if the LHS of the assignment statements are being used
// in mirror, digest or resubmit.
struct AssignmentStmtErrorCheck : public DeparserInspector {
    const P4::IR::Type* left = nullptr;
    bool stmtOk = false;
    explicit AssignmentStmtErrorCheck(const P4::IR::Type* left) : left(left) { }

    void postorder(const P4::IR::MethodCallExpression* methodCall) override {
        auto member = methodCall->method->to<P4::IR::Member>();
        auto expr = member->expr->to<P4::IR::PathExpression>();
        if (!expr) return;
        const P4::IR::Type_Extern* type = nullptr;
        if (auto spType = expr->type->to<P4::IR::Type_SpecializedCanonical>()) {
            type = spType->baseType->to<P4::IR::Type_Extern>();
        } else {
            type = expr->type->to<P4::IR::Type_Extern>();
        }
        if (!type) return;
        if (type->name != "Mirror" && type->name != "Digest" && type->name != "Resubmit") {
            return;
        }
        auto arguments = *methodCall->arguments;
        for (auto argument : arguments) {
            if (argument->expression->type->equiv(*left)) {
                stmtOk = true;
                return;
            }
        }
        return;
    }
};

}  // namespace BFN

#endif /* BF_P4C_PARDE_EXTRACT_DEPARSER_H_ */
