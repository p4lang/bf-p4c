#ifndef BF_P4C_PARDE_GEN_DEPARSER_H_
#define BF_P4C_PARDE_GEN_DEPARSER_H_

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

namespace IR {

namespace BFN {
class Pipe;
}  // namespace BFN

class P4Control;

}  // namespace IR

namespace BFN {

class ExtractDeparser : public DeparserInspector {
    P4::TypeMap                                 *typeMap;
    P4::ReferenceMap                            *refMap;
    IR::BFN::Pipe                               *rv;
    IR::BFN::Deparser                           *dprsr = nullptr;
    const IR::Expression                        *pred = nullptr;
    ordered_map<cstring, IR::BFN::Digest *>     digests;
    ordered_map<cstring, cstring>               nameMap;
    const CollectGlobalPragma                   &collect_pragma;

    ordered_map<cstring, std::vector<const IR::BFN::EmitField*>> headerToEmits;

    std::set<ordered_set<cstring>*>             userEnforcedHeaderOrdering;

    void generateEmits(const IR::MethodCallExpression* mc);
    void generateDigest(IR::BFN::Digest *&digest, cstring name, const IR::Expression *list,
                        const IR::MethodCallExpression* mc, cstring controlPlaneName = nullptr,
                        bool singleEntry = false);
    void simpl_concat(std::vector<const IR::Expression*>& slices, const IR::Concat* expr);
    void process_concat(IR::Vector<IR::BFN::FieldLVal>& vec, const IR::Concat* expr);
    void fixup_mirror_digest(const IR::MethodCallExpression*,
            IR::IndexedVector<IR::NamedExpression>*);

    void enforceHeaderOrdering();

    bool preorder(const IR::Annotation* annot) override;
    bool preorder(const IR::Declaration_Instance *decl) override;
    bool preorder(const IR::IfStatement *ifstmt) override;
    bool preorder(const IR::MethodCallExpression* mc) override;
    bool preorder(const IR::AssignmentStatement* stmt) override;
    void end_apply() override;

 public:
    explicit ExtractDeparser(P4::ReferenceMap* refMap, P4::TypeMap* typeMap,
                            IR::BFN::Pipe *rv, CollectGlobalPragma &collect_pragma) :
            typeMap(typeMap), refMap(refMap), rv(rv), collect_pragma(collect_pragma) {
        setName("ExtractDeparser");
    }

    bool preorder(const IR::BFN::TnaDeparser* deparser) override {
        gress_t thread = deparser->thread;
        dprsr = new IR::BFN::Deparser(thread);
        digests.clear();
        nameMap.clear();
        return true;
    }

    void postorder(const IR::BFN::TnaDeparser* deparser) override {
        for (const auto& kv : digests) {
            auto name = kv.first;
            auto digest = kv.second;
            if (!digest)
                continue;
            for (auto fieldList : digest->fieldLists) {
                if (fieldList->idx < 0 ||
                    fieldList->idx > static_cast<int>(Device::maxCloneId(deparser->thread))) {
                    ::error("Invalid %1% index %2% in %3%", name, fieldList->idx,
                            int(deparser->thread));
                }
            }
        }

        // COMPILER-914: In Tofino, clone id - 0 is reserved in i2e
        // due to a hardware bug. Hence, valid clone ids are 1 - 7.
        // We check mirror id 0 is not used in the program, and create a dummy
        // mirror (with id = 0) for i2e;
        if (deparser->thread == INGRESS && Device::currentDevice() == Device::TOFINO &&
            BackendOptions().arch == "v1model") {
            // TODO(zma) it's not very clear to me how to handle this for TNA program
            // in particular, the mirror id is a user defined field. So we probably
            // need to find the field reference of mirror id in the program.

            auto mirror = digests["mirror"];
            if (mirror) {
                for (auto fieldList : mirror->fieldLists) {
                    bool disableI2eDropImpl =
                        collect_pragma.exists(PragmaDisableI2EReservedDropImplementation::name);
                    if ((fieldList->idx == 0) && !disableI2eDropImpl) {
                        ::error("Invalid mirror index 0, valid i2e mirror indices are 1-7");
                    }
                }
            } else {
                auto deparserMetadataHdr =
                        getMetadataType(rv, "ingress_intrinsic_metadata_for_deparser");
                auto select = gen_fieldref(deparserMetadataHdr, "mirror_type");
                mirror = new IR::BFN::Digest("mirror", select);
                dprsr->digests.addUnique("mirror", mirror);
            }

            IR::Vector<IR::BFN::FieldLVal> sources;
            auto compilerMetadataHdr = getMetadataType(rv, COMPILER_META);
            auto mirrorId = gen_fieldref(compilerMetadataHdr, "mirror_id");
            sources.push_back(new IR::BFN::FieldLVal(mirrorId));
            auto dummy = new IR::BFN::DigestFieldList(0, sources, nullptr);
            mirror->fieldLists.push_back(dummy);
        }

        rv->thread[deparser->thread].deparser = dprsr; }
};
//// check if the LHS of the assignment statements are being used
// in mirror, digest or resubmit.
struct AssignmentStmtErrorCheck : public DeparserInspector {
    const IR::Type* left = nullptr;
    bool stmtOk = false;
    explicit AssignmentStmtErrorCheck(const IR::Type* left) : left(left) { }

    void postorder(const IR::MethodCallExpression* methodCall) override {
        auto member = methodCall->method->to<IR::Member>();
        auto expr = member->expr->to<IR::PathExpression>();
        if (!expr) return;
        const IR::Type_Extern* type = nullptr;
        if (auto spType = expr->type->to<IR::Type_SpecializedCanonical>()) {
            type = spType->baseType->to<IR::Type_Extern>();
        } else {
            type = expr->type->to<IR::Type_Extern>();
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

#endif /* BF_P4C_PARDE_GEN_DEPARSER_H_ */
