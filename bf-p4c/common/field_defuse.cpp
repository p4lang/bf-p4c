#include "field_defuse.h"
#include "lib/hex.h"
#include "lib/log.h"
#include "lib/map.h"
#include "lib/range.h"

static std::ostream &operator<<(std::ostream &out, const FieldDefUse::locpair &loc) {
    return out << *loc.second << " in " << *loc.first;
}

class FieldDefUse::ClearBeforeEgress : public Inspector, TofinoWriteContext {
    FieldDefUse &self;
    bool preorder(const IR::Expression *e) override {
        auto *f = self.phv.field(e);
        if (f && isWrite()) {
            LOG4("CLEARING FIELD: " << e);
            self.defuse.erase(f->id);
            return false; }
        if (e->is<IR::Member>())
            return false;
        return true; }
    bool preorder(const IR::HeaderRef *hr) override {
        for (int id : self.phv.struct_info(hr).field_ids()) {
            if (isWrite()) {
                self.defuse.erase(id);
                LOG4("CLEARING HEADER REF: " << hr); } }
        return false; }
 public:
    explicit ClearBeforeEgress(FieldDefUse &self) : self(self) {}
};

class FieldDefUse::CollectAliasDestinations : public Inspector {
    FieldDefUse& self;
    bool preorder(const IR::BFN::AliasMember *e) override {
        const auto* f = self.phv.field(e);
        if (!f) return false;
        self.alias_destinations.insert(f);
        return false;
    }
    bool preorder(const IR::BFN::AliasSlice* sl) override {
        const auto* f = self.phv.field(sl);
        if (!f) return false;
        self.alias_destinations.insert(f);
        return false;
    }
 public:
    explicit CollectAliasDestinations(FieldDefUse &s) : self(s) {}
};

Visitor::profile_t FieldDefUse::init_apply(const IR::Node *root) {
    auto rv = Inspector::init_apply(root);
    conflict.clear();
    defs.clear();
    uses.clear();
    defuse.clear();
    located_uses.clear();
    located_defs.clear();
    output_deps.clear();
    parser_zero_inits.clear();
    alias_destinations.clear();
    uninitialized_fields.clear();
    non_dark_refs.clear();
    return rv;
}

void FieldDefUse::check_conflicts(const info &read, int when) {
    int firstdef = INT_MAX;
    for (auto def : read.def)
        firstdef = std::min(firstdef, def.first->stage());
    for (auto &other : Values(defuse)) {
        if (other.field == read.field) continue;
        for (auto use : other.use) {
            int use_when = use.first->stage();
            if (use_when >= firstdef && use_when <= when)
                conflict(read.field->id, other.field->id) = true; } }
}

FieldDefUse::info &FieldDefUse::field(const PHV::Field *f) {
    auto &info = defuse[f->id];
    assert(!info.field || info.field == f);
    info.field = f;
    return info;
}

void FieldDefUse::read(const PHV::Field *f, const IR::BFN::Unit *unit,
                       const IR::Expression *e, bool needsIXBar) {
    if (!f) return;
    auto &info = field(f);
    LOG3("defuse: " << DBPrint::Brief << *unit << " reading " << f->name);
    info.use.clear();
    locpair use(unit, e);
    info.use.emplace(use);
    located_uses[f->id].emplace(use);
    check_conflicts(info, unit->stage());
    for (auto def : info.def) {
        LOG4("  " << use << " uses " << def);
        uses[def].emplace(use);
        defs[use].emplace(def); }
    non_dark_refs[use] |= needsIXBar;

    LOG5("\t Adding IXBar " << needsIXBar << " for use  " << use <<
         "  non_dark_refs:" << non_dark_refs.size());
}
void FieldDefUse::read(const IR::HeaderRef *hr, const IR::BFN::Unit *unit,
                       const IR::Expression *e, bool needsIXBar) {
    if (!hr) return;
    PhvInfo::StructInfo info = phv.struct_info(hr);
    for (int id : info.field_ids())
        read(phv.field(id), unit, e, needsIXBar);
    if (!info.metadata)
        read(phv.field(hr->toString() + ".$valid"), unit, e, needsIXBar);
}
void FieldDefUse::write(const PHV::Field *f, const IR::BFN::Unit *unit,
                        const IR::Expression *e, bool needsIXBar, bool partial) {
    if (!f) return;
    auto &info = field(f);
    LOG3("defuse: " << DBPrint::Brief << *unit <<
         " writing " << f->name << (partial ? " (partial)" : ""));

    // Update output_deps with the new def.
    locpair def(unit, e);
    for (auto old_def : info.def) {
        LOG4("  " << def << " overwrites " << old_def);
        output_deps[def].insert(old_def);
    }

    if (unit->is<IR::BFN::ParserState>()) {
        // parser can't rewrite PHV (it ors), so need to treat it as a read for conflicts, but
        // we don't mark it as a use of previous writes, and don't clobber those previous writes.
        if (!partial) {
            info.use.clear();
            // Though parser do OR value into phv, as long as it is not partial, the zero-init
            // def should be remove, because this def will override the 0.
            auto def_copy = info.def;
            for (const auto& v : def_copy) {
                if (parser_zero_inits.count(v)) {
                    info.def.erase(v); } }
        }

        info.use.emplace(unit, e);
        check_conflicts(info, unit->stage());
        for (auto def : info.def)
            LOG4("  " << e << " in " << *unit << " combines with " <<
                 def.second << " from " << *def.first);
    } else if (!partial) {
        info.def.clear(); }
    info.def.emplace(unit, e);
    located_defs[f->id].emplace(unit, e);
    non_dark_refs[def] |= needsIXBar;
    LOG5("\t Adding IXBar " << needsIXBar << " for def " << def <<
         "  non_dark_refs:" << non_dark_refs.size());
}
void FieldDefUse::write(const IR::HeaderRef *hr, const IR::BFN::Unit *unit,
                        const IR::Expression *e, bool needsIXBar) {
    if (!hr) return;
    PhvInfo::StructInfo info = phv.struct_info(hr);
    for (int id : info.field_ids())
        write(phv.field(id), unit, e, needsIXBar);
    if (!info.metadata)
        write(phv.field(hr->toString() + ".$valid"), unit, e, needsIXBar);
}

bool FieldDefUse::preorder(const IR::BFN::Pipe *p) {
    p->apply(CollectAliasDestinations(*this));
    return true;
}

bool FieldDefUse::preorder(const IR::BFN::Parser *p) {
    if (p->gress == EGRESS) {
        /* after processing the ingress pipe, before proceeding to the egress pipe, we
         * clear everything mentioned in the egress parser.  We want to ensure that nothing
         * that might be set by the egress parser is considered for bridging -- if it might
         * be set but isn't, it should be left unset in the egress pipe (not bridged) */
        p->apply(ClearBeforeEgress(*this));
    }

    for (const auto& f : phv) {
        if (f.gress != p->gress) {
            continue; }

        // Some DeparserParameters are not initialized by parser, i.e. fields that are
        // f.deparsed_to_tm() && f.is_solitary(). However, they should be treated as
        // implicitly initialized to an invalid value, instead of not initialized,
        // for the correctness of overlay analysis.

        // In the ingress, bridged_metadata is considered as a header field.
        // For ingress ,all metadata are initializes in the beginning.
        // for egress, only none bridged metadata are initializes at the beginning.
        if (!alias_destinations.count(&f)) {
            if (p->gress == INGRESS && (!f.metadata && !f.bridged)) continue;
            if (p->gress == EGRESS  && (!f.metadata || f.bridged)) continue;
        }
        LOG1("Ignoring implicit initialization for " << f.name);
        auto* parser_begin = p->start;
        const PHV::Field* f_p = phv.field(f.id);
        BUG_CHECK(f_p != nullptr, "Deferencing a invalidate field id");
        IR::Expression* dummy_expr = new ImplicitParserInit(f_p);
        auto& info = field(f_p);
        parser_zero_inits.emplace(parser_begin, dummy_expr);
        info.def.emplace(parser_begin, dummy_expr);
        located_defs[f.id].emplace(parser_begin, dummy_expr);
    }

    return true;
}

bool FieldDefUse::preorder(const IR::BFN::LoweredParser*) {
    BUG("Running FieldDefUse after the parser IR has been lowered; "
        "this will produce invalid results.");
    return false;
}

bool FieldDefUse::preorder(const IR::MAU::Action *act) {
    // stateful table arguments are read before the the action code runs which reads
    // them.  FIXME -- should only visit the SaluAction that is triggered by this action,
    // not all of them.
    // Only multistage_fifo.p4 needs visit stateful call before the action code runs.
    LOG1("FieldDefUse preorder Action : " << act);
    visit(act->stateful_calls, "stateful");
    if (act->parallel) {
        mode = VisitJustReads;
        visit(act->action, "action");
        mode = VisitJustWrites;
        visit(act->action, "action");
        mode = VisitAll;
    } else {
        visit(act->action, "action"); }
    return false;
}

bool FieldDefUse::preorder(const IR::MAU::Primitive* prim) {
    // XXX(yumin): consider h.f1 = h.f1 + 1; When we visit it,
    // we should first visit the source on the RHS, as how hardware does.
    // The h.f1 on RHS is an use of previous def, and the one on LHS is a
    // write that clears the previous defs from this point.
    // TODO(yumin): The long-term fix for this is to change the order of visiting when
    // visiting IR::MAU::Primitive to the evaluation order defined in spec,
    // to make control flow visit correct.
    LOG1("FieldDefUse preorder Primitive : " << prim);
    if (prim->operands.size() > 0) {
        if (mode != VisitJustWrites) {
            for (size_t i = 1; i < prim->operands.size(); ++i) {
                visit(prim->operands[i], "operands", i); } }
        if (mode != VisitJustReads) {
            visit(prim->operands[0], "dest", 0); }
    }
    return false;
}

/* StatefulALU can be defined in a global scope and have StatefulALU Actions in
 * different threads e.g. one in ingress and one in ghost. FieldDefUse must only
 * visit the actions relevant to the current thread.
 * - Make a list of all actions on the SALU
 * - Find the Table invoking the SALU
 * - Visit all actions on the table and create a list of the ones which map to
 *   the SALU actions
 * - Visit only the collected actions in the list
 * This ensures only the actions relevant to the current thread are visited.
 */
bool FieldDefUse::preorder(const IR::MAU::StatefulAlu *salu) {
    LOG1("FieldDefUse preorder Stateful : " << salu);
    visitAgain();
    std::set<cstring> salu_actions_to_visit;
    if (auto tbl = findContext<IR::MAU::Table>()) {
        for (auto act : tbl->actions) {
            auto tblActIdx = tbl->name + "-" + act.first;
            if (salu->action_map.count(tblActIdx)) {
                salu_actions_to_visit.insert(salu->action_map.at(tblActIdx));
            }
        }
        for (auto sv : salu_actions_to_visit) {
            LOG3("  visiting salu action " << sv);
            visit(salu->instruction.at(sv));
        }
    }
    return false;
}

bool FieldDefUse::preorder(const IR::Expression *e) {
    LOG1("FieldDefUse preorder : " << e);
    le_bitrange bits;
    auto *f = phv.field(e, &bits);
    auto *hr = e->to<IR::HeaderRef>();

    // Prevent visiting HeaderRefs in Members when PHV lookup fails, eg. for
    // $valid fields before allocatePOV.
    if (!f && e->is<IR::Member>()) return false;
    if (!f && !hr) return true;

    if (auto unit = findContext<IR::BFN::Unit>()) {
        bool needsIXBar = true;
        for (auto c = getContext(); c; c = c->parent) {
            if (c->node->is<IR::MAU::IXBarExpression>() || c->node->is<IR::MAU::StatefulCall>() ||
                c->node->is<IR::MAU::StatefulAlu>() || c->node->is<IR::MAU::Table>() ||
                c->node->is<IR::MAU::Meter>())
                break;
            if (c->node->is<IR::MAU::Action>()) {
                needsIXBar = false;
                break;
            }
        }
        if (isWrite()) {
           /* this is a temporary fix to make sure that we dont overwrite the
            * previous assignment. This needs to be enhanced to deal with range
            * being non-contiguous and overwrite if the range is contiguous
            */
            bool partial = (f && (bits.lo != 0 || bits.hi != f->size-1));
            write(f, unit, e, needsIXBar, partial);
            write(hr, unit, e, needsIXBar);
            LOG3(" write at unit : " << unit);
        } else {
            read(f, unit, e, needsIXBar);
            read(hr, unit, e, needsIXBar);
            LOG3(" read at unit : " << unit);
        }
    } else {
        assert(0); }
    return false;
}

void FieldDefUse::flow_merge(Visitor &a_) {
    FieldDefUse &a = dynamic_cast<FieldDefUse &>(a_);
    for (auto &i : Values(a.defuse)) {
        auto &info = field(i.field);
        BUG_CHECK(&info != &i, "same object in FieldDefUse::flow_merge");
        info.def.insert(i.def.begin(), i.def.end());
        info.use.insert(i.use.begin(), i.use.end()); }

    for (auto ndr : a.non_dark_refs) {
        non_dark_refs[ndr.first] |= a.non_dark_refs[ndr.first];
    }
}

std::ostream &operator<<(std::ostream &out, const FieldDefUse::info &i) {
    out << DBPrint::Brief;
    out << i.field->name << ": def:";
    const char *sep = "";
    for (auto u : i.def) {
        out << sep << *u.first;
        sep = ","; }
    out << " use:";
    sep = "";
    for (auto u : i.use) {
        out << sep << *u.first;
        sep = ","; }
    out << std::endl;
    out << DBPrint::Reset;
    return out;
}
void dump(const FieldDefUse::info &a) { std::cout << a; }

std::ostream &operator<<(std::ostream &out, const FieldDefUse &a) {
    for (auto &i : Values(a.defuse))
        out << i;
    out << DBPrint::Brief;
    unsigned maxw = 0;
    for (unsigned i = 0; i < a.phv.num_fields(); i++) {
        unsigned sz = a.phv.field(i)->name.size();
        if (!a.defuse.count(i))
            sz += 2;
        if (maxw < sz) maxw = sz; }
    for (unsigned i = 0; i < a.phv.num_fields(); i++) {
        auto field = a.phv.field(i);
        if (!field) continue;
        auto name = field->name;
        if (!a.defuse.count(i))
            out << '[' << std::setw(maxw-2) << std::left << name << ']';
        else
            out << std::setw(maxw) << std::left << name;
        out << ' ';
        for (unsigned j = 0; j <= i; j++)
            out << (a.conflict[i][j] ? '1' : '0');
        out << std::endl; }
    out << DBPrint::Reset;
    return out;
}
void dump(const FieldDefUse &a) { std::cout << a; }

struct code { int id; };
std::ostream &operator<<(std::ostream &out, const code &c) {
    switch (c.id/26/26) {
    case 0:
        return out << char('a' + c.id/26) << char('a' + c.id%26);
    case 1:
        return out << char('A' + c.id/26 - 26) << char('a' + c.id%26);
    case 2:
        return out << char('a' + c.id/26 - 52) << char('A' + c.id%26);
    case 3:
        return out << char('A' + c.id/26 - 78) << char('A' + c.id%26);
    default:
        return out << "??"; }
}

bool FieldDefUse::isUsedInParser(const PHV::Field* f) const {
    for (const FieldDefUse::locpair def : getAllDefs(f->id))
        if (def.first->is<IR::BFN::ParserState>() || def.first->is<IR::BFN::Parser>())
            return true;
    for (const FieldDefUse::locpair use : getAllUses(f->id))
        if (use.first->is<IR::BFN::ParserState>() || use.first->is<IR::BFN::Parser>())
            return true;
    return false;
}

bool FieldDefUse::hasUseAt(const PHV::Field* f, const IR::BFN::Unit* u) const {
    for (auto& use : getAllUses(f->id))
        if (u == use.first) return true;
    return false;
}

bool FieldDefUse::hasDefAt(const PHV::Field* f, const IR::BFN::Unit* u) const {
    for (auto& def : getAllDefs(f->id))
        if (def.first == u) return true;
    return false;
}

void FieldDefUse::end_apply(const IR::Node *) {
    // Get all uninitialized fields
    for (const auto& def : parser_zero_inits) {
        auto uses = getUses(def);
        if (uses.size()) {
            auto* init = def.second->to<ImplicitParserInit>();
            BUG_CHECK(init, "Defuse zero init IR type error.");
            uninitialized_fields.insert(init->field);
        }
    }

    if (!LOGGING(2)) return;
    LOG2("FieldDefUse result:");
    int count = phv.num_fields();
    if (count >= 40) {
        for (auto& f : phv)
            std::clog << code{f.id} << " " << f.name << std::endl; }
    std::clog << "  ";
    for (int i = 0; i < count; i++)
        std::clog << char('a' + i/26);
    std::clog << "\n  ";
    for (int i = 0; i < count; i++)
        std::clog << char('a' + i%26);
    for (int i = 0; i < count; i++) {
        std::clog << '\n' << code{i};
        for (int j = 0; j < count; j++)
            std::clog << (conflict[i][j] ? '1' : '0');
        if (count < 40)
            std::clog << " " << phv.field(i)->name; }
    std::clog << std::endl;

    LOG2("The number of uninitialized fields: " << uninitialized_fields.size());
    for (const auto* f : uninitialized_fields) {
        LOG2("---------------------------------");
        LOG2("uninitialized field: " << f);
        LocPairSet defs = getAllDefs(f->id);
        LOG2(".......Defs: ");
        for (const auto& kv : defs) {
            auto* unit = kv.first;
            auto* expr = kv.second;
            LOG2("unit name, unit->name = " << DBPrint::Brief << *unit);
            LOG2("in expression, expr = " << expr);
        }
        LocPairSet uses = getAllUses(f->id);
        LOG2("......Uses: ");
        for (const auto& kv : uses) {
            auto* unit = kv.first;
            auto* expr = kv.second;
            LOG2("unit name, unit->name = " << DBPrint::Brief << *unit);
            LOG2("in expression, expr = " << expr);
        }
    }
}
