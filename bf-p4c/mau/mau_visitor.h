#ifndef _mau_visitor_h_
#define _mau_visitor_h_

#include "ir/ir.h"

/* MAU-specific visitor subclasses that automatically prune off traversal of non-MAU
 * parts of the tree */

class MauInspector : public Inspector {
    bool preorder(const IR::BFN::Parser *) override { return false; }
    bool preorder(const IR::BFN::Deparser *) override { return false; }
};

class MauModifier : public Modifier {
    bool preorder(IR::BFN::Parser *) override { return false; }
    bool preorder(IR::BFN::Deparser *) override { return false; }
};

class MauTransform : public Transform {
    IR::BFN::Parser *preorder(IR::BFN::Parser *p) override { prune(); return p; }
    IR::BFN::Deparser *preorder(IR::BFN::Deparser *d) override { prune(); return d; }
};

#endif /* _mau_visitor_h_ */
