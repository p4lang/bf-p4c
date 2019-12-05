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
        out << TableNoActions;
        for (auto &a : Values(actions))
            out << endl << a;
        if (match_table && match_table->getDefaultAction())
            out << endl << "default_action " << match_table->getDefaultAction();
        out << clrflag(TableNoActions); }
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
        auto a_mem = a->attached;
        out << sep << a_mem->kind() << ' ' << a_mem->name;
        sep = ", "; }
    if (!(dbgetflags(out) & TableNoActions))
        for (auto &a : attached)
            if (auto salu = a->attached->to<StatefulAlu>())
                out << endl << *salu;
    if (entries_list) {
        out << endl << "static_entries " << endl;
        for (auto e : entries_list->entries) {
            out << e << endl;
        }
    }
}

void IR::MAU::BackendAttached::dbprint(std::ostream &out) const {
    out << *attached;
    if (hash_dist) out << " hd=" << *hash_dist;
    switch (use) {
    case StatefulUse::LOG: out << " {log}"; break;
    case StatefulUse::FIFO_PUSH: out << " {enq}"; break;
    case StatefulUse::FIFO_POP: out << " {deq}"; break;
    case StatefulUse::STACK_PUSH: out << " {push}"; break;
    case StatefulUse::STACK_POP: out << " {pop}"; break;
    default: break; }
}

void IR::MAU::StatefulAlu::dbprint(std::ostream &out) const {
    out << "stateful " << name << " ";
    if (dual)
        out << width/2 << "x2";
    else
        out << width;
    if (!(dbgetflags(out) & TableNoActions)) {
        out << indent;
        for (auto salu : Values(instruction))
            out << endl << salu;
        out << unindent; }
}

void IR::MAU::TableSeq::dbprint(std::ostream &out) const {
    out << "seq" << tables.size() << "[" << id << "]:";
    for (unsigned i = 1; i < tables.size(); i++) {
        out << ' ';
        for (unsigned j = 0; j < i; j++) out << (deps(i, j) ? '1' : '0'); }
    out << indent;
    for (auto &t : tables)
        out << endl << t;
    out << unindent;
}

void IR::MAU::Action::dbprint(std::ostream &out) const {
    out << "action " << name << "(";
    const char *sep = "";
    for (auto &arg : args) {
        out << sep << *arg->type << ' ' << arg->name;
        sep = ", "; }
    out << ")";
    if (miss_action_only) out << " @miss_only";
    if (init_default) out << " @default";
    if (!default_allowed) out << " @table_only";
    if (is_constant_action) out << " @const";
    out << " {" << indent;
    for (auto &p : action)
        out << endl << p;
    out << unindent << " }";
    if (!stateful_calls.empty()) {
        out << " + {" << indent;
        for (auto &call : stateful_calls)
            out << endl << call;
        out << unindent << " }"; }
}

void IR::MAU::StatefulCall::dbprint(std::ostream &out) const {
    if (prim) out << prim << " ";
    out << attached_callee->kind() << " " << attached_callee->name;
    if (index)
        out << "(" << index << ")";
}

void IR::MAU::SaluAction::dbprint(std::ostream &out) const {
    out << "action " << name << "(";
    const char *sep = "";
    for (auto &arg : args) {
        out << sep << *arg->type << ' ' << arg->name;
        sep = ", "; }
    out << ") {" << indent;
    for (auto &p : action)
        out << endl << p;
    out << unindent << " }";
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

    out << "(shift=" << shift << ')';

    for (const auto& save : saves) {
        out << endl << save; }

    out << endl << "goto " << (next ? next->name : "(end)");
}

void IR::BFN::Select::dbprint(std::ostream &out) const {
    out << "select " << p4Source << " from " << source;
}

void IR::BFN::LoweredParserMatch::dbprint(std::ostream &out) const {
    if (value)
        out << "match " << value << ": ";
    else
        out << "default: ";

    out << "(shift=" << shift << ')';

    out << indent;
    for (auto *st : extracts)
        out << endl << *st;
    for (auto *save : saves)
        out << endl << *save;
    for (auto *chk : checksums)
        out << endl << *chk;
    for (auto *ctr : counters)
        out << endl << *ctr;

    out << unindent;

    out << endl << "goto ";
    if (next)
        out << next->name;
    else if (loop)
        out << loop;
    else
        out << "(end)";
}

void IR::BFN::ParserState::dbprint(std::ostream &out) const {
    out << gress << " parser state " << name;
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

void IR::BFN::LoweredSelect::dbprint(std::ostream &out) const {
    out << "select";
    const char* sep = " ";
    for (const auto& r : regs) {
        out << sep << r.name;
        sep = ", "; }
}

void IR::BFN::LoweredParserState::dbprint(std::ostream &out) const {
    out << gress << " parser state " << name;
    if (dbgetflags(out) & Brief)
        return;
    out << ':' << indent;

    out << endl << "select(" << setprec(Prec_Low);
    out << *select;
    out << ")" << setprec(0);

    for (auto *m : transitions)
        out << endl << *m;
    out << unindent;
}

void IR::BFN::Parser::dbprint(std::ostream &out) const {
    out << gress << " parser " << indent;
    forAllMatching<IR::BFN::ParserState>(this,
                  [&](const IR::BFN::ParserState* state) {
        out << endl << *state;
    });
    out << unindent;
}

void IR::BFN::LoweredParser::dbprint(std::ostream &out) const {
    out << "lowered " << gress << " parser " << indent;
    forAllMatching<IR::BFN::LoweredParserState>(this,
                  [&](const IR::BFN::LoweredParserState* state) {
        out << endl << *state;
    });
    out << unindent;
}

void IR::BFN::DigestFieldList::dbprint(std::ostream &out) const {
    out << idx << " :" << indent;
    out << "[ ";

    const char* sep = "";
    for (auto* source : sources) {
        out << sep << source->field->toString();
        sep = ", ";
    }

    out << " ]";
    out << unindent;
}

void IR::BFN::Digest::dbprint(std::ostream &out) const {
    out << endl << name << ": " << indent << endl
                << "select: " << *selector->field;
    for (auto fieldList : fieldLists) {
        out << endl << name << ' ' << fieldList;
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
        out << endl << *param;
    for (auto digest : Values(digests))
        out << endl << *digest;
    out << unindent;
}

void IR::BFN::DigestTableEntry::dbprint(std::ostream &out) const {
    out << "[ ";

    const char* sep = "";
    for (auto* source : sources) {
        out << sep << *source;
        sep = ", ";
    }

    out << " ]";
}

void IR::BFN::LearningTableEntry::dbprint(std::ostream &out) const {
    IR::BFN::DigestTableEntry::dbprint(out);
}

void IR::BFN::LoweredDigest::dbprint(std::ostream &out) const {
    out << endl << name << ": " << indent << endl
                << "select: " << *selector;
    int idx = 0;
    for (auto* entry : entries) {
        out << endl << name << ' ' << idx++ << ": "
            << indent << *entry << unindent;
    }
    out << unindent;
}

void IR::BFN::ChecksumPhvInput::dbprint(std::ostream &out) const {
    out << source;
    if (povBit) out << " if " << povBit;
}

void IR::BFN::ChecksumClotInput::dbprint(std::ostream &out) const {
    out << clot;
    if (povBit) out << " if " << povBit;
}

void IR::BFN::ChecksumUnitConfig::dbprint(std::ostream &out) const {
    out << "checksum unit " << unit << " {";

    for (auto* phv : phvs)
        out << endl << indent << *phv << unindent;

    for (auto* clot : clots)
        out << endl << indent << clot << unindent;

    out << " }";
}

void IR::BFN::LoweredEmitClot::dbprint(std::ostream &out) const {
    out << "emit clot " << clot->clot;
}

void IR::BFN::LoweredDeparser::dbprint(std::ostream &out) const {
    out << gress << " deparser";
    if (dbgetflags(out) & Brief)
        return;
    out << ':' << indent;
    for (auto* emit : emits)
        out << endl << *emit;
    for (auto* param : params)
        out << endl << *param;
    for (auto digest : digests)
        out << endl << *digest;
    for (auto* checksumFieldList : checksums)
        out << *checksumFieldList;
    out << unindent;
}

void IR::BFN::Pipe::dbprint(std::ostream &out) const {
    if (ghost_thread) out << "ghost:" << indent << ghost_thread << unindent << endl;
    out << "ingress:" << indent << endl;
    for (auto p : thread[0].parsers)
        out << p << endl;
    out << thread[0].mau << endl
        << thread[0].deparser << unindent << endl;
    out << "egress:" << indent << endl;
    for (auto p : thread[1].parsers)
        out << p << endl;
    out << thread[1].mau << endl
        << thread[1].deparser << unindent;
}

// reinterpret_cast is still printed as cast, due to lack of P4 syntax.
void IR::BFN::ReinterpretCast::dbprint(std::ostream &out) const {
    int prec = getprec(out);
    if (prec > Prec_Prefix) out << '(';
    out << setprec(Prec_Prefix) << "(" << type << ")" << setprec(Prec_Prefix)
        << expr << setprec(prec);
    if (prec > Prec_Prefix) out << ')';
    if (prec == 0) out << ';';
}

// sign_extend is still printed as cast, due to lack to P4 syntax.
void IR::BFN::SignExtend::dbprint(std::ostream &out) const {
    int prec = getprec(out);
    if (prec > Prec_Prefix) out << '(';
    out << setprec(Prec_Prefix) << "(" << type << ")" << setprec(Prec_Prefix)
        << expr << setprec(prec);
    if (prec > Prec_Prefix) out << ')';
    if (prec == 0) out << ';';
}
