#include "tofino/intrinsic_metadata.p4"


header_type begin_t {
    fields {
        sel : 8;
        blah : 24;
    }
}

header_type hdr1_t {
    fields {
        a_8 : 8;
        b_16 : 16;
        c_32 : 32;
        d_16 : 16;
        e_16 : 16;
    }
}

header_type meta_t {
    fields {
        x_32 : 32;
        y_32 : 32;
        z_32 : 32;
    }
}


parser start {
    return parse_begin;
}

parser parse_begin {
    extract(begin);
    //set_metadata(meta.z_32, 3);
    return select(begin.sel){
        0 : parse_pkt;
        default : parse_pkt_2;
    }
}

parser parse_pkt {
    extract(hdr1);
    set_metadata(meta.x_32, 0);
    return ingress;
}

parser parse_pkt_2 {
    extract(hdr2);
    set_metadata(meta.y_32, 1);
    return ingress;
}

header begin_t begin;

@pragma pa_container_size ingress hdr1.a_6 8
@pragma pa_container_size ingress hdr1.c_8 16
@pragma pa_solitary ingress hdr1.d_8
header hdr1_t hdr1;

header hdr1_t hdr2;

@pragma pa_container_size ingress meta.x_32 16
@pragma pa_container_size ingress meta.y_32 16
@pragma pa_mutually_exclusive ingress meta.x_32 meta.y_32
metadata meta_t meta;

action do_nothing(){}

action a0(b){
    modify_field(begin.blah, b);
}

table t0 {
    reads {
         meta.x_32 mask 0xFF000000 : ternary;
         meta.y_32 mask 0xFFFF0000 : ternary;
         hdr1.e_16 : exact;
         meta.z_32 : exact;
    }
    actions {
         a0;
         do_nothing;
    }
    size : 512;
}

control ingress {
    apply(t0);
}

control egress { }