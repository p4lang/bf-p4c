#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/hex.h"
#include "lib/ordered_set.h"

using namespace DBPrint;
using namespace IndentCtl;

void IR::MAU::Table::dbprint(std::ostream &out) const {
    out << "table " << name;
    if (logical_id >= 0)
        out << '[' << gress << ' ' << hex(logical_id) << ']';
    if (dbgetflags(out) & Brief)
        return;
    for (auto &gw : gateway_rows) {
        out << endl << "gw: ";
        if (gw.first)
            out << gw.first;
        else
            out << "(miss)";
        out << " => " << (gw.second ? gw.second : "run table"); }
    if (layout.match_width_bits || layout.overhead_bits) {
        out << endl << "{ " << (layout.gateway ? "G" : "")
            << (layout.ternary ? "T" : "E") << " " << layout.match_width_bits << "+"
            << layout.overhead_bits << ", " << layout.action_data_bytes;
        if (!ways.empty()) {
            out << " [" << ways[0].width << 'x' << ways[0].match_groups;
            for (auto &way : ways) out << " " << (way.entries/1024U) << "K";
            out << "]"; }
        out << " }"; }
    if (!(dbgetflags(out) & TableNoActions)) {
        for (auto &a : Values(actions))
            out << endl << a;
        if (match_table && match_table->getDefaultAction())
            out << endl << "default_action " << match_table->getDefaultAction(); }
    std::set<const IR::MAU::TableSeq *> done;
    for (auto it = next.begin(); it != next.end(); ++it) {
        if (done.count(it->second)) continue;
        out << endl << it->first;
        for (auto it2 = std::next(it); it2 != next.end(); ++it2)
            if (it->second == it2->second)
                out << ", " << it2->first;
        out << ": " << indent << it->second << unindent;
        done.insert(it->second); }
    if (!attached.empty())
        out << endl;
    const char *sep = ": ";
    for (auto &a : attached) {
        out << sep << a->kind() << ' ' << a->name;
        sep = ", "; }
}

void IR::MAU::TableSeq::dbprint(std::ostream &out) const {
    out << "seq" << tables.size() << ":";
    for (unsigned i = 1; i < tables.size(); i++) {
        out << ' ';
        for (unsigned j = 0; j < i; j++) out << (deps(i, j) ? '1' : '0'); }
    for (auto &t : tables)
        out << endl << indent << t << unindent;
}

void IR::MAU::ActionFunctionEx::dbprint(std::ostream &out) const {
    ActionFunction::dbprint(out);
    if (!stateful.empty()) {
        out << " + {" << indent;
        for (auto &p : action)
            out << endl << p;
        out << unindent << " }";
    }
}

void IR::RangeMatch::dbprint(std::ostream &out) const {
    int prec = getprec(out);
    out << setprec(Prec_Equ) << expr << " in 0x" << hex(data) << setprec(prec);
    if (prec == 0) out << ';';
}

void IR::Tofino::ParserMatch::dbprint(std::ostream &out) const {
    (value ? out << "match " << value : out << "default") << ":  (shift=" << shift << ')' << indent;
    for (auto st : stmts)
        out << endl << *st;
    if (next)
        out << endl << "goto " << next->name;
    if (except)
        out << endl << "exception";
    out << unindent;
}

void IR::Tofino::ParserState::dbprint(std::ostream &out) const {
    out << gress << " parser " << name;
    if (dbgetflags(out) & Brief)
        return;
    out << ':' << indent;
    if (!select.empty()) {
        out << endl << "select(" << setprec(Prec_Low);
        const char *sep = "";
        for (auto &e : select) {
            out << sep << *e;
            sep = ", "; }
        out << ")" << setprec(0); }
    for (auto *m : match)
        out << endl << *m;
    out << unindent;
}

struct FindStates : Inspector {
    ordered_set<const IR::Tofino::ParserState *>        states;
    bool preorder(const IR::Tofino::ParserState *s) override { states.insert(s); return true; }
};


void IR::Tofino::Parser::dbprint(std::ostream &out) const {
    FindStates states;
    apply(states);
    for (auto st : states.states)
        out << endl << *st;
}

void IR::Tofino::Digest::dbprint(std::ostream &out) const {
    for (auto s : sets)
        out << endl << name << ": " << *s;
}

void IR::Tofino::Deparser::dbprint(std::ostream &out) const {
    out << gress << " deparser";
    if (dbgetflags(out) & Brief)
        return;
    out << ':' << indent;
    for (auto st : emits)
        out << endl << *st;
    if (egress_port)
        out << endl << "egress_port: " << *egress_port;
    for (auto digest : Values(digests))
        out << *digest;
    out << unindent;
}

void IR::Tofino::Pipe::dbprint(std::ostream &out) const {
    out << "ingress:" << indent << thread[0].parser << endl << thread[0].mau << endl
                                << thread[0].deparser << unindent << endl
        << "egress:" << indent << thread[1].parser << endl << thread[1].mau << endl
                               << thread[1].deparser << unindent;
}
