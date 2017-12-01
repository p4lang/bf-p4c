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
    if (!(dbgetflags(out) & TableNoActions))
        for (auto &a : attached)
            if (auto salu = a->to<StatefulAlu>())
                out << endl << *salu;
}

void IR::MAU::StatefulAlu::dbprint(std::ostream &out) const {
    out << "stateful " << name << " ";
    if (dual)
        out << width/2 << "x2";
    else
        out << width;
    out << indent;
    for (auto salu : Values(instruction))
        out << endl << salu;
    out << unindent;
}

void IR::MAU::TableSeq::dbprint(std::ostream &out) const {
    out << "seq" << tables.size() << ":";
    for (unsigned i = 1; i < tables.size(); i++) {
        out << ' ';
        for (unsigned j = 0; j < i; j++) out << (deps(i, j) ? '1' : '0'); }
    for (auto &t : tables)
        out << endl << indent << t << unindent;
}

void IR::MAU::Action::dbprint(std::ostream &out) const {
    ActionFunction::dbprint(out);
    if (!stateful.empty()) {
        out << " + {" << indent;
        for (auto &p : stateful)
            out << endl << p;
        out << unindent << " }"; }
}

void IR::MAU::SaluAction::dbprint(std::ostream &out) const {
    ActionFunction::dbprint(out);
}

void IR::RangeMatch::dbprint(std::ostream &out) const {
    int prec = getprec(out);
    out << setprec(Prec_Equ) << expr << " in 0x" << hex(data) << setprec(prec);
    if (prec == 0) out << ';';
}

void IR::BFN::Transition::dbprint(std::ostream &out) const {
    if (value)
        out << "match " << value << ": ";
    else
        out << "default: ";

    if (shift)
        out << "(shift=" << *shift << ')';
    else
        out << "(shift unknown)";

    out << endl << "goto " << (next ? next->name : "(end)");
}

void IR::BFN::LoweredParserMatch::dbprint(std::ostream &out) const {
    if (value)
        out << "match " << value << ": ";
    else
        out << "default: ";

    out << "(shift=" << shift << ')';

    out << indent;
    for (auto *st : statements)
        out << endl << *st;
    out << unindent;

    out << endl << "goto " << (next ? next->name : "(end)");
}

void IR::BFN::ParserState::dbprint(std::ostream &out) const {
    out << gress << " parser " << name;
    if (dbgetflags(out) & Brief)
        return;
    out << ':' << indent;

    for (auto *statement : statements)
        out << endl << *statement;

    if (!selects.empty()) {
        out << endl << "select(" << setprec(Prec_Low);
        const char *sep = "";
        for (auto &e : selects) {
            out << sep << *e;
            sep = ", "; }
        out << ")" << setprec(0); }

    for (auto *transition : transitions)
        out << endl << *transition;

    out << unindent;
}

void IR::BFN::LoweredParserState::dbprint(std::ostream &out) const {
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

void IR::BFN::Parser::dbprint(std::ostream &out) const {
    forAllMatching<IR::BFN::ParserState>(this,
                  [&](const IR::BFN::ParserState* state) {
        out << endl << *state;
    });
}

void IR::BFN::LoweredParser::dbprint(std::ostream &out) const {
    forAllMatching<IR::BFN::LoweredParserState>(this,
                  [&](const IR::BFN::LoweredParserState* state) {
        out << endl << *state;
    });
}

void IR::BFN::DigestFieldList::dbprint(std::ostream &out) const {
    out << "[ ";

    const char* sep = "";
    for (auto* source : sources) {
        out << sep << source->field->toString();
        sep = ", ";
    }

    out << " ]";
}

void IR::BFN::Digest::dbprint(std::ostream &out) const {
    out << endl << name << ": " << indent << endl
                << "select: " << *selector->field;
    int idx = 0;
    for (auto* fieldList : fieldLists) {
        out << endl << name << ' ' << idx++ << ": "
            << indent << *fieldList << unindent;
    }
    out << unindent;
}

void IR::BFN::EmitChecksum::dbprint(std::ostream &out) const {
    out << "emit checksum { ";

    const char* sep = "";
    for (auto* source : sources) {
        out << sep << source->field->toString();
        sep = ", ";
    }

    out << " } if " << povBit->field->toString();
}

void IR::BFN::Deparser::dbprint(std::ostream &out) const {
    out << gress << " deparser";
    if (dbgetflags(out) & Brief)
        return;
    out << ':' << indent;
    for (auto* emit : emits)
        out << endl << *emit;
    for (auto* param : params)
        out << *param;
    for (auto digest : Values(digests))
        out << *digest;
    out << unindent;
}

void IR::BFN::Pipe::dbprint(std::ostream &out) const {
    out << "ingress:" << indent << thread[0].parser << endl << thread[0].mau << endl
                                << thread[0].deparser << unindent << endl
        << "egress:" << indent << thread[1].parser << endl << thread[1].mau << endl
                               << thread[1].deparser << unindent;
}
