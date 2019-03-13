#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#include "includes/tofino.p4"
#endif

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header ethernet_t ethernet;

header_type metadata_t {
    fields {
        field_1_1_1  : 1;
        field_1_1_2  : 1;
        field_1_1_3  : 1;
        field_1_1_4  : 1;
        field_1_1_5  : 1;
        field_1_1_6  : 1;
        field_1_1_7  : 1;
        field_1_1_8  : 1;
        field_1_1_9  : 1;
        field_1_1_10 : 1;
        field_1_1_11 : 1;
        field_1_1_12 : 1;
        field_1_1_13 : 1;
        field_1_1_14 : 1;
        field_1_1_15 : 1;
        field_1_1_16 : 1;

        field_1_8_1  : 8;
        field_1_8_2  : 8;
        field_1_8_3  : 8;
        field_1_8_4  : 8;
        field_1_8_5  : 8;
        field_1_8_6  : 8;
        field_1_8_7  : 8;
        field_1_8_8  : 8;
        field_1_8_9  : 8;
        field_1_8_10 : 8;
        field_1_8_11 : 8;
        field_1_8_12 : 8;
        field_1_8_13 : 8;
        field_1_8_14 : 8;
        field_1_8_15 : 8;
        field_1_8_16 : 8;

        field_1_16_1  : 16;
        field_1_16_2  : 16;
        field_1_16_3  : 16;
        field_1_16_4  : 16;
        field_1_16_5  : 16;
        field_1_16_6  : 16;
        field_1_16_7  : 16;
        field_1_16_8  : 16;
        field_1_16_9  : 16;
        field_1_16_10 : 16;
        field_1_16_11 : 16;
        field_1_16_12 : 16;
        field_1_16_13 : 16;
        field_1_16_14 : 16;
        field_1_16_15 : 16;
        field_1_16_16 : 16;

        field_1_32_1  : 32;
        field_1_32_2  : 32;
        field_1_32_3  : 32;
        field_1_32_4  : 32;
        field_1_32_5  : 32;
        field_1_32_6  : 32;
        field_1_32_7  : 32;
        field_1_32_8  : 32;
        field_1_32_9  : 32;
        field_1_32_10 : 32;
        field_1_32_11 : 32;
        field_1_32_12 : 32;
        field_1_32_13 : 32;
        field_1_32_14 : 32;
        field_1_32_15 : 32;
        field_1_32_16 : 32;

        field_2_1_1  : 1;
        field_2_1_2  : 1;
        field_2_1_3  : 1;
        field_2_1_4  : 1;
        field_2_1_5  : 1;
        field_2_1_6  : 1;
        field_2_1_7  : 1;
        field_2_1_8  : 1;
        field_2_1_9  : 1;
        field_2_1_10 : 1;
        field_2_1_11 : 1;
        field_2_1_12 : 1;
        field_2_1_13 : 1;
        field_2_1_14 : 1;
        field_2_1_15 : 1;
        field_2_1_16 : 1;

        field_2_8_1  : 8;
        field_2_8_2  : 8;
        field_2_8_3  : 8;
        field_2_8_4  : 8;
        field_2_8_5  : 8;
        field_2_8_6  : 8;
        field_2_8_7  : 8;
        field_2_8_8  : 8;
        field_2_8_9  : 8;
        field_2_8_10 : 8;
        field_2_8_11 : 8;
        field_2_8_12 : 8;
        field_2_8_13 : 8;
        field_2_8_14 : 8;
        field_2_8_15 : 8;
        field_2_8_16 : 8;

        field_2_16_1  : 16;
        field_2_16_2  : 16;
        field_2_16_3  : 16;
        field_2_16_4  : 16;
        field_2_16_5  : 16;
        field_2_16_6  : 16;
        field_2_16_7  : 16;
        field_2_16_8  : 16;
        field_2_16_9  : 16;
        field_2_16_10 : 16;
        field_2_16_11 : 16;
        field_2_16_12 : 16;
        field_2_16_13 : 16;
        field_2_16_14 : 16;
        field_2_16_15 : 16;
        field_2_16_16 : 16;

        field_2_32_1  : 32;
        field_2_32_2  : 32;
        field_2_32_3  : 32;
        field_2_32_4  : 32;
        field_2_32_5  : 32;
        field_2_32_6  : 32;
        field_2_32_7  : 32;
        field_2_32_8  : 32;
        field_2_32_9  : 32;
        field_2_32_10 : 32;
        field_2_32_11 : 32;
        field_2_32_12 : 32;
        field_2_32_13 : 32;
        field_2_32_14 : 32;
        field_2_32_15 : 32;
        field_2_32_16 : 32;
    }
}

metadata metadata_t md;

parser start {
    extract(ethernet);
    return ingress;
}

#define ACTION(w, n)                                    \
action action_##w##_##n(value) {                        \
    modify_field(md.field_1_##w##_##n, value);          \
    modify_field(md.field_2_32_16,     w##n);           \
}

ACTION(1, 1)
ACTION(1, 2)
ACTION(1, 3)
ACTION(1, 4)
ACTION(1, 5)
ACTION(1, 6)
ACTION(1, 7)
ACTION(1, 8)
ACTION(1, 9)
ACTION(1, 10)
ACTION(1, 11)
ACTION(1, 12)
ACTION(1, 13)
ACTION(1, 14)
ACTION(1, 15)
ACTION(1, 16)

ACTION(8, 1)
ACTION(8, 2)
ACTION(8, 3)
ACTION(8, 4)
ACTION(8, 5)
ACTION(8, 6)
ACTION(8, 7)
ACTION(8, 8)
ACTION(8, 9)
ACTION(8, 10)
ACTION(8, 11)
ACTION(8, 12)
ACTION(8, 13)
ACTION(8, 14)
ACTION(8, 15)
ACTION(8, 16)

ACTION(16, 1)
ACTION(16, 2)
ACTION(16, 3)
ACTION(16, 4)
ACTION(16, 5)
ACTION(16, 6)
ACTION(16, 7)
ACTION(16, 8)
ACTION(16, 9)
ACTION(16, 10)
ACTION(16, 11)
ACTION(16, 12)
ACTION(16, 13)
ACTION(16, 14)
ACTION(16, 15)
ACTION(16, 16)

ACTION(32, 1)
ACTION(32, 2)
ACTION(32, 3)
ACTION(32, 4)
ACTION(32, 5)
ACTION(32, 6)
ACTION(32, 7)
ACTION(32, 8)
ACTION(32, 9)
ACTION(32, 10)
ACTION(32, 11)
ACTION(32, 12)
ACTION(32, 13)
ACTION(32, 14)
ACTION(32, 15)
ACTION(32, 16)

table dmac {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        action_1_1;
        action_1_2;
        action_1_3;
        action_1_4;
        action_1_5;
        action_1_6;
        action_1_7;
        action_1_8;
        action_1_9;
        action_1_10;
        action_1_11;
        action_1_12;
        action_1_13;
        action_1_14;
        action_1_15;
        action_1_16;

        action_8_1;
        action_8_2;
        action_8_3;
        action_8_4;
        action_8_5;
        action_8_6;
        action_8_7;
        action_8_8;
        action_8_9;
        action_8_10;
        action_8_11;
        action_8_12;
        action_8_13;
        action_8_14;
        action_8_15;
    /*
     *  Maximum number of actions per table is 31 
     */
#if 0
        action_8_16;

        action_16_1;
        action_16_2;
        action_16_3;
        action_16_4;
        action_16_5;
        action_16_6;
        action_16_7;
        action_16_8;
        action_16_9;
        action_16_10;
        action_16_11;
        action_16_12;
        action_16_13;
        action_16_14;
        action_16_15;
        action_16_16;

        action_32_1;
        action_32_2;
        action_32_3;
        action_32_4;
        action_32_5;
        action_32_6;
        action_32_7;
        action_32_8;
        action_32_9;
        action_32_10;
        action_32_11;
        action_32_12;
        action_32_13;
        action_32_14;
        action_32_15;
        action_32_16;
#endif
    }
}

control ingress {
    apply(dmac);
}

control egress {
}
