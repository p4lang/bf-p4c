#ifndef _parde_visitor_h_
#define _parde_visitor_h_

#include "ir/ir.h"

class PardeInspector : public Inspector {
    bool preorder(const IR::MAU::Table *) { return true; }
    bool preorder(const IR::MAU::TableSeq *) { return true; }
};

class PardeModifier : public Modifier {
    bool preorder(IR::MAU::Table *) { return true; }
    bool preorder(IR::MAU::TableSeq *) { return true; }
};

class PardeTransform : public Transform {
    IR::MAU::Table *preorder(IR::MAU::Table *t) { prune(); return t; }
    IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *s) { prune(); return s; }
};

#endif /* _parde_visitor_h_ */
