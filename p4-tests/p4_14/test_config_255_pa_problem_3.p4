#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_t {
    fields {
        priority : 3;
        cfi : 1;
        vid : 12;
        vtype : 16;
    }
}

header_type m_t {
    fields {
        p : 3;
        c : 1;
        v : 12;
        t : 16;
        x : 12;
        y : 4;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x800 : parse_ipv4;
        0x8100 : parse_vlan;
        default: ingress;
    }
}

parser parse_vlan {
    extract(vlan);
    return parse_ipv4;
}

header ethernet_t ethernet;
header vlan_t vlan;
header ipv4_t ipv4;
metadata m_t m;


parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

action do_nothing(){}

action read_vlan(){
    modify_field(m.p, vlan.priority);
    modify_field(m.c, vlan.cfi);
    modify_field(m.v, vlan.vid);
    modify_field(m.t, vlan.vtype);  

    modify_field(m.x, vlan.vid);
}

action set_port(p){
    modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}

table t1 {
    reads {
        ethernet.srcAddr mask 0xFFFF : ternary;
    }
    actions {
        do_nothing;
        read_vlan;
    }
    size : 512;
}


table t2 {
    reads {
        m.p : ternary;
        m.t : exact;
        m.c : exact;
        m.v : exact;
        m.x : exact;
    }
    actions {
        do_nothing;
        set_port;
    }
    size : 512;
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress {
}
