/* -*- P4_14 -*- */

#ifdef __TARGET_TOFINO__
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#else
#error This program is intended to compile for Tofino P4 architecture only
#endif

#define ETHERTYPE_TO_CPU 0xBF01

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp       : 3;
        cfi       : 1;
        vid       : 12;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version        : 4;
        ihl            : 4;
        diffserv       : 8;
        totalLen       : 16;
        identification : 16;
        flags          : 3;
        fragOffset     : 13;
        ttl            : 8;
        protocol       : 8;
        hdrChecksum    : 16;
        srcAddr        : 32;
        dstAddr        : 32;
    }
}

header_type to_cpu_t {
    fields {
        mirror_type   : 16;
        ingress_port  : 16;
        pkt_length    : 16;
    }
}

/*************************************************************************
 ***********************  M E T A D A T A  *******************************
*************************************************************************/
#define MIRROR_TYPE_INGRESS 0
#define MIRROR_TYPE_EGRESS  1

header_type mirror_meta_t {
    fields {
        mirror_type  : 1;
        mirror_dest  : 10;
        ingress_port : 9;
    }
}

metadata mirror_meta_t mirror_meta;

/*************************************************************************
 ***********************  P A R S E R  ***********************************
 *************************************************************************/
header ethernet_t ethernet;
header vlan_tag_t vlan_tag[2];
header ipv4_t     ipv4;

header ethernet_t cpu_ethernet;
header to_cpu_t   to_cpu;

parser start {
    return select(current(96, 16)) {
        ETHERTYPE_TO_CPU: parse_cpu_ethernet;
        default         : parse_ethernet;
    }
}

parser parse_cpu_ethernet {
    extract(cpu_ethernet);
    return select(cpu_ethernet.etherType) {
        ETHERTYPE_TO_CPU: parse_to_cpu;
        default         : ingress;
    }
}

parser parse_to_cpu {
    extract(to_cpu);
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x8100 : parse_vlan_tag;
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_vlan_tag {
    extract(vlan_tag[next]);
    return select(latest.etherType) {
        0x8100 : parse_vlan_tag;
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

#ifdef BMV2TOFINO
/*
 * Tofino compatibility.
 */
action tofino_init() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 511);
}
table tofino_init {
    actions { tofino_init; }
    default_action: tofino_init();
    size : 1;
}
#endif

counter ipv4_host_stats {
    type   : packets_and_bytes;
    direct : ipv4_host;
}

action send(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action discard() {
    modify_field(ig_intr_md_for_tm.drop_ctl, 1);
}

table ipv4_host {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
        send;
        discard;
    }
    size : 32768;
}

table ipv4_lpm {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        send;
        discard;
    }
    size : 8192;
}

/*
 * Ingress ACL
 */
action acl_drop() {
    drop();
}

field_list mirror_list {
    mirror_meta.ingress_port;
    mirror_meta.mirror_dest;
    mirror_meta.mirror_type;
}

action acl_mirror(mirror_dest) {
    modify_field(mirror_meta.mirror_type, MIRROR_TYPE_INGRESS);
    modify_field(mirror_meta.ingress_port, ig_intr_md.ingress_port);
    modify_field(mirror_meta.mirror_dest, mirror_dest);
    clone_ingress_pkt_to_egress(mirror_dest, mirror_list);
}

action acl_drop_and_mirror(mirror_dest) {
    acl_drop();
    acl_mirror(mirror_dest);
}

table ing_acl {
    reads {
        ig_intr_md.ingress_port : ternary;
        ethernet.srcAddr        : ternary;
        ethernet.dstAddr        : ternary;
        vlan_tag[0].valid       : ternary;
        vlan_tag[0].vid         : ternary;
        ipv4.valid              : ternary;
        ipv4.srcAddr            : ternary;
        ipv4.dstAddr            : ternary;
    }
    actions {
        acl_drop;
        acl_mirror;
        acl_drop_and_mirror;
    }
    size : 512;
}

control ingress {
    if (valid(ipv4)) {
        apply(ipv4_host) {
            miss {
                apply(ipv4_lpm);
            }
        }
    }

    apply(ing_acl);
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
/* 
 * Mirrored Packet handling 
 */
action send_ether() {
    /* Do Nothing, really */
}

action send_to_cpu() {
    add_header(cpu_ethernet);
    modify_field(cpu_ethernet.dstAddr,   0xFFFFFFFFFFFF);
    modify_field(cpu_ethernet.srcAddr,   0xAAAAAAAAAAAA);
    modify_field(cpu_ethernet.etherType, ETHERTYPE_TO_CPU);
    add_header(to_cpu);
    modify_field(to_cpu.mirror_type,  mirror_meta.mirror_type);
    modify_field(to_cpu.ingress_port, mirror_meta.ingress_port);
    modify_field(to_cpu.pkt_length,   eg_intr_md.pkt_length);
}

action send_rspan(pcp, cfi, vid) {
    push(vlan_tag, 1);
    add_header(vlan_tag[0]);
    modify_field(vlan_tag[0].pcp, pcp);
    modify_field(vlan_tag[0].cfi, cfi);
    modify_field(vlan_tag[0].vid, vid);
    modify_field(vlan_tag[0].etherType, ethernet.etherType);
    modify_field(ethernet.etherType, 0x8100);
}

table mirror_dest {
    reads {
        mirror_meta.mirror_dest : exact;
    }
    actions {
        send_ether;
        send_to_cpu;
        send_rspan;
    }
}

control egress {
    if (pkt_is_mirrored) {
        apply(mirror_dest);
    }
}
