#include "tofino/intrinsic_metadata.p4"

header_type hdr_t {
    fields {
        x : 32;
        y : 32;
        z : 32;
    }
}

@pragma pa_atomic ingress hdr.x
@pragma pa_atomic ingress hdr.y
@pragma pa_atomic ingress hdr.z
header hdr_t hdr;

parser start {
   return parse_hdr;
}

parser parse_hdr {
   extract(hdr);
   return ingress;
}

action do_nothing(){ }

action action_0(p){
    funnel_shift_right(hdr.x, hdr.y, hdr.z, 14);
}
action action_1(){
    shift_right(hdr.x, hdr.x, 4);
}


table table_0 {
    reads {
        hdr.x : ternary;
    }
    actions {
        action_0;
        action_1;
        do_nothing;
    }
    size : 512;
}

control ingress {
    apply(table_0);
}