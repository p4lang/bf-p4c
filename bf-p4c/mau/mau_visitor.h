#ifndef _mau_visitor_h_
#define _mau_visitor_h_

#include "ir/ir.h"

/* MAU-specific visitor subclasses that automatically prune off traversal of non-MAU
 * parts of the tree */

class MauInspector : public Inspector {
    /// for traversing backend IR
    bool preorder(const IR::BFN::AbstractParser *) override { return false; }
    bool preorder(const IR::BFN::AbstractDeparser *) override { return false; }
    /// for traversing midend IR
    bool preorder(const IR::P4Parser *) override { return false; }
    bool preorder(const IR::BFN::TranslatedP4Parser *) override { return false; }
    bool preorder(const IR::BFN::TranslatedP4Deparser *) override { return false; }
};

class MauModifier : public Modifier {
    /// for traversing backend IR
    bool preorder(IR::BFN::AbstractParser *) override { return false; }
    bool preorder(IR::BFN::AbstractDeparser *) override { return false; }
    /// for traversing midend IR
    bool preorder(IR::P4Parser *) override { return false; }
    bool preorder(IR::BFN::TranslatedP4Parser *) override { return false; }
    bool preorder(IR::BFN::TranslatedP4Deparser *) override { return false; }
};

class MauTransform : public Transform {
    /// for traversing backend IR
    IR::Node *preorder(IR::BFN::AbstractParser *p) override { prune(); return p; }
    IR::Node *preorder(IR::BFN::AbstractDeparser *d) override { prune(); return d; }
    /// for traversing midend IR
    IR::Node *preorder(IR::P4Parser *p) override { prune(); return p; }
    IR::Node *preorder(IR::BFN::TranslatedP4Parser *p) override { prune(); return p; }
    IR::Node *preorder(IR::BFN::TranslatedP4Deparser *p) override { prune(); return p; }
};

#endif /* _mau_visitor_h_ */
