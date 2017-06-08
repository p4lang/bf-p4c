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
        x : 8;
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

action set_m(){
    modify_field(m.p, 7);
    modify_field(m.c, 0);
    modify_field(m.v, 2);
    modify_field(m.t, 1);
    modify_field(m.x, 4);
}


action add_vlan(){
    add_header(vlan);
    /* Packing requirement that does not fill container. */
    modify_field(vlan.cfi, m.c);
    modify_field(vlan.vid, m.v);
    modify_field(vlan.vtype, m.t);   
    modify_field(ipv4.diffserv, m.x);
}

table t1 {
    reads {
        ethernet.srcAddr mask 0xFFFF : ternary;
    }
    actions {
        do_nothing;
        set_m;
    }
    size : 512;
}


table t2 {
    reads {
        ethernet.srcAddr mask 0xFFFF : ternary;
    }
    actions {
        do_nothing;
        add_vlan;
    }
    size : 512;
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress {
}