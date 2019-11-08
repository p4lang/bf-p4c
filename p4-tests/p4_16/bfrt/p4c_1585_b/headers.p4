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
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------

#ifndef _P4_HEADERS_
#define _P4_HEADERS_

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

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

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
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

// Router Alert IP option -- RFC 2113, RFC 2711
header router_alert_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header opaque_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
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

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// RDMA over Converged Ethernet (RoCEv2)
header rocev2_bth_h {
    bit<8> opcodee;
    bit<1> se;
    bit<1> migration_req;
    bit<2> pad_count;
    bit<4> transport_version;
    bit<16> partition_key;
    bit<1> f_res1;
    bit<1> b_res1;
    bit<6> reserved;
    bit<24> dst_qp;
    bit<1> ack_req;
    bit<7> reserved2;
    // ...
}

// Fiber Channel over Ethernet (FCoE)
header fcoe_fc_h {
    bit<4> version;
    bit<100> reserved;
    bit<8> sof;        // Start of frame

    bit<8> r_ctl;      // Routing control
    bit<24> d_id;      // Destination identifier
    bit<8> cs_ctl;     // Class specific control
    bit<24> s_id;      // Source identifier
    bit<8> type;
    bit<24> f_ctl;     // Frame control
    bit<8> seq_id;
    bit<8> df_ctl;
    bit<16> seq_cnt;   // Sequence count
    bit<16> ox_id;     // Originator exchange id
    bit<16> rx_id;     // Responder exchange id
    // ...
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
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

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}

// cmace - redefined ERSPAN in npb_headers.p4
//
//// ERSPAN Type II -- IETFv3
//header erspan_type2_h {
//    bit<4> version;
//    bit<12> vlan;
//    bit<6> cos_en_t;
//    bit<10> session_id;
//    bit<12> reserved;
//    bit<20> index;
//}
//
//// ERSPAN Type III -- IETFv3
//header erspan_type3_h {
//    bit<4> version;
//    bit<12> vlan;
//    bit<6> cos_bso_t;
//    bit<10> session_id;
//    bit<32> timestamp;
//    bit<16> sgt;    // Security group tag
//    bit<1>  p;
//    bit<5> ft;      // Frame type
//    bit<6> hw_id;
//    bit<1> d;       // Direction
//    bit<2> gra;     // Timestamp granularity
//    bit<1> o;       // Optional sub-header
//}
//
//// ERSPAN platform specific subheader -- IETFv3
//header erspan_platform_h {
//    bit<6> id;
//    bit<58> info;
//}

// Generic Network Virtualization Encapsulation (Geneve)
header geneve_h {
    bit<2> version;
    bit<6> opt_len;
    bit<1> oam;
    bit<1> critical;
    bit<6> reserved;
    bit<16> proto_type;
    bit<24> vni;
    bit<8> reserved2;
}

header geneve_option_h {
    bit<16> opt_class;
    bit<8> opt_type;
    bit<3> reserved;
    bit<5> opt_len;
}

// Bidirectional Forwarding Detection (BFD) -- RFC 5880
header bfd_h {
    bit<3> version;
    bit<5> diag;
    bit<8> flags;
    bit<8> detect_multi;
    bit<8> len;
    bit<32> my_discriminator;
    bit<32> your_discriminator;
    bit<32> desired_min_tx_interval;
    bit<32> req_min_rx_interval;
    bit<32> req_min_echo_rx_interval;
}

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

// DTel drop report header
header dtel_drop_report_h {
    bit<16> ingress_port;
    bit<16> egress_port;
    bit<8> queue_id;
    bit<8> drop_reason;
    bit<16> reserved;
}

// DTel switch local report header
header dtel_switch_local_report_h {
    bit<16> ingress_port;
    bit<16> egress_port;
    bit<8> queue_id;
    bit<24> queue_occupancy;
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

// Optional metadata present in the telemetry report.
struct dtel_report_metadata_0 {
    bit<16> ingress_port;
    bit<16> egress_port;
}

struct dtel_report_metadata_2 {
    bit<8> queue_id;
    bit<24> queue_occupancy;
}

struct dtel_report_metadata_3 {
    bit<32> timestamp;
}

struct dtel_report_metadata_4 {
    bit<8> queue_id;
    bit<8> drop_reason;
    bit<16> reserved;
}

// Barefoot Specific Headers.
// Fabric header
header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
    bit<16> dst_port_or_group;
}

// CPU header
header cpu_h {
    bit<5> egress_queue;
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<16> ingress_port;
    bit<16> ingress_ifindex;
    bit<16> ingress_bd;
    bit<16> reason_code; // Also used as a 16-bit bypass flag.
    bit<16> ether_type;
}

header timestamp_h {
    bit<48> timestamp;
}

// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// Extreme Added
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------

#define TENANT_ID_WIDTH            16
#define FLOW_TYPE_WIDTH             8
#define SRVC_FUNC_CHAIN_WIDTH       8
#define NSH_RSVD_WIDTH             32  // NSH must be multiple of 4B

//////////////////////////////////////////////////////////////
// Underlay Headers
//////////////////////////////////////////////////////////////

header ethernet_tagged_h {  // for snooping
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;

    bit<3> tag_pcp;
    bit<1> tag_cfi;
    vlan_id_t tag_vid;
    bit<16> ether_type_tag;
}

//-----------------------------------------------------------
// SPBM
//-----------------------------------------------------------

header spbm_h {
    bit<3>  pcp;
    bit<1>  dei;
    bit<1>  uca;
    bit<1>  res1;
    bit<2>  res2;
    bit<24> isid;
}

// header spbm_snoop_h {
//     mac_addr_t b_dst_addr;
//     mac_addr_t b_src_addr;
//     bit<16> b_ether_type;
//     bit<3> b_pcp;
//     bit<1> b_cfi;
//     vlan_id_t b_vid;
//     bit<16> i_ether_type;
//     //bit<3>  i_pcp;
//     //bit<1>  i_dei;
//     //bit<1>  i_uca;
//     //bit<1>  i_res1;
//     //bit<2>  i_res2;
//     //bit<24> i_isid;
// }

header erspan_type1_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// ERSPAN Type2 -- IETFv3
header erspan_type2_h {
    bit<32> seq_num;
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// Barefoot ERSPAN Type3 header is incomplete. Let's
// redefine it here (and use this one instead).

// ERSPAN Type3 -- IETFv3
header erspan_type3_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_bso_t;
    bit<10> session_id;
    bit<32> timestamp;
    bit<16> sgt;        // Security group tag
    bit<1> p;
    bit<5> ft;          // Frame type
    bit<6> hw_id;
    bit<1> d;           // Direction
    bit<2> gra;         // Timestamp granularity
    bit<1> o;           // Optional sub-header
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}

//-----------------------------------------------------------
// NSH
//-----------------------------------------------------------

// NSH Base Header
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

// NSH Service Path Header
header nsh_svc_path_h {
    bit<24> spi;
    bit<8> si;
}

// NSH MD Type1 (Fixed Length) Context Header
header nsh_md1_context_h {
    bit<128> md;
}

/*
// NSH MD Type2 (Variable Length) Context Header(s)
header nsh_md2_context_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
    varbit<1024> md; // (2^7)*8
}
*/

// fixed sized version of this is needed for lookahead
header nsh_md2_context_fixed_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
}

// Single, Fixed Sized Extreme NSH Header
header nsh_extr_h {
    // word 0: base word 0
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;

    // word 1: base word 1
    bit<24> spi;
    bit<8> si;

    // word 2: ext type 2 word 0
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved3;
    bit<7> md_len;

    // word 3: ext type 2 word 1
    bit<8>  extr_srvc_func_bitmask;       //  1 byte
    bit<TENANT_ID_WIDTH> extr_tenant_id;  //  2 bytes
    bit<FLOW_TYPE_WIDTH> extr_flow_type;  //  1 byte?

    // word 4: ext type 2 word 2
#if NSH_RSVD_WIDTH>0
    bit<NSH_RSVD_WIDTH> extr_rsvd;        //  3 bytes
#endif

//  bit<160> md_extr; // 20Byte fixed Extreme MD
//  bit<120> md_extr; // 20Byte fixed Extreme MD
}

// Single, Fixed Sized Extreme NSH Header
struct nsh_extr_internal_lkp_t {
    // metadata
    bit<1>               valid;        // set by sfc or incoming packet
    bit<1>               end_of_chain; // set by sff

    // word 0: base word 0

    // word 1: base word 1
    bit<24> spi;
    bit<8>  si;

    // word 2: ext type 2 word 0

    // word 3: ext type 2 word 1
    bit<8>               extr_srvc_func_bitmask_local;  //  1 byte
    bit<8>               extr_srvc_func_bitmask_remote; //  1 byte
    bit<TENANT_ID_WIDTH> extr_tenant_id;                //  2 bytes
    bit<FLOW_TYPE_WIDTH> extr_flow_type;                //  1 byte?
}

//////////////////////////////////////////////////////////////
// Layer2 Headers
//////////////////////////////////////////////////////////////

header e_tag_h {
    bit<3>  pcp;
    bit<1>  dei;
    bit<12> ingress_cid_base;
    bit<2>  rsvd_0;
    bit<2>  grp;
    bit<12> cid_base;
    bit<16> rsvd_1;
    bit<16> ether_type;
}

header vn_tag_h {
    bit<1>  dir;
    bit<1>  ptr;
    bit<14> dvif_id;
    bit<1>  loop;
    bit<3>  rsvd;
    bit<12> svif_id;
    bit<16> ether_type;
}

//////////////////////////////////////////////////////////////
// Layer3 Headers
//////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////
// Layer4 Headers
//////////////////////////////////////////////////////////////

header sctp_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> verifTag;
    bit<32> checksum;
}

//////////////////////////////////////////////////////////////
// LayerX Headers
//////////////////////////////////////////////////////////////

// (end of) MPLS pseudo wire control word (RFC 4448)
header mpls_pw_cw_h {
    bit<4>   zeros;
    bit<12>  rsvd;
    bit<16>  seqNum;
}

//////////////////////////////////////////////////////////////
// Tunnel Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// IPsec - ESP
//-----------------------------------------------------------

header esp_h {
    bit<32> spi;
    bit<32> seq_num;
}

//-----------------------------------------------------------
// GTP
//-----------------------------------------------------------

header gtp_v1_base_h {
    bit<3>  version;
    bit<1>  PT;
    bit<1>  reserved;
    bit<1>  E;
    bit<1>  S;
    bit<1>  PN;
    bit<8>  msg_type;
    bit<16> msg_len;
    bit<32> TEID;
}

header gtp_v1_optional_h {
    bit<16>  seq_num;
    bit<8>   n_pdu_num;
    bit<8>   next_ext_hdr_type;
}

/*
header gtp_v1_extension_h {
    bit<8> ext_len;
    varbit<8192> contents;
    bit<8> next_ext_hdr;
}
*/

header gtp_v2_base_h {
    bit<3>  version;
    bit<1>  P;
    bit<1>  T;
    bit<3>  reserved;
    bit<8>  msg_type;
    bit<16> msg_len;
}
header gtp_v2_optional_teid_h {
    bit<32> teid;
}

#endif /* _P4_HEADERS_ */
