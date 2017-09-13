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

class ParserInspector : public Inspector {
    bool preorder(const IR::BFN::Deparser *) override { return false; }
    bool preorder(const IR::MAU::Table *) override { return false; }
    bool preorder(const IR::MAU::TableSeq *) override { return false; }
};

class ParserModifier : public Modifier {
    bool preorder(IR::BFN::Deparser *) override { return false; }
    bool preorder(IR::MAU::Table *) override { return false; }
    bool preorder(IR::MAU::TableSeq *) override { return false; }
};

class ParserTransform : public Transform {
    IR::BFN::Deparser *preorder(IR::BFN::Deparser *d) { prune(); return d; }
    IR::MAU::Table *preorder(IR::MAU::Table *t) { prune(); return t; }
    IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *s) { prune(); return s; }
};

#endif /* _parde_visitor_h_ */
