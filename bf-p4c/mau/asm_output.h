#ifndef BF_P4C_MAU_ASM_OUTPUT_H_
#define BF_P4C_MAU_ASM_OUTPUT_H_

#include <map>
#include <set>
#include <vector>
#include "bf-p4c/bf-p4c-options.h"
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/mau/default_next.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/mau/jbay_next_table.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/safe_vector.h"

class PhvInfo;

class MauAsmOutput : public MauInspector {
 protected:
    const PhvInfo       &phv;
    const IR::BFN::Pipe *pipe;
    const NextTableProp *nxt_tbl;
    const BFN_Options   &options;

 private:
    struct TableInstance {
        explicit TableInstance(const IR::MAU::Table *table)
            : tableInfo(table) { }

        const IR::MAU::Table *tableInfo;
    };

    DefaultNext         default_next;
    std::map<std::pair<gress_t, int>, std::vector<TableInstance>>       by_stage;
    ordered_map<std::pair<int, const IR::MAU::Selector *>,
                std::pair<UniqueId, const Memories::Use *>>     selector_memory;
    profile_t init_apply(const IR::Node *root) override {
        root->apply(default_next);
        return MauInspector::init_apply(root); }
    bool preorder(const IR::MAU::Table *tbl) override {
        auto tableId = std::make_pair(tbl->gress, tbl->logical_id/16U);
        by_stage[tableId].push_back(TableInstance(tbl));
        return true; }
    void postorder(const IR::MAU::Selector *as) override {
        visitAgain();
        auto tbl = findContext<IR::MAU::Table>();
        if (tbl->is_placed()) {
            auto &unattached = tbl->resources->memuse.at(tbl->unique_id()).unattached_tables;
            auto unique_id = tbl->unique_id(as);
            if (!unattached.count(unique_id) && tbl->resources->memuse.count(unique_id)) {
                selector_memory[std::make_pair(tbl->stage(), as)] =
                std::make_pair(unique_id, &tbl->resources->memuse.at(unique_id)); } } }
    bool preorder(const IR::MAU::StatefulAlu *) override { return false; }
    friend std::ostream &operator<<(std::ostream &, const MauAsmOutput &);

 public:
    class TableMatch;
    class NextTableSet;

 private:
    void emit_ixbar(std::ostream &out, indent_t, const IXBar::Use *, const IXBar::Use *,
        const safe_vector<IXBar::HashDistUse> *, const Memories::Use *, const TableMatch *,
        const IR::MAU::Table *, bool ternary) const;
    void emit_ways(std::ostream &out, indent_t indent, const IXBar::Use *use,
            const Memories::Use *mem) const;
    void emit_hash_dist(std::ostream &out, indent_t indent,
        const safe_vector<IXBar::HashDistUse> *hash_dist_use, bool hashmod) const;
    void emit_ixbar_gather_bytes(const safe_vector<IXBar::Use::Byte> &use,
        std::map<int, std::map<int, Slice>> &sort, std::map<int, std::map<int, Slice>> &midbytes,
        const IR::MAU::Table *tbl, bool ternary, bool atcam = false) const;
    void emit_ixbar_hash_table(int hash_table, safe_vector<Slice> &match_data,
            safe_vector<Slice> &ghost, const TableMatch *fmt,
            std::map<int, std::map<int, Slice>> &sort) const;
    void emit_ixbar_gather_map(std::map<int, Slice> &match_data_map,
            std::map<le_bitrange, const IR::Constant*> &constant_map,
            safe_vector<Slice> &match_data,
            const safe_vector<const IR::Expression *> &field_list_order, int &total_bits) const;
    void emit_ixbar_hash(std::ostream &out, indent_t indent, safe_vector<Slice> &match_data,
            safe_vector<Slice> &ghost, const IXBar::Use *use, int hash_group,
            int &ident_bits_prev_alloc) const;
    void ixbar_hash_exact_info(int &min_way_size, int &min_way_slice, const IXBar::Use *use,
        int hash_group, std::map<int, bitvec> &slice_to_select_bits) const;
    void emit_ixbar_match_func(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, Slice *ghost, le_bitrange hash_bits) const;
    void ixbar_hash_exact_bitrange(Slice ghost_slice, int min_way_size,
        le_bitrange non_rotated_slice, le_bitrange comp_slice, int initial_lo_bit,
        safe_vector<std::pair<le_bitrange, Slice>> &ghost_positions) const;
    void emit_ixbar_hash_atcam(std::ostream &out, indent_t indent, safe_vector<Slice> &ghost,
            const IXBar::Use *use, int hash_group) const;
    void emit_ixbar_hash_exact(std::ostream &out, indent_t indent,
        safe_vector<Slice> &match_data, safe_vector<Slice> &ghost, const IXBar::Use *use,
        int hash_group, int &ident_bits_prev_alloc) const;
    void emit_ixbar_hash_dist_ident(std::ostream &out, indent_t indent,
            safe_vector<Slice> &match_data, const IXBar::Use::HashDistHash &hdh,
            const safe_vector<const IR::Expression *> &field_list_order) const;
    void emit_ixbar_meter_alu_hash(std::ostream &out, indent_t indent,
            safe_vector<Slice> &match_data, const IXBar::Use::MeterAluHash &mah,
            const safe_vector<const IR::Expression *> &field_list_order) const;
    void emit_ixbar_proxy_hash(std::ostream &out, indent_t indent, safe_vector<Slice> &match_data,
            const IXBar::Use::ProxyHashKey &ph,
            const safe_vector<const IR::Expression *> &field_list_order) const;

    void emit_single_ixbar(std::ostream& out, indent_t indent, const IXBar::Use *use,
            const TableMatch *fmt, const IR::MAU::Table *) const;
    void emit_memory(std::ostream &out, indent_t, const Memories::Use &,
        const IR::MAU::Table::Layout *l = nullptr, const TableFormat::Use *f = nullptr) const;
    bool emit_gateway(std::ostream &out, indent_t gw_indent, const IR::MAU::Table *tbl,
             bool hash_action, NextTableSet next_hit, NextTableSet &gw_miss) const;
    void emit_no_match_gateway(std::ostream &out, indent_t gw_indent,
            const IR::MAU::Table *tbl) const;
    void emit_table_format(std::ostream &out, indent_t, const TableFormat::Use &use,
            const TableMatch *tm, bool ternary, bool no_match) const;
    void emit_table_context_json(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    void emit_ternary_match(std::ostream &out, indent_t, const TableFormat::Use &use) const;
    void emit_atcam_match(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    void emit_table(std::ostream &out, const IR::MAU::Table *tbl, int stage, gress_t gress) const;
    void emit_static_entries(std::ostream &out, indent_t indent, const IR::MAU::Table *tbl) const;
    void next_table_non_action_map(const IR::MAU::Table *,
            safe_vector<NextTableSet> &next_table_map) const;
    void emit_table_indir(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::TernaryIndirect *ti) const;
    void emit_action_data_format(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::Action *af) const;
    void emit_single_alias(std::ostream &out, cstring &sep, const ActionData::Parameter *param,
            le_bitrange adt_range, cstring alias,
            safe_vector<ActionData::Argument> &full_args, cstring action_name) const;
    void emit_action_data_alias(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::Action *af) const;
    void emit_action_data_bus(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
                              bitvec source) const;
    bool emit_idletime(std::ostream &out, indent_t indent, const IR::MAU::Table *tbl,
                       const IR::MAU::IdleTime *id) const;
    void emit_indirect_res_context_json(std::ostream &out, indent_t indent,
                        const IR::MAU::Table *tbl) const;
    void emit_always_init_action(std::ostream &out, indent_t,
                                 const std::pair<gress_t, int>& stageGress) const;
    cstring find_attached_name(const IR::MAU::Table *tbl,
           const IR::MAU::AttachedMemory *am) const;
    std::string indirect_address(const IR::MAU::AttachedMemory *) const;
    std::string indirect_pfe(const IR::MAU::AttachedMemory *) const;
    std::string stateful_counter_addr(IR::MAU::StatefulUse use) const;
    std::string build_call(const IR::MAU::AttachedMemory *at_mem,
        const IR::MAU::BackendAttached *ba, const IR::MAU::Table *tbl) const;
    std::string build_sel_len_call(const IR::MAU::Selector *as) const;
    std::string build_meter_color_call(const IR::MAU::Meter *mtr,
        const IR::MAU::BackendAttached *ba, const IR::MAU::Table *tbl) const;
    NextTableSet next_for(const IR::MAU::Table *tbl, cstring what) const;

    class EmitAction;
    class EmitAttached;
    class UnattachedName;
    class EmitHashExpression;

 public:
    MauAsmOutput(const PhvInfo &phv, const IR::BFN::Pipe *pipe, const NextTableProp *nxts,
                 const BFN_Options &options)
            : phv(phv), pipe(pipe), nxt_tbl(nxts), options(options) { }
};

#endif /* BF_P4C_MAU_ASM_OUTPUT_H_ */
