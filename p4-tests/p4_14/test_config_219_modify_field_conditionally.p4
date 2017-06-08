#include "tofino/intrinsic_metadata.p4"

header_type first_t {
    fields {
       a : 8;
       b : 8;
       c : 8;
       d : 8;
    }
}

header_type hdr_0_t {
    fields {
        a_0 : 4;
        a_1 : 4;
        b : 16;
        c : 32;
        d : 32;
        e : 8;
        f : 16;
        g : 3;
        h : 8;
        i : 5;
    }
}

header first_t first;
header hdr_0_t hdr_0;


parser start {
    return first_p;
}

parser first_p {
    extract(first);
    return select(first.c) {
       0x3f : parse_hdr_0;
       default : ingress;
    }
}

parser parse_hdr_0 {
    extract(hdr_0);
    return ingress;
}

action action_0(src0){
    /* will end up being unconditional modify_field(dst, src) */
    modify_field_conditionally(hdr_0.c, 1, src0);
}

action action_1(src1){
    /* will be eliminated */
    modify_field_conditionally(hdr_0.c, 0, src1);
}

action action_2(cond2, src2){
    modify_field_conditionally(hdr_0.c, cond2, src2);
}

table table_i0 {
    reads {
        hdr_0.b: ternary;
    }
    actions {
        action_0;
        action_1;
        action_2;
    }
    size : 512;
}

control ingress {
    apply(table_i0);
}

