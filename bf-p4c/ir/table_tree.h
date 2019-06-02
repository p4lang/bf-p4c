#ifndef BF_P4C_IR_TABLE_TREE_H_
#define BF_P4C_IR_TABLE_TREE_H_

#include "ir/ir.h"
#include "lib/hex.h"
#include "lib/indent.h"
#include "lib/ordered_map.h"
#include "lib/safe_vector.h"

class TableTree {
    mutable indent_t indent;
    mutable std::set<const IR::MAU::TableSeq *> done;
    safe_vector<cstring> name;
    const IR::MAU::TableSeq *seq;

    void print(std::ostream &out,
               const safe_vector<cstring> &tag,
               const IR::MAU::TableSeq *s) const {
        const char *sep = "";
        out << indent++;
        for (auto n : tag) {
            out << sep << n;
            sep = ", "; }
        out << ": [" << s->id << "]";
        if (done.count(s)) {
            out << "..." << std::endl;
        } else {
            for (unsigned i = 1; i < s->tables.size(); ++i) {
                out << ' ';
                for (unsigned j = 0; j < i; ++j) out << (s->deps(i, j) ? '1' : '0'); }
            out << std::endl;
            done.insert(s);
            for (auto tbl : s->tables) print(out, tbl); }
        --indent; }
    void print(std::ostream &out, const IR::MAU::Table *tbl) const {
        ordered_map<const IR::MAU::TableSeq *, safe_vector<cstring>> next;
        out << indent++;
        if (tbl->logical_id >= 0) out << hex(tbl->logical_id) << ": ";
        out << tbl->name;
        const char *sep = "(";
        for (auto &row : tbl->gateway_rows) {
            out << sep;
            if (row.first)
                out << *row.first;
            else
                out << "1";
            if (row.second) out << " => " << row.second;
            sep = ", "; }
        out << (*sep == ',' ? ")" : "");
        if (tbl->layout.match_width_bits || tbl->layout.overhead_bits) {
            out << "{ " << (tbl->layout.gateway ? "G" : "")
                << (tbl->layout.ternary ? "T" : "E") << " " << tbl->layout.match_width_bits << "+"
                << tbl->layout.overhead_bits << ", " << tbl->layout.action_data_bytes;
            if (!tbl->ways.empty()) {
                out << " [" << tbl->ways[0].width << 'x' << tbl->ways[0].match_groups;
                for (auto &way : tbl->ways) out << " " << (way.entries/1024U) << "K";
                out << "]";
            } else {
                out << " " << (tbl->layout.entries / 1024U) << "K"; }
            out << " }"; }
        auto stage = tbl->get_provided_stage();
        if (stage >= 0) out << " @stage(" << stage << ")";
        out << std::endl;
        for (auto &at : tbl->attached) {
            if (at->attached->direct) continue;
            out << indent << at->attached->kind() << " " << at->attached->name
                << " " << (at->attached->size/1024U) << "K" << std::endl; }
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

#endif /* BF_P4C_IR_TABLE_TREE_H_ */
