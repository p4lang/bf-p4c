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
    enum { NONE=-1, IMMEDIATE_HIGH=0, IMMEDIATE_LOW=1, METER_ADDRESS=2, STATISTICS_ADDRESS=3,
           ACTION_DATA_ADDRESS=4, HASHMOD_DIVIDEND=5 };
    int         xbar_use = NONE;
    HashDistribution(int id, value_t &data, int u=NONE);
    static void parse(std::vector<HashDistribution> &out, const value_t &v, int u=NONE);
    bool compatible(HashDistribution *a);
    void pass1(Table *tbl);
    void write_regs(Table *, int, bool);
};

#endif /* _hash_dist_h_ */
