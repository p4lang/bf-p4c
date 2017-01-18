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
        flag : 1;
        tmp : 9;
        egress_port1 : 9;
        egress_port2 : 9;
    }
}

metadata ingress_metadata_t ing_metadata;

action set_ingress_port_props(port_type) {
    modify_field(ing_metadata.flag, port_type);
}

table ingress_port_map {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_ingress_port_props;
    }
    size : 288;
}

action assign_egress_interfaces(value) {
    modify_field(ing_metadata.tmp, value);
}

table dmac {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        assign_egress_interfaces;
    }
}

action assign_egress1_action() {
    modify_field(ing_metadata.egress_port1, ing_metadata.tmp);
}

table assign_egress1 {
    actions {
        assign_egress1_action;
    }
}

action assign_egress2_action() {
    modify_field(ing_metadata.egress_port2, ing_metadata.tmp);
}

table assign_egress2 {
    actions {
        assign_egress2_action;
    }
}

control ingress {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(ingress_port_map);

        apply(dmac);

        if (ing_metadata.flag == 1) {
            apply(assign_egress1);
        } else {
            apply(assign_egress2);
        }
    }
}

control egress {
}
