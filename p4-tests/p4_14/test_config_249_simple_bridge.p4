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
        v : 2;
        w : 6;
        x : 8;
        y : 16;
        z : 64;//16;
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

action i0(px, py, pz){
    modify_field(m.w, 4);
    modify_field(m.x, px);
    modify_field(m.y, py);
    modify_field(m.z, pz);
}

action set_port(p0){
    modify_field(eg_intr_md.egress_port, p0);
}

table t0 {
    reads {
        ethernet.srcAddr mask 0xFFFF : ternary;
    }
    actions {
        do_nothing;
        i0;
    }
    size : 512;
}

table t1 {
    reads {
        ethernet.srcAddr mask 0xFFFF : ternary;
    }
    actions {
        do_nothing;
    }
    size : 512;
}

table te0 {
    reads {
        m.w : ternary;
        m.x : exact;
        m.y : exact;
        m.z : exact;
        ipv4.ttl : exact;
    }
    actions {
        do_nothing;
        set_port;
    }
    size : 512;
}

control ingress {
    apply(t0);
    apply(t1);
}

control egress {
    apply(te0);
}