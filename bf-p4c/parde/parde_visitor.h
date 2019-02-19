#ifndef EXTENSIONS_BF_P4C_PARDE_PARDE_VISITOR_H_
#define EXTENSIONS_BF_P4C_PARDE_PARDE_VISITOR_H_

#include "ir/ir.h"

class PardeInspector : public Inspector {
    bool preorder(const IR::MAU::Table *) override { return false; }
    bool preorder(const IR::MAU::TableSeq *) override { return false; }
    /// for traversing midend IR
    bool preorder(const IR::BFN::TnaControl *) override { return false; }
};

class PardeModifier : public Modifier {
    bool preorder(IR::MAU::Table *) override { return false; }
    bool preorder(IR::MAU::TableSeq *) override { return false; }
    /// for traversing midend IR
    bool preorder(IR::BFN::TnaControl *) override { return false; }
};

class PardeTransform : public Transform {
    IR::MAU::Table *preorder(IR::MAU::Table *t) override { prune(); return t; }
    IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *s) override { prune(); return s; }
    /// for traversing midend IR
    IR::Node *preorder(IR::BFN::TnaControl *c) override { prune(); return c; }
};

class ParserInspector : public Inspector {
    bool preorder(const IR::BFN::Deparser *) override { return false; }
    bool preorder(const IR::MAU::Table *) override { return false; }
    bool preorder(const IR::MAU::TableSeq *) override { return false; }
    /// for traversing midend IR
    bool preorder(const IR::BFN::TnaDeparser *) override { return false; }
    bool preorder(const IR::BFN::TnaControl *) override { return false; }
};

class ParserModifier : public Modifier {
    bool preorder(IR::BFN::Deparser *) override { return false; }
    bool preorder(IR::MAU::Table *) override { return false; }
    bool preorder(IR::MAU::TableSeq *) override { return false; }
    /// for traversing midend IR
    bool preorder(IR::BFN::TnaDeparser *) override { return false; }
    bool preorder(IR::BFN::TnaControl *) override { return false; }
};

class ParserTransform : public Transform {
    IR::BFN::Deparser *preorder(IR::BFN::Deparser *d) override { prune(); return d; }
    IR::MAU::Table *preorder(IR::MAU::Table *t) override { prune(); return t; }
    IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *s) override { prune(); return s; }
    /// for traversing midend IR
    IR::Node *preorder(IR::BFN::TnaDeparser *d) override { prune(); return d; }
    IR::Node *preorder(IR::BFN::TnaControl *c) override { prune(); return c; }
};

class DeparserInspector : public Inspector {
    bool preorder(const IR::BFN::AbstractParser *) override { return false; }
    bool preorder(const IR::MAU::Table *) override { return false; }
    bool preorder(const IR::MAU::TableSeq *) override { return false; }
    /// for traversing midend IR
    bool preorder(const IR::BFN::TnaParser *) override { return false; }
    bool preorder(const IR::BFN::TnaControl *) override { return false; }
};

class DeparserModifier : public Modifier {
    bool preorder(IR::BFN::AbstractParser *) override { return false; }
    bool preorder(IR::MAU::Table *) override { return false; }
    bool preorder(IR::MAU::TableSeq *) override { return false; }
    /// for traversing midend IR
    bool preorder(IR::BFN::TnaParser *) override { return false; }
    bool preorder(IR::BFN::TnaControl *) override { return false; }
};

class DeparserTransform : public Transform {
    IR::BFN::AbstractParser *preorder(IR::BFN::AbstractParser *p) override { prune(); return p; }
    IR::MAU::Table *preorder(IR::MAU::Table *t) override { prune(); return t; }
    IR::MAU::TableSeq *preorder(IR::MAU::TableSeq *s) override { prune(); return s; }
    /// for traversing midend IR
    IR::Node *preorder(IR::BFN::TnaParser * p) override { prune(); return p; }
    IR::Node *preorder(IR::BFN::TnaControl * c) override { prune(); return c; }
};

#endif /* EXTENSIONS_BF_P4C_PARDE_PARDE_VISITOR_H_ */
