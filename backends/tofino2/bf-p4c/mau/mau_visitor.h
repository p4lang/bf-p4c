#ifndef EXTENSIONS_BF_P4C_MAU_MAU_VISITOR_H_
#define EXTENSIONS_BF_P4C_MAU_MAU_VISITOR_H_

#include "ir/ir.h"

using namespace P4;

/* MAU-specific visitor subclasses that automatically prune off traversal of non-MAU
 * parts of the tree */

class MauInspector : public Inspector {
    /// for traversing backend IR
    bool preorder(const IR::BFN::AbstractParser *) override { return false; }
    bool preorder(const IR::BFN::AbstractDeparser *) override { return false; }
    /// for traversing midend IR
    bool preorder(const IR::P4Parser *) override { return false; }
    bool preorder(const IR::BFN::TnaParser *) override { return false; }
    bool preorder(const IR::BFN::TnaDeparser *) override { return false; }
};

class MauTableInspector : public MauInspector {
    // skip subtrees (of tables) that never contain tables
    bool preorder(const IR::MAU::Action *) override { return false; }
    bool preorder(const IR::Expression *) override { return false; }
};

class MauModifier : public Modifier {
    /// for traversing backend IR
    bool preorder(IR::BFN::AbstractParser *) override { return false; }
    bool preorder(IR::BFN::AbstractDeparser *) override { return false; }
    /// for traversing midend IR
    bool preorder(IR::P4Parser *) override { return false; }
    bool preorder(IR::BFN::TnaParser *) override { return false; }
    bool preorder(IR::BFN::TnaDeparser *) override { return false; }
};

class MauTransform : public Transform {
    /// for traversing backend IR
    IR::Node *preorder(IR::BFN::AbstractParser *p) override { prune(); return p; }
    IR::Node *preorder(IR::BFN::AbstractDeparser *d) override { prune(); return d; }
    /// for traversing midend IR
    IR::Node *preorder(IR::P4Parser *p) override { prune(); return p; }
    IR::Node *preorder(IR::BFN::TnaParser *p) override { prune(); return p; }
    IR::Node *preorder(IR::BFN::TnaDeparser *p) override { prune(); return p; }
};

#endif /* EXTENSIONS_BF_P4C_MAU_MAU_VISITOR_H_ */
