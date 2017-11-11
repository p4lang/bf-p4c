#ifndef BF_P4C_MAU_ASM_OUTPUT_H_
#define BF_P4C_MAU_ASM_OUTPUT_H_

#include <map>
#include <vector>
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/mau/default_next.h"
#include "bf-p4c/mau/memories.h"
#include "bf-p4c/mau/resource.h"
#include "lib/log.h"
#include "lib/safe_vector.h"

class PhvInfo;

class MauAsmOutput : public MauInspector {
 protected:
    const PhvInfo       &phv;
    const IR::BFN::Pipe *pipe;

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
    std::map<std::pair<gress_t, int>, std::vector<TableInstance>>      by_stage;
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
    friend std::ostream &operator<<(std::ostream &, const MauAsmOutput &);
    class TableMatch;
    void emit_ixbar(std::ostream &out, indent_t, const IXBar::Use *,
            const safe_vector<IXBar::HashDistUse> *,
            const Memories::Use *, const TableMatch *) const;
    void emit_ways(std::ostream &out, indent_t indent, const IXBar::Use *use,
            const Memories::Use *mem) const;
    void emit_hash_dist(std::ostream &out, indent_t indent,
             const safe_vector<IXBar::HashDistUse> *hash_dist_use) const;
    void emit_ixbar_gather_bytes(const safe_vector<IXBar::Use::Byte> &use,
             std::map<int, std::map<int, Slice>> &sort, bool ternary, bool atcam = false) const;
    void emit_ixbar_hash_table(int hash_table, safe_vector<Slice> &match_data,
            safe_vector<Slice> &ghost, const TableMatch *fmt,
            std::map<int, std::map<int, Slice>> &sort) const;
    void emit_ixbar_hash(std::ostream &out, indent_t indent, safe_vector<Slice> &match_data,
            safe_vector<Slice> &ghost, const IXBar::Use *use, int hash_group,
            int &ident_bits_prev_alloc) const;
    void emit_ixbar_hash_exact(std::ostream &out, indent_t indent, safe_vector<Slice> &match_data,
            safe_vector<Slice> &ghost, const IXBar::Use *use, int &ident_bits_prev_alloc) const;
    void emit_ixbar_hash_way(std::ostream &out, indent_t indent, safe_vector<Slice> &match_data,
           Slice *ghost, const IXBar::Use *use, int start_bit, int end_bit) const;
    void emit_ixbar_hash_way_select(std::ostream &out, indent_t indent,
            safe_vector<Slice> &match_data, Slice *ghost, int start_bit, int end_bit) const;
    void emit_single_ixbar(std::ostream& out, indent_t indent, const IXBar::Use *use,
            const TableMatch *fmt) const;
    void emit_memory(std::ostream &out, indent_t, const Memories::Use &) const;
    void emit_gateway(std::ostream &out, indent_t gw_indent, const IR::MAU::Table *tbl,
             bool hash_action, cstring next_hit, cstring &gw_miss) const;
    void emit_no_match_gateway(std::ostream &out, indent_t gw_indent,
            const IR::MAU::Table *tbl) const;
    void emit_table_format(std::ostream &out, indent_t, const TableFormat::Use &use,
            const TableMatch *tm, bool ternary) const;
    void emit_table_context_json(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    void emit_ternary_match(std::ostream &out, indent_t, const TableFormat::Use &use) const;
    void emit_table(std::ostream &out, const IR::MAU::Table *tbl) const;
    std::string find_indirect_index(const IR::Attached *at) const;
    void emit_table_indir(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    void emit_action_data_format(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::Action *af) const;
    void emit_action_data_alias(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::Action *af) const;
    void emit_action_data_bus(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    bool emit_idletime(std::ostream &out, indent_t indent, const IR::MAU::Table *tbl,
                       const IR::MAU::IdleTime *id) const;
    class EmitAction;
    class EmitAttached;
    class UnattachedName;

 public:
    explicit MauAsmOutput(const PhvInfo &p) : phv(p) {}
};

#endif /* BF_P4C_MAU_ASM_OUTPUT_H_ */
