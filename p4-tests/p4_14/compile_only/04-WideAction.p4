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

        field16_1 : 16;
        field16_2 : 16;
        field16_3 : 16;
        field16_4 : 16;
        field16_5 : 16;
        field16_6 : 16;
        field16_7 : 16;
        field16_8 : 16;

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

#define ACTION(w, n)     modify_field(md.field##w##_##n, value##w##_##n)

action action1(
    value1_1, 
    value1_2, 
    value1_3, 
    value1_4, 
    value1_5, 
    value1_6, 
    value1_7, 
    value1_8,

    value8_1, 
    value8_2, 
    value8_3, 
    value8_4, 
    value8_5, 
    value8_6, 
    value8_7, 
    value8_8,

    value16_1, 
    value16_2, 
    value16_3, 
    value16_4, 
    value16_5, 
    value16_6, 
    value16_7, 
    value16_8,

    value32_1, 
    value32_2, 
    value32_3, 
    value32_4, 
    value32_5, 
    value32_6, 
    value32_7, 
    value32_8
)
{
    ACTION(1, 1);
    ACTION(1, 2);
    ACTION(1, 3);
    ACTION(1, 4);
    ACTION(1, 5);
    ACTION(1, 6);
    ACTION(1, 7);
    ACTION(1, 8);

    ACTION(8, 1);
    ACTION(8, 2);
    ACTION(8, 3);
    ACTION(8, 4);
    ACTION(8, 5);
    ACTION(8, 6);
    ACTION(8, 7);
    ACTION(8, 8);

    ACTION(16, 1);
    ACTION(16, 2);
    ACTION(16, 3);
    ACTION(16, 4);
    ACTION(16, 5);
    ACTION(16, 6);
    ACTION(16, 7);
    ACTION(16, 8);

    ACTION(32, 1);
    ACTION(32, 2);
    ACTION(32, 3);
    ACTION(32, 4);
    ACTION(32, 5);
    ACTION(32, 6);
    ACTION(32, 7);
    ACTION(32, 8);
}

table dmac {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        action1;
    }
    size: 16536;
}


control ingress {
    apply(dmac);
}

control egress {
}
