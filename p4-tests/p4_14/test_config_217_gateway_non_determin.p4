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
    }
}

header_type hdr_1_t {
    fields {
        a : 32;
        b : 32;
        c : 16;
        d_0 : 4;
        d_1 : 4;
        e : 8;
        f : 16;
        g : 32;
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
header hdr_1_t hdr_1;

metadata meta_t meta;


parser start {
    return first_p;
}

parser first_p {
    extract(first);
    return select(first.c) {
       0x3f : parse_hdr_0;
       default : parse_hdr_1;
    }
}

parser parse_hdr_0 {
    extract(hdr_0);
    return ingress;
}

parser parse_hdr_1 {
    extract(hdr_1);
    return ingress;
}

action do_nothing(){}

action set_all(p0, p2, p3){
    modify_field(meta.a, p0);
    modify_field(meta.c, p2);
    modify_field(meta.d, p3);
}

action action_0(p0, p1){
    modify_field(meta.a, 0);
    modify_field(meta.b, hdr_0.a_1);
    drop();
}

action action_1(p1, p2){
    modify_field(meta.b, hdr_1.d_1);
    modify_field(meta.d, p1);
    add(meta.c, meta.c, 1);
    subtract(meta.e, p2, meta.f);
}

table table_i0 {
    reads {
        hdr_0.b: ternary;
    }
    actions {
        set_all;
        action_0;
    }
    size : 512;
}

table table_i1 {
    reads {
        hdr_1.c: ternary;
        hdr_1.c: ternary;
    }
    actions {
        action_1;
        do_nothing;
    }
    size : 512;
}

table table_i2 {
    reads {
        meta.a : exact;
        meta.b : exact;
        meta.c : exact;
        meta.d : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

control ingress {

    if (valid(hdr_0)){
        if (first.a == 1 and first.b == 3) {
            apply(table_i0);
        }
    } else {
        if (first.d == 8 and meta.b == 5 and meta.c == 0) {
            apply(table_i1);
        }
    }
    if (valid(hdr_1)) {
        apply(table_i2);
    }
}

