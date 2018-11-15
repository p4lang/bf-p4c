#ifndef _hash_dist_h_
#define _hash_dist_h_

#include "asm-types.h"
#include <vector>

class Stage;
class Table;

/* config for a hash distribution unit in match central.
 * FIXME -- need to abstract this away rather than have it be explicit
 * FIXME -- in the asm code */

struct HashDistribution {
    // FIXME -- need less 'raw' data for this */
    Table       *tbl = 0;
    int         lineno = -1;
    int         hash_group = -1, id = -1;
    int         shift = 0, mask = 0, expand = -1;
    bool        meter_pre_color = false;
    int         meter_mask_index;
    enum { IMMEDIATE_HIGH=1<<0, IMMEDIATE_LOW=1<<1, METER_ADDRESS=1<<2, STATISTICS_ADDRESS=1<<3,
           ACTION_DATA_ADDRESS=1<<4, HASHMOD_DIVIDEND=1<<5 };
    unsigned    xbar_use = 0;
    enum delay_type_t { SELECTOR=0, OTHER=1 } delay_type;
    bool        non_linear;
    HashDistribution(int id, value_t &data, unsigned  u=0);
    static void parse(std::vector<HashDistribution> &out, const value_t &v, unsigned u=0);
    bool compatible(HashDistribution *a);
    void pass1(Table *tbl, delay_type_t dt, bool nl);
    template<class REGS> void write_regs(REGS &regs, Table *);
};

#endif /* _hash_dist_h_ */
