#ifndef BF_P4C_MAU_ASM_OUTPUT_H_
#define BF_P4C_MAU_ASM_OUTPUT_H_

#include <map>
#include <set>
#include <vector>
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/mau/default_next.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/resource.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/log.h"
#include "lib/safe_vector.h"

class PhvInfo;

class MauAsmOutput : public MauInspector {
 protected:
    const PhvInfo        &phv;
    const IR::BFN::Pipe  *pipe;

 private:
    struct TableInstance {
        explicit TableInstance(const IR::MAU::Table *table)
            : tableInfo(table), phase0Info(nullptr) { }
        explicit TableInstance(const BFN::Phase0Info *phase0)
            : tableInfo(nullptr), phase0Info(phase0) { }

        const IR::MAU::Table *tableInfo;
        const BFN::Phase0Info *phase0Info;
    };

    DefaultNext         default_next;
    std::map<std::pair<gress_t, int>, std::vector<TableInstance>>       by_stage;
    ordered_map<const IR::MAU::Selector *, const Memories::Use *>       selector_memory;
    profile_t init_apply(const IR::Node *root) override {
        root->apply(default_next);
        return MauInspector::init_apply(root); }
    bool preorder(const IR::BFN::Pipe *p) override {
        pipe = p;
        if (p->phase0Info) {
            auto tableId = std::make_pair(INGRESS, 0);
            by_stage[tableId].push_back(TableInstance(p->phase0Info));
        }
        return true; }
    bool preorder(const IR::MAU::Table *tbl) override {
        auto tableId = std::make_pair(tbl->gress, tbl->logical_id/16U);
        by_stage[tableId].push_back(TableInstance(tbl));
        return true; }
    void postorder(const IR::MAU::Selector *as) override {
        auto tbl = findContext<IR::MAU::Table>();
        if (tbl->is_placed()) {
          auto unique_id = tbl->unique_id(as);
          if (tbl->resources->memuse.count(unique_id))
              selector_memory[as] = &tbl->resources->memuse.at(unique_id);
        }
    }
    bool preorder(const IR::MAU::StatefulAlu *) override { return false; }
    friend std::ostream &operator<<(std::ostream &, const MauAsmOutput &);
    class TableMatch;
    void emit_ixbar(std::ostream &out, indent_t, const IXBar::Use *,
                    const safe_vector<IXBar::HashDistUse> *,
                    const Memories::Use *, const TableMatch *, bool ternary) const;
    void emit_ways(std::ostream &out, indent_t indent, const IXBar::Use *use,
            const Memories::Use *mem) const;
    void emit_hash_dist(std::ostream &out, indent_t indent,
             const safe_vector<IXBar::HashDistUse> *hash_dist_use) const;
    void emit_ixbar_gather_bytes(const safe_vector<IXBar::Use::Byte> &use,
             std::map<int, std::map<int, Slice>> &sort,
             std::map<int, std::map<int, Slice>> &midbytes, bool ternary,
             bool atcam = false) const;
    void emit_ixbar_hash_table(int hash_table, safe_vector<Slice> &match_data,
            safe_vector<Slice> &ghost, const TableMatch *fmt,
            std::map<int, std::map<int, Slice>> &sort) const;
    void emit_ixbar_gather_map(std::map<int, Slice> &match_data_map,
            safe_vector<Slice> &match_data,
            const safe_vector<PHV::FieldSlice> &field_list_order, int &total_bits) const;
    void emit_ixbar_hash(std::ostream &out, indent_t indent, safe_vector<Slice> &match_data,
            safe_vector<Slice> &ghost, const IXBar::Use *use, int hash_group,
            int &ident_bits_prev_alloc, const IR::Expression *hd_expr) const;
    void emit_ixbar_hash_exact(std::ostream &out, indent_t indent, safe_vector<Slice> &match_data,
            safe_vector<Slice> &ghost, const IXBar::Use *use, int hash_group,
            int &ident_bits_prev_alloc) const;
    void emit_ixbar_hash_atcam(std::ostream &out, indent_t indent, safe_vector<Slice> &ghost,
            const IXBar::Use *use, int hash_group) const;
    void emit_ixbar_hash_way(std::ostream &out, indent_t indent, safe_vector<Slice> &match_data,
           Slice *ghost, const IXBar::Use *use, int hash_group, int start_bit, int end_bit) const;
    void emit_ixbar_hash_way_select(std::ostream &out, indent_t indent,
            safe_vector<Slice> &match_data, Slice *ghost, int start_bit, int end_bit) const;
    void emit_ixbar_hash_dist_ident(std::ostream &out, indent_t indent,
            safe_vector<Slice> &match_data, const IXBar::Use::HashDistHash &hdh,
             const IR::Expression *hd_expr) const;
    void emit_ixbar_meter_alu_hash(std::ostream &out, indent_t indent,
            safe_vector<Slice> &match_data, const IXBar::Use::MeterAluHash &mah,
            const safe_vector<PHV::FieldSlice> &field_list_order) const;
    void emit_single_ixbar(std::ostream& out, indent_t indent, const IXBar::Use *use,
            const TableMatch *fmt, const IR::Expression *hd_expr = nullptr) const;
    void emit_memory(std::ostream &out, indent_t, const Memories::Use &) const;
    void emit_gateway(std::ostream &out, indent_t gw_indent, const IR::MAU::Table *tbl,
             bool hash_action, cstring next_hit, cstring &gw_miss) const;
    void emit_no_match_gateway(std::ostream &out, indent_t gw_indent,
            const IR::MAU::Table *tbl) const;
    void emit_table_format(std::ostream &out, indent_t, const TableFormat::Use &use,
            const TableMatch *tm, bool ternary, bool no_match) const;
    void emit_table_context_json(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    void emit_ternary_match(std::ostream &out, indent_t, const TableFormat::Use &use) const;
    void emit_atcam_match(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    void emit_table(std::ostream &out, const IR::MAU::Table *tbl, int stage, gress_t gress) const;
    void emit_static_entries(std::ostream &out, indent_t indent, const IR::MAU::Table *tbl) const;
    /*
    std::string find_indirect_index(const IR::MAU::AttachedMemory *am, bool index_only,
            const IR::MAU::BackendAttached *ba, const IR::MAU::Table *tbl) const;
    */
    void emit_table_indir(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::TernaryIndirect *ti) const;
    void emit_action_data_format(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::Action *af) const;
    void emit_action_data_alias(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::Action *af) const;
    void emit_action_data_bus(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
                              bitvec source) const;
    bool emit_idletime(std::ostream &out, indent_t indent, const IR::MAU::Table *tbl,
                       const IR::MAU::IdleTime *id) const;
    cstring find_attached_name(const IR::MAU::Table *tbl,
           const IR::MAU::AttachedMemory *am) const;
    std::string indirect_address(const IR::MAU::AttachedMemory *) const;
    std::string indirect_pfe(const IR::MAU::AttachedMemory *) const;
    std::string stateful_counter_addr(IR::MAU::StatefulUse use) const;
    std::string build_call(const IR::MAU::AttachedMemory *at_mem,
        const IR::MAU::BackendAttached *ba, const IR::MAU::Table *tbl) const;
    std::string build_sel_len_call(const IR::MAU::Selector *as) const;
    class EmitAction;
    class EmitAttached;
    class UnattachedName;

 public:
    explicit MauAsmOutput(const PhvInfo &p) : phv(p) {}
};

#endif /* BF_P4C_MAU_ASM_OUTPUT_H_ */
