#include <config.h>

#include "algorithm.h"
#include "constants.h"
#include "parser.h"
#include "phv.h"
#include "range.h"
#include "stage.h"
#include "target.h"
#include "top_level.h"
#include "vector.h"

#include "tofino/parser.cpp"            // tofino template specializations
#if HAVE_JBAY
#include "jbay/parser.cpp"              // jbay template specializations
#endif // HAVE_JBAY
#if HAVE_CLOUDBREAK
#include "cloudbreak/parser.cpp"        // cloudbreak template specializations
#endif // HAVE_CLOUDBREAK

class AsmParser : public Section {
    std::vector<Parser*> parser[2];     // INGRESS, EGRESS
    bitvec               phv_use[2];    // ingress/egress only
    Phv::Ref             ghost_parser;  // the ghost "parser" extracts a single
                                        // 32-bit value
    void start(int lineno, VECTOR(value_t) args);
    void input(VECTOR(value_t) args, value_t data);
    void process();
    void output(json::map &);
    void init_port_use(bitvec& port_use, const value_t &arg);
    static AsmParser& get_parser() { return singleton_object; }
    AsmParser();
    ~AsmParser() {}
public:
    static AsmParser    singleton_object;
} AsmParser::singleton_object;

AsmParser::AsmParser() : Section("parser") {
}

void AsmParser::init_port_use(bitvec& port_use, const value_t &arg) {
    if (arg.type == tVEC) {
        for (int i = 0; i < arg.vec.size; i++) {
            init_port_use(port_use, arg[i]); }
    } else if (arg.type == tRANGE) {
        if (arg.hi > arg.lo)
            error(arg.lineno, "port range hi index %d cannot be smaller than lo index %d",
                  arg.hi, arg.lo);
        port_use.setrange(arg.lo, arg.hi - arg.lo + 1);
    } else if (arg.type == tINT) {
        port_use.setbit(arg.i); }
}

void AsmParser::start(int lineno, VECTOR(value_t) args) {
    if (args.size != 0 && args[0] != "ingress" && args[0] != "egress" &&
        (args[0] != "ghost" || options.target < JBAY))
        error(lineno, "parser must specify ingress%s or egress",
              options.target >= JBAY ? ", ghost" : "");
}

void AsmParser::input(VECTOR(value_t) args, value_t data) {
    if (args.size > 0 && args[0] == "ghost") {
        ghost_parser = Phv::Ref(GHOST, 0, data);
        return; }
    gress_t gress = (args.size > 0 && args[0] == "egress") ? EGRESS : INGRESS;
    auto* p = new Parser(phv_use, gress, parser[gress].size());
    parser[gress].push_back(p);
    if (args.size == 1) {
        p->port_use.setrange(0, Target::NUM_PARSERS());
    } else if (args.size == 2) {
        init_port_use(p->port_use, args[1]); }
    p->input(args, data);
}

void AsmParser::process() {
    for (auto gress : Range(INGRESS, EGRESS)) {
        for (auto p : parser[gress]) {
            p->ghost_parser = ghost_parser;
            p->process(); } }

    bitvec phv_allow_bitwise_or;
    for (auto p : parser[INGRESS]) {
        phv_allow_bitwise_or |= p->phv_allow_bitwise_or; }
    for (auto p : parser[EGRESS]) {
        phv_allow_bitwise_or |= p->phv_allow_bitwise_or; }
    for (auto p : parser[INGRESS]) {
        p->phv_allow_bitwise_or = phv_allow_bitwise_or; }
    for (auto p : parser[EGRESS]) {
        p->phv_allow_bitwise_or = phv_allow_bitwise_or; }

    bitvec phv_allow_clear_on_write;
    for (auto p : parser[INGRESS]) {
        phv_allow_clear_on_write |= p->phv_allow_clear_on_write; }
    for (auto p : parser[EGRESS]) {
        phv_allow_clear_on_write |= p->phv_allow_clear_on_write; }
    for (auto p : parser[INGRESS]) {
        p->phv_allow_clear_on_write = phv_allow_clear_on_write; }
    for (auto p : parser[EGRESS]) {
        p->phv_allow_clear_on_write = phv_allow_clear_on_write; }

    bitvec phv_init_valid;
    for (auto p : parser[INGRESS]) {
        phv_init_valid |= p->phv_init_valid; }
    for (auto p : parser[EGRESS]) {
        phv_init_valid |= p->phv_init_valid; }
    for (auto p : parser[INGRESS]) {
        p->phv_init_valid = phv_init_valid; }
    for (auto p : parser[EGRESS]) {
        p->phv_init_valid = phv_init_valid; }
}

void AsmParser::output(json::map &ctxt_json) {
    ctxt_json["parser"]["ingress"] = json::vector();
    ctxt_json["parser"]["egress"] = json::vector();

    bool use_multiple_parser_impl = false;

    for (auto gress : Range(INGRESS, EGRESS)) {
        if (parser[gress].size() > 1)
            use_multiple_parser_impl = true;
    }
    /// We use the 'parsers' node in ctxt json to implement
    /// multiple parser instances support.
    /// We use the 'parser' node for all single parser
    /// instance support.
    for (auto gress : Range(INGRESS, EGRESS)) {
        /// remove after multi-parser support is fully-tested.
        if (use_multiple_parser_impl) {
            for (auto p : parser[gress]) {
                p->output(ctxt_json);
            }
        } else {
            if (!parser[gress].empty() && parser[gress][0] != nullptr)
                parser[gress][0]->output_legacy(ctxt_json);
        }
    }
}

std::map<std::string, std::vector<Parser::State::Match::Clot *>>     Parser::clots;
Alloc1D<std::vector<Parser::State::Match::Clot *>, PARSER_MAX_CLOTS> Parser::clot_use;
unsigned                                                             Parser::max_handle = 0;

static void collect_phv_vector(value_t value, gress_t gress, bitvec& bv) {
    for (auto &el : value.vec) {
        Phv::Ref reg(gress, 0, el);
        if (reg.check()) {
            int id = reg->reg.uid;
            bv[id] = 1;
        }
    }
}

void Parser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (args.size > 0) {
            if (args[0] == "ingress" && gress != INGRESS) continue;
            if (args[0] == "egress" && gress != EGRESS) continue;
        } else if (error_count > 0)
            break;
        for (auto &kv : MapIterChecked(data.map, true)) {
            if (kv.key == "name" && (kv.value.type == tSTR)) {
                name = kv.value.s;
                continue; }
            if (kv.key == "start" && (kv.value.type == tVEC || kv.value.type == tSTR)) {
                if (kv.value.type == tVEC)
                    for (int i = 0; i < 4 && i < kv.value.vec.size; i++)
                        start_state[i] = kv.value[i];
                else
                    for (int i = 0; i < 4; i++)
                        start_state[i] = kv.value;
                continue; }
            if (kv.key == "priority" && (kv.value.type == tVEC || kv.value.type == tINT)) {
                if (kv.value.type == tVEC) {
                    for (int i = 0; i < 4 && i < kv.value.vec.size; i++)
                        if (CHECKTYPE(kv.value[i], tINT))
                            priority[i] = kv.value[i].i;
                } else
                    for (int i = 0; i < 4; i++)
                        priority[i] = kv.value.i;
                continue; }
            if (kv.key == "priority_threshold" &&
                (kv.value.type == tVEC || kv.value.type == tINT)) {
                if (kv.value.type == tVEC) {
                    for (int i = 0; i < 4 && i < kv.value.vec.size; i++)
                        if (CHECKTYPE(kv.value[i], tINT))
                            pri_thresh[i] = kv.value[i].i;
                } else
                    for (int i = 0; i < 4; i++)
                        pri_thresh[i] = kv.value.i;
                continue; }
            if (kv.key == "parser_error") {
                if (parser_error.lineno >= 0) {
                    error(kv.key.lineno, "Multiple parser_error declarations");
                    warning(parser_error.lineno, "Previous was here");
                } else
                    parser_error = Phv::Ref(gress, 0, kv.value);
                continue; }
            if (kv.key == "bitwise_or") {
                if (CHECKTYPE(kv.value, tVEC))
                    collect_phv_vector(kv.value, gress, phv_allow_bitwise_or);

                continue;
            }
            if (kv.key == "clear_on_write") {
                if (options.target == TOFINO)
                    error(kv.key.lineno, "Tofino parser does not support clear-on-write semantic");

                if (CHECKTYPE(kv.value, tVEC))
                    collect_phv_vector(kv.value, gress, phv_allow_clear_on_write);

                continue;
            }
            if (kv.key == "init_zero") {
                if (CHECKTYPE(kv.value, tVEC)) {
                    collect_phv_vector(kv.value, gress, phv_init_valid);
                    collect_phv_vector(kv.value, gress, phv_use[gress]);
                }

                continue;
            }
            if (kv.key == "hdr_len_adj") {
                if (CHECKTYPE(kv.value, tINT))
                    hdr_len_adj = kv.value.i;
                continue; }
            if (kv.key == "states") {
                if (CHECKTYPE(kv.value, tMAP))
                    for (auto &st : kv.value.map)
                        define_state(gress, st);
                continue; }
            if (gress == EGRESS && kv.key == "meta_opt") {
                if (CHECKTYPE(kv.value, tINT))
                    meta_opt = kv.value.i;
                continue; }
            define_state(gress, kv); }

        // process the CLOTs immediately rather than in Parser::process() so that it
        // happens before Deparser::process()
        for (auto &vec : Values(clots)) {
            State::Match::Clot *maxlen = 0;
            for (auto *cl : vec) {
                if (cl->tag >= 0)
                    clot_use[cl->tag].push_back(cl);
                if (!maxlen || cl->max_length > maxlen->max_length)
                    maxlen = cl; }
            for (auto *cl : vec)
                cl->max_length = maxlen->max_length; }
        std::map<std::string, unsigned> clot_alloc;
        unsigned free_clot_tag = 0;
        while (free_clot_tag < PARSER_MAX_CLOTS && !clot_use[free_clot_tag].empty())
            ++free_clot_tag;
        for (auto &vec : Values(clots)) {
            for (auto *cl : vec) {
                if (cl->tag >= 0) continue;
                if (clot_alloc.count(cl->name)) {
                    cl->tag = clot_alloc.at(cl->name);
                    clot_use[cl->tag].push_back(cl);
                } else if (free_clot_tag >= PARSER_MAX_CLOTS) {
                    error(cl->lineno, "Too many CLOTs (%d max)", PARSER_MAX_CLOTS);
                } else {
                    clot_alloc[cl->name] = cl->tag = free_clot_tag++;
                    clot_use[cl->tag].push_back(cl);
                    while (free_clot_tag < PARSER_MAX_CLOTS &&
                           !clot_use[free_clot_tag].empty())
                        ++free_clot_tag; } } }
    }
}

void Parser::define_state(gress_t gress, pair_t &kv) {
   if (!CHECKTYPE2M(kv.key, tSTR, tCMD, "state declaration")) return;
   const char *name = kv.key.s;
   match_t stateno = { 0, 0 };
   if (kv.key.type == tCMD) {
       name = kv.key[0].s;
       if (!CHECKTYPE2(kv.key[1], tINT, tMATCH)) return;
       if (kv.key[1].type == tINT) {
           if (kv.key[1].i > PARSER_STATE_MASK)
               error(kv.key.lineno, "Explicit state out of range");
           stateno.word1 = kv.key[1].i;
           stateno.word0 = (~kv.key[1].i) & PARSER_STATE_MASK;
       } else {
           stateno = kv.key[1].m;
           if ((stateno.word0 | stateno.word1) > PARSER_STATE_MASK)
               error(kv.key.lineno, "Explicit state out of range");
           stateno.word0 |= ~(stateno.word0 | stateno.word1) & PARSER_STATE_MASK; } }
   if (!CHECKTYPE(kv.value, tMAP)) return;
   auto n = states.emplace(name, new State(kv.key.lineno, name, gress,
                                  stateno, kv.value.map));
   if (n.second)
       all.push_back(n.first->second);
   else {
       error(kv.key.lineno, "State %s already defined in %sgress", name,
             gress ? "e" : "in");
       warning(n.first->second->lineno, "previously defined here"); }
}

void Parser::process() {
    if (all.empty()) return;
    for (auto st : all) st->pass1(this);
    for (gress_t gress : Range(INGRESS, EGRESS)) {
        if (states.empty()) continue;
        if (start_state[0].lineno < 0) {
            State *start = states.at("start");
            if (!start) start = states.at("START");
            if (!start) {
                error(lineno, "No %sgress parser start state", gress ? "e" : "in");
                continue;
            } else for (int i = 0; i < 4; i++) {
                start_state[i].name = start->name;
                start_state[i].lineno = start->lineno;
                start_state[i].ptr.push_back(start); }
        } else for (int i = 0; i < 4; i++)
            start_state[i].check(gress, this, 0);
        for (int i = 0; i < 4 && !start_state[i]; i++)
            if (!start_state[i]->can_be_start()) {
                std::string name = std::string("<start") + char('0'+i) + '>';
                LOG1("Creating new " << gress << " " << name << " state");
                auto n = states.emplace(name, new State(lineno, name.c_str(), gress,
                        match_t{ 0, 0 }, VECTOR(pair_t) { 0, 0, 0 }));
                BUG_CHECK(n.second);
                State *state = n.first->second;
                state->def = new State::Match(lineno, gress, *start_state[i]);
                for (int j = 3; j >= i; j--)
                    if (start_state[j] == start_state[i]) {
                        start_state[j].name = name;
                        start_state[j].ptr[0] = state; }
                all.insert(all.begin(), state); }
        if (parser_error.lineno >= 0)
            if (parser_error.check() && parser_error.gress() == gress)
                phv_use[gress][parser_error->reg.uid] = 1; }
    if (ghost_parser && ghost_parser.check()) {
        if (ghost_parser.size() != 32)
            error(ghost_parser.lineno, "ghost thread input must be 32 bits"); }
    if (error_count > 0) return;
    int all_index = 0;
    for (auto st : all) st->all_idx = all_index++;
    bitvec unreach(0, all_index);
    for (int i = 0; i < 4; i++)
        if (!states.empty())
            start_state[i]->unmark_reachable(this, unreach);
    for (auto u : unreach)
        warning(all[u]->lineno, "%sgress state %s unreachable",
                all[u]->gress ? "E" : "In", all[u]->name.c_str());
    if (phv_use[INGRESS].intersects(phv_use[EGRESS])) {
        bitvec tmp = phv_use[INGRESS];
        tmp &= phv_use[EGRESS];
        for (int reg : tmp)
            error(lineno, "Phv register %s(R%d) used by both ingress and egress",
                  Phv::reg(reg)->name, reg); }
    if (options.match_compiler || 1) {  /* FIXME -- need proper liveness analysis */
        Phv::setuse(INGRESS, phv_use[INGRESS]);
        Phv::setuse(EGRESS, phv_use[EGRESS]); }
}

void Parser::output_default_ports(json::vector& vec, bitvec port_use) {
    while(!port_use.empty()) {
        auto idx = port_use.ffs(0);
        vec.push_back(idx);
        port_use.clrbit(idx);
    }
}

std::map<std::string, unsigned> Parser::parser_handles;

// output context.json format with multiple parser support
void Parser::output(json::map& ctxt_json) {
    json::vector& cjson = ctxt_json["parsers"][gress ? "egress" : "ingress"];
    if (all.empty()) return;
    for (auto st : all) st->pass2(this);
    if (error_count > 0) return;
    tcam_row_use = PARSER_TCAM_DEPTH;
    SWITCH_FOREACH_TARGET(options.target,
        auto *regs = new TARGET::parser_regs;
        declare_registers(regs);
        json::map parser_ctxt_json;
        // Parser Handles are generated in the assembler. Since the assembler
        // has no idea about multipipe program (since assembler is separately
        // invoked for each pipe bfa) the parser handles generated can be same
        // across multiple pipes. Here, we rely on the driver to prefix a pipe id
        // (profile id) to make the handles unique. The upper 2 bits are
        // reserved for this id.
        parser_handle = next_handle();
        parser_handles[name] = parser_handle;  // store parser handles
        parser_ctxt_json["name"] = name;
        parser_ctxt_json["handle"] = parser_handle;
        json::vector default_ports;
        output_default_ports(default_ports, port_use);
        parser_ctxt_json["default_parser_id"] = std::move(default_ports);
        write_config(*regs, parser_ctxt_json, false);
        cjson.push_back(std::move(parser_ctxt_json));
        gen_configuration_cache(*regs, ctxt_json["configuration_cache"]);
    )
}

// output context.json format prior to multiple parser support
// XXX(hanw): remove after multi-parser support is fully-tested.
void Parser::output_legacy(json::map& ctxt_json) {
    if (all.empty()) return;
    for (auto st : all) st->pass2(this);
    if (error_count > 0) return;
    tcam_row_use = PARSER_TCAM_DEPTH;
    SWITCH_FOREACH_TARGET(options.target,
        auto *regs = new TARGET::parser_regs;
        declare_registers(regs);
        parser_handle = next_handle();
        write_config(*regs, ctxt_json["parser"], true);
        gen_configuration_cache(*regs, ctxt_json["configuration_cache"]);
    )
}

Parser::Checksum::Checksum(gress_t gress, pair_t data) : lineno(data.key.lineno), gress(gress) {
    if (!CHECKTYPE2(data.key, tSTR, tCMD)) return;
    if (!CHECKTYPE(data.value, tMAP)) return;
    if (data.key.vec.size == 2) {
        if ((unit = data.key[1].i) >= Target::PARSER_CHECKSUM_UNITS())
            error(lineno, "Ran out of %sgress parser checksum units (%d available)",
                  gress ? "e" : "in", Target::PARSER_CHECKSUM_UNITS());
    } else { error(data.key.lineno, "Syntax error"); }
    for (auto &kv : MapIterChecked(data.value.map, true)) {
        if (kv.key == "type") {
            if (CHECKTYPE(kv.value, tSTR)) {
                     if (kv.value == "VERIFY")   type = 0;
                else if (kv.value == "RESIDUAL") type = 1;
                else if (kv.value == "CLOT")     type = 2;
                else error(kv.value.lineno, "Unknown parser checksum type");
            }
            if (kv.value == "clot") {
                if (unit < 2 || unit > 4)
                    error(kv.value.lineno, "CLOT can only use checksum engine 2-4"); }
        } else if (kv.key == "start") {
            if (CHECKTYPE(kv.value, tINT)) start = kv.value.i;
        } else if (kv.key == "end") {
            if (CHECKTYPE(kv.value, tINT)) end = kv.value.i;
        } else if (kv.key == "addr") {
            if (CHECKTYPE(kv.value, tINT)) addr = kv.value.i;
        } else if (kv.key == "add") {
            if (CHECKTYPE(kv.value, tINT)) add = kv.value.i;
        } else if (kv.key == "dest") {
            if (kv.value.type == tCMD && kv.value == "clot" && kv.value.vec.size == 2)
                tag = kv.value[1].i;
            else dest = Phv::Ref(gress, 0, kv.value);
        } else if (kv.key == "end_pos") {
            if (CHECKTYPE(kv.value, tINT)) {
                if (kv.value.i > PARSER_INPUT_BUFFER_SIZE)
                    error(kv.value.lineno, "Header end position is out of input buffer");
                if (kv.value.i < 0)
                    error(kv.value.lineno, "Header end postion cannot be negative");
                dst_bit_hdr_end_pos = kv.value.i;
            }
        } else if (kv.key == "mask") {
            if (CHECKTYPE(kv.value, tVEC)) {
                for (int i = 0; i < kv.value.vec.size; i++) {
                    auto range = kv.value[i];
                    unsigned lo = 0, hi = 0;
                    if (range.type == tRANGE) {
                        lo = range.lo;
                        hi = range.hi;
                    } else if (range.type == tINT)
                        lo = hi = range.i;
                    else error(kv.value.lineno, "Syntax error, expecting range or int");

                    if (lo > hi)
                        error(kv.value.lineno, "Invalid parser checksum input");
                    if ((hi + 1) > PARSER_INPUT_BUFFER_SIZE)
                        error(kv.value.lineno, "Parser checksum out of input buffer?");

                    for (unsigned byte = lo; byte <= hi; ++byte) {
                       if (kv.key == "mask")
                           mask |= (1 << byte);
                    }
                }
            }
        } else if (kv.key == "swap") {
            if (CHECKTYPE(kv.value, tINT)) swap = kv.value.i;
        } else if (kv.key == "mul_2") {
            if (options.target == TOFINO) {
                error(kv.value.lineno, "multiply by 2 feature is available for Tofino2 and higher");
            }
            if (CHECKTYPE(kv.value, tINT)) mul_2 = kv.value.i;
        } else if (kv.key == "shift") {
            shift = get_bool(kv.value);
        } else {
             warning(kv.key.lineno, "ignoring unknown item %s in checksum", value_desc(kv.key));
        }
    }
}

bool Parser::Checksum::equiv(const Checksum &a) const {
    if (unit != a.unit) return false;
    if (tag != a.tag) return false;
    if (dest && a.dest) {
        if (dest != a.dest) return false;
    } else if (dest || a.dest) return false;
    return add == a.add && mask == a.mask && swap == a.swap && start == a.start &&
           end == a.end && shift == a.shift && type == a.type;
}

void Parser::Checksum::pass1(Parser *parser) {
    if (parser->checksum_use.empty())
        parser->checksum_use.resize(Target::PARSER_CHECKSUM_UNITS());
    if (addr >= 0) {
        if (addr >= PARSER_CHECKSUM_ROWS)
            error(lineno, "invalid %sgress parser checksum address %d", gress ? "e" : "in", addr);
        else if (parser->checksum_use[unit][addr]) {
            if (!equiv(*parser->checksum_use[unit][addr])) {
                error(lineno, "incompatible %sgress parser checksum use at address %d",
                      gress ? "e" : "in", addr);
                warning(parser->checksum_use[unit][addr]->lineno, "previous use"); }
        } else
            parser->checksum_use[unit][addr] = this; }
    if (dest.check() && dest->reg.parser_id() < 0)
        error(dest.lineno, "%s is not accessable in the parser", dest->reg.name);
    if (dest && dest->reg.size == 32)
        error(dest.lineno, "checksum unit cannot write to 32-bit container");
    if (type == 0 && dest) {
        if (dest->lo != dest->hi)
            error(dest.lineno, "checksum verification destination must be single bit");
        else dst_bit_hdr_end_pos = dest->lo;
        if (options.target == JBAY && dest->reg.size == 8 && dest->reg.deparser_id() % 2)
            dst_bit_hdr_end_pos += 8;
    } else if (type == 1 && dest && dest.size() != dest->reg.size) {
        error(dest.lineno, "residual checksum must write whole container"); }
}

void Parser::Checksum::pass2(Parser *parser) {
    if (addr < 0) {
        int avail = -1;
        for (int i = 0; i < PARSER_CHECKSUM_ROWS; ++i) {
            if (parser->checksum_use[unit][i]) {
                if (equiv(*parser->checksum_use[unit][i])) {
                    addr = i;
                    break;
                }
            } else if (avail < 0)
                avail = i;
        }
        if (addr < 0) {
            if (avail >= 0)
                parser->checksum_use[unit][addr = avail] = this;
            else
                error(lineno, "Ran out of room in parser checksum control RAM of"
                        " %sgress unit %d (%d rows available)",
                      gress ? "e" : "in", unit, PARSER_CHECKSUM_ROWS);
        }
    }
}

template<class ROW>
void Parser::Checksum::write_row_config(ROW &row) {
    row.add = add;
    if (dest) row.dst = dest->reg.parser_id();
    else if (tag >= 0) row.dst = tag;
    row.dst_bit_hdr_end_pos = dst_bit_hdr_end_pos;
    row.hdr_end = end;
    int rsh = 0;
    for (auto &el : row.mask)
         el = (mask >> rsh++) & 1;
    row.shr = shift;
    row.start = start;
    rsh = 0;
    for (auto &el : row.swap)
         el = (swap >> rsh++) & 1;
    row.type = type;
}

Parser::CounterInit::CounterInit(gress_t gress, pair_t data) : lineno(data.key.lineno), gress(gress) {
    if (!CHECKTYPE2(data.key, tSTR, tCMD)) return;
    if (!CHECKTYPE(data.value, tMAP)) return;

    if (options.target == TOFINO) mask = 7;

    for (auto &kv : MapIterChecked(data.value.map, true)) {
        if (kv.key == "add" && CHECKTYPE(kv.value, tINT)) {
            add = kv.value.i;
            if (add > 255)
                error(lineno, "Parser counter add value out of range (0-255)");
        } else if (kv.key == "max" && CHECKTYPE(kv.value, tINT)) {
            max = kv.value.i;
            if (max > 255)
                error(lineno, "Parser counter max value out of range (0-255)");
        } else if (kv.key == "rotate" && CHECKTYPE(kv.value, tINT)) {
            rot = kv.value.i;
            if (rot > 7)
                error(lineno, "Parser counter rotate value out of range (0-7)");
        } else if (kv.key == "mask" && CHECKTYPE(kv.value, tINT)) {
            mask = kv.value.i;
            if (options.target == TOFINO && mask > 7) {
                error(lineno, "Parser counter mask value out of range (0-7)");
            } else if (options.target == JBAY && mask > 255) {
                error(lineno, "Parser counter mask value out of range (0-255)");
            }
        } else if (kv.key == "src") {
            if (CHECKTYPE(kv.value, tSTR)) {
                if (options.target == TOFINO) {
                         if (kv.value == "half_lo") src = 0;
                    else if (kv.value == "half_hi") src = 1;
                    else if (kv.value == "byte0")   src = 2;
                    else if (kv.value == "byte1")   src = 3;
                    else error(lineno, "Unexpected counter load source");
                } else if (options.target == JBAY) {
                         if (kv.value == "byte0") src = 0;
                    else if (kv.value == "byte1") src = 1;
                    else if (kv.value == "byte2") src = 2;
                    else if (kv.value == "byte3") src = 3;
                    else error(lineno, "Unexpected counter load source");
                }
            }
        } else if (kv.key != "push" && kv.key != "update_with_top") {
            error(lineno, "Syntax error in parser counter init expression");
        }
    }
}

bool Parser::CounterInit::equiv(const CounterInit &a) const {
    return add == a.add && mask == a.mask && rot == a.rot && max == a.max && src == a.src;
}

void Parser::CounterInit::pass2(Parser *parser) {
    if (addr < 0) {
        int avail = -1;
        for (int i = 0; i < PARSER_CTRINIT_ROWS; ++i) {
            if (parser->counter_init[i]) {
                if (equiv(*parser->counter_init[i])) {
                    addr = i;
                    break;
                }
            } else if (avail < 0)
                avail = i;
        }
        if (addr < 0) {
            if (avail >= 0)
                parser->counter_init[addr = avail] = this;
            else
                error(lineno, "Ran out of room in parser counter init RAM of"
                        " %sgress (%d rows available)",
                      gress ? "e" : "in", PARSER_CTRINIT_ROWS);
        }
    }
}

Parser::PriorityUpdate::PriorityUpdate(const value_t &exp) {
    lineno = exp.lineno;
    if (!parse(exp))
        error(lineno, "Syntax error in priority expression");
}

bool Parser::PriorityUpdate::parse(const value_t &exp, int what) {
    enum { START, MASK, SHIFT, LOAD };
    if (exp.type == tCMD) {
        if (exp[0] == ">>") {
            return what < SHIFT && parse(exp[1], LOAD) && parse(exp[2], SHIFT);
        } else if (exp[0] == "&") {
            return what < SHIFT && parse(exp[1], MASK) && parse(exp[2], MASK);
        }
    } else if (exp.type == tINT) {
        switch (what) {
        case START: case MASK:
            if (mask >= 0) return false;
            if ((mask = exp.i) < 0 || mask > 7) {
                error(exp.lineno, "priority mask %d out of range", mask);
                return false; }
            return true;
        case SHIFT:
            if (shift >= 0) return false;
            if ((shift = exp.i) < 0 || shift > 15) {
                error(exp.lineno, "priority shift %d out of range", shift);
                return false; }
            return true;
        default:
            return false; }
    } else if (exp.type == tSTR && exp.s[0] == '@' && isdigit(exp.s[1])) {
        char *end;
        if (what == SHIFT || offset >= 0 || (offset = strtol(exp.s+1, &end, 10)) < 0 || *end)
            return false;
        return true; }
    return false;
}

Parser::State::Ref &Parser::State::Ref::operator=(const value_t &v) {
    lineno = v.lineno;
    ptr.clear();
    if (v.type == tSTR) {
        name = v.s;
        pattern.word0 = pattern.word1 = 0;
    } else if (CHECKTYPE2M(v, tINT, tMATCH, "state reference")) {
        name.clear();
        if (v.type == tINT) {
            pattern.word0 = ~v.i;
            pattern.word1 = v.i;
        } else
            pattern = v.m;
        if ((pattern.word0 | pattern.word1) > PARSER_STATE_MASK) {
            error(lineno, "Parser state out of range");
            pattern.word0 &= PARSER_STATE_MASK;
            pattern.word1 &= PARSER_STATE_MASK;
        } else
            pattern.word1 |= ~(pattern.word0 | pattern.word1) & PARSER_STATE_MASK; }
    return *this;
}

void Parser::State::Ref::check(gress_t gress, Parser *pa, State *state) {
    if (ptr.empty()) {
        if (name.size()) {
            auto it = pa->states.find(name);
            if (it != pa->states.end())
                ptr.push_back(it->second);
            else if (name != "END" && name != "end")
                error(lineno, "No state named %s in %sgress parser",
                      name.c_str(), gress ? "e" : "in");
        } else if (pattern) {
            match_t tmp = pattern;
            unsigned wc = tmp.word0 & tmp.word1;
            if (wc && !state->stateno) {
                warning(lineno, "Using next state pattern in state without an explicit "
                        "state number");
                wc = 0; }
            tmp.word0 &= ~wc | state->stateno.word0;
            tmp.word1 &= ~wc | state->stateno.word1;
            for (auto *st : pa->all) {
                if (st->gress != state->gress) continue;
                if (st == state) continue;
                if (tmp.matches(st->stateno))
                    ptr.push_back(st); } } }
}

const char* Parser::match_key_loc_name(int loc) {
    if (options.target == TOFINO) {
        if (loc == 0 || loc == 1) return "half";
        if (loc == 2) return "byte0";
        if (loc == 3) return "byte1";
    } else {
        if (loc == 0) return "byte0";
        if (loc == 1) return "byte1";
        if (loc == 2) return "byte2";
        if (loc == 3) return "byte3";
    }

    error(-1, "Invalid match key loc");
    return nullptr;
}

int Parser::match_key_loc(value_t &key, bool errchk) {
    if (errchk && !CHECKTYPE(key, tSTR)) return -1;
    int loc = Parser::match_key_loc(key.s);
    if (loc < 0)
        error(key.lineno, "Invalid matcher location %s", key.s);
    return loc;
}

int Parser::match_key_loc(const char* key) {
    if (options.target == TOFINO) {
        if (!strcmp(key, "half") || !strcmp(key, "half0")) return 0;
        if (!strcmp(key, "byte0")) return 2;
        if (!strcmp(key, "byte1")) return 3;
    } else {
        if (!strcmp(key, "byte0")) return 0;
        if (!strcmp(key, "byte1")) return 1;
        if (!strcmp(key, "byte2")) return 2;
        if (!strcmp(key, "byte3")) return 3;
    }

    error(-1, "Invalid match key %s", key);
    return -1;
}

int Parser::match_key_size(const char* key) {
    if (!strncmp(key, "half", 4)) return 16;
    if (!strncmp(key, "byte", 4)) return 8;

    error(-1, "Invalid match key %s", key);
    return -1;
}

int Parser::State::MatchKey::move_down(int loc) {
    int to = loc;
    while (to >= 0 && ((specified >> to) & 1)) to--;
    if (to < 0) return -1;
    if (data[to].bit >= 0 && move_down(to) < 0)
        return -1;
    data[to] = data[loc];
    data[loc].bit = -1;
    return 0;
}

int Parser::State::MatchKey::add_byte(int loc, int byte, bool use_saved) {
    if (byte <= -64 || byte >= 32) {
        error(lineno, "Match key index out of range");
        return -1; }
    if (loc >= 0) {
        if ((specified >> loc) & 1)
            error(lineno, "Multiple matches in %s matcher", Parser::match_key_loc_name(loc));
        specified |= (1 << loc);
        if (data[loc].bit >= 0 && move_down(loc) < 0)
            return -1;
    } else {
        for (int i = 3; i >= 0; i--)
            if (data[i].bit < 0) {
                loc = i;
                break; }
        if (loc < 0) {
            error(lineno, "Too much data for parse matcher");
            return -1; } }
    data[loc].bit = width;
    data[loc].byte = use_saved ? USE_SAVED : byte;
    width += 8;
    return 0;
}

int Parser::State::MatchKey::setup_match_el(int at, value_t &spec) {
    switch (spec.type) {
    case tINT:
        return add_byte(at, spec.i);
    case tRANGE:
        if (spec.lo >= spec.hi) {
            error(spec.lineno, "Invalid match range");
            return -1; }
        if (at >= 0) at += spec.hi - spec.lo;
        for (int i = spec.hi; i >= spec.lo; i--) {
            if (add_byte(at, i) < 0)
                return -1;
            if (at >= 0) at--; }
        return 0;
    case tMAP:
        if (at >= 0) goto error;
        for (int i = spec.map.size-1; i >= 0; i--)
            if (setup_match_el(Parser::match_key_loc(spec.map[i].key), spec.map[i].value) < 0)
                return -1;
        return 0;
    case tSTR:
        if (spec == "ctr_zero") {
            if (ctr_zero >= 0) {
                error(spec.lineno, "'ctr_zero' specified twice");
                return -1; }
            ctr_zero = width++;
            return 0;
        } else if (spec == "ctr_neg") {
            if (ctr_neg >= 0) {
                error(spec.lineno, "'ctr_neg' specified twice");
                return -1; }
            ctr_neg = width++;
            return 0;
        } else if (!strncmp(spec.s, "save_byte", 9)) {
            if (options.target == TOFINO)
                error(spec.lineno, "Tofino does not have scratch registers in the parser");

            int i = spec.s[9] - '0';
            if (i < 0 || i > 4)
                error(spec.lineno, "Invalid parser save source %s", spec.s);
            save = 1 << i;
            width += 8;
            return 0;
        } else if (at < 0 && (at = Parser::match_key_loc(spec, false)) >= 0) {
            if (options.target == TOFINO && at == 0 && add_byte(1, 0, true) < 0) return -1;
            return add_byte(at, 0, true); }
        /* fall through */
    default:
    error:
        error(spec.lineno, "Syntax error in match spec");
        return -1; }
}

void Parser::State::MatchKey::setup(value_t &spec) {
    lineno = spec.lineno;
    if (spec.type == tVEC) {
        /* allocate the keys bits for the least significant match bits first... */
        for (int i = spec.vec.size-1; i >= 0; i--)
            if (setup_match_el(-1, spec[i]) < 0)
                return;
    } else
        setup_match_el(-1, spec);

    // For TOFINO, the first match byte pair must be an adjacent 16 bit pair. We
    // check and re-arrange the bytes for a 16 bit extractor. In JBAY this check
    // is not necessary as we can have independent byte extractors
    if (Target::MATCH_BYTE_16BIT_PAIRS() && (data[0].byte & data[1].byte) != USE_SAVED) {
        if (data[0].bit >= 0 && data[1].bit >= 0 && data[0].byte + 1 != data[1].byte) {
            BUG_CHECK((data[0].byte | data[1].byte) != USE_SAVED);
            int unused = -1;  // unused slot
            for (int i = 0; i < 4; i++) {
                if (data[i].bit < 0) {
                    if (unused < 0) unused = i;
                    continue; }
                for (int j = 0; j < 4; j++) {
                    if (data[j].bit >= 0 && data[i].byte+1 == data[j].byte) {
                        if (i == 1 && j == 0) {
                            std::swap(data[i], data[j]);
                        } else {
                            std::swap(data[0], data[i]);
                            std::swap(data[1], data[j]); }
                        return; } } }
            if (unused >= 0) {
                BUG_CHECK(unused > 1);
                std::swap(data[1], data[unused]);
            } else {
                error(spec.lineno, "Must have a 16-bit pair in match bytes"); } }
        if (data[0].bit < 0 && data[1].bit >= 0) {
            /* if we're using half of the 16-bit match, use the upper (first) half */
            std::swap(data[0], data[1]); }
    }
}

Parser::State::Match::Match(int l, gress_t gress, State* s, match_t m, VECTOR(pair_t) &data) :
    lineno(l), state(s), match(m)
{
    for (auto &kv : data) {
        if (kv.key == "counter") {
            if (kv.value.type == tMAP) {
                ctr_load = 1;

                bool from_ctr_init_ram = false;

                for (auto &kkv : MapIterChecked(kv.value.map, true)) {
                    if (kkv.key == "src") {
                        from_ctr_init_ram = true;
                    } else if (kkv.key == "push" && CHECKTYPE(kkv.value, tINT)) {
                        if (options.target == TOFINO)
                            error(kkv.key.lineno, "Tofino does not have counter stack");
                        ctr_stack_push = kkv.value.i;
                    } else if (kkv.key == "update_with_top" && CHECKTYPE(kkv.value, tINT)) {
                        if (options.target == TOFINO)
                            error(kkv.key.lineno, "Tofino does not have counter stack");
                        ctr_stack_upd_w_top = kkv.value.i;
                    }
                }

                if (from_ctr_init_ram) {
                    ctr_ld_src = 1;
                    ctr_instr = new CounterInit(gress, kv);
                } else {  // load from immediate
                    for (auto &kkv : MapIterChecked(kv.value.map, true)) {
                        if (kkv.key == "imm" && CHECKTYPE(kkv.value, tINT))
                            ctr_imm_amt = kkv.value.i;
                        else if (kkv.key != "push" && kkv.key != "update_with_top")
                            error(kkv.value.lineno, "Unknown parser counter init command");
                    }
                }
            } else if (kv.value.type == tCMD) {
                if (kv.value[0] == "inc" || kv.value[0] == "increment") {
                    if (CHECKTYPE(kv.value[1], tINT))
                        ctr_imm_amt = kv.value[1].i;
                } else if (kv.value[0] == "dec" || kv.value[0] == "decrement") {
                    if (CHECKTYPE(kv.value[1], tINT))
                        ctr_imm_amt = ~kv.value[1].i + 1;
                } else {
                    error(kv.value.lineno, "Unknown parser counter command");
                }
            } else if (kv.value.type == tSTR) {
                if (kv.value == "pop") {
                    if (options.target == TOFINO)
                        error(kv.key.lineno, "Tofino does not have counter stack");
                    ctr_stack_pop = true;
                } else {
                    error(kv.value.lineno, "Unknown parser counter command");
                }
            } else {
                error(kv.value.lineno, "Syntax error for parser counter");
            }
        } else if (kv.key == "hdr_len_inc_stop") {
            if (options.target == TOFINO)
                error(kv.key.lineno, "Tofino does not support hdr_len_inc_stop");
            else if (hdr_len_inc_stop)
                error(kv.key.lineno, "Mulitple hdr_len_inc_stop in match");
            hdr_len_inc_stop = HdrLenIncStop(kv.value);
        } else if (kv.key == "priority") {
            if (priority)
                error(kv.key.lineno, "Mulitple priority updates in match");
            else
                priority = PriorityUpdate(kv.value);
        } else if (kv.key == "shift") {
            if (shift)
                error(kv.key.lineno, "Multiple shift settings in match");
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if ((shift = kv.value.i) < 0 || shift > PARSER_INPUT_BUFFER_SIZE)
                error(kv.value.lineno, "shift value %d out of range", shift);
        } else if (kv.key == "offset_inc") {
            if (offset_inc)
                error(kv.key.lineno, "Multiple offset_inc settings in match");
            if (!CHECKTYPE(kv.value, tINT)) continue;
            offset_inc = kv.value.i;
        } else if (kv.key == "buf_req") {
            if (buf_req >= 0)
                error(kv.key.lineno, "Multiple buf_req settings in match");
            if (!CHECKTYPE(kv.value, tINT)) continue;
            if ((buf_req = kv.value.i) < 0 || shift > PARSER_INPUT_BUFFER_SIZE)
                error(kv.value.lineno, "buf_req value %d out of range", shift);
        } else if (kv.key == "next") {
            if (next.lineno >= 0) {
                error(kv.key.lineno, "Multiple next settings in match");
                error(next.lineno, "previously set here"); }
            next = kv.value;
        } else if (kv.key == "load") {
            if (load.lineno) {
                error(kv.value.lineno, "Multiple load entries in match");
                error(load.lineno, "previous specified here");
            } else
                load.setup(kv.value);
        } else if (kv.key == "save") {
            if (options.target == TOFINO)
                error(kv.key.lineno, "Tofino does not have scratch registers in the parser");

            if (load.save)
                error(kv.value.lineno, "Multiple save entries in match");

            if (CHECKTYPE(kv.value, tVEC)) {
                for (int i = 0; i < kv.value.vec.size; i++) {
                    if (CHECKTYPE(kv.value[i], tSTR)) {
                             if (kv.value[i] == "byte0") load.save = 1 << 0;
                        else if (kv.value[i] == "byte1") load.save = 1 << 1;
                        else if (kv.value[i] == "byte2") load.save = 1 << 2;
                        else if (kv.value[i] == "byte3") load.save = 1 << 3;
                        else error(lineno, "Unexpected parser save source");
                    }
                }
            }
        } else if (kv.key == "checksum") {
            csum.emplace_back(gress, kv);
        } else if (kv.key == "field_mapping") {
            if (CHECKTYPE(kv.value, tMAP)) {
                for (auto map : kv.value.map) {
                    auto ref = Phv::Ref(gress, 0, map.key);
                    auto fm = FieldMapping(ref, map.value);
                    field_mapping.emplace_back(fm);
                }
            }
        } else if (kv.key == "handle") {
            if (CHECKTYPE(kv.value, tINT))
                value_set_handle = kv.value.i;
        } else if (kv.key.type == tCMD && kv.key == "clot" && kv.key.vec.size == 2) {
            clots.push_back(new Clot(gress, kv.key.vec[1], kv.value));
        } else if (kv.key.type == tINT) {
            save.push_back(new Save(gress, this, kv.key.i, kv.key.i, kv.value));
        } else if (kv.key.type == tRANGE) {
            save.push_back(new Save(gress, this, kv.key.lo, kv.key.hi, kv.value));
        } else if (kv.value.type == tINT) {
            set.push_back(new Set(gress, this, kv.key, kv.value.i));
        } else if (kv.value.type == tCMD && kv.value[0] == "rotate") {
            if (CHECKTYPE(kv.value[1], tINT))
                set.push_back(new Set(gress, this, kv.key, kv.value[1].i, ROTATE));
        } else {
            error(kv.key.lineno, "Syntax error");
        }
    }

    for (auto c : csum) {
        if (c.type == 1 && c.end) {
            if (c.dst_bit_hdr_end_pos >= shift)  // see MODEL-542
                error(c.lineno, "Residual checksum end_pos must be less than state shift amount");
        }
    }
}

Parser::State::Match::Match(int l, gress_t gress, State *n) : lineno(l)
{
    /* build a default match for a synthetic start state */
    offset_inc = shift = 0;
    offset_rst = true;
    next.name = n->name;
    next.ptr.push_back(n);
}

static value_t &extract_save_phv(value_t &data) {
    if (data.type == tVEC)
        return data[0];
    if (data.type == tCMD && (data[0] == "offset" || data[0] == "rotate"))
        return data[1];
    return data;
}

Parser::State::Match::Save::Save(gress_t gress, Match* m,
                                 int l, int h, value_t &data, int flgs) :
    match(m), lo(l), hi(h), where(gress, 0, extract_save_phv(data)), flags(flgs)
{
    if (hi < lo || hi-lo > 3 || hi-lo == 2)
        error(data.lineno, "Invalid parser extraction size");
    if (data.type == tVEC) {
        if (data.vec.size > 2 || data.vec.size < 1)
            error(data.lineno, "Can only extract into single or pair");
        if (data.vec.size == 2)
            second = Phv::Ref(gress, 0, data[1]); }
    if (data.type == tCMD) {
        if (data[0] == "offset")
            flags |= OFFSET;
        else if (data[0] == "rotate")
            flags |= ROTATE; }
}

Parser::State::Match::Set::Set(gress_t gress, Match* m,
                               value_t &data, int v, int flgs) :
    match(m), where(gress, 0, extract_save_phv(data)), what(v), flags(flgs)
{
    if (data.type == tCMD) {
        if (data[0] == "offset")
            flags |= OFFSET;
        else if (data[0] == "rotate")
            flags |= ROTATE; }
}

bool Parser::State::Match::Clot::parse_length(const value_t &exp, int what) {
    enum { START, MASK, SHIFT, LOAD };
    if (exp.type == tCMD) {
        if (exp[0] == ">>") {
            return what < SHIFT && parse_length(exp[1], LOAD) && parse_length(exp[2], SHIFT);
        } else if (exp[0] == "&") {
            return what < SHIFT && parse_length(exp[1], MASK) && parse_length(exp[2], MASK);
        }
    } else if (exp.type == tINT) {
        switch (what) {
        case START: case MASK:
            if (length_mask >= 0) return false;
            if ((length_mask = exp.i) < 0 || length_mask > 0x3f) {
                error(exp.lineno, "length mask %d out of range", length_mask);
                return false; }
            return true;
        case SHIFT:
            if (length_shift >= 0) return false;
            if ((length_shift = exp.i) < 0 || length_shift > 15) {
                error(exp.lineno, "length shift %d out of range", length_shift);
                return false; }
            return true;
        default:
            return false; }
    } else if (exp.type == tSTR && exp.s[0] == '@' && isdigit(exp.s[1])) {
        char *end;
        if (what == SHIFT || length >= 0 || (length = strtol(exp.s+1, &end, 10)) < 0 || *end)
            return false;
        load_length = true;
        return true; }
    return false;
}

Parser::State::Match::Clot::Clot(gress_t gress, const value_t &tag,
                                 const value_t &data) : lineno(tag.lineno) {
    if (CHECKTYPE2(tag, tINT, tSTR)) {
        if (tag.type == tINT) {
            this->tag = tag.i;
            name = std::to_string(tag.i);
        } else {
            this->tag = -1;
            name = tag.s; } }
    Parser::clots[name].push_back(this);
    if (!CHECKTYPE3(data, tINT, tRANGE, tMAP)) return;
    if (data.type == tINT) {
       start = data.i;
       length = 1;
    } else if (data.type == tRANGE) {
        start = data.lo;
        length = data.hi - data.lo + 1;
    } else for (auto &kv : data.map) {
        if (kv.key == "start") {
            if (CHECKTYPE(kv.value, tINT))
                start = kv.value.i;
        } else if (kv.key == "length") {
            if (kv.value.type == tINT) {
                length = kv.value.i;
            } else if (!parse_length(kv.value) || !load_length)
                error(kv.value.lineno, "Syntax error");
            if (length_mask < 0) length_mask = 0x3f;
            if (length_shift < 0) length_shift = 0;
        } else if (kv.key == "max_length") {
            if (CHECKTYPE(kv.value, tINT))
                max_length = kv.value.i;
        } else if (kv.key == "checksum") {
            if (CHECKTYPE(kv.value, tINT))
                csum_unit = kv.value.i;
        } else
            error(kv.key.lineno, "Unknown CLOT key %s", value_desc(kv.key)); }
    if (start < 0)
        error(data.lineno, "No start in clot %s", name.c_str());
    if (length < 0)
        error(data.lineno, "No length in clot %s", name.c_str());
    if (max_length < 0) {
        if (load_length)
            max_length = 64;
        else
            max_length = length;
    } else if (!load_length && max_length != length) {
        error(data.lineno, "Inconsistent constant length and max_length in clot"); }
}

Parser::State::Match::FieldMapping::FieldMapping(Phv::Ref &ref, const value_t &a) {
    if (CHECKTYPE(a, tCMD)) {
        where = ref;
        container_id = a.vec[0].s;
        lo = a.vec[1].lo;
        hi = a.vec[1].hi;
    } else {
        error(a.lineno, "Syntax error");
    }
}

Parser::State::Match::HdrLenIncStop::HdrLenIncStop(const value_t &data) {
    if (CHECKTYPE(data, tINT)) {
        if (data.i < 0 || data.i > PARSER_INPUT_BUFFER_SIZE)
            error(data.lineno, "hdr_len_inc_stop %" PRId64 " out of range", data.i);
        lineno = data.lineno;
        final_amt = data.i;
    }
}

Parser::State::State(int l, const char *n, gress_t gr, match_t sno, const VECTOR(pair_t) &data) :
    name(n), gress(gr), stateno(sno), def(0), lineno(l)
{
    VECTOR(pair_t) default_data = EMPTY_VECTOR_INIT;
    bool have_default = data["default"] != 0;
    for (auto &kv : data) {
        if (kv.key.type == tINT && kv.value.type == tMAP) {
            match_t m = { ~(unsigned)kv.key.i, (unsigned)kv.key.i };
            match.push_back(new Match(kv.key.lineno, gress, this, m, kv.value.map));
        } else if (kv.key.type == tBIGINT && kv.value.type == tMAP) {
            match_t m = { ~(unsigned)kv.key.bigi.data[0], (unsigned)kv.key.bigi.data[0] };
            match.push_back(new Match(kv.key.lineno, gress, this, m, kv.value.map));
        } else if (kv.key == "value_set" && kv.value.type == tMAP) {
            match_t m = { 0, 0 };
            match.push_back(new Match(kv.key.lineno, gress, this, m, kv.value.map));
            if (kv.key.type == tCMD) {
                if (CHECKTYPE(kv.key[1], tSTR))
                    match.back()->value_set_name = kv.key[1].s;
                if (kv.key.vec.size > 2 && CHECKTYPE(kv.key[2], tINT))
                    match.back()->value_set_size = kv.key[2].i;
                else
                    match.back()->value_set_size = 1;
            } else
                match.back()->value_set_size = 1;
        } else if (kv.key.type == tMATCH) {
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            match.push_back(new Match(kv.key.lineno, gress, this, kv.key.m, kv.value.map));
        } else if (kv.key == "match") {
            if (key.lineno) {
                error(kv.value.lineno, "Multiple match entries in state %s", n);
                error(key.lineno, "previous specified here");
            } else
                key.setup(kv.value);
        } else if (kv.key == "default") {
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            if (def) {
                error(kv.key.lineno, "Multiple defaults in state %s", n);
                error(def->lineno, "previous specified here");
            } else {
                match_t m = { 0, 0 };
                def = new Match(kv.key.lineno, gress, this, m, kv.value.map); }
        } else if (!have_default) {
            VECTOR_add(default_data, kv);
        } else
            error(kv.key.lineno, "Syntax error");
    }
    if (default_data.size) {
        BUG_CHECK(!def);
        match_t m = { 0, 0 };
        def = new Match(default_data[0].key.lineno, gress, this, m, default_data); }
    VECTOR_fini(default_data);
}

bool Parser::State::can_be_start() {
    if (match.size()) return false;
    if (!def) return true;
    //if (def->counter || def->offset || def->shift) return false;
    //if (def->counter_reset || def->offset_reset) return false;
    //if (def->save.size() || def->set.size()) return false;
    return true;
}

void Parser::State::unmark_reachable(Parser *pa, bitvec &unreach) {
    if (!unreach[all_idx]) return;
    unreach[all_idx] = 0;
    for (auto m : match) m->unmark_reachable(pa, this, unreach);
    if (def) def->unmark_reachable(pa, this, unreach);
}

void Parser::State::Match::unmark_reachable(Parser *pa, Parser::State *state, bitvec &unreach) {
    for (auto succ : next) succ->unmark_reachable(pa, unreach);
}

/********* pass 1 *********/

void Parser::State::Match::pass1(Parser *pa, State *state) {
    next.check(state->gress, pa, state);
    for (auto s : save) {
        if (!s->where.check()) continue;
        if (s->where->reg.parser_id() < 0)
            error(s->where.lineno, "%s is not accessable in the parser", s->where->reg.name);
        if (options.target == TOFINO && s->lo >= 32 && s->lo < 54)
            error(s->where.lineno, "byte 32-53 of input buffer cannot be used for output");
        if (options.target == JBAY && s->lo >= 32 && s->lo < 48)
            error(s->where.lineno, "byte 32-47 of input buffer cannot be used for output");
        pa->phv_use[state->gress][s->where->reg.uid] = 1;
        int size = s->where->reg.size;
        if (s->second) {
            if (!s->second.check()) continue;
            if (s->second->reg.parser_id() < 0)
                error(s->second.lineno, "%s is not accessable in the parser", s->second->reg.name);
            else if (s->second->lo >= 32 && s->second->lo < 54)
                error(s->where.lineno, "byte 32-53 of input buffer cannot be used for output");
            else if (s->second->reg.parser_id() != s->where->reg.parser_id() + 1 ||
                (s->where->reg.parser_id() & 1))
                error(s->second.lineno, "Can only write into even/odd register pair");
            else if (s->second->lo || s->second->hi != size-1)
                error(s->second.lineno, "Can only write data into whole phv registers in parser");
            else
                size *= 2; }
        if (s->where->lo || s->where->hi != s->where->reg.size-1)
            error(s->where.lineno, "Can only write data into whole phv registers in parser");
        else if ((s->hi-s->lo+1)*8 != size)
            error(s->where.lineno, "Data to write doesn't match phv register size");
    }
    for (auto s : set) {
        if (!s->where.check()) continue;
        if (s->where->reg.parser_id() < 0)
            error(s->where.lineno, "%s is not accessable in the parser", s->where->reg.name);
        pa->phv_use[state->gress][s->where->reg.uid] = 1;
    }
    if (value_set_size == 0) {
        uint64_t match_mask = (UINT64_C(1) << state->key.width) - 1;
        uint64_t not_covered = match_mask & ~(match.word0 | match.word1);
        if (not_covered != 0) {
            warning(lineno, "Match pattern does not cover all bits of match key, "
                    "assuming the rest are don't care");
            match.word0 |= not_covered;
            match.word1 |= not_covered; }
        if ((match.word1 & ~match.word0 & ~match_mask) != 0)
            error(lineno, "Matching on bits not in the match of state %s", state->name.c_str());
        for (auto m : state->match) {
            if (m == this) break;
            if (m->match == match) {
                warning(lineno, "Can't match parser state due to previous match");
                warning(m->lineno, "here");
                break; } } }
    for (auto &c : csum)
        c.pass1(pa);
}

bool Parser::State::Match::Set::merge(gress_t gress, const Set &a) {
    auto orig = where;
    if (where->reg != a.where->reg) return false;
    if (!(where->hi < a.where->lo || a.where->hi < where->lo)) {
        warning(where.lineno, "Phv slices %s and %s overlapping"
                , where.name(), a.where.name()); }
    what = ((what << where->lo) | (a.what << a.where->lo))
        >> (std::min(where->lo, a.where->lo));
    where = Phv::Ref(where->reg, gress, std::min(where->lo, a.where->lo),
                     std::max(where->hi, a.where->hi));
    LOG1("Merging phv slices " << orig << " + " << a.where << " = " << where);
    return true;
}

void Parser::State::pass1(Parser *pa) {
    for (auto m : match) m->pass1(pa, this);
    if (def) def->pass1(pa, this);
    for (auto code : MatchIter(stateno)) {
        if (pa->state_use[code]) {
            error(lineno, "%sgress state %s uses state code %d, already in use",
                  gress ? "E" : "In", name.c_str(), code);
            for (auto *state : pa->all) {
                if (state != this && state->gress == gress && state->stateno.matches(code))
                    error(state->lineno, "also used by state %s", state->name.c_str()); } }
        pa->state_use[code] = 1; }

    for (auto m : match)
        for (auto succ : m->next)
            succ->pred.insert(m);

    if (def)
        for (auto succ : def->next)
            succ->pred.insert(def);
}

/********* pass 2 *********/

void Parser::State::MatchKey::preserve_saved(unsigned saved) {
    for (int i = 3; i >= 0; i--) {
        if (!((saved >> i) & 1)) continue;
        if (data[i].bit < 0 || data[i].byte == USE_SAVED)
            continue;
        if ((specified >> i) & 1)
            error(lineno, "match in %s matcher conflicts with previous state save "
                  "action", Parser::match_key_loc_name(i));
        else if (move_down(i) < 0) {
            error(lineno, "Ran out of matching space due to preserved values from "
                  "previous states");
            break; } }
}

Parser::State::OutputUse Parser::State::Match::Save::output_use() const {
    OutputUse rv;
    if (lo == hi) rv.b8++;
    else if (lo+1 == hi) rv.b16++;
    else if (lo+3 == hi) rv.b32++;
    else BUG();
    return rv;
}
Parser::State::OutputUse Parser::State::Match::Set::output_use() const {
    OutputUse rv;
    if (where->reg.size == 8) rv.b8++;
    else if (where->reg.size == 16) rv.b16++;
    else if (where->reg.size == 32) rv.b32++;
    else BUG();
    return rv;
}
Parser::State::OutputUse Parser::State::Match::output_use() const {
    OutputUse rv;
    for (auto s : save) rv += s->output_use();
    for (auto s : set) rv += s->output_use();
    return rv;
}
void Parser::State::Match::merge_outputs(OutputUse use) {
    if (options.target != TOFINO) return;
    // In a loop, do not merge the extracts since the offset inc count is tied to the container.
    if (offset_inc) return;
    // FIXME -- this is tofino specific
    use += output_use();
    if (use.b32 >= 4 && use.b16 >= 4) return;
    std::sort(save.begin(), save.end(), [](const Save* a, const Save* b)->bool {
        return a->lo < b->lo; });
    /* combine adjacent aligned 16-bit extracts into 32 bit */
    for (unsigned i = 0; i+1 < save.size() && use.b32 < 4; ++i) {
        if (save[i]->hi == save[i]->lo + 1 && save[i+1]->lo == save[i]->hi + 1 &&
            save[i+1]->hi == save[i+1]->lo + 1 && !save[i]->flags && !save[i+1]->flags &&
            (save[i]->where->reg.parser_id() & 1) == 0 &&
            save[i]->where->reg.parser_id() + 1 == save[i+1]->where->reg.parser_id()) {
            LOG3("merge 2x16->32 (" << save[i]->where << ", " << save[i+1]->where << ")");
            save[i]->hi += 2;
            save.erase(save.begin()+i+1);
            use.b32++;
            use.b16 -= 2; } }
    /* combine adjacent aligned 8-bit extracts into 16 bit */
    for (unsigned i = 0; i+1 < save.size() && use.b16 < 4; ++i) {
        if (save[i]->hi == save[i]->lo && save[i+1]->lo == save[i]->hi + 1 &&
            save[i+1]->hi == save[i+1]->lo && !save[i]->flags && !save[i+1]->flags &&
            (save[i]->where->reg.parser_id() & 1) == 0 &&
            save[i]->where->reg.parser_id() + 1 == save[i+1]->where->reg.parser_id()) {
            LOG3("merge 2x8->16 (" << save[i]->where << ", " << save[i+1]->where << ")");
            save[i]->hi += 1;
            save.erase(save.begin()+i+1);
            use.b16++;
            use.b8 -= 2; } }
    /* combine 4 adjacent aligned 8-bit extracts into 32 bit */
    for (unsigned i = 0; i+1 < save.size() && use.b32 < 4; ++i) {
        if (save[i]->hi == save[i]->lo + 1 && save[i+1]->lo == save[i]->hi + 1 &&
            save[i+1]->hi == save[i+1]->lo + 1 && !save[i]->flags && !save[i+1]->flags &&
            (save[i]->where->reg.parser_id() & 1) == 0 &&
            save[i]->where->reg.parser_id() + 1 == save[i+1]->where->reg.parser_id()) {
            LOG3("merge 4x8->32 (" << save[i]->where << ", " << save[i+1]->where << ")");
            save[i]->hi += 2;
            save.erase(save.begin()+i+1);
            use.b32++;
            use.b16 -= 2; } }
}

void Parser::State::Match::pass2(Parser *pa, State *state) {
    for (auto &c : csum)
        c.pass2(pa);

    if (ctr_instr)
        ctr_instr->pass2(pa);

    if (clots.size() > 0) {
        if (options.target == TOFINO)
            error(clots[0]->lineno, "clots not supported on tofino");
        else if (clots.size() > 2)
            error(clots[2]->lineno, "no more than two clots per state"); }
}

void Parser::State::pass2(Parser *pa) {
    if (!stateno) {
        unsigned s;
        for (s = 0; pa->state_use[s]; s++);
        if (s > PARSER_STATE_MASK)
            error(lineno, "Can't allocate state number for %sgress state %s",
                  gress ? "e" : "in", name.c_str());
        else {
            stateno.word0 = s ^ PARSER_STATE_MASK;
            stateno.word1 = s;
            pa->state_use[s] = 1; } }
    unsigned def_saved = 0;
    if (def && def->load.lineno >= 0) {
        for (int i = 0; i < 4; i++)
            if (def->load.data[i].bit >= 0)
                def_saved |= 1 << i;
        if (def_saved && def->next)
            def->next->key.preserve_saved(def_saved); }
    OutputUse defuse;
    if (def) defuse = def->output_use();
    for (auto m : match) {
        m->pass2(pa, this);
        unsigned saved = def_saved;
        if (m->load.lineno) {
            for (int i = 0; i < 4; i++)
                if (m->load.data[i].bit >= 0)
                    saved |= 1 << i;
                else if (def && def->load.lineno && def->load.data[i].bit >= 0)
                    m->load.data[i] = def->load.data[i]; }
        if (saved) {
            if (m->next)
                m->next->key.preserve_saved(saved);
            else if (def && def->next)
                def->next->key.preserve_saved(saved); }
        if (!options.match_compiler)
            m->merge_outputs(defuse); }
}

/********* output *********/

template <class REGS>
void Parser::PriorityUpdate::write_config(REGS &action_row) {
    if (offset >= 0) {
        action_row.pri_upd_type = 1;
        action_row.pri_upd_src = offset;
        action_row.pri_upd_en_shr = shift;
        action_row.pri_upd_val_mask = mask;
    } else {
        action_row.pri_upd_type = 0;
        action_row.pri_upd_en_shr = 1;
        action_row.pri_upd_val_mask = mask;
    }
}

template <class REGS>
void Parser::State::Match::write_config(REGS &regs, Parser *pa, State *state,
                                        Match *def, json::map &ctxt_json) {
    int row, count = 0;
    do {
        if ((row = --pa->tcam_row_use) < 0) {
            if (row == -1)
                error(state->lineno, "Ran out of tcam space in %sgress parser",
                      state->gress ? "e" : "in");
            return; }
        ctxt_json["tcam_rows"].to<json::vector>().push_back(row);
        write_row_config(regs, pa, state, row, def,ctxt_json);
        pa->match_to_row[this] = row;
    } while (++count < value_set_size);
}

template<class REGS>
void Parser::State::Match::write_config(REGS &regs, json::vector &vec) {
    int select_statement_bit = 0;
    for (auto f : field_mapping) {
        json::map container_cjson;
        container_cjson["container_width"] = Parser::match_key_size(f.container_id.c_str());

        int container_hardware_id = Parser::match_key_loc(f.container_id.c_str());
        container_cjson["container_hardware_id"] = container_hardware_id;

        container_cjson["mask"] = (1 << (f.hi - f.lo + 1)) - 1;
        json::vector field_mapping_cjson;
        for (auto i = f.lo; i <= f.hi; i++) {
            json::map field_map;
            field_map["register_bit"] = i;
            field_map["field_name"] = f.where.name();
            field_map["start_bit"] = i;
            field_map["select_statement_bit"] = select_statement_bit++;
            field_mapping_cjson.push_back(field_map.clone());
        }
        container_cjson["field_mapping"] = field_mapping_cjson.clone();
        vec.push_back(container_cjson.clone());
    }
}

/** Extractor config tracking and register config code
 * Different tofino models have very different ways in which their parser extractors are
 * managed, but all are common in that there are multiple extractions that can happen in
 * parallel in a single parser match tcam row.  We manage this by having a target-specific
 * 'output_map' object passed via a void * to target-sepcific write_output_config methods
 * along with an `unsigned used` mask that tracks which or how many extractors have been
 * used, so as to issue errors for conflicting uses.
 *
 * The `setup_phv_output_map` method creates the target specific output_map object that
 * will be passed to subsequent `write_output_config` calls to deal with each individual
 * extract.  Finally, `mark_unused_output_map` is called to deal with any register setup
 * needed for unused extractors.  They're called 'outputs' as the are concerned with
 * outputting PHV values from the parser.
 *
 * PHV outputs are split into 'saves' and 'sets' which come from different syntax in the
 * asm source.  'saves' copy data from the input buffer into PHVs, while 'sets' write
 * constants into the PHVs.  Different targets have different constraints on how flexible
 * they are for saves vs sets, so some want to do saves first and other sets
 *  - tofino1: do saves first (why? sets seem more constrained, but there's an issue
 *    with ganging smaller extractors to write larger PHVs)
 *  - tofino2: do sets first as some extractors can only do saves
 *  - tofino3: don't care -- extractors are entirely symmetric vis sets vs saves
 *
 * FIXME -- should probably refactor this into a more C++ style base class pointer with
 * derived classes for each target.  Should move the 'used' mask into that object as well.
 * Alternately, could move the entire `setup` to `mark_unused` process into a target specific
 * method.
 */

template <class REGS>
void Parser::State::Match::write_saves(REGS &regs, Match* def, void *output_map, int& max_off, unsigned& used) {
    if (offset_inc) for (auto s : save) s->flags |= OFFSET;
    for (auto s : save)
        max_off = std::max(max_off, s->write_output_config(regs, output_map, used));
    if (def) for (auto &s : def->save)
        max_off = std::max(max_off, s->write_output_config(regs, output_map, used));
}

template <class REGS>
void Parser::State::Match::write_sets(REGS &regs, Match* def, void *output_map, unsigned& used) {
    if (offset_inc) for (auto s : set) s->flags |= ROTATE;
    for (auto s : set) s->write_output_config(regs, output_map, used);
    if (def) for (auto s : def->set) s->write_output_config(regs, output_map, used);
}

template <class REGS>
void Parser::State::Match::write_common_row_config(REGS &regs, Parser *pa, State *state, int row,
                                                   Match *def, json::map &ctxt_json) {
    int max_off = -1;
    write_lookup_config(regs, state, row);

    auto &ea_row = regs.memory[state->gress].ml_ea_row[row];
    if (ctr_instr || ctr_load || ctr_imm_amt || ctr_stack_pop)
        write_counter_config(ea_row);
    else if (def)
        def->write_counter_config(ea_row);
    if (shift)
        max_off = std::max(max_off, int(ea_row.shift_amt = shift) - 1);
    else if (def)
        max_off = std::max(max_off, int(ea_row.shift_amt = def->shift) - 1);
    max_off = std::max(max_off, write_load_config(regs, pa, state, row));
    if (auto &next = (!this->next && def) ? def->next : this->next) {
        std::vector<State *> prev;
        for (auto n : next) {
            max_off = std::max(max_off, n->write_lookup_config(regs, pa, state, row, prev));
            prev.push_back(n); }
        const match_t &n = next.pattern ? next.pattern : next->stateno;
        ea_row.nxt_state = n.word1;
        ea_row.nxt_state_mask = ~(n.word0 & n.word1) & PARSER_STATE_MASK;
    } else
        ea_row.done = 1;

    auto &action_row = regs.memory[state->gress].po_action_row[row];
    for (auto &c : csum) {
        action_row.csum_en[c.unit] = 1;
        action_row.csum_addr[c.unit] = c.addr; }
    if (offset_inc || offset_rst) {
        action_row.dst_offset_inc = offset_inc;
        action_row.dst_offset_rst = offset_rst;
    } else if (def) {
        action_row.dst_offset_inc = def->offset_inc;
        action_row.dst_offset_rst = def->offset_rst; }
    if (priority)
        priority.write_config(action_row);
    if (hdr_len_inc_stop)
        hdr_len_inc_stop.write_config(action_row);

    void *output_map = pa->setup_phv_output_map(regs, state->gress, row);
    unsigned used = 0;
    for (auto &c : csum) c.write_output_config(regs, pa, output_map, used);

    if (options.target == TOFINO) {
        write_saves(regs, def, output_map, max_off, used);
        write_sets(regs, def, output_map, used);
    } else {
        write_sets(regs, def, output_map, used);
        write_saves(regs, def, output_map, max_off, used);
    }

    int clot_unit = 0;
    for (auto *c : clots) c->write_config(action_row, clot_unit++);
    if (def) for (auto *c : def->clots) c->write_config(action_row, clot_unit++);
    pa->mark_unused_output_map(regs, output_map, used);

    if (buf_req < 0) {
        buf_req = max_off + 1;
        BUG_CHECK(buf_req <= 32); }
    ea_row.buf_req = buf_req;
}

std::set<Parser::State::Match*>
Parser::State::Match::get_all_preds() {
    std::set<Parser::State::Match*> visited;
    return get_all_preds_impl(visited);
}

std::set<Parser::State::Match*>
Parser::State::Match::get_all_preds_impl(std::set<Parser::State::Match*>& visited) {
    if (visited.count(this))
        return {};

    visited.insert(this);

    std::set<Parser::State::Match*> rv;

    for (auto p : this->state->pred) {
        rv.insert(p);
        auto pred = p->get_all_preds_impl(visited);
        rv.insert(pred.begin(), pred.end());
    }

    return rv;
}

template <class REGS>
void Parser::State::Match::write_row_config(REGS &regs, Parser *pa, State *state, int row,
                                            Match *def, json::map &ctxt_json) {
    write_common_row_config(regs, pa, state, row, def, ctxt_json);
}

template <class REGS>
void Parser::State::MatchKey::write_config(REGS &, json::vector &) {
    // FIXME -- TBD -- probably needs to be different for tofino/jbay, so there will be
    // FIXME -- template specializations for this in those files
}

template <class REGS>
void Parser::State::write_config(REGS &regs, Parser *pa, json::vector &ctxt_json) {
    LOG2(gress << " state " << name << " (" << stateno << ')');
    for (auto i : match) {
        bool uses_pvs = false;
        json::map state_cjson;
        state_cjson["parser_name"] = name;
        i->write_config(regs, state_cjson["match_registers"]);
        if (i->value_set_size > 0) uses_pvs = true;
        i->write_config(regs, pa, this, def, state_cjson);
        state_cjson["uses_pvs"] = uses_pvs;
        if (def) def->write_config(regs, pa, this, 0, state_cjson);
        if (uses_pvs) {
            state_cjson["pvs_name"] = i->value_set_name;
            if (i->value_set_handle < 0)
                error(lineno, "Invalid handle for parser value set %s", i->value_set_name.c_str());
            auto pvs_handle_full = i->value_set_handle;
            state_cjson["pvs_handle"] = pvs_handle_full;
        }
        for (auto idx : MatchIter(stateno)) {
            state_cjson["parser_state_id"] = idx;
            ctxt_json.push_back(state_cjson.clone());
        }
    }
}
