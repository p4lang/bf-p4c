#ifndef INITIALIZE_MIRROR_IO_SELECT_H_
#define INITIALIZE_MIRROR_IO_SELECT_H_

#include "ir/ir.h"
#include "bf-p4c/device.h"
#include "type_checker.h"

namespace BFN {

// Initialize eg_intr_md_for_dprsr.mirror_io_select
class DoInitializeMirrorIOSelect: public Transform {
    cstring egIntrMdForDprsrName;

 public:
    DoInitializeMirrorIOSelect() {};

    // Add mirror_io_select initialization to egress parser
    const IR::Node* preorder(IR::BFN::TnaParser* parser) override;
    const IR::Node* preorder(IR::ParserState* state) override;

    // Skip controls and deparsers
    const IR::Node* preorder(IR::BFN::TnaControl* control) override { prune(); return control; };
    const IR::Node* preorder(IR::BFN::TnaDeparser* deparser) override { prune(); return deparser; };
};

// Initialize eg_intr_md_for_dprsr.mirror_io_select on devices except Tofino1
class InitializeMirrorIOSelect : public PassManager {
 public:
    InitializeMirrorIOSelect(P4::ReferenceMap* refMap, P4::TypeMap* typeMap) {
        addPasses({
            new PassIf([]() { return Device::hasMirrorIOSelect(); }, {
                new DoInitializeMirrorIOSelect(),
                new P4::ClearTypeMap(typeMap),
                new P4::ResolveReferences(refMap),
                new BFN::TypeInference(refMap, typeMap, false), /* extended P4::TypeInference */
                new P4::ApplyTypesToExpressions(typeMap),
                new P4::ResolveReferences(refMap) })
        });
        setName("InitializeMirrorIOSelect");
    }
};

}  // namespace BFN

#endif  // INITIALIZE_MIRROR_IO_SELECT_H_
