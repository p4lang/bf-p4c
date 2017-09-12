/* -*- P4_14 -*- */

/*
 *   gtp.p4 - gtp stripping + "Chronos40" GTP load-balancing. csommers 2017-07-05
 *
 *   Parses Ethernet|ip[46]|UDP(dport=6081)|GTP|ip[46] and extracts inner IP incl. dip,sip.
 *   Forms hash of dip,sip, use as index into "portnum" table for weighted load-balancing.
 *   Derives 2-bit "type" field based on parsing and modifies outgoing dmac.
 *   Modify outgoing dmac with 8-bit portnum from hash table.
 *   Derives group number by performing ternary lookup on outer SIP, modifies 3 bits of dmac 
 *   If stripping enabled via table entry, then discard outer ip, UDP, GTP and send tunneled payload inside outer ethernet.
 *   Limitations - no VLAN, MPLS, etc. Only handles the above nesting, else just send out unmodified.
 *
 *   See commands.txt for table programming
 *
 */

#include <tofino/intrinsic_metadata.p4> // tofino only
#include <tofino/constants.p4> // tofino only

//=====================
//      DEFINES
//=====================

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_IPV6 0x86dd
#define ETHERTYPE_MPLS 0x8847
#define ETHERTYPE_VLAN 0x8100
#define ETHERTYPE_QINQ 0x88A8
#define ETHERTYPE_QINQ_OBS 0x9100
#define GTP_C_PORT_NUM 2123
#define GTP_U_PORT_NUM 2152
#define ETHERTYPE_ETHERNET 0x6558
#define IP_PROTO_UDP 17

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


#define LB_HASH_TBL_SZ  16 // 1024
#define LB_HASH_IDX_LEN 4 // 10

/* BUG: If enable both IPv4 & IPv6 hash get compiler error
ERROR: Internal MAU Compiler Error
Attempting to utilize multiple hash distribution units for same Immediate in logical table 0 in stage 3.
  HDU 0 and 3.
    */
#define GTP_IPV4_TUNNEL
#define GTP_IPV6_TUNNEL

/* BUG: if parse sub-byte fields of dmac, get compiler error
SPHagrb0c|ERROR: 
+------------------------------------------------------+
Unable to perform PHV allocation.
+------------------------------------------------------+
Unable to allocate field instance group used in parse node parse_outer_eth (2) (ingress).
   outer_eth.lb_type <2 bits ingress parsed W>
   outer_eth.zero_fill <1 bits ingress parsed W>
   outer_eth.lb_group <3 bits ingress parsed W>
   outer_eth.one_zero_fill <2 bits ingress parsed W>
   outer_eth.lb_port <8 bits ingress parsed W>
   outer_eth.lower_dmac <32 bits ingress parsed tagalong>
   outer_eth.srcAddr <48 bits ingress parsed tagalong>
   outer_eth.etherType <16 bits ingress parsed tagalong>
Failure Reasons:
  Field violates source operand constraints (case 700) -- tried 520 variants

No valid packing options.

 */

//#define MAC_SPLIT_UPPER

//=====================
//      HEADERS
//=====================


header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

    /*
      Rewrite spec for dmac:

      type group    portnum
        |   |         |
      \bTT0GGG10 \bPPPPPPPP <original lower 32 bits of dmac>

      Where:

      Type = lb_type as determined by parser (see #defines)

      GGG = Group looked up in a classifer table (TBD)

      Portnum = lookup into load-balancer table based on hashed inner sip/dip
      
    */

/* following header contains fields intended to overwritten for some GTP cases */
header_type ethernet_split_dmac_t {
    fields {
#ifdef MAC_SPLIT_UPPER
        lb_type         : 2;    // lb type based on parsing outcome
        zero_fill       : 1;    // fixed value \b0
        lb_group        : 3;    // group derived from SIP lookup table
        one_zero_fill   : 2;    // fixed value = \b10
#else
        mac_upper_byte  : 8;    // temp until solve PHV alloc. error
#endif
        lb_port         : 8;    // portnum from weighted LB hashtable
        lower_dmac      : 32;   // unmodified remainder of dmac
        srcAddr         : 48;
        etherType       : 16;
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

header_type metadata_t {
    fields {
        tunnel_type         : 3;    // determined from GTP payload
        lb_type             : 2;    // dmac field TT in Chronos40 spec
        lb_port_group       : 3;    // dmac field GGG in Chronos40 spec
        lb_port_num         : 8;    // hashed port num from lb table, becomes PPPPPPPP field in dmac
        zero_fill           : 1;    // fixed value \b0
        one_zero_fill       : 2;    // fixed value = \b10
        lb_hash             : LB_HASH_IDX_LEN;  // computed from hash fields
    }
}

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

//header ethernet_t outer_eth;
header ethernet_split_dmac_t    outer_eth;
header ipv4_t       outer_ipv4;
header ipv6_t       outer_ipv6;
header udp_t        outer_udp;
header gtpv1_t      gtpv1_hdr;
header ipv4_t       inner_ipv4;
header ipv6_t       inner_ipv6;
header gtpv1_opt_fields_t gtpv1_opts;

metadata metadata_t meta;


//=====================
//      PARSER
//=====================

parser start {
    return parse_outer_eth;
}

parser parse_outer_eth {
    extract(outer_eth);
    return select(outer_eth.etherType) {
        ETHERTYPE_IPV4: parse_outer_ipv4;
        ETHERTYPE_IPV6: parse_outer_ipv6;
        default: ingress;
    }
}

parser parse_outer_ipv4 {
    extract(outer_ipv4);
    return select(outer_ipv4.protocol) {
        IP_PROTO_UDP: parse_outer_udp;
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
    return select(outer_udp.dstPort) {
        GTP_C_PORT_NUM: parse_gtpc;
        GTP_U_PORT_NUM: parse_gtpu;
        default: ingress; // not gtp, punt
         }
    }

parser parse_gtpc {
    set_metadata(meta.lb_type, LB_TYPE_GTP_C);
    return parse_gtpv1_hdr;
}

parser parse_gtpu {
    set_metadata(meta.lb_type, LB_TYPE_GTP_U);
    return parse_gtpv1_hdr;
}

parser parse_non_gtp {
    set_metadata(meta.lb_type, LB_TYPE_NON_GTP);
    return ingress;
}

parser parse_gtpv1_hdr {
    extract(gtpv1_hdr);
    set_metadata(meta.zero_fill, 0);
    set_metadata(meta.one_zero_fill, 2);
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
        4: parse_inner_ipv4;
        6: parse_inner_ipv6;
        default: ingress; // not IP, punt
    }
}

parser parse_inner_ipv4 {
    extract(inner_ipv4);
    set_metadata(meta.tunnel_type, TUNNEL_TYPE_IPV4);
    return ingress;
}

parser parse_inner_ipv6 {
    extract(inner_ipv6);
    set_metadata(meta.tunnel_type, TUNNEL_TYPE_IPV6);
    return ingress;
}

parser parse_inner_non_ip {
    set_metadata(meta.lb_type, LB_TYPE_NON_IP);
    return ingress;
}

//=====================
//      ACTIONS
//=====================

action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec); // tofino only
}

action _drop() {
    drop();
}

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
    remove_header(outer_udp);
    remove_header(gtpv1_hdr);
    remove_header(gtpv1_opts);
}

// rewrite outer ethertype with ipv4 tunnel's ethertype
action rewrite_outer_ethtype_ipv4() {
    modify_field(outer_eth.etherType, ETHERTYPE_IPV4);
}

// rewrite outer ethertype with ipv6 tunnel's ethertype
action rewrite_outer_ethtype_ipv6() {
    modify_field(outer_eth.etherType, ETHERTYPE_IPV6);
}

// rewrite outer dmac to contain tag fields
action rewrite_outer_dmac() {
    /*
      Rewrite spec for dmac:

      type group    portnum
        |   |         |
      0xTT0GGG10 0xPPPPPPPP <original lower 32 bits of dmac>

      Where:

      Type = lb_type as determined by parser (see #defines)

      GGG = Group looked up in a classifer table (TBD)

      Portnum = lookup into load-balancer table based on hashed inner sip/dip
    */

#ifdef MAC_SPLIT_UPPER
    modify_field(outer_eth.lb_type, meta.lb_type);
    modify_field(outer_eth.zero_fill, meta.zero_fill);
    modify_field(outer_eth.one_zero_fill, meta.one_zero_fill);
    modify_field(outer_eth.lb_group, meta.lb_port_group);
#endif
    modify_field(outer_eth.lb_port, meta.lb_port_num);


}

// look up the weighted lb port number based on hashed values
action set_hashed_lb_port(lb_port) {
    modify_field(meta.lb_port_num, lb_port);
}

// look up the port group number based on inner SIP
action set_lb_group(group_num) {
    modify_field(meta.lb_port_group, group_num);
}

//=====================
//      TABLES
//=====================
  
// GTP strip on/off control
table gtp_tbl {
    reads {
        gtpv1_hdr:              valid; 
    }

    actions {
        gtp_strip;  // table_add gtp_tbl gtp_strip 1 =>
    }
    max_size: 1;
}

// rewrite tunnel ethertype to outer eth, also generate hashed inner IPs
table compute_inner_ip_hash_tbl {
    reads {
        meta.tunnel_type:   exact;
    }

    actions { 
#ifdef GTP_IPV4_TUNNEL
        // table_add compute_inner_ip_hash_tbl set_lb_hashed_index_ipv4 2 => 
        set_lb_hashed_index_ipv4;
#endif

#ifdef GTP_IPV6_TUNNEL
        // table_add compute_inner_ip_hash_tbl set_lb_hashed_index_ipv6 3 => 
        set_lb_hashed_index_ipv6;
#endif
    }
    max_size: 8;
}

// rewrite tunnel ethertype to outer eth, also generate hashed inner IPs
table rewrite_tunnel_tbl {
    reads {
        meta.tunnel_type:   exact;
    }

    actions { 
#ifdef GTP_IPV4_TUNNEL
        // table_add rewrite_tunnel_tbl rewrite_outer_ethtype_ipv4 2 => 
        rewrite_outer_ethtype_ipv4;
#endif

#ifdef GTP_IPV6_TUNNEL
        // table_add rewrite_tunnel_tbl rewrite_outer_ethtype_ipv6 3 => 
        rewrite_outer_ethtype_ipv6;
#endif
    }
    max_size: 8;
}

// map input port to output port
table fwd_tbl {
    reads {
        ig_intr_md.ingress_port:exact;      // map input port to output port
    }

    actions { 
        set_egr;
        _drop;
    }
    max_size: 8;
}

// map hashed inner IP addr to weighted lb tool portnumber
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

// rewrite outer dmac upper two bytes w/ GTP LB fields
table rewrite_dmac_tbl {
    reads {
        gtpv1_hdr:          valid; 
        meta.tunnel_type:   exact;
    }
    actions { 
        rewrite_outer_dmac;
    }
    max_size: 2;
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

//=====================
//      INGRESS CTRL
//=====================

control ingress {
	apply(compute_inner_ip_hash_tbl);
	apply(lb_weight_tbl);
	apply(lb_group_tbl_ipv4);
	apply(lb_group_tbl_ipv6);

	apply(rewrite_dmac_tbl);
    apply(fwd_tbl);
}

//=====================
//      EGRESS CTRL
//=====================

control egress {
    apply(gtp_tbl);
	apply(rewrite_tunnel_tbl);  // won't trigger if tunnel type = 0 i.e. none
}

