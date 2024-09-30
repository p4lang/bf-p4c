#ifndef EXTENSIONS_BF_P4C_MAU_MAU_VISITOR_H_
#define EXTENSIONS_BF_P4C_MAU_MAU_VISITOR_H_

#include "ir/ir.h"

/* MAU-specific visitor subclasses that automatically prune off traversal of non-MAU
 * parts of the tree */

class MauInspector : public Inspector {
    /// for traversing backend IR
    bool preorder(const P4::IR::BFN::AbstractParser *) override { return false; }
    bool preorder(const P4::IR::BFN::AbstractDeparser *) override { return false; }
    /// for traversing midend IR
    bool preorder(const P4::IR::P4Parser *) override { return false; }
    bool preorder(const P4::IR::BFN::TnaParser *) override { return false; }
    bool preorder(const P4::IR::BFN::TnaDeparser *) override { return false; }
};

class MauTableInspector : public MauInspector {
    // skip subtrees (of tables) that never contain tables
    bool preorder(const P4::IR::MAU::Action *) override { return false; }
    bool preorder(const P4::IR::Expression *) override { return false; }
};

class MauModifier : public Modifier {
    /// for traversing backend IR
    bool preorder(P4::IR::BFN::AbstractParser *) override { return false; }
    bool preorder(P4::IR::BFN::AbstractDeparser *) override { return false; }
    /// for traversing midend IR
    bool preorder(P4::IR::P4Parser *) override { return false; }
    bool preorder(P4::IR::BFN::TnaParser *) override { return false; }
    bool preorder(P4::IR::BFN::TnaDeparser *) override { return false; }
};

class MauTransform : public Transform {
    /// for traversing backend IR
    P4::IR::Node *preorder(P4::IR::BFN::AbstractParser *p) override { prune(); return p; }
    P4::IR::Node *preorder(P4::IR::BFN::AbstractDeparser *d) override { prune(); return d; }
    /// for traversing midend IR
    P4::IR::Node *preorder(P4::IR::P4Parser *p) override { prune(); return p; }
    P4::IR::Node *preorder(P4::IR::BFN::TnaParser *p) override { prune(); return p; }
    P4::IR::Node *preorder(P4::IR::BFN::TnaDeparser *p) override { prune(); return p; }
};

#endif /* EXTENSIONS_BF_P4C_MAU_MAU_VISITOR_H_ */
