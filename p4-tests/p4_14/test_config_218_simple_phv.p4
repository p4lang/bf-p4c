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
/*
        g : 3;
        h : 8;
        i : 5;
*/
    }
}

header_type meta_t {
     fields {
         a : 32;
         b : 4;
         c : 4;
         d : 16;
         e : 8;
         f : 8;
     }
}

header first_t first;
header hdr_0_t hdr_0;
metadata meta_t meta;


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

action do_nothing(){}

action action_0(p0, p1){
    modify_field(hdr_0.e, p0);
    drop();
}

action action_1(p1, p2){
    modify_field(meta.d, p1);
/*
    add(meta.c, meta.c, 1);
    subtract(meta.e, p2, meta.f);
*/
}

table table_i0 {
    reads {
        hdr_0.b: ternary;
    }
    actions {
        action_0;
    }
    size : 512;
}

table table_i1 {
    reads {
        hdr_0.c: ternary;
    }
    actions {
        action_1;
        do_nothing;
    }
    size : 512;
}

control ingress {
    if (valid(hdr_0)){
        apply(table_i0);
    } else {
        apply(table_i1);
    }
}

