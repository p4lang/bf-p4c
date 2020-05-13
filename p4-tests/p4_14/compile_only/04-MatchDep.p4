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
        drop         : 1;
        bd           : 16;
        ingress_port : 9;
        egress_port  : 9;
    }
} 

metadata ingress_metadata_t ing_metadata;

action nop() {
}

action ing_drop() {
    modify_field(ing_metadata.drop, 1);
}

action ing_drop_cancel() {
    modify_field(ing_metadata.drop, 0);
}

action set_egress_port(egress_port) {
    modify_field(ing_metadata.egress_port, egress_port);
}

action set_bd(bd) {
    modify_field(ing_metadata.bd, bd);
}

table port_bd {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_bd;
    }
    size : 288;
}

table port_drop {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        ing_drop;
    }
    size : 288;
}
   
table dmac {
    reads {
        ethernet.dstAddr : exact;
        ing_metadata.bd  : exact;
    }
    actions {
        nop;
        set_egress_port;
    }
    size : 131072;
}

table smac_filter {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        nop;
        ing_drop;
    }
}

control ingress {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(port_bd);
	apply(port_drop);
    }
    apply(dmac);
//    apply(smac_filter);
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