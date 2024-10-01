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
        field1_1 : 1;
        field1_2 : 1;
        field1_3 : 1;
        field1_4 : 1;
        field1_5 : 1;
        field1_6 : 1;
        field1_7 : 1;
        field1_8 : 1;

        field8_1 : 8;
        field8_2 : 8;
        field8_3 : 8;
        field8_4 : 8;
        field8_5 : 8;
        field8_6 : 8;
        field8_7 : 8;
        field8_8 : 8;

        field16_1 : 64;
        field16_2 : 64;
        field16_3 : 64;
        field16_4 : 64;
        field16_5 : 64;
        field16_6 : 64;
        field16_7 : 64;
        field16_8 : 64;

        field32_1 : 32;
        field32_2 : 32;
        field32_3 : 32;
        field32_4 : 32;
        field32_5 : 32;
        field32_6 : 32;
        field32_7 : 32;
        field32_8 : 32;
    }
}

metadata metadata_t md;

parser start {
    extract(ethernet);
    return ingress;
}

#define ACTION(w, n)                                  \
action set_field##w##_##n(value) {                    \
    modify_field(md.field##w##_##n, value);     \
}

ACTION(1, 1)
ACTION(1, 2)
ACTION(1, 3)
ACTION(1, 4)
ACTION(1, 5)
ACTION(1, 6)
ACTION(1, 7)
ACTION(1, 8)

ACTION(8, 1)
ACTION(8, 2)
ACTION(8, 3)
ACTION(8, 4)
ACTION(8, 5)
ACTION(8, 6)
ACTION(8, 7)
ACTION(8, 8)

ACTION(16, 1)
ACTION(16, 2)
ACTION(16, 3)
ACTION(16, 4)
ACTION(16, 5)
ACTION(16, 6)
ACTION(16, 7)
ACTION(16, 8)

ACTION(32, 1)
ACTION(32, 2)
ACTION(32, 3)
ACTION(32, 4)
ACTION(32, 5)
ACTION(32, 6)
ACTION(32, 7)
ACTION(32, 8)

table dmac1 {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        set_field1_1;
        set_field1_2;
        set_field1_3;
        set_field1_4;
        set_field1_5;
        set_field1_6;
        set_field1_7;
        set_field1_8;

        set_field8_1;
        set_field8_2;
        set_field8_3;
        set_field8_4;
        set_field8_5;
        set_field8_6;
        set_field8_7;
        set_field8_8;

        set_field16_1;
        set_field16_2;
        set_field16_3;
        set_field16_4;
        set_field16_5;
        set_field16_6;
        set_field16_7;
        set_field16_8;

        set_field32_1;
        set_field32_2;
        set_field32_3;
        set_field32_4;
        set_field32_5;
        set_field32_6;
        set_field32_7;
#if 0       
        set_field32_8;
#endif

    }
    size: 32768;
}

table dmac2 {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        set_field1_1;
        set_field1_2;
        set_field1_3;
        set_field1_4;
        set_field1_5;
        set_field1_6;
        set_field1_7;
        set_field1_8;

        set_field8_1;
        set_field8_2;
        set_field8_3;
        set_field8_4;
        set_field8_5;
        set_field8_6;
        set_field8_7;
        set_field8_8;

        set_field16_1;
        set_field16_2;
        set_field16_3;
        set_field16_4;
        set_field16_5;
        set_field16_6;
        set_field16_7;
        set_field16_8;

        set_field32_1;
        set_field32_2;
        set_field32_3;
        set_field32_4;
        set_field32_5;
        set_field32_6;
        set_field32_7;
#if 0       
        set_field32_8;
#endif
    }
    size : 32768;
}

control ingress {
    if ((ig_intr_md.ingress_port & 0x001) == 0x001) {
        apply(dmac1);
    } else {
        apply(dmac2);
    }
}

control egress {
}
