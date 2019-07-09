#ifndef BF_P4C_ARCH_FROMV1_0_PHASE0_H_
#define BF_P4C_ARCH_FROMV1_0_PHASE0_H_

#include "ir/ir.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

namespace BFN {

/**
 * Searches for a phase 0 table and transforms the program to implement it.
 *
 * If a phase 0 table is found, the following transformations are performed:
 *  - The `apply()` call that invokes the phase 0 table is removed. The table
 *  itself remains in case it's invoked in multiple places; if it isn't, dead
 *  code elimination will remove it.
 *  - An `@phase0` annotation describing the control plane API for the phase 0
 *  table and the layout of its fields is generated and attached to the ingress
 *  control.
 *  - A parser state which extracts the phase 0 data and implements the phase
 *  0 table's action is generated and substituted into the `__phase0` parser
 *  state.
 *
 * XXX(seth): There is a known issue with this pass: the parser it generates
 * will be invalid if the P4 program uses a different name for the TNA M
 * parameter in the ingress parser than it uses in the ingress control. This
 * will get fixed with a followup PR.
 *
 * @pre All controls are inlined, the program has been transformed to use the
 * TNA architecture, and a `__phase0` parser state has been created.
 * @post The transformations above are applied if a phase 0 table is found.
 */
struct TranslatePhase0 : public PassManager {
    TranslatePhase0(P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
};

typedef std::map<const IR::BFN::TnaParser*, const IR::Type_StructLike*> Phase0CallMap;

/* Check if phase0 extern - port_metadata_unpack - is used in the program.
 * Since we can have multiple ingress parsers, we create a map of parser -
 * fields to extract for each parser
 * Fields can be specified as a Type_Header/Type_Struct
 */
class CheckPhaseZeroExtern: public Inspector {
 public:
    CheckPhaseZeroExtern(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
            Phase0CallMap *phase0_calls) :
            refMap(refMap), typeMap(typeMap), phase0_calls(phase0_calls) {
        setName("CheckPhaseZeroExtern"); }

 private:
    bool preorder(const IR::MethodCallExpression* expr) override;

    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    Phase0CallMap *phase0_calls;
};

class UpdatePhase0NodeInParser: public Transform {
 public:
    explicit UpdatePhase0NodeInParser(
            Phase0CallMap *phase0_calls, IR::IndexedVector<IR::Node> *decls)
            : phase0_calls(phase0_calls), declarations(decls) {
        setName("UpdatePhase0NodeInParser"); }

 private:
    IR::IndexedVector<IR::StructField>* canPackDataIntoPhase0(
            const IR::IndexedVector<IR::StructField>* fields,
            const int);
    // Populate Phase0 Node in Parser & generate new Phase0 Header type
    IR::BFN::TnaParser* preorder(IR::BFN::TnaParser *parser) override;

    Phase0CallMap *phase0_calls;
    IR::IndexedVector<IR::Node> *declarations;
    int phase0_count = 0;
};

// Replace phase0 struct/header declaration to new phase0 header with flexible
// layout annotation for backend
class UpdatePhase0Header: public Transform {
 public:
    explicit UpdatePhase0Header(IR::IndexedVector<IR::Node>* decls)
            : declarations(decls) {
        setName("UpdatePhase0Header"); }

 private:
    IR::Node* preorder(IR::Type_Struct* s) override {
        LOG3("visiting struct : " << s);
        if (auto* d = declarations->getDeclaration(s->name.toString())) {
            LOG4("modifying struct " << s << " to header " << d->to<IR::Type_Header>());
            return d->to<IR::Node>()->clone(); }
        return s; }

    IR::IndexedVector<IR::Node> *declarations;
};

/* A Phase0 assignment statement in IR is converted into an extract for the
 * backend Parser
 * E.g.
 * Before => ig_md.port_md = port_metadata_unpack<my_port_metadata_t>(pkt);
 * After  => pkt.extract<my_port_metadata_t>(ig_md.port_md);
 *
 * A Phase0 method call expression in IR is converted into an extract for the
 * backend Parser
 * E.g.
 * Before => port_metadata_unpack<my_port_metadata_t>(pkt);
 * After  => pkt.advance(64); // for Tofino
 * After  => pkt.advance(192); // for Tofino2
 * The advance bits are determined by
 * Device::pardeSpec().bitPhase0Size() + Device::pardeSpec().bitIngressPrePacketPaddingSize()
 * as specified in bf-p4c/parde/parde_spec.h
 *
 * Used when we dont wish to extract the fields but simply advance or skip
 * through phase0 or port metadata
 */
class ConvertPhase0AssignToExtract: public Transform {
 public:
    ConvertPhase0AssignToExtract(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) :
            refMap(refMap), typeMap(typeMap) {
        setName("ConvertPhase0MceToExtract");
    }

 private:
    IR::MethodCallExpression* generate_phase0_extract_method_call(
            const IR::Expression* lExpr, const IR::MethodCallExpression *rExpr);
    IR::Node* preorder(IR::MethodCallExpression* expr) override;
    IR::Node* preorder(IR::AssignmentStatement* stmt) override;

    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
};

class ConvertPhase0 : public PassManager {
 public:
    ConvertPhase0(P4::ReferenceMap *refMap, P4::TypeMap *typeMap) {
        auto* phase0_calls = new Phase0CallMap();
        auto* decls = new IR::IndexedVector<IR::Node>();
        addPasses({
            new CheckPhaseZeroExtern(refMap, typeMap, phase0_calls),
            new UpdatePhase0NodeInParser(phase0_calls, decls),
            new UpdatePhase0Header(decls),
            new ConvertPhase0AssignToExtract(refMap, typeMap),
        });
    }
};

}  // namespace BFN

#endif /* BF_P4C_ARCH_FROMV1_0_PHASE0_H_ */
