#include "phv_fields.h"
#include "lib/bitops.h"

void repack_metadata(PhvInfo &phv) {
    for (auto &field : phv) {
        if (!field.metadata || field.pov) continue;
        std::map<PHV::Container, uint64_t>      uses;
        bool                                    repack = false;
        for (auto &alloc : field.alloc) {
            if (uses.count(alloc.container))
                repack = true;
            uint64_t bits = ((1UL << alloc.width) - 1) << alloc.container_bit;
            if (uses[alloc.container] & bits)
                BUG("metadata %s uses bits in %s multiple times", field.name,
                    alloc.container.toString());
            uses[alloc.container] |= bits; }
        if (!repack) continue;
        field.alloc.clear();
        int width_left = field.size;
        for (auto &c : uses) {
            unsigned bits = c.second;
            while (bits) {
                int hi = floor_log2(bits);
                int lo = floor_log2(bits ^ ((1UL << (hi+1)) - 1)) + 1;
                int width = hi - lo + 1;
                field.alloc.emplace_back(c.first, width_left - width, lo, width);
                width_left -= width;
                bits &= ~(((1UL << width) - 1) << lo); } }
        if (width_left != 0)
            BUG("wrong number of bits for %s", field.name); }
}
