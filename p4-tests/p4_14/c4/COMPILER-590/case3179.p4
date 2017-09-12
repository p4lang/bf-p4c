/*
npb.p4 - P4_14 PoC program to implement some NPB and AFM features
TODO - l2_gre_encap is not setting GRE protocol correctly:
 gets set to 0x17c1 = 6081d = geneve port number instead of 0x6558


*/
#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/pktgen_headers.p4>
#include <tofino/stateful_alu_blackbox.p4>


//=====================
//      DEFINES
//=====================

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_ETHERNET 0x6558
#define ETHERTYPE_IPV6 0x86dd
#define ETHERTYPE_MPLS 0x8847
#define ETHERTYPE_VLAN 0x8100
#define ETHERTYPE_QINQ 0x88A8
#define ETHERTYPE_FABRICPATH 0x8903
#define ETHERTYPE_VNTAG 0x8926
#define ETHERTYPE_QINQ_OBS 0x9100

#define IP_PROTO_TCP 17
#define IP_PROTO_UDP 17
#define IP_PROTO_GRE 47

#define GTP_C_PORT_NUM 2123
#define GTP_U_PORT_NUM 2152
#define GENEVE_PORT_NUM 6081

#define TUNNEL_TYPE_NONE 0
#define TUNNEL_TYPE_VLAN 1
#define TUNNEL_TYPE_IPV4 2
#define TUNNEL_TYPE_IPV6 3
#define TUNNEL_TYPE_QINQ 4
#define TUNNEL_TYPE_QINQ_OBS 5
#define TUNNEL_TYPE_MPLS 6

/*
      Type = 00 - Non-IP packets
             01 - GTP-C packets
             10 - Non-GTP IP packets
             11 - GTP-U Packets
*/
#define LB_TYPE_NON_IP  0
#define LB_TYPE_GTP_C   1
#define LB_TYPE_NON_GTP 2
#define LB_TYPE_GTP_U   3


#define LB_HASH_TBL_SZ  1024
#define LB_HASH_IDX_LEN  10

#define INGRESS_IP_ACL_TABLE_SIZE 512


//=====================
//      HEADERS
//=====================


// === Standard Headers ===

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}

header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
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

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
    }
}

header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
    }
}

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

header_type gtpv1_t {
    fields {
        ver         : 3;    // 1 = gtpv1
        pt          : 1;    // 0 = gtp', 1 = gtp
        r           : 1;    // reserved, 0
        e           : 1;    // ext hdr flag
        s           : 1;    // seq number flag
        pn          : 1;    // N-PDU number flag
        mtype       : 8;    // message type
        mlen        : 16;   // message length
        teid        : 32;   // tunnel endpoint identifier
    }
}

// gtpv1 opts present if any of e,s,pn are true
header_type gtpv1_opt_fields_t {
    fields {
        seqnum      : 16;   // sequence number
        next_hdr    : 8;    // next ext hdr or 0 if none
        npdu        : 8;    // n-pdu number
    }
}

header_type genv_t {
    fields {
        ver : 2;
        optLen : 6;
        oam : 1;
        critical : 1;
        reserved : 6;
        protoType : 16;
        vni : 24;
        reserved2 : 8;
//      options: *;
    }
//  length:optLen*4 + 8;
//  max_length : 136;
}

header_type gre_t {
    fields {
        C : 1;
        R : 1;
        K : 1;
        S : 1;
        s : 1;
        recurse : 3;
        flags : 5;
        ver : 3;
        proto : 16;
    }
}
// The part of the fabricpath hdr incl. etherType, but sans ftag/ttl (sans 16 final bits)
header_type fabricpath_t {
    fields {
        endnode_id:     6;
        univ_local:     1;
        indiv_group:    1;
        endnode_idx:    2;
        rsvd:           1;
        ooo_dl:         1;
        switch_id:      12;
        subswitch_id:   8;
        port_id:        16;
        srcAddr:        48;
        etherType:      16;
    }
}

header_type fabricpath_extra_t {
    fields {
        ftag:           10;
        ttl:            6;
    }
}
header_type etherType_t {
    fields {    
        etherType: 16;
    }
}

/* smac and dmac only */
header_type macs_t {
    fields {
      dstAddr: 48;
      srcAddr: 48;
    }
}


// vntag hdr incl. vntag etherType and special vntag fields
header_type vntag_t {
    fields {
        etherType:  16;
        Version:    2; // TODO - not sure of location of this field
        dbit:       1; // destination bit
        ptr_bit:    1;  // pointer bit
        dest_vif:   12; // destination VIF
        looped:     1; // 
        rsvd:       3; // reserved
        src_vif:    12; // source VIF
    }
}
// === Metadata Headers ===

header_type metadata_t {
    fields {
        lb_type                 : 2;    // dmac field TT in Chronos40 spec
        lb_port_group           : 3;    // dmac field GGG in Chronos40 spec
        lb_port_num             : 48;   // hashed port num from lb table, becomes PPPPPPPP field in dmac
        lb_hash                 : LB_HASH_IDX_LEN;  // computed from hash fields
        mpls_tunnel_type        : 3;    // determined from MPLS payload
        inner_tunnel_type       : 3;    // determined from GTP payload
        pw_ctrl_word_present    : 1;
    }
}
/*
 * Layer-2 processing
 */

header_type l2_metadata_t {
    fields {
        lkp_mac_sa : 48;
        lkp_mac_da : 48;
        lkp_mac_type : 16;  // extracted ethertype
    }
}

/*
 * L3 Metadata
 */

header_type l3_metadata_t {
    fields {
        lkp_ip_type : 2;
        lkp_ip_version : 4;
        lkp_ip_proto : 8;
        lkp_dscp : 8;
        lkp_ip_ttl : 8;
        lkp_l4_sport : 16;
        lkp_l4_dport : 16;
        lkp_outer_l4_sport : 16;
        lkp_outer_l4_dport : 16;
    }
}
/*
 * IPv4 metadata
 */
header_type ipv4_metadata_t {
    fields {
        lkp_ipv4_sa : 32;
        lkp_ipv4_da : 32;
        ipv4_unicast_enabled : 1;      /* is ipv4 unicast routing enabled */
        ipv4_urpf_mode : 2;            /* 0: none, 1: strict, 3: loose */
    }
}
/*
 * IPv6 Metadata
 */
header_type ipv6_metadata_t {
    fields {
        lkp_ipv6_sa : 128;                     /* ipv6 source address */
        lkp_ipv6_da : 128;                     /* ipv6 destination address*/

        ipv6_unicast_enabled : 1;              /* is ipv6 unicast routing enabled on BD */
        ipv6_src_is_link_local : 1;            /* source is link local address */
        ipv6_urpf_mode : 2;                    /* 0: none, 1: strict, 3: loose */
    }
}


// === Hash field lists ===

field_list lb_fields_ipv4 {
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
}

field_list lb_fields_ipv6 {
    inner_ipv6.srcAddr;
    inner_ipv6.dstAddr;
}

field_list_calculation lb_hash_ipv4 {
    input {
        lb_fields_ipv4;
    }
    algorithm : crc16;
    output_width : LB_HASH_IDX_LEN;
}

field_list_calculation lb_hash_ipv6 {
    input {
        lb_fields_ipv6;
    }
    algorithm : crc16;
    output_width : LB_HASH_IDX_LEN;
}

// === Header Instances ===

//header ethernet_t outer_eth;
header macs_t       outer_macs;
header vntag_t      vntag;
header etherType_t  outer_etherType;

header ipv4_t       outer_ipv4;
header ipv6_t       outer_ipv6;
header icmp_t       outer_icmp;
header tcp_t        outer_tcp;
header udp_t        outer_udp;
header gtpv1_t      gtpv1_hdr;
header ipv4_t       inner_ipv4;
header ipv6_t       inner_ipv6;
header gtpv1_opt_fields_t gtpv1_opts;
header genv_t       geneve_hdr;
header ethernet_t   inner_eth;
header gre_t        gre;
header fabricpath_t         fp_hdr;
header fabricpath_extra_t   fp_extra;

#define VLAN_DEPTH 2
header vlan_tag_t vlan_tag_[VLAN_DEPTH];

#define MPLS_DEPTH 8
header mpls_t mpls[MPLS_DEPTH];

metadata metadata_t meta;
metadata l2_metadata_t l2_metadata;
metadata l3_metadata_t l3_metadata;
metadata ipv4_metadata_t ipv4_metadata;
metadata ipv6_metadata_t ipv6_metadata;


//=====================
//      PARSER
//=====================

parser start {
    return lookahead_etherType;
}

parser lookahead_etherType {
    return select(current(108, 4)) {
            ETHERTYPE_VNTAG: parse_vntag;
            ETHERTYPE_FABRICPATH: parse_fabricpath;
            default : parse_outer_ethernet;
    }
}

parser parse_vntag {
    extract(outer_macs);
    extract(vntag);
    return parse_outer_etherType;
}

parser parse_fabricpath {
    // extract extra fields of Fabricpath:
    extract(fp_hdr);
    extract(fp_extra);
    return parse_outer_ethernet;    // now extract std ethernet frame hdr
}

parser parse_outer_ethernet {
    extract(outer_macs);
    return parse_outer_etherType;
}

parser parse_outer_etherType {
    extract(outer_etherType);
    return select(outer_etherType.etherType) {
        ETHERTYPE_VLAN : parse_vlan;
        ETHERTYPE_QINQ : parse_vlan;
        ETHERTYPE_QINQ_OBS : parse_vlan;
        ETHERTYPE_MPLS : parse_mpls;
        ETHERTYPE_IPV4: parse_outer_ipv4;
        ETHERTYPE_IPV6: parse_outer_ipv6;
        default: ingress;
    }
}

parser no_inner_tunnel {
    set_metadata(meta.inner_tunnel_type, TUNNEL_TYPE_NONE);
    return ingress;
}


parser parse_vlan {
    extract(vlan_tag_[next]);
    return select(latest.etherType) {
        ETHERTYPE_VLAN : parse_vlan;
        ETHERTYPE_MPLS : parse_mpls;
        default : ingress;
    }
}

parser parse_mpls {
    extract(mpls[next]);
    return select(latest.bos) {
        0 : parse_mpls;
        1 : parse_mpls_bos;
        default: ingress;
    }
}

parser parse_mpls_bos {
    return select(current(0, 4)) {
        0x0 : parse_mpls_pw_ctrl;
        0x4 : parse_mpls_inner_ipv4;
        0x6 : parse_mpls_inner_ipv6;
        default: no_inner_tunnel;
    }
}

parser parse_mpls_pw_ctrl {
    set_metadata(meta.pw_ctrl_word_present,1);
    set_metadata(meta.mpls_tunnel_type, TUNNEL_TYPE_NONE);
    return ingress;
}

parser parse_mpls_inner_ipv4 {
    set_metadata(meta.mpls_tunnel_type, TUNNEL_TYPE_IPV4);
        return parse_outer_ipv4;
}

parser parse_mpls_inner_ipv6 {
    set_metadata(meta.mpls_tunnel_type, TUNNEL_TYPE_IPV6);
        return parse_outer_ipv6;
}

parser parse_outer_ipv4 {
    extract(outer_ipv4);
    return select(outer_ipv4.protocol) {
        IP_PROTO_TCP: parse_outer_tcp;
        IP_PROTO_UDP: parse_outer_udp;
        IP_PROTO_GRE: parse_gre;
        default: ingress; // not UDP, punt
    }
}

parser parse_outer_ipv6 {
    extract(outer_ipv6);
    return select(outer_ipv6.nextHdr) {
        IP_PROTO_UDP: parse_outer_udp;
        default: ingress; // not UDP, punt
    }
}

parser parse_outer_udp {
    extract(outer_udp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
    return select(outer_udp.dstPort) {
        GTP_C_PORT_NUM: parse_gtpc;
        GTP_U_PORT_NUM: parse_gtpu;
        GENEVE_PORT_NUM: parse_geneve_hdr;
        default: parse_non_gtp;
    }
}

parser parse_outer_tcp {
    extract(outer_tcp);
    set_metadata(l3_metadata.lkp_l4_sport, latest.srcPort);
    set_metadata(l3_metadata.lkp_l4_dport, latest.dstPort);
   return ingress;
}

parser parse_gtpc {
    set_metadata(meta.lb_type, LB_TYPE_GTP_C);
    return ingress;  // don't parse or strip
}

parser parse_gtpu {
    return parse_gtpv1_hdr;
}

parser parse_non_gtp {
    set_metadata(meta.lb_type, LB_TYPE_NON_GTP);
    return ingress;
}

parser parse_gtpv1_hdr {
    extract(gtpv1_hdr);
    return select(gtpv1_hdr.e, gtpv1_hdr.s, gtpv1_hdr.pn) {
        0,0,0 :     parse_gtp_payload;
        default:    parse_gtpv1_opts;   // parse opt fields if ANY of the flag bits are set
    }
}

parser parse_gtpv1_opts {
    extract(gtpv1_opts);
    // TODO - extract more hdrs if e = 1
    return parse_gtp_payload;
}

parser parse_gtp_payload {
    // look at first nibble to determine IP type
    return select(current(0, 4)) {
        4: parse_gtp_inner_ipv4;
        6: parse_gtp_inner_ipv6;
        default: parse_gtp_inner_non_ip;
    }
}

parser parse_gtp_inner_ipv4 {
    set_metadata(meta.lb_type, LB_TYPE_GTP_U);
    return parse_inner_ipv4;
}

parser parse_inner_ipv4 {
    extract(inner_ipv4);
    set_metadata(meta.inner_tunnel_type, TUNNEL_TYPE_IPV4);
    return ingress;
}

parser parse_gtp_inner_ipv6 {
    set_metadata(meta.lb_type, LB_TYPE_GTP_U);
    return parse_inner_ipv6;
}

parser parse_inner_ipv6 {
    extract(inner_ipv6);
    set_metadata(meta.inner_tunnel_type, TUNNEL_TYPE_IPV6);
    return ingress;
}

parser parse_gtp_inner_non_ip {
    set_metadata(meta.lb_type, LB_TYPE_NON_IP);
    return ingress; // not IP, punt
}

parser parse_geneve_hdr {
    extract(geneve_hdr);
#ifdef GENEVE_OPTS // future
    return select(geneve_hdr.optLen) {
        0: parse_geneve_payload;
        default: parse_geneve_opts; // no Geneve options
    }
#else
    return parse_geneve_payload;
#endif
}

#ifdef GENEVE_OPTS // future
parser parse_geneve_opts {
        /* NOTE, below we extract potentially 260 bytes, consuming hdr resources. */
       //extract(geneve_opts, (bit<32>)((bit<16>)geneve_optLen * 32) ); // note typecasting is crucial
       return parse_geneve_payload;
}
#endif

parser parse_geneve_payload {
    return select(geneve_hdr.protoType) {
        ETHERTYPE_ETHERNET: parse_inner_eth;
        // TODO - inner ipv4, ipv6, ...
        default: ingress; // not ethernet bridging, punt
    }
}

parser parse_gre {
    extract(gre);
    return select(gre.proto) {
        ETHERTYPE_ETHERNET: parse_inner_eth;
        default: ingress;
    }
}

parser parse_inner_eth {
    extract(inner_eth);
    set_metadata(l2_metadata.lkp_mac_sa, latest.srcAddr);
    set_metadata(l2_metadata.lkp_mac_da, latest.dstAddr);
    return select(inner_eth.etherType) {
        ETHERTYPE_IPV4: parse_inner_ipv4;
        ETHERTYPE_IPV6: parse_inner_ipv6;
        default: ingress;
    }
}

//=====================
//      ACTIONS
//=====================

// === COMMON actions ===
action set_egr(egress_spec) {
#ifndef __TARGET_SIMPLE_SWITCH__
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec); // tofino only
#else
    modify_field(standard_metadata.egress_spec, egress_spec); // simple-switch only
#endif
}

action nop() {
}

action _drop() {
    drop();
}

// === MPLS Actions ===

// rewrite mpls payload's etherType to outer ethernet
action rewrite_outer_ethtype(etherType) {
    modify_field(outer_etherType.etherType, etherType);
}

// rewrite mpls payload's etherType to inner vlan tag
action rewrite_vlan0_ethtype(etherType) {
    modify_field(vlan_tag_[0].etherType, etherType);
}

// rewrite mpls payload's etherType to outer vlan tag
action rewrite_vlan1_ethtype(etherType) {
    modify_field(vlan_tag_[1].etherType, etherType);
}

action mpls_strip() {
    // blindly set all MPLS tags invalid
    remove_header(mpls[0]);
    remove_header(mpls[1]);
    remove_header(mpls[2]);
    remove_header(mpls[3]);
    remove_header(mpls[4]);
    remove_header(mpls[5]);
    remove_header(mpls[6]);
    remove_header(mpls[7]);
}

// === GTP Actions ===

action set_lb_hashed_index_ipv4() {
    modify_field_with_hash_based_offset(meta.lb_hash, 0,
                                        lb_hash_ipv4, LB_HASH_TBL_SZ);
}

action set_lb_hashed_index_ipv6() {
    modify_field_with_hash_based_offset(meta.lb_hash, 0,
                                        lb_hash_ipv6, LB_HASH_TBL_SZ);
}

// gtp_strip - mark outer fields invalid, only gtp payload remains
action gtp_strip() {
    remove_header(outer_ipv4);
    remove_header(outer_ipv6);
    remove_header(outer_udp);
    remove_header(gtpv1_hdr);
    remove_header(gtpv1_opts);
}

// rewrite outer dmac to contain tag fields upper byte
action rewrite_outer_dmac(mac) {
    modify_field(outer_macs.dstAddr, mac,0xFF0000000000);
}

// look up the weighted lb port number based on hashed values
action set_hashed_lb_port(lb_port) {
    modify_field(outer_macs.dstAddr,lb_port,0x00FF00000000);
}

// look up the port group number based on inner SIP
action set_lb_group(group_num) {
    modify_field(meta.lb_port_group, group_num);
}

//=== FABRICPATH actions ===
    
action fp_strip() {
    remove_header(fp_hdr);
    remove_header(fp_extra);
}

//=== VNTAG actions ===

action vntag_strip() {
    remove_header(vntag);
}

//=== GENEVE actions ===

// geneve_strip - mark outer fields invalid, only geneve payload remains
action geneve_strip() {
    remove_header(outer_macs);
    remove_header(outer_etherType);
    remove_header(outer_ipv4);
    remove_header(outer_udp);
    remove_header(geneve_hdr);
}

//=== GRE actions

// l2gre_decap -  remove outer eth|ipv4|GRE
action l2gre_decap() {
    remove_header(outer_macs);
    remove_header(outer_etherType);
    remove_header(outer_ipv4);
    remove_header(gre);
}

// l2gre_encap -  wrap L2 payload in eth|ipv4|GRE
action l2gre_encap(
        smac,           // our smac
        dmac,           // dmac of next hop
        sip,            // tunnel src IP
        dip)            // tunnel dst IP
{
        modify_field(inner_eth.dstAddr, outer_macs.dstAddr);
        modify_field(inner_eth.srcAddr, outer_macs.srcAddr);
        modify_field(inner_eth.etherType, outer_etherType.etherType);
        modify_field(outer_macs.dstAddr, dmac); // from table
        modify_field(outer_macs.srcAddr, smac); // from table
        modify_field(outer_etherType.etherType, ETHERTYPE_IPV4);

        copy_header(inner_ipv4, outer_ipv4);
        modify_field(outer_ipv4.srcAddr, sip);  // from table
        modify_field(outer_ipv4.dstAddr, dip);  // from table
        modify_field(outer_ipv4.version, 4);    // ipv4
        modify_field(outer_ipv4.ihl, 5);        // no options
        modify_field(outer_ipv4.diffserv, 0);   // note - could make programmable
        add_to_field(outer_ipv4.totalLen, 18); // inner ip4v4 + inner eth + GRE hdr(4)
        modify_field(outer_ipv4.identification, 0);
        modify_field(outer_ipv4.flags, 0); // don't handle fragments
        modify_field(outer_ipv4.fragOffset, 0);
        modify_field(outer_ipv4.ttl, 64);   // NOTE could make programmable
        modify_field(outer_ipv4.protocol, IP_PROTO_GRE); //GRE
        modify_field(outer_ipv4.hdrChecksum, 0);    // TODO - compute checksum

        add_header(gre);
        modify_field(gre.C, 0);
        modify_field(gre.R, 0);
        modify_field(gre.K, 0);
        modify_field(gre.S, 0);
        modify_field(gre.s, 0);
        modify_field(gre.recurse, 0);
        modify_field(gre.flags, 0);
        modify_field(gre.ver, 0);
        modify_field(gre.proto, ETHERTYPE_ETHERNET); // TODO <=== not setting!
}

//=== ACL Actions ===
action acl_deny() {
    drop();
}

action acl_permit(egress_spec) {
    set_egr(egress_spec);   // TODO - multicast, etc.
}

//=====================
//      TABLES
//=====================
 

// == COMMON TABLES ===
   
table fwd_tbl {
    reads {
        ig_intr_md.ingress_port:exact;      // map input port to output port
    }

    actions { 
        set_egr;
        _drop;
    }
    max_size: 16;
}

table rewrite_tbl {
    reads {
        vlan_tag_[0]:               valid;
        vlan_tag_[1]:               valid;
        meta.mpls_tunnel_type:      ternary;
        meta.inner_tunnel_type:     ternary;
    }

    actions { 
        rewrite_outer_ethtype;
        rewrite_vlan0_ethtype;
        rewrite_vlan1_ethtype;
        nop;
    }
    default_action: nop;
    max_size: 16;
}

// === MPLS Tables
   
table mpls_tbl {
    reads {
        ig_intr_md.ingress_port:exact;      // use port to gate MPLS stripping
        mpls[0]:                    valid; // true if any MPLS labels
        meta.pw_ctrl_word_present:  exact; // only strip non-IPv4/6 if pw word present
        meta.mpls_tunnel_type:      exact;

    }

    actions { 
        mpls_strip;
        nop;
    }
    default_action: nop;
    max_size: 16;
}
// FABRICPATH tables
 
table fp_tbl {
    reads {
        fp_hdr: valid; // execute specified action if this packet is fabricpath only
        ig_intr_md.ingress_port:exact;      // use port to gate MPLS stripping
    }

    actions {   // simple_CLI commands to set table entry accordingly shown below:
        fp_strip; // table_add fp_tbl fp_strip 1 1 =>
        nop;
    }
    default_action: nop;
    max_size: 256; // per-port control
}

// === GTP Tables

// GTP strip on/off control
table gtp_tbl {
    reads {
        gtpv1_hdr:              valid; 
        ig_intr_md.ingress_port:exact;      // use port to gate GTP stripping
    }

    actions {
        gtp_strip;  // table_add gtp_tbl gtp_strip 1 1 =>
        nop;
    }
    default_action: nop;
    max_size: 256; // map up to 256 ports
}

/*
  map hashed inner IP addr to weighted lb tool portnumber
  port numbers must be shifted left 32 bits so the PPPPPPP field is bit-aligned with dmac
  
  Python code:
ports=[0x11,0x22,0x33]
  
ports=[0x11,0x22,0x33]
p=0
for i in range(16):
  print("table_add lb_weight_tbl set_hashed_lb_port 1 %d => 00:%02x:00:00:00:00") % (i,ports[p])
  p = (p+1)%3
  
 */ 
table lb_weight_tbl {
    // table_add lb_weight_tbl set_hashed_lb_port 0 => 0x11
    reads {
        gtpv1_hdr:      valid; 
        meta.lb_hash:   exact; // this is the hashed index
    }
    actions {
        set_hashed_lb_port;
    }
    size : LB_HASH_TBL_SZ;
}

/*
  rewrite outer dmac upper byte w/ GTP LB fields
  table inflates the 2 & 3-bit fields into 32 48-bit values where upper byte contains:
    type group
        |   |
     \bTT0GGG10 \b00000000 .. etc.
  
   This is aligned with dmac and can be ORed into it with a mask 0xFF0000000000
Python code to generate CLI commands:
for t in range(4):
  for g in range(8):
    b=(t<<6)+(g<<2)+2
    print ("table_add rewrite_dmac_tbl rewrite_outer_dmac 1 2 %d %d => 0x%02x0000000000") % (t,g,b)
    print ("table_add rewrite_dmac_tbl rewrite_outer_dmac 1 3 %d %d => 0x%02x0000000000") % (t,g,b)
*/
table rewrite_dmac_tbl {
    reads {
        gtpv1_hdr:                  valid; // must be gtp hdr
        meta.inner_tunnel_type:     exact; // 2 or 3 for IPv4 or IPv6
        meta.lb_type:               exact; // next 2 fields have 32 combinations which get mapped to to hi byte
        meta.lb_port_group:         exact; // including fill bits
    }
    actions { 
        rewrite_outer_dmac;
    }
    max_size: 64;
}

// look up outer SIP subnet, assign to one of 4 groups 0-3; on miss, assign to group 4
// table_set_default lb_group_tbl set_lb_group 4
// table_add lb_group_tbl set_lb_group 172.1.0.0&&&255.255.0.0 => 1 0
table lb_group_tbl_ipv4 {
    reads {
        outer_ipv4.srcAddr: ternary;
    }
    actions {
        set_lb_group;
    }
    
    max_size: 16;
}
// table_add lb_group_tbl set_lb_group 1:2:3:4:5:6:7:8&&&255:255:255:255:0:0:0:0 => 2 0
table lb_group_tbl_ipv6 {
    reads {
        outer_ipv6.srcAddr: ternary;
    }
    actions {
        set_lb_group;
    }
    max_size: 16;
}

table compute_inner_ip_hash_tbl_ipv4 {
    actions {
        set_lb_hashed_index_ipv4;
    }
   default_action: set_lb_hashed_index_ipv4;
   size: 1;
}

table compute_inner_ip_hash_tbl_ipv6 {
    actions {
        set_lb_hashed_index_ipv6;
    }
   default_action: set_lb_hashed_index_ipv6;
   size: 1;
}

//=== GENEVE Tables ===

table geneve_tbl {
    reads {
            geneve_hdr:             valid; 
            ig_intr_md.ingress_port:                exact; 
            // FUTURE - add criteria for stripping, e.g. vni, others?
    }

    actions {       // simple_CLI commands to set table entry accordingly shown below:
        geneve_strip; // table_add geneve_tbl geneve_strip 1 =>
        nop;
    }
    default_action: nop;
    max_size: 256; // map up to 256 ports
}

//=== L2GRE Tables ===

table l2gre_encap_tbl {
        reads {
            ig_intr_md.ingress_port:    exact; 
        }
       actions {   
            l2gre_encap;
            nop;
    }
    default_action: nop;
    max_size: 256; // map up to 256 ports
}
table l2gre_decap_tbl {
        reads {
            gre:                        valid;
            ig_intr_md.ingress_port:    exact; 
        }
       actions {   
            l2gre_decap;
            nop;
    }
    default_action: nop;
    max_size: 256; // map up to 256 ports
}

//=== VNTAG Tables
table vntag_tbl {
    reads {
        vntag: valid;
            ig_intr_md.ingress_port:    exact; 
    }
    actions {
        vntag_strip;
            nop;
    }
    default_action: nop;
    max_size: 256; // map up to 256 ports
}

//===ACL Tables ===
@pragma entries_with_ranges 40
table acl_tbl {
    reads {
        l2_metadata.lkp_mac_sa : ternary;
        l2_metadata.lkp_mac_da : ternary;
        l2_metadata.lkp_mac_type : ternary;
        ipv4_metadata.lkp_ipv4_sa : ternary;
        ipv4_metadata.lkp_ipv4_da : ternary;
        l3_metadata.lkp_ip_proto : ternary;
        l3_metadata.lkp_l4_sport : range;
        l3_metadata.lkp_l4_dport : range;
        // uncomment next two lines, div-by-0 error
#ifndef CASE_FIX
        l3_metadata.lkp_outer_l4_sport : range;
        l3_metadata.lkp_outer_l4_dport : range;
#endif
        //outer_tcp.flags : ternary;
        l3_metadata.lkp_ip_ttl : ternary;
    }
    actions {
        nop;
        acl_deny;
        acl_permit;
        // TODO - mirror, ecmp, multicast
    }
    default_action: nop;
    size : INGRESS_IP_ACL_TABLE_SIZE;
}


//=====================
//      INGRESS CTRL
//=====================

control ingress {
    if (meta.inner_tunnel_type == TUNNEL_TYPE_IPV4) {
        apply(compute_inner_ip_hash_tbl_ipv4);
    } else if (meta.inner_tunnel_type ==TUNNEL_TYPE_IPV6) {
        apply(compute_inner_ip_hash_tbl_ipv6);
    }
    // TODO - strip fp/vntag then extract outer IPs?
    apply(fp_tbl);
    apply(vntag_tbl);
	apply(lb_weight_tbl);

	// only lookup outer IP if valid, because default acion assigns group 4
	// and if didn't check valid first, would result in miss -> default
	if (valid(outer_ipv4)) {
		apply(lb_group_tbl_ipv4);
	}
	if (valid(outer_ipv6)) {
		apply(lb_group_tbl_ipv6);
	}
    apply(mpls_tbl);
    apply(geneve_tbl);
    apply(l2gre_decap_tbl);
	apply(rewrite_dmac_tbl);
	apply(acl_tbl) {
		miss {
			apply(fwd_tbl);
		}
	}
    
}

//=====================
//      EGRESS CTRL
//=====================

control egress {
	if (meta.lb_type == LB_TYPE_GTP_U) {
		// only strip GTP-U
    	apply(gtp_tbl);
    }
    apply(rewrite_tbl);
	apply(l2gre_encap_tbl);
}

