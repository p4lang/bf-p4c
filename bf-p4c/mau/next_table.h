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
};

#endif /* BF_P4C_MAU_NEXT_TABLE_H_ */
