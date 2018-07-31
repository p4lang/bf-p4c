#ifndef PAD_ALIGNMENT_H_
#define PAD_ALIGNMENT_H_

#include "lib/algorithm.h"

static int getAlignment(int bitSize) {
    int nextByteBoundary = 8 * ROUNDUP(bitSize, 8);
    return (nextByteBoundary - bitSize);
}

#endif  /* PAD_ALIGNMENT_H_ */
