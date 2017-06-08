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
    extract(vlan2);
    return parse_ipv4;
}

header ethernet_t ethernet;
header vlan_t vlan;
header vlan_t vlan2;
header ipv4_t ipv4;
metadata m_t m;
metadata m_t m2;


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
}

action set_m2(){
    modify_field(m2.p, vlan2.priority);
    modify_field(m2.c, vlan2.cfi);
    modify_field(m2.v, vlan2.vid);
    modify_field(m2.t, vlan2.vtype);
}

action add_vlan(){
    add_header(vlan);
    modify_field(vlan.priority, m.p);
    modify_field(vlan.cfi, m.c);
    modify_field(vlan.vid, m.v);
    modify_field(vlan.vtype, m.t);   
}

action set_m_again(){
    modify_field(m.p, m2.p);
    modify_field(m.c, m2.c);
    modify_field(m.v, m2.v);
    modify_field(m.t, m2.t);
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

table t3 {
    reads {
        ethernet.srcAddr mask 0xFFFF : ternary;
    }
    actions {
        do_nothing;
        set_m2;
    }
    size : 512;
}

table t4 {
    reads {
        ethernet.srcAddr mask 0xFFFF : ternary;
    }
    actions {
        do_nothing;
        set_m_again;
    }
    size : 512;
}

table t5 {
    reads {
        m.p : exact;
        m.c : exact;
        m.v : exact;
        m.t : exact;
        m2.p : exact;
        m2.c : exact;
        m2.v : exact;
        m2.t : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
    support_timeout : true;
} 


control ingress {
    apply(t1);
    apply(t2);
    apply(t3);
    apply(t4);
    apply(t5);
}

control egress {
}