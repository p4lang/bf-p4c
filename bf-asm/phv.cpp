#include <iostream>
#include "log.h"
#include "misc.h"
#include "phv.h"

Phv Phv::phv;
const Phv::Register Phv::Slice::invalid("<bad>", Phv::Register::NORMAL, 0, ~0, 0);

void Phv::init_phv(target_t target_type) {
    if (target) {
        assert(target->type() == target_type);  // sanity check
        return; }
    switch (target_type) {
#define INIT_FOR_TARGET(TARGET)                                         \
    case Target::TARGET::tag:                                           \
        target = new Target::TARGET::Phv;                               \
        break;
    FOR_ALL_TARGETS(INIT_FOR_TARGET)
    default:
        assert(0); }
#undef INIT_FOR_TARGET
    target->init_regs(*this);
}

void Phv::start(int lineno, VECTOR(value_t) args) {
    init_phv(options.target);
    if (args.size > 1 ||
        (args.size == 1 && args[0] != "ingress" && args[0] != "egress"))
        error(lineno, "phv can only be ingress or egress");
}

int Phv::addreg(gress_t gress, const char *name, const value_t &what) {
    if (!CHECKTYPE2M(what, tSTR, tCMD, "register or slice"))
        return -1;
    auto reg = what.type == tSTR ? what.s : what[0].s;
    if (const Slice *sl = get(gress, reg)) {
        if (sl->valid) {
            phv_use[gress][sl->reg.uid] = true;
            user_defined[&sl->reg].first = gress;
            user_defined[&sl->reg].second.push_back(name); }
        if (what.type == tSTR) {
            names[gress].emplace(name, *sl);
            return 0; }
        if (what.vec.size != 2) {
            error(what.lineno, "Syntax error, expecting bit or slice");
            return -1; }
        if (!CHECKTYPE2M(what[1], tINT, tRANGE, "bit or slice")) return -1;
        if (what[1].type == tINT)
            sl = &names[gress].emplace(name, Slice(*sl, what[1].i, what[1].i)).first->second;
        else
            sl = &names[gress].emplace(name, Slice(*sl, what[1].lo, what[1].hi)).first->second;
        if (!sl->valid) {
            error(what.lineno, "Invalid register slice");
            return -1; }
        return 0;
    } else {
        error(what.lineno, "No register named %s", reg);
        return -1; }
}

void Phv::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    gress_t gress = (args.size == 1 && args[0] == "egress") ? EGRESS : INGRESS;
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
            if (get(gress, kv.key.s) || (!args.size && get(EGRESS, kv.key.s))) {
                error(kv.key.lineno, "Duplicate phv name '%s'", kv.key.s);
                continue; }
            if (!addreg(gress, kv.key.s, kv.value) && args.size == 0)
                addreg(EGRESS, kv.key.s, kv.value); } }
}

void Phv::output_names(json::map &out) {
    for (auto &slot : phv.user_defined)
        out[std::to_string(slot.first->mau_id())] = std::string(1, "IE"[slot.second.first])
                + " [" + join(slot.second.second, ", ") + "]";
}

Phv::Ref::Ref(gress_t g, const value_t &n) : gress(g), lo(-1), hi(-1), lineno(n.lineno) {
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

Phv::Ref::Ref(const Phv::Register &r) : gress(EGRESS), lo(-1), hi(-1), lineno(-1) {
    name_ = r.name;
}

bool Phv::Ref::merge(const Phv::Ref &r) {
    if (r.name_ != name_ || r.gress != gress) return false;
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


// Loop through the phv_field_sizes map and add byte sizes for each field until
// you reach the specified field. This gives the position offset for that field
// Position offset is unique for a field and is used by the driver to determine
// position of the field in the buffer it allocates for all fields.
int Phv::get_position_offset(gress_t gress, std::string name) {
    int position_offset = 0;
    for (auto f : phv_field_sizes[gress]) {
        if (f.first == name) return position_offset;
        position_offset += f.second; }
    return 0;
}

// Generate a map of phv field names and their total sizes. Iterates through all
// user defined fields and adds any field slices if present to create a map of
// phv field names and their total sizes. This map is also be used to get a
// position offset for a field.
void Phv::gen_phv_field_size_map() {
    for (auto &slot : phv.user_defined) {
        gress_t gress = slot.second.first;
        unsigned phv_container_size = slot.first->size;
        for (auto field_name : slot.second.second) {
            int field_size = 0, field_size_bytes = 0;
            unsigned field_lo = remove_name_tail_range(field_name, &field_size);
            if (field_size == 0)
                field_size = phv_container_size;
            // Fields can be stored only in 8/16/32 bit containers
            field_size_bytes = field_size/8;
            if (field_size % 8) field_size_bytes++; //round up if not byte-aligned
            if (field_size_bytes == 3) field_size_bytes++;
            if (phv_field_sizes[gress].count(field_name) == 0)
                phv_field_sizes[gress][field_name] = field_size_bytes;
            else
                phv_field_sizes[gress][field_name] += field_size_bytes; } }
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
                auto sl = get(gress, field_name);
                phv_lsb = sl->lo;
                phv_msb = sl->hi;
                field_lo = remove_name_tail_range(field_name, &field_size);
                if (field_size == 0)
                    field_size = phv_container_size;
                phv_record["position_offset"] = get_position_offset(gress, field_name);
                phv_record["field_name"] = field_name;
                phv_record["field_msb"] = field_lo + field_size - 1;
                phv_record["field_lsb"] = field_lo;
                // Pass through per-field context_json information from the compiler.
                if (field_context_json.count(field_name))
                    phv_record.merge(field_context_json.at(field_name));
                // Field width is set to total field width irrespective of current
                // field slice width
                phv_record["field_width"] = phv_field_sizes[gress][field_name];
                phv_record["phv_msb"] = phv_msb;
                phv_record["phv_lsb"] = phv_lsb;
                // FIXME: 'is_compiler_generated' is set to false as there is no
                // sure way of knowing from current assembly syntax whether the
                // field is in the header or generated by the compiler. Driver
                // possibly just ignores the fields marked 'true'.
                phv_record["is_compiler_generated"] = false;
                phv_record["is_pov"] = false;
                if (field_name.find(".$valid") != std::string::npos) {
                    phv_record["is_pov"] = true;
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
                phv_alloc_stage_egress.push_back(std::move(phv_container)); } }
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
