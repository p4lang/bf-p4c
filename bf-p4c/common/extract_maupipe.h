#ifndef BF_P4C_COMMON_EXTRACT_MAUPIPE_H_
#define BF_P4C_COMMON_EXTRACT_MAUPIPE_H_

#include "ir/ir.h"
#include "frontends/common/options.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/midend/param_binding.h"
#include "bf-p4c/arch/fromv1.0/resubmit.h"
#include "bf-p4c/arch/fromv1.0/mirror.h"
#include "bf-p4c/arch/arch.h"

class BFN_Options;
class CreateSaluInstruction;

namespace BFN {

const IR::BFN::Pipe *extract_maupipe(const IR::P4Program *, BFN_Options& options);

/** The purpose of this code is to translate in each pipeline to Backend structures.
 *  At the top of each pipeline, each extern to be used by that pipeline is declared.
 *
 *  At the moment, we only resolve Declaration Instances to create BackendAttached tables.
 *  This may need to extend to other features at somepoint, for example Checksums, or other
 *  potential parser externs.
 *
 *  Furthermore, there is not always a one-to-one map of Declaration_Instance to BackendAttached
 *  table.  The two currently known and handled cases are:
 *      1. An action profile and a action selector share a Declaration_Instance
 *      2. A stateful selector will also share an instance with an action profile or action
 *         selector
 *
 *  These two special cases are handled individually in the code, rather than having a total
 *  map for the entire gress.  Depending on how complicated cases get, this may have to
 *  expanded at somepoint.
 */
typedef std::map<const IR::Declaration_Instance *,
                 const IR::MAU::AttachedMemory *> DeclarationConversions;
// a mapping from Registers to the (converted) ActionSelectors that are bound to them
typedef std::map<const IR::Declaration_Instance *, const IR::MAU::Selector *> StatefulSelectors;

class AttachTables : public PassManager {
    P4::ReferenceMap *refMap;
    P4::TypeMap* typeMap;
    // Have to keep all non StatefulAlus separate from other Declaration_Instances, because
    // selectors and StatefulAlus may have the same Declaration
    DeclarationConversions &converted;
    DeclarationConversions all_salus;
    StatefulSelectors   stateful_selectors;

    // Create all the stateful ALUs by passing over all of the register actions.  Once
    // the pipeline is fully examined, add these to the all_salus map
    class InitializeStatefulAlus : public MauInspector {
        AttachTables &self;
        std::map<const IR::Declaration_Instance *, IR::MAU::StatefulAlu *> salu_inits;
        std::set<const IR::Declaration_Instance *> register_actions;
        std::map<const IR::MAU::StatefulAlu *, CreateSaluInstruction *> inst_ctor;
        void postorder(const IR::Expression *) override { visitAgain(); }
        void postorder(const IR::GlobalRef *) override;
        void end_apply() override;
        void updateAttachedSalu(const IR::Declaration_Instance *,
                                const IR::GlobalRef *);

     public:
        explicit InitializeStatefulAlus(AttachTables &s) : self(s) {}
    };

    class DefineGlobalRefs : public MauModifier {
        AttachTables &self;
        P4::ReferenceMap *refMap;
        P4::TypeMap* typeMap;

        std::map<cstring, safe_vector<const IR::MAU::BackendAttached *>> attached;
        bool preorder(IR::MAU::Table *) override;
        bool preorder(IR::MAU::Action *) override;
        void postorder(IR::MAU::Table *) override;
        void postorder(IR::Expression *) override { visitAgain(); }
        void postorder(IR::GlobalRef *) override;

        const IR::MAU::StatefulAlu *findAttachedSalu(const IR::Declaration_Instance *ext);

     public:
        explicit DefineGlobalRefs(AttachTables &s, P4::ReferenceMap *refMap,
                P4::TypeMap* typeMap) :
            self(s), refMap(refMap), typeMap(typeMap) {}
    };
    bool findSaluDeclarations(const IR::Declaration_Instance *ext,
                              const IR::Declaration_Instance **reg_ptr,
                              const IR::Type_Specialized **regtype_ptr = nullptr,
                              const IR::Type_Extern **seltype_ptr = nullptr);
    profile_t init_apply(const IR::Node *root) override;

    static bool isSaluActionType(const IR::Type *);

 public:
    AttachTables(P4::ReferenceMap *rm, P4::TypeMap* tm, DeclarationConversions &con,
            StatefulSelectors ss)
        : refMap(rm), typeMap(tm), converted(con), stateful_selectors(ss) {
        addPasses({
            new InitializeStatefulAlus(*this),
            new DefineGlobalRefs(*this, refMap, typeMap)
        });
        stop_on_error = false;
    }
};

/// must be applied to IR::BFN::Pipe
class ProcessBackendPipe : public PassManager {
 public:
    ProcessBackendPipe(P4::ReferenceMap *refMap, P4::TypeMap *typeMap,
                       IR::BFN::Pipe* rv, DeclarationConversions &converted,
                       StatefulSelectors ss,
                       ParamBinding *bindings);
};

class BackendConverter {
    P4::ReferenceMap *refMap;
    P4::TypeMap *typeMap;
    IR::ToplevelBlock* toplevel;
    ParseTna *arch;

 public:
    BackendConverter(P4::ReferenceMap *refMap, P4::TypeMap *typeMap, IR::ToplevelBlock* toplevel)
        : refMap(refMap), typeMap(typeMap), toplevel(toplevel) {
        arch = new ParseTna();
        CHECK_NULL(refMap); CHECK_NULL(typeMap); CHECK_NULL(toplevel); }

    void convertTnaProgram(const IR::P4Program *program, BFN_Options &options);
    cstring getPipelineName(const IR::P4Program* program, int index);
    const ProgramThreads &getThreads() const { return arch->threads; }

    std::vector<const IR::BFN::Pipe*> pipe;
};

}  // namespace BFN

#endif /* BF_P4C_COMMON_EXTRACT_MAUPIPE_H_ */
