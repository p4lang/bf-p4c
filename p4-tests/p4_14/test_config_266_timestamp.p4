#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type hdr1_t {
    fields {
        a : 8;
        b : 16;
        c : 8;
        d : 48;
    }
}

parser start {
    return parse_pkt;
}


parser parse_pkt {
    extract(hdr1);
    return ingress;
}

header hdr1_t hdr1;

action do_nothing(){}


action set_pkt(){
    modify_field(hdr1.d, ig_intr_md_from_parser_aux.ingress_global_tstamp);
}

/*
action set_pkt(d){
    modify_field(hdr1.d, d);
}
*/

table t1 {
    reads {
         hdr1.a : ternary;
    }
    actions {
         set_pkt;
         do_nothing;
    }
    size : 512;
}

control ingress {
    apply(t1);
}

control egress { }