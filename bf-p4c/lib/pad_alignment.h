#ifndef PAD_ALIGNMENT_H_
#define PAD_ALIGNMENT_H_

static int getAlignment(int bitSize) {
    int nextByteBoundary = 8 * ((bitSize + 7) / 8);
    return (nextByteBoundary - bitSize);
}

#endif  /* PAD_ALIGNMENT_H_ */
