#ifndef _parde_visitor_h_
#define _parde_visitor_h_

#include "ir/ir.h"

class PardeInspector : public Inspector {
    bool preorder(const IR::MAU::Table *) override { return false; }
    bool preorder(const IR::MAU::TableSeq *) override { return false; }
};

class PardeModifier : public Modifier {
    bool preorder(IR::MAU::Table *) override { return false; }
    bool preorder(IR::MAU::TableSeq *) override { return false; }
};

class PardeTransform : public Transform {
    IR::MAU::Table *preorder(IR::MAU::Table *t) { prune(); return t; }
    IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *s) { prune(); return s; }
};

#endif /* _parde_visitor_h_ */
