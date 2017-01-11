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

header_type hdr_2_t {
    fields {
       a : 8;
       b : 8;
       c : 8;
       d : 8;
    }
}

header_type hdr_3_t {
    fields {
/*       big : 280;
*/

/*
       a : 32 ;
       b : 32 ;  
       c : 32 ;
       d : 32 ;  
       e : 32 ;
       f : 32 ;  
       g : 16 ;  
       g_a : 3 ; 
       h : 32 ;  
       i : 5;
*/

       a_3 : 32;
       a_4 : 32;
       a_5 : 32;
       a_6 : 32;

       a_7 : 27;
       b_1 : 1;
       b_2 : 2;
       b_3 : 4;

       a_8 : 30;
       a_9 : 32;
       a_10 : 32;
       a_11 : 32;
       a_12 : 32;
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

@pragma pa_container_size ingress first.b 16
header first_t first;

@pragma pa_container_size ingress hdr_0.d 32
header hdr_0_t hdr_0;
header hdr_1_t hdr_1[3];
header hdr_2_t hdr_2;
header hdr_3_t hdr_3;

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
    extract(hdr_1[next]);
    return select(hdr_1[0].d_0){
        0 : parse_hdr_1;
        1 : parse_hdr_2;
        default : ingress;
    }
    /* return ingress; */
}

parser parse_hdr_2 {
    extract(hdr_2);
    return parse_hdr_3;
}

parser parse_hdr_3 {
    extract(hdr_3);
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
    modify_field(meta.b, hdr_1[0].d_1);
    modify_field(meta.d, p1);
    add(meta.c, meta.c, 1);
    subtract(meta.e, p2, meta.f);
}

action action_2(){
    add_to_field(meta.e, 5);
}

action action_3(p0){
    modify_field(meta.f, 1);
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
        hdr_1[0].c: ternary;
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
        action_2;
    }
    size : 1024;
}

table table_i3 {
    reads {
        meta.b : ternary;
    }
    actions { 
        do_nothing;
        action_3;
    }
    size : 512;
}

control ingress {

    if (valid(hdr_0)){
        apply(table_i0);
    } else {
        apply(table_i1);
    }
    apply(table_i2);
    apply(table_i3);
}

