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
        drop : 1;
        egress_port : 8;
    }
} 

metadata ingress_metadata_t ing_metadata;

action nop() {
}

action ing_drop() {
    modify_field(ing_metadata.drop, 1); /* instead of drop() */
}

action set_egress_port(egress_port) {
    modify_field(standard_metadata.egress_spec, egress_port);
}

table dmac {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        nop;
        ing_drop;
        set_egress_port;
    }
    size : 131072;
}

table smac_filter {
    reads {
        ethernet.srcAddr : exact;
    }
    actions {
        nop;
        ing_drop;
    }
}

action hw_drop() {
    drop();
}

table do_drop {
    actions {
        hw_drop;
    }
}
 
control ingress {
    apply(dmac);
    apply(smac_filter);
#if 1
    if (ing_metadata.drop == 1) {
        apply(do_drop);
    }
#endif
}

table e_t1 {
    reads {
        ethernet.srcAddr : exact;
    }
    actions {
        nop;
    }
}

control egress {
    apply(e_t1);
}
