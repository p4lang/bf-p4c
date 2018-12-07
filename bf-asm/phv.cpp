#include <iostream>
#include "log.h"
#include "misc.h"
#include "phv.h"

Phv Phv::phv;
const Phv::Register Phv::Slice::invalid("<bad>", Phv::Register::NORMAL, 0, ~0, 0);

void Phv::init_phv(target_t target_type) {
    if (target) {
        BUG_CHECK(target->type() == target_type);  // sanity check
        return; }
    switch (target_type) {
#define INIT_FOR_TARGET(TARGET)                                         \
    case Target::TARGET::tag:                                           \
        target = new Target::TARGET::Phv;                               \
        break;
    FOR_ALL_TARGETS(INIT_FOR_TARGET)
    default:
        BUG(); }
#undef INIT_FOR_TARGET
    target->init_regs(*this);
}

void Phv::start(int lineno, VECTOR(value_t) args) {
    init_phv(options.target);
    // The only argument to phv is the thread.  We allow phv section with no thread argument
    // which defines aliases for all threads.  Does that really make sense when threads can't
    // share registers?  We never use this capability in the compiler.
    if (args.size > 1 ||
        (args.size == 1 && args[0] != "ingress" && args[0] != "egress"
                        && (args[0] != "ghost" || options.target < JBAY)))
        error(lineno, "phv can only be ingress%s or egress",
              (options.target >= JBAY ? ", ghost" : 0));
}

int Phv::addreg(gress_t gress, const char *name, const value_t &what, int stage, int max_stage) {
    std::string phv_name = name;
    remove_name_tail_range(phv_name);
    if (stage == -1 && what.type == tMAP) {
        int rv = 0;
        for (auto &kv : what.map) {
            auto &key = kv.key.type == tCMD && kv.key.vec.size > 1 && kv.key == "stage"
                ? kv.key[1] : kv.key;
            if (CHECKTYPE2(key, tINT, tRANGE)) {
                if (key.type == tINT)
                    rv |= addreg(gress, name, kv.value, key.i);
                else
                    rv |= addreg(gress, name, kv.value, key.lo, key.hi); } }
        int size = -1;
        PerStageInfo *prev = 0;
        for (auto &ch : names[gress].at(name)) {
            if (prev) {
                if (prev->max_stage >= ch.first) {
                    if (prev->max_stage != INT_MAX)
                        error(what.lineno, "Overalpping assignments in stages %d..%d for %s",
                              ch.first, prev->max_stage, name);
                    prev->max_stage = ch.first - 1; } }
            prev = &ch.second;
            if (size < 0)
                size = ch.second.slice->size();
            else if (size != ch.second.slice->size() && size > 0) {
                error(what.lineno, "Inconsitent sizes for %s", name);
                size = 0; } }
        if (prev && prev->max_stage >= Target::NUM_MAU_STAGES())
            prev->max_stage = INT_MAX;
        add_phv_field_sizes(gress, phv_name, size);
        return rv; }
    if (!CHECKTYPE2M(what, tSTR, tCMD, "register or slice"))
        return -1;
    auto reg = what.type == tSTR ? what.s : what[0].s;
    if (const Slice *sl = get(gress, stage, reg)) {
        if (sl->valid) {
            phv_use[gress][sl->reg.uid] = true;
            user_defined[&sl->reg].first = gress;
            user_defined[&sl->reg].second.push_back(name); }
        auto &reg = names[gress][name];
        if (what.type == tSTR) {
            reg[stage].slice = *sl;
        } else if (what.vec.size != 2) {
            error(what.lineno, "Syntax error, expecting bit or slice");
            return -1;
        } else if (!CHECKTYPE2M(what[1], tINT, tRANGE, "bit or slice")) {
            return -1;
        } else if (what[1].type == tINT) {
            reg[stage].slice = Slice(*sl, what[1].i, what[1].i);
        } else {
            reg[stage].slice = Slice(*sl, what[1].lo, what[1].hi); }
        reg[stage].max_stage = max_stage;
        if (!reg[stage].slice.valid) {
            error(what.lineno, "Invalid register slice");
            return -1; }
        if (stage == -1)
            add_phv_field_sizes(gress, phv_name, reg[stage].slice->size());
        return 0;
    } else {
        error(what.lineno, "No register named %s", reg);
        return -1; }
}

void Phv::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    gress_t gress = args[0] == "ingress" ? INGRESS
                  : args[0] == "egress" ? EGRESS
                  : args[0] == "ghost" && options.target >= JBAY ? GHOST
                  : (error(args[1].lineno, "Invalid thread %s", value_desc(args[1])), INGRESS);
    for (auto &kv : data.map) {
        if (!CHECKTYPE(kv.key, tSTR)) continue;
        if (kv.key == "context_json") {
            if (!CHECKTYPE(kv.value, tMAP)) continue;
            for (auto& cjkv : kv.value.map) {
                if (!CHECKTYPE(cjkv.key, tSTR)) continue;
                if (!CHECKTYPE(cjkv.value, tMAP)) continue;
                std::string name = cjkv.key.s;
                for (auto& prop : cjkv.value.map)
                    field_context_json[name][prop.key.s] = toJson(prop.value); }
        } else {
            if (get(gress, INT_MAX, kv.key.s) ||
                (!args.size && get(EGRESS, INT_MAX, kv.key.s)) ||
                (!args.size && get(GHOST, INT_MAX, kv.key.s))) {
                error(kv.key.lineno, "Duplicate phv name '%s'", kv.key.s);
                continue; }
            if (!addreg(gress, kv.key.s, kv.value) && args.size == 0) {
                addreg(EGRESS, kv.key.s, kv.value);
                if (options.target >= JBAY)
                    addreg(GHOST, kv.key.s, kv.value); } } }
}

void Phv::output_names(json::map &out) {
    for (auto &slot : phv.user_defined)
        out[std::to_string(slot.first->mau_id())] = std::string(1, "IE"[slot.second.first])
                + " [" + join(slot.second.second, ", ") + "]";
}

Phv::Ref::Ref(gress_t g, int stage, const value_t &n)
: gress_(g), stage(stage), lo(-1), hi(-1), lineno(n.lineno) {
    if (CHECKTYPE2M(n, tSTR, tCMD, "phv or register reference or slice")) {
        if (n.type == tSTR) {
            name_ = n.s;
        } else {
            name_ = n[0].s;
            if (PCHECKTYPE2M(n.vec.size == 2, n[1], tINT, tRANGE, "register slice")) {
                if (n[1].type == tINT)
                    lo = hi = n[1].i;
                else {
                    lo = n[1].lo;
                    hi = n[1].hi;
                    if (lo > hi) {
                        lo = n[1].hi;
                        hi = n[1].lo; } } } } }
}

Phv::Ref::Ref(const Phv::Register &r, gress_t gr, int l, int h)
: gress_(gr), stage(0), name_(r.name), lo(l), hi(h < 0 ? l : h), lineno(-1) { }

bool Phv::Ref::merge(const Phv::Ref &r) {
    if (r.name_ != name_ || r.gress_ != gress_) return false;
    if (lo < 0) return true;
    if (r.lo < 0) {
        lo = hi = -1;
        return true; }
    if (r.hi+1 < lo || hi+1 < r.lo) return false;
    if (r.lo < lo) lo = r.lo;
    if (r.hi > hi) {
        lineno = r.lineno;
        hi = r.hi; }
    return true;
}

void merge_phv_vec(std::vector<Phv::Ref> &vec, const Phv::Ref &r) {
    int merged = -1;
    for (int i = 0; (unsigned)i < vec.size(); i++) {
        if (merged >= 0) {
            if (vec[merged].merge(vec[i])) {
                vec.erase(vec.begin()+i);
                --i; }
        } else if (vec[i].merge(r))
            merged = i; }
    if (merged < 0)
        vec.push_back(r);
}

void merge_phv_vec(std::vector<Phv::Ref> &v1, const std::vector<Phv::Ref> &v2) {
    for (auto &r : v2)
        merge_phv_vec(v1, r);
}

std::vector<Phv::Ref> split_phv_bytes(const Phv::Ref &r) {
    std::vector<Phv::Ref> rv;
    const auto &sl = *r;
    for (unsigned byte = sl.lo/8U; byte <= sl.hi/8U; byte++) {
        int lo = byte*8 - sl.lo;
        int hi = lo + 7;
        if (lo < 0) lo = 0;
        if (hi >= (int)sl.size()) hi = sl.size() - 1;
        rv.emplace_back(r, lo, hi); }
    return rv;
}

std::vector<Phv::Ref> split_phv_bytes(const std::vector<Phv::Ref> &v) {
    std::vector<Phv::Ref> rv;
    for (auto &r : v)
        append(rv, split_phv_bytes(r));
    return rv;
}

std::string Phv::Ref::toString() const {
    std::stringstream str;
    str << *this;
    return str.str();
}

void Phv::Ref::dbprint(std::ostream &out) const {
    out << name_;
    if (lo >= 0) {
        out << '(' << lo;
        if (hi != lo) out << ".." << hi;
        out << ')'; }
    Slice sl(**this);
    if (sl.valid) {
        out << '[';
        sl.dbprint(out);
        out << ']'; }
}

std::string Phv::Ref::desc() const {
    return toString();
}

std::string Phv::Slice::toString() const {
    std::stringstream str;
    str << *this;
    return str.str();
}

void Phv::Slice::dbprint(std::ostream &out) const {
    if (valid) {
        out << reg.name;
        if (lo != 0 || hi != reg.size-1) {
            out << '(' << lo;
            if (hi != lo) out << ".." << hi;
            out << ')'; }
    } else
        out << "<invalid>";
}

std::string Phv::db_regset(const bitvec &s) {
    std::string rv;
    for (int reg : s) {
        if (!rv.empty()) rv += ", ";
        rv += Phv::reg(reg)->name; }
    return rv;
}


// For snapshot, the driver (generate pd script) generates a buffer of all phv
// fields and indexes through the buffer with a position offset to determine its
// location. It assumes the phv fields are arranged with the pov fields at the
// end. To maintain this ordering while generating the position offsets for each
// phv field, we initially generate 2 separate maps for normal and pov phv
// fields. We loop through the normap phv map first and then the pov phv map
// adding field sizes. The fields are byte aligned and put into 8/16/32 bit
// containers.
int Phv::get_position_offset(gress_t gress, std::string name) {
    int position_offset = 0;
    for (auto f : phv_field_sizes[gress]) {
        if (f.first == name) return position_offset;
        auto bytes_to_add = (f.second + 7)/8U;
        if (bytes_to_add == 3) bytes_to_add++;
        position_offset += bytes_to_add; }
    for (auto f : phv_pov_field_sizes[gress]) {
        if (f.first == name) return position_offset;
        // POV should be single bit
        BUG_CHECK(f.second == 1);
        position_offset += 1; }
    return 0;
}

// Output function sets the 'phv_allocation' node in context json Contains info
// on phv containers per gress (INGRESS/EGRESS) per stage Currently the phv
// containers are assumed to be present in all stages hence are replicated in
// each stage. Support for liveness indication for each container must be added
// (in assembly syntax/compiler) to set per stage phv containers correctly.
void Phv::output(json::map &ctxt_json) {
    json::vector &phv_alloc = ctxt_json["phv_allocation"];
    for (int i = 0; i < Target::NUM_MAU_STAGES(); i++) {
        json::map phv_alloc_stage;
        json::vector &phv_alloc_stage_ingress = phv_alloc_stage["ingress"] = json::vector();
        json::vector &phv_alloc_stage_egress = phv_alloc_stage["egress"] = json::vector();
        for (auto &slot : phv.user_defined) {
            unsigned phv_number = slot.first->uid;
            unsigned phv_container_size = slot.first->size;
            gress_t gress = slot.second.first;
            json::map phv_container;
            phv_container["phv_number"] = phv_number;
            phv_container["container_type"] = slot.first->type_to_string();
            json::vector &phv_records = phv_container["records"] = json::vector();
            for (auto field_name : slot.second.second) {
                unsigned phv_lsb = 0, phv_msb = 0;
                unsigned field_lo = 0;
                int field_size = 0;
                json::map phv_record;
                auto sl = get(gress, i, field_name);
                if (!sl) continue;
                phv_lsb = sl->lo;
                phv_msb = sl->hi;
                field_lo = remove_name_tail_range(field_name, &field_size);
                auto field_width = get_phv_field_size(gress, field_name);
                if (field_size == 0) field_size = field_width;
                phv_record["position_offset"] = get_position_offset(gress, field_name);
                phv_record["field_name"] = field_name;
                phv_record["field_msb"] = field_lo + field_size - 1;
                phv_record["field_lsb"] = field_lo;
                // Pass through per-field context_json information from the compiler.
                if (field_context_json.count(slot.first->name)) {
                    auto &container_json = field_context_json.at(slot.first->name);
                    if (container_json.count(field_name))
                        phv_record.merge(container_json[field_name]);
                }
                auto field_width_bytes = (field_width + 7)/8U;
                phv_record["field_width"] = field_width_bytes;
                phv_record["phv_msb"] = phv_msb;
                phv_record["phv_lsb"] = phv_lsb;
                // FIXME-P4C: 'is_compiler_generated' is set to false for all
                // fields except POV as there is no sure way of knowing from
                // current assembly syntax whether the field is in the header or
                // generated by the compiler. This will require additional
                // assembly syntax to convey the same. Driver does not use
                // is_compiler_generated (other than requiring it).  p4i does
                // use it for display purposes.
                phv_record["is_compiler_generated"] = false;
                phv_record["is_pov"] = false;
                if (field_name.find(".$valid") != std::string::npos) {
                    phv_record["is_pov"] = true;
                    phv_record["is_compiler_generated"] = true;
                    phv_record["field_width"] = 0;
                    phv_record["position_offset"] = 0;
                    /* Now that we know that this record is representing a POV, overwrite the
                     * phv_record to call it "POV" and get rid of "$valid" */
                    phv_record["field_name"] = "POV";
                    json::vector &pov_headers = phv_record["pov_headers"] = json::vector();
                    json::map pov_header;
                    pov_header["bit_index"] = phv_lsb;
                    pov_header["position_offset"] = get_position_offset(gress, field_name);
                    remove_aug_names(field_name);
                    pov_header["header_name"] = field_name;
                    // FIXME: Checks for reserved POV bits, not supported?
                    pov_header["hidden"] = false;;
                    pov_headers.push_back(std::move(pov_header)); }
                phv_records.push_back(std::move(phv_record)); }
            phv_container["word_bit_width"] = phv_container_size;
            if (gress == INGRESS) {
                phv_alloc_stage_ingress.push_back(std::move(phv_container));
            } else if (gress == EGRESS) {
                phv_alloc_stage_egress.push_back(std::move(phv_container));
            } else if (gress == GHOST) {
                /* FIXME -- deal with ghost phv */ } }
        phv_alloc_stage["stage_number"] = i;
        phv_alloc.push_back(std::move(phv_alloc_stage)); }
    // FIXME: Fix json clone method to do above loops more efficiently
    //for (int i = 0; i < Target::NUM_MAU_STAGES(); i++) {
    //    phv_alloc_stage["stage_number"] = i;
    //    phv_alloc.push_back(std::move(phv_alloc_stage.clone())); }
}

#include "tofino/phv.cpp"
#if HAVE_JBAY
#include "jbay/phv.cpp"
#endif // HAVE_JBAY
