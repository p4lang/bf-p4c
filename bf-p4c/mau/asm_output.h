#ifndef _TOFINO_MAU_ASM_OUTPUT_H_
#define _TOFINO_MAU_ASM_OUTPUT_H_

#include "default_next.h"
#include "resource.h"
#include "lib/log.h"
#include "tofino/common/asm_output.h"
#include "memories.h"

class PhvInfo;

class MauAsmOutput : public MauInspector {
    const PhvInfo       &phv;
    DefaultNext         default_next;
    const IR::Tofino::Pipe *pipe;
    std::map<std::pair<gress_t, int>, std::vector<const IR::MAU::Table *>>      by_stage;
    profile_t init_apply(const IR::Node *root) override {
        root->apply(default_next);
        return MauInspector::init_apply(root); }
    bool preorder(const IR::Tofino::Pipe *p) override {
        pipe = p;
        return true; }
    bool preorder(const IR::MAU::Table *tbl) override {
        by_stage[std::make_pair(tbl->gress, tbl->logical_id/16U)].push_back(tbl);
        return true; }
    friend std::ostream &operator<<(std::ostream &, const MauAsmOutput &);
    class TableMatch;
    // class ImmedFormat;
    // class ActionDataFormat;
    void emit_ixbar(std::ostream &out, indent_t, const IXBar::Use &,
            const Memories::Use *, const TableMatch *, bool hash_action,
            bool is_sel = false, const IR::ActionSelector *as = nullptr) const;
    void emit_ixbar_gather_bytes(const vector<IXBar::Use::Byte> &use,
                                 map<int, map<int, Slice>> &sort) const;
    void emit_ixbar_ways(std::ostream &out, indent_t indent,
             const IXBar::Use &use, const Memories::Use *mem, bool is_sel) const;
    void emit_ixbar_hash_dist(std::ostream &out, indent_t indent,
             const IXBar::Use &use) const;
    void emit_ixbar_hash_table(int hash_table, vector<Slice> &match_data,
            vector<Slice> &ghost, const TableMatch *fmt, map<int, map<int, Slice>> &sort) const;
    void emit_ixbar_hash(std::ostream &out, indent_t indent, vector<Slice> &match_data,
            vector<Slice> &ghost, const IXBar::Use &use, int hash_group,
            const IR::ActionSelector *as) const;
    void emit_ixbar_hash_dist_hash(std::ostream &out, indent_t indent,
            vector<Slice> &match_data, vector<Slice> &ghost,
            const IXBar::Use::HashDist &hash_dist) const;
    void emit_memory(std::ostream &out, indent_t, const Memories::Use &) const;
    void emit_gateway(std::ostream &out, indent_t gw_indent, const IR::MAU::Table *tbl,
             bool hash_action, cstring next_hit, cstring &gw_miss) const;
    void emit_hash_action_gateway(std::ostream &out, indent_t gw_indent,
            const IR::MAU::Table *tbl) const;
    void emit_table_format(std::ostream &out, indent_t, const TableFormat::Use &use,
            const TableMatch *tm, bool ternary) const;
    void emit_table(std::ostream &out, const IR::MAU::Table *tbl) const;
    std::string find_indirect_index(const IR::MAU::Table *tbl, const IR::Attached *at) const;
    void emit_table_indir(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    void emit_action_data_format(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::Action *af) const;
    void emit_action_data_alias(std::ostream &out, indent_t, const IR::MAU::Table *tbl,
            const IR::MAU::Action *af) const;
    void emit_action_data_bus(std::ostream &out, indent_t, const IR::MAU::Table *tbl) const;
    class EmitAction;
    class EmitAttached;
    class UnattachedName;

 public:
    explicit MauAsmOutput(const PhvInfo &p) : phv(p) {}
};

#endif /* _TOFINO_MAU_ASM_OUTPUT_H_ */
