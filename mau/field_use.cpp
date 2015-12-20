#include "ir/ir.h"
#include "field_use.h"

bool FieldUse::preorder(const IR::MAU::Table *t) {
    table_use[t->name];
    return true;
}

void FieldUse::access_field(cstring name) {
    int idx;
    if (!field_index.count(name)) {
        idx = field_index[name] = field_names.size();
        field_names.push_back(name);
    } else
        idx = field_index[name];
    if (auto table = findContext<IR::MAU::Table>()) {
        if (isWrite())
            table_use[table->name].writes[idx] = 1;
        else
            table_use[table->name].reads[idx] = 1;
    } else
        assert(0);
}

bool FieldUse::preorder(const IR::FieldRef *f) {
    access_field(f->toString());
    return false;
}

bool FieldUse::preorder(const IR::HeaderStackItemRef *f) {
    access_field(f->toString());
    return false;
}

bitvec FieldUse::tables_modify(const IR::MAU::Table *t) const {
    bitvec rv;
    rv |= table_use.at(t->name).writes;
    for (auto &n : t->next)
        if (n.second)
            rv |= tables_modify(n.second);
    return rv;
}

bitvec FieldUse::tables_access(const IR::MAU::Table *t) const {
    bitvec rv;
    rv |= table_use.at(t->name).reads;
    rv |= table_use.at(t->name).writes;
    for (auto &n : t->next)
        if (n.second)
            rv |= tables_access(n.second);
    return rv;
}


bitvec FieldUse::tables_modify(const IR::MAU::TableSeq *g) const {
    bitvec rv;
    for (auto t : g->tables)
        rv |= tables_modify(t);
    return rv;
}

bitvec FieldUse::tables_access(const IR::MAU::TableSeq *g) const {
    bitvec rv;
    for (auto t : g->tables)
        rv |= tables_access(t);
    return rv;
}

std::ostream &operator<<(std::ostream &out, const FieldUse &f) {
    for (auto &t : f.table_use) {
        out << std::setw(20) << t.first << " R:";
        for (auto i : t.second.reads) out << ' ' << f.field_names[i];
        out << std::endl;
        out << std::setw(20) << " " << " W:";
        for (auto i : t.second.writes) out << ' ' << f.field_names[i];
        out << std::endl; }
    return out;
}
