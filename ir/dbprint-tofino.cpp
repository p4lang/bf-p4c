#include "ir/ir.h"
#include "ir/dbprint.h"
#include "lib/hex.h"

using namespace DBPrint;

void IR::MAU::Table::dbprint(std::ostream &out) const {
    out << "table " << name;
    if (gateway_expr) {
        int prec = getprec(out);
        out << " " << (gateway_cond ? "" : "!") << "(" << setprec(Prec_Low) << indent
            << gateway_expr << unindent << setprec(prec) << ")"; }
    if (logical_id >= 0)
        out << '[' << gress << ' ' << hex(logical_id) << ']';
    if (layout.match_width_bits || layout.overhead_bits)
        out << endl << "{ " << (layout.gateway ? "G" : "")
            << (layout.ternary ? "T" : "E") << " " << layout.match_width_bits << "+"
            << layout.overhead_bits << ", " << layout.action_data_bytes << " }";
    if (!(dbgetflags(out) & TableNoActions))
        for (auto &a : actions)
            out << endl << a;
    for (auto &n : next)
        out << endl << n.first << ": " << indent << n.second << unindent;
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

void IR::Tofino::Parser::dbprint(std::ostream &out) const {
    out << "IR::Tofino::Parser";
}

void IR::Tofino::Deparser::dbprint(std::ostream &out) const {
    out << "IR::Tofino::Deparser";
}

void IR::Tofino::Pipe::dbprint(std::ostream &out) const {
    out << "ingress:" << indent << thread[0].parser << endl << thread[0].mau << endl
                                << thread[0].deparser << unindent << endl
        << "egress:" << indent << thread[1].parser << endl << thread[1].mau << endl
                               << thread[1].deparser << unindent;
}
