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

header_type l2_metadata_t {
    fields {
        bd : 22;
       _pad : 2;
    }
}

header l2_metadata_t l2_metadata;

action nop() {
}

action ing_drop() {
    drop();
}

action set_egress_port(egress_port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action set_bd(bd) {
    modify_field(l2_metadata.bd, bd);
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

table vlan_port_tab {
    reads {
        ig_intr_md.ingress_port : exact;
        l2_metadata.bd          : exact;
    }
    actions {
        nop;
        ing_drop;
    }
    size : 409600;
}

control ingress {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(port_bd);
        apply(vlan_port_tab);
    }
}

control egress {
}
