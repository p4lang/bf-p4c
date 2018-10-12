#ifndef _power_ctl_h_
#define _power_ctl_h_

#include "misc.h"

/* power_ctl is weirdly encoded!
 * As far as I can tell, it actually walks like this:
 * -[1:0] dimension controls hi-lo for each 8/16/32b type. In other words,
 *    [0] = 8b[31~0], 16b[47~0], 32b[31~0] and [1] = 8b[63~32], 16b[95~48], 32[63~32].
 * -Within the wider dimension, [13:0] = 112b vector, where [31:0] = control for
 *  32b section (array slice 3~0), [63:32] = control for 8b section (array slice 7~4),
 *  [111:64] = control for 16b section (array slice 13~8)
 *
 * Yes, Jay's decription of how the [1~0][13~0] translates to 224b is correct.
 * The [1~0] index discriminates phv words going to the left side alu's [0]
 * vs the right side ones [1]. Within each container size, the bottom 32
 * (or 48 for 16b) are on the left and the top half ones are on the right.
 * Pat
 *
 * CSR DESCRIPTION IS WRONG!!!
 */

template <int I>
void set_power_ctl_reg(checked_array<2, checked_array<16, ubits<I>>> &power_ctl, int reg) {
    int side = 0;
    switch (reg/(I*8)) {
    case 1: // 8 bit
        reg -= I*8;
        side = reg / (I*4);
        reg = (reg % (I*4)) + (I*4);
        break;
    case 2: case 3: // 16 bit
        reg -= I*16;
        side = reg / (I*6);
        reg = (reg % (I*6)) + (I*8);
        break;
    case 0: // 32 bit
        side = reg / (I*4);
        reg = (reg % (I*4));
        break;
    default:
        BUG(); }
    power_ctl[side][reg/I] |= 1U << reg%I;
}

#endif /* _power_ctl_h_ */
