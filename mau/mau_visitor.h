#ifndef _mau_visitor_h_
#define _mau_visitor_h_

#include "tofino/ir/tofino.h"

/* MAU-specific visitor subclasses that automatically prune off traversal of non-MAU
 * parts of the tree */

class MauInspector : public Inspector {
    bool preorder(const IR::Tofino::Parser *) override { return false; }
    bool preorder(const IR::Tofino::Deparser *) override { return false; }
};

class MauModifier : public Modifier {
    bool preorder(IR::Tofino::Parser *) override { return false; }
    bool preorder(IR::Tofino::Deparser *) override { return false; }
};

class MauTransform : public Transform {
    IR::Tofino::Parser *preorder(IR::Tofino::Parser *p) override { prune(); return p; }
    IR::Tofino::Deparser *preorder(IR::Tofino::Deparser *d) override { prune(); return d; }
};

#endif /* _mau_visitor_h_ */
