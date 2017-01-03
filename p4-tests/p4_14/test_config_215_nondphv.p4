
header_type hdr_0_t {
    fields {
        a : 8;
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
        d : 8;
        e : 8;
        f : 16;
        g : 32;
    }
}

header_type meta_t {
     fields {
         a : 1;
         b : 32;
         c : 3;
         d : 4;
         e : 1;
         f : 16;
         g : 1;
         h : 12;
         i : 14;
         j : 2;
         k : 20;
         l : 6;
         m : 32;
     }
}

header hdr_0_t hdr_0;
header hdr_1_t hdr_1;

metadata meta_t meta;


parser start {
    return parse_hdr_0;
}

parser parse_hdr_0 {
    extract(hdr_0);
    return parse_hdr_1;
}

parser parse_hdr_1 {
    extract(hdr_1);
    return ingress;
}

action do_nothing(){}

action set_all(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12){
    modify_field(meta.a, p0);
    modify_field(meta.b, p1);
    modify_field(meta.c, p2);
    modify_field(meta.d, p3);
    modify_field(meta.e, p4);
    modify_field(meta.f, p5);
    modify_field(meta.g, p6);
    modify_field(meta.h, p7);
    modify_field(meta.i, p8);
    modify_field(meta.j, p9);
    modify_field(meta.k, p10);
    modify_field(meta.l, p11);
    modify_field(meta.m, p12);
}

action action_0(p0, p1){
    modify_field(meta.a, p0);
    modify_field(meta.f, 0);
    modify_field(meta.d, p1);
}

action action_1(p0, p1){
    modify_field(meta.c, p0);
    modify_field(meta.e, 0);
    modify_field(meta.f, p1);
}

action action_2(p0){
    modify_field(meta.e, meta.a);
    modify_field(meta.k, p0);
    modify_field(meta.m, meta.b);
    bit_xor(hdr_0.f, hdr_0.f, hdr_1.c);
}

action action_e(p0){
    modify_field(hdr_1.d, hdr_0.a);
    modify_field(hdr_1.g, p0);
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
        meta.e : exact;
        meta.f : exact;
        meta.g : exact;
        meta.h : exact;
        meta.i : exact;
        meta.j : exact;
        meta.k : exact;
        meta.l : exact;
        meta.m : exact;
    }
    actions {
        action_2;
        do_nothing;
    }
    size : 1024;
}

table table_e0 {
    reads {
        meta.e : exact;
        meta.h : exact;
    }
    actions {
        action_e;
    }
    size : 4096;
}

control ingress {
    apply(table_i0);
    apply(table_i1);
    apply(table_i2);
}

control egress {
    apply(table_e0);
}