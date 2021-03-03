#ifndef BF_P4C_MAU_NEXT_TABLE_H_
#define BF_P4C_MAU_NEXT_TABLE_H_

#include "ir/ir.h"

class NextTable : public virtual Visitor {
 public:
    virtual ordered_set<UniqueId> next_for(const IR::MAU::Table *tbl, cstring what) const = 0;
    virtual void dbprint(std::ostream &) const = 0;
    virtual const std::unordered_map<int, std::set<UniqueId>> &long_branches(UniqueId) const {
        static std::unordered_map<int, std::set<UniqueId>> empty;
        return empty; }
    virtual std::pair<ssize_t, ssize_t> get_live_range_for_lb_with_dest(UniqueId) const {
        return { -1, -1 }; }
    int long_branch_tag_for(UniqueId from, UniqueId to) const {
        for (auto &lb : long_branches(from))
            if (lb.second.count(to))
                return lb.first;
        return -1; }
};

class DynamicNextTable : public DynamicVisitor, public NextTable {
    NextTable   *pass;

 public:
    ordered_set<UniqueId> next_for(const IR::MAU::Table *tbl, cstring what) const {
        return pass->next_for(tbl, what); }
    void dbprint(std::ostream &out) const { pass->dbprint(out); }
    const std::unordered_map<int, std::set<UniqueId>> &long_branches(UniqueId id) const {
        return pass->long_branches(id); }
    std::pair<ssize_t, ssize_t> get_live_range_for_lb_with_dest(UniqueId id) const {
        return pass->get_live_range_for_lb_with_dest(id); }
    void setVisitor(NextTable *v) { DynamicVisitor::setVisitor((pass = v)); }
    DynamicNextTable *clone() const override { BUG("DynamicNextTable not cloneable"); }
};

#endif /* BF_P4C_MAU_NEXT_TABLE_H_ */
