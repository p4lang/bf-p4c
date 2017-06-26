#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#else
#include "includes/tofino.p4"
#endif

/*
 * Packet headers and parser
 */
header_type bff_t {    /* Barefoot Fabric :) */
    fields {
        f1        : 16;
        f2        : 16;
    }
}
    
header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        ethertype : 16;
    }
}

header_type  metadata_t {
    fields {
        port_type : 1;
    }
}

header bff_t bff;
header ethernet_t ethernet;
metadata metadata_t m;

parser start {
    return select(m.port_type) {
        0 : parse_ethernet;
        1 : parse_bff;
    }
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

parser parse_bff {
    extract(bff);
    return parse_ethernet;
}

/*
 * Table ingress_port_mapping converts a port# into a local port bitmap
 */
action set_port_properties(port_type) {
    modify_field(m.port_type, port_type);
}

table ingress_port {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_port_properties;
    }
    size : 288;
}

action do_fabric_forward() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, bff.f1);
}

table fabric_forward {
    actions {
        do_fabric_forward;
    }
    default_action : do_fabric_forward;
}

action do_ethernet_forward(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

table ethernet_forward {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        do_ethernet_forward;
    }
}

action do_remove_fabric() {
    remove_header(bff);
}

table remove_fabric {
    actions {
        do_remove_fabric; 
    }
    default_action : do_remove_fabric;
}

control ingress {
    if (ig_intr_md.resubmit_flag == 0) {
        apply(ingress_port);
    }

    if (valid(bff)) {
        apply(fabric_forward);
    } else {
        apply(ethernet_forward);
    }
}

control egress {
    apply(remove_fabric);
}
