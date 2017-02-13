#ifndef _TOFINO_MAU_TABLE_LAYOUT_H_
#define _TOFINO_MAU_TABLE_LAYOUT_H_

#include "mau_visitor.h"
class PhvInfo;

class HashDistReq {
    bool required = false;
    const IR::Primitive *instr;
    const IR::Attached *attached;
 public:
    HashDistReq(bool r, const IR::Primitive *i, const IR::Attached *at)
        : required(r), instr(i), attached(at) {}
    bool is_required() const { return required; }
    const IR::Attached *get_attached() const { return attached; }
    const IR::Primitive *get_instr() const { return instr; }
    bool is_address() const {
        if (attached != nullptr)
            if (attached->is<IR::MAU::MAUCounter>() || attached->is<IR::MAU::MAUMeter>())
                return true;
        return false; 
    }
    bool is_immediate() const {
        if (instr != nullptr)
            if (instr->name == "modify_field_with_hash_based_offset");
                return true;
        return false;
    }
    int bits_required(const PhvInfo &phv) const;
};

class HashDistChoices {
 public:
    ordered_map<cstring, vector<HashDistReq>> total_hash_dist_reqs;
    vector<HashDistReq> get_hash_dist_req(const IR::MAU::Table *t) const {
        vector<HashDistReq> empty;
        if (t == nullptr)
            return empty;
        if (total_hash_dist_reqs.find(t->name) == total_hash_dist_reqs.end())
            return empty;
        return total_hash_dist_reqs.at(t->name);
    }
};

class TableLayout : public MauModifier, Backtrack {
    const PhvInfo &phv;
    HashDistChoices &hdc;
    bool alloc_done = false;
    profile_t init_apply(const IR::Node *root) override;
    bool backtrack(trigger &trig) override;
    bool preorder(IR::MAU::Table *tbl) override;
    void setup_match_layout(IR::MAU::Table::Layout &, const IR::MAU::Table *);
    void setup_gateway_layout(IR::MAU::Table::Layout &, IR::MAU::Table *);
    void setup_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved,
                              bool has_action_profile);
    void setup_ternary_layout_options(IR::MAU::Table *tbl, int immediate_bytes_reserved,
                                      bool has_action_profile);
    void setup_layout_option_no_match(IR::MAU::Table *tbl, int immediate_bytes_reserved);
 public:
    explicit TableLayout(const PhvInfo &phv, HashDistChoices &hdc) : phv(phv), hdc(hdc) {}
};

#endif /* _TOFINO_MAU_TABLE_LAYOUT_H_ */
