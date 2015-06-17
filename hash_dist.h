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
    int         lineno = -1;
    int         hash_group = -1, id = -1;
    int         shift = 0, mask = 0;
    //HashDistribution() = default;
    HashDistribution(value_t &v);
    HashDistribution(int id, value_t &data);
    static void parse(std::vector<HashDistribution> &out, value_t &v);
    void pass1(Table *tbl);
    void write_regs(Stage *, gress_t, int, bool);
};

#endif /* _hash_dist_h_ */
