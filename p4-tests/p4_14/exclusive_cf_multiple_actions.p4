#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ether;

parser start {
    extract(ether);
    return ingress;
}

header_type md_t {
    fields {
        port : 9;
        direction: 1;
    }
}

metadata md_t md;

action forward() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, md.port);
}

action a1() {
    modify_field(md.port, 1);
    // and forward to port 1 since this is the default action
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}
action a2() {
    modify_field(md.port, 2);
}
action a3() {
    modify_field(md.port, 3);
}
action a4() {
    modify_field(md.port, 4);
}
action a5() {
    modify_field(md.port, 5);
}

action branch() {
    modify_field(md.direction, ether.dstAddr, 0x1);
}

table t0 {
    actions {
        branch;
    }
    default_action: branch;
    size: 1;
}

table t1 {
    reads {
        ether.dstAddr: exact;
    }
    actions {
        a1; // default action
        a2;
        a3;
        a4;
        a5;
    }
}

table t2 {
    actions {
        forward;
    }
    default_action: forward;
    size: 1;
}
table t3 {
    actions {
        forward;
    }
    default_action: forward;
    size: 1;
}
table t4 {
    actions {
        forward;
    }
    default_action: forward;
    size: 1;
}
table t5 {
    actions {
        forward;
    }
    default_action: forward;
    size: 1;
}

control ingress {
    apply(t0); // decide which way to go based on the last bit of ether.dstAddr
    if (md.direction == 1) {
        apply(t1) {
            a2 { apply(t2); }
            a3 { apply(t3); }
        }
    }
    else {
        apply(t1) {
            a4 { apply(t4); }
            a5 { apply(t5); }
        }
    }

}
