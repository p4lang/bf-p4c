#include <t2na.p4>
# 1 "npb.p4"
# 36 "npb.p4"
# 1 "features_t2.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

// List of all supported #define directives.

// ===== pkt header defines =================================

// ----- applies to: transport -----
# 37 "features_t2.p4"
// ----- applies to: outer -----
# 48 "features_t2.p4"
// ----- applies to: inner -----



// ----- applies to: outer and inner -----



// ===== feature defines ====================================

// ----- parser -----
# 69 "features_t2.p4"
// ----- switch: mirroring -----





// ----- switch: cpu -----
# 84 "features_t2.p4"
// ----- switch: dtel -----






// ----- switch: other -----

// #define QINQ_ENABLE
// #define QINQ_RIF_ENABLE




// ----- npb: sfc -----






// ----- npb: sff -----




// ----- npb: sf #0 -----
# 124 "features_t2.p4"
// ----- npb: sf #2  -----
# 139 "features_t2.p4"
// ----- tofino 1 fitting -----





// ----- debug and miscellaneous -----




// ----- bug fixes -----


// ----- other wanted / needed features that don't fit -----
# 37 "npb.p4" 2


# 1 "field_widths.p4" 1






    // -------------------------------------
    // Switch Widths
    // -------------------------------------
# 28 "field_widths.p4"
    // -------------------------------------
    // NPB Widths
    // -------------------------------------
# 40 "npb.p4" 2
# 1 "table_sizes.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




// --------------------------------------------




// --------------------------------------------

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Tofino 1
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
# 194 "table_sizes.p4"
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Tofino 2
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Switch
// -----------------------------------------------------------------------------

const bit<32> PORT_TABLE_SIZE = 256;

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// IP Hosts/Routes
const bit<32> RMAC_TABLE_SIZE = 64;

// 16K MACs
const bit<32> MAC_TABLE_SIZE = 1024;

// Tunnels - 4K IPv4 + 1K IPv6
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 64; // ingress
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 256; // ingress
const bit<32> IPV6_DST_TUNNEL_TABLE_SIZE = 64; // ingress
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 256; // ingress

const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512; // egress
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 1024; // egress
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 32; // egress
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 256; // egress

// ECMP/Nexthop
const bit<32> NEXTHOP_TABLE_SIZE = 8192;
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024; // derek: unused; removed this table
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384; // derek: unused; removed this table

// ECMP/Nexthop
const bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096; // aka NUM_TUNNELS
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096; // derek: unused in switch.p4
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE = 16384; // derek: unused; changed table type to normal table

// Lag
const bit<32> LAG_TABLE_SIZE = 1024; // switch.p4 was 1024
const bit<32> LAG_GROUP_TABLE_SIZE = 32; // switch.p4 was 256
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64; // switch.p4 was 64
const bit<32> LAG_SELECTOR_TABLE_SIZE = 2048; // 256 * 64 // switch.p4 was 16384

// Ingress ACLs
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 2048; // derek: was told to change this from the 512 in the spec.
//const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE                          = 8192; // derek: ideally this should be 8192
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144; // derek: ideally this should be 8192
//const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE                          = 4096; // derek: ideally this should be 8192
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024;

// Egress ACL
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 128;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 128;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 128;

const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 512;
const bit<32> DTEL_GROUP_TABLE_SIZE = 4;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> DTEL_SELECTOR_TABLE_SIZE = 256;

// -----------------------------------------------------------------------------
// NPB
// -----------------------------------------------------------------------------

// net intf

// sfc -- classifies non-nsh packets
const bit<32> NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH = 8192;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH = 8192; // unused now
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH = 1024; // was 256;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH = 8192;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 256;
const bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH = 8192; // derek, what size to make this?

// sf #0 -- basic / advanced
const bit<32> NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH = 128;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH = 128;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH = 128;

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_FLW_CLS_TABLE_DEPTH = 128;
const bit<32> NPB_ING_SFF_SCHD_TABLE_SIZE = 64;
const bit<32> NPB_ING_SFF_SCHD_GROUP_TABLE_SIZE = 32;
const bit<32> NPB_ING_SFF_SCHD_MAX_MEMBERS_PER_GROUP = 32;
const bit<32> NPB_ING_SFF_SCHD_SELECTOR_TABLE_SIZE = 1024; // 32 * 32
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH = 8192;

// sf #1 -- replication
const bit<32> NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE = 2096;

// sf #2 -- tool proxy
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH = 8192;

const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH= 128;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH= 128;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH= 128;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH = 8; // unused in latest spec
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH = 8; // unused in latest spec
# 41 "npb.p4" 2
# 1 "headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

//////////////////////////////////////////////////////////////
// Layer2 Headers
//////////////////////////////////////////////////////////////
/*
@pa_container_size("ingress", "hdr.transport.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.transport.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.transport.ethernet.$valid", 16)
@pa_container_size("ingress", "hdr.outer.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.outer.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.outer.ethernet.$valid", 16)
@pa_container_size("ingress", "hdr.inner.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.inner.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.inner.ethernet.$valid", 16)
*/
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header vlan_tag_grouped_h {
    bit<16> pcp_cfi_vid;
    bit<16> ether_type;
}

header e_tag_h {
    bit<3> pcp;
    bit<1> dei;
    bit<12> ingress_cid_base;
    bit<2> rsvd_0;
    bit<2> grp;
    bit<12> cid_base;
    bit<16> rsvd_1;
    bit<16> ether_type;
}

header vn_tag_h {
    bit<1> dir;
    bit<1> ptr;
    bit<14> dvif_id;
    bit<1> loop;
    bit<3> rsvd;
    bit<12> svif_id;
    bit<16> ether_type;
}


//////////////////////////////////////////////////////////////
// Layer3 Headers
//////////////////////////////////////////////////////////////

// Address Resolution Protocol -- RFC 6747

header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> tos;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}


  header ipv6_h {
      bit<4> version;
      bit<8> tos;
      bit<20> flow_label;
      bit<16> payload_len;
      bit<8> next_hdr;
      bit<8> hop_limit;
      ipv6_addr_t src_addr;
      ipv6_addr_t dst_addr;
}


header dummy_h {
      bit<8> unused;
}


//////////////////////////////////////////////////////////////
// Layer4 Headers
//////////////////////////////////////////////////////////////

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
    bit<16> checksum;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header sctp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> verifTag;
    bit<32> checksum;
}


//////////////////////////////////////////////////////////////
// Transport Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// NSH
//-----------------------------------------------------------

// NSH Base Header (word 0, base word 0)
header nsh_base_h {
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;
}

// NSH Service Path Header (word 1, base word 1)
header nsh_svc_path_h {
    bit<24> spi;
    bit<8> si;
}

// NSH MD Type1 (Fixed Length) Context Header (word 2, ext type 1 words 0-3)
header nsh_md1_context_h {
    bit<128> md;
}

// fixed sized version of this is needed for lookahead (word 2, ext type 2 word 0)
header nsh_md2_context_fixed_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
}

// Single, Fixed Sized Extreme NSH Header (external)
header nsh_type1_h {
    // word 0: base word 0
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;

 // --------------------

    // word 1: base word 1
    bit<24> spi;
    bit<8> si;

 // --------------------

    // word 2: ext type 1 word 0-3
 bit<8> ver; // word 0
//	bit<8>                          scope;     // word 0
 bit<8> reserved3; // word 0
//	bit<16>                         reserved3; // word 0
 bit<16> lag_hash; // word 0

 bit<16> vpn; // word 1
 bit<16> sfc_data; // word 1

 bit<8> reserved4; // word 2
 bit<8> scope; // word 2
 bit<16> sap; // word 2

 bit<32> timestamp; // word 3
}


//-----------------------------------------------------------
// ERSPAN
//-----------------------------------------------------------

// ERSPAN Type II -- IETFv3
header erspan_type2_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// ERSPAN Type III -- IETFv3
header erspan_type3_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_bso_t;
    bit<10> session_id;
    bit<32> timestamp;
    bit<16> sgt; // Security group tag
    bit<1> p;
    bit<5> ft; // Frame type
    bit<6> hw_id;
    bit<1> d; // Direction
    bit<2> gra; // Timestamp granularity
    bit<1> o; // Optional sub-header
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}



//////////////////////////////////////////////////////////////
// LayerX Headers
//////////////////////////////////////////////////////////////

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

// (end of) MPLS pseudo wire control word (RFC 4448)
header mpls_pw_cw_h {
    bit<4> zeros;
    bit<12> rsvd;
    bit<16> seqNum;
}


//////////////////////////////////////////////////////////////
// Tunnel Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// VXLAN
//-----------------------------------------------------------

header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Protocol Extension for VXLAN -- IETFv4
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8> reserved2;
}


//-----------------------------------------------------------
// GRE
//-----------------------------------------------------------

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R; // deprecated in RFC 2784
    bit<1> K; // deprecated in RFC 2784, brought back in RFC 2890
    bit<1> S; // deprecated in RFC 2784, brought back in RFC 2890
    bit<1> s; // deprecated in RFC 2784
    bit<3> recurse; // deprecated in RFC 2784
    bit<5> flags; // deprecated in RFC 2784
    bit<3> version;
    bit<16> proto;
}

header gre_optional_h {
    bit<32> data;
}

header gre_extension_sequence_h {
    bit<32> seq_num;
}


//-----------------------------------------------------------
// NVGRE
//-----------------------------------------------------------

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}


//-----------------------------------------------------------
// ESP - IPsec
//-----------------------------------------------------------

header esp_h {
    //bit<32> spi;
    bit<16> spi_hi;
    bit<16> spi_lo;
    bit<32> seq_num;
}


//-----------------------------------------------------------
// GTP
//-----------------------------------------------------------
// GTP-U: v1
// GTP-C: v2

header gtp_v1_base_h {
    bit<3> version;
    bit<1> PT;
    bit<1> reserved;
    bit<1> E;
    bit<1> S;
    bit<1> PN;
    bit<8> msg_type;
    bit<16> msg_len;
    bit<32> teid;
}

header gtp_v1_optional_h {
    bit<16> seq_num;
    bit<8> n_pdu_num;
    bit<8> next_ext_hdr_type;
}

// header gtp_v1_extension_h {
//     bit<8>       ext_len;
//     varbit<8192> contents;
//     bit<8>       next_ext_hdr;
// }

header gtp_v2_base_h {
    bit<3> version;
    bit<1> P;
    bit<1> T;
    bit<3> reserved;
    bit<8> msg_type;
    bit<16> msg_len;
    bit<32> teid;
    //bit<24> seq_num;
    //bit<8>  spare;
}



//////////////////////////////////////////////////////////////
// Layer7 Headers (aka UDF)
//////////////////////////////////////////////////////////////

header udf_h {
    bit<128> opaque;
}




//////////////////////////////////////////////////////////////
// DTel
//////////////////////////////////////////////////////////////

// Telemetry report header -- version 0.5
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v0_5.pdf
header dtel_report_v05_h {
    bit<4> version;
    bit<4> next_proto;
    bit<3> d_q_f;
    bit<15> reserved;
    bit<6> hw_id;
    bit<32> seq_number;
    bit<32> timestamp;
    bit<32> switch_id;
}

// DTel report base header
header dtel_report_base_h {



    bit<7> pad0;

    PortId_t ingress_port;



    bit<7> pad1;

    PortId_t egress_port;




    bit<1> pad2;
    bit<7> queue_id;

}

// DTel drop report header
header dtel_drop_report_h {
    bit<8> drop_reason;
    bit<16> reserved;
}

// DTel switch local report header
header dtel_switch_local_report_h {
    bit<5> pad3;
    bit<19> queue_occupancy;
    bit<32> timestamp;
}

// Telemetry report header -- version 1.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v1_0.pdf
header dtel_report_v10_h {
    bit<4> version;
    bit<4> length;
    bit<3> next_proto;
    bit<6> metadata_bits;
    bit<6> reserved;
    bit<3> d_q_f;
    bit<6> hw_id;
    bit<32> switch_id;
    bit<32> seq_number;
    bit<32> timestamp;
}

// Telemetry report header -- version 2.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v2_0.pdf
header dtel_report_v20_h {
    bit<4> version;
    // Telemetry Report v2.0 hw_id is 6 bits, however due to p4 constraints,
    // shrinking it to 4 bits
    bit<4> hw_id;
    // Telemetry Report v2.0 seq_number is 22 bits, however due to p4
    // constraints, expanding it to 24 bits, always leaving the top 2 bits as 0
    bit<24> seq_number;
    bit<32> switch_id;
    // Due to p4 constraints, need to treat the following as one field:
    // bit<4> rep_type;
    // bit<4> in_type;
    // bit<16> report_length;
    bit<16> report_length;
    bit<8> md_length;
    bit<3> d_q_f;
    bit<5> reserved;
    bit<16> rep_md_bits;
    bit<16> domain_specific_id;
    bit<16> ds_md_bits;
    bit<16> ds_md_status;
}

// Optional metadata present in the telemetry report.
header dtel_metadata_1_h {



    bit<7> pad0;

    PortId_t ingress_port;



    bit<7> pad1;

    PortId_t egress_port;
}

header dtel_metadata_2_h {
    bit<32> hop_latency;
}

header dtel_metadata_3_h {




    bit<1> pad2;
    bit<7> queue_id;

    bit<5> pad3;
    bit<19> queue_occupancy;
}

header dtel_metadata_4_h {
    bit<16> pad;
    bit<48> ingress_timestamp;
}

header dtel_metadata_5_h {
    bit<16> pad;
    bit<48> egress_timestamp;
}

header dtel_report_metadata_15_h {




    bit<1> pad;
    bit<7> queue_id;

    bit<8> drop_reason;
    bit<16> reserved;
}

//////////////////////////////////////////////////////////////
// Barefoot Specific Headers
//////////////////////////////////////////////////////////////

header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
}

// CPU header
header cpu_h {
    bit<5> egress_queue;
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<16> ingress_port;
    bit<16> port_lag_index;
    bit<16> ingress_bd;
    bit<16> reason_code; // Also used as a 16-bit bypass flag.
    bit<16> ether_type;
}

// CPU header
//TODO(msharif): Update format of the CPU header.
// header cpu_h {
//    bit<8> flags; /*
//        bit<1> tx_bypass;
//        bit<1> capture_ts;
//        bit<1> multicast;
//        bit<5> reserved;
//    */
//    bit<8> qid;
//    bit<16> reserved;
//    bit<16> port_or_group;
//    bit<16> port;
//    bit<16> port_lag_index;
//    bit<16> bd;
//    bit<16> reason_code; // Also used as a 16-bit bypass flag.
//    bit<16> ether_type;
//}

// header timestamp_h {
//     bit<48> timestamp;
// }



//////////////////////////////////////////////////////////////
// Lookahead/Snoop Headers
//////////////////////////////////////////////////////////////

header snoop_enet_my_mac_h {
    bit<16> dst_addr_hi;
    bit<32> dst_addr_lo;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header snoop_enet_cpu_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]
# 667 "headers.p4"
    bit<5> cpu_egress_queue;
    bit<1> cpu_tx_bypass;
    bit<1> cpu_capture_ts;
 bit<1> reserved;
    bit<16> cpu_ingress_port;
    bit<16> cpu_port_lag_index;
    bit<16> cpu_ingress_bd;
    bit<16> cpu_reason_code;
    bit<16> cpu_ether_type;
}

header snoop_head_enet_vlan_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<3> vlan_pcp;
    bit<1> vlan_cfi;
    vlan_id_t vlan_vid;
    bit<16> vlan_ether_type; // lookahead<bit<144>>()[15:0]
} // 14B + 4B = 18B

header snoop_head_enet_ipv4_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol; // lookahead<bit<224>>()[7:0]
} // 14B + 10B = 24B

header snoop_head_enet_vlan_ipv4_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<3> vlan_pcp;
    bit<1> vlan_cfi;
    vlan_id_t vlan_vid;
    bit<16> vlan_ether_type; // lookahead<bit<144>>()[15:0]

    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol; // lookahead<bit<224>>()[7:0]
} // 14B + 4B + 10B = 28B
# 42 "npb.p4" 2
# 1 "types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
# 46 "types.p4"
//#define ETHERTYPE_VN   0x892F
# 86 "types.p4"
//#define MPLS_DEPTH 3


// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------

typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;





typedef PortId_t switch_port_t; // defined in tna




const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;
typedef bit<7> switch_port_padding_t;


typedef QueueId_t switch_qid_t; // defined in tna (t2 = 7 bits)

typedef ReplicationId_t switch_rid_t; // defined in tna
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<10> switch_port_lag_index_t;
const switch_port_lag_index_t SWITCH_FLOOD = 0x3ff;

typedef bit<8> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf

typedef bit<12> switch_nexthop_t;
typedef bit<12> switch_outer_nexthop_t;






typedef bit<32> switch_hash_t;





typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_smac_index_t;

typedef bit<8> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_cpu_reason_t SWITCH_CPU_REASON_IG_PORT_MIRRROR = 254;
const switch_cpu_reason_t SWITCH_CPU_REASON_EG_PORT_MIRRROR = 255;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    switch_port_t port;
}

//#define switch_drop_reason_width 8
typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK = 17;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_VLAN_MAPPING_MISS = 55;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_VERSION_INVALID = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_OAM = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_TTL_ZERO = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_LEN_INVALID = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_MDTYPE_INVALID = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_NEXT_PROTO_INVALID = 115;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_SI_ZERO = 116;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_MD_LEN_INVALID = 117;
const switch_drop_reason_t SWITCH_DROP_REASON_SFC_TABLE_MISS = 118;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// Bypass flags ---------------------------------------------------------------

typedef bit<8> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 8w0x01;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SF_ACL = 8w0x02;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SF_MCAST = 8w0x04;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SFF = 8w0x08;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_REWRITE = 8w0x10;

// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 8w0xff;


typedef bit<8> switch_egress_bypass_t;
//const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE         = 8w0x01;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SF_ACL = 8w0x02;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SFF = 8w0x04;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x10;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_MTU = 8w0x80;

// Add more egress bypass flags here.

const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ALL = 8w0xff;


// PKT ------------------------------------------------------------------------

typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;

// Metering -------------------------------------------------------------------

//#define switch_copp_meter_id_width 8
typedef bit<8> switch_copp_meter_id_t;

//#define switch_meter_index_width 10
typedef bit<10> switch_meter_index_t;

//#define switch_mirror_meter_id_width 8
typedef bit<8> switch_mirror_meter_id_t;

// Multicast ------------------------------------------------------------------

typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

//typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
//  switch_multicast_rpf_group_t rpf_group;
}

// Mirroring ------------------------------------------------------------------

typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<8> switch_mirror_type_t;






/* Although strictly speaking deflected packets are not mirrored packets,
 * need a mirror_type codepoint for packet length adjustment.
 * Pick a large value since this is not used by mirror logic.
 */


// Common metadata used for mirroring.
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_meter_id_t meter_index;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_port_padding_t _pad1; // 7  \ 16 total
    switch_port_t port; // 9  /
    switch_bd_t bd; // 16
    bit<6> _pad2; // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
    bit<32> timestamp;



    switch_mirror_session_t session_id;
}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t src; // 8
    switch_mirror_type_t type; // 8
    switch_port_padding_t _pad1; // 7  \ 16 total
    switch_port_t port; // 9  /
    switch_bd_t bd; // 16
    bit<6> _pad2; // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
    switch_cpu_reason_t reason_code; // 16
}

// Tunneling ------------------------------------------------------------------

enum switch_tunnel_mode_t { PIPE, UNIFORM }

typedef bit<4> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NSH = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPC = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPU = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_ERSPAN = 7;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE = 8;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VLAN = 9;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS = 10;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_UNSUPPORTED = 11;

//#ifndef switch_tunnel_index_width
//#define switch_tunnel_index_width 16
//#endif
typedef bit<16> switch_tunnel_index_t;
typedef bit<32> switch_tunnel_id_t;

//struct switch_header_inner_inner_t {
//	bool ethernet_isValid;
//	bool ipv4_isValid;
//	bool ipv6_isValid;
//}

struct switch_tunnel_metadata_t { // for transport
 // note: in addition to tunnel stuff, this structure serves as a catch-all for all non-scoped signals (tunnel related or not)
 // --------------------------------
    switch_tunnel_index_t index;
    switch_tunnel_id_t id;
//  switch_ifindex_t ifindex;
//  bit<16> hash;

    switch_tunnel_type_t type; // only used by egress encap code (parser does not set)

 bit<8> nvgre_flow_id;

 bool terminate;
 bool encap;
}

struct switch_tunnel_metadata_reduced_t { // for outer and inner
 // note: in addition to tunnel stuff, this structure serves as a catch-all for all non-scoped signals (tunnel related or not)
 // --------------------------------
//	switch_tunnel_type_t type; // not used (parser does not set)

 bit<8> nvgre_flow_id;
 bool terminate;
 bool encap;
}

// Data-plane telemetry (DTel) ------------------------------------------------
/* report_type bits for drop and flow reflect dtel_acl results,
 * i.e. whether drop reports and flow reports may be triggered by this packet.
 * report_type bit for queue is not used by bridged / deflected packets,
 * reflects whether queue report is triggered by this packet in cloned packets.
 */
typedef bit<8> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE = 0b000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP = 0b100;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE = 0b010;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW = 0b001;

const switch_dtel_report_type_t SWITCH_DTEL_SUPPRESS_REPORT = 0b1000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_IFA_CLONE = 0b10000;
const switch_dtel_report_type_t SWITCH_DTEL_IFA_EDGE = 0b100000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE = 0b1000000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_HIT = 0b10000000;

typedef bit<8> switch_ifa_sample_id_t;






typedef bit<6> switch_dtel_hw_id_t;

// Outer header sizes for DTEL Reports
/* Up to the beginning of the DTEL Report v0.5 header
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 4 (CRC) = 46 bytes */
const bit<16> DTEL_REPORT_V0_5_OUTER_HEADERS_LENGTH = 46;
/* Outer headers + part of DTEL Report v2 length not included in report_length
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 12 (DTEL) + 4 (CRC) = 58 bytes */
const bit<16> DTEL_REPORT_V2_OUTER_HEADERS_LENGTH = 58;

struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<1> ifa_gen_clone; // Ingress only, indicates desire to clone this packet
    bit<1> ifa_cloned; // Egress only, indicates this is an ifa cloned packet
    bit<32> latency; // Egress only.
    switch_mirror_session_t session_id;
    switch_mirror_session_t clone_session_id; // Used for IFA interop
    bit<32> hash;
    bit<2> drop_report_flag; // Egress only.
    bit<2> flow_report_flag; // Egress only.
    bit<1> queue_report_flag; // Egress only.
}

header switch_dtel_switch_local_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;



    bit<1> _pad4;

    switch_qid_t qid;
    bit<5> _pad5;
    bit<19> qdepth;



    bit<32> egress_timestamp;

}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;



    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;



    bit<1> _pad4;

    switch_qid_t qid;
    switch_drop_reason_t drop_reason;
}

// Used for dtel truncate_only and ifa_clone mirror sessions
header switch_simple_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
}

@flexible
struct switch_bridged_metadata_dtel_extension_t {
    switch_dtel_report_type_t report_type;
    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_port_t egress_port;
}

//-----------------------------------------------------------------------------
// NSH Metadata
//-----------------------------------------------------------------------------

struct nsh_metadata_t {
    bool start_of_path; // ingress / egress
    bool end_of_path; // ingress / egress
    bool truncate_enable; // ingress / egress
    bit<14> truncate_len; // ingress / egress
//	bool                            sf1_active;             // ingress / egress

    bit<8> si_predec; // ingress only
    bool sfc_enable; // ingress only (for sfp sel)
    bit<12> sfc; // ingress only (for sfp sel)
 bit<16> hash_1; // ingress only (for sfp sel)
    bool l2_fwd_en; // ingress only
 bit<32> hash_2; // ingress only (for dedup)
 bit<6> lag_hash_mask_en; // ingress only

    bit<16> dsap; // egress only (for egress sf)
    bool strip_tag_e; // egress only
    bool strip_tag_vn; // egress only
    bool strip_tag_vlan; // egress only
    bit<8> add_tag_vlan_bd; // egress only
    bool terminate_outer; // egress only
    bool terminate_inner; // egress only
    bool dedup_en; // egress only
}

// ** Note: tenant id definition, from draft-wang-sfc-nsh-ns-allocation-00:
//
// Tenant ID: The tenant identifier is used to represent the tenant or security
// policy domain that the Service Function Chain is being applied to. The Tenant
// ID is a unique value assigned by a control plane. The distribution of Tenant
// ID's is outside the scope of this document. As an example application of
// this field, the first node on the Service Function Chain may insert a VRF
// number, VLAN number, VXLAN VNI or a policy domain ID.

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------

// Flags
//XXX Force the fields that are XORd to NOT share containers.
struct switch_ingress_flags_t {
    bool ipv4_checksum_err_0;
    bool ipv4_checksum_err_1;
    bool ipv4_checksum_err_2;
    //  bool acl_deny;
//  bool port_vlan_miss;
    bool rmac_hit;
//	bool dmac_miss;
//  bool glean;
 bool bypass_egress;
    // Add more flags here.



}

struct switch_egress_flags_t {
 bool bypass_egress;
//  bool ipv4_checksum_err_0;
//  bool ipv4_checksum_err_1;
//  bool ipv4_checksum_err_2;
//  bool acl_deny;
    bool rmac_hit;
    // Add more flags here.
}

// Checks
struct switch_ingress_checks_t {
    // Add more checks here.
}

struct switch_egress_checks_t {
    // Add more checks here.
}

struct switch_lookup_fields_t {
 // l2
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;
 bit<1> pad; // to keep everything byte-aligned, so that the parser can extract to this struct.
 vlan_id_t vid;

 // l3
    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_tos;
 bit<3> ip_flags;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
 bit<32> ip_src_addr_v4;
 bit<32> ip_dst_addr_v4;
    @pa_alias("ingress" , "ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_1.ip_dst_addr[31:0]", "ig_md.lkp_1.ip_dst_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_2.ip_src_addr[31:0]", "ig_md.lkp_2.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_2.ip_dst_addr[31:0]", "ig_md.lkp_2.ip_dst_addr_v4" )
    @pa_alias("egress" , "eg_md.lkp_1.ip_src_addr[31:0]", "eg_md.lkp_1.ip_src_addr_v4" )
    @pa_alias("egress" , "eg_md.lkp_1.ip_dst_addr[31:0]", "eg_md.lkp_1.ip_dst_addr_v4" )
    bit<16> ip_len;

 // l4
    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;

 // tunnel
    switch_tunnel_type_t tunnel_type;
    switch_tunnel_id_t tunnel_id;

    switch_tunnel_type_t tunnel_outer_type; // egress only
    switch_tunnel_type_t tunnel_inner_type; // egress only

 // misc
 bool next_lyr_valid;
    switch_drop_reason_t drop_reason;
}

// --------------------------------------------------------------------------------
// Bridged Metadata
// --------------------------------------------------------------------------------

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
    switch_port_lag_index_t ingress_port_lag_index;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
//  switch_pkt_type_t pkt_type;
 switch_cpu_reason_t cpu_reason;
//  bit<48> timestamp;
 bool rmac_hit;
 bool bypass_egress;

    // Add more fields here.
}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_acl_extension_t {
# 670 "types.p4"
    bit<8> tcp_flags;

}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_index_t index;
    switch_outer_nexthop_t outer_nexthop;
//  bit<16> hash;

//  bool terminate;
//  bool terminate_0; // unused, but removing causes a compiler error
//  bool terminate_1;
//  bool terminate_2;
}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_nsh_extension_t {
    // ---------------
    // nsh meta data
    // ---------------
    bool nsh_md_start_of_path;
    bool nsh_md_end_of_path;
    bool nsh_md_l2_fwd_en;
//  bool                            nsh_md_sf1_active;

 bool nsh_md_dedup_en;

    // ---------------
    // dedup stuff
    // ---------------





}

// ----------------------------------------
# 736 "types.p4"
// ----------------------------------------

typedef bit<8> switch_bridge_type_t;

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;
 switch_bridged_metadata_nsh_extension_t nsh;




    switch_bridged_metadata_tunnel_extension_t tunnel;




}

// --------------------------------------------------------------------------------
// Ingress Port Metadata
// --------------------------------------------------------------------------------

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
//  switch_ifindex_t                ifindex;

 bit<1> l2_fwd_en;


/*
    switch_yid_t exclusion_id;

	// for packets w/o nsh header:
    bit<SSAP_ID_WIDTH>              sap;
    bit<VPN_ID_WIDTH>               vpn;
    bit<24>                         spi;
    bit<8>                          si;
    bit<8>                          si_predec;
*/

}

@pa_auto_init_metadata

// --------------------------------------------------------------------------------
// Ingress Metadata
// --------------------------------------------------------------------------------

@pa_container_size("ingress", "ig_md.mirror.src", 8)
@pa_container_size("ingress", "ig_md.mirror.type", 8)
//@pa_container_size("ingress", "smac_src_move", 16)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")

@pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")

//@pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid")
//@pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")

@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.mirror.type")


struct switch_ingress_metadata_t {
    switch_port_t port; /* ingress port */
    switch_port_t egress_port; /* egress  port */
    switch_port_lag_index_t port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress  port/lag index */ /* derek: passed to egress */
    switch_bd_t bd;
    switch_nexthop_t nexthop; /* derek: egress table pointer #1 */
    switch_outer_nexthop_t outer_nexthop; /* derek: egress table pointer #2 */
//  switch_nexthop_t acl_nexthop;
//  bool acl_redirect;
 switch_nexthop_t unused_nexthop;

    bit<48> timestamp;
    bit<32> hash;
//  bit<32> hash_nsh;

    switch_ingress_flags_t flags;
//  switch_ingress_checks_t checks;
 switch_ingress_bypass_t bypass;

 switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;
//  switch_drop_reason_t drop_reason_0;
//  switch_drop_reason_t drop_reason_1;
//  switch_drop_reason_t drop_reason_2;

    switch_lookup_fields_t lkp_0;
    switch_lookup_fields_t lkp_1; // initially non-scoped, later scoped, version of fields
    switch_lookup_fields_t lkp_2; // non-scoped version of fields

    switch_multicast_metadata_t multicast;
 switch_mirror_metadata_t mirror;

    switch_tunnel_metadata_t tunnel_0; // non-scoped version of fields /* derek: egress table pointer #3 (tunnel_0.index) */
    switch_tunnel_metadata_reduced_t tunnel_1; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_2; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_3; // non-scoped version of fields

 switch_dtel_metadata_t dtel;

    nsh_metadata_t nsh_md;

//	bool copp_enable;
//	switch_copp_meter_id_t copp_meter_id;

//	switch_header_inner_inner_t inner_inner;
}

// --------------------------------------------------------------------------------
// Egress Metadata
// --------------------------------------------------------------------------------

@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.type", 8)





struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
//  switch_kt_type_t pkt_type;

    switch_port_lag_index_t port_lag_index; /* egress port/lag index */
    switch_port_t port; /* Mutable copy of egress port */
    switch_port_t ingress_port; /* ingress port */
    switch_bd_t bd;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;




    bit<32> timestamp;

//  bit<48> ingress_timestamp;

    switch_egress_flags_t flags;
//  switch_egress_checks_t checks;
 switch_egress_bypass_t bypass;

 switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;
//  switch_drop_reason_t drop_reason_0;
//  switch_drop_reason_t drop_reason_1;
//  switch_drop_reason_t drop_reason_2;

    switch_lookup_fields_t lkp_1; //     scoped version of fields
//  switch_tunnel_type_t   lkp_1_tunnel_outer_type;
//  switch_tunnel_type_t   lkp_1_tunnel_inner_type;
    switch_tunnel_metadata_t tunnel_0; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_1; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_2; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_3; // non-scoped version of fields
 switch_mirror_metadata_t mirror;
 switch_dtel_metadata_t dtel;

    nsh_metadata_t nsh_md;

//	bool copp_enable;
//	switch_copp_meter_id_t copp_meter_id;

//  bit<6>                                              action_bitmask;
//  bit<NPB_EGR_SF_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2> action_3_meter_id;
//  bit<10>                                             action_3_meter_id;
//  bit<8>                                              action_3_meter_overhead;

//	switch_header_inner_inner_t inner_inner;
}

// --------------------------------------------------------------------------
// Headers
// --------------------------------------------------------------------------

struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h port;
    switch_cpu_mirror_metadata_h cpu;
    switch_dtel_drop_mirror_metadata_h dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
    switch_simple_mirror_metadata_h simple_mirror;
}

// -----------------------------------------------------------------------------

struct switch_header_transport_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;
    nsh_type1_h nsh_type1;


    ipv4_h ipv4;







    gre_h gre;



 gre_extension_sequence_h gre_sequence;
    erspan_type2_h erspan_type2;
    //erspan_type3_h erspan_type3;


}

// -----------------------------------------------------------------------------

struct switch_header_outer_t {

    ethernet_h ethernet;


    e_tag_h e_tag;


    vn_tag_h vn_tag;

    vlan_tag_h[2] vlan_tag;




    ipv4_h ipv4;

    ipv6_h ipv6;

    udp_h udp;
    tcp_h tcp;
    sctp_h sctp;

    vxlan_h vxlan;

    gre_h gre;
    gre_optional_h gre_optional;

    nvgre_h nvgre;


    gtp_v1_base_h gtp_v1_base;
    gtp_v1_optional_h gtp_v1_optional;
# 996 "types.p4"
    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;

}

// -----------------------------------------------------------------------------

struct switch_header_inner_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;

    ipv4_h ipv4;

    ipv6_h ipv6;


    udp_h udp;
    tcp_h tcp;
    sctp_h sctp;


    gre_h gre;
    gre_optional_h gre_optional;



    gtp_v1_base_h gtp_v1_base;
    gtp_v1_optional_h gtp_v1_optional;


}

// -----------------------------------------------------------------------------

struct switch_header_inner_inner_t {
 dummy_h ethernet;
 dummy_h ipv4;
 dummy_h ipv6;
}

// -----------------------------------------------------------------------------

struct switch_header_t {

    // ===========================
    // misc 
    // ===========================

    switch_bridged_metadata_h bridged_md;
 // switch_mirror_metadata_h mirror;
    fabric_h fabric;
    cpu_h cpu;

    // ===========================
    // transport
    // ===========================

 switch_header_transport_t transport;

    // ===========================
    // outer
    // ===========================

 switch_header_outer_t outer;

    // ===========================
    // inner
    // ===========================

    switch_header_inner_t inner;

    // ===========================
    // inner
    // ===========================

    switch_header_inner_inner_t inner_inner;

    // ===========================
    // layer7
    // ===========================

    udf_h udf;

}
# 43 "npb.p4" 2
# 1 "util.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 24 "util.p4" 2

// -----------------------------------------------------------------------------

control HashMask(
 inout switch_lookup_fields_t lkp_1,
 inout bit<6> lkp_1_hash_mask_en
) {

 // -----------------------------------------

 apply {

//		if(lkp_1_hash_mask_en[0:0] == 1) { lkp_1.mac_type     = 0; }
//		if(lkp_1_hash_mask_en[1:1] == 1) { lkp_1.mac_src_addr = 0; }
//		if(lkp_1_hash_mask_en[1:1] == 1) { lkp_1.mac_dst_addr = 0; }
//		if(lkp_1_hash_mask_en[2:2] == 1) { lkp_1.ip_src_addr  = 0; }
//		if(lkp_1_hash_mask_en[2:2] == 1) { lkp_1.ip_dst_addr  = 0; }
  if(lkp_1_hash_mask_en[3:3] == 1) { lkp_1.ip_proto = 0; }
  if(lkp_1_hash_mask_en[4:4] == 1) { lkp_1.l4_src_port = 0; }
  if(lkp_1_hash_mask_en[4:4] == 1) { lkp_1.l4_dst_port = 0; }
  if(lkp_1_hash_mask_en[5:5] == 1) { lkp_1.tunnel_id = 0; }

 }
}

// -----------------------------------------------------------------------------

// Flow hash calculation.

control Ipv4Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
//	@symmetric("ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_dst_addr[31:0]")
 @symmetric("ig_md.lkp_1.ip_src_addr_v4", "ig_md.lkp_1.ip_dst_addr_v4")
 @symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

 Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;

 apply {
  hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
//			lkp.ip_dst_addr[31:0],
   lkp.ip_src_addr_v4,
   lkp.ip_dst_addr_v4,
   lkp.ip_proto,
   lkp.l4_dst_port,
   lkp.l4_src_port,
   lkp.tunnel_id // extreme added
  });
 }
}

control Ipv6Hash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
 @symmetric("ig_md.lkp_1.ip_src_addr", "ig_md.lkp_1.ip_dst_addr")
 @symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

 Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;

 apply {
  hash[31:0] = ipv6_hash.get({
   lkp.ip_src_addr,
   lkp.ip_dst_addr,
   lkp.ip_proto,
   lkp.l4_dst_port,
   lkp.l4_src_port,
   lkp.tunnel_id // extreme added
  });
 }
}

control NonIpHash(in switch_lookup_fields_t lkp, out switch_hash_t hash) {
 @symmetric("ig_md.lkp_1.mac_src_addr", "ig_md.lkp_1.mac_dst_addr")

 Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;

 apply {
  hash [31:0] = non_ip_hash.get({
   lkp.mac_type,
   lkp.mac_src_addr,
   lkp.mac_dst_addr
  });
 }
}

// -----------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
 inout switch_bridged_metadata_h bridged_md,
 in switch_ingress_metadata_t ig_md
) {
 bridged_md.setValid();
 bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
 bridged_md.base = {
  ig_md.port,
  ig_md.port_lag_index,
  ig_md.bd,
  ig_md.nexthop,
//		ig_md.lkp.pkt_type,
  ig_md.cpu_reason,
//		ig_md.timestamp,
  ig_md.flags.rmac_hit,
  ig_md.flags.bypass_egress
 };

 bridged_md.nsh = {
  // nsh metadata
  ig_md.nsh_md.start_of_path,
  ig_md.nsh_md.end_of_path,
  ig_md.nsh_md.l2_fwd_en,
//		ig_md.nsh_md.sf1_active,
  ig_md.nsh_md.dedup_en
 };


 bridged_md.tunnel = {
  ig_md.tunnel_0.index,
  ig_md.outer_nexthop
//		ig_md.hash[15:0],

//		ig_md.tunnel_0.terminate // unused, but removing causes a compiler error
//		ig_md.tunnel_1.terminate,
//		ig_md.tunnel_2.terminate
 };
# 156 "util.p4"
}

// -----------------------------------------------------------------------------

action set_ig_intr_md(
 in switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
 ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;

 // Set PRE hash values
 bit<13> hash;



 hash = ig_md.hash[32/2+12:32/2]; // cap  at 13 bits


//	ig_intr_md_for_tm.level1_mcast_hash = ig_md.hash[12:0];
//	ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
 ig_intr_md_for_tm.level2_mcast_hash = hash;

//	ig_intr_md_for_dprsr.mirror_type = (bit<4>) ig_md.mirror.type;



}

// -----------------------------------------------------------------------------

action set_eg_intr_md(
 in switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {




 eg_intr_md_for_dprsr.mirror_type = (bit<4>) eg_md.mirror.type;
 eg_intr_md_for_dprsr.mirror_io_select = 1;


}
# 44 "npb.p4" 2

# 1 "l3.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

// DEREK: NOT USING THIS TABLE ANYMORE -- USING THE TABLE IN TUNNEL.P4 INSTEAD.

# 1 "acl.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




# 1 "scoper.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




// ============================================================================

control Scoper(
  in switch_lookup_fields_t lkp_in,
//		in    switch_drop_reason_t      drop_reason,

  inout switch_lookup_fields_t lkp
) {

 apply {




  // l2
  lkp.mac_src_addr = lkp_in.mac_src_addr;
  lkp.mac_dst_addr = lkp_in.mac_dst_addr;
  lkp.mac_type = lkp_in.mac_type;
  lkp.pcp = lkp_in.pcp;
  lkp.pad = lkp_in.pad;
  lkp.vid = lkp_in.vid;

  // l3
  lkp.ip_type = lkp_in.ip_type;
  lkp.ip_proto = lkp_in.ip_proto;
  lkp.ip_tos = lkp_in.ip_tos;
  lkp.ip_flags = lkp_in.ip_flags;
  lkp.ip_src_addr = lkp_in.ip_src_addr;
  lkp.ip_dst_addr = lkp_in.ip_dst_addr;
  // Comment the two below as they are alias fields and do not need to be written again.
  //lkp.ip_src_addr_v4    = lkp_in.ip_src_addr_v4;
  //lkp.ip_dst_addr_v4    = lkp_in.ip_dst_addr_v4;
  lkp.ip_len = lkp_in.ip_len;

  // l4
  lkp.tcp_flags = lkp_in.tcp_flags;
  lkp.l4_src_port = lkp_in.l4_src_port;
  lkp.l4_dst_port = lkp_in.l4_dst_port;

  // tunnel
  lkp.tunnel_type = lkp_in.tunnel_type;
  lkp.tunnel_id = lkp_in.tunnel_id;

  lkp.tunnel_outer_type = lkp_in.tunnel_outer_type; // egress only
  lkp.tunnel_inner_type = lkp_in.tunnel_inner_type; // egress only

  // misc
  lkp.next_lyr_valid = lkp_in.next_lyr_valid;
//		lkp.drop_reason         = lkp_in.drop_reason;

 }
}

// ============================================================================

control ScoperOuter(
  in switch_header_outer_t hdr_1,
  in switch_tunnel_metadata_t tunnel,
  in switch_drop_reason_t drop_reason,

  inout switch_lookup_fields_t lkp
) {

 // -----------------------------
 // L2
 // -----------------------------

 action scope_l2_none() {
  lkp.mac_src_addr = 0;
  lkp.mac_dst_addr = 0;
  lkp.mac_type = 0;
  lkp.pcp = 0;
 }

 action scope_l2() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.ethernet.ether_type;
  lkp.pcp = 0;
 }


 action scope_l2_e_tag() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.e_tag.ether_type;
  //lkp.pcp          = hdr_1.e_tag.pcp;
  lkp.pcp = 0; // do not populate w/ e-tag
 }



 action scope_l2_vn_tag() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.vn_tag.ether_type;
  lkp.pcp = 0;
 }


 action scope_l2_1tag() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.vlan_tag[0].ether_type;
  lkp.pcp = hdr_1.vlan_tag[0].pcp;
 }

 action scope_l2_2tags() {
  lkp.mac_src_addr = hdr_1.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_1.ethernet.dst_addr;
  lkp.mac_type = hdr_1.vlan_tag[1].ether_type;
  lkp.pcp = hdr_1.vlan_tag[0].pcp;
 }

 table scope_l2_ {
  key = {
   hdr_1.ethernet.isValid(): exact;


   hdr_1.e_tag.isValid(): exact;



   hdr_1.vn_tag.isValid(): exact;


   hdr_1.vlan_tag[0].isValid(): exact;
   hdr_1.vlan_tag[1].isValid(): exact;
  }
  actions = {
   scope_l2_none;
   scope_l2;


   scope_l2_e_tag;



   scope_l2_vn_tag;


   scope_l2_1tag;
   scope_l2_2tags;
  }
  const entries = {



   (false, false, false, false, false): scope_l2_none();

   (true, false, false, false, false): scope_l2();

   (true, true, false, false, false): scope_l2_e_tag();
   (true, false, true, false, false): scope_l2_vn_tag();

   (true, false, false, true, false): scope_l2_1tag();
   (true, true, false, true, false): scope_l2_1tag();
   (true, false, true, true, false): scope_l2_1tag();

   (true, false, false, true, true ): scope_l2_2tags();
   (true, true, false, true, true ): scope_l2_2tags();
   (true, false, true, true, true ): scope_l2_2tags();
# 228 "scoper.p4"
        }
 }

 // -----------------------------
 // L3
 // -----------------------------

 action scope_l3_none() {
  lkp.ip_type = 0;
  lkp.ip_tos = 0;
  lkp.ip_proto = 0;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = 0;
  lkp.ip_dst_addr = 0;
  lkp.ip_len = 0; // extreme added
 }

 action scope_l3_v4() {
  lkp.ip_type = SWITCH_IP_TYPE_IPV4;
  lkp.ip_tos = hdr_1.ipv4.tos;
  lkp.ip_proto = hdr_1.ipv4.protocol;
  lkp.ip_flags = hdr_1.ipv4.flags;
  lkp.ip_src_addr = (bit<128>) hdr_1.ipv4.src_addr;
  lkp.ip_dst_addr = (bit<128>) hdr_1.ipv4.dst_addr;
  lkp.ip_len = hdr_1.ipv4.total_len;
 }

 action scope_l3_v6() {

  lkp.ip_type = SWITCH_IP_TYPE_IPV6;
  lkp.ip_tos = hdr_1.ipv6.tos;
  lkp.ip_proto = hdr_1.ipv6.next_hdr;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = hdr_1.ipv6.src_addr;
  lkp.ip_dst_addr = hdr_1.ipv6.dst_addr;
  lkp.ip_len = hdr_1.ipv6.payload_len;

 }

 table scope_l3_ {
  key = {
   hdr_1.ipv4.isValid(): exact;

   hdr_1.ipv6.isValid(): exact;

  }
  actions = {
   scope_l3_none;
   scope_l3_v4;
   scope_l3_v6;
  }
  const entries = {

   (false, false): scope_l3_none();
   (true, false): scope_l3_v4();
   (false, true ): scope_l3_v6();




  }
 }

 // -----------------------------
 // L4
 // -----------------------------

 action scope_l4_none() {
  lkp.l4_src_port = 0;
  lkp.l4_dst_port = 0;
  lkp.tcp_flags = 0;
 }

 action scope_l4_tcp() {
  lkp.l4_src_port = hdr_1.tcp.src_port;
  lkp.l4_dst_port = hdr_1.tcp.dst_port;
  lkp.tcp_flags = hdr_1.tcp.flags;
 }

 action scope_l4_udp() {
  lkp.l4_src_port = hdr_1.udp.src_port;
  lkp.l4_dst_port = hdr_1.udp.dst_port;
  lkp.tcp_flags = 0;
 }

 action scope_l4_sctp() {
  lkp.l4_src_port = hdr_1.sctp.src_port;
  lkp.l4_dst_port = hdr_1.sctp.dst_port;
  lkp.tcp_flags = 0;
 }

 table scope_l4_ {
  key = {
   hdr_1.tcp.isValid(): exact;
   hdr_1.udp.isValid(): exact;
   hdr_1.sctp.isValid(): exact;
  }
  actions = {
   scope_l4_tcp;
   scope_l4_udp;
   scope_l4_sctp;
   scope_l4_none;
  }
  const entries = {
   (false, false, false): scope_l4_none();
   (true, false, false): scope_l4_tcp();
   (false, true, false): scope_l4_udp();
   (false, false, true ): scope_l4_sctp();
  }
 }

 // -----------------------------
 // L3 / L4
 // -----------------------------

 action scope_l3_none_l4_none() { scope_l3_none(); scope_l4_none(); }
 action scope_l3_v4_l4_none() { scope_l3_v4(); scope_l4_none(); }
 action scope_l3_v6_l4_none() { scope_l3_v6(); scope_l4_none(); }
 action scope_l3_v4_l4_tcp() { scope_l3_v4(); scope_l4_tcp(); }
 action scope_l3_v6_l4_tcp() { scope_l3_v6(); scope_l4_tcp(); }
 action scope_l3_v4_l4_udp() { scope_l3_v4(); scope_l4_udp(); }
 action scope_l3_v6_l4_udp() { scope_l3_v6(); scope_l4_udp(); }
 action scope_l3_v4_l4_sctp() { scope_l3_v4(); scope_l4_sctp(); }
 action scope_l3_v6_l4_sctp() { scope_l3_v6(); scope_l4_sctp(); }

 table scope_l34_ {
  key = {
   hdr_1.ipv4.isValid(): exact;

   hdr_1.ipv6.isValid(): exact;


   hdr_1.tcp.isValid(): exact;
   hdr_1.udp.isValid(): exact;
   hdr_1.sctp.isValid(): exact;
  }
  actions = {
   scope_l3_v4_l4_tcp;
   scope_l3_v6_l4_tcp;
   scope_l3_v4_l4_udp;
   scope_l3_v6_l4_udp;
   scope_l3_v4_l4_sctp;
   scope_l3_v6_l4_sctp;
   scope_l3_v4_l4_none;
   scope_l3_v6_l4_none;
   scope_l3_none_l4_none;
  }
  const entries = {

   (false, false, false, false, false): scope_l3_none_l4_none();

   (true, false, false, false, false): scope_l3_v4_l4_none();
   (false, true, false, false, false): scope_l3_v6_l4_none();
   (true, false, true, false, false): scope_l3_v4_l4_tcp();
   (false, true, true, false, false): scope_l3_v6_l4_tcp();
   (true, false, false, true, false): scope_l3_v4_l4_udp();
   (false, true, false, true, false): scope_l3_v6_l4_udp();
   (true, false, false, false, true ): scope_l3_v4_l4_sctp();
   (false, true, false, false, true ): scope_l3_v6_l4_sctp();
# 395 "scoper.p4"
  }
 }

 // -----------------------------
 // L2 / L3 / L4
 // -----------------------------
// Derek: Not using this, because it chews up too much vliw resources in tofino....
/*
	action scope_l2_none_l3_none_l4_none()  { scope_l2_none();   scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_none_l4_none()  { scope_l2();        scope_l3_none(); scope_l4_none(); }
	action scope_l2_etag_l3_none_l4_none()  { scope_l2_e_tag();  scope_l3_none(); scope_l4_none(); }
	action scope_l2_vntag_l3_none_l4_none() { scope_l2_vn_tag(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none()  { scope_l2_1tag();   scope_l3_none(); scope_l4_none(); }
	action scope_l2_2tag_l3_none_l4_none()  { scope_l2_2tags();  scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_none()    { scope_l2();        scope_l3_v4();   scope_l4_none(); }
	action scope_l2_etag_l3_v4_l4_none()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_none(); }
	action scope_l2_vntag_l3_v4_l4_none()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_none(); }
	action scope_l2_2tag_l3_v4_l4_none()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_none(); }

	action scope_l2_0tag_l3_v6_l4_none()    { scope_l2();        scope_l3_v6();   scope_l4_none(); }
	action scope_l2_etag_l3_v6_l4_none()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_none(); }
	action scope_l2_vntag_l3_v6_l4_none()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_none(); }
	action scope_l2_2tag_l3_v6_l4_none()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_tcp()     { scope_l2();        scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v4_l4_tcp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v4_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v4_l4_tcp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v4_l4_tcp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v6_l4_tcp()     { scope_l2();        scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v6_l4_tcp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v6_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v6_l4_tcp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v6_l4_tcp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v4_l4_udp()     { scope_l2();        scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_etag_l3_v4_l4_udp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v4_l4_udp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v4_l4_udp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v6_l4_udp()     { scope_l2();        scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_etag_l3_v6_l4_udp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v6_l4_udp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v6_l4_udp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v4_l4_sctp()    { scope_l2();        scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v4_l4_sctp()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v4_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v4_l4_sctp()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v4_l4_sctp()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_sctp(); }

	action scope_l2_0tag_l3_v6_l4_sctp()    { scope_l2();        scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v6_l4_sctp()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v6_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v6_l4_sctp()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v6_l4_sctp()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_sctp(); }

	table scope_l234_ {
		key = {
			hdr_1.ethernet.isValid(): exact;
			hdr_1.e_tag.isValid(): exact;
			hdr_1.vn_tag.isValid(): exact;
			hdr_1.vlan_tag[0].isValid(): exact;
			hdr_1.vlan_tag[1].isValid(): exact;

			hdr_1.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_1.ipv6.isValid(): exact;
#endif // IPV6_ENABLE

			hdr_1.tcp.isValid():  exact;
			hdr_1.udp.isValid():  exact;
			hdr_1.sctp.isValid(): exact;
		}
		actions = {
			scope_l2_0tag_l3_v4_l4_tcp;
			scope_l2_etag_l3_v4_l4_tcp;
			scope_l2_vntag_l3_v4_l4_tcp;
			scope_l2_1tag_l3_v4_l4_tcp;
			scope_l2_2tag_l3_v4_l4_tcp;

			scope_l2_0tag_l3_v6_l4_tcp;
			scope_l2_etag_l3_v6_l4_tcp;
			scope_l2_vntag_l3_v6_l4_tcp;
			scope_l2_1tag_l3_v6_l4_tcp;
			scope_l2_2tag_l3_v6_l4_tcp;

			scope_l2_0tag_l3_v4_l4_udp;
			scope_l2_etag_l3_v4_l4_udp;
			scope_l2_vntag_l3_v4_l4_udp;
			scope_l2_1tag_l3_v4_l4_udp;
			scope_l2_2tag_l3_v4_l4_udp;

			scope_l2_0tag_l3_v6_l4_udp;
			scope_l2_etag_l3_v6_l4_udp;
			scope_l2_vntag_l3_v6_l4_udp;
			scope_l2_1tag_l3_v6_l4_udp;
			scope_l2_2tag_l3_v6_l4_udp;

			scope_l2_0tag_l3_v4_l4_sctp;
			scope_l2_etag_l3_v4_l4_sctp;
			scope_l2_vntag_l3_v4_l4_sctp;
			scope_l2_1tag_l3_v4_l4_sctp;
			scope_l2_2tag_l3_v4_l4_sctp;

			scope_l2_0tag_l3_v6_l4_sctp;
			scope_l2_etag_l3_v6_l4_sctp;
			scope_l2_vntag_l3_v6_l4_sctp;
			scope_l2_1tag_l3_v6_l4_sctp;
			scope_l2_2tag_l3_v6_l4_sctp;

			scope_l2_0tag_l3_v4_l4_none;
			scope_l2_etag_l3_v4_l4_none;
			scope_l2_vntag_l3_v4_l4_none;
			scope_l2_1tag_l3_v4_l4_none;
			scope_l2_2tag_l3_v4_l4_none;

			scope_l2_0tag_l3_v6_l4_none;
			scope_l2_etag_l3_v6_l4_none;
			scope_l2_vntag_l3_v6_l4_none;
			scope_l2_1tag_l3_v6_l4_none;
			scope_l2_2tag_l3_v6_l4_none;

			scope_l2_0tag_l3_none_l4_none;
			scope_l2_etag_l3_none_l4_none;
			scope_l2_vntag_l3_none_l4_none;
			scope_l2_1tag_l3_none_l4_none;
			scope_l2_2tag_l3_none_l4_none;

			scope_l2_none_l3_none_l4_none;
		}
		const entries = {
			(false, false, false, false, false,     false, false,     false, false, false): scope_l2_none_l3_none_l4_none();

			(true,  false, false, false, false,     false, false,     false, false, false): scope_l2_0tag_l3_none_l4_none();
			(true,  true,  false, false, false,     false, false,     false, false, false): scope_l2_etag_l3_none_l4_none();
			(true,  false, true,  false, false,     false, false,     false, false, false): scope_l2_vntag_l3_none_l4_none();
			(true,  false, false, true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  true,  false, true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  false, true,  true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  false, false, true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();
			(true,  true,  false, true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();
			(true,  false, true,  true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();

			(true,  false, false, false, false,     true,  false,     false, false, false): scope_l2_0tag_l3_v4_l4_none();
			(true,  true,  false, false, false,     true,  false,     false, false, false): scope_l2_etag_l3_v4_l4_none();
			(true,  false, true,  false, false,     true,  false,     false, false, false): scope_l2_vntag_l3_v4_l4_none();
			(true,  false, false, true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  true,  false, true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  false, true,  true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  false, false, true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();
			(true,  true,  false, true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();
			(true,  false, true,  true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();

			(true,  false, false, false, false,     false, true,      false, false, false): scope_l2_0tag_l3_v6_l4_none();
			(true,  true,  false, false, false,     false, true,      false, false, false): scope_l2_etag_l3_v6_l4_none();
			(true,  false, true,  false, false,     false, true,      false, false, false): scope_l2_vntag_l3_v6_l4_none();
			(true,  false, false, true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  true,  false, true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  false, true,  true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  false, false, true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();
			(true,  true,  false, true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();
			(true,  false, true,  true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();

			(true,  false, false, false, false,     true,  false,     true,  false, false): scope_l2_0tag_l3_v4_l4_tcp();
			(true,  true,  false, false, false,     true,  false,     true,  false, false): scope_l2_etag_l3_v4_l4_tcp();
			(true,  false, true,  false, false,     true,  false,     true,  false, false): scope_l2_vntag_l3_v4_l4_tcp();
			(true,  false, false, true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  true,  false, true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  false, true,  true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  false, false, true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();
			(true,  true,  false, true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();
			(true,  false, true,  true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();

			(true,  false, false, false, false,     false, true,      true,  false, false): scope_l2_0tag_l3_v6_l4_tcp();
			(true,  true,  false, false, false,     false, true,      true,  false, false): scope_l2_etag_l3_v6_l4_tcp();
			(true,  false, true,  false, false,     false, true,      true,  false, false): scope_l2_vntag_l3_v6_l4_tcp();
			(true,  false, false, true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  true,  false, true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  false, true,  true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  false, false, true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();
			(true,  true,  false, true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();
			(true,  false, true,  true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();

			(true,  false, false, false, false,     true,  false,     false, true,  false): scope_l2_0tag_l3_v4_l4_udp();
			(true,  true,  false, false, false,     true,  false,     false, true,  false): scope_l2_etag_l3_v4_l4_udp();
			(true,  false, true,  false, false,     true,  false,     false, true,  false): scope_l2_vntag_l3_v4_l4_udp();
			(true,  false, false, true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  true,  false, true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  false, true,  true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  false, false, true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();
			(true,  true,  false, true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();
			(true,  false, true,  true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();

			(true,  false, false, false, false,     false, true,      false, true,  false): scope_l2_0tag_l3_v6_l4_udp();
			(true,  true,  false, false, false,     false, true,      false, true,  false): scope_l2_etag_l3_v6_l4_udp();
			(true,  false, true,  false, false,     false, true,      false, true,  false): scope_l2_vntag_l3_v6_l4_udp();
			(true,  false, false, true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  true,  false, true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  false, true,  true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  false, false, true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();
			(true,  true,  false, true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();
			(true,  false, true,  true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();

			(true,  false, false, false, false,     true,  false,     false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
			(true,  true,  false, false, false,     true,  false,     false, false, true ): scope_l2_etag_l3_v4_l4_sctp();
			(true,  false, true,  false, false,     true,  false,     false, false, true ): scope_l2_vntag_l3_v4_l4_sctp();
			(true,  false, false, true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  true,  false, true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  false, true,  true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  false, false, true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();
			(true,  true,  false, true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();
			(true,  false, true,  true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();

			(true,  false, false, false, false,     false, true,      false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
			(true,  true,  false, false, false,     false, true,      false, false, true ): scope_l2_etag_l3_v6_l4_sctp();
			(true,  false, true,  false, false,     false, true,      false, false, true ): scope_l2_vntag_l3_v6_l4_sctp();
			(true,  false, false, true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  true,  false, true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  false, true,  true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  false, false, true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
			(true,  true,  false, true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
			(true,  false, true,  true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
		}
	}
*/
 // -----------------------------
 // TUNNEL
 // -----------------------------

 action scope_tunnel_none() {
  lkp.tunnel_type = 0;
  lkp.tunnel_id = 0;
 }
/*
	action scope_tunnel_vlan() {
		lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
		lkp.tunnel_id   = (switch_tunnel_id_t)hdr_1.vlan_tag[0].vid;
	}
*/
 action scope_tunnel_vni() {
  lkp.tunnel_type = lkp.tunnel_type;
  lkp.tunnel_id = lkp.tunnel_id;
 }

 table scope_tunnel_ {
  key = {
   lkp.tunnel_type: exact;
/*
			tunnel.type: ternary;
			hdr_1.vlan_tag[0].isValid(): exact;
			hdr_1.vlan_tag[0].vid: ternary;
*/
  }
  actions = {
   scope_tunnel_vni;
//          scope_tunnel_vlan;
   scope_tunnel_none;
  }
  const entries = {
/*
			// highest -> lowest priority in tcam
			(0, true,  0): scope_tunnel_none(); // tag has priority only
			(0, true,  _): scope_tunnel_vlan(); // tag has priority and vlan
			(_, true,  _): scope_tunnel_vni();
			(_, false, _): scope_tunnel_vni();
			(0, false, _): scope_tunnel_none();
*/
   (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
  }
  const default_action = scope_tunnel_vni;
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
  scope_l2_.apply();
//		scope_l3_.apply();
//		scope_l4_.apply();
  scope_l34_.apply();
//		scope_tunnel_.apply();
  scope_tunnel_vni();

  lkp.drop_reason = drop_reason;
 }
}

// ============================================================================

control ScoperInner(
  in switch_header_inner_t hdr_2,
  in switch_lookup_fields_t lkp_2,
  in switch_tunnel_metadata_t tunnel,
  in switch_drop_reason_t drop_reason,

  inout switch_lookup_fields_t lkp
) {

 // -----------------------------
 // L2
 // -----------------------------

 action scope_l2_none() {
  lkp.mac_src_addr = 0;
  lkp.mac_dst_addr = 0;
  lkp.mac_type = 0;
  lkp.pcp = 0;
 }

 action scope_l2() {
  lkp.mac_src_addr = hdr_2.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_2.ethernet.dst_addr;
  lkp.mac_type = hdr_2.ethernet.ether_type;
  lkp.pcp = 0;
 }

 action scope_l2_1tag() {
  lkp.mac_src_addr = hdr_2.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_2.ethernet.dst_addr;
  lkp.mac_type = hdr_2.vlan_tag[0].ether_type;
  lkp.pcp = hdr_2.vlan_tag[0].pcp;
 }

 table scope_l2_ {
  key = {
   hdr_2.ethernet.isValid(): exact;
   hdr_2.vlan_tag[0].isValid(): exact;
  }
  actions = {
   scope_l2_none;
   scope_l2;
   scope_l2_1tag;
  }
  const entries = {
   (false, false): scope_l2_none();

   (true, false): scope_l2();

   (true, true ): scope_l2_1tag();
  }
 }

 // -----------------------------
 // L3
 // -----------------------------

 action scope_l3_none() {
  lkp.ip_type = 0;
  lkp.ip_tos = 0;
  lkp.ip_proto = 0;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = 0;
  lkp.ip_dst_addr = 0;
  lkp.ip_len = 0; // extreme added
 }

 action scope_l3_v4() {
  lkp.ip_type = SWITCH_IP_TYPE_IPV4;
  lkp.ip_tos = hdr_2.ipv4.tos;
  lkp.ip_proto = hdr_2.ipv4.protocol;
  lkp.ip_flags = hdr_2.ipv4.flags;
  lkp.ip_src_addr = (bit<128>) hdr_2.ipv4.src_addr;
  lkp.ip_dst_addr = (bit<128>) hdr_2.ipv4.dst_addr;
  lkp.ip_len = hdr_2.ipv4.total_len;
 }

 action scope_l3_v6() {

  lkp.ip_type = SWITCH_IP_TYPE_IPV6;
  lkp.ip_tos = hdr_2.ipv6.tos;
  lkp.ip_proto = hdr_2.ipv6.next_hdr;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = hdr_2.ipv6.src_addr;
  lkp.ip_dst_addr = hdr_2.ipv6.dst_addr;
  lkp.ip_len = hdr_2.ipv6.payload_len;

 }

 table scope_l3_ {
  key = {
   hdr_2.ipv4.isValid(): exact;

   hdr_2.ipv6.isValid(): exact;

  }
  actions = {
   scope_l3_none;
   scope_l3_v4;
   scope_l3_v6;
  }
  const entries = {

   (false, false): scope_l3_none();
   (true, false): scope_l3_v4();
   (false, true ): scope_l3_v6();




  }
 }

 // -----------------------------
 // L4
 // -----------------------------

 action scope_l4_none() {
  lkp.l4_src_port = 0;
  lkp.l4_dst_port = 0;
  lkp.tcp_flags = 0;
 }

 action scope_l4_tcp() {
  lkp.l4_src_port = hdr_2.tcp.src_port;
  lkp.l4_dst_port = hdr_2.tcp.dst_port;
  lkp.tcp_flags = hdr_2.tcp.flags;
 }

 action scope_l4_udp() {
  lkp.l4_src_port = hdr_2.udp.src_port;
  lkp.l4_dst_port = hdr_2.udp.dst_port;
  lkp.tcp_flags = 0;
 }

 action scope_l4_sctp() {
  lkp.l4_src_port = hdr_2.sctp.src_port;
  lkp.l4_dst_port = hdr_2.sctp.dst_port;
  lkp.tcp_flags = 0;
 }

 table scope_l4_ {
  key = {
   hdr_2.tcp.isValid(): exact;
   hdr_2.udp.isValid(): exact;
   hdr_2.sctp.isValid(): exact;
  }
  actions = {
   scope_l4_tcp;
   scope_l4_udp;
   scope_l4_sctp;
   scope_l4_none;
  }
  const entries = {
   (false, false, false): scope_l4_none();
   (true, false, false): scope_l4_tcp();
   (false, true, false): scope_l4_udp();
   (false, false, true ): scope_l4_sctp();
  }
 }

 // -----------------------------
 // L2 / L3 / L4
 // -----------------------------

 action scope_l2_none_l3_none_l4_none() { scope_l2_none(); scope_l3_none(); scope_l4_none(); }
 action scope_l2_0tag_l3_none_l4_none() { scope_l2(); scope_l3_none(); scope_l4_none(); }
 action scope_l2_1tag_l3_none_l4_none() { scope_l2_1tag(); scope_l3_none(); scope_l4_none(); }
 action scope_l2_0tag_l3_v4_l4_none() { scope_l2(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_1tag_l3_v4_l4_none() { scope_l2_1tag(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_0tag_l3_v6_l4_none() { scope_l2(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_1tag_l3_v6_l4_none() { scope_l2_1tag(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_0tag_l3_v4_l4_tcp() { scope_l2(); scope_l3_v4(); scope_l4_tcp(); }
 action scope_l2_1tag_l3_v4_l4_tcp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_tcp(); }
 action scope_l2_0tag_l3_v6_l4_tcp() { scope_l2(); scope_l3_v6(); scope_l4_tcp(); }
 action scope_l2_1tag_l3_v6_l4_tcp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_tcp(); }
 action scope_l2_0tag_l3_v4_l4_udp() { scope_l2(); scope_l3_v4(); scope_l4_udp(); }
 action scope_l2_1tag_l3_v4_l4_udp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_udp(); }
 action scope_l2_0tag_l3_v6_l4_udp() { scope_l2(); scope_l3_v6(); scope_l4_udp(); }
 action scope_l2_1tag_l3_v6_l4_udp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_udp(); }
 action scope_l2_0tag_l3_v4_l4_sctp() { scope_l2(); scope_l3_v4(); scope_l4_sctp(); }
 action scope_l2_1tag_l3_v4_l4_sctp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_sctp(); }
 action scope_l2_0tag_l3_v6_l4_sctp() { scope_l2(); scope_l3_v6(); scope_l4_sctp(); }
 action scope_l2_1tag_l3_v6_l4_sctp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_sctp(); }

 table scope_l234_ {
  key = {
   hdr_2.ethernet.isValid(): exact;
   hdr_2.vlan_tag[0].isValid(): exact;

   hdr_2.ipv4.isValid(): exact;

   hdr_2.ipv6.isValid(): exact;


   hdr_2.tcp.isValid(): exact;
   hdr_2.udp.isValid(): exact;
   hdr_2.sctp.isValid(): exact;
  }
  actions = {
   scope_l2_0tag_l3_v4_l4_tcp;
   scope_l2_1tag_l3_v4_l4_tcp;
   scope_l2_0tag_l3_v6_l4_tcp;
   scope_l2_1tag_l3_v6_l4_tcp;
   scope_l2_0tag_l3_v4_l4_udp;
   scope_l2_1tag_l3_v4_l4_udp;
   scope_l2_0tag_l3_v6_l4_udp;
   scope_l2_1tag_l3_v6_l4_udp;
   scope_l2_0tag_l3_v4_l4_sctp;
   scope_l2_1tag_l3_v4_l4_sctp;
   scope_l2_0tag_l3_v6_l4_sctp;
   scope_l2_1tag_l3_v6_l4_sctp;
   scope_l2_0tag_l3_v4_l4_none;
   scope_l2_1tag_l3_v4_l4_none;
   scope_l2_0tag_l3_v6_l4_none;
   scope_l2_1tag_l3_v6_l4_none;
   scope_l2_0tag_l3_none_l4_none;
   scope_l2_1tag_l3_none_l4_none;
   scope_l2_none_l3_none_l4_none;
  }
  const entries = {

   (false, false, false, false, false, false, false): scope_l2_none_l3_none_l4_none();

   (true, false, false, false, false, false, false): scope_l2_0tag_l3_none_l4_none();
   (true, true, false, false, false, false, false): scope_l2_1tag_l3_none_l4_none();

   (true, false, true, false, false, false, false): scope_l2_0tag_l3_v4_l4_none();
   (true, true, true, false, false, false, false): scope_l2_1tag_l3_v4_l4_none();

   (true, false, false, true, false, false, false): scope_l2_0tag_l3_v6_l4_none();
   (true, true, false, true, false, false, false): scope_l2_1tag_l3_v6_l4_none();

   (true, false, true, false, true, false, false): scope_l2_0tag_l3_v4_l4_tcp();
   (true, true, true, false, true, false, false): scope_l2_1tag_l3_v4_l4_tcp();

   (true, false, false, true, true, false, false): scope_l2_0tag_l3_v6_l4_tcp();
   (true, true, false, true, true, false, false): scope_l2_1tag_l3_v6_l4_tcp();

   (true, false, true, false, false, true, false): scope_l2_0tag_l3_v4_l4_udp();
   (true, true, true, false, false, true, false): scope_l2_1tag_l3_v4_l4_udp();

   (true, false, false, true, false, true, false): scope_l2_0tag_l3_v6_l4_udp();
   (true, true, false, true, false, true, false): scope_l2_1tag_l3_v6_l4_udp();

   (true, false, true, false, false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
   (true, true, true, false, false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();

   (true, false, false, true, false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
   (true, true, false, true, false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
# 961 "scoper.p4"
  }
 }

 // -----------------------------
 // TUNNEL
 // -----------------------------

 action scope_tunnel_none() {
  lkp.tunnel_type = 0;
  lkp.tunnel_id = 0;
 }
/*
	action scope_tunnel_vlan() {
		lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
		lkp.tunnel_id   = (switch_tunnel_id_t)hdr_2.vlan_tag[0].vid;
	}
*/
 action scope_tunnel_vni() {
  lkp.tunnel_type = lkp_2.tunnel_type;
  lkp.tunnel_id = lkp_2.tunnel_id;
 }

 table scope_tunnel_ {
  key = {
   lkp_2.tunnel_type: exact;
/*
			tunnel_type: ternary;
			hdr_2.vlan_tag[0].isValid(): exact;
			hdr_2.vlan_tag[0].vid: ternary;
*/
  }
  actions = {
   scope_tunnel_vni;
//          scope_tunnel_vlan;
   scope_tunnel_none;
  }
  const entries = {
/*
			// highest -> lowest priority in tcam
			(0, true,  0): scope_tunnel_none(); // tag has priority only
			(0, true,  _): scope_tunnel_vlan(); // tag has priority and vlan
			(_, true,  _): scope_tunnel_vni();
			(_, false, _): scope_tunnel_vni();
			(0, false, _): scope_tunnel_none();
*/
   (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
  }
  const default_action = scope_tunnel_vni;
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
//		scope_l2_.apply();
//		scope_l3_.apply();
//		scope_l4_.apply();
  scope_l234_.apply();
//		scope_tunnel_.apply();
  scope_tunnel_vni();

//		lkp.drop_reason = drop_reason;
 }

}

// ============================================================================
/*
control Scoper_l7(
	in udf_h hdr_udf,
	inout switch_lookup_fields_t lkp
) {
	// -----------------------------
		
	action set_udf() {
#ifdef UDF_ENABLE
		lkp.udf = hdr_udf.opaque;
#endif 
	}

	action clear_udf() {
#ifdef UDF_ENABLE
		lkp.udf = 0;
#endif
	}

	table validate_udf {
		key = {
			hdr_udf.isValid() : exact;
		}

		actions = {
			NoAction;
			set_udf;
			clear_udf;
		}

		const default_action = NoAction;
		const entries = {
			(true)  : set_udf();
			(false) : clear_udf();
		}
	}

	// -----------------------------

	apply {
#ifdef UDF_ENABLE
		validate_udf.apply();
#endif // UDF_ENABLE
	}

}
*/
# 27 "acl.p4" 2
# 1 "copp.p4" 1



// -----------------------------------------------------------------------------
// Ingress COPP
// -----------------------------------------------------------------------------

control IngressCopp (
 in switch_copp_meter_id_t copp_meter_id,

 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
) {



 //-------------------------------------------------------------

 Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;

 action meter_index(switch_copp_meter_id_t index) {
  ig_intr_md_for_tm.packet_color = (bit<2>) copp_meter.execute(index);
 }

 //-------------------------------------------------------------

 DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

 action copp_drop() {
  ig_intr_md_for_tm.copy_to_cpu = 1w0;
  copp_stats.count();
 }

 action copp_permit() {
  copp_stats.count();
 }

 table copp {
  key = {
   ig_intr_md_for_tm.packet_color : ternary;
   copp_meter_id : ternary @name("copp_meter_id");
  }

  actions = {
   copp_permit;
   copp_drop;
  }

  const default_action = copp_permit;
  size = (1 << 8 + 1);
  counters = copp_stats;
 }



 //-------------------------------------------------------------

 apply {


  // apply the meter, then process the result
  meter_index(copp_meter_id);
  copp.apply();


 }

}

// -----------------------------------------------------------------------------
// Egress COPP
// -----------------------------------------------------------------------------

control EgressCopp (
 in switch_copp_meter_id_t copp_meter_id,

 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr
) (
) {



 switch_pkt_color_t copp_color;

 //-------------------------------------------------------------

 Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;

 action meter_index(switch_copp_meter_id_t index) {
  copp_color = (bit<2>) copp_meter.execute(index);
 }

 //-------------------------------------------------------------

 DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

 action copp_drop() {
  eg_intr_md_for_dprsr.mirror_type = 0;
  copp_stats.count();
 }

 action copp_permit() {
  copp_stats.count();
 }

 table copp {
  key = {
   copp_color : exact;
   copp_meter_id : exact;
  }

  actions = {
   copp_permit;
   copp_drop;
  }

  const default_action = copp_permit;
  size = (1 << 8 + 1);
  counters = copp_stats;
 }



 //-------------------------------------------------------------

 apply {


  // apply the meter, then process the result
  meter_index(copp_meter_id);
  copp.apply();


 }
}
# 28 "acl.p4" 2

//-----------------------------------------------------------------------------
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 108 "acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 176 "acl.p4"
//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------
# 233 "acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL actions.
//-----------------------------------------------------------------------------
# 289 "acl.p4"
// ============================================================================
// ============================================================================
// Ingress ACL ================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control IngressMacAcl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 in switch_header_outer_t hdr_1,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary; lkp.pcp : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------

   lkp.vid : ternary;

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control IngressIpAcl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;
   lkp.mac_type : ternary;

   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control IngressIpv4Acl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr_v4 : ternary @name("lkp.ip_src_addr[31:0]"); lkp.ip_dst_addr_v4 : ternary @name("lkp.ip_dst_addr[31:0]"); lkp.ip_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;




   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







  }

  actions = {
   no_action;
   hit();
  }
  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------



control IngressIpv6Acl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;




   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}



//-----------------------------------------------------------------------------
// L7 ACL
//-----------------------------------------------------------------------------

control IngressL7Acl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 in udf_h hdr_udf,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout switch_nexthop_t nexthop_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<8> flow_class_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
  

   // extreme added



   // -------------------------------------------
   hdr.nsh_type1.sap : ternary @name("sap");
   // -------------------------------------------
   flow_class_ : ternary @name("flow_class");
  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

// ----------------------------------------------------------------------------
// Ingress Access Control List (ACL)
//
// @param lkp : Lookup fields used for lookups.
// @param ig_md : Ingress metadata.
// @param mac_acl_enable : Add a ACL slice for L2 traffic. If mac_acl_enable is false, IPv4 ACL is
// applied to IPv4 and non-IP traffic.
// @param mac_packet_class_enable : Controls whether MAC ACL applies to all traffic entering the
// interface, including IP traffic, or to non-IP traffic only.
// ----------------------------------------------------------------------------

control IngressAcl(
 inout switch_lookup_fields_t lkp,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 inout switch_header_transport_t hdr_0,
 in switch_header_outer_t hdr_1,
 in switch_header_inner_t hdr_2,
 in udf_h hdr_udf,
 in bit<8> int_ctrl_flags
) (



 switch_uint32_t ipv4_table_size=512,
 switch_uint32_t ipv6_table_size=512,

 switch_uint32_t mac_table_size=512,
 switch_uint32_t l7_table_size=512
) {

 // ---------------------------------------------------




 IngressIpv4Acl(ipv4_table_size) ipv4_acl;

 IngressIpv6Acl(ipv6_table_size) ipv6_acl;


 IngressMacAcl(mac_table_size) mac_acl;




//	Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
 Counter<bit<32>, bit<15>>(32768, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<16>>(65536, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<17>>(131072, CounterType_t.PACKETS_AND_BYTES) indirect_counter;

 switch_nexthop_t nexthop;
 bool drop;
 bool terminate;
 bool scope;
 switch_cpu_reason_t cpu_reason;
 bool copy_to_cpu;
 bool redirect_to_cpu;
 bool dtel_report_type_enable;
 switch_copp_meter_id_t copp_meter_id;
 bit<8> flow_class;
 switch_dtel_report_type_t dtel_report_type;
 bit<6> indirect_counter_index;

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		hdr_0.nsh_type1.scope = scope_new;
	}

	table scope_inc {
		key = {
			hdr_0.nsh_type1.scope : exact;
		}
		actions = {
			new_scope;
		}
		const entries = {
			0  : new_scope(1);
			1  : new_scope(2);
			2  : new_scope(3);
		}
	}
*/

 // -------------------------------------
 // Table: COPP
 // -------------------------------------

 action copy_to_cpu_process_results(in switch_cpu_reason_t cpu_reason_, in switch_copp_meter_id_t copp_meter_id_) {
  ig_intr_md_for_tm.copy_to_cpu = 1w1;
  ig_md.cpu_reason = cpu_reason_;
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
  nexthop = 0;
  drop = false;
  terminate = false;
  scope = false;
  copy_to_cpu = false;
  redirect_to_cpu = false;
  dtel_report_type_enable = false;
  cpu_reason = 0;
//		copp_meter_id                = 0; // TODO: this may be data and therefore not need to be initialized
  flow_class = 0;

  ig_md.nsh_md.truncate_enable = false;
  ig_md.nsh_md.dedup_en = false;
  ig_md.nsh_md.sfc_enable = false;

  // --------------
  // tables
  // --------------

  // Derek: The way this works is that the "hit" action of each table MUST write ALL of the outputs.  This is so that we don't
  // end up with partial results from one table and partial results from another in the final result.  So it is very import
  // that all "hit" actions write ALL of the outputs.

  // ----- l2 -----
  mac_acl.apply(
   lkp,
   hdr_0,
   hdr_1,
   ig_md,
   ig_intr_md_for_dprsr,
   ip_len, ip_len_is_rng_bitmask,
   l4_src_port, l4_src_port_is_rng_bitmask,
   l4_dst_port, l4_dst_port_is_rng_bitmask,
   int_ctrl_flags,
   // ----- results -----
   nexthop,
   drop,
   terminate,
   scope,
   copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class,
   dtel_report_type_enable, dtel_report_type,
   indirect_counter_index
  );

  // ----- l3/4 -----
# 914 "acl.p4"
  if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

   ipv6_acl.apply(
    lkp,
    hdr_0,
    ig_md,
    ig_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    nexthop,
    drop,
    terminate,
    scope,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class,
    dtel_report_type_enable, dtel_report_type,
    indirect_counter_index
   );

  } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
   ipv4_acl.apply(
    lkp,
    hdr_0,
    ig_md,
    ig_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    nexthop,
    drop,
    terminate,
    scope,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id, flow_class,
    dtel_report_type_enable, dtel_report_type,
    indirect_counter_index
   );
  }


  // ----- l7 -----
# 982 "acl.p4"
  // --------------
  // results
  // --------------

  // ----- drop -----

  if(drop == true) {
   ig_intr_md_for_dprsr.drop_ctl = 0x1;
  }

  // note: terminate + !scope is an illegal condition

  if(lkp.next_lyr_valid == true) {

   // ----- terminate -----

   if(terminate == true) {
    ig_md.tunnel_1.terminate = true;
    if(hdr_0.nsh_type1.scope == 1) {
     ig_md.tunnel_2.terminate = true;
    }
   }

   // ----- scope -----


   if(scope == true) {
    if(hdr_0.nsh_type1.scope == 0) {

     // note: need to change scope here so that the lag
     // hash gets the new values....


     Scoper.apply(
      ig_md.lkp_2,
//						ig_md.drop_reason_2,

      ig_md.lkp_1
     );
# 1031 "acl.p4"
//					ig_md.nsh_md.hash_1 = ig_md.nsh_md.hash_2;
    }

    hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
//				scope_inc.apply();
   }

  }

  // ----- truncate -----

  if(ig_md.nsh_md.truncate_enable) {

   ig_intr_md_for_dprsr.mtu_trunc_len = ig_md.nsh_md.truncate_len + 43;

  }

  // ----- copy to cpu -----

  if(copy_to_cpu == true) {
   copy_to_cpu_process_results(cpu_reason, copp_meter_id);
  } else if(redirect_to_cpu == true) {
   ig_intr_md_for_dprsr.drop_ctl = 0b1;
   copy_to_cpu_process_results(cpu_reason, copp_meter_id);
  }

  if((copy_to_cpu == true) || (redirect_to_cpu == true)) {
   IngressCopp.apply(copp_meter_id, ig_intr_md_for_tm);
  }
# 1069 "acl.p4"
  indirect_counter.count(ig_md.port ++ indirect_counter_index);
 }
}

// ============================================================================
// ============================================================================
// Egress ACL =================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control EgressMacAcl(
 in switch_lookup_fields_t lkp,
 in switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool drop_,
 inout bool terminate_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

 action no_action() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary; lkp.pcp : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   eg_md.lkp_1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.lkp_1.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control EgressIpAcl(
 in switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool drop_,
 inout bool terminate_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<6> indirect_counter_index_
)(
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

 action no_action() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.ip_flags : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;
   lkp.mac_type : ternary;

   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







   // -------------------------------------------

   eg_md.lkp_1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.lkp_1.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}
//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control EgressIpv4Acl(
 in switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool drop_,
 inout bool terminate_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

 action no_action() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr_v4 : ternary @name("lkp.ip_src_addr[31:0]"); lkp.ip_dst_addr_v4 : ternary @name("lkp.ip_dst_addr[31:0]"); lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.ip_flags : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;




   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







   // -------------------------------------------

   eg_md.lkp_1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.lkp_1.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------



control EgressIpv6Acl(
 in switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool drop_,
 inout bool terminate_,
 inout bool copy_to_cpu_,
 inout bool redirect_to_cpu_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_copp_meter_id_t copp_meter_id_,
 inout bit<6> indirect_counter_index_
)(
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

 action no_action() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool copy_to_cpu, bool redirect_to_cpu, switch_cpu_reason_t cpu_reason_code, switch_copp_meter_id_t copp_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; copy_to_cpu_ = copy_to_cpu; redirect_to_cpu_ = redirect_to_cpu; cpu_reason_ = cpu_reason_code; copp_meter_id_ = copp_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;




   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   ip_len : ternary @name("lkp.ip_len");
   ip_len_is_rng_bitmask : ternary @name("lkp.ip_len_is_rng_bitmask");







   // -------------------------------------------

   l4_src_port : ternary @name("lkp.l4_src_port");
   l4_src_port_is_rng_bitmask : ternary @name("lkp.l4_src_port_is_rng_bitmask");







   // -------------------------------------------

   l4_dst_port : ternary @name("lkp.l4_dst_port");
   l4_dst_port_is_rng_bitmask : ternary @name("lkp.l4_dst_port_is_rng_bitmask");







   // -------------------------------------------

   eg_md.lkp_1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.lkp_1.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  acl.apply();
 }
}



//-----------------------------------------------------------------------------

control EgressAcl(
 in switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bool ip_len_is_rng_bitmask,
 in bit<16> l4_src_port,
 in bool l4_src_port_is_rng_bitmask,
 in bit<16> l4_dst_port,
 in bool l4_dst_port_is_rng_bitmask,
 inout switch_header_transport_t hdr_0,
 in switch_header_outer_t hdr_1,
 in bit<8> int_ctrl_flags
) (



 switch_uint32_t ipv4_table_size=512,
 switch_uint32_t ipv6_table_size=512,

 switch_uint32_t mac_table_size=512
) {

 // ---------------------------------------------------




 EgressIpv4Acl(ipv4_table_size) egress_ipv4_acl;

 EgressIpv6Acl(ipv6_table_size) egress_ipv6_acl;


 EgressMacAcl(mac_table_size) egress_mac_acl;

//	Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
 Counter<bit<32>, bit<15>>(32768, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<16>>(65536, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<17>>(131072, CounterType_t.PACKETS_AND_BYTES) indirect_counter;

 bool drop;
 bool terminate;
 bool copy_to_cpu;
 bool redirect_to_cpu;
 switch_cpu_reason_t cpu_reason;
 switch_copp_meter_id_t copp_meter_id;
 bit<6> indirect_counter_index;

 // -------------------------------------
 // Table: Terminate
 // -------------------------------------

/*
	action terminate_table_none() {
//		eg_md.nsh_md.terminate_popcount = 0;
	}

	action terminate_table_outer() {
		eg_md.tunnel_1.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 1;
	}

//	action terminate_table_inner() {
//		eg_md.tunnel_2.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 1;
//	}

	action terminate_table_both() {
		eg_md.tunnel_1.terminate = true;
		eg_md.tunnel_2.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 2;
	}

	table terminate_table {
		key = {
			hdr_0.nsh_type1.scope        : exact;

			eg_md.nsh_md.terminate_outer : exact; // prev
			terminate                    : exact; // curr
			eg_md.nsh_md.terminate_inner : exact; // next
		}
		actions = {
			terminate_table_none;
			terminate_table_outer;
//			terminate_table_inner;
			terminate_table_both;
		}
		const entries = {
			//  prev,  curr,  next
			// --------------------
			// scope is "outer" -- ignore terminate prev bit (there is nothing before present scope)
			(0, false, false, false) : terminate_table_none();
			(0, true,  false, false) : terminate_table_none();
			(0, false, true,  false) : terminate_table_outer();
			(0, true,  true,  false) : terminate_table_outer();
			(0, false, false, true ) : terminate_table_both();  // can't term just inner, must term both outer and inner
			(0, true,  false, true ) : terminate_table_both();  // can't term just inner, must term both outer and inner
			(0, false, true,  true ) : terminate_table_both();
			(0, true,  true,  true ) : terminate_table_both();

			// scope is "inner" -- ignore terminate next bit (there is nothing after present scope)
			(1, false, false, false) : terminate_table_none();
			(1, true,  false, false) : terminate_table_outer();
			(1, false, true,  false) : terminate_table_both();   // can't term just inner, must term both outer and inner
			(1, true,  true,  false) : terminate_table_both();
			(1, false, false, true ) : terminate_table_none();
			(1, true,  false, true ) : terminate_table_outer();
			(1, false, true,  true ) : terminate_table_both();   // can't term just inner, must term both outer and inner
			(1, true,  true,  true ) : terminate_table_both();
		}
	}
*/

 // -------------------------------------
 // Table: COPP
 // -------------------------------------

 action copy_to_cpu_process_results(in switch_cpu_reason_t cpu_reason_, in switch_copp_meter_id_t copp_meter_id_) {
  eg_md.cpu_reason = cpu_reason_;
  eg_intr_md_for_dprsr.mirror_type = 2;
  eg_md.mirror.type = 2;
  eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU;
  eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
  drop = false;
  terminate = false;
  copy_to_cpu = false;
  redirect_to_cpu = false;
  cpu_reason = 0;
//		copp_meter_id                = 0; // TODO: this may be data and therefore not need to be initialized

  eg_md.nsh_md.strip_tag_e = false;
  eg_md.nsh_md.strip_tag_vn = false;
  eg_md.nsh_md.strip_tag_vlan = false;
  eg_md.nsh_md.add_tag_vlan_bd = 0;
  eg_md.nsh_md.truncate_enable = false;
  eg_md.nsh_md.dedup_en = false;
  eg_md.nsh_md.terminate_outer = false;
  eg_md.nsh_md.terminate_inner = false;

  // --------------
  // tables
  // --------------

  // Derek: The way this works is that the "hit" action of each table MUST write ALL of the outputs.  This is so that we don't
  // end up with partial results from one table and partial results from another in the final result.  So it is very import
  // that all "hit" actions write ALL of the outputs.

  // ----- l2 -----
  egress_mac_acl.apply(
   lkp,
   hdr_1,
   eg_md,
   eg_intr_md_for_dprsr,
   ip_len, ip_len_is_rng_bitmask,
   l4_src_port, l4_src_port_is_rng_bitmask,
   l4_dst_port, l4_dst_port_is_rng_bitmask,
   int_ctrl_flags,
   // ----- results -----
   drop,
   terminate,
   copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id,
   indirect_counter_index
  );

  // ----- l3/4 -----
# 1653 "acl.p4"
  if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

   egress_ipv6_acl.apply(
    lkp,
    eg_md,
    eg_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    drop,
    terminate,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id,
    indirect_counter_index
   );

  } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
   egress_ipv4_acl.apply(
    lkp,
    eg_md,
    eg_intr_md_for_dprsr,
    ip_len, ip_len_is_rng_bitmask,
    l4_src_port, l4_src_port_is_rng_bitmask,
    l4_dst_port, l4_dst_port_is_rng_bitmask,
    int_ctrl_flags,
    // ----- results -----
    drop,
    terminate,
    copy_to_cpu, redirect_to_cpu, cpu_reason, copp_meter_id,
    indirect_counter_index
   );
  }


  // --------------
  // results
  // --------------

  // ----- drop -----

  if(drop == true) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1;
  }

  // note: terminate + !scope is an illegal condition

  // ----- terminate -----
/*
		if(terminate || eg_md.nsh_md.terminate_inner) {
			eg_md.tunnel_1.terminate           = true;
			if(hdr_0.nsh_type1.scope == 1) {
				eg_md.tunnel_2.terminate           = true;
			}
		}
*/
  if((eg_md.nsh_md.terminate_inner == true)) {
   // outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
   if(hdr_0.nsh_type1.scope == 1) {
    eg_md.tunnel_1.terminate = true;
   }
  }

  if(lkp.next_lyr_valid == true) {

   // ----- terminate -----

   if(terminate == true) {
    eg_md.tunnel_1.terminate = true;
    if(hdr_0.nsh_type1.scope == 1) {
     eg_md.tunnel_2.terminate = true;
    }

   }

   // ----- scope -----

   // since we don't have an explicit 'scope' signal in egress acl, use 'terminate':
   if(terminate == true) {

    // note: don't need to advance the data here, as nobody else looks at it after this.

    hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
//				scope_inc.apply();
   }
  }

  // ----- truncate -----

  if(eg_md.nsh_md.truncate_enable) {

   eg_intr_md_for_dprsr.mtu_trunc_len = eg_md.nsh_md.truncate_len;

  }

  // ----- copy to cpu -----

  if(copy_to_cpu == true) {
   copy_to_cpu_process_results(cpu_reason, copp_meter_id);
  } else if(redirect_to_cpu == true) {
   copy_to_cpu_process_results(cpu_reason, copp_meter_id);
   eg_intr_md_for_dprsr.drop_ctl = 0x1;
  }

  if((copy_to_cpu == true) || (redirect_to_cpu == true)) {
   EgressCopp.apply(copp_meter_id, eg_intr_md_for_dprsr);
  }



  indirect_counter.count(eg_md.port ++ indirect_counter_index);
 }
}
# 26 "l3.p4" 2
# 1 "l2.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




//-----------------------------------------------------------------------------
// Destination MAC lookup
//
// Performs a lookup on bd and destination MAC address.
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress BD.
//
// @param dst_addr : destination MAC address.
// @param ig_md : Ingess metadata
// @param ig_intr_md_for_tm
// @param table_size : Size of the dmac table.
//-----------------------------------------------------------------------------
//control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);

control DMAC(
 in mac_addr_t dst_addr,
 inout switch_ingress_metadata_t ig_md
) (
 switch_uint32_t table_size
) {

//	bool copp_enable_;
//	switch_copp_meter_id_t copp_meter_id_;

 //-------------------------------------------------------------

 action dmac_miss(//bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  ig_md.egress_port_lag_index = SWITCH_FLOOD;
//		ig_md.flags.dmac_miss = true;

//		copp_enable_ = copp_enable;
//		copp_meter_id_ = copp_meter_id;
 }

 action dmac_hit(switch_port_lag_index_t port_lag_index //, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  ig_md.egress_port_lag_index = port_lag_index;

//		copp_enable_ = copp_enable;
//		copp_meter_id_ = copp_meter_id;
 }

 action dmac_multicast(switch_mgid_t index //, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  ig_md.multicast.id = index;
  ig_md.egress_port_lag_index = 0; // derek added

//		copp_enable_ = copp_enable;
//		copp_meter_id_ = copp_meter_id;
 }

 action dmac_redirect(switch_nexthop_t nexthop_index //, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  ig_md.nexthop = nexthop_index;

//		copp_enable_ = copp_enable;
//		copp_meter_id_ = copp_meter_id;
 }

 table dmac {
  key = {
   ig_md.bd : exact;
   dst_addr : exact;
  }

  actions = {
   dmac_miss;
   dmac_hit;
   dmac_multicast;
   dmac_redirect;
  }

//		const default_action = dmac_miss(false, 0);
  const default_action = dmac_miss;
  size = table_size;
 }

 //-------------------------------------------------------------

 apply {
//		ig_md.flags.dmac_miss = false;

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {
   dmac.apply();
  }


//		ig_md.copp_enable = copp_enable_;
//      ig_md.copp_meter_id = copp_meter_id_;

 }
}

//-----------------------------------------------------------------------------

control IngressBd(
 in switch_bd_t bd,
 in switch_pkt_type_t pkt_type
) (
 switch_uint32_t table_size
) {

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action count() { stats.count(); }

 table bd_stats {
  key = {
   bd : exact;
   pkt_type : exact;
  }

  actions = {
   count;
   @defaultonly NoAction;
  }

  const default_action = NoAction;

  // 3 entries per bridge domain for unicast/broadcast/multicast packets.
  size = 3 * table_size;
  counters = stats;
 }

 apply {
  bd_stats.apply();
 }
}

//-----------------------------------------------------------------------------

control EgressBd(
 in switch_header_transport_t hdr,
 in switch_bd_t bd,
 in switch_pkt_src_t pkt_src,
 out switch_smac_index_t smac_idx
) (
 switch_uint32_t table_size
) {
/*
	DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS_AND_BYTES) stats;

	action count() {
		stats.count();
	}

	table bd_stats {
		key = {
			bd : exact;
//          pkt_type : exact;
		}

		actions = {
			count;
			@defaultonly NoAction;
		}

		size = 3 * table_size;
		counters = stats;
	}
*/
 action set_bd_properties(
  switch_smac_index_t smac_index
 ) {

  smac_idx = smac_index;

 }

 table bd_mapping {
  key = { bd : exact; }
  actions = {
   NoAction;
   set_bd_properties;
  }

  const default_action = NoAction;
  size = table_size;
 }

 apply {
  smac_idx = 0; // extreme added

  bd_mapping.apply();
//		if (pkt_src == SWITCH_PKT_SRC_BRIDGED)
//			bd_stats.apply();
 }
}

//-----------------------------------------------------------------------------
// VLAN tag decapsulation
// Removes the vlan tag by default or selectively based on the ingress port if QINQ_ENABLE flag
// is defined.
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param port : Ingress port.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------

control VlanDecap(
 inout switch_header_transport_t hdr,
 in switch_egress_metadata_t eg_md
) {

 // ---------------------
 // Apply
 // ---------------------

 apply {
  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
   // Remove the vlan tag by default.
   if (hdr.vlan_tag[0].isValid()) {
    hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
    hdr.vlan_tag[0].setInvalid();
   }
  }
 }
}

//-----------------------------------------------------------------------------
// Vlan translation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------

control VlanXlate(
 inout switch_header_transport_t hdr,
 in switch_egress_metadata_t eg_md
) (
 switch_uint32_t bd_table_size,
 switch_uint32_t port_bd_table_size
) {

 action set_vlan_untagged() {
  //NoAction.
 }
# 283 "l2.p4"
 action set_vlan_tagged(vlan_id_t vid, bit<3> pcp) {



  hdr.vlan_tag[0].setValid();
  hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
  hdr.vlan_tag[0].pcp = pcp; // derek: added this here...barefoot set it in qos.p4, which we don't have.
  hdr.vlan_tag[0].cfi = 0;
  hdr.vlan_tag[0].vid = vid;
  hdr.ethernet.ether_type = 0x8100;
 }

 table port_bd_to_vlan_mapping {
  key = {
   eg_md.port_lag_index : exact @name("port_lag_index");
   eg_md.bd : exact @name("bd");
  }

  actions = {
   set_vlan_untagged;
   set_vlan_tagged;
  }

  const default_action = set_vlan_untagged;
  size = port_bd_table_size;
  //TODO : fix table size once scale requirements for double tag is known
 }

 table bd_to_vlan_mapping {
  key = { eg_md.bd : exact @name("bd"); }
  actions = {
   set_vlan_untagged;
   set_vlan_tagged;
  }

  const default_action = set_vlan_untagged;
  size = bd_table_size;
 }
# 350 "l2.p4"
 apply {
  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
   if (!port_bd_to_vlan_mapping.apply().hit) {
    bd_to_vlan_mapping.apply();
   }
  }



 }
}
# 27 "l3.p4" 2

//-----------------------------------------------------------------------------
// Router MAC lookup
// key: destination MAC address.
// - Route the packet if the destination MAC address is owned by the switch.
//-----------------------------------------------------------------------------
# 59 "l3.p4"
//-----------------------------------------------------------------------------
// @param lkp : Lookup fields used to perform L2/L3 lookups.
// @param ig_md : Ingress metadata fields.
// @param dmac : DMAC instance (See l2.p4)
//-----------------------------------------------------------------------------
control IngressUnicast(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md
) (
) {

//  RMAC

 //-----------------------------------------------------------------------------
 // Apply
 //-----------------------------------------------------------------------------

    apply {
//      if (rmac.apply().hit) {
//      } else {
//      }
    }
}
# 46 "npb.p4" 2
# 1 "nexthop.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

// ----------------------------------------------------------------------------
// Nexthop/ECMP resolution
//
// @param ig_md : Ingress metadata fields
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_group_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control Nexthop(inout switch_ingress_metadata_t ig_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_table_size,
                switch_uint32_t ecmp_selection_table_size) {
/*
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
#ifdef RESILIENT_ECMP_HASH_ENABLE
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.RESILIENT,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;
#else
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;
#endif
*/
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action(
 ) {
  stats.count();

 }

    action set_nexthop_properties(
  switch_port_lag_index_t port_lag_index,
        switch_bd_t bd
 ) {
  stats.count();

        ig_md.egress_port_lag_index = port_lag_index;
    }

    action set_nexthop_properties_post_routed_flood(
  switch_bd_t bd,
  switch_mgid_t mgid
 ) {
  stats.count();

        ig_md.egress_port_lag_index = 0;
        ig_md.multicast.id = mgid;
    }
/*
    action set_nexthop_properties_glean(
	) {
		stats.count();

        ig_md.flags.glean = true;
    }
*/
    action set_nexthop_properties_drop(
 ) {
  stats.count();

        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }
/*
    action set_ecmp_properties(
		switch_port_lag_index_t port_lag_index,
        switch_bd_t bd,
        switch_nexthop_t nexthop_index
	) {
		stats.count();

        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(port_lag_index, bd);
    }

    action set_ecmp_properties_drop(
	) {
		stats.count();

        set_nexthop_properties_drop();
    }

    action set_ecmp_properties_post_routed_flood(
        switch_bd_t bd,
        switch_mgid_t mgid,
        switch_nexthop_t nexthop_index
	) {
		stats.count();

        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid);
    }

    action set_ecmp_properties_glean(
		switch_nexthop_t nexthop_index
	) {
		stats.count();

        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }
*/
    action set_nexthop_properties_tunnel(
  switch_bd_t bd,
  switch_tunnel_index_t tunnel_index
 ) {
  stats.count();

        // TODO(msharif) : Disable cut-through for non-ip packets.
        ig_md.tunnel_0.index = tunnel_index;
        ig_md.egress_port_lag_index = 0;
    }
/*
    action set_ecmp_properties_tunnel(
		switch_bd_t bd,
		switch_tunnel_index_t tunnel_index,
		switch_nexthop_t nexthop_index
	) {
		stats.count();

        set_nexthop_properties_tunnel(bd, tunnel_index);
        ig_md.nexthop = nexthop_index;
    }
*/
/*
    table ecmp {
        key = {
            ig_md.nexthop : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_drop;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;
            set_ecmp_properties_tunnel;
        }

        const default_action = NoAction;
        size = ecmp_table_size;
        implementation = ecmp_selector;
    }
*/



    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            no_action;
            set_nexthop_properties;
            set_nexthop_properties_drop;
//          set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;
            set_nexthop_properties_tunnel;
        }

        const default_action = no_action;
  counters = stats;
        size = nexthop_table_size;
    }

    apply {






        switch(nexthop.apply().action_run) {
//          NoAction : { ecmp.apply(); }
            default : {}
        }


    }
}

// ----------------------------------------------------------------------------
// OuterFib (aka Outer Nexthop)
// ----------------------------------------------------------------------------

control OuterFib(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t fib_table_size,
                     switch_uint32_t ecmp_table_size,
                     switch_uint32_t ecmp_selection_table_size) {
//  Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
//  ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
//  ActionSelector(ecmp_action_profile,
//                 selector_hash,
//                 SelectorMode_t.FAIR,
//                 ECMP_MAX_MEMBERS_PER_GROUP,
//                 ecmp_group_table_size) ecmp_selector;

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action(
 ) {
  stats.count();

 }

    action set_nexthop_properties(
  switch_port_lag_index_t port_lag_index,
        switch_outer_nexthop_t nexthop_index
 ) {
  stats.count();

        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_port_lag_index = port_lag_index;
    }

    table fib {
        key = {
            ig_md.tunnel_0.index : exact;
//          ig_md.hash[31:0] : selector;
        }

        actions = {
            no_action;
            set_nexthop_properties;
        }

        const default_action = no_action;
//      implementation = ecmp_selector;
  counters = stats;
        size = fib_table_size;
    }

    apply {

        fib.apply();

    }
}
# 47 "npb.p4" 2
# 1 "port.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "rewrite.p4" 1

/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




# 1 "l2.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 28 "rewrite.p4" 2

control Rewrite(inout switch_header_outer_t hdr,
    inout switch_egress_metadata_t eg_md,
    inout switch_tunnel_metadata_t tunnel
)(
    switch_uint32_t nexthop_table_size,
    switch_uint32_t bd_table_size) {

//	EgressBd(bd_table_size) egress_bd;
 switch_smac_index_t smac_index;

 // ---------------------------------------------
 // Table: Nexthop Rewrite
 // ---------------------------------------------

 action rewrite_l2_with_tunnel( // ---- + -- + tun type + -------
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

  switch_tunnel_type_t type
 ) {
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later


  tunnel.type = type;

 }

 // ---------------------------------------------

 action rewrite_l3( // dmac + bd + -------- + -------
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,
  switch_bd_t bd
 ) {
//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = bd; // derek: add in later
 }

 // ---------------------------------------------

 action rewrite_l3_with_tunnel_id( // dmac + bd + tun type + tun id
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

  switch_tunnel_type_t type,
  switch_tunnel_id_t id
 ) {

//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = SWITCH_BD_DEFAULT_VRF; // derek: add in later

  tunnel.type = type;
  tunnel.id = id;

 }

 // ---------------------------------------------

 action rewrite_l3_with_tunnel_bd( // dmac + bd + tun type + -------
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,
  switch_bd_t bd,

  switch_tunnel_type_t type
 ) {

//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = bd; // derek: add in later

  tunnel.type = type;

 }

 // ---------------------------------------------

 action rewrite_l3_with_tunnel( // dmac + bd(vrf) + tun type + -------
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

  switch_tunnel_type_t type
 ) {

//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = (switch_bd_t) eg_md.vrf;

  tunnel.type = type;

 }

 // ---------------------------------------------

 table nexthop_rewrite {
  key = { eg_md.nexthop : exact; }
  actions = {

   NoAction;


   rewrite_l2_with_tunnel;
   rewrite_l3;
   rewrite_l3_with_tunnel;
   rewrite_l3_with_tunnel_bd;
   rewrite_l3_with_tunnel_id;



  }


  const default_action = NoAction;



  size = nexthop_table_size;
 }

 // ---------------------------------------------
 // Table: SMAC Rewrite
 // ---------------------------------------------
/*
	action rewrite_smac(mac_addr_t smac) {
		hdr.ethernet.src_addr = smac;
	}

	table smac_rewrite {
		key = { smac_index : exact; }
		actions = {
			NoAction;
			rewrite_smac;
		}

		const default_action = NoAction;
	}
*/
 // ---------------------------------------------
 // Apply
 // ---------------------------------------------

 apply {
  smac_index = 0;

  // Should not rewrite packets redirected to CPU.

  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {



   nexthop_rewrite.apply();
  }

//		egress_bd.apply(hdr, eg_md.bd,                          eg_md.pkt_src,
//			smac_index);

//		if (!EGRESS_BYPASS(REWRITE) && eg_md.flags.routed) {
//			smac_rewrite.apply();
//		}
 }
}
# 24 "port.p4" 2

//-----------------------------------------------------------------------------
// Ingress/Egress Port Mirroring
//-----------------------------------------------------------------------------

control PortMirror(
  in switch_port_t port,
  in switch_pkt_src_t src,
  inout switch_mirror_metadata_t mirror_md
) (
  switch_uint32_t table_size=288
) {

 action set_mirror_id(
  switch_mirror_session_t session_id,
  switch_mirror_meter_id_t meter_index // derek added
 ) {
  mirror_md.type = 1;
  mirror_md.src = src;
  mirror_md.session_id = session_id;

  mirror_md.meter_index = meter_index; // derek added

 }

 table port_mirror {
  key = {
   port : exact;
  }
  actions = {
   NoAction;
   set_mirror_id;
  }

  const default_action = NoAction;
  size = table_size;
 }

 apply {
  port_mirror.apply();
 }
}

//-----------------------------------------------------------------------------
// Ingress Port Mapping
//-----------------------------------------------------------------------------

control IngressPortMapping(
  inout switch_header_t hdr,
  inout switch_ingress_metadata_t ig_md,
  inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
  inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr
) (
  switch_uint32_t port_vlan_table_size,
  switch_uint32_t bd_table_size,
  switch_uint32_t port_table_size=288,
  switch_uint32_t vlan_table_size=4096
) {

 PortMirror(port_table_size) port_mirror;

 ActionProfile(bd_table_size) bd_action_profile;

 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

 // Helper action:

 action terminate_cpu_packet() {
  // ig_md.bypass = (bit<8>) hdr.cpu.reason_code;                                 // Done in parser
//		ig_md.port = (switch_port_t) hdr.cpu.ingress_port;                              // Done in parser
//		ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index; // Done in parser
//		ig_intr_md_for_tm.qid = (switch_qid_t) hdr.cpu.egress_queue;                    // Not done in parser, since ig_intr_md_for_tm doesn't exist there.

//		ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;                           // Done in parser
//		DEREK: This next line should be deleted, but doing so causes us not to fit!?!?  ¯\_('')_/¯
    ig_intr_md_for_tm.bypass_egress = hdr.cpu.tx_bypass; // Not done in parser, since ig_intr_md_for_tm doesn't exist there.

//		hdr.outer.ethernet.ether_type = hdr.cpu.ether_type;                             // Wants to be done in parser (see bf-case 10933)
 }

 // --------------------------

 action set_cpu_port_properties(
  switch_port_lag_index_t port_lag_index,
//		switch_port_lag_label_t port_lag_label,
  switch_yid_t exclusion_id,
//		switch_qos_trust_mode_t trust_mode,
//		switch_qos_group_t qos_group,
//		switch_pkt_color_t color,
//		switch_tc_t tc
  bool l2_fwd_en
 ) {

  ig_md.port_lag_index = port_lag_index;
//		ig_md.port_lag_label = port_lag_label;
//		ig_md.qos.trust_mode = trust_mode;
//		ig_md.qos.group = qos_group;
//		ig_md.qos.color = color;
//		ig_md.qos.tc = tc;
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
  ig_md.nsh_md.l2_fwd_en = l2_fwd_en;

  terminate_cpu_packet();

 }

 // --------------------------

 action set_port_properties(
  // note: for regular ports, port_lag_index and l2_fwd_en come from the port_metadata table.
  switch_yid_t exclusion_id
//		bool l2_fwd_en
 ) {
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
//		ig_md.nsh_md.l2_fwd_en = l2_fwd_en;
 }

 // --------------------------

 table port_mapping {
  key = {
   ig_md.port : exact;

   hdr.cpu.isValid() : exact;
//			hdr.cpu.ingress_port : exact; // DEREK: IS THIS NEEDED / WHAT IS IT FOR?

  }

  actions = {
   set_port_properties;
   set_cpu_port_properties;
  }

  size = port_table_size * 2;
 }

 // ----------------------------------------------
 // Table: BD Mapping
 // ----------------------------------------------

 action port_vlan_miss() {
  //ig_md.flags.port_vlan_miss = true;
 }

 action set_bd_properties(
  switch_bd_t bd ,
  switch_rid_t rid
 ) {
  ig_md.bd = bd;

  ig_intr_md_for_tm.rid = rid;

 }

 // (port, vlan) --> bd mapping -- Following set of entres are needed:
 //   (port, 0, *)    L3 interface.
 //   (port, 1, vlan) L3 sub-interface.
 //   (port, 0, *)    Access port + untagged packet.
 //   (port, 1, vlan) Access port + packets tagged with access-vlan.
 //   (port, 1, 0)    Access port + .1p tagged packets.
 //   (port, 1, vlan) L2 sub-port.
 //   (port, 0, *)    Trunk port if native-vlan is not tagged.

 table port_vlan_to_bd_mapping {
  key = {
   ig_md.port_lag_index : exact;
//			hdr.transport.vlan_tag[0].isValid() : ternary;
//			hdr.transport.vlan_tag[0].vid : ternary;
   hdr.outer.vlan_tag[0].isValid() : ternary;
   hdr.outer.vlan_tag[0].vid : ternary;
  }

  actions = {
   NoAction;
   port_vlan_miss;
   set_bd_properties;
  }

  const default_action = NoAction;
  implementation = bd_action_profile;
  size = port_vlan_table_size;
 }

 // (*, vlan) --> bd mapping
 table vlan_to_bd_mapping {
  key = {
//			hdr.transport.vlan_tag[0].vid : exact;
   hdr.outer.vlan_tag[0].vid : exact;
  }

  actions = {
   NoAction;
   port_vlan_miss;
   set_bd_properties;
  }

  const default_action = port_vlan_miss;
  implementation = bd_action_profile;
  size = vlan_table_size;
 }

 table cpu_to_bd_mapping {
  key = { ig_md.bd : exact; }

  actions = {
   NoAction;
   port_vlan_miss;
   set_bd_properties;
  }

  const default_action = port_vlan_miss;
  implementation = bd_action_profile;
  size = bd_table_size;
 }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {
/*
		switch (port_mapping.apply().action_run) {
#ifdef CPU_BD_MAP_ENABLE
			set_cpu_port_properties : {
				cpu_to_bd_mapping.apply();
			}
#endif

			set_port_properties : {



					if (!port_vlan_to_bd_mapping.apply().hit) {
						if (hdr.transport.vlan_tag[0].isValid())
							vlan_to_bd_mapping.apply();
					}



			}
		}
*/
  if(port_mapping.apply().hit) {
   if(hdr.cpu.isValid()) {

    cpu_to_bd_mapping.apply();

   } else {
    if (!port_vlan_to_bd_mapping.apply().hit) {
     if (hdr.transport.vlan_tag[0].isValid()) {
      vlan_to_bd_mapping.apply();
     }
    }
   }
  }


  port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror);
//		port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror, ig_md.copp_enable, ig_md.copp_meter_id);

 }
}

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
// ----------------------------------------------------------------------------

control LAG(
 inout switch_ingress_metadata_t ig_md,
 in bit<(32/2)> hash,
 out switch_port_t egress_port
) {
 bit<16> lag_hash;

 Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;



 ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
 ActionSelector(lag_action_profile,
                selector_hash,
//	               SelectorMode_t.FAIR,
                SelectorMode_t.RESILIENT,
                LAG_MAX_MEMBERS_PER_GROUP,
                LAG_GROUP_TABLE_SIZE) lag_selector;

 // ----------------------------------------------
 // Table: LAG
 // ----------------------------------------------

 DirectCounter<bit<32> >(type=CounterType_t.PACKETS_AND_BYTES) stats_in; // direct counter
 Counter <bit<32>, switch_port_t>(512, CounterType_t.PACKETS_AND_BYTES) stats_out; // indirect counter

 action set_lag_port(switch_port_t port) {
  stats_in.count();

  egress_port = port;
 }







 action lag_miss() {
  stats_in.count();

 }

 table lag {
  key = {



   ig_md.egress_port_lag_index : exact @name("port_lag_index");



   hash : selector;



  }

  actions = {
   lag_miss;
   set_lag_port;



  }

  const default_action = lag_miss;
  size = LAG_TABLE_SIZE;
  counters = stats_in;
  implementation = lag_selector;
 }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {
        lag_hash = selector_hash.get({ig_md.lkp_1.mac_src_addr,
                                      ig_md.lkp_1.mac_dst_addr,
                                      ig_md.lkp_1.mac_type,
                                      ig_md.lkp_1.ip_src_addr,
                                      ig_md.lkp_1.ip_dst_addr,
                                      ig_md.lkp_1.ip_proto,
                                      ig_md.lkp_1.l4_dst_port,
                                      ig_md.lkp_1.l4_src_port});
  lag.apply();

//		stats_out.count(port);
 }
}

//-----------------------------------------------------------------------------
// Egress Port Mapping
//-----------------------------------------------------------------------------

control EgressPortMapping(
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in switch_port_t port
) (
 switch_uint32_t table_size=288
) {

 PortMirror(table_size) port_mirror;


 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

 action cpu_rewrite() {
  // ----- add fabric header -----







  // ----- add cpu header -----
  hdr.cpu.setValid();
  hdr.cpu.egress_queue = 0;
  hdr.cpu.tx_bypass = 0;
  hdr.cpu.capture_ts = 0;
  hdr.cpu.reserved = 0;
  // Both these line are here instead of parser out due to compiler... "error: Field is
  // extracted in the parser into multiple containers, but the container
  // slices after the first aren't byte aligned"
  hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
  hdr.cpu.port_lag_index = (bit<16>) eg_md.port_lag_index;
  hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
  hdr.cpu.reason_code = (bit<16>) eg_md.cpu_reason;
  hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;



  hdr.outer.ethernet.ether_type = 0x9001;

 }

 action port_normal(
  switch_port_lag_index_t port_lag_index
 ) {
  eg_md.port_lag_index = port_lag_index;
 }

 action port_cpu(
  switch_port_lag_index_t port_lag_index,
  switch_meter_index_t meter_index
 ) {

  cpu_rewrite();




 }

 table port_mapping {
  key = {
   port : exact;
  }

  actions = {
   port_normal;
   port_cpu;
  }

  size = table_size;
 }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {
  port_mapping.apply();


  port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror);
//		port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror, eg_md.copp_enable, eg_md.copp_meter_id);

 }
}
# 48 "npb.p4" 2
//#include "validation.p4"
# 1 "rewrite.p4" 1

/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 50 "npb.p4" 2
# 1 "tunnel.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




# 1 "scoper.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 27 "tunnel.p4" 2

//#if defined(IPV6_TUNNEL_ENABLE) && !defined(IPV6_ENABLE)
//#error "IPv6 tunneling cannot be enabled without enabling IPv6"
//#endif

//-----------------------------------------------------------------------------
// Ingress Tunnel RMAC: Transport
//-----------------------------------------------------------------------------

control IngressTunnelRMAC(
 inout switch_header_transport_t hdr_0,
 inout switch_lookup_fields_t lkp_0,
 inout switch_ingress_metadata_t ig_md
) (
 switch_uint32_t table_size = 128
) {

 // -------------------------------------
 // Table: RMAC
 // -------------------------------------


 action rmac_hit(
 ) {
  ig_md.flags.rmac_hit = true;
 }

 action rmac_miss(
 ) {
  ig_md.flags.rmac_hit = false;
 }

 table rmac {
  key = {



   hdr_0.ethernet.dst_addr : exact;

  }

  actions = {
   NoAction;
   rmac_hit;
   rmac_miss; // extreme added
  }

//		const default_action = NoAction;
  const default_action = rmac_miss;
  size = table_size;
 }


 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if(hdr_0.ethernet.isValid()) {
//		if(ig_md.nsh_md.l2_fwd_en == true) {
   // network tapped
   rmac.apply();
  } else {
   // optically tapped
   ig_md.flags.rmac_hit = true;
  }



 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Transport (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnel(
 inout switch_ingress_metadata_t ig_md,
 inout switch_header_transport_t hdr_0,
 inout switch_lookup_fields_t lkp_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr // extreme added
) (
 switch_uint32_t ipv4_src_vtep_table_size=1024,
 switch_uint32_t ipv6_src_vtep_table_size=1024,
 switch_uint32_t ipv4_dst_vtep_table_size=1024,
 switch_uint32_t ipv6_dst_vtep_table_size=1024
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_src_vtep;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_dst_vtep;





 // -------------------------------------
 // Table: IPv4 Src VTEP
 // -------------------------------------

 // Derek note: These tables are unused in latest switch.p4 code from barefoot

 action src_vtep_hit(
  switch_port_lag_index_t port_lag_index,
  bit<16> sap,
  bit<12> vpn
 ) {
  stats_src_vtep.count();

  ig_md.port_lag_index = port_lag_index;
  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
 }

 // -------------------------------------

 action src_vtep_miss(
 ) {
  stats_src_vtep.count();
 }

 // -------------------------------------

 table src_vtep {
  key = {




   hdr_0.ipv4.src_addr : ternary @name("src_addr");


//			tunnel_0.type           : exact @name("tunnel_type");
   lkp_0.tunnel_type : exact @name("tunnel_type");
  }

  actions = {
   src_vtep_miss;
   src_vtep_hit;
  }

  const default_action = src_vtep_miss;
  counters = stats_src_vtep;
  size = ipv4_src_vtep_table_size;
 }

 // -------------------------------------
 // Table: IPv6 Src VTEP
 // -------------------------------------
# 223 "tunnel.p4"
 // -------------------------------------
 // Table: IPv4 Dst VTEP
 // -------------------------------------

 bool drop_ = false;

 action dst_vtep_hit(
//		switch_bd_t bd,

  bool drop


  ,
  switch_port_lag_index_t port_lag_index,
  bit<16> sap,
  bit<12> vpn

 ) {
  stats_dst_vtep.count();

//		ig_md.bd = bd;

//		ig_intr_md_for_dprsr.drop_ctl = drop;
  drop_ = drop;


  ig_md.port_lag_index = port_lag_index;
  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;

 }

 // -------------------------------------

//	action dst_vtep_tunid_hit(
//	) {
//		stats_dst_vtep.count();
//	}

 // -------------------------------------

 action NoAction_(
 ) {
  stats_dst_vtep.count();
 }

 // -------------------------------------

 table dst_vtep {
  key = {





   hdr_0.ipv4.src_addr : ternary @name("src_addr");





   hdr_0.ipv4.dst_addr : ternary @name("dst_addr");


//			tunnel_0.type           : exact @name("tunnel_type");
   lkp_0.tunnel_type : exact @name("tunnel_type");
  }

  actions = {
   NoAction_;
   dst_vtep_hit;
//			dst_vtep_tunid_hit;
  }

  const default_action = NoAction_;
  counters = stats_dst_vtep;
  size = ipv4_dst_vtep_table_size;
 }

 // -------------------------------------
 // Table: IPv6 Dst VTEP
 // -------------------------------------
# 381 "tunnel.p4"
 // -------------------------------------
 // Table: VNI to BD
 // -------------------------------------
/*
    // Tunnel id -> BD Translation
    table vni_to_bd_mapping {
        key = {
			lkp_0.tunnel_id : exact;
		}

        actions = {
            NoAction;
            dst_vtep_hit;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }

	// -------------------------------------
	// -------------------------------------

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
    // Tunnel id -> BD Translation
    table vni_to_bd_mappingv6 {
        key = {
			lkp_0.tunnel_id : exact;
		}

        actions = {
            NoAction;
            dst_vtepv6_hit;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }
#endif
*/
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  // outer RMAC lookup for tunnel termination.
//		switch(rmac.apply().action_run) {
//			rmac_hit : {

    if (hdr_0.ipv4.isValid()) {
//				if (lkp_0.ip_type == SWITCH_IP_TYPE_IPV4) {



     switch(dst_vtep.apply().action_run) {
//						dst_vtep_tunid_hit : {
//							// Vxlan
//							vni_to_bd_mapping.apply();
//						}
      dst_vtep_hit : {
      }
     }
# 460 "tunnel.p4"
    }

//			}
//		}

  // --------------------

  if(drop_ == true) {
   ig_intr_md_for_dprsr.drop_ctl = 0x1;
//			ig_intr_md_for_dprsr.drop_ctl = (bit<3>)drop_;
  }


 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Network SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelNetwork(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp_0,
 inout switch_header_transport_t hdr_0,

 inout switch_tunnel_metadata_t tunnel_0
) (
 switch_uint32_t sap_table_size=32w1024
) {

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------




 action NoAction_ (
 ) {
  stats.count();
 }

 action sap_hit (
  bit<16> sap,
  bit<12> vpn
 ) {
  stats.count();

  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
 }

 // ---------------------------------

 table sap {
  key = {
   hdr_0.nsh_type1.sap : exact @name("sap");

   // tunnel
//			tunnel_0.type          : exact @name("tunnel_type");
//			tunnel_0.id            : exact @name("tunnel_id");
   lkp_0.tunnel_type : exact @name("tunnel_type");
   lkp_0.tunnel_id : exact @name("tunnel_id");
  }

  actions = {
   NoAction_;
   sap_hit;
  }

  const default_action = NoAction_;
  counters = stats;
  size = sap_table_size;
 }




 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {


  sap.apply();


 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Outer SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelOuter(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp,
 inout switch_header_transport_t hdr_0,

 in switch_lookup_fields_t lkp_2,
 in switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2
) (
 switch_uint32_t sap_exm_table_size=32w1024,
 switch_uint32_t sap_tcam_table_size=32w1024
) {
//	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------

 bool terminate_ = false;
 bool scope_ = false;
/*
	action NoAction_exm (
	) {
		stats_exm.count();
	}

	action sap_exm_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate
	) {
		stats_exm.count();

		hdr_0.nsh_type1.sap     = (bit<16>)sap;
		hdr_0.nsh_type1.vpn     = (bit<16>)vpn;
		scope_                  = scope;
		terminate_              = terminate;
	}

	// -------------------------------------

	table sap_exm {
		key = {
			hdr_0.nsh_type1.sap : exact @name("sap");

			// l3
			lkp.ip_type         : exact @name("ip_type");
			lkp.ip_src_addr     : exact @name("ip_src_addr");
			lkp.ip_dst_addr     : exact @name("ip_dst_addr");

			// tunnel
			lkp.tunnel_type     : exact @name("tunnel_type");
			lkp.tunnel_id       : exact @name("tunnel_id");
		}

		actions = {
			NoAction_exm;
			sap_exm_hit;
		}

		const default_action = NoAction_exm;
		counters = stats_exm;
		size = sap_exm_table_size;
	}
*/
 // -------------------------------------
 // -------------------------------------

 action NoAction_tcam (
 ) {
  stats_tcam.count();
 }

 action sap_tcam_hit(
  bit<16> sap,
  bit<12> vpn,
  bool scope,
  bool terminate
 ) {
  stats_tcam.count();

  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
  scope_ = scope;
  terminate_ = terminate;
 }

 // -------------------------------------

 table sap_tcam {
  key = {
   hdr_0.nsh_type1.sap : ternary @name("sap");

   // l3
   lkp.ip_type : ternary @name("ip_type");
   lkp.ip_src_addr : ternary @name("ip_src_addr");
   lkp.ip_dst_addr : ternary @name("ip_dst_addr");

   // tunnel
   lkp.tunnel_type : ternary @name("tunnel_type");
   lkp.tunnel_id : ternary @name("tunnel_id");
  }

  actions = {
   NoAction_tcam;
   sap_tcam_hit;
  }

  const default_action = NoAction_tcam;
  counters = stats_tcam;
  size = sap_tcam_table_size;
 }

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		hdr_0.nsh_type1.scope = scope_new;
	}

	table scope_inc {
		key = {
			hdr_0.nsh_type1.scope : exact;
		}
		actions = {
			new_scope;
		}
		const entries = {
			0  : new_scope(1);
			1  : new_scope(2);
			2  : new_scope(3);
		}
	}
*/
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

//		if(!sap_exm.apply().hit) {
   sap_tcam.apply();
//		}

  if(lkp.next_lyr_valid == true) {
   if(terminate_ == true) {
    ig_md.tunnel_1.terminate = true;
    if(hdr_0.nsh_type1.scope == 1) {
     ig_md.tunnel_2.terminate = true;
    }
   }

   if(scope_ == true) {
    if(hdr_0.nsh_type1.scope == 0) {

     Scoper.apply(
      lkp_2,
//						ig_md.drop_reason_2,

      lkp
     );
# 730 "tunnel.p4"
    }

//				scope_inc.apply();
    hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
   }
  }
 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Inner SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelInner(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp,
 inout switch_header_transport_t hdr_0,

 in switch_lookup_fields_t lkp_2,
 in switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2
) (
 switch_uint32_t sap_exm_table_size=32w1024,
 switch_uint32_t sap_tcam_table_size=32w1024
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------

 bool terminate_ = false;
 bool scope_ = false;

 action NoAction_exm (
 ) {
  stats_exm.count();
 }

 action sap_exm_hit(
  bit<16> sap,
  bit<12> vpn,
  bool scope,
  bool terminate
 ) {
  stats_exm.count();

  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
  scope_ = scope;
  terminate_ = terminate;
 }

 // -------------------------------------

 table sap_exm {
  key = {
   hdr_0.nsh_type1.sap : exact @name("sap");

   // tunnel
   lkp.tunnel_type : exact @name("tunnel_type");
   lkp.tunnel_id : exact @name("tunnel_id");
  }

  actions = {
   NoAction_exm;
   sap_exm_hit;
  }

  const default_action = NoAction_exm;
  counters = stats_exm;
  size = sap_exm_table_size;
 }

 // -------------------------------------
 // -------------------------------------

 action NoAction_tcam (
 ) {
  stats_tcam.count();
 }

 action sap_tcam_hit(
  bit<16> sap,
  bit<12> vpn,
  bool scope,
  bool terminate
 ) {
  stats_tcam.count();

  hdr_0.nsh_type1.sap = (bit<16>)sap;
  hdr_0.nsh_type1.vpn = (bit<16>)vpn;
  scope_ = scope;
  terminate_ = terminate;
 }

 // -------------------------------------

 table sap_tcam {
  key = {
   hdr_0.nsh_type1.sap : ternary @name("sap");

   // tunnel
   lkp.tunnel_type : ternary @name("tunnel_type");
   lkp.tunnel_id : ternary @name("tunnel_id");
  }

  actions = {
   NoAction_tcam;
   sap_tcam_hit;
  }

  const default_action = NoAction_tcam;
  counters = stats_tcam;
  size = sap_tcam_table_size;
 }

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		hdr_0.nsh_type1.scope = scope_new;
	}

	table scope_inc {
		key = {
			hdr_0.nsh_type1.scope : exact;
		}
		actions = {
			new_scope;
		}
		const entries = {
			0  : new_scope(1);
			1  : new_scope(2);
			2  : new_scope(3);
		}
	}
*/
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if(!sap_exm.apply().hit) {
   sap_tcam.apply();
  }

  if(lkp.next_lyr_valid == true) {
   if(terminate_ == true) {
    ig_md.tunnel_1.terminate = true;
    if(hdr_0.nsh_type1.scope == 1) {
     ig_md.tunnel_2.terminate = true;
    }
   }

   if(scope_ == true) {
    if(hdr_0.nsh_type1.scope == 0) {

     Scoper.apply(
      lkp_2,
//						ig_md.drop_reason_2,

      lkp
     );
# 906 "tunnel.p4"
    }

//				scope_inc.apply();
    hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
   }
  }
 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap / Encap Transport
//-----------------------------------------------------------------------------

control TunnelDecapTransportIngress(
 inout switch_header_transport_t hdr_0,
 // ----- current header data -----
//	inout switch_header_transport_t hdr_0,
 in switch_tunnel_metadata_t tunnel_0,
 // ----- next header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- next header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
  if(tunnel_0.terminate) {
   // ----- l2 -----
//			// (none -- done in egress)
//			hdr_0.ethernet.setInvalid();
//			hdr_0.vlan_tag[0].setInvalid();

   // ----- l3 / l4 / tunnel -----
   // (none -- instead, we do this by simply not deparsing any transport l3 / 4 / tunnels)

   // ----- fix the next layer's l2, if we had an l3 tunnel -----

   if(!hdr_1.ethernet.isValid()) {
    // Pkt doesn't have an l2 header...add one.
    // TODO: Do we need to set da/sa?  If so, what to (perhaps copy it from the transport)?
//				hdr_1.ethernet.dst_addr = hdr_0.ethernet.dst_addr;
//				hdr_1.ethernet.src_addr = hdr_0.ethernet.src_addr;
    if(hdr_1.ipv4.isValid()) {
     hdr_1.ethernet.ether_type = 0x0800;
    } else {
     hdr_1.ethernet.ether_type = 0x86dd;
    }
   }
   hdr_1.ethernet.setValid(); // always set valid (it may already be valid)


/*
			if(tunnel_1.terminate && tunnel_2.terminate) {

				// get from inner-inner
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_3.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_3.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			} else if(tunnel_1.terminate) {

				// get from inner
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_2.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_2.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			} else {

				// get from outer
				if(hdr_0.vlan_tag[0].isValid()) {
					if(hdr_1.ipv4.isValid()) {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
					}
				} else {
					if(hdr_1.ipv4.isValid()) {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV4;
					} else {
						hdr_0.ethernet.ether_type = ETHERTYPE_IPV6;
					}
				}

			}
*/

  }
 }
}

//-----------------------------------------------------------------------------

control TunnelEncapTransportIngress(
 inout switch_header_transport_t hdr_0,
 // ----- current header data -----
//  inout switch_header_transport_t hdr_0,
 in switch_tunnel_metadata_t tunnel_0,
 // ----- next header data -----
 inout switch_header_outer_t hdr_1
) (
 switch_tunnel_mode_t mode
) {

 apply {
/*
		if(tunnel_0.encap) {
			// ----- l2 -----
			// add an ethernet header, for egress parser -- only need to set the etype (not the da/sa)....
			hdr_0.ethernet.setValid();
			hdr_0.ethernet.ether_type = ETHERTYPE_NSH;

			// ----- l3 / l4 / tunnel -----
			// (none -- done in egress)
		}
*/
 }

}

//-----------------------------------------------------------------------------
// Tunnel Decap Outer
//-----------------------------------------------------------------------------

control TunnelDecapOuter(
 // ----- current header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- next header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {


  if(tunnel_1.terminate) {
   // ----- l2 -----

   // only remove l2 when the next layer's is valid
   if(hdr_2.ethernet.isValid() || (tunnel_2.terminate && hdr_3.ethernet.isValid())) {
    hdr_1.ethernet.setInvalid();


    hdr_1.e_tag.setInvalid();


    hdr_1.vn_tag.setInvalid();


    hdr_1.vlan_tag[0].setInvalid(); // extreme added
    hdr_1.vlan_tag[1].setInvalid(); // extreme added
   }

   // ----- l3 -----
   hdr_1.ipv4.setInvalid();

   hdr_1.ipv6.setInvalid();


   // ----- l4 -----
   hdr_1.tcp.setInvalid();
   hdr_1.udp.setInvalid();
   hdr_1.sctp.setInvalid(); // extreme added

   // ----- tunnel -----

   hdr_1.vxlan.setInvalid();

   hdr_1.gre.setInvalid();
   hdr_1.gre_optional.setInvalid();

   hdr_1.nvgre.setInvalid();


   hdr_1.gtp_v1_base.setInvalid(); // extreme added
   hdr_1.gtp_v1_optional.setInvalid(); // extreme added


   // ----- fix outer ethertype, if we had an l3 tunnel -----


   // this is organized from highest priority to lowest priority
   if(tunnel_2.terminate) {

    // get from inner-inner
    if(hdr_1.vlan_tag[1].isValid()) {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.vlan_tag[1].ether_type = 0x0800;
     } else {
      hdr_1.vlan_tag[1].ether_type = 0x86dd;
     }
    } else if(hdr_1.vlan_tag[0].isValid()) {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.vlan_tag[0].ether_type = 0x0800;
     } else {
      hdr_1.vlan_tag[0].ether_type = 0x86dd;
     }

    } else if(hdr_1.vn_tag.isValid()) {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.vn_tag.ether_type = 0x0800;
     } else {
      hdr_1.vn_tag.ether_type = 0x86dd;
     }


    } else if(hdr_1.e_tag.isValid()) {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.e_tag.ether_type = 0x0800;
     } else {
      hdr_1.e_tag.ether_type = 0x86dd;
     }

    } else {
     if(hdr_3.ipv4.isValid()) {
      hdr_1.ethernet.ether_type = 0x0800;
     } else {
      hdr_1.ethernet.ether_type = 0x86dd;
     }
    }

   } else {

    // get from inner
    if(hdr_1.vlan_tag[1].isValid()) {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.vlan_tag[1].ether_type = 0x0800;
     } else {
      hdr_1.vlan_tag[1].ether_type = 0x86dd;
     }
    } else if(hdr_1.vlan_tag[0].isValid()) {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.vlan_tag[0].ether_type = 0x0800;
     } else {
      hdr_1.vlan_tag[0].ether_type = 0x86dd;
     }

    } else if(hdr_1.vn_tag.isValid()) {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.vn_tag.ether_type = 0x0800;
     } else {
      hdr_1.vn_tag.ether_type = 0x86dd;
     }


    } else if(hdr_1.e_tag.isValid()) {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.e_tag.ether_type = 0x0800;
     } else {
      hdr_1.e_tag.ether_type = 0x86dd;
     }

    } else {
     if(hdr_2.ipv4.isValid()) {
      hdr_1.ethernet.ether_type = 0x0800;
     } else {
      hdr_1.ethernet.ether_type = 0x86dd;
     }
    }

   }

  }

 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Inner
//-----------------------------------------------------------------------------

control TunnelDecapInner(
 // ----- previous header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- current header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if(tunnel_2.terminate) {
   // ----- l2 -----

   // only remove l2 when the next layer's is valid
   if(hdr_3.ethernet.isValid()) {
    hdr_2.ethernet.setInvalid();
    hdr_2.vlan_tag[0].setInvalid(); // extreme added
   }

   // ----- l3 -----
   hdr_2.ipv4.setInvalid();

   hdr_2.ipv6.setInvalid();


   // ----- l4 -----
   hdr_2.tcp.setInvalid();
   hdr_2.udp.setInvalid();
   hdr_2.sctp.setInvalid(); // extreme added

   // ----- tunnel -----

   hdr_2.gre.setInvalid();
   hdr_2.gre_optional.setInvalid();


   hdr_2.gtp_v1_base.setInvalid(); // extreme added
   hdr_2.gtp_v1_optional.setInvalid(); // extreme added


   // ----- fix outer ethertype, if we had an l3 tunnel -----

   // this is organized from highest priority to lowest priority
   if(hdr_2.vlan_tag[0].isValid()) {
    if(hdr_3.ipv4.isValid()) {
     hdr_2.vlan_tag[0].ether_type = 0x0800;
    } else {
     hdr_2.vlan_tag[0].ether_type = 0x86dd;
    }
   } else {
    if(hdr_3.ipv4.isValid()) {
     hdr_2.ethernet.ether_type = 0x0800;
    } else {
     hdr_2.ethernet.ether_type = 0x86dd;
    }
   }
/*
  #if defined(FIX_L3_TUN_LYR_BY_LYR) && !defined(FIX_L3_TUN_ALL_AT_ONCE)
			// this is organized from highest priority to lowest priority
			if(hdr_1.vlan_tag[1].isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV6;
				}
			} else if(hdr_1.vlan_tag[0].isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
				}
    #ifdef VNTAG_ENABLE
			} else if(hdr_1.vn_tag.isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.vn_tag.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.vn_tag.ether_type = ETHERTYPE_IPV6;
				}
    #endif
    #ifdef ETAG_ENABLE
			} else if(hdr_1.e_tag.isValid()) {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.e_tag.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.e_tag.ether_type = ETHERTYPE_IPV6;
				}
    #endif
			} else {
				if(hdr_3.ipv4.isValid()) {
					hdr_1.ethernet.ether_type = ETHERTYPE_IPV4;
				} else {
					hdr_1.ethernet.ether_type = ETHERTYPE_IPV6;
				}
			}
	#endif
*/
  }

 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - L2 Ethertype Fix
//-----------------------------------------------------------------------------

control TunnelDecapFixEthertype(
 // ----- current header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- next header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
) {
 // -------------------------------------
 // Table
 // -------------------------------------

 action fix_l2_decap_hdr_1() {
  hdr_1.ethernet.setInvalid();


  hdr_1.e_tag.setInvalid();


  hdr_1.vn_tag.setInvalid();


  hdr_1.vlan_tag[0].setInvalid(); // extreme added
  hdr_1.vlan_tag[1].setInvalid(); // extreme added
 }

 action fix_l2_decap_hdr_2() {
  hdr_2.ethernet.setInvalid();
  hdr_2.vlan_tag[0].setInvalid(); // extreme added
 }
# 1492 "tunnel.p4"
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply{



 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - Scope Decrement
//-----------------------------------------------------------------------------

control TunnelDecapScopeDecrement (
 inout bool terminate_a,
 inout bool terminate_b,
 inout switch_header_transport_t hdr_0
) {

 action new_scope(bit<8> scope_new) {
  hdr_0.nsh_type1.scope = scope_new;
//		terminate_a = false;
//		terminate_b = false;
 }

 table scope_dec {
  key = {
   hdr_0.nsh_type1.scope : exact;
   terminate_a : exact;
   terminate_b : exact;
  }
  actions = {
   NoAction;
   new_scope;
  }
  const entries = {
   // no decrement
   (0, false, false) : new_scope(0);
   (1, false, false) : new_scope(1);
   (2, false, false) : new_scope(2);
   (3, false, false) : new_scope(3);
   // decrement by one
   (0, true, false) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
   (1, true, false) : new_scope(0);
   (2, true, false) : new_scope(1);
   (3, true, false) : new_scope(2);
   // decrement by one (these should never occur)
   (0, false, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
   (1, false, true ) : new_scope(0);
   (2, false, true ) : new_scope(1);
   (3, false, true ) : new_scope(2);
   // decrement by two
   (0, true, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
   (1, true, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0!
   (2, true, true ) : new_scope(0);
   (3, true, true ) : new_scope(1);
  }
  const default_action = NoAction;
 }

 // -------------------------

 apply {
  scope_dec.apply();
 }
}

//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

control TunnelRewrite(
 inout switch_header_transport_t hdr_0,
 inout switch_egress_metadata_t eg_md,
 in switch_tunnel_metadata_t tunnel
) (
 switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024,
 switch_uint32_t ipv6_dst_addr_rewrite_table_size=1024,
 switch_uint32_t nexthop_rewrite_table_size=512,
 switch_uint32_t src_addr_rewrite_table_size=1024,
 switch_uint32_t smac_rewrite_table_size=1024
) {

 EgressBd(BD_TABLE_SIZE) egress_bd;
 switch_smac_index_t smac_index;

 // -------------------------------------
 // Table: Nexthop Rewrite (DMAC & BD)
 // -------------------------------------

 // Outer nexthop rewrite
 action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
  eg_md.bd = bd;
  hdr_0.ethernet.dst_addr = dmac;
 }

 table nexthop_rewrite {
  key = {
   eg_md.outer_nexthop : exact;
  }

  actions = {
   NoAction;
   rewrite_tunnel;
  }

  const default_action = NoAction;
  size = nexthop_rewrite_table_size;
 }

 // -------------------------------------
 // Table: SIP Rewrite
 // -------------------------------------

 // Tunnel source IP rewrite
 action rewrite_ipv4_src(ipv4_addr_t src_addr) {

  hdr_0.ipv4.src_addr = src_addr;

 }

 action rewrite_ipv6_src(ipv6_addr_t src_addr) {



 }

 table src_addr_rewrite {
  key = { eg_md.bd : exact; }
  actions = {
   rewrite_ipv4_src;
   rewrite_ipv6_src;
  }

  size = src_addr_rewrite_table_size;
 }

 // -------------------------------------
 // Table: DIP Rewrite
 // -------------------------------------

 // Tunnel destination IP rewrite

 action rewrite_ipv4_dst(ipv4_addr_t dst_addr) {
  hdr_0.ipv4.dst_addr = dst_addr;
 }
# 1649 "tunnel.p4"
 table ipv4_dst_addr_rewrite {
  key = { tunnel.index : exact; }
  actions = { rewrite_ipv4_dst; }
//		const default_action = rewrite_ipv4_dst(0); // extreme modified!
  size = ipv4_dst_addr_rewrite_table_size;
 }
# 1666 "tunnel.p4"
 // -------------------------------------
 // Table: SMAC Rewrite
 // -------------------------------------

 // Tunnel source MAC rewrite
 action rewrite_smac(mac_addr_t smac) {
  hdr_0.ethernet.src_addr = smac;
 }

 table smac_rewrite {
  key = { smac_index : exact; }
  actions = {
   NoAction;
   rewrite_smac;
  }

  const default_action = NoAction;
  size = smac_rewrite_table_size;
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
   nexthop_rewrite.apply();

  if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
   egress_bd.apply(hdr_0, eg_md.bd, eg_md.pkt_src,
    smac_index);


  if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
   src_addr_rewrite.apply();

  if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {

   if (hdr_0.ipv4.isValid()) {
    ipv4_dst_addr_rewrite.apply();
    }
# 1717 "tunnel.p4"
  }


  smac_rewrite.apply();

 }
}

//-----------------------------------------------------------------------------
// Tunnel encapsulation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param mode :  Specify the model for tunnel encapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying into the outer header on encapsulation. This results in 'normal'
// behaviour for ECN field (See RFC 6040 secion 4.1). In the PIPE model, outer header ttl and dscp
// fields are independent of that in the inner header and are set to user-defined values on
// encapsulation.
// @param vni_mapping_table_size : Number of VNIs.
//
//-----------------------------------------------------------------------------

control TunnelEncap(
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 inout switch_tunnel_metadata_t tunnel_
) (
 switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
 switch_uint32_t vni_mapping_table_size=1024
) {

 bit<16> payload_len;
 bit<8> ip_proto;

 // -------------------------------------
/*
	action set_vni(switch_tunnel_id_t id) {
		tunnel_.id = id;
	}

	table bd_to_vni_mapping {
		key = { eg_md.bd : exact; }

		actions = {
			NoAction;
			set_vni;
		}

		size = vni_mapping_table_size;
	}
*/
 //=============================================================================
 // Copy L3/4 Outer -> Inner
 //=============================================================================

 action copy_ipv4_header() {

  // Copy all of the IPv4 header fields.
  hdr_0.ipv4.setInvalid(); // is this supposed to be transport hdr_0?

 }

 action copy_ipv6_header() {



 }

 // --------------------------------
 // --------------------------------

 action rewrite_inner_ipv4_udp() {
  payload_len = hdr_1.ipv4.total_len;
  copy_ipv4_header();
  ip_proto = 4;
 }

 action rewrite_inner_ipv4_unknown() {
  payload_len = hdr_1.ipv4.total_len;
  copy_ipv4_header();
  ip_proto = 4;
 }

 // --------------------------------
# 1815 "tunnel.p4"
 // --------------------------------

 table encap_outer {
  key = {
   hdr_1.ipv4.isValid() : exact;



   hdr_1.udp.isValid() : exact;
   // hdr_1.tcp.isValid() : exact;
  }

  actions = {
   rewrite_inner_ipv4_udp;
   rewrite_inner_ipv4_unknown;




  }

  const entries = {






   (true, false) : rewrite_inner_ipv4_unknown();
   (true, true ) : rewrite_inner_ipv4_udp();


  }
 }

 //=============================================================================
 // Copy L2 Outer -> Inner
 // Writes Tunnel header, rewrites some of Outer
 //=============================================================================

 //-----------------------------------------------------------------------------
 // Helper actions to add various headers.
 //-----------------------------------------------------------------------------

 // there is no UDP supported in the transport
 // action add_udp_header(bit<16> src_port, bit<16> dst_port) {
 //     hdr_0.udp.setValid();
 //     hdr_0.udp.src_port = src_port;
 //     hdr_0.udp.dst_port = dst_port;
 //     hdr_0.udp.checksum = 0;
 //     // hdr_0.udp.length = 0;
 // }

 // -------------------------------------
 // Extreme Networks - Modified
 // -------------------------------------

 action add_gre_header(bit<16> proto, bit<1> K, bit<1> S) {

  hdr_0.gre.setValid();
  hdr_0.gre.proto = proto;
  hdr_0.gre.C = 0;
  hdr_0.gre.R = 0;
  hdr_0.gre.K = K;
  hdr_0.gre.S = S;
  hdr_0.gre.s = 0;
  hdr_0.gre.recurse = 0;
  hdr_0.gre.flags = 0;
  hdr_0.gre.version = 0;

 }

 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

 action add_gre_header_seq() {




 }

 action add_l2_header(bit<16> ethertype) {
  hdr_0.ethernet.setValid();
  hdr_0.ethernet.ether_type = ethertype;
 }

 // -------------------------------------

 action add_erspan_header_type2(switch_mirror_session_t session_id) {
# 1915 "tunnel.p4"
 }

 // action add_erspan_header(bit<32> timestamp, switch_mirror_session_t session_id) {
 // 	hdr_0.erspan_type3.setValid();
 // 	hdr_0.erspan_type3.timestamp = timestamp;
 // 	hdr_0.erspan_type3.session_id = (bit<10>) session_id;
 // 	hdr_0.erspan_type3.version = 4w0x2;
 // 	hdr_0.erspan_type3.sgt = 0;
 // 	hdr_0.erspan_type3.vlan = 0;
 // }

 // -------------------------------------

 action add_ipv4_header(bit<8> proto, bit<3> flags) {

  hdr_0.ipv4.setValid();
  hdr_0.ipv4.version = 4w4;
  hdr_0.ipv4.ihl = 4w5;
  // hdr_0.ipv4.total_len = 0;
  hdr_0.ipv4.identification = 0;
  hdr_0.ipv4.flags = flags; // derek: was 0 originally, but request came in to set 'don't frag' bit
  hdr_0.ipv4.frag_offset = 0;
  hdr_0.ipv4.protocol = proto;
  // hdr_0.ipv4.src_addr = 0;
  // hdr_0.ipv4.dst_addr = 0;

  if (mode == switch_tunnel_mode_t.UNIFORM) {
   // NoAction.
  } else if (mode == switch_tunnel_mode_t.PIPE) {
   hdr_0.ipv4.ttl = 8w64;
   hdr_0.ipv4.tos = 0;
  }

 }

 action add_ipv6_header(bit<8> proto) {
# 1967 "tunnel.p4"
 }

 //-----------------------------------------------------------------------------
 // Actual actions.
 //-----------------------------------------------------------------------------

 // =====================================
 // ----- Rewrite, IPv4 Stuff -----
 // =====================================

 action rewrite_ipv4_gre() {

  // ----- l3 -----
  add_ipv4_header(47, 2);
  // Total length = packet length + 24
  //   IPv4 (20) + GRE (4)
  hdr_0.ipv4.total_len = payload_len + 16w24;

  // ----- tunnel -----
  add_gre_header(0x0800, 0, 0);

  // ----- l2 -----
  add_l2_header(0x0800);

  hdr_1.ethernet.setInvalid();
  hdr_1.vlan_tag[0].setInvalid();
  hdr_1.vlan_tag[1].setInvalid();

 }

 action rewrite_ipv4_erspan(switch_mirror_session_t session_id) {
# 2013 "tunnel.p4"
 }

 // =====================================
 // ----- Rewrite, IPv6 Stuff -----
 // =====================================

 action rewrite_ipv6_gre() {
# 2038 "tunnel.p4"
 }
/*
	action rewrite_ipv6_erspan(switch_mirror_session_t session_id) {
		// ----- l3 -----
//		hdr_0.inner_ethernet = hdr_0.ethernet;
		add_ipv6_header(IP_PROTOCOLS_GRE);
		// Payload length = packet length + 8
		//   GRE (4)
		hdr_0.ipv6.payload_len = payload_len + 16w30; // 8 GRE + 8 ERSPAN + 14 ETHERNET

		// ----- tunnel -----
		add_gre_header(GRE_PROTOCOLS_ERSPAN_TYPE_2, 0, 1);
		add_gre_header_seq();
		add_erspan_header_type2(session_id);

		// ----- l2 -----
		add_l2_header(ETHERTYPE_IPV6);
	}
*/
 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

 action rewrite_mac_in_mac_nsh_type1(
  bit<24> tool_address
 ) {
  add_l2_header(0x894F);

  // This is a hack to support the old nsh type 1 header
  // for slx.  It really should be done in a nsh table,
  // as putting it here in the encap logic violates the
  // whole "separation of concerns" principle.  However,
  // time is tight on this program and the goal is to
  // minimize changes, so I'm putting it here....
  hdr_0.nsh_type1.spi = tool_address;
  hdr_0.nsh_type1.si = 0x1;



 }

 // -------------------------------------

 action rewrite_mac_in_mac() {
  add_l2_header(0x894F);
 }

 // -------------------------------------

 table tunnel {
  key = {
   tunnel_.type : exact;
  }

  actions = {
   NoAction;

   rewrite_mac_in_mac_nsh_type1; // extreme added
   rewrite_mac_in_mac; // extreme added
   rewrite_ipv4_gre; // extreme added
   rewrite_ipv6_gre; // extreme added
   rewrite_ipv4_erspan; // extreme added
//			rewrite_ipv6_erspan;          // extreme added
  }

  const default_action = NoAction;
 }

 //=============================================================================
 // Apply
 //=============================================================================

 apply {

  if (tunnel_.type != SWITCH_TUNNEL_TYPE_NONE && tunnel_.id == 0) {
//			bd_to_vni_mapping.apply(); // Derek: since tunnel.id is only used by vxlan, getting rid of this table (for now, anyway).
  }

  if (tunnel_.type != SWITCH_TUNNEL_TYPE_NONE) {
   // Copy L3/L4 header into inner headers.
   encap_outer.apply();

   // Add outer L3/L4/Tunnel headers.
   tunnel.apply();
  }

 }
}
# 51 "npb.p4" 2
# 1 "multicast.p4" 1



// =============================================================================
// =============================================================================
// =============================================================================

control MulticastReplication (
 inout switch_header_transport_t hdr_0,
 in switch_rid_t replication_id,
 in switch_port_t port,
 inout switch_egress_metadata_t eg_md
) (
 switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table #1: 
 // =========================================================================


 action rid_hit_unique_copies(
  switch_bd_t bd,

  bit<24> spi,
  bit<8> si,

  switch_nexthop_t nexthop_index,
  switch_tunnel_index_t tunnel_index,
  switch_outer_nexthop_t outer_nexthop_index
 ) {
  eg_md.bd = bd;

  hdr_0.nsh_type1.spi = spi;
  hdr_0.nsh_type1.si = si;

  eg_md.nexthop = nexthop_index;
  eg_md.tunnel_0.index = tunnel_index;
  eg_md.outer_nexthop = outer_nexthop_index;
 }

 action rid_hit_identical_copies(
  switch_bd_t bd
 ) {
  eg_md.bd = bd;
 }

 action rid_miss() {
 }

 table rid {
  key = {
   replication_id : exact;
  }
  actions = {
   rid_miss;
   rid_hit_identical_copies;
   rid_hit_unique_copies;
  }

  size = table_size;
  const default_action = rid_miss;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Replication ID Lookup
  // =====================================


  if(replication_id != 0) {
   rid.apply();
  }

 }
}
# 52 "npb.p4" 2
# 1 "meter.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




# 1 "acl.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 27 "meter.p4" 2
/*
//-------------------------------------------------------------------------------------------------
// Storm Control
//
// Monitors incoming traffic and prevents the excessive traffic on a particular interface by
// dropping the traffic. Each port has a single storm control levels for all types of traffic
// (broadcast, multicast, and unicast).
//
// @param ig_md : Ingress metadata fields
// @param pkt_type : One of Unicast, Multicast, or Broadcast packet types.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the storm control table [per pipe]
// @param meter_size : Size of storm control meters [global pool]
// Stats table size must be 512 per pipe - each port with 6 stat entries [2 colors per pkt-type]
//-------------------------------------------------------------------------------------------------
control StormControl(inout switch_ingress_metadata_t ig_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=256,
                     switch_uint32_t meter_size=1024) {
    DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(meter_size, MeterType_t.PACKETS) meter;

    action count() {
        storm_control_stats.count();
        flag = false;
    }

    action drop_and_count() {
        storm_control_stats.count();
        flag = true;
    }

    table stats {
        key = {
            ig_md.qos.storm_control_color: exact;
            pkt_type : ternary;
            ig_md.port: exact;
            ig_md.flags.dmac_miss : ternary;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = storm_control_stats;
    }

    action set_meter(bit<16> index) {
        ig_md.qos.storm_control_color = (bit<2>) meter.execute(index);
    }

    table storm_control {
        key =  {
            ig_md.port : exact;
            pkt_type : ternary;
            ig_md.flags.dmac_miss : ternary;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
#ifdef STORM_CONTROL_ENABLE
        if (!INGRESS_BYPASS(STORM_CONTROL))
            storm_control.apply();

        if (!INGRESS_BYPASS(STORM_CONTROL))
            stats.apply();
#endif
    }
}
*/
//-------------------------------------------------------------------------------------------------
// Ingress Mirror Meter
//-------------------------------------------------------------------------------------------------
control IngressMirrorMeter(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    action mirror_and_count() {
        stats.count();
    }

    action no_mirror_and_count() {
        stats.count();
        ig_md.mirror.type = 0;
    }

    table meter_action {
        key = {
            color: exact;
            ig_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            ig_md.mirror.meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
            meter_index.apply();
            meter_action.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Egress Mirror Meter
//-------------------------------------------------------------------------------------------------
control EgressMirrorMeter(inout switch_egress_metadata_t eg_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    action mirror_and_count() {
        stats.count();
    }

    action no_mirror_and_count() {
        stats.count();
        eg_md.mirror.type = 0;
    }

    table meter_action {
        key = {
            color: exact;
            eg_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            eg_md.mirror.meter_index : exact;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
            meter_index.apply();
            meter_action.apply();
    }
}
# 53 "npb.p4" 2
# 1 "dtel.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

// Data-plane telemetry (DTel).

//-----------------------------------------------------------------------------
// Deflect on drop configuration checks if deflect on drop is enabled for a given queue/port pair.
// DOD must be only enabled for unicast traffic.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control DeflectOnDrop(
        in switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t table_size=1024) {

    action enable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w1;
    }

    action disable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w0;
    }

    table config {
        key = {
            ig_md.dtel.report_type : ternary;
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
//          ig_md.qos.qid: ternary @name("qid"); // derek hack
            ig_md.multicast.id : ternary;
            ig_md.cpu_reason : ternary; // to avoid validity issues, replaces
                                         // ig_intr_md_for_tm.copy_to_cpu
        }

        actions = {
            enable_dod;
            disable_dod;
        }

        size = table_size;
        const default_action = disable_dod;
    }

    apply {
        config.apply();
    }
}

//-----------------------------------------------------------------------------
// Mirror on drop configuration
// Checks if mirror on drop is enabled for a given drop reason.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control MirrorOnDrop(in switch_drop_reason_t drop_reason,
                     inout switch_dtel_metadata_t dtel_md,
                     inout switch_mirror_metadata_t mirror_md) {
    action mirror() {
        mirror_md.type = 3;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    action mirror_and_set_d_bit() {
        dtel_md.report_type = dtel_md.report_type | SWITCH_DTEL_REPORT_TYPE_DROP;
        mirror_md.type = 3;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    table config {
        key = {
            drop_reason : ternary;
            dtel_md.report_type : ternary;
        }

        actions = {
            NoAction;
            mirror;
            mirror_and_set_d_bit;
        }

        const default_action = NoAction;
        // const entries = {
        //    (SWITCH_DROP_REASON_UNKNOWN, _) : NoAction();
        //    (_, SWITCH_DTEL_REPORT_TYPE_DROP &&& SWITCH_DTEL_REPORT_TYPE_DROP) : mirror();
        // }
    }

    apply {
        config.apply();
    }
}


//-----------------------------------------------------------------------------
// Simple bloom filter for drop report suppression to avoid generating duplicate reports.
//
// @param hash : Hash value used to query the bloom filter.
// @param flag : A flag indicating that the report needs to be suppressed.
//-----------------------------------------------------------------------------
control DropReport(in switch_header_outer_t hdr,
                   in switch_egress_metadata_t eg_md,
                   in bit<32> hash, inout bit<2> flag) {
    // Two bit arrays of 128K bits.
    Register<bit<1>, bit<17>>(1 << 17, 0) array1;
    Register<bit<1>, bit<17>>(1 << 17, 0) array2;
    RegisterAction<bit<1>, bit<17>, bit<1>>(array1) filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<17>, bit<1>>(array2) filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    apply {
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[0:0] = filter1.execute(hash[(17 - 1):0]);
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[1:1] = filter2.execute(hash[31:(32 - 17)]);

    }
}

//-----------------------------------------------------------------------------
// Generates queue reports if hop latency (or queue depth) exceeds a configurable thresholds.
// Quota-based report suppression to avoid generating excessive amount of reports.
// @param port : Egress port
// @param qid : Queue Id.
// @param qdepth : Queue depth.
//-----------------------------------------------------------------------------
struct switch_queue_alert_threshold_t {
    bit<32> qdepth;
    bit<32> latency;
}

struct switch_queue_report_quota_t {
    bit<32> counter;
    bit<32> latency; // Qunatized latency
}

// Quota policy -- The policy maintains counters to track the number of generated reports.

// @param flag : indicating whether to generate a telemetry report or not.
control QueueReport(inout switch_egress_metadata_t eg_md,
                    in egress_intrinsic_metadata_t eg_intr_md,
                    out bit<1> qalert) {
    // Quota for a (port, queue) pair.
    bit<16> quota_;
    const bit<32> queue_table_size = 1024;
    const bit<32> queue_register_size = 2048;

    // Register to store latency/qdepth thresholds per (port, queue) pair.
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_register_size) thresholds;
    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            // Set the flag if either of qdepth or latency exceeds the threshold.
//          if (reg.latency <= eg_md.dtel.latency || reg.qdepth <= (bit<32>) eg_md.qos.qdepth) { // derek hack
            if (reg.latency <= eg_md.dtel.latency ) { // derek hack
                flag = 1;
            }
        }
    };

    action set_qmask(bit<32> quantization_mask) {
        // Quantize the latency.
        eg_md.dtel.latency = eg_md.dtel.latency & quantization_mask;
    }
    action set_qalert(bit<16> index, bit<16> quota, bit<32> quantization_mask) {
        qalert = check_thresholds.execute(index);
        quota_ = quota;
        set_qmask(quantization_mask);
    }

    table queue_alert {
        key = {
//          eg_md.qos.qid : exact @name("qid"); // derek hack
            eg_md.port : exact @name("port");
        }

        actions = {
            set_qalert;
            set_qmask;
        }

        size = queue_table_size;
    }

    // Register to store last observed quantized latency and a counter to track available quota.
    Register<switch_queue_report_quota_t, bit<16>>(queue_register_size) quotas;
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) reset_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            reg.counter = (bit<32>) quota_[15:0];
        }
    };

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }

            // Send a report if quantized latency is changed.
            if (reg.latency != eg_md.dtel.latency) {
                reg.latency = eg_md.dtel.latency;
                flag = 1;
            }
        }
    };

    // This is only used for deflected packets.
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }
        }
    };


    action reset_quota_(bit<16> index) {
        qalert = reset_quota.execute(index);
    }

    action update_quota_(bit<16> index) {
        qalert = update_quota.execute(index);
    }

    action check_latency_and_update_quota_(bit<16> index) {
        qalert = check_latency_and_update_quota.execute(index);
    }

    table check_quota {
        key = {
            eg_md.pkt_src : exact;
            qalert : exact;
//          eg_md.qos.qid : exact @name("qid"); // derek hack
            eg_md.port : exact @name("port");
        }

        actions = {
            NoAction;
            reset_quota_;
            update_quota_;
            check_latency_and_update_quota_;
        }

        const default_action = NoAction;
        size = 3 * queue_table_size;
    }

    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            queue_alert.apply();
        check_quota.apply();
    }
}


control FlowReport(in switch_egress_metadata_t eg_md, out bit<2> flag) {
    bit<16> digest;

    //TODO(msharif): Use a better hash
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;

    // Two bit arrays of 32K bits. The probability of false positive is about 1% for 4K flows.
    Register<bit<16>, bit<16>>(1 << 16, 0) array1;
    Register<bit<16>, bit<16>>(1 << 16, 0) array2;

    // Encodes 2 bit information for flow state change detection
    // rv = 0b1* : New flow.
    // rv = 0b01 : No change in digest is detected.

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array1) filter1 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array2) filter2 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    apply {
# 352 "dtel.p4"
    }
}

control IngressDtel(in switch_header_outer_t hdr,
                    in switch_lookup_fields_t lkp,
                    inout switch_ingress_metadata_t ig_md,
                    in bit<16> hash,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm) {

    DeflectOnDrop() dod;
    MirrorOnDrop() mod;

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(DTEL_SELECTOR_TABLE_SIZE) dtel_action_profile;
    ActionSelector(dtel_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   DTEL_MAX_MEMBERS_PER_GROUP,
                   DTEL_GROUP_TABLE_SIZE) session_selector;
    action set_mirror_session(switch_mirror_session_t session_id) {
        ig_md.dtel.session_id = session_id;
    }

    table mirror_session {
        key = {
            hdr.ethernet.isValid() : ternary;
            hash : selector;
        }
        actions = {
            NoAction;
            set_mirror_session;
        }

        implementation = session_selector;
    }

    apply {
# 400 "dtel.p4"
    }
}


control DtelConfig(inout switch_header_outer_t hdr,
                   inout bit<32> hdr_transport_timestamp, // derek hack
                   inout switch_egress_metadata_t eg_md,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
# 422 "dtel.p4"
            reg = reg + 1;

            rv = reg;
        }
    };

    action mirror_switch_local() {
        // Generate switch local telemetry report for flow/queue reports.
        eg_md.mirror.type = 4;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_switch_local_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_switch_local();
    }

    action mirror_switch_local_and_drop() {
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_f_bit_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_FLOW;
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_q_f_bits_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | (
            SWITCH_DTEL_REPORT_TYPE_QUEUE | SWITCH_DTEL_REPORT_TYPE_FLOW);
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_drop() {
        // Generate telemetry drop report.
        eg_md.mirror.type = 3;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_drop_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_drop();
    }

    action mirror_clone() {
        // Generate (sampled) clone on behalf of downstream IFA capable devices
        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.dtel.session_id = eg_md.dtel.clone_session_id;
    }

    action drop() {
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,




            bit<4> next_proto,

            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
# 504 "dtel.p4"
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved = 0;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
//      hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
        hdr.dtel.timestamp = (bit<32>) hdr_transport_timestamp; // derek hack

    }

    action update_and_mirror_truncate(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type) {



        update(switch_id, hw_id, next_proto, report_type);

        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update_and_set_etrap(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type,
            bit<2> etrap_status) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
# 554 "dtel.p4"
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved[14:13] = etrap_status; // etrap indication
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
//      hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
        hdr.dtel.timestamp = (bit<32>) hdr_transport_timestamp; // derek hack

    }

    action set_ipv4_dscp_all(bit<6> dscp) {
        hdr.ipv4.tos[7:2] = dscp;
    }

    action set_ipv6_dscp_all(bit<6> dscp) {

        hdr.ipv6.tos[7:2] = dscp;

    }

    action set_ipv4_dscp_2(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[2:2] = dscp_bit_value;
    }

    action set_ipv6_dscp_2(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[2:2] = dscp_bit_value;

    }

    action set_ipv4_dscp_3(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[3:3] = dscp_bit_value;
    }

    action set_ipv6_dscp_3(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[3:3] = dscp_bit_value;

    }

    action set_ipv4_dscp_4(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[4:4] = dscp_bit_value;
    }

    action set_ipv6_dscp_4(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[4:4] = dscp_bit_value;

    }

    action set_ipv4_dscp_5(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[5:5] = dscp_bit_value;
    }

    action set_ipv6_dscp_5(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[5:5] = dscp_bit_value;

    }

    action set_ipv4_dscp_6(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[6:6] = dscp_bit_value;
    }

    action set_ipv6_dscp_6(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[6:6] = dscp_bit_value;

    }

    action set_ipv4_dscp_7(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[7:7] = dscp_bit_value;
    }

    action set_ipv6_dscp_7(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[7:7] = dscp_bit_value;

    }

    /* config table is responsible for triggering the flow/queue report generation for normal
     * traffic and updating the dtel report headers for telemetry reports.
     *
     * pkt_src        report_type     drop_ flow_ queue drop_  drop_ action
     *                                flag  flag  _flag reason report
     *                                                         valid
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_INGRESS DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_INGRESS DROP            0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP            *     *     *     *      y     update(d)
     *
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dqf)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     1     *      *     update(dqf)
     * DEFLECTED      DROP | FLOW     *     *     1     *      *     update(dqf)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(df)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     *     *      *     drop
     * DEFLECTED      DROP | FLOW     *     *     *     *      *     update(df)
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dq)
     * DEFLECTED      DROP            0b11  *     1     *      *     update(dq)
     * DEFLECTED      DROP            *     *     1     *      *     update(dq)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(d)
     * DEFLECTED      DROP            0b11  *     *     *      *     drop
     * DEFLECTED      DROP            *     *     *     *      *     update(d)
     * DEFLECTED      *               *     *     0     *      *     drop
     * DEFLECTED      *               *     *     1     *      *     update(q)
     *
     * CLONED_EGRESS  FLOW | QUEUE    *     *     *     *      n     update(qf)
     * CLONED_EGRESS  QUEUE           *     *     *     *      n     update(q)
     * CLONED_EGRESS  FLOW            *     *     *     *      n     update(f)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_EGRESS  DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dq)
     *                | QUEUE
     * CLONED_EGRESS  DROP | QUEUE    0b11  *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | QUEUE    *     *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(d)
     *
     * BRIDGED        FLOW | SUPPRESS *     *     1     0      *     mirror_sw
     * BRIDGED        FLOW            *     0b00  1     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  1     0      *     mirror_sw_l
     * BRIDGED        *               *     *     1     0      *     mirror_sw_l
     * BRIDGED        FLOW | SUPPRESS *     *     *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b00  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     TCPfl *     0      *     mirror_sw_l
     *
     * BRIDGED        DROP            *     *     *     0      *     NoAction
     * User specified entries for egress drop_reason values: mirror or NoAction
     * BRIDGED        DROP            *     *     1     value  *     mirror_drop
     * BRIDGED        DROP            *     *     *     value  *     action
     * BRIDGED        *               *     *     1     value  *     mirror_sw_l
     * Drop report catch all entries
     * BRIDGED        DROP            *     *     1     *      *     mirror_drop
     * BRIDGED        DROP            *     *     *     *      *     mirror_drop
     * BRIDGED        *               *     *     1     *      *     mirror_sw_l
     *
     * *              *               *     *     *     *      *     NoAction
     * This table is asymmetric as hw_id is pipe specific.
     */

    table config {
        key = {
            eg_md.pkt_src : ternary;
            eg_md.dtel.report_type : ternary;
            eg_md.dtel.drop_report_flag : ternary;
            eg_md.dtel.flow_report_flag : ternary;
            eg_md.dtel.queue_report_flag : ternary;
            eg_md.drop_reason : ternary;
            eg_md.mirror.type : ternary;
            hdr.dtel_drop_report.isValid() : ternary;
# 732 "dtel.p4"
        }

        actions = {
            NoAction;
            drop;
            mirror_switch_local;
            mirror_switch_local_and_set_q_bit;
            mirror_drop;
            mirror_drop_and_set_q_bit;
            update;
# 769 "dtel.p4"
        }

        const default_action = NoAction;
    }

    apply {
        config.apply();
    }
}

control IntEdge(inout switch_egress_metadata_t eg_md)(
                switch_uint32_t port_table_size=288) {

    action set_clone_mirror_session_id(switch_mirror_session_t session_id) {
        eg_md.dtel.clone_session_id = session_id;
    }

    action set_ifa_edge() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_IFA_EDGE;
    }

    table port_lookup {
        key = {
            eg_md.port : exact;
        }
        actions = {
            NoAction;
            set_clone_mirror_session_id;
            set_ifa_edge;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            port_lookup.apply();
    }
}

control EgressDtel(inout switch_header_outer_t hdr,
                   inout bit<32> hdr_transport_timestamp, // derek hack
                   inout switch_egress_metadata_t eg_md,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   in bit<32> hash) {
    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report;
    IntEdge() int_edge;

    action convert_ingress_port(switch_port_t port) {



        hdr.dtel_report.ingress_port = port;

    }

    table ingress_port_conversion {
        key = {




          hdr.dtel_report.ingress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");

        }
        actions = {
            NoAction;
            convert_ingress_port;
        }

        const default_action = NoAction;
    }

    action convert_egress_port(switch_port_t port) {



        hdr.dtel_report.egress_port = port;

    }

    table egress_port_conversion {
        key = {




          hdr.dtel_report.egress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");

        }
        actions = {
            NoAction;
            convert_egress_port;
        }

        const default_action = NoAction;
    }

    apply {
# 920 "dtel.p4"
    }
}
# 54 "npb.p4" 2

# 1 "npb_ing_parser.p4" 1



parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum_transport;
    Checksum() ipv4_checksum_outer;
    Checksum() ipv4_checksum_inner;

    value_set<switch_cpu_port_value_set_t>(4) cpu_port;

    //value_set<bit<32>>(20) my_mac_lo;
    //value_set<bit<16>>(20) my_mac_hi;
    //value_set<bit<32>>(8) my_mac_lo;
    //value_set<bit<16>>(8) my_mac_hi;
    value_set<bit<32>>(1) my_mac_lo;
    value_set<bit<16>>(1) my_mac_hi;

 //bit<8>  protocol_outer;
 //bit<8>  protocol_inner;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        ig_md.flags.rmac_hit = false;




        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //     1 : parse_resubmit;
        //     0 : parse_port_metadata;
        // }

        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_0.tunnel_id = 0;
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_1.tunnel_id = 0;
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_2.tunnel_id = 0;
# 71 "npb_ing_parser.p4"
        // initialize lookup struct to zeros
        ig_md.lkp_1.mac_src_addr = 0;
        ig_md.lkp_1.mac_dst_addr = 0;
        ig_md.lkp_1.mac_type = 0;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.pad = 0;
        ig_md.lkp_1.vid = 0;
        ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_1.ip_proto = 0;
        ig_md.lkp_1.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_flags = 0;
        ig_md.lkp_1.ip_src_addr = 0;
        ig_md.lkp_1.ip_dst_addr = 0;
        ig_md.lkp_1.ip_len = 0;
        ig_md.lkp_1.tcp_flags = 0;
        ig_md.lkp_1.l4_src_port = 0;
        ig_md.lkp_1.l4_dst_port = 0;
        ig_md.lkp_1.drop_reason = 0;




        // initialize lookup struct (2) to zeros
        ig_md.lkp_2.mac_src_addr = 0;
        ig_md.lkp_2.mac_dst_addr = 0;
        ig_md.lkp_2.mac_type = 0;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.pad = 0;
        ig_md.lkp_2.vid = 0;
        ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_2.ip_proto = 0;
        ig_md.lkp_2.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_flags = 0;
        ig_md.lkp_2.ip_src_addr = 0;
        ig_md.lkp_2.ip_dst_addr = 0;
        ig_md.lkp_2.ip_len = 0;
        ig_md.lkp_2.tcp_flags = 0;
        ig_md.lkp_2.l4_src_port = 0;
        ig_md.lkp_2.l4_dst_port = 0;
        ig_md.lkp_2.drop_reason = 0;


//      ig_md.inner_inner.ethernet_isValid = false;
//      ig_md.inner_inner.ipv4_isValid = false;
//      ig_md.inner_inner.ipv6_isValid = false;

        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Port Metadata
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
  ig_md.nsh_md.l2_fwd_en = (bool)port_md.l2_fwd_en;
        transition check_from_cpu;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // CPU Packet Check
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////



    state check_from_cpu {
        transition select(
            pkt.lookahead<ethernet_h>().ether_type,
            ig_intr_md.ingress_port) {

            cpu_port: check_my_mac_lo_cpu;
            default: check_my_mac_lo;
        }
    }
# 165 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // My-MAC Check
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    //  My   L2   MAU                   First   
    //  MAC  Fwd  Path                  Stack
    //  ----------------------------    ------------
    //  0    0    SFC Optical-Tap       Outer       
    //  0    1    Bridging              Outer       
    //  1    x    SFC Network-Tap       Transport   
    //            or SFC Bypass (nsh)   Transport

    state check_my_mac_lo {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi;
            default: parse_outer_ethernet; // Bridging path
        }
    }

    state check_my_mac_lo_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi_cpu;
            default: parse_outer_ethernet_cpu; // Bridging path
        }
    }

    state check_my_mac_hi {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet; // SFC Network-Tap / SFC Bypass Path
            default: parse_outer_ethernet; // Bridging path
        }
    }

    state check_my_mac_hi_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet_cpu; // SFC Network-Tap / SFC Bypass Path
            default: parse_outer_ethernet_cpu; // Bridging path
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Transport" Headers / Stack (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Transport (ETH-T)
    ///////////////////////////////////////////////////////////////////////////
    // todo: explore implementing a fanout state here to save tcam

    state parse_transport_ethernet {
        ig_md.flags.rmac_hit = true;
        pkt.extract(hdr.transport.ethernet);
# 230 "npb_ing_parser.p4"
        // populate for L3-tunnel case (where there's no L2 present)
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.transport.ethernet.ether_type;



        // populate for L3-tunnel case (where there's no L2 present)
        ig_md.lkp_2.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.transport.ethernet.ether_type;


        transition select(hdr.transport.ethernet.ether_type) {
            0x894F: parse_transport_nsh;
            0x8100: parse_transport_vlan;
            0x88A8: parse_transport_vlan;

            0x0800: parse_transport_ipv4;




           default: parse_udf;
        }
    }

    // -------------------------------------------------------------------------
    state parse_transport_ethernet_cpu {
        ig_md.flags.rmac_hit = true;
        pkt.extract(hdr.transport.ethernet);




        pkt.extract(hdr.cpu);


  ig_md.bypass = (bit<8>)hdr.cpu.reason_code;

        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
  ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
  ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;
  hdr.transport.ethernet.ether_type = hdr.cpu.ether_type;
// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE







// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.cpu.ether_type;


// populate for L3-tunnel case (where there's no L2 present)        

        ig_md.lkp_2.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.cpu.ether_type;


        transition select(hdr.cpu.ether_type) {
            0x894F: parse_transport_nsh;
            0x8100: parse_transport_vlan;
            0x88A8: parse_transport_vlan;

            0x0800: parse_transport_ipv4;




            default: parse_udf;
        }
    }


    // -------------------------------------------------------------------------
    state parse_transport_vlan {

     pkt.extract(hdr.transport.vlan_tag[0]);
# 331 "npb_ing_parser.p4"
// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_1.pcp = hdr.transport.vlan_tag[0].pcp;

        ig_md.lkp_1.vid = hdr.transport.vlan_tag[0].vid;

        ig_md.lkp_1.mac_type = hdr.transport.vlan_tag[0].ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.pcp = hdr.transport.vlan_tag[0].pcp;

        ig_md.lkp_2.vid = hdr.transport.vlan_tag[0].vid;

        ig_md.lkp_2.mac_type = hdr.transport.vlan_tag[0].ether_type;


        transition select(hdr.transport.vlan_tag[0].ether_type) {
            0x894F: parse_transport_nsh;

            0x0800: parse_transport_ipv4;




            default: parse_udf;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer3 - Transport
    ///////////////////////////////////////////////////////////////////////////



    state parse_transport_ipv4 {
     pkt.extract(hdr.transport.ipv4);

        ipv4_checksum_transport.add(hdr.transport.ipv4);
        ig_md.flags.ipv4_checksum_err_0 = ipv4_checksum_transport.verify();
# 385 "npb_ing_parser.p4"
        transition select(hdr.transport.ipv4.protocol) {
           47: parse_transport_gre;
           default : parse_udf;
        }
    }
# 417 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Transport
    ///////////////////////////////////////////////////////////////////////////    



    //-------------------------------------------------------------------------
    // GRE - Transport
    //-------------------------------------------------------------------------

    state parse_transport_gre {
        pkt.extract(hdr.transport.gre);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_0.tunnel_id = 0;

        transition select(
            hdr.transport.gre.C,
            hdr.transport.gre.R,
            hdr.transport.gre.K,
            hdr.transport.gre.S,
            hdr.transport.gre.s,
            hdr.transport.gre.recurse,
            hdr.transport.gre.flags,
            hdr.transport.gre.version,
            hdr.transport.gre.proto) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0,0x0800): parse_outer_ipv4;
            (0,0,0,0,0,0,0,0,0x86dd): parse_outer_ipv6;

            (0,0,0,1,0,0,0,0,0x88BE): parse_transport_erspan_t2;
          //(0,0,0,1,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_transport_erspan_t3;

            default: parse_udf;
        }
    }




    //-------------------------------------------------------------------------
    // ERSPAN - Transport
    //-------------------------------------------------------------------------



    state parse_transport_erspan_t2 {
        pkt.extract(hdr.transport.gre_sequence);
        pkt.extract(hdr.transport.erspan_type2);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;



        ig_md.lkp_0.tunnel_id = 0;

        transition parse_outer_ethernet;
    }

    // state parse_transport_erspan_t3 {
    //     pkt.extract(hdr.transport.gre_sequence);
    //     pkt.extract(hdr.transport.erspan_type3);
    //     ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
    //     transition select(hdr.transport.erspan_type3.o) {
    //         1: parse_erspan_type3_platform;
    //         default: parse_inner_ethernet;
    //     }
    // }
    // 
    // state parse_transport_erspan_type3_platform {
    //     pkt.extract(hdr.transport.erspan_platform);
    //     transition parse_outer_ethernet;
    // }




    //-------------------------------------------------------------------------
    // NSH - Transport
    //-------------------------------------------------------------------------

    state parse_transport_nsh {
     pkt.extract(hdr.transport.nsh_type1);
        transition select(hdr.transport.nsh_type1.next_proto) {
            0x3: parse_outer_ethernet;
            default: parse_udf; // todo: support ipv4? ipv6?
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////
    // todo: explore implementing a fanout state here to save tcam

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);


        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.outer.ethernet.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;


        transition select(hdr.outer.ethernet.ether_type) {


            0x893F : parse_outer_br;


            0x8926 : parse_outer_vn;


            0x8100 : parse_outer_vlan_0;
            0x88A8 : parse_outer_vlan_0;



            //ETHERTYPE_ARP  : parse_outer_arp;
            0x0800 : parse_outer_ipv4;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }


    state parse_outer_ethernet_cpu {
        pkt.extract(hdr.outer.ethernet);



        pkt.extract(hdr.cpu);


  ig_md.bypass = (bit<8>)hdr.cpu.reason_code;

        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
  ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
  ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;
  hdr.outer.ethernet.ether_type = hdr.cpu.ether_type;
// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE


        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.cpu.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.cpu.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;


        transition select(hdr.cpu.ether_type) {


            0x893F : parse_outer_br;


            0x8926 : parse_outer_vn;


            0x8100 : parse_outer_vlan_0;
            0x88A8 : parse_outer_vlan_0;



            //ETHERTYPE_ARP  : parse_outer_arp;
            0x0800 : parse_outer_ipv4;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }


    state parse_outer_br {
     pkt.extract(hdr.outer.e_tag);


        ig_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;
        //ig_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_type = hdr.outer.e_tag.ether_type;
        //ig_md.lkp_2.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag


        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan_0;
            0x88A8 : parse_outer_vlan_0;



            0x0800 : parse_outer_ipv4;
            //ETHERTYPE_ARP  : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }



    state parse_outer_vn {
     pkt.extract(hdr.outer.vn_tag);


        ig_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_type = hdr.outer.vn_tag.ether_type;


        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan_0;
            0x88A8 : parse_outer_vlan_0;



            0x0800 : parse_outer_ipv4;
            //ETHERTYPE_ARP  : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }



    state parse_outer_vlan_0 {

     pkt.extract(hdr.outer.vlan_tag[0]);






        ig_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;

        ig_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;

        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.pcp = hdr.outer.vlan_tag[0].pcp;

        ig_md.lkp_2.vid = hdr.outer.vlan_tag[0].vid;

        ig_md.lkp_2.mac_type = hdr.outer.vlan_tag[0].ether_type;


        transition select(hdr.outer.vlan_tag[0].ether_type) {
            0x8100 : parse_outer_vlan_1;
            0x88A8 : parse_outer_vlan_1;



            0x0800 : parse_outer_ipv4;
            //ETHERTYPE_ARP  : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }


    state parse_outer_vlan_1 {
     pkt.extract(hdr.outer.vlan_tag[1]);


        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_2.mac_type = hdr.outer.vlan_tag[1].ether_type;


        transition select(hdr.outer.vlan_tag[1].ether_type) {



            0x0800 : parse_outer_ipv4;
            //ETHERTYPE_ARP  : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : parse_udf;
        }
    }


    // ///////////////////////////////////////////////////////////////////////////
    // // Layer 2.5 - Outer
    // ///////////////////////////////////////////////////////////////////////////
    // 
    // state parse_outer_arp {
    //     // pkt.extract(hdr.outer.arp);
    //     // transition accept;
    //     transition parse_udf;
    // 
    // }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

//     state parse_outer_ipv4 {
//         pkt.extract(hdr.outer.ipv4);
//         protocol_outer = hdr.outer.ipv4.protocol;
// #ifdef INGRESS_PARSER_POPULATES_LKP_1
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv4.protocol;
//         ig_md.lkp_1.ip_tos        = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_flags      = hdr.outer.ipv4.flags;
//         ig_md.lkp_1.ip_src_addr   = (bit<128>)hdr.outer.ipv4.src_addr;
//         ig_md.lkp_1.ip_dst_addr   = (bit<128>)hdr.outer.ipv4.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_outer.add(hdr.outer.ipv4);
//         transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
//             (5, 0): parse_outer_ipv4_no_options_frags;
//             default : parse_udf;
//         }
//     }
// 
//     state parse_outer_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
//         transition select(hdr.outer.ipv4.protocol) {
//             //IP_PROTOCOLS_ICMP: parse_outer_icmp_igmp_overload;
//             //IP_PROTOCOLS_IGMP: parse_outer_icmp_igmp_overload;
//             default: branch_outer_l3_protocol;
//         }
//     }

    state parse_outer_ipv4 {
        pkt.extract(hdr.outer.ipv4);

        // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
        ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_1.ip_proto = hdr.outer.ipv4.protocol;
        ig_md.lkp_1.ip_tos = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_flags = hdr.outer.ipv4.flags;
        ig_md.lkp_1.ip_src_addr = (bit<128>)hdr.outer.ipv4.src_addr;
        ig_md.lkp_1.ip_dst_addr = (bit<128>)hdr.outer.ipv4.dst_addr;
        ig_md.lkp_1.ip_len = hdr.outer.ipv4.total_len;

        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum_outer.add(hdr.outer.ipv4);
        transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
            (5, 0): parse_outer_ipv4_no_options_frags;
            default : parse_udf;
        }
    }

    state parse_outer_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
        transition select(hdr.outer.ipv4.protocol) {
            //IP_PROTOCOLS_ICMP: parse_outer_icmp_igmp_overload;
            //IP_PROTOCOLS_IGMP: parse_outer_icmp_igmp_overload;
            4: parse_outer_ipinip_set_tunnel_type;
            41: parse_outer_ipv6inip_set_tunnel_type;
            17: parse_outer_udp;
            6: parse_outer_tcp;
            0x84: parse_outer_sctp;
            47: parse_outer_gre;
            //IP_PROTOCOLS_ESP: parse_outer_esp_overload;
            default: parse_udf;
        }
    }


//     state parse_outer_ipv6 {
// #ifdef IPV6_ENABLE
//         pkt.extract(hdr.outer.ipv6);
//         protocol_outer = hdr.outer.ipv6.next_hdr;
// #ifdef INGRESS_PARSER_POPULATES_LKP_1        
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv6.next_hdr;
//         //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_src_addr   = hdr.outer.ipv6.src_addr;
//         ig_md.lkp_1.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv6.payload_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         transition select(hdr.outer.ipv6.next_hdr) {
//             //IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload;
//             default: branch_outer_l3_protocol;
//         }
// #else
//         transition reject;
// #endif
//     }


    state parse_outer_ipv6 {

        pkt.extract(hdr.outer.ipv6);

        ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_1.ip_proto = hdr.outer.ipv6.next_hdr;
        //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_src_addr = hdr.outer.ipv6.src_addr;
        ig_md.lkp_1.ip_dst_addr = hdr.outer.ipv6.dst_addr;
        ig_md.lkp_1.ip_len = hdr.outer.ipv6.payload_len;

        transition select(hdr.outer.ipv6.next_hdr) {
            //IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload;
            4: parse_outer_ipinip_set_tunnel_type;
            41: parse_outer_ipv6inip_set_tunnel_type;
            17: parse_outer_udp;
            6: parse_outer_tcp;
            0x84: parse_outer_sctp;
            47: parse_outer_gre;
            //IP_PROTOCOLS_ESP: parse_outer_esp_overload;
            default: parse_udf;
        }



    }


    // // shared fanout/branch state to save tcam resource
    // state branch_outer_l3_protocol {
    //     transition select(protocol_outer) {
    //         IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
    //         IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
    //         IP_PROTOCOLS_UDP: parse_outer_udp;
    //         IP_PROTOCOLS_TCP: parse_outer_tcp;
    //         IP_PROTOCOLS_SCTP: parse_outer_sctp;
    //         IP_PROTOCOLS_GRE: parse_outer_gre;
    //         //IP_PROTOCOLS_ESP: parse_outer_esp_overload;
    //         default: parse_udf;
    //    }
    // }


//     // For ICMP and IGMP, we're not actually extracting the header;
//     // We're simply over-loading L4-port info for policy via lookahead.    
//     state parse_outer_icmp_igmp_overload {
// #if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_1)
//         ig_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
// #endif
//         transition parse_udf;
//     }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp {
        pkt.extract(hdr.outer.udp);


        ig_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;


        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {


            (_, 4789): parse_outer_vxlan;



            (_, 2123): parse_outer_gtp_c;
            (2123, _): parse_outer_gtp_c;
            (_, 2152): parse_outer_gtp_u;
            (2152, _): parse_outer_gtp_u;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u;            

            default : parse_udf;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp {
        pkt.extract(hdr.outer.tcp);

        ig_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        ig_md.lkp_1.tcp_flags = hdr.outer.tcp.flags;

        transition parse_udf;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp {
        pkt.extract(hdr.outer.sctp);

        ig_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;

        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
# 1001 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------



    state parse_outer_vxlan {
        pkt.extract(hdr.outer.vxlan);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.vxlan.vni;




        transition parse_inner_ethernet;
    }




    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_type {

        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;




        transition parse_inner_ipv4;



    }

    state parse_outer_ipv6inip_set_tunnel_type {

        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;




        transition parse_inner_ipv6;



    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_gre {
        gre_h snoop_gre = pkt.lookahead<gre_h>();

        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;




        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified;
            default: parse_udf;
        }
    }

    state parse_outer_gre_qualified {
        pkt.extract(hdr.outer.gre);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_1.tunnel_id = 0;





        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S

            (0,1,0,0x6558): parse_outer_nvgre;

            (0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0x86dd): parse_inner_ipv6;



            (1,0,0,_): parse_outer_gre_optional;
            (0,1,0,_): parse_outer_gre_optional;
            (0,0,1,_): parse_outer_gre_optional;
            default: parse_udf;
        }
    }


    state parse_outer_gre_optional {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;



            default: parse_udf;
        }
    }



    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - (aka: L2 GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre {
     pkt.extract(hdr.outer.nvgre);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.nvgre.vsid;
        ig_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; // from switch




        transition parse_inner_ethernet;
    }



    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //-------------------------------------------------------------------------

//     state parse_outer_esp_overload {
// #if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_1)
//         ig_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         ig_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif
//         transition parse_udf;
//     }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    // GTP-C
    //-------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state parse_outer_gtp_c {

        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;




        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified;
            default: parse_udf;
        }
    }

    state parse_outer_gtp_c_qualified {
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;




     transition parse_udf;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_outer_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();

        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;




        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional;
            default: parse_udf;
        }
    }

    state parse_outer_gtp_u_qualified {
        pkt.extract(hdr.outer.gtp_v1_base);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;




        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: parse_udf;
        }
    }

    state parse_outer_gtp_u_with_optional {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;




        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4;
            (0, 6): parse_inner_ipv6;
            default: parse_udf;
        }
    }




    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer 2 (ETH-T) - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner.ethernet);


        ig_md.lkp_2.mac_src_addr = hdr.inner.ethernet.src_addr;
        ig_md.lkp_2.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        ig_md.lkp_2.mac_type = hdr.inner.ethernet.ether_type;
        ig_md.lkp_2.pcp = 0;
        ig_md.lkp_2.vid = 0;


        transition select(hdr.inner.ethernet.ether_type) {
            //ETHERTYPE_ARP:  parse_inner_arp;
            0x8100: parse_inner_vlan;
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default : parse_udf;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner.vlan_tag[0]);






        ig_md.lkp_2.pcp = hdr.inner.vlan_tag[0].pcp;

        ig_md.lkp_2.vid = hdr.inner.vlan_tag[0].vid;

        ig_md.lkp_2.mac_type = hdr.inner.vlan_tag[0].ether_type;


        transition select(hdr.inner.vlan_tag[0].ether_type) {
            //ETHERTYPE_ARP:  parse_inner_arp;
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default : parse_udf;
        }
    }


    // ///////////////////////////////////////////////////////////////////////////
    // // Layer 2.5 - Inner
    // ///////////////////////////////////////////////////////////////////////////
    // 
    // state parse_inner_arp {
    //     // pkt.extract(hdr.inner.arp);
    //     // transition accept;
    //     transition parse_udf;
    // }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

//     state parse_inner_ipv4 {
//         pkt.extract(hdr.inner.ipv4);
//         protocol_inner = hdr.inner.ipv4.protocol;
// 
// #ifdef INGRESS_PARSER_POPULATES_LKP_2
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
// 
//         // fixup ethertype for ip-n-ip case
//         ig_md.lkp_2.mac_type      = ETHERTYPE_IPV4;
// 
//         ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_2.ip_proto      = hdr.inner.ipv4.protocol;
//         ig_md.lkp_2.ip_tos        = hdr.inner.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_2.ip_flags      = hdr.inner.ipv4.flags;
//         ig_md.lkp_2.ip_src_addr   = (bit<128>)hdr.inner.ipv4.src_addr;
//         ig_md.lkp_2.ip_dst_addr   = (bit<128>)hdr.inner.ipv4.dst_addr;
//         ig_md.lkp_2.ip_len        = hdr.inner.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_2        
//         
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_inner.add(hdr.inner.ipv4);
//         transition select(
//             hdr.inner.ipv4.ihl,
//             hdr.inner.ipv4.frag_offset) {
//             (5, 0): parse_inner_ipv4_no_options_frags;
//             default: parse_udf;
//         }
//     }
// 
//     state parse_inner_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
//         transition select(hdr.inner.ipv4.protocol) {
//             //IP_PROTOCOLS_ICMP: parse_inner_icmp_igmp_overload;
//             //IP_PROTOCOLS_IGMP: parse_inner_icmp_igmp_overload;
//             default: branch_inner_l3_protocol;
//         }
//     }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner.ipv4);


        // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?

        // fixup ethertype for ip-n-ip case
        ig_md.lkp_2.mac_type = 0x0800;

        ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_2.ip_proto = hdr.inner.ipv4.protocol;
        ig_md.lkp_2.ip_tos = hdr.inner.ipv4.tos; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_flags = hdr.inner.ipv4.flags;
        ig_md.lkp_2.ip_src_addr = (bit<128>)hdr.inner.ipv4.src_addr;
        ig_md.lkp_2.ip_dst_addr = (bit<128>)hdr.inner.ipv4.dst_addr;
        ig_md.lkp_2.ip_len = hdr.inner.ipv4.total_len;


        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum_inner.add(hdr.inner.ipv4);
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset) {
            (5, 0): parse_inner_ipv4_no_options_frags;
            default: parse_udf;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
        transition select(hdr.inner.ipv4.protocol) {
            //IP_PROTOCOLS_ICMP: parse_inner_icmp_igmp_overload;
            //IP_PROTOCOLS_IGMP: parse_inner_icmp_igmp_overload;
            17: parse_inner_udp;
            6: parse_inner_tcp;
            0x84: parse_inner_sctp;

            47: parse_inner_gre;

            //IP_PROTOCOLS_ESP: parse_inner_esp_overload;
            4: parse_inner_ipinip_set_tunnel_type;
            41: parse_inner_ipv6inip_set_tunnel_type;
            default : parse_udf;
        }
    }


//     state parse_inner_ipv6 {
// #ifdef IPV6_ENABLE
//         pkt.extract(hdr.inner.ipv6);
//         protocol_inner = hdr.inner.ipv6.next_hdr;
// 
// #ifdef INGRESS_PARSER_POPULATES_LKP_2
//         
//         // fixup ethertype for ip-n-ip case
//         ig_md.lkp_2.mac_type      = ETHERTYPE_IPV6;
//         
//         ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV6;
//         ig_md.lkp_2.ip_proto      = hdr.inner.ipv6.next_hdr;
//         //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
//         ig_md.lkp_2.ip_src_addr   = hdr.inner.ipv6.src_addr;
//         ig_md.lkp_2.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
//         ig_md.lkp_2.ip_len        = hdr.inner.ipv6.payload_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_2        
// 
//         transition select(hdr.inner.ipv6.next_hdr) {
//             //IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload;
//             default: branch_inner_l3_protocol;
//         }
// #else
//         transition reject;
// #endif
//     }

    state parse_inner_ipv6 {

        pkt.extract(hdr.inner.ipv6);


        // fixup ethertype for ip-n-ip case
        ig_md.lkp_2.mac_type = 0x86dd;

        ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_2.ip_proto = hdr.inner.ipv6.next_hdr;
        //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_2.ip_src_addr = hdr.inner.ipv6.src_addr;
        ig_md.lkp_2.ip_dst_addr = hdr.inner.ipv6.dst_addr;
        ig_md.lkp_2.ip_len = hdr.inner.ipv6.payload_len;


        transition select(hdr.inner.ipv6.next_hdr) {
            //IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload;
            17: parse_inner_udp;
            6: parse_inner_tcp;
            0x84: parse_inner_sctp;

            47: parse_inner_gre;

            //IP_PROTOCOLS_ESP: parse_inner_esp_overload;
            4: parse_inner_ipinip_set_tunnel_type;
            41: parse_inner_ipv6inip_set_tunnel_type;
            default : parse_udf;
        }



    }


//     // shared fanout/branch state to save tcam resource
//     state branch_inner_l3_protocol {
//         transition select(protocol_inner) {
//             IP_PROTOCOLS_UDP: parse_inner_udp;
//             IP_PROTOCOLS_TCP: parse_inner_tcp;
//             IP_PROTOCOLS_SCTP: parse_inner_sctp;
// #ifdef INNER_GRE_ENABLE
//             IP_PROTOCOLS_GRE: parse_inner_gre;
// #endif // INNER_GRE_ENABLE
//             //IP_PROTOCOLS_ESP: parse_inner_esp_overload;
//             IP_PROTOCOLS_IPV4: parse_inner_ipinip_set_tunnel_type;
//             IP_PROTOCOLS_IPV6: parse_inner_ipv6inip_set_tunnel_type;
//             default : parse_udf;
//        }
//     }    

//     // For ICMP and IGMP, we're not actually extracting the header;
//     // We're simply over-loading L4-port info for policy via lookahead.     
//     state parse_inner_icmp_igmp_overload {
// #if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_2)
//         ig_md.lkp_2.l4_src_port = pkt.lookahead<bit<16>>();
// #endif
//         transition parse_udf;
//     }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner.udp);

        ig_md.lkp_2.l4_src_port = hdr.inner.udp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.udp.dst_port;

        transition select(hdr.inner.udp.src_port, hdr.inner.udp.dst_port) {

            (_, 2123): parse_inner_gtp_c;
            (2123, _): parse_inner_gtp_c;
            (_, 2152): parse_inner_gtp_u;
            (2152, _): parse_inner_gtp_u;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u;            

            default: parse_udf;
        }
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner.tcp);

        ig_md.lkp_2.l4_src_port = hdr.inner.tcp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.tcp.dst_port;
        ig_md.lkp_2.tcp_flags = hdr.inner.tcp.flags;

        transition parse_udf;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner.sctp);

        ig_md.lkp_2.l4_src_port = hdr.inner.sctp.src_port;
        ig_md.lkp_2.l4_dst_port = hdr.inner.sctp.dst_port;

        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_ipinip_set_tunnel_type {

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
        transition parse_inner_inner_ipv4;



    }

    state parse_inner_ipv6inip_set_tunnel_type {

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
        transition parse_inner_inner_ipv6;



    }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Inner
    //-------------------------------------------------------------------------

//     state parse_inner_esp_overload {
// #if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_2)
//         ig_md.lkp_2.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         ig_md.lkp_2.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif
//         transition parse_udf;
//     }    


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //-------------------------------------------------------------------------



    state parse_inner_gre {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_inner_gre_qualified;
            (1,0,0,0,0,0,0,0): parse_inner_gre_qualified;
            (0,0,1,0,0,0,0,0): parse_inner_gre_qualified;
            (0,0,0,1,0,0,0,0): parse_inner_gre_qualified;
            default: parse_udf;
        }
    }

    state parse_inner_gre_qualified {
        pkt.extract(hdr.inner.gre);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_2.tunnel_id = 0;

        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.proto) {

            (0,0,0,0x0800): parse_inner_inner_ipv4;
            (0,0,0,0x86dd): parse_inner_inner_ipv6;
            (1,0,0,_): parse_inner_gre_optional;
            (0,1,0,_): parse_inner_gre_optional;
            (0,0,1,_): parse_inner_gre_optional;
            default: parse_udf;
        }
    }

    state parse_inner_gre_optional {
        pkt.extract(hdr.inner.gre_optional);
        transition select(hdr.inner.gre.proto) {
            0x0800: parse_inner_inner_ipv4;
            0x86dd: parse_inner_inner_ipv6;
            default: parse_udf;
        }
    }






    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Inner
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //-------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state parse_inner_gtp_c {
        //gtp_v2_base_h snoop_inner_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        //transition select(
        //    snoop_inner_gtp_v2_base.version,
        //    snoop_inner_gtp_v2_base.T) {

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_inner_gtp_c_qualified;
            default: parse_udf;
        }
    }

    state parse_inner_gtp_c_qualified {
        //pkt.extract(hdr.inner.gtp_v2_base);
        //ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        //ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v2_base.teid;

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_2.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
        transition parse_udf;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_inner_gtp_u {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_inner_gtp_u_qualified;
            (1, 1, 0, 1, 0): parse_inner_gtp_u_with_optional;
            default: parse_udf;
        }
    }

    state parse_inner_gtp_u_qualified {
        pkt.extract(hdr.inner.gtp_v1_base);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: parse_udf;
        }
    }

    state parse_inner_gtp_u_with_optional {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: parse_udf;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_inner_ipv4 {
  hdr.inner_inner.ipv4.setValid();
//      ig_md.inner_inner.ipv4_isValid = true;
  transition parse_udf;
    }
    state parse_inner_inner_ipv6 {
  hdr.inner_inner.ipv6.setValid();
//      ig_md.inner_inner.ipv6_isValid = true;
  transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // UDF
    ///////////////////////////////////////////////////////////////////////////

    state parse_udf {



        transition extract_udf;
    }

    @dontmerge ("ingress")
    state extract_udf {



        transition accept;
    }

}
# 56 "npb.p4" 2
# 1 "npb_ing_set_lkp.p4" 1




// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookup(
        in switch_header_t hdr, // src
        inout switch_ingress_metadata_t ig_md // dst
) {

    // -----------------------------
 // Apply
    // -----------------------------

    apply {

  ig_md.lkp_0.next_lyr_valid = true;
//		if((ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
//			ig_md.lkp_0.next_lyr_valid = true;
//		}

//		ig_md.lkp_1.next_lyr_valid = true;
  if((ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
   ig_md.lkp_1.next_lyr_valid = true;
  }

//		ig_md.lkp_2.next_lyr_valid = true;
  if((ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
   ig_md.lkp_2.next_lyr_valid = true;
  }

  // -----------------------------------------------------------------------

        // Override whatever the parser set "ip_type" to.  Doing so allows the
        // signal to fit when normally it doesn't.  This code should be only
        // temporary, and can be removed at a later date when a better compiler
        // is available....
        if (hdr.outer.ipv4.isValid())
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        else if(hdr.outer.ipv6.isValid())
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        else
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;

        if (hdr.inner.ipv4.isValid())
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
        else if(hdr.inner.ipv6.isValid())
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
        else
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;

  // -----------------------------------------------------------------------

  // ipv6: would like to do this stuff in the parser, but can't because tos
  // field isn't byte aligned...

  // ipv4: would like to do this stuff in the parser, but get the following error:
        //   "error: Field is extracted in the parser into multiple containers, but
        //    the container slices after the first aren't byte aligned"


  if(hdr.outer.ipv6.isValid()) {
   ig_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
  }

//		if(hdr.outer.ipv4.isValid()) {
//			ig_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//		}        



  if(hdr.inner.ipv6.isValid()) {
   ig_md.lkp_2.ip_tos = hdr.inner.ipv6.tos;
  }

//		if(hdr.inner.ipv4.isValid()) {
//			ig_md.lkp_2.ip_tos = hdr.inner.ipv4.tos;
//		}


    }
}
# 57 "npb.p4" 2
# 1 "npb_ing_top.p4" 1
# 1 "npb_ing_sfc_top.p4" 1
# 1 "tunnel.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 2 "npb_ing_sfc_top.p4" 2





control npb_ing_sfc_top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {


 IngressTunnel(
  IPV4_SRC_TUNNEL_TABLE_SIZE, IPV6_SRC_TUNNEL_TABLE_SIZE,
  IPV4_DST_TUNNEL_TABLE_SIZE, IPV6_DST_TUNNEL_TABLE_SIZE
 ) tunnel_transport;


 IngressTunnelNetwork(NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH) tunnel_network;




 IngressTunnelOuter(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH) tunnel_outer;

 IngressTunnelInner(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;

 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // W/  NSH... Table #0:
 // =========================================================================

 action ing_sfc_sf_sel_hit(
  bit<8> si_predec
 ) {
  ig_md.nsh_md.si_predec = si_predec;
 }

 // ---------------------------------

 action ing_sfc_sf_sel_miss(
 ) {
//		ig_md.nsh_md.si_predec  = 0;
  ig_md.nsh_md.si_predec = hdr_0.nsh_type1.si;
 }

 // ---------------------------------

 table ing_sfc_sf_sel {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");
   hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   ing_sfc_sf_sel_hit;
   ing_sfc_sf_sel_miss;
   NoAction;
  }

  const default_action = ing_sfc_sf_sel_miss;
  size = NPB_ING_SFC_SF_SEL_TABLE_DEPTH;
 }

 // =========================================================================
 // W/O NSH... Table #0:
 // =========================================================================

 action set_port_properties(
  bit<8> si_predec,

  bit<16> sap,
  bit<12> vpn,
  bit<24> spi,
  bit<8> si
 ) {
  ig_md.nsh_md.si_predec = si_predec; //  8 bits

  hdr_0.nsh_type1.sap = (bit<16>)sap; // 16 bits
  hdr_0.nsh_type1.vpn = (bit<16>)vpn; // 16 bits
  hdr_0.nsh_type1.spi = spi; // 24 bits
  hdr_0.nsh_type1.si = si; //  8 bits
 }

 // ---------------------------------

 table port_mapping {
  key = {
   ig_md.port : exact @name("port");
//			ig_md.port_lag_index : exact @name("port_lag_index");
  }

  actions = {
   set_port_properties;
   NoAction;
  }

  const default_action = NoAction;
//		size = port_table_size;
  size = 1024;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // ---------------------------------------------------------------------
  // Classify
  // ---------------------------------------------------------------------

  // -----------------------------------------------------------------------------------------------------
  // | transport  | trasnport |
  // | nsh valid  | eth valid | result
  // +------------+-----------+----------------
  // | 1          | x         | internal  fabric -> sfc no tables...instead grab fields from nsh header
  // | 0          | 1         | normally  tapped -> sfc transport table, sap mapping table, inner table
  // | 0          | 0         | optically tapped -> sfc outer     table,                    inner table
  // -----------------------------------------------------------------------------------------------------

  if(hdr_0.nsh_type1.isValid()) {

   // -----------------------------------------------------------------
   // Packet does    have a NSH header on it (is already classified)
   // -----------------------------------------------------------------

   // ----- metadata -----
   ig_md.nsh_md.start_of_path = false;
//			ig_md.nsh_md.sfc_enable    = false;

   // ----- table -----

   ing_sfc_sf_sel.apply();

  } else {

   // -----------------------------------------------------------------
   // Packet doesn't have a NSH header on it -- add it (needs classification)
   // -----------------------------------------------------------------

   // ----- metadata -----
   ig_md.nsh_md.start_of_path = true; // * see design note below
//			ig_md.nsh_md.sfc_enable    = false; // * see design note below

   // ----- header -----

   // note: according to p4 spec, initializing a header also automatically sets it valid.
//			hdr_0.nsh_type1.setValid();
   hdr_0.nsh_type1 = {
    version = 0x0,
    o = 0x0,
    reserved = 0x0,
    ttl = 0x3f, // 63 is the rfc's recommended default value.
    len = 0x6, // in 4-byte words (1 + 1 + 4).
    reserved2 = 0x0,
    md_type = 0x1, // 0 = reserved, 1 = fixed len, 2 = variable len.
    next_proto = 0x3, // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.

    spi = 0x0,
    si = 0x0,

    ver = 0x2,
    reserved3 = 0x0,
    lag_hash = 0x0,

    vpn = 0x0,
    sfc_data = 0x0,

    reserved4 = 0x0,
    scope = 0x0,
    sap = 0x0,




    timestamp = 0

   };

   // ----- table -----
   port_mapping.apply();

   // -----------------------------------------------------------------

   if(hdr_0.ethernet.isValid()) {

    // ---------------------------
    // ----- Normally Tapped -----
    // ---------------------------


    tunnel_transport.apply(ig_md, hdr_0, ig_md.lkp_0, tunnel_0, ig_intr_md_for_dprsr);


    // -----------------------
    // Network SAP
    // -----------------------
    tunnel_network.apply(ig_md, ig_md.lkp_0, hdr_0, tunnel_0);


   } else {

    // ----------------------------
    // ----- Optically Tapped -----
    // ----------------------------

    // -----------------------
    // Outer SAP
    // -----------------------

    tunnel_outer.apply(ig_md, ig_md.lkp_1, hdr_0, ig_md.lkp_2, hdr_2, tunnel_2);

   }

   // -----------------------
   // Inner SAP
   // -----------------------
   tunnel_inner.apply(ig_md, ig_md.lkp_1, hdr_0, ig_md.lkp_2, hdr_2, tunnel_2);

  }

  // always terminate transport headers
  tunnel_0.terminate = true;
 }
}
# 2 "npb_ing_top.p4" 2
# 1 "npb_ing_sf_npb_basic_adv_top.p4" 1
//#include "npb_ing_sf_npb_basic_adv_acl.p4"
# 1 "npb_ing_sf_npb_basic_adv_sfp_sel.p4" 1

control npb_ing_sf_npb_basic_adv_sfp_hash (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 in bit<16> mac_type,
 in bit<8> ip_proto,
 in bit<16> l4_src_port,
 in bit<16> l4_dst_port,
 out bit<16> hash
) {
 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table #1 (main lkp struct):
 // =========================================================================

 bit<10> flow_class_internal = 0;

 action ing_flow_class_hit (
  bit<10> flow_class
 ) {
  // ----- change nsh -----

  // change metadata
  flow_class_internal = flow_class;
 }

 // ---------------------------------

 table ing_flow_class {
  key = {
   hdr_0.nsh_type1.vpn : ternary @name("vpn");
   mac_type : ternary @name("mac_type");
   ip_proto : ternary @name("ip_proto");
   l4_src_port : ternary @name("l4_src_port");
   l4_dst_port : ternary @name("l4_dst_port");
  }

  actions = {
   NoAction;
   ing_flow_class_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFF_FLW_CLS_TABLE_DEPTH;
 }

 // =========================================================================
 // Hash #1 (main lkp struct):
 // =========================================================================

//	Hash<bit<32>>(HashAlgorithm_t.CRC32) hash_func;
//	Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_func;
 Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_func;

 action compute_hash(
 ) {
  hash = hash_func.get({
   hdr_0.nsh_type1.vpn,
   flow_class_internal
  });
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  ing_flow_class.apply();
  compute_hash();
 }
}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_sfp_sel (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // =========================================================================
 // Table #1: Action Selector
 // =========================================================================
# 116 "npb_ing_sf_npb_basic_adv_sfp_sel.p4"
 // Use an Action Selector with the table...
    Hash<bit<16>>(
  HashAlgorithm_t.IDENTITY
 ) selector_hash;
/*
    Hash<switch_uint16_t>(
		HashAlgorithm_t.IDENTITY
	) selector_hash;
*/
/*
	Hash<bit<16>>(
		HashAlgorithm_t.CRC16
	) selector_hash;
*/
/*
	Hash<bit<32>>(
		HashAlgorithm_t.CRC32
	) selector_hash;
*/
 ActionProfile(NPB_ING_SFF_SCHD_SELECTOR_TABLE_SIZE) schd_action_profile;
    ActionSelector(
  schd_action_profile,
  selector_hash,
//		SelectorMode_t.FAIR,
  SelectorMode_t.RESILIENT,
  NPB_ING_SFF_SCHD_MAX_MEMBERS_PER_GROUP,
  NPB_ING_SFF_SCHD_GROUP_TABLE_SIZE
 ) schd_selector;





 // ---------------------------------

 action ing_schd_hit (
  bit<24> spi,
  bit<8> si,

  bit<8> si_predec
 ) {
  hdr_0.nsh_type1.spi = spi;
  hdr_0.nsh_type1.si = si;

  // change metadata
  ig_md.nsh_md.si_predec = si_predec;
 }

 // ---------------------------------

 table ing_schd {
  key = {
   ig_md.nsh_md.sfc : exact @name("sfc");

//			hdr_0.nsh_type1.vpn       : selector;
//			flow_class_internal       : selector;
   ig_md.nsh_md.hash_1 : selector;

  }

  actions = {
   NoAction;
   ing_schd_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFF_SCHD_TABLE_SIZE;

  implementation = schd_selector;

 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  if(ig_md.nsh_md.sfc_enable == true) {
   ing_schd.apply();
  }
 }

}
# 3 "npb_ing_sf_npb_basic_adv_top.p4" 2




control npb_ing_sf_npb_basic_adv_top (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_header_inner_t hdr_2,
    inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 IngressAcl(
  INGRESS_IPV4_ACL_TABLE_SIZE,


  INGRESS_IPV6_ACL_TABLE_SIZE,

  INGRESS_MAC_ACL_TABLE_SIZE,
  INGRESS_L7_ACL_TABLE_SIZE
 ) acl;

 // temporary internal variables
//	bit<2>  action_bitmask_internal;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: policy
 //   [1:1] act #2: unused (was dedup)

 // =========================================================================
 // Table #1: Action Select
 // =========================================================================

 bit<8> int_ctrl_flags = 0;

 action ing_sf_action_sel_hit(
//		bit<2>  action_bitmask,



//      bit<3>  discard
 ) {
//		action_bitmask_internal = action_bitmask;




//      ig_intr_md_for_dprsr.drop_ctl = discard; // drop packet
 }

 // =====================================

 action ing_sf_action_sel_miss(
 ) {
//		action_bitmask_internal = 0;
//		int_ctrl_flags = 0;
 }

 // =====================================

 table ing_sf_action_sel {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");
   hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   NoAction;
   ing_sf_action_sel_hit;
   ing_sf_action_sel_miss;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #2: IP Length Range
 // =========================================================================

 bit<16> ip_len = 0;
 bool ip_len_is_rng_bitmask = false;


 action ing_sf_ip_len_rng_hit(
  bit<16> rng_bitmask
 ) {
  ip_len = rng_bitmask;
  ip_len_is_rng_bitmask = true;
 }

 // =====================================

 action ing_sf_ip_len_rng_miss(
 ) {
  ip_len = ig_md.lkp_1.ip_len;
  ip_len_is_rng_bitmask = false;
 }

 // =====================================

 table ing_sf_ip_len_rng {
  key = {
   ig_md.lkp_1.ip_len : range @name("ip_len");
  }

  actions = {
   NoAction;
   ing_sf_ip_len_rng_hit;
   ing_sf_ip_len_rng_miss;
  }

  const default_action = ing_sf_ip_len_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Table #3: L4 Src Port Range
 // =========================================================================

 bit<16> l4_src_port = 0;
 bool l4_src_port_is_rng_bitmask = false;


 action ing_sf_l4_src_port_rng_hit(
  bit<16> rng_bitmask
 ) {
  l4_src_port = rng_bitmask;
  l4_src_port_is_rng_bitmask = true;
 }

 // =====================================

 action ing_sf_l4_src_port_rng_miss(
 ) {
  l4_src_port = ig_md.lkp_1.l4_src_port;
  l4_src_port_is_rng_bitmask = false;
 }

 // =====================================

 table ing_sf_l4_src_port_rng {
  key = {
   ig_md.lkp_1.l4_src_port : range @name("l4_src_port");
  }

  actions = {
   NoAction;
   ing_sf_l4_src_port_rng_hit;
   ing_sf_l4_src_port_rng_miss;
  }

  const default_action = ing_sf_l4_src_port_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Table #4: L4 Dst Port Range
 // =========================================================================

 bit<16> l4_dst_port = 0;
 bool l4_dst_port_is_rng_bitmask = false;


 action ing_sf_l4_dst_port_rng_hit(
  bit<16> rng_bitmask
 ) {
  l4_dst_port = rng_bitmask;
  l4_dst_port_is_rng_bitmask = true;
 }

 // =====================================

 action ing_sf_l4_dst_port_rng_miss(
 ) {
  l4_dst_port = ig_md.lkp_1.l4_dst_port;
  l4_dst_port_is_rng_bitmask = false;
 }

 // =====================================

 table ing_sf_l4_dst_port_rng {
  key = {
   ig_md.lkp_1.l4_dst_port : range @name("l4_dst_port");
  }

  actions = {
   NoAction;
   ing_sf_l4_dst_port_rng_hit;
   ing_sf_l4_dst_port_rng_miss;
  }

  const default_action = ing_sf_l4_dst_port_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Action Lookup
  // =====================================

  if(ing_sf_action_sel.apply().hit) {

   // =====================================
   // Decrement SI
   // =====================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
   ig_md.nsh_md.si_predec = ig_md.nsh_md.si_predec - 1; // decrement sp_index





   // =====================================
   // Action(s)
   // =====================================

//			if(action_bitmask_internal[0:0] == 1) {

    // -------------------------------------
    // Action #0 - Policy
    // -------------------------------------


    ing_sf_ip_len_rng.apply();





    ing_sf_l4_src_port_rng.apply();





    ing_sf_l4_dst_port_rng.apply();





    acl.apply(
     ig_md.lkp_1,
     ig_md,
     ig_intr_md_for_dprsr,
     ig_intr_md_for_tm,
     ip_len,
     ip_len_is_rng_bitmask,
     l4_src_port,
     l4_src_port_is_rng_bitmask,
     l4_dst_port,
     l4_dst_port_is_rng_bitmask,
     hdr_0,
     hdr_1,
     hdr_2,
     hdr_udf,
     int_ctrl_flags
    );
//			}

//			if(action_bitmask_internal[1:1] == 1) {

    // -------------------------------------
    // Action #1 - Deduplication
    // -------------------------------------
# 309 "npb_ing_sf_npb_basic_adv_top.p4"
//			}

  }
/*
		npb_ing_sf_npb_basic_adv_sfp_sel.apply(
			hdr_0,
			ig_md,
			ig_intr_md,
			ig_intr_md_from_prsr,
			ig_intr_md_for_dprsr,
			ig_intr_md_for_tm
		);
*/
 }
}
# 3 "npb_ing_top.p4" 2
//#include "npb_ing_sf_npb_basic_adv_sfp_sel.p4"
# 1 "npb_ing_sf_multicast_top.p4" 1



control npb_ing_sf_multicast_top_part1 (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
 switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH
) {

 // temporary internal variables
//  bit<1> action_bitmask_internal;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: multicast

 // =========================================================================
 // Table #1: Action Select
 // =========================================================================

 action ing_sf_action_sel_hit(
//		bit<1> action_bitmask,
  switch_mgid_t mgid
 ) {
//		action_bitmask_internal = action_bitmask;

  ig_md.multicast.id = mgid;

  ig_md.egress_port_lag_index = 0;
 }

 // =====================================

 action ing_sf_action_sel_miss(
 ) {
//		action_bitmask_internal = 0;
 }

 // =====================================

 table ing_sf_action_sel {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");
   hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   ing_sf_action_sel_hit;
   ing_sf_action_sel_miss;
  }

  size = table_size;
  const default_action = ing_sf_action_sel_miss;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Action Lookup
  // =====================================

  if(ing_sf_action_sel.apply().hit) {

//			ig_md.nsh_md.sf1_active = true;

   // =====================================
   // Decrement SI
   // =====================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index




   // =====================================
   // Action(s)
   // =====================================

//			if(action_bitmask_internal[0:0] == 1) {

    // There used to be a table here that took sfc and gave mgid.  It has been removed in the latest iteration.

//			}

  } else {
//			ig_md.nsh_md.sf1_active = false;
  }

 }
}

// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sf_multicast_top_part2 (
 inout switch_header_transport_t hdr_0,
 in switch_rid_t replication_id,
 in switch_port_t port,
 inout switch_egress_metadata_t eg_md
) (
 switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table #1: 
 // =========================================================================
/*
#ifdef MULTICAST_ENABLE
	action rid_hit_nsh(
		switch_bd_t bd,

		bit<24>               spi,
		bit<8>                si,

		switch_nexthop_t nexthop_index,
		switch_tunnel_index_t tunnel_index,
		switch_outer_nexthop_t outer_nexthop_index
	) {
		eg_md.bd = bd;

		hdr_0.nsh_type1.spi     = spi;
		hdr_0.nsh_type1.si      = si;

		eg_md.nexthop = nexthop_index;
		eg_md.tunnel_0.index = tunnel_index;
		eg_md.outer_nexthop = outer_nexthop_index;
	}

	action rid_hit(
		switch_bd_t bd
	) {
		eg_md.bd = bd;
	}

	action rid_miss() {
	}

	table rid {
		key = {
			replication_id : exact;
		}
		actions = {
			rid_miss;
			rid_hit;
			rid_hit_nsh;
		}

		size = table_size;
		const default_action = rid_miss;
	}
#endif
*/
 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Action Lookup
  // =====================================
/*
		if(eg_md.nsh_md.sf1_active == true) {

			// =====================================
			// Decrement SI
			// =====================================

			// Derek: We have moved this here, rather than at the end of the sf,
			// in violation of RFC8300.  This is because of an issue were a sf
			// can reclassify the packet with a new si, which would then get immediately
			// decremented.  This means firmware would have to add 1 to the si value
			// the really wanted.  So we move it here so that is gets decremented after
			// the lookup that uses it, but before any actions have run....

			// NOTE: THIS IS DONE IN EGRESS INSTEAD OF INGRESS, BECAUSE WE DON"T FIT OTHERWISE!

#ifdef BUG_09719_WORKAROUND
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index
#else
			hdr_0.nsh_type1.si = hdr_0.nsh_type1.si |-| 1; // decrement sp_index
#endif
			// =====================================
			// Action(s)
			// =====================================

		}
*/
  // =====================================
  // Replication ID Lookup
  // =====================================
/*
#ifdef MULTICAST_ENABLE
		if(replication_id != 0) {
			rid.apply();
		}
#endif
*/
 }
}
# 5 "npb_ing_top.p4" 2
# 1 "npb_ing_sff_top.p4" 1
control npb_ing_sff_top (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // =========================================================================
 // Table: FIB
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action drop_pkt (
 ) {
  stats.count();

  ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//		ig_md.nsh_md.end_of_path = false;
 }

 // =====================================

 action unicast(
  switch_nexthop_t nexthop_index,

  bool end_of_chain,
  bit<6> lag_hash_mask_en
 ) {
  stats.count();

  ig_md.nexthop = nexthop_index;

  ig_md.nsh_md.end_of_path = end_of_chain;
  ig_md.nsh_md.lag_hash_mask_en = lag_hash_mask_en;
 }

 // =====================================

 action multicast(
  bool end_of_chain,
  bit<6> lag_hash_mask_en
 ) {
  stats.count();

  ig_md.nsh_md.end_of_path = end_of_chain;
  ig_md.nsh_md.lag_hash_mask_en = lag_hash_mask_en;
 }

 // =====================================
 // Table
 // =====================================

 table ing_sff_fib {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");

   ig_md.nsh_md.si_predec : exact @name("si");



  }

  actions = {
   drop_pkt;
   multicast;
   unicast;
  }

  // Derek: drop packet on miss...
  //
  // RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
  // do not correspond to a valid next hop in a valid SFP, that packet MUST
  // be dropped by the SFF.

  const default_action = drop_pkt;
  counters = stats;
  size = NPB_ING_SFF_ARP_TABLE_DEPTH;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  // -------------------------------------
  // Perform Forwarding Lookup
  // -------------------------------------

  ing_sff_fib.apply();

 }
}
# 6 "npb_ing_top.p4" 2

# 1 "scoper.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 8 "npb_ing_top.p4" 2

control npb_ing_top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout switch_header_inner_inner_t hdr_3,
 inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {






 npb_ing_sf_npb_basic_adv_sfp_hash() npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1;

//	npb_ing_sf_npb_basic_adv_sfp_hash() npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2;



 TunnelDecapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_decap_transport_ingress;
 TunnelDecapOuter(switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
 TunnelDecapInner(switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

//	TunnelEncapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_encap_transport_ingress;

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // Derek: Don't know what we want to do with this signal for the 
  // npb path.  For now, just setting it to 0 here (it's set in port.p4,
  // but probably not using the fields we want to be used for the npb)

  ig_intr_md_for_tm.level2_exclusion_id = 0;

  // -----------------------------------------------------------------
  // Set Initial Scope
  // -----------------------------------------------------------------

  if(hdr_0.nsh_type1.scope == 0) {

   // do nothing
# 71 "npb_ing_top.p4"
  } else {

   Scoper.apply(
    ig_md.lkp_2,
//				ig_md.drop_reason_2,

    ig_md.lkp_1
   );
# 88 "npb_ing_top.p4"
  }

  // -----------------------------------------------------------------
  // Set Initial Scope (L7)
  // -----------------------------------------------------------------






  // -----------------------------------------------------------------

  // populate udf in lkp struct for the following cases:
  //   scope==inner
  //   scope==outer and no inner stack present
  // todo: do we need to qualify this w/ hdr_udf.isValid()? (the thinking is it will just work w/o doing so)







  // -------------------------------------
  // SFC
  // -------------------------------------

  npb_ing_sfc_top.apply (
   hdr_0,
   tunnel_0,
   hdr_1,
   tunnel_1,
   hdr_2,
   tunnel_2,
   hdr_udf,

   ig_md,
   ig_intr_md,
   ig_intr_md_from_prsr,
   ig_intr_md_for_dprsr,
   ig_intr_md_for_tm
  );

  // -------------------------------------
  // Pre-Generate Flow Schd Hashes
  // -------------------------------------


  npb_ing_sf_npb_basic_adv_sfp_hash_lkp_1.apply(
   hdr_0,
   ig_md,
   ig_intr_md,
   ig_intr_md_from_prsr,
   ig_intr_md_for_dprsr,
   ig_intr_md_for_tm,

   ig_md.lkp_1.mac_type,
   ig_md.lkp_1.ip_proto,
   ig_md.lkp_1.l4_src_port,
   ig_md.lkp_1.l4_dst_port,
   ig_md.nsh_md.hash_1
  );

  // -------------------------------------
# 164 "npb_ing_top.p4"
  // -------------------------------------
/*
  #ifdef SF_0_ALLOW_SCOPE_CHANGES

    #ifdef INGRESS_PARSER_POPULATES_LKP_2
    #else
		ScoperInner.apply(
			hdr_2,
			tunnel_2,
//			ig_md.drop_reason_2,

			ig_md.lkp_2
		);
    #endif

		npb_ing_sf_npb_basic_adv_sfp_hash_lkp_2.apply(
			hdr_0,
			ig_md,
			ig_intr_md,
			ig_intr_md_from_prsr,
			ig_intr_md_for_dprsr,
			ig_intr_md_for_tm,

			ig_md.lkp_2.mac_type,
			ig_md.lkp_2.ip_proto,
			ig_md.lkp_2.l4_src_port,
			ig_md.lkp_2.l4_dst_port,
			ig_md.nsh_md.hash_2
		);
  #endif // SF_0_ALLOW_SCOPE_CHANGES
*/


  // -------------------------------------
  // SF #0 - Policy
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SF_ACL != 0)) {
   npb_ing_sf_npb_basic_adv_top.apply (
    hdr_0,
    hdr_1,
    hdr_2,
    hdr_udf,

    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );

   // -------------------------------------

   npb_ing_sf_npb_basic_adv_sfp_sel.apply(
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }

  // -------------------------------------
  // SFF Reframing
  // -------------------------------------

  // Decaps ------------------------------

  tunnel_decap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);



  tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
  tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		TunnelDecapFixEthertype.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
  TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0);
# 255 "npb_ing_top.p4"
  // Encaps ------------------------------

//		tunnel_0.encap = true;
//		tunnel_encap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1);

  // -------------------------------------
  // SFF
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SFF != 0)) {
   npb_ing_sff_top.apply (
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }

  // -------------------------------------
  // SF #1 - Multicast
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SF_MCAST != 0)) {
   npb_ing_sf_multicast_top_part1.apply (
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }
 }
}
# 58 "npb.p4" 2
# 1 "npb_ing_deparser.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "npb_ing_deparser.p4" 2
# 1 "types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 23 "npb_ing_deparser.p4" 2

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------

control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.


    Mirror() mirror;


    apply {

        if (ig_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<switch_port_mirror_metadata_h>(ig_md.mirror.session_id, {
                 ig_md.mirror.src,
                 ig_md.mirror.type,
                 0,
                 ig_md.port,
                 ig_md.bd,
                 0,
                 ig_md.port_lag_index,
//               ig_md.timestamp,
                 (bit<32>)hdr.transport.nsh_type1.timestamp,



                 ig_md.mirror.session_id
            });
        } else if (ig_intr_md_for_dprsr.mirror_type == 3) {
# 81 "npb_ing_deparser.p4"
        }

    }
}

//-----------------------------------------------------------------------------

control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

 IngressMirror() mirror;

    apply {
  mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.

        // ***** PRE-TRANSPORT *****
        pkt.emit(hdr.transport.nsh_type1);

        // ***** TRANSPORT *****
//      pkt.emit(hdr.transport.ethernet);
//      pkt.emit(hdr.transport.vlan_tag);

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);

        pkt.emit(hdr.outer.e_tag);


        pkt.emit(hdr.outer.vn_tag);

        pkt.emit(hdr.outer.vlan_tag);




        pkt.emit(hdr.outer.ipv4);

        pkt.emit(hdr.outer.ipv6);

        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.sctp);

        pkt.emit(hdr.outer.vxlan);

        pkt.emit(hdr.outer.gre);
        pkt.emit(hdr.outer.gre_optional);

        pkt.emit(hdr.outer.nvgre);


        pkt.emit(hdr.outer.gtp_v1_base);
        pkt.emit(hdr.outer.gtp_v1_optional);



        // ***** INNER *****
        pkt.emit(hdr.inner.ethernet);
        pkt.emit(hdr.inner.vlan_tag);
        pkt.emit(hdr.inner.ipv4);

        pkt.emit(hdr.inner.ipv6);

        pkt.emit(hdr.inner.udp);
        pkt.emit(hdr.inner.tcp);
        pkt.emit(hdr.inner.sctp);


        pkt.emit(hdr.inner.gre);
        pkt.emit(hdr.inner.gre_optional);


        pkt.emit(hdr.inner.gtp_v1_base);
        pkt.emit(hdr.inner.gtp_v1_optional);





    }
}
# 59 "npb.p4" 2
# 1 "npb_egr_parser.p4" 1



parser NpbEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    bit<8> scope;
    bool l2_fwd_en;
    bool rmac_hit;

 bit<8> protocol_outer;
 bit<8> protocol_inner;


    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;


        // initialize lookup struct to zeros
        eg_md.lkp_1.mac_src_addr = 0;
        eg_md.lkp_1.mac_dst_addr = 0;
        eg_md.lkp_1.mac_type = 0;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.pad = 0;
        eg_md.lkp_1.vid = 0;
        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        eg_md.lkp_1.ip_proto = 0;
        eg_md.lkp_1.ip_tos = 0;
        eg_md.lkp_1.ip_flags = 0;
        eg_md.lkp_1.ip_src_addr = 0;
        eg_md.lkp_1.ip_dst_addr = 0;
        eg_md.lkp_1.ip_len = 0;
        eg_md.lkp_1.tcp_flags = 0;
        eg_md.lkp_1.l4_src_port = 0;
        eg_md.lkp_1.l4_dst_port = 0;
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        eg_md.lkp_1.tunnel_id = 0;
        eg_md.lkp_1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE; // note: outer here means "current scope - 2"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NONE; // note: inner here means "current scope - 1"



        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {




            (_, SWITCH_PKT_SRC_BRIDGED, _ ) : parse_bridged_pkt;
//          (_, _,                             SWITCH_MIRROR_TYPE_PORT             ) : parse_port_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 1 ) : parse_ig_port_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_EGRESS, 1 ) : parse_eg_port_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_EGRESS, 2 ) : parse_cpu_mirrored_metadata;
# 67 "npb_egr_parser.p4"
        }



    }

    state parse_bridged_pkt {
  pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;

  // ---- extract base bridged metadata -----
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
//      eg_md.pkt_type             = hdr.bridged_md.base.pkt_type;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
//      eg_md.ingress_timestamp    = hdr.bridged_md.base.timestamp;
        eg_md.flags.rmac_hit = hdr.bridged_md.base.rmac_hit;
  eg_md.flags.bypass_egress = hdr.bridged_md.base.bypass_egress;

        eg_md.outer_nexthop = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel_0.index = hdr.bridged_md.tunnel.index;
//      eg_md.tunnel_0.hash        = hdr.bridged_md.tunnel.hash;

//      eg_md.tunnel_0.terminate   = hdr.bridged_md.tunnel.terminate_0;
//      eg_md.tunnel_1.terminate   = hdr.bridged_md.tunnel.terminate_1;
//      eg_md.tunnel_2.terminate   = hdr.bridged_md.tunnel.terminate_2;


  // ----- extract nsh bridged metadata -----
        eg_md.nsh_md.start_of_path = hdr.bridged_md.nsh.nsh_md_start_of_path;
  eg_md.nsh_md.end_of_path = hdr.bridged_md.nsh.nsh_md_end_of_path;
  eg_md.nsh_md.l2_fwd_en = hdr.bridged_md.nsh.nsh_md_l2_fwd_en;
//      eg_md.nsh_md.sf1_active    = hdr.bridged_md.nsh.nsh_md_sf1_active;

  // ----- extract dedup bridged metadata -----
//#ifdef SF_2_DEDUP_ENABLE
  eg_md.nsh_md.dedup_en = hdr.bridged_md.nsh.nsh_md_dedup_en;
//#endif







        // -----------------------------
        // packet will always have NSH present

        //  L2   My   MAU                   First   
        //  Fwd  MAC  Path                  Stack
        //  ----------------------------    ------------
        //  0    0    SFC Optical-Tap       Outer       
        //  0    1    SFC Optical-Tap       Outer       
        //  1    0    Bridging              Outer       
        //  1    1    SFC Network-Tap       Transport   
        //            or SFC Bypass (nsh)   Transport

        transition select(
            (bit<1>)hdr.bridged_md.nsh.nsh_md_l2_fwd_en,
            (bit<1>)hdr.bridged_md.base.rmac_hit) {

            (1, 0): parse_outer_ethernet_scope0; // SFC Optical-Tap / Bridging Path
//          default: parse_transport_ethernet;    // SFC Network-Tap / SFC Bypass Path
            default: parse_transport_nsh; // SFC Network-Tap / SFC Bypass Path
        }

    }

    state parse_ig_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src; // for cpu header
        eg_md.bd = port_md.bd; // for cpu header (derek added)
  eg_md.ingress_port = port_md.port; // for cpu header (derek added)
        eg_md.port_lag_index = port_md.port_lag_index; // for cpu header (derek added)
  eg_md.cpu_reason = SWITCH_CPU_REASON_IG_PORT_MIRRROR; // for cpu header (derek added)
        eg_md.mirror.session_id = port_md.session_id; // for ??? header
//      eg_md.ingress_timestamp = port_md.timestamp;          // for ??? header
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;







        transition accept;
    }

    state parse_eg_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src; // for cpu header
        eg_md.bd = port_md.bd; // for cpu header (derek added)
  eg_md.ingress_port = port_md.port; // for cpu header (derek added)
        eg_md.port_lag_index = port_md.port_lag_index; // for cpu header (derek added)
  eg_md.cpu_reason = SWITCH_CPU_REASON_EG_PORT_MIRRROR; // for cpu header (derek added)
        eg_md.mirror.session_id = port_md.session_id; // for ??? header
//      eg_md.ingress_timestamp = port_md.timestamp;          // for ??? header
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;







        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = cpu_md.src; // for cpu header
        eg_md.bd = cpu_md.bd; // for cpu header
        eg_md.ingress_port = cpu_md.port; // for cpu header
        eg_md.port_lag_index = cpu_md.port_lag_index; // for cpu header (derek added)
        eg_md.cpu_reason = cpu_md.reason_code; // for cpu header
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;







        transition accept;
    }
# 411 "npb_egr_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Transport Layer 2 (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // NSH
    ///////////////////////////////////////////////////////////////////////////

    state parse_transport_ethernet {
        pkt.extract(hdr.transport.ethernet);
        transition select(hdr.transport.ethernet.ether_type) {
            0x8100: parse_transport_vlan;
            0x894F: parse_transport_nsh;
            default: accept; // should never get here
        }
    }
    state parse_transport_vlan {
        pkt.extract(hdr.transport.vlan_tag[0]);
        transition select(hdr.transport.vlan_tag[0].ether_type) {
            0x894F: parse_transport_nsh;
            default: accept; // should never get here
        }
    }
    state parse_transport_nsh {
     pkt.extract(hdr.transport.nsh_type1);
        scope = hdr.transport.nsh_type1.scope;

        transition select(scope, hdr.transport.nsh_type1.next_proto) {
            (0, 0x3): parse_outer_ethernet_scope0;


            (1, 0x3): parse_outer_ethernet_scope1;




            default: reject; // todo: support ipv4? ipv6?
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////

    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_outer_ethernet_scope0 {
        pkt.extract(hdr.outer.ethernet);

        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;


        transition select(hdr.outer.ethernet.ether_type) {


            0x893F : parse_outer_br_scope0;


            0x8926 : parse_outer_vn_scope0;

            0x8100 : parse_outer_vlan_0_scope0;
            0x88A8 : parse_outer_vlan_0_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    state parse_outer_br_scope0 {
     pkt.extract(hdr.outer.e_tag);

        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;
        //eg_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag

        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan_0_scope0;
            0x88A8 : parse_outer_vlan_0_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }



    state parse_outer_vn_scope0 {
     pkt.extract(hdr.outer.vn_tag);

        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;

        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan_0_scope0;
            0x88A8 : parse_outer_vlan_0_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    state parse_outer_vlan_0_scope0 {
     pkt.extract(hdr.outer.vlan_tag[0]);

        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;

  eg_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;

        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;







        transition select(hdr.outer.vlan_tag[0].ether_type) {
            0x8100 : parse_outer_vlan_1_scope0;
            0x88A8 : parse_outer_vlan_1_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }

    state parse_outer_vlan_1_scope0 {
     pkt.extract(hdr.outer.vlan_tag[1]);


        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;




        transition select(hdr.outer.vlan_tag[1].ether_type) {



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_outer_ethernet_scope1 {
        pkt.extract(hdr.outer.ethernet);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;


        transition select(hdr.outer.ethernet.ether_type) {


            0x893F : parse_outer_br_scope1;



            0x8926 : parse_outer_vn_scope1;


            0x8100 : parse_outer_vlan_0_scope1;
            0x88A8 : parse_outer_vlan_0_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    state parse_outer_br_scope1 {
     pkt.extract(hdr.outer.e_tag);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;


        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan_0_scope1;
            0x88A8 : parse_outer_vlan_0_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }



    state parse_outer_vn_scope1 {
     pkt.extract(hdr.outer.vn_tag);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;


        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan_0_scope1;
            0x88A8 : parse_outer_vlan_0_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }



    state parse_outer_vlan_0_scope1 {
     pkt.extract(hdr.outer.vlan_tag[0]);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.pcp = hdr.outer.vlan_tag[0].pcp;

  eg_md.lkp_1.vid = hdr.outer.vlan_tag[0].vid;

        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[0].ether_type;
# 681 "npb_egr_parser.p4"
        transition select(hdr.outer.vlan_tag[0].ether_type) {
            0x8100 : parse_outer_vlan_1_scope1;
            0x88A8 : parse_outer_vlan_1_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    state parse_outer_vlan_1_scope1 {
     pkt.extract(hdr.outer.vlan_tag[1]);


        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag[1].ether_type;





        transition select(hdr.outer.vlan_tag[1].ether_type) {



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_outer_ipv4_scope0 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;

        // todo: should the lkp struct be set only if no frag and options?
        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto = hdr.outer.ipv4.protocol;
        eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
        eg_md.lkp_1.ip_flags = hdr.outer.ipv4.flags;
        eg_md.lkp_1.ip_src_addr = (bit<128>)hdr.outer.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr = (bit<128>)hdr.outer.ipv4.dst_addr;
        eg_md.lkp_1.ip_len = hdr.outer.ipv4.total_len;


        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset,
            hdr.outer.ipv4.protocol) {

            //(5, 0, IP_PROTOCOLS_ICMP): parse_outer_icmp_igmp_overload_scope0;
            //(5, 0, IP_PROTOCOLS_IGMP): parse_outer_icmp_igmp_overload_scope0;
            (5, 0, _): branch_outer_l3_protocol_scope0;
            default: accept;
        }
    }

    state parse_outer_ipv6_scope0 {

        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;

        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto = hdr.outer.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        eg_md.lkp_1.ip_src_addr = hdr.outer.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr = hdr.outer.ipv6.dst_addr;
        eg_md.lkp_1.ip_len = hdr.outer.ipv6.payload_len;


        transition branch_outer_l3_protocol_scope0;
        // transition select(hdr.outer.ipv6.next_hdr) {
        //     IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload_scope0;
        //     default: branch_outer_l3_protocol_scope0;
        // }



    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope0 {
        transition select(protocol_outer) {
           4: parse_outer_ipinip_set_tunnel_scope0;
           41: parse_outer_ipv6inip_set_tunnel_scope0;
           17: parse_outer_udp_scope0;
           6: parse_outer_tcp_scope0;
           0x84: parse_outer_sctp_scope0;
           47: parse_outer_gre_scope0;
           //IP_PROTOCOLS_ESP: parse_outer_esp_overload_scope0;
           default: accept;
       }
    }


    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_outer_ipv4_scope1 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset) {

            (5, 0): branch_outer_l3_protocol_scope1;
            default: accept;
        }
    }

    state parse_outer_ipv6_scope1 {

        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;
        transition branch_outer_l3_protocol_scope1;



    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope1 {
        transition select(protocol_outer) {
           4: parse_outer_ipinip_set_tunnel_scope1;
           41: parse_outer_ipv6inip_set_tunnel_scope1;
           17: parse_outer_udp_scope1;
           6: parse_outer_tcp_scope1;
           0x84: parse_outer_sctp_scope1;
           47: parse_outer_gre_scope1;
           default: accept;
       }
    }


//     // For ICMP and IGMP, we're not actually extracting the header;
//     // We're simply over-loading L4-port info for policy via lookahead.    
//     state parse_outer_icmp_igmp_overload_scope0 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
// #endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp_scope0 {
        pkt.extract(hdr.outer.udp);


        eg_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;


        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {


            (_, 4789): parse_outer_vxlan_scope0;



            (_, 2123): parse_outer_gtp_c_scope0;
            (2123, _): parse_outer_gtp_c_scope0;
            (_, 2152): parse_outer_gtp_u_scope0;
            (2152, _): parse_outer_gtp_u_scope0;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c_scope0;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u_scope0;

            default : accept;
        }
    }

    state parse_outer_udp_scope1 {
        pkt.extract(hdr.outer.udp);
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {


            (_, 4789): parse_outer_vxlan_scope1;



            (_, 2123): parse_outer_gtp_c_scope1;
            (2123, _): parse_outer_gtp_c_scope1;
            (_, 2152): parse_outer_gtp_u_scope1;
            (2152, _): parse_outer_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u_scope1;

            default : accept;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp_scope0 {
        pkt.extract(hdr.outer.tcp);

        eg_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        eg_md.lkp_1.tcp_flags = hdr.outer.tcp.flags;

        transition accept;
    }

    state parse_outer_tcp_scope1 {
        pkt.extract(hdr.outer.tcp);
        transition accept;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp_scope0 {
        pkt.extract(hdr.outer.sctp);

        eg_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;

        transition accept;
    }

    state parse_outer_sctp_scope1 {
        pkt.extract(hdr.outer.sctp);
        transition accept;
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
# 1000 "npb_egr_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////



    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_vxlan_scope0 {
        pkt.extract(hdr.outer.vxlan);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        eg_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.vxlan.vni;

        transition parse_inner_ethernet_scope0;
    }

    state parse_outer_vxlan_scope1 {
        pkt.extract(hdr.outer.vxlan);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_VXLAN; // note: inner here means "current scope - 1"
        transition parse_inner_ethernet_scope1;
    }




    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_ipv4_scope0;



    }

    state parse_outer_ipv6inip_set_tunnel_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_ipv6_scope0;



    }


    state parse_outer_ipinip_set_tunnel_scope1 {

        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_ipv4_scope1;



    }

    state parse_outer_ipv6inip_set_tunnel_scope1 {

        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_ipv6_scope1;



    }



    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_gre_scope0 {
        gre_h snoop_gre = pkt.lookahead<gre_h>();


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;


        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_gre_scope1 {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED; // note: inner here means "current scope - 1"

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified_scope1;
            default: accept;
        }
    }


    state parse_outer_gre_qualified_scope0 {
        pkt.extract(hdr.outer.gre);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;


        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S

            (0,1,0,0x6558): parse_outer_nvgre_scope0;

            (0,0,0,0x0800): parse_inner_ipv4_scope0;
            (0,0,0,0x86dd): parse_inner_ipv6_scope0;



            (1,0,0,_): parse_outer_gre_optional_scope0;
            (0,1,0,_): parse_outer_gre_optional_scope0;
            (0,0,1,_): parse_outer_gre_optional_scope0;
            default: accept;
        }
    }

    state parse_outer_gre_qualified_scope1 {
        pkt.extract(hdr.outer.gre);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GRE; // note: inner here means "current scope - 1"

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S

            (0,1,0,0x6558): parse_outer_nvgre_scope1;

            (0,0,0,0x0800): parse_inner_ipv4_scope1;
            (0,0,0,0x86dd): parse_inner_ipv6_scope1;



            (1,0,0,_): parse_outer_gre_optional_scope1;
            (0,1,0,_): parse_outer_gre_optional_scope1;
            (0,0,1,_): parse_outer_gre_optional_scope1;
            default: accept;
        }
    }


    state parse_outer_gre_optional_scope0 {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4_scope0;
            0x86dd: parse_inner_ipv6_scope0;



            default: accept;
        }
    }

    state parse_outer_gre_optional_scope1 {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4_scope1;
            0x86dd: parse_inner_ipv6_scope1;



            default: accept;
        }
    }




    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - (aka: L2 GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre_scope0 {
     pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        eg_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.nvgre.vsid;

     transition parse_inner_ethernet_scope0;
    }

    state parse_outer_nvgre_scope1 {
     pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NVGRE; // note: inner here means "current scope - 1"
     transition parse_inner_ethernet_scope1;
    }



//     //-------------------------------------------------------------------------
//     // Encapsulating Security Payload (ESP) - Outer
//     //-------------------------------------------------------------------------
//     
//     state parse_outer_esp_overload_scope0 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//          eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//          eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    // GTP-C
    //-------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state parse_outer_gtp_c_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;


        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_gtp_c_qualified_scope0 {

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;

     transition accept;
    }

    state parse_outer_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED; // note: inner here means "current scope - 1"

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_c_qualified_scope1 {
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPC; // note: inner here means "current scope - 1"
     transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_outer_gtp_u_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;


        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified_scope0;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_gtp_u_qualified_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;

        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope0;
            6: parse_inner_ipv6_scope0;
            default: accept;
        }
    }

    state parse_outer_gtp_u_with_optional_qualified_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;

        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope0;
            (0, 6): parse_inner_ipv6_scope0;
            default: accept;
        }
    }


    state parse_outer_gtp_u_scope1 {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED; // note: inner here means "current scope - 1"

        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified_scope1;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional_qualified_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_u_qualified_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU; // note: inner here means "current scope - 1"
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope1;
            6: parse_inner_ipv6_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_u_with_optional_qualified_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU; // note: inner here means "current scope - 1"
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope1;
            (0, 6): parse_inner_ipv6_scope1;
            default: accept;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer 2 (ETH-T) - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_inner_ethernet_scope0 {
        pkt.extract(hdr.inner.ethernet);
        transition select(hdr.inner.ethernet.ether_type) {
            0x8100 : parse_inner_vlan_scope0;
            0x0800 : parse_inner_ipv4_scope0;
            0x86dd : parse_inner_ipv6_scope0;
            default : accept;
        }
    }

    state parse_inner_vlan_scope0 {
        pkt.extract(hdr.inner.vlan_tag[0]);
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            0x0800 : parse_inner_ipv4_scope0;
            0x86dd : parse_inner_ipv6_scope0;
            default : accept;
        }
    }

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------            

    state parse_inner_ethernet_scope1 {
        pkt.extract(hdr.inner.ethernet);

        eg_md.lkp_1.mac_src_addr = hdr.inner.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.inner.ethernet.ether_type;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.vid = 0;

        transition select(hdr.inner.ethernet.ether_type) {
            0x8100 : parse_inner_vlan_scope1;
            0x0800 : parse_inner_ipv4_scope1;
            0x86dd : parse_inner_ipv6_scope1;
            default : accept;
        }
    }

    state parse_inner_vlan_scope1 {
        pkt.extract(hdr.inner.vlan_tag[0]);

        eg_md.lkp_1.pcp = hdr.inner.vlan_tag[0].pcp;

  eg_md.lkp_1.vid = hdr.inner.vlan_tag[0].vid;

        eg_md.lkp_1.mac_type = hdr.inner.vlan_tag[0].ether_type;






        transition select(hdr.inner.vlan_tag[0].ether_type) {
            0x0800 : parse_inner_ipv4_scope1;
            0x86dd : parse_inner_ipv6_scope1;
            default : accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------            

    // For scope0 inner parsing, v4 or v6 is all that's needed downstream.

    state parse_inner_ipv4_scope0 {
        pkt.extract(hdr.inner.ipv4);
        transition accept;
    }

    state parse_inner_ipv6_scope0 {

        pkt.extract(hdr.inner.ipv6);
        transition accept;



    }


    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_inner_ipv4_scope1 {
        pkt.extract(hdr.inner.ipv4);
        protocol_inner = hdr.inner.ipv4.protocol;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type = 0x0800;

        // todo: should the lkp struct be set only if no frag and options?
        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto = hdr.inner.ipv4.protocol;
        eg_md.lkp_1.ip_tos = hdr.inner.ipv4.tos;
        eg_md.lkp_1.ip_flags = hdr.inner.ipv4.flags;
        eg_md.lkp_1.ip_src_addr = (bit<128>)hdr.inner.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr = (bit<128>)hdr.inner.ipv4.dst_addr;
        eg_md.lkp_1.ip_len = hdr.inner.ipv4.total_len;

        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset,
            hdr.inner.ipv4.protocol) {
            //(5, 0, IP_PROTOCOLS_ICMP): parse_inner_icmp_igmp_overload_scope1;
            //(5, 0, IP_PROTOCOLS_IGMP): parse_inner_icmp_igmp_overload_scope1;
            (5, 0, _): branch_inner_l3_protocol_scope1;
            default : accept;
       }
    }

    state parse_inner_ipv6_scope1 {

        pkt.extract(hdr.inner.ipv6);
        protocol_inner = hdr.inner.ipv6.next_hdr;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type = 0x86dd;

        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto = hdr.inner.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
        eg_md.lkp_1.ip_src_addr = hdr.inner.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr = hdr.inner.ipv6.dst_addr;
        eg_md.lkp_1.ip_len = hdr.inner.ipv6.payload_len;

        transition branch_inner_l3_protocol_scope1;
        // transition select(hdr.inner.ipv6.next_hdr) {
        //     IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload_scope1;
        //     default: branch_inner_l3_protocol_scope1;
        // }



    }

    state branch_inner_l3_protocol_scope1 {
        transition select(protocol_inner) {
           17: parse_inner_udp_scope1;
           6: parse_inner_tcp_scope1;
           0x84: parse_inner_sctp_scope1;

           47: parse_inner_gre_scope1;

           //IP_PROTOCOLS_ESP:  parse_inner_esp_overload_scope1;
           4: parse_inner_ipinip_set_tunnel_scope1;
           41: parse_inner_ipv6inip_set_tunnel_scope1;
        }
    }


//     // For ICMP and IGMP, we're not actually extracting the header;
//     // We're simply over-loading L4-port info for policy via lookahead.    
//     state parse_inner_icmp_igmp_overload_scope1 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_inner_udp_scope1 {
        pkt.extract(hdr.inner.udp);
        eg_md.lkp_1.l4_src_port = hdr.inner.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.udp.dst_port;
        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {


            (_, 2123): parse_inner_gtp_c_scope1;
            (2123, _): parse_inner_gtp_c_scope1;
            (_, 2152): parse_inner_gtp_u_scope1;
            (2152, _): parse_inner_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u_scope1;

            default: accept;
        }
    }

    state parse_inner_tcp_scope1 {
        pkt.extract(hdr.inner.tcp);
        eg_md.lkp_1.tcp_flags = hdr.inner.tcp.flags;
        eg_md.lkp_1.l4_src_port = hdr.inner.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.tcp.dst_port;
        transition accept;
    }

    state parse_inner_sctp_scope1 {
        pkt.extract(hdr.inner.sctp);
        eg_md.lkp_1.l4_src_port = hdr.inner.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.sctp.dst_port;
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_ipinip_set_tunnel_scope1 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_inner_ipv4;



    }

    state parse_inner_ipv6inip_set_tunnel_scope1 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_inner_ipv6;



    }


//     //-------------------------------------------------------------------------
//     // Encapsulating Security Payload (ESP) - Inner
//     //-------------------------------------------------------------------------
//      
//     state parse_inner_esp_overload_scope1 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //-------------------------------------------------------------------------



    state parse_inner_gre_scope1 {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (1,0,0,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (0,0,1,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (0,0,0,1,0,0,0,0): parse_inner_gre_qualified_scope1;
            default: accept;
        }
    }

    state parse_inner_gre_qualified_scope1 {
        pkt.extract(hdr.inner.gre);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;

        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.proto) {

            (0,0,0,0x0800): parse_inner_inner_ipv4;
            (0,0,0,0x86dd): parse_inner_inner_ipv6;
            (1,0,0,_): parse_inner_gre_optional;
            (0,1,0,_): parse_inner_gre_optional;
            (0,0,1,_): parse_inner_gre_optional;
            default: accept;
        }
    }

    state parse_inner_gre_optional {
        pkt.extract(hdr.inner.gre_optional);
        transition select(hdr.inner.gre.proto) {
            0x0800: parse_inner_inner_ipv4;
            0x86dd: parse_inner_inner_ipv6;
            default: accept;
        }
    }






    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Inner
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //-------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state parse_inner_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_inner_gtp_c_qualified_scope1;
            default: accept;
        }
    }

    state parse_inner_gtp_c_qualified_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
        transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_inner_gtp_u_scope1 {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_inner_gtp_u_qualified_scope1;
            (1, 1, 0, 1, 0): parse_inner_gtp_u_with_optional_qualified_scope1;
            default: accept;
        }
    }

    state parse_inner_gtp_u_qualified_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_gtp_u_with_optional_qualified_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: accept;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_inner_ipv4 {
  hdr.inner_inner.ipv4.setValid();
  transition accept;
    }
    state parse_inner_inner_ipv6 {
  hdr.inner_inner.ipv6.setValid();
  transition accept;
    }

}
# 60 "npb.p4" 2
# 1 "npb_egr_set_lkp.p4" 1




// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control EgressSetLookup(
        in switch_header_t hdr, // src
        inout switch_egress_metadata_t eg_md // dst
) {

    // -----------------------------
 // Apply
    // -----------------------------

    apply {

//		eg_md.lkp_1.next_lyr_valid = true;
  if((eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
   eg_md.lkp_1.next_lyr_valid = true;
  }

        // -----------------------------------------------------------------------

        // Override whatever the parser set "ip_type" to.  Doing so allows the
        // signal to fit when normally it doesn't.  This code should be only
        // temporary, and can be removed at a later date when a better compiler
        // is available....
        if(hdr.transport.nsh_type1.scope == 0) {
            if (hdr.outer.ipv4.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
            else if(hdr.outer.ipv6.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
            else
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        } else {
            if (hdr.inner.ipv4.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
            else if(hdr.inner.ipv6.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
            else
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        }

        // -----------------------------------------------------------------------

  // ipv6: would like to do this stuff in the parser, but can't because tos
  // field isn't byte aligned...

  // ipv4: would like to do this stuff in the parser, but get the following error:
        //   "error: Field is extracted in the parser into multiple containers, but
        //    the container slices after the first aren't byte aligned"

  if(hdr.transport.nsh_type1.scope == 0) {
   // ----- outer -----

   if(hdr.outer.ipv6.isValid()) {
    eg_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
   }

//			if(hdr.outer.ipv4.isValid()) {
//				eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//			}
  } else {
   // ----- inner -----

   if(hdr.inner.ipv6.isValid()) {
    eg_md.lkp_1.ip_tos = hdr.inner.ipv6.tos;
   }

//			if(hdr.inner.ipv4.isValid()) {
//				eg_md.lkp_1.ip_tos = hdr.inner.ipv4.tos;
//			}
  }
# 92 "npb_egr_set_lkp.p4"
    }
}
# 61 "npb.p4" 2
# 1 "npb_egr_top.p4" 1




# 1 "npb_egr_sff_top.p4" 1
control npb_egr_sff_top (
 inout switch_header_transport_t hdr_0,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table
 // =========================================================================

 // RFC 8300, Page 9: Decrementing (the TTL) from an incoming value of 0 shall
 // result in a TTL value of 63.   The handling of an incoming 0 TTL allows
 // for better, although not perfect, interoperation with pre-standard
 // implementations that do not support this TTL field.

    action new_ttl(bit<6> ttl) {
        hdr_0.nsh_type1.ttl = ttl;
    }

    action discard() {
//        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table npb_egr_sff_dec_ttl {
        key = { hdr_0.nsh_type1.ttl : exact; }
        actions = { new_ttl; discard; }
  size = 64;
        const entries = {
            0 : new_ttl(63);
//          1  : discard();
            1 : new_ttl(0);
            2 : new_ttl(1);
            3 : new_ttl(2);
            4 : new_ttl(3);
            5 : new_ttl(4);
            6 : new_ttl(5);
            7 : new_ttl(6);
            8 : new_ttl(7);
            9 : new_ttl(8);
            10 : new_ttl(9);
            11 : new_ttl(10);
            12 : new_ttl(11);
            13 : new_ttl(12);
            14 : new_ttl(13);
            15 : new_ttl(14);
            16 : new_ttl(15);
            17 : new_ttl(16);
            18 : new_ttl(17);
            19 : new_ttl(18);
            20 : new_ttl(19);
            21 : new_ttl(20);
            22 : new_ttl(21);
            23 : new_ttl(22);
            24 : new_ttl(23);
            25 : new_ttl(24);
            26 : new_ttl(25);
            27 : new_ttl(26);
            28 : new_ttl(27);
            29 : new_ttl(28);
            30 : new_ttl(29);
            31 : new_ttl(30);
            32 : new_ttl(31);
            33 : new_ttl(32);
            34 : new_ttl(33);
            35 : new_ttl(34);
            36 : new_ttl(35);
            37 : new_ttl(36);
            38 : new_ttl(37);
            39 : new_ttl(38);
            40 : new_ttl(39);
            41 : new_ttl(40);
            42 : new_ttl(41);
            43 : new_ttl(42);
            44 : new_ttl(43);
            45 : new_ttl(44);
            46 : new_ttl(45);
            47 : new_ttl(46);
            48 : new_ttl(47);
            49 : new_ttl(48);
            50 : new_ttl(49);
            51 : new_ttl(50);
            52 : new_ttl(51);
            53 : new_ttl(52);
            54 : new_ttl(53);
            55 : new_ttl(54);
            56 : new_ttl(55);
            57 : new_ttl(56);
            58 : new_ttl(57);
            59 : new_ttl(58);
            60 : new_ttl(59);
            61 : new_ttl(60);
            62 : new_ttl(61);
            63 : new_ttl(62);
        }
    }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =============================
  // SFF (continued)
  // =============================

  // -------------------------------------
  // Check TTL & SI
  // -------------------------------------

  // RFC 8300, Page 12: "an SFF that is not the terminal SFF for an SFP
  // will discard any NSH packet with an SI of 0, as there will be no
  // valid next SF information."

  if(eg_md.nsh_md.start_of_path == true) {

   // ---------------
   // add new header
   // ---------------

   // (done in ingress)

   // ---------------

   if(eg_md.nsh_md.end_of_path == true) {

    // ---------------
    // process start + end of chain
    // ---------------

    hdr_0.nsh_type1.setInvalid(); // it's the end of the line for this nsh chain....

   } else {

    // ---------------
    // process start of chain
    // ---------------

    if((hdr_0.nsh_type1.ttl == 0) || (hdr_0.nsh_type1.si == 0)) {
     eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
    }

   }


  } else {

   // ---------------
   // update existing header
   // ---------------

   npb_egr_sff_dec_ttl.apply();

   // ---------------

   if(eg_md.nsh_md.end_of_path == true) {

    // ---------------
    // process end of chain
    // ---------------

    hdr_0.nsh_type1.setInvalid(); // it's the end of the line for this nsh chain....

   } else {

    // ---------------
    // process middle of chain
    // ---------------

    if((hdr_0.nsh_type1.ttl == 0) || (hdr_0.nsh_type1.si == 0)) {
     eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
    }

   }

  }

  // -------------------------------------
  // Fowrarding Lookup
  // -------------------------------------

  // Derek: The forwarding lookup would normally
  // be done here.  However, since Tofino requires the outport
  // to set in ingress, it has to be done there instead....

 }

}
# 6 "npb_egr_top.p4" 2

# 1 "npb_egr_sf_proxy_top.p4" 1
# 1 "npb_egr_sf_proxy_hdr_strip.p4" 1

control npb_egr_sf_proxy_hdr_strip (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -----------------------------------------------------------------
 // Table
 // -----------------------------------------------------------------

 action hdr_strip_1__from_vlan_tag0__to_eth() {
  hdr_1.ethernet.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();
 }

 action hdr_strip_1__from_vlan_tag0__to_e_tag() {

  hdr_1.e_tag.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();

 }

 action hdr_strip_1__from_vlan_tag0__to_vn_tag() {

  hdr_1.vn_tag.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();

 }

 // --------------------------------

 action hdr_strip_1__from_vn_tag_____to_eth() {

  hdr_1.ethernet.ether_type = hdr_1.vn_tag.ether_type;
  hdr_1.vn_tag.setInvalid();

 }

 // --------------------------------

 action hdr_strip_1__from_e_tag______to_eth() {

  hdr_1.ethernet.ether_type = hdr_1.e_tag.ether_type;
  hdr_1.e_tag.setInvalid();

 }

 // --------------------------------

 action hdr_strip_2__from_vlan_tag0__to_eth() {
  // tag0 to eth
  hdr_1.ethernet.ether_type = hdr_1.vlan_tag[0].ether_type;

  hdr_1.e_tag.setInvalid();


  hdr_1.vn_tag.setInvalid();

  hdr_1.vlan_tag[0].setInvalid();
 }

 // --------------------------------

 bool hdr_1_e_tag_isValid;
 bool hdr_1_vn_tag_isValid;

 table hdr_strip {
  key = {

   hdr_1.e_tag.isValid() : exact;


   hdr_1.vn_tag.isValid() : exact;

   hdr_1.vlan_tag[0].isValid() : exact;
//			hdr_1.vlan_tag[1].isValid() : exact;


   eg_md.nsh_md.strip_tag_e : ternary;


   eg_md.nsh_md.strip_tag_vn : ternary;

   eg_md.nsh_md.strip_tag_vlan : ternary;
  }

  actions = {
   NoAction();
   hdr_strip_1__from_e_tag______to_eth();
   hdr_strip_1__from_vn_tag_____to_eth();
   hdr_strip_1__from_vlan_tag0__to_eth();
   hdr_strip_1__from_vlan_tag0__to_e_tag();
   hdr_strip_1__from_vlan_tag0__to_vn_tag();

   hdr_strip_2__from_vlan_tag0__to_eth();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // ==============         ==============      
   // Packet                 Enables
   // {vn/e,  vlan}          {e/vn,  vlan}
   // ==============         ==============      
   // {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
   // {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
   // {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
   // {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
   // --------------         --------------      
   // {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
   // {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
   // {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
   // {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
   // --------------         --------------      
   // {true,  false}         {false, false}          --> nothing   enabled, vn in pkt        --> no action
   // {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
   // {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
   // {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
   // --------------         --------------      
   // {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
   // {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
   // {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
   // {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)

// ipv4,	 vl[0], vn,    e,   ethernet



   // case 0 (---- + vlan delete, only vlan          are valid):
   (false, false, true, _, _, true ): hdr_strip_1__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

   // case 1 (e/vn + ---- delete, only e/vn          are valid):
   (true, false, false, true, _, _ ): hdr_strip_1__from_e_tag______to_eth(); // pkt: 0   tags + e  ==> delete e        (e    to eth)
   (false, true, false, _, true, _ ): hdr_strip_1__from_vn_tag_____to_eth(); // pkt: 0   tags + vn ==> delete vn       (vn   to eth)

   // case 2 (---  + vlan delete, both e/vn and vlan are valid):
   (true, false, true, false, _, true ): hdr_strip_1__from_vlan_tag0__to_e_tag(); // pkt: 1-2 tags + e  ==> delete vlan0    (vlan to e)
   (false, true, true, _, false, true ): hdr_strip_1__from_vlan_tag0__to_vn_tag(); // pkt: 1-2 tags + vn ==> delete vlan0    (vlan to vn)

   // case 3 (e/vn + ---- delete, both e/vn and vlan are valid):
   (true, false, true, true, _, false): hdr_strip_1__from_e_tag______to_eth(); // pkt: 1-2 tags + e  ==> delete e        (e    to eth)
   (false, true, true, _, true, false): hdr_strip_1__from_vn_tag_____to_eth(); // pkt: 1-2 tags + vn ==> delete vn       (vn   to eth)

   // case 4 (e/vn + vlan delete, both e/vn and vlan are valid): -- double delete case
   (true, false, true, true, _, true ): hdr_strip_2__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + e  ==> delete vlan0+e  (vlan to eth)
   (false, true, true, _, true, true ): hdr_strip_2__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + vn ==> delete vlan0+vn (vlan to eth)
# 193 "npb_egr_sf_proxy_hdr_strip.p4"
  }
 }

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {

   hdr_1_e_tag_isValid = hdr_1.e_tag.isValid();





   hdr_1_vn_tag_isValid = hdr_1.vn_tag.isValid();




  hdr_strip.apply();
 }

}
# 2 "npb_egr_sf_proxy_top.p4" 2
# 1 "npb_egr_sf_proxy_hdr_edit.p4" 1

control npb_egr_sf_proxy_hdr_edit (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 bit<3> pcp_ = 0;
 vlan_id_t vid_ = 0;

 bool hdr_1_ethernet_isEtypeStag;
 bool hdr_1_e_tag_isEtypeStag;
 bool hdr_1_vn_tag_isEtypeStag;

 // -----------------------------------------------------------------
 // Table: bd_to_vlan_mapping
 // -----------------------------------------------------------------

    action set_vlan_tagged(vlan_id_t vid, bit<3> pcp) {
  pcp_ = pcp;
  vid_ = vid;
    }

    table bd_to_vlan_mapping {
        key = { eg_md.nsh_md.add_tag_vlan_bd : exact @name("bd"); }
        actions = {
   set_vlan_tagged;
   NoAction;
        }

        const default_action = NoAction;
        size = 512;
    }

 // -----------------------------------------------------------------
 // Table: hdr_add
 // -----------------------------------------------------------------

 // helper action
 action hdr_add_vlan_tag(vlan_id_t vid, bit<3> pcp) {
  // copy from 0 to 1
//		hdr_1.vlan_tag[1].setValid(); // will be set by the individual actions
  hdr_1.vlan_tag[1].pcp = hdr_1.vlan_tag[0].pcp;
  hdr_1.vlan_tag[1].cfi = hdr_1.vlan_tag[0].cfi;
  hdr_1.vlan_tag[1].vid = hdr_1.vlan_tag[0].vid;
  hdr_1.vlan_tag[1].ether_type = hdr_1.vlan_tag[0].ether_type;

  // add 0
  hdr_1.vlan_tag[0].setValid(); // might already be valid, which is fine
  hdr_1.vlan_tag[0].pcp = pcp;
  hdr_1.vlan_tag[0].cfi = 0;
  hdr_1.vlan_tag[0].vid = vid;
//		hdr_1.vlan_tag[0].ether_type = ?; // will be set by the individual actions
 }

 // --------------------------------

 action hdr_add_0__from_eth_____to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.ethernet.ether_type;

  hdr_1.ethernet.ether_type = 0x8100;
 }

 action hdr_add_0__from_e_tag___to_vlan_tag0() {

  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.e_tag.ether_type;

  hdr_1.e_tag.ether_type = 0x8100;

 }

 action hdr_add_0__from_vn_tag__to_vlan_tag0() {

  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.vn_tag.ether_type;

  hdr_1.vn_tag.ether_type = 0x8100;

 }

 // --------------------------------

 action hdr_add_1__from_eth_____to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.ethernet.ether_type;

  hdr_1.ethernet.ether_type = 0x8100;
 }

 action hdr_add_1__from_e_tag___to_vlan_tag0() {

  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.e_tag.ether_type;

  hdr_1.e_tag.ether_type = 0x8100;

 }

 action hdr_add_1__from_vn_tag__to_vlan_tag0() {

  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.vn_tag.ether_type;

  hdr_1.vn_tag.ether_type = 0x8100;

 }

 // --------------------------------

 table hdr_add {
  key = {
   hdr_1_ethernet_isEtypeStag : exact;

   hdr_1.e_tag.isValid() : exact;
   hdr_1_e_tag_isEtypeStag : exact;


   hdr_1.vn_tag.isValid() : exact;
   hdr_1_vn_tag_isEtypeStag : exact;

   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;
  }

  actions = {
   NoAction();
   hdr_add_0__from_eth_____to_vlan_tag0();
   hdr_add_0__from_e_tag___to_vlan_tag0();
   hdr_add_0__from_vn_tag__to_vlan_tag0();
   hdr_add_1__from_eth_____to_vlan_tag0();
   hdr_add_1__from_e_tag___to_vlan_tag0();
   hdr_add_1__from_vn_tag__to_vlan_tag0();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // =====================
   // Packet               
   // {e/vn,  vl[0], vl[1]}
   // =====================
   // {false, false, false}   --> empty,      disabled --> no action
   // {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
   // {false, false, true }   --> impossible, disabled --> no action
   // {false, false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {false, true,  false}   --> one full,   disabled --> no action
   // {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
   // {false, true,  true }   --> both full,  disabled --> no action
   // {false, true,  true }   --> both full,  enabled  --> no action
   // ---------------------
   // {true,  false, false}   --> empty,      disabled --> no action
   // {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
   // {true,  false, true }   --> impossible, disabled --> no action
   // {true,  false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {true,  true,  false}   --> one full,   disabled --> no action
   // {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
   // {true,  true,  true }   --> both full,  disabled --> no action
   // {true,  true,  true }   --> both full,  enabled  --> no action

// eth,		e, vn, vl[0], vl[1], ipv4



   // ====   =============   =============   =====    =====
   // eth    e               vn              vl[0]    vl[1]
   // ====   =============   =============   =====    =====

   // case 0 (eth  to vlan)
   (false, false, false, false, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (false, false, true, false, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (false, false, false, false, true, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (false, false, true, false, true, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

   // case 1 (eth  to vlan)
   (false, false, false, false, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (false, false, true, false, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (false, false, false, false, true, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (false, false, true, false, true, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

   // case 2 (e/vn to vlan)
   (false, true, false, false, false, false, false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty
   (false, true, false, false, true, false, false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty

   (false, false, false, true, false, false, false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty
   (false, false, true, true, false, false, false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty

   // case 3 (e/vn to vlan)
   (false, true, false, false, false, true, false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full
   (false, true, false, false, true, true, false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full

   (false, false, false, true, false, true, false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
   (false, false, true, true, false, true, false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
# 259 "npb_egr_sf_proxy_hdr_edit.p4"
  }
 }

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
  if(hdr_1.ethernet.ether_type == 0x88a8) hdr_1_ethernet_isEtypeStag = true; else hdr_1_ethernet_isEtypeStag = false;

  if(hdr_1.e_tag.ether_type == 0x88a8) hdr_1_e_tag_isEtypeStag = true; else hdr_1_e_tag_isEtypeStag = false;


  if(hdr_1.vn_tag.ether_type == 0x88a8) hdr_1_vn_tag_isEtypeStag = true; else hdr_1_vn_tag_isEtypeStag = false;



  if(bd_to_vlan_mapping.apply().hit) {
   hdr_add.apply();
  }

 }

}
# 3 "npb_egr_sf_proxy_top.p4" 2
# 1 "npb_egr_sf_proxy_truncate.p4" 1

control npb_egr_sf_proxy_truncate (
 inout switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -----------------------------------------------------------------
 // Table
 // -----------------------------------------------------------------

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
    if(eg_md.nsh_md.truncate_enable) {

        eg_intr_md_for_dprsr.mtu_trunc_len = eg_md.nsh_md.truncate_len;

        }

 }

}
# 4 "npb_egr_sf_proxy_top.p4" 2
//#include "npb_egr_sf_proxy_meter.p4"




# 1 "acl.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 10 "npb_egr_sf_proxy_top.p4" 2

control npb_egr_sf_proxy_top (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 EgressAcl(
  EGRESS_IPV4_ACL_TABLE_SIZE,


  EGRESS_IPV6_ACL_TABLE_SIZE,

  EGRESS_MAC_ACL_TABLE_SIZE
 ) acl;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: policy
 //   [1:1] act #2: header strip
 //   [2:2] act #3: header edit
 //   [3:3] act #4: truncate
 //   [4:4] act #5: meter
 //   [5:5] act #6: dedup

 // =========================================================================
 // Table #1: Action Select
 // =========================================================================

 bit<8> int_ctrl_flags = 0;

 action egr_sf_action_sel_hit(
//		bit<6>                                                action_bitmask,



  bit<16> dsap
//		bit<NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2> action_3_meter_id,
//		bit<8>                                                action_3_meter_overhead
//		bit<3>                                                discard
 ) {
//		eg_md.action_bitmask          = action_bitmask;



  eg_md.nsh_md.dsap = dsap;

//		eg_md.action_3_meter_id       = action_3_meter_id;
//		eg_md.action_3_meter_overhead = action_3_meter_overhead;

//		eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet
 }

 // =====================================

 action egr_sf_action_sel_miss(
 ) {
//		eg_md.action_bitmask          = 0;
//		int_ctrl_flags                = 0;
//		eg_md.nsh_md.dsap             = 0;
 }

 // =====================================

 table egr_sf_action_sel {
  key = {
      hdr_0.nsh_type1.spi : exact @name("spi");
      hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   NoAction;
      egr_sf_action_sel_hit;
      egr_sf_action_sel_miss;
  }

  const default_action = egr_sf_action_sel_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #x: Ip Length Range
 // =========================================================================

 bit<16> ip_len = 0;
 bool ip_len_is_rng_bitmask = false;


 action egr_sf_ip_len_rng_hit(
  bit<16> rng_bitmask
 ) {
  ip_len = rng_bitmask;
  ip_len_is_rng_bitmask = true;
 }

 // =====================================

 action egr_sf_ip_len_rng_miss(
 ) {
  ip_len = eg_md.lkp_1.ip_len;
  ip_len_is_rng_bitmask = false;
 }

 // =====================================

 table egr_sf_ip_len_rng {
  key = {
   eg_md.lkp_1.ip_len : range @name("ip_len");
  }

  actions = {
   NoAction;
   egr_sf_ip_len_rng_hit;
   egr_sf_ip_len_rng_miss;
  }

  const default_action = egr_sf_ip_len_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Table #2: L4 Src Port Range
 // =========================================================================

 bit<16> l4_src_port = 0;
 bool l4_src_port_is_rng_bitmask = false;


 action egr_sf_l4_src_port_rng_hit(
  bit<16> rng_bitmask
 ) {
  l4_src_port = rng_bitmask;
  l4_src_port_is_rng_bitmask = true;
 }

 // =====================================

 action egr_sf_l4_src_port_rng_miss(
 ) {
  l4_src_port = eg_md.lkp_1.l4_src_port;
  l4_src_port_is_rng_bitmask = false;
 }

 // =====================================

 table egr_sf_l4_src_port_rng {
  key = {
   eg_md.lkp_1.l4_src_port : range @name("l4_src_port");
  }

  actions = {
   NoAction;
   egr_sf_l4_src_port_rng_hit;
   egr_sf_l4_src_port_rng_miss;
  }

  const default_action = egr_sf_l4_src_port_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Table #2: L4 Dst Port Range
 // =========================================================================

 bit<16> l4_dst_port = 0;
 bool l4_dst_port_is_rng_bitmask = false;


 action egr_sf_l4_dst_port_rng_hit(
  bit<16> rng_bitmask
 ) {
  l4_dst_port = rng_bitmask;
  l4_dst_port_is_rng_bitmask = true;
 }

 // =====================================

 action egr_sf_l4_dst_port_rng_miss(
 ) {
  l4_dst_port = eg_md.lkp_1.l4_dst_port;
  l4_dst_port_is_rng_bitmask = false;
 }

 // =====================================

 table egr_sf_l4_dst_port_rng {
  key = {
   eg_md.lkp_1.l4_dst_port : range @name("l4_dst_port");
  }

  actions = {
   NoAction;
   egr_sf_l4_dst_port_rng_hit;
   egr_sf_l4_dst_port_rng_miss;
  }

  const default_action = egr_sf_l4_dst_port_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  eg_md.nsh_md.dsap = 0;

  // ==================================
  // Action Lookup
  // ==================================

  if(egr_sf_action_sel.apply().hit) {

   // ==================================
   // Decrement SI
   // ==================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index




   // ==================================
   // Actions(s)
   // ==================================

//			if(eg_md.action_bitmask[0:0] == 1) {

    // ----------------------------------
    // Action #0 - Policy
    // ----------------------------------


    egr_sf_ip_len_rng.apply();





    egr_sf_l4_src_port_rng.apply();





    egr_sf_l4_dst_port_rng.apply();





    acl.apply(
     eg_md.lkp_1,
     eg_md,
     eg_intr_md_for_dprsr,
     ip_len,
     ip_len_is_rng_bitmask,
     l4_src_port,
     l4_src_port_is_rng_bitmask,
     l4_dst_port,
     l4_dst_port_is_rng_bitmask,
     hdr_0,
     hdr_1,
     int_ctrl_flags
    );
//			}

//			if(eg_md.action_bitmask[1:1] == 1) {

    // ----------------------------------
    // Action #1 - Hdr Strip
    // ----------------------------------
    npb_egr_sf_proxy_hdr_strip.apply (
     hdr_0,
     hdr_1,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

//			}

//			if(eg_md.action_bitmask[2:2] == 1) {

    // ----------------------------------
    // Action #2 - Hdr Edit
    // ----------------------------------
    npb_egr_sf_proxy_hdr_edit.apply (
     hdr_0,
     hdr_1,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

//			}

//			if(eg_md.action_bitmask[3:3] == 1) {
/*
				// ----------------------------------
				// Action #3 - Truncate
				// ----------------------------------
				npb_egr_sf_proxy_truncate.apply (
					hdr_0,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
*/
//			}

//			if(eg_md.action_bitmask[4:4] == 1) {

    // ----------------------------------
    // Action #4 - Meter
    // ----------------------------------
# 362 "npb_egr_sf_proxy_top.p4"
//			}

//			if(eg_md.action_bitmask[5:5] == 1) {

    // ----------------------------------
    // Action #5 - Deduplication
    // ----------------------------------
# 379 "npb_egr_sf_proxy_top.p4"
//			}

  }
 }
}
# 8 "npb_egr_top.p4" 2
# 1 "npb_ing_sf_npb_basic_adv_dedup.p4" 1
/* -*- P4_16 -*- */







//#define DEPTH      32w131072
//#define DEPTH_POW2 17

//#define DEPTH      32w262144
//#define DEPTH_POW2 18



// =============================================================================
// =============================================================================
// =============================================================================
// Register (Ingress & Egress Shared Code)
// =============================================================================
// =============================================================================
// =============================================================================

struct pair_t {
 bit<16> hash;
 bit<16> data;
};

// =============================================================================

// note: this register code has been structured such that multiple registers can
// be laid down, perhaps using upper bits of the hash to select between them....

control npb_dedup_reg (
 in bit<16> flowtable_hash_lo, // address
 in bit<16> flowtable_hash_hi, // data -- always 16 bits
 in bit<16> ssap,

 out bit<1> drop
) {

 // =========================================================================
 // Register Array
 // =========================================================================

 // This code works similar to how vpp's flow collector works...on a hash
 // collision, the current flow occupying the slot is simply replaced with
 // the new flow (i.e. the old flow is simply booted out of the cache).

 Register <pair_t, bit<16>>(32w65536) test_reg; // syntax seems to be <data type, index type>

 // =========================================================================

 RegisterAction<pair_t, bit<16>, bit<1>>(test_reg) register_array = { // syntax seems to be <data type, index type, return type>
  void apply(
   inout pair_t reg_value, // register entry
   out bit<1> return_value // return value
  ) {
   if(reg_value.hash == (bit<16>)flowtable_hash_hi) {
    // existing flow
    // --------
    if(reg_value.data == (bit<16>)ssap) {
     // same ssap
     // ---------
     return_value = 0; // pass packet
    } else {
     // different ssap
     // ---------
     return_value = 1; // drop packet
    }
   } else {
    // new flow (entry collision, overwrite old flow)
    // --------
    // update entry
    reg_value.hash = (bit<16>)flowtable_hash_hi;
    reg_value.data = (bit<16>)ssap;

    return_value = 0; // pass packet
   }
  }
 };

 // =========================================================================
 // Apply Block
 // =========================================================================

 apply {
  drop = register_array.execute(flowtable_hash_lo);
 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// Ingress
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup_hash (
 in switch_lookup_fields_t lkp, // for hash
 in bit<12> vpn, // for hash
 out bit<32> hash
) {
 // =========================================================================
 // Hash
 // =========================================================================





 Hash<bit<32 >>(HashAlgorithm_t.CRC32) h;


 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  // ***** hash the key *****
# 143 "npb_ing_sf_npb_basic_adv_dedup.p4"
  hash = h.get ({
   vpn,
   lkp.ip_src_addr,
   lkp.ip_dst_addr,
   lkp.ip_proto,
   lkp.l4_src_port,
   lkp.l4_dst_port
  });
 }

}

// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup (
 in bool enable,
 in switch_lookup_fields_t lkp, // for hash
 in bit<12> vpn, // for hash
 in bit<32> hash,
 in bit<16> ssap, // for dedup
 inout bit<3> drop_ctl
) {
 npb_dedup_reg() npb_dedup_reg_0;
 npb_dedup_reg() npb_dedup_reg_1;
 npb_dedup_reg() npb_dedup_reg_2;
 npb_dedup_reg() npb_dedup_reg_3;
 npb_dedup_reg() npb_dedup_reg_4;
 npb_dedup_reg() npb_dedup_reg_5;
 npb_dedup_reg() npb_dedup_reg_6;
 npb_dedup_reg() npb_dedup_reg_7;
 npb_dedup_reg() npb_dedup_reg_8;
 npb_dedup_reg() npb_dedup_reg_9;
 npb_dedup_reg() npb_dedup_reg_10;
 npb_dedup_reg() npb_dedup_reg_11;
 npb_dedup_reg() npb_dedup_reg_12;
 npb_dedup_reg() npb_dedup_reg_13;
 npb_dedup_reg() npb_dedup_reg_14;
 npb_dedup_reg() npb_dedup_reg_15;
/*
	npb_dedup_reg() npb_dedup_reg_16;
	npb_dedup_reg() npb_dedup_reg_17;
	npb_dedup_reg() npb_dedup_reg_18;
	npb_dedup_reg() npb_dedup_reg_19;
	npb_dedup_reg() npb_dedup_reg_20;
	npb_dedup_reg() npb_dedup_reg_21;
	npb_dedup_reg() npb_dedup_reg_22;
	npb_dedup_reg() npb_dedup_reg_23;
	npb_dedup_reg() npb_dedup_reg_24;
	npb_dedup_reg() npb_dedup_reg_25;
	npb_dedup_reg() npb_dedup_reg_26;
	npb_dedup_reg() npb_dedup_reg_27;
	npb_dedup_reg() npb_dedup_reg_28;
	npb_dedup_reg() npb_dedup_reg_29;
	npb_dedup_reg() npb_dedup_reg_30;
	npb_dedup_reg() npb_dedup_reg_31;
*/

 // =========================================================================

 bit<32> flowtable_hash = 0;

 bit<16> flowtable_hash_lo;
 bit<16> flowtable_hash_hi; // always 16 bits
 bit<4> flowtable_hash_chk; // always 16 bits

 bit<1> drop = 0;

 // =========================================================================
 // Hash
 // =========================================================================





 Hash<bit<32 >>(HashAlgorithm_t.CRC32) h;


 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  // ***** hash the key *****
# 246 "npb_ing_sf_npb_basic_adv_dedup.p4"
/*
		flowtable_hash    = h.get ({
			vpn,
			lkp.ip_src_addr,
			lkp.ip_dst_addr,
			lkp.ip_proto,
			lkp.l4_src_port,
			lkp.l4_dst_port
		});
		flowtable_hash_lo  = flowtable_hash[15: 0];
		flowtable_hash_hi  = flowtable_hash[31:16];
		flowtable_hash_chk = flowtable_hash[31:28];
*/
  flowtable_hash_lo = hash[15: 0];
  flowtable_hash_hi = hash[31:16];
  flowtable_hash_chk = hash[31:28];


  // note: putting the enable check around all the dedup blocks doesn't fit, so instead if disabled
  // we force it to use block 0 by setting hash_chk to 0, and then put the enable check around only that block.

  // ***** call dedup function *****
  if(enable) {
          if(flowtable_hash_chk == 0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   }

/*
			       if(flowtable_hash_chk ==  0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 16) { npb_dedup_reg_16.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 17) { npb_dedup_reg_17.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 18) { npb_dedup_reg_18.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 19) { npb_dedup_reg_19.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 20) { npb_dedup_reg_20.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 21) { npb_dedup_reg_21.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 22) { npb_dedup_reg_22.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 23) { npb_dedup_reg_23.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 24) { npb_dedup_reg_24.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 25) { npb_dedup_reg_25.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 26) { npb_dedup_reg_26.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 27) { npb_dedup_reg_27.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 28) { npb_dedup_reg_28.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 29) { npb_dedup_reg_29.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 30) { npb_dedup_reg_30.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 31) { npb_dedup_reg_31.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			}
*/
  }

  if(drop == 1) {
   drop_ctl = 0x1;
  }
 }
}

// =============================================================================
// =============================================================================
// =============================================================================
// Egress
// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sf_proxy_dedup (
 in bool enable,
 in switch_lookup_fields_t lkp, // for hash
 in bit<12> vpn, // for hash
 in bit<16> ssap, // for dedup
 inout bit<3> drop_ctl
) {
 npb_dedup_reg() npb_dedup_reg_0;
 npb_dedup_reg() npb_dedup_reg_1;
 npb_dedup_reg() npb_dedup_reg_2;
 npb_dedup_reg() npb_dedup_reg_3;
 npb_dedup_reg() npb_dedup_reg_4;
 npb_dedup_reg() npb_dedup_reg_5;
 npb_dedup_reg() npb_dedup_reg_6;
 npb_dedup_reg() npb_dedup_reg_7;
 npb_dedup_reg() npb_dedup_reg_8;
 npb_dedup_reg() npb_dedup_reg_9;
 npb_dedup_reg() npb_dedup_reg_10;
 npb_dedup_reg() npb_dedup_reg_11;
 npb_dedup_reg() npb_dedup_reg_12;
 npb_dedup_reg() npb_dedup_reg_13;
 npb_dedup_reg() npb_dedup_reg_14;
 npb_dedup_reg() npb_dedup_reg_15;
/*
	npb_dedup_reg() npb_dedup_reg_16;
	npb_dedup_reg() npb_dedup_reg_17;
	npb_dedup_reg() npb_dedup_reg_18;
	npb_dedup_reg() npb_dedup_reg_19;
	npb_dedup_reg() npb_dedup_reg_20;
	npb_dedup_reg() npb_dedup_reg_21;
	npb_dedup_reg() npb_dedup_reg_22;
	npb_dedup_reg() npb_dedup_reg_23;
	npb_dedup_reg() npb_dedup_reg_24;
	npb_dedup_reg() npb_dedup_reg_25;
	npb_dedup_reg() npb_dedup_reg_26;
	npb_dedup_reg() npb_dedup_reg_27;
	npb_dedup_reg() npb_dedup_reg_28;
	npb_dedup_reg() npb_dedup_reg_29;
	npb_dedup_reg() npb_dedup_reg_30;
	npb_dedup_reg() npb_dedup_reg_31;
*/

 // =========================================================================

 bit<32> flowtable_hash = 0;

 bit<16> flowtable_hash_lo;
 bit<16> flowtable_hash_hi; // always 16 bits
 bit<4> flowtable_hash_chk; // always 16 bits

 bit<1> drop = 0;

 // =========================================================================
 // Hash
 // =========================================================================





 Hash<bit<32 >>(HashAlgorithm_t.CRC32) h;


 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  // ***** hash the key *****
# 426 "npb_ing_sf_npb_basic_adv_dedup.p4"
  flowtable_hash = h.get ({
   vpn,
   lkp.ip_src_addr,
   lkp.ip_dst_addr,
   lkp.ip_proto,
   lkp.l4_src_port,
   lkp.l4_dst_port
  });

  flowtable_hash_lo = flowtable_hash[15: 0];
  flowtable_hash_hi = flowtable_hash[31:16];
  flowtable_hash_chk = flowtable_hash[31:28];


  // note: putting the enable check around all the dedup blocks doesn't fit, so instead if disabled
  // we force it to use block 0 by setting hash_chk to 0, and then put the enable check around only that block.

  // ***** call dedup function *****
  if(enable) {
          if(flowtable_hash_chk == 0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   } else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
   }

/*
			       if(flowtable_hash_chk ==  0) { npb_dedup_reg_0.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  1) { npb_dedup_reg_1.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  2) { npb_dedup_reg_2.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  3) { npb_dedup_reg_3.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  4) { npb_dedup_reg_4.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  5) { npb_dedup_reg_5.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  6) { npb_dedup_reg_6.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  7) { npb_dedup_reg_7.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  8) { npb_dedup_reg_8.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk ==  9) { npb_dedup_reg_9.apply (flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 10) { npb_dedup_reg_10.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 11) { npb_dedup_reg_11.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 12) { npb_dedup_reg_12.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 13) { npb_dedup_reg_13.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 14) { npb_dedup_reg_14.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 15) { npb_dedup_reg_15.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 16) { npb_dedup_reg_16.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 17) { npb_dedup_reg_17.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 18) { npb_dedup_reg_18.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 19) { npb_dedup_reg_19.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 20) { npb_dedup_reg_20.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 21) { npb_dedup_reg_21.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 22) { npb_dedup_reg_22.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 23) { npb_dedup_reg_23.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 24) { npb_dedup_reg_24.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 25) { npb_dedup_reg_25.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 26) { npb_dedup_reg_26.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 27) { npb_dedup_reg_27.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 28) { npb_dedup_reg_28.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 29) { npb_dedup_reg_29.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 30) { npb_dedup_reg_30.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			} else if(flowtable_hash_chk == 31) { npb_dedup_reg_31.apply(flowtable_hash_lo, flowtable_hash_hi, ssap, drop);
			}
*/
  }

  if(drop == 1) {
   drop_ctl = 0x1;
  }
 }
}
# 9 "npb_egr_top.p4" 2

# 1 "scoper.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 11 "npb_egr_top.p4" 2

control npb_egr_top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout switch_header_inner_inner_t hdr_3,

 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {





 TunnelDecapOuter(switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
 TunnelDecapInner(switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // -------------------------------------
  // Ingress Dedup (continued from ingress side)
  // -------------------------------------
# 74 "npb_egr_top.p4"
  // -------------------------------------
  // Set Initial Scope
  // -------------------------------------

  if(hdr_0.nsh_type1.scope == 0) {

   // do nothing
# 91 "npb_egr_top.p4"
   // outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
//			eg_md.lkp_1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE;
//			eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NONE;

  } else {

   // do nothing
# 108 "npb_egr_top.p4"
   // outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
//			eg_md.lkp_1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE;
//			eg_md.lkp_1.tunnel_inner_type = eg_md.tunnel_1.type;

  }

  // -------------------------------------
  // SF(s): Part 1 --> *** before reframing ***
  // -------------------------------------

  npb_egr_sf_multicast_top_part2.apply (
   hdr_0,
   eg_intr_md.egress_rid,
   eg_intr_md.egress_port,
   eg_md
  );

  // -------------------------------------

  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SF_ACL != 0)) {
   npb_egr_sf_proxy_top.apply (
    hdr_0,
    hdr_1,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );
  }

  // -------------------------------------
  // SFF Pkt Decap(s)
  // -------------------------------------

  // Decaps ------------------------------

  tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
  tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		TunnelDecapFixEthertype.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
  TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0);

  // -------------------------------------
  // SF(s): Part 2 --> *** after reframing ***
  // -------------------------------------
/*
		npb_egr_sf_proxy_top_part2.apply (
			hdr_0,
			hdr_1,
			eg_md,
			eg_intr_md,
			eg_intr_md_from_prsr,
			eg_intr_md_for_dprsr,
			eg_intr_md_for_oport
		);
*/
  // -------------------------------------
  // SFF Hdr Decap / Encap
  // -------------------------------------

  if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SFF != 0)) {
   npb_egr_sff_top.apply (
    hdr_0,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );
  }

 }
}
# 62 "npb.p4" 2
# 1 "npb_egr_deparser.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

# 1 "headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "npb_egr_deparser.p4" 2
# 1 "types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/
# 23 "npb_egr_deparser.p4" 2

//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.

    Mirror() mirror;


    apply {

        if (eg_intr_md_for_dprsr.mirror_type == 1) {

            mirror.emit<switch_port_mirror_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                0,
                eg_md.ingress_port,
                eg_md.bd,
                0,
                eg_md.port_lag_index,
//              eg_md.ingress_timestamp,
                (bit<32>)hdr.transport.nsh_type1.timestamp,



                eg_md.mirror.session_id
            });

        } else if (eg_intr_md_for_dprsr.mirror_type == 2) {

            mirror.emit<switch_cpu_mirror_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                0,
                eg_md.ingress_port,
                eg_md.bd,
                0,
                eg_md.port_lag_index,
                eg_md.cpu_reason
            });

        } else if (eg_intr_md_for_dprsr.mirror_type == 4) {
# 96 "npb_egr_deparser.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 3) {
# 119 "npb_egr_deparser.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 5) {
# 130 "npb_egr_deparser.p4"
        }

    }
}

//-----------------------------------------------------------------------------

control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

 EgressMirror() mirror;

    Checksum() ipv4_checksum_transport;

    Checksum() ipv4_checksum_outer;

    apply {
  mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);


        if (hdr.transport.ipv4.isValid()) {
            hdr.transport.ipv4.hdr_checksum = ipv4_checksum_transport.update({
                hdr.transport.ipv4.version,
                hdr.transport.ipv4.ihl,
                hdr.transport.ipv4.tos,
                hdr.transport.ipv4.total_len,
                hdr.transport.ipv4.identification,
                hdr.transport.ipv4.flags,
                hdr.transport.ipv4.frag_offset,
                hdr.transport.ipv4.ttl,
                hdr.transport.ipv4.protocol,
                hdr.transport.ipv4.src_addr,
                hdr.transport.ipv4.dst_addr});
        }



/*
        if (hdr.outer.ipv4.isValid()) {
            hdr.outer.ipv4.hdr_checksum = ipv4_checksum_outer.update({
                    hdr.outer.ipv4.version,
                    hdr.outer.ipv4.ihl,
                    hdr.outer.ipv4.tos,
                    hdr.outer.ipv4.total_len,
                    hdr.outer.ipv4.identification,
                    hdr.outer.ipv4.flags,
                    hdr.outer.ipv4.frag_offset,
                    hdr.outer.ipv4.ttl,
                    hdr.outer.ipv4.protocol,
                    hdr.outer.ipv4.src_addr,
                    hdr.outer.ipv4.dst_addr});
        }
*/


        // ***** TRANSPORT *****
        pkt.emit(hdr.transport.ethernet);
        pkt.emit(hdr.transport.vlan_tag);
        pkt.emit(hdr.transport.nsh_type1);


        pkt.emit(hdr.transport.ipv4);







        pkt.emit(hdr.transport.gre);
# 211 "npb_egr_deparser.p4"
        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);




  pkt.emit(hdr.cpu);


        pkt.emit(hdr.outer.e_tag);


        pkt.emit(hdr.outer.vn_tag);

        pkt.emit(hdr.outer.vlan_tag);




        pkt.emit(hdr.outer.ipv4);

        pkt.emit(hdr.outer.ipv6);

        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.sctp);

        pkt.emit(hdr.outer.vxlan);

        pkt.emit(hdr.outer.gre);
        pkt.emit(hdr.outer.gre_optional);

        pkt.emit(hdr.outer.nvgre);


        pkt.emit(hdr.outer.gtp_v1_base);
        pkt.emit(hdr.outer.gtp_v1_optional);

        pkt.emit(hdr.outer.dtel); // Egress only.







        pkt.emit(hdr.outer.dtel_report); // Egress only.
        pkt.emit(hdr.outer.dtel_switch_local_report); // Egress only.

        pkt.emit(hdr.outer.dtel_drop_report); // Egress only.

        // ***** INNER *****
        pkt.emit(hdr.inner.ethernet);
        pkt.emit(hdr.inner.vlan_tag);
        pkt.emit(hdr.inner.ipv4);

        pkt.emit(hdr.inner.ipv6);

        pkt.emit(hdr.inner.udp);
        pkt.emit(hdr.inner.tcp);
        pkt.emit(hdr.inner.sctp);

        pkt.emit(hdr.inner.gre);
        pkt.emit(hdr.inner.gre_optional);


        pkt.emit(hdr.inner.gtp_v1_base);
        pkt.emit(hdr.inner.gtp_v1_optional);


    }
}
# 63 "npb.p4" 2


# 1 "npb_ing_hdr_stack_counters.p4" 1
control IngressHdrStackCounters(
    in switch_header_t hdr
) {


    DirectCounter<bit<32>>(CounterType_t.PACKETS) cpu_hdr_cntrs;

    DirectCounter<bit<32>>(CounterType_t.PACKETS) transport_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) outer_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) inner_stack_hdr_cntrs;





    // ------------------------------------------------------------
    // local variables to support ifdefs

    // error: PHV allocation creates an invalid container action within a Tofino ALU
    // bool hdr_transport_ipv4_isValid;
    // bool hdr_transport_gre_isValid;
    // bool hdr_transport_gre_sequence_isValid;
    // bool hdr_transport_erspan_type2_isValid;

    bool hdr_outer_ipv6_isValid;
    bool hdr_inner_ipv6_isValid;

    bool hdr_inner_gtp_v1_base_isValid;
    bool hdr_inner_gtp_v1_optional_isValid;
    bool hdr_inner_gre_isValid;
    bool hdr_inner_gre_optional_isValid;




    // ------------------------------------------------------------
    // CPU Header -------------------------------------------------
    // ------------------------------------------------------------

    action bump_cpu_hdr_cntr() {
        cpu_hdr_cntrs.count();
    }

    table cpu_hdr_cntr_tbl {
        key = {
            hdr.cpu.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_cpu_hdr_cntr;
        }

        size = 2;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_cpu_hdr_cntr;
        counters = cpu_hdr_cntrs;

//         // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//             false: bump_cpu_hdr_cntr; 
//             true:  bump_cpu_hdr_cntr; 
//         }
    }





    // ------------------------------------------------------------
    // transport stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_transport_stack_hdr_cntr() {
        transport_stack_hdr_cntrs.count();
    }

    table transport_stack_hdr_cntr_tbl {
        key = {
            hdr.transport.ethernet.isValid(): exact;
            hdr.transport.vlan_tag[0].isValid(): exact;
            hdr.transport.nsh_type1.isValid(): exact;
            // hdr_transport_ipv4_isValid: exact;
            // hdr_transport_gre_isValid: exact;
            // hdr_transport_gre_sequence_isValid: exact;
            // hdr_transport_erspan_type2_isValid: exact;

            hdr.transport.ipv4.isValid(): exact;
            hdr.transport.gre.isValid(): exact;

            hdr.transport.gre_sequence.isValid(): exact;
            hdr.transport.erspan_type2.isValid(): exact;


        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_transport_stack_hdr_cntr;
        }


        size = 9;






        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_transport_stack_hdr_cntr;
        // const default_action = bump_transport_stack_unexpected_hdr_cntr;
        counters = transport_stack_hdr_cntrs;

        // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//
// #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//
//             //enet  vlan0   nsh    ipv4   gre    greSeq erspan 
// 
//             // None
//             ( false, false, false, false, false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false, true,  true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  false, false ): bump_transport_stack_hdr_cntr;
// 
//             // ERSPAN-TYPE1
//             ( true,  false, false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr;
// 
//             // ERSPAN-TYPE2
//             ( true,  false, false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
//
// #elif defined(GRE_TRANSPORT_INGRESS_ENABLE)
//
//             //enet  vlan0   nsh    ipv4   gre
// 
//             // None
//             ( false, false, false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true,  false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false, true,  true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true  ): bump_transport_stack_hdr_cntr;
// 
// #else
// 
//             //enet  vlan0   nsh
// 
//             // None
//             ( false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true  ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false ): bump_transport_stack_hdr_cntr;
// 
// #endif // #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//         }
    }


    // ------------------------------------------------------------
    // outer stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_outer_stack_hdr_cntr() {
        outer_stack_hdr_cntrs.count();
    }

    table outer_stack_hdr_cntr_tbl {
        key = {
            hdr.outer.ethernet.isValid(): exact;

            hdr.outer.e_tag.isValid(): exact;


            hdr.outer.vn_tag.isValid(): exact;

            hdr.outer.vlan_tag[0].isValid(): exact;
            hdr.outer.vlan_tag[1].isValid(): exact;

            hdr.outer.ipv4.isValid(): exact;
            hdr_outer_ipv6_isValid: exact;

            hdr.outer.udp.isValid(): exact;
            hdr.outer.tcp.isValid(): exact;
            hdr.outer.sctp.isValid(): exact;

            hdr.outer.gre.isValid(): exact;
            hdr.outer.gre_optional.isValid(): exact;

            hdr.outer.vxlan.isValid(): exact;


            hdr.outer.nvgre.isValid(): exact;

            hdr.outer.gtp_v1_base.isValid(): exact;
            hdr.outer.gtp_v1_optional.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_outer_stack_hdr_cntr;
        }

        counters = outer_stack_hdr_cntrs;

// VXLAN  NVGRE  ETAG  VNTAG
//   1      1      1     1



        size = 210; // was 190 prior to adding gre_opt

        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_outer_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // None (invalid)                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2                                                                                  
        //     ( true,  false, false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV4                                                                           
        //     ( true,  false, false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV6                                                                           
        //     ( true,  false, false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / UDP                                                                      
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / TCP                                                                       
        //     ( true,  false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / SCTP                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / GRE                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                             
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 

        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / L4 / VXLAN                                                               
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     // L2 / L3 / L4 / NVGRE
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U                                                                
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U w/ Sequence Number                                             
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // IPV4                                                                               
        //     ( false, false, false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // IPV6                                                                                
        //     ( false, false, false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / UDP                                                                            
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / TCP                                                                            
        //     ( false, false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / SCTP                                                                           
        //     ( false, false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                            
        //     // L3 / GRE                                                                            
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / VXLAN                                                                     
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / NVGRE                                                                     
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U                                                                     
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U w/ Sequence Number                                                  
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // }





// VXLAN  NVGRE  ETAG  VNTAG
//   1      1      1     0
//   1      1      0     1
# 748 "npb_ing_hdr_stack_counters.p4"
// VXLAN  NVGRE  ETAG  VNTAG
//   1      0      1     1
//   0      1      1     1        
# 1042 "npb_ing_hdr_stack_counters.p4"
// VXLAN  NVGRE  ETAG  VNTAG
//   1      0      1     0
//   1      0      0     1
//   0      1      1     0
//   0      1      0     1
# 1277 "npb_ing_hdr_stack_counters.p4"
    }


    // ------------------------------------------------------------
    // inner stack ------------------------------------------------
    // ------------------------------------------------------------

    action bump_inner_stack_hdr_cntr() {
        inner_stack_hdr_cntrs.count();
    }

    table inner_stack_hdr_cntr_tbl {
        key = {

            hdr.inner.ethernet.isValid(): exact;
            hdr.inner.vlan_tag[0].isValid(): exact;

            hdr.inner.ipv4.isValid(): exact;
            hdr.inner.ipv6.isValid(): exact;

            hdr.inner.udp.isValid(): exact;
            hdr.inner.tcp.isValid(): exact;
            hdr.inner.sctp.isValid(): exact;


            hdr.inner.gre.isValid(): exact;
            hdr.inner.gre_optional.isValid(): exact;


            hdr.inner.gtp_v1_base.isValid(): exact;
            hdr.inner.gtp_v1_optional.isValid(): exact;

        }

        actions = {
            //NoAction;
            bump_inner_stack_hdr_cntr;
        }

        counters = inner_stack_hdr_cntrs;




        size = 51; // Was 45 prior to addnig gre optional
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_inner_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   vlan0  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt gtp_v1 gtp_v1_opt
        //                                                                      
        //     // None (invalid)                                                
        //     ( false, false, false, false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2                                                             
        //     ( true,  false, false, false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3                                                        
        //     ( true,  false, true,  false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / UDP                                                  
        //     ( true,  false, true,  false, true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / TCP                                                  
        //     ( true,  false, true,  false, false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / SCTP                                                 
        //     ( true,  false, true,  false, false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / GRE                                                  
        //     ( true,  false, true,  false, false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / GRE w/ OPTIONAL                                       
        //     ( true,  false, true,  false, false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / UDP / GTP-U                                          
        //     ( true,  false, true,  false, true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / UDP / GTP-U w/ Sequence Number                       
        //     ( true,  false, true,  false, true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3                                                             
        //     ( false, false, true,  false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / UDP                                                       
        //     ( false, false, true,  false, true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / TCP                                                       
        //     ( false, false, true,  false, false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / SCTP                                                      
        //     ( false, false, true,  false, false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / GRE                                                       
        //     ( false, false, true,  false, false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / GRE w/ OPTIONAL                                            
        //     ( false, false, true,  false, false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / UDP / GTP-U                                               
        //     ( false, false, true,  false, true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / UDP / GTP-U w/ Sequence Number                            
        //     ( false, false, true,  false, true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        // 
        // }
# 1643 "npb_ing_hdr_stack_counters.p4"
    }
# 1682 "npb_ing_hdr_stack_counters.p4"
    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {

    // Stubs (for #defines)

// error: PHV allocation creates an invalid container action within a Tofino ALU
// #if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
//     hdr_transport_ipv4_isValid = hdr.transport.ipv4.isValid();
//     hdr_transport_gre_isValid = hdr.transport.gre.isValid();
// #else
//     hdr_transport_ipv4_isValid = false;
//     hdr_transport_gre_isValid = false;
// #endif // defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
//         
// #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//     hdr_transport_gre_sequence_isValid = hdr.transport.gre_sequence.isValid();
//     hdr_transport_erspan_type2_isValid = hdr.transport.erspan_type2.isValid();
// #else
//     hdr_transport_gre_sequence_isValid = false;
//     hdr_transport_erspan_type2_isValid = false;
// #endif // ERSPAN_TRANSPORT_INGRESS_ENABLE



        hdr_outer_ipv6_isValid = hdr.outer.ipv6.isValid();
        hdr_inner_ipv6_isValid = hdr.inner.ipv6.isValid();







        hdr_inner_gtp_v1_base_isValid = hdr.inner.gtp_v1_base.isValid();
        hdr_inner_gtp_v1_optional_isValid = hdr.inner.gtp_v1_optional.isValid();






        hdr_inner_gre_isValid = hdr.inner.gre.isValid();
        hdr_inner_gre_optional_isValid = hdr.inner.gre_optional.isValid();







        // Tables

        cpu_hdr_cntr_tbl.apply();

        transport_stack_hdr_cntr_tbl.apply();
        outer_stack_hdr_cntr_tbl.apply();
        inner_stack_hdr_cntr_tbl.apply();



    }

}
# 66 "npb.p4" 2


@pa_auto_init_metadata
@pa_no_overlay("ingress", "hdr.transport.ipv4.src_addr")
@pa_no_overlay("ingress", "hdr.transport.ipv4.dst_addr")
@pa_atomic("ingress" , "ig_md.lkp_1.ip_type")
@pa_atomic("ingress" , "ig_md.lkp_2.ip_type")
@pa_atomic("egress" , "eg_md.bypass")
@pa_solitary("egress" , "eg_md.lkp_1.ip_flags")
@pa_container_size("egress" , "protocol_outer_0" , 8)
@pa_container_size("egress" , "protocol_inner_0" , 8)
@pa_container_size("egress" , "eg_md.lkp_1.tcp_flags", 8)

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchIngress(
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // ---------------------------------------------------------------------

 IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE, PORT_TABLE_SIZE, VLAN_TABLE_SIZE) ingress_port_mapping;






 DMAC(MAC_TABLE_SIZE) dmac;

//	IngressBd(BD_TABLE_SIZE) bd_stats;
//	IngressUnicast(RMAC_TABLE_SIZE) unicast;
 Ipv4Hash() ipv4_hash;
 Ipv6Hash() ipv6_hash;
 NonIpHash() non_ip_hash;
// 	IngressIpAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
 IngressMirrorMeter() ingress_mirror_meter;
//	IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
 Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
 OuterFib(OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
 LAG() lag;
   IngressDtel() dtel;

 // ---------------------------------------------------------------------

 apply {

  ig_intr_md_for_dprsr.drop_ctl = 0; // no longer present in latest switch.p4
  ig_md.multicast.id = 0; // no longer present in latest switch.p4
# 145 "npb.p4"
  IngressSetLookup.apply(hdr, ig_md); // set lookup structure fields that parser couldn't


  IngressHdrStackCounters.apply(hdr);


  // -----------------------------------------------------
# 169 "npb.p4"
  ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

//		unicast.apply(hdr.transport, ig_md);


  if((ig_md.flags.rmac_hit == false) && (ig_md.nsh_md.l2_fwd_en == true)) {
   // ----- Bridging Path -----

 // the new parser puts bridging in outer

   dmac.apply(ig_md.lkp_1.mac_dst_addr, ig_md);




  } else {
   // ----- NPB Path -----

   npb_ing_top.apply (
    hdr.transport,
    ig_md.tunnel_0,
    hdr.outer,
    ig_md.tunnel_1,
    hdr.inner,
    ig_md.tunnel_2,
    hdr.inner_inner,
    hdr.udf,

    ig_md,
    ig_intr_md,
    ig_intr_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );

  }


  ingress_mirror_meter.apply(ig_md);


  // if lag hash masking enabled, move this before the hash
  nexthop.apply(ig_md);
  outer_fib.apply(ig_md);

  HashMask.apply(ig_md.lkp_1, ig_md.nsh_md.lag_hash_mask_en);

  if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
   non_ip_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  } else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
   ipv4_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  } else {
   ipv6_hash.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  }
# 231 "npb.p4"
  hdr.transport.nsh_type1.lag_hash = ig_md.hash[32 -1:32/2];


  if (ig_md.egress_port_lag_index == SWITCH_FLOOD) {
  } else {
//			lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
   lag.apply(ig_md, ig_md.hash[32 -1:32/2], ig_intr_md_for_tm.ucast_egress_port);
  }

  // Only add bridged metadata if we are NOT bypassing egress pipeline.
  if (ig_intr_md_for_tm.bypass_egress == 1w0) {
   add_bridged_md(hdr.bridged_md, ig_md);
  }




  set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
# 260 "npb.p4"
 }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchEgress(
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -------------------------------------------------------------------------

 EgressSetLookup() egress_set_lookup;
 EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
 EgressMirrorMeter() egress_mirror_meter;
 VlanDecap() vlan_decap;
 Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
 TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
 TunnelRewrite() tunnel_rewrite;
 VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
//	NSHTypeFixer() nsh_type_fixer;
//	MulticastReplication(RID_TABLE_SIZE) multicast_replication;
 MulticastReplication(NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE) multicast_replication;
   EgressDtel() dtel;
   DtelConfig() dtel_config;

 // -------------------------------------------------------------------------

 apply {

//		eg_intr_md_for_dprsr.drop_ctl = 0;
  eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];

  egress_set_lookup.apply(hdr, eg_md); // set lookup structure fields that parser couldn't

  egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);

  if (eg_md.flags.bypass_egress == false) {
   multicast_replication.apply (
    hdr.transport,
    eg_intr_md.egress_rid,
    eg_intr_md.egress_port,
    eg_md
   );




   if((eg_md.flags.rmac_hit == false) && (eg_md.nsh_md.l2_fwd_en == true)) {
    // do nothing (bridging the packet)
   } else {

    npb_egr_top.apply (
     hdr.transport,
     eg_md.tunnel_0,
     hdr.outer,
     eg_md.tunnel_1,
     hdr.inner,
     eg_md.tunnel_2,
     hdr.inner_inner,

     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

   }


   egress_mirror_meter.apply(eg_md);

   // ----- nexthop               code: operates on 'outer' ----
   rewrite.apply(hdr.outer, eg_md, eg_md.tunnel_0);
//			npb_egr_sf_proxy_hdr_strip.apply(hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
//			npb_egr_sf_proxy_hdr_edit.apply (hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

   // ---- outer nexthop (tunnel) code: operates on 'transport' ----
   vlan_decap.apply(hdr.transport, eg_md);
   tunnel_encap.apply(hdr.transport, hdr.outer, eg_md, eg_md.tunnel_0);
   tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
   if (eg_md.tunnel_0.type != SWITCH_TUNNEL_TYPE_NONE) { // derek added this check
    vlan_xlate.apply(hdr.transport, eg_md);
   }





  }
  set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);


 }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

Pipeline(
        NpbIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        NpbEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
