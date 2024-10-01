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

parser start {
    extract(ethernet);
    return ingress;
}

header_type ingress_metadata_t {
    fields {
        f1 : 8;
        f2 : 16;
        f3 : 32;
        f4 : 64;     
    }
}

metadata ingress_metadata_t ing_metadata;

action nop() {
}

action set_ingress_port_props(f1, f2, f3) {
    modify_field(ing_metadata.f1, f1);
    modify_field(ing_metadata.f2, f2);
    modify_field(ing_metadata.f3, f3);
}

action set_ingress_port_prop64(f4) {    
    modify_field(ing_metadata.f4, f4);
}

table ingress_port_map {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_ingress_port_props; // or use set_ingress_port_props64, but not both!
    }
    size : 288;
}

control ingress {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(ingress_port_map);
    }
}

control egress {
}
