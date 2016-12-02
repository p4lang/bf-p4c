#ifndef TOFINO_IR_TABLE_TREE_H_
#define TOFINO_IR_TABLE_TREE_H_

#include "ir/ir.h"
#include "lib/indent.h"
#include "lib/ordered_map.h"

class TableTree {
    mutable indent_t indent;
    mutable std::set<const IR::MAU::TableSeq *> done;
    vector<cstring> name;
    const IR::MAU::TableSeq *seq;

    void print(std::ostream &out, const vector<cstring> &tag, const IR::MAU::TableSeq *s) const {
        const char *sep = "";
        out << indent++;
        for (auto n : tag) {
            out << sep << n;
            sep = ", "; }
        out << ": [" << s->id << "]";
        if (done.count(s)) {
            out << "..." << std::endl;
        } else {
            out << std::endl;
            done.insert(s);
            for (auto tbl : s->tables) print(out, tbl); }
        --indent; }
    void print(std::ostream &out, const IR::MAU::Table *tbl) const {
        ordered_map<const IR::MAU::TableSeq *, vector<cstring>> next;
        out << indent++ << tbl->name;
        const char *sep = "(";
        for (auto &row : tbl->gateway_rows) {
            out << sep;
            if (row.first) out << *row.first;
            else out << "1";
            if (row.second) out << " => " << row.second;
            sep = ", "; }
        out << (*sep == ',' ? ")" : "") << std::endl;
        for (auto &n : tbl->next)
            next[n.second].push_back(n.first);
        for (auto &n : next)
            print(out, n.second, n.first);
        --indent; }

 public:
    TableTree(cstring name, const IR::MAU::TableSeq *seq) : name{name}, seq(seq) {}
    friend std::ostream &operator<<(std::ostream &out, const TableTree &tt) {
        tt.indent = indent_t();
        tt.done.clear();
        if (tt.seq) tt.print(out, tt.name, tt.seq);
        return out; }
};

#endif /* TOFINO_IR_TABLE_TREE_H_ */
