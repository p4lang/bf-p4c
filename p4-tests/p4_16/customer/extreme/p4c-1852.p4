# 1 "npb.p4"
# 1 "<command-line>"
# 1 "npb.p4"
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

// Custom profiles.
# 32 "npb.p4"

#include <tna.p4>       /* TOFINO1_ONLY */


# 1 "features.p4" 1
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

// ***** ORIGINAL SWITCH DEFINES -- FOR REFERENCE  *****
// ***** (what barefoot initially had them set to) *****

/*
// #define ACL_REDIRECT_ENABLE
// #define BRIDGE_PORT_ENABLE
#define COPP_ENABLE

#if __TARGET_TOFINO__ == 1
#define DTEL_ENABLE
#define DTEL_QUEUE_REPORT_ENABLE
#define DTEL_DROP_REPORT_ENABLE
#define DTEL_FLOW_REPORT_ENABLE
#define DTEL_ACL_ENABLE
#endif

// #define ECN_ACL_ENABLE
// #define EGRESS_ACL_ENABLE
#define EGRESS_PORT_MIRROR_ENABLE
#define ERSPAN_ENABLE
#define ERSPAN_TYPE2_ENABLE
#define INGRESS_POLICER_ENABLE
#define INGRESS_PORT_MIRROR_ENABLE
// #define IPINIP_ENABLE
#define IPV6_ENABLE
// #define IPV6_TUNNEL_ENABLE
#define L4_PORT_LOU_ENABLE
// #define MAC_PACKET_CLASSIFICATION
#define MIRROR_ENABLE
#define MIRROR_ACL_ENABLE
// #define MLAG_ENABLE
#define MULTICAST_ENABLE
#define PACKET_LENGTH_ADJUSTMENT
// #define PBR_ENABLE
// #define PTP_ENABLE
// #define QINQ_ENABLE
// #define QINQ_RIF_ENABLE
#define QOS_ENABLE
// #define QOS_ACL_ENABLE
#define RACL_ENABLE
#define STORM_CONTROL_ENABLE
// #define STP_ENABLE
// #define TCP_FLAGS_LOU_ENABLE
// #define TUNNEL_ENABLE
// #define UNICAST_SELF_FORWARDING_CHECK
// #define VXLAN_ENABLE
// #define WRED_ENABLE
*/

// ==========================================================
// ==========================================================
// ==========================================================
// Tofino 1
// ==========================================================
// ==========================================================
// ==========================================================





// ==========================================================
// With Tunneling, Without Dedup
// ==========================================================



// #define ACL_REDIRECT_ENABLE
// #define BRIDGE_PORT_ENABLE
# 104 "features.p4"
// #define ECN_ACL_ENABLE
// #define EGRESS_ACL_ENABLE





// (below)
// (below)
// #define IPV6_TUNNEL_ENABLE

// #define MAC_PACKET_CLASSIFICATION


// #define MLAG_ENABLE


// #define PBR_ENABLE
// #define PTP_ENABLE
// #define  QINQ_ENABLE
// #define  QINQ_RIF_ENABLE

// #define QOS_ACL_ENABLE


// #define STP_ENABLE
// #define TCP_FLAGS_LOU_ENABLE

// #define  UNICAST_SELF_FORWARDING_CHECK
// (below)
// #define WRED_ENABLE






// -----------------------------
// Extreme Networks Additions
// -----------------------------




//#define MPLS_ENABLE

//#define SPBM_ENABLE

// define for a single sfc table (useful for fitting in Tofino 1)



// define for selecting simple tables, rather than action_selectors/action_profiles tables -- only used if _ONE_TABLE and _TWO_TABLES are undefined.



// define for action selector, undef for action_profile -- only used if _SIMPLE is undefined.



// per header stack counters for debug


// define so that you don't have to program up any tables to get a packet through (for debug only!)


// define for simultaneous switch and npb functionality (undefine for npb only)
# 40 "npb.p4" 2
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

@pa_container_size("ingress", "hdr.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.ethernet.$valid", 16)
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
    bit<8> sof; // Start of frame

    bit<8> r_ctl; // Routing control
    bit<24> d_id; // Destination identifier
    bit<8> cs_ctl; // Class specific control
    bit<24> s_id; // Source identifier
    bit<8> type;
    bit<24> f_ctl; // Frame control
    bit<8> seq_id;
    bit<8> df_ctl;
    bit<16> seq_cnt; // Sequence count
    bit<16> ox_id; // Originator exchange id
    bit<16> rx_id; // Responder exchange id
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

// -------------------------------------
// Extreme Networks - Changed
// -------------------------------------
// - redfined ERSPAN in npb_headers.p4
/*
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
    bit<16> sgt;    // Security group tag
    bit<1>  p;
    bit<5> ft;      // Frame type
    bit<6> hw_id;
    bit<1> d;       // Direction
    bit<2> gra;     // Timestamp granularity
    bit<1> o;       // Optional sub-header
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}
*/

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
    bit<7> pad0;
    bit<9> ingress_port;
    bit<7> pad1;
    bit<9> egress_port;
    bit<3> pad2;
    bit<5> queue_id;
    bit<8> drop_reason;
    bit<16> reserved;
}

// DTel switch local report header
header dtel_switch_local_report_h {
    bit<7> pad0;
    bit<9> ingress_port;
    bit<7> pad1;
    bit<9> egress_port;
    bit<3> pad2;
    bit<5> queue_id;
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
//    bit<16> ifindex;
//    bit<16> bd;
//    bit<16> reason_code; // Also used as a 16-bit bypass flag.
//    bit<16> ether_type;
//}

header timestamp_h {
    bit<48> timestamp;
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Extreme Networks - Added
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------







//////////////////////////////////////////////////////////////
// Underlay Headers
//////////////////////////////////////////////////////////////

header ethernet_tagged_h { // for snooping
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
    bit<3> pcp;
    bit<1> dei;
    bit<1> uca;
    bit<1> res1;
    bit<2> res2;
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

// Single, Fixed Sized Extreme NSH Header (external)
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
    bit<8> extr_srvc_func_bitmask; //  1 byte
    bit<16> extr_tenant_id; //  2 bytes **see note below
    bit<8> extr_flow_type; //  1 byte?

    // word 4: ext type 2 word 2

    bit<32> extr_rsvd; //  3 bytes


//  bit<160> md_extr; // 20Byte fixed Extreme MD
//  bit<120> md_extr; // 20Byte fixed Extreme MD
}

// Single, Fixed Sized Extreme NSH Header (internal)
struct nsh_extr_internal_lkp_t {
    // metadata
    bit<1> valid; // set by sfc or incoming packet
    bit<1> end_of_chain; // set by sff

    // word 0: base word 0

    // word 1: base word 1
    bit<24> spi;
    bit<8> si;

    // word 2: ext type 2 word 0

    // word 3: ext type 2 word 1
    bit<8> extr_srvc_func_bitmask_local; //  1 byte
    bit<8> extr_srvc_func_bitmask_remote; //  1 byte
    bit<16> extr_tenant_id; //  2 bytes **see note below
    bit<8> extr_flow_type; //  1 byte?
}

// ** Note: tenant id definition, from draft-wang-sfc-nsh-ns-allocation-00:
//
// Tenant ID: The tenant identifier is used to represent the tenant or security
// policy domain that the Service Function Chain is being applied to. The Tenant
// ID is a unique value assigned by a control plane. The distribution of Tenant
// ID's is outside the scope of this document. As an example application of
// this field, the first node on the Service Function Chain may insert a VRF
// number, VLAN number, VXLAN VNI or a policy domain ID.

//////////////////////////////////////////////////////////////
// Layer2 Headers
//////////////////////////////////////////////////////////////

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
    bit<4> zeros;
    bit<12> rsvd;
    bit<16> seqNum;
}

//////////////////////////////////////////////////////////////
// Layer7 Headers (aka UDF)
//////////////////////////////////////////////////////////////

header udf_h {
    bit<88> opaque;
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
    bit<3> version;
    bit<1> PT;
    bit<1> reserved;
    bit<1> E;
    bit<1> S;
    bit<1> PN;
    bit<8> msg_type;
    bit<16> msg_len;
//  bit<32> TEID;
}

header gtp_v2_base_h {
    bit<3> version;
    bit<1> P;
    bit<1> T;
    bit<3> reserved;
    bit<8> msg_type;
    bit<16> msg_len;
}

header gtp_v1_v2_teid_h {
    bit<32> teid;
}

header gtp_v1_optional_h {
    bit<16> seq_num;
    bit<8> n_pdu_num;
    bit<8> next_ext_hdr_type;
}

/*
header gtp_v1_extension_h {
    bit<8> ext_len;
    varbit<8192> contents;
    bit<8> next_ext_hdr;
}
*/
# 41 "npb.p4" 2
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
# 38 "types.p4"
//#define ETHERTYPE_QINQ 0x88A8 // Note: uncomment once ptf/scapy-vxlan are fixed

// -------------------------------------
// Extreme Networks - Added
// -------------------------------------


//#define ETHERTYPE_VN   0x892F
# 58 "types.p4"
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
# 69 "types.p4"
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
# 82 "types.p4"
//#define MPLS_DEPTH 3 // extreme modified



// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

typedef QueueId_t switch_qid_t;

typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<3> switch_ingress_cos_t;

typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;

typedef bit<16> switch_ifindex_t;
const switch_ifindex_t SWITCH_IFINDEX_FLOOD = 16w0xffff;

typedef bit<10> switch_port_lag_index_t;
typedef bit<16> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf

typedef bit<16> switch_vrf_t;



typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;

typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_port_lag_label_t;
typedef bit<16> switch_bd_label_t;
typedef bit<16> switch_if_label_t;

typedef bit<10> switch_rmac_group_t;
typedef bit<16> switch_smac_index_t;

typedef bit<16> switch_mtu_t;

typedef bit<12> switch_stats_index_t;

typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    bit<9> port;
}


typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
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
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_LEARNING = 56;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_BLOCKING = 57;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_MTU_CHECK_FAIL = 70;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_METER = 72;
const switch_drop_reason_t SWITCH_DROP_REASON_WRED = 73;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_RACL_DENY = 81;
const switch_drop_reason_t SWITCH_DROP_REASON_URPF_CHECK_FAIL = 82;
const switch_drop_reason_t SWITCH_DROP_REASON_IPSG_MISS = 83;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_YELLOW = 85;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_RED = 86;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_YELLOW = 87;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_RED = 88;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_NON_IP_ROUTER_MAC = 94;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV6_DISABLE = 100;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_VERSION_INVALID = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_OAM = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_TTL_ZERO = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_LEN_INVALID = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_MDTYPE_INVALID = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_NEXT_PROTO_INVALID = 115;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_SI_ZERO = 116;
const switch_drop_reason_t SWITCH_DROP_REASON_UNDERLAY_NSH_MD_LEN_INVALID = 117;

typedef bit<1> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

// Bypass flags ---------------------------------------------------------------
typedef bit<16> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 16w0x0001;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 16w0x0002;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 16w0x0004;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 16w0x0008;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 16w0x0010;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_POLICER = 16w0x0020;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x0040;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x0080;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x0100;

// Add more ingress bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;


typedef bit<8> switch_egress_bypass_t;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_REWRITE = 8w0x01;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_ACL = 8w0x02;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_SYSTEM_ACL = 8w0x04;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_QOS = 8w0x08;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_WRED = 8w0x10;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_STP = 8w0x20;
const switch_egress_bypass_t SWITCH_EGRESS_BYPASS_MTU = 8w0x40;

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

// LOU ------------------------------------------------------------------------

typedef bit<16> switch_l4_port_label_t;

// STP ------------------------------------------------------------------------
typedef bit<2> switch_stp_state_t;
const switch_stp_state_t SWITCH_STP_STATE_FORWARDING = 0;
const switch_stp_state_t SWITCH_STP_STATE_BLOCKING = 1;
const switch_stp_state_t SWITCH_STP_STATE_LEARNING = 2;

typedef bit<10> switch_stp_group_t;

struct switch_stp_metadata_t {
    switch_stp_group_t group;
    switch_stp_state_t state_;
}

// Metering -------------------------------------------------------------------

typedef bit<8> switch_copp_meter_id_t;


typedef bit<10> switch_policer_meter_index_t;


// QoS ------------------------------------------------------------------------
typedef bit<2> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_PCP = 2;

typedef bit<5> switch_qos_group_t;


typedef bit<8> switch_tc_t;
typedef bit<3> switch_cos_t;

struct switch_qos_metadata_t {
    switch_qos_trust_mode_t trust_mode; // Ingress only.
    switch_qos_group_t group;
    switch_tc_t tc;
    switch_pkt_color_t color;
    switch_policer_meter_index_t meter_index; // Ingress only.
    switch_qid_t qid;
    switch_ingress_cos_t icos; // Ingress only.
    bit<19> qdepth; // Egress only.
}

// Learning -------------------------------------------------------------------
typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;

struct switch_learning_digest_t {
    switch_bd_t bd;
    switch_ifindex_t ifindex;
    mac_addr_t src_addr;
}

struct switch_learning_metadata_t {
    switch_learning_mode_t bd_mode;
    switch_learning_mode_t port_mode;
    switch_learning_digest_t digest;
}

// Multicast ------------------------------------------------------------------
typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
    switch_multicast_rpf_group_t rpf_group;
}

// URPF -----------------------------------------------------------------------
typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;

// WRED/ECN -------------------------------------------------------------------

typedef bit<8> switch_wred_index_t;
typedef bit<12> switch_wred_stats_index_t;

typedef bit<2> switch_ecn_codepoint_t;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_NON_ECT = 0b00; // Non ECN-capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT0 = 0b10; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT1 = 0b01; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_CE = 0b11; // Congestion encountered

// Mirroring ------------------------------------------------------------------
typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<8> switch_mirror_type_t;






// Common metadata used for mirroring.
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
}

header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;

    bit<6> _pad;

    switch_mirror_session_t session_id;

}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<7> _pad;
    switch_port_t port;
    switch_bd_t bd;
    switch_ifindex_t ifindex;
    switch_cpu_reason_t reason_code;
}

// Tunneling ------------------------------------------------------------------
enum switch_tunnel_mode_t { PIPE, UNIFORM }
typedef bit<3> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MACINMAC = 3; // extreme added
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 4; // extreme added
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPC = 5; // extreme added
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPU = 6; // extreme added

enum switch_tunnel_term_mode_t { P2P, P2MP };




typedef bit<16> switch_tunnel_index_t;
//typedef bit<24> switch_tunnel_id_t; // extreme changed (gtp uses 32 bitss)
typedef bit<32> switch_tunnel_id_t; // extreme changed (gtp uses 32 bitss)

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index;
    switch_tunnel_id_t id;
    bit<8> flow_id; // extreme added
    switch_ifindex_t ifindex;
    bit<16> hash;
    bool terminate;
}

// Data-plane telemetry (DTel) ------------------------------------------------
typedef bit<3> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE = 0b000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP = 0b100;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE = 0b010;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW = 0b001;

struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<32> latency; // Egress only.
    switch_mirror_session_t session_id; // Ingress only.
    bit<32> hash;
}

header switch_dtel_switch_local_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;

    bit<6> _pad;



    switch_mirror_session_t session_id;
    bit<32> hash;
    bit<5> _pad1;
    switch_dtel_report_type_t report_type;
    bit<7> _pad2;
    bit<9> ingress_port;
    bit<7> _pad3;
    bit<9> egress_port;
    bit<3> _pad4;
    bit<5> qid;
    bit<5> _pad5;
    bit<19> qdepth;
    bit<32> egress_timestamp;
}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    bit<48> timestamp;

    bit<6> _pad;



    switch_mirror_session_t session_id;
    bit<32> hash;
    bit<13> _pad1;
    switch_dtel_report_type_t report_type;
    bit<7> _pad2;
    bit<9> ingress_port;
    bit<7> _pad3;
    bit<9> egress_port;
    bit<3> _pad4;
    bit<5> qid;
    switch_drop_reason_t drop_reason;
}

@flexible
struct switch_bridged_metadata_dtel_extension_t {
    switch_dtel_report_type_t report_type;
    switch_mirror_session_t session_id;
    bit<32> hash;
}

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
// Flags
//XXX Force the fields that are XORd to NOT share containers.
@pa_container_size("ingress", "ig_md.checks.same_if", 16)
@pa_container_size("ingress", "ig_md.checks.same_bd", 16)
struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool dmac_miss;
    bool myip;
    bool glean;
    bool storm_control_drop;
    bool qos_policer_drop;
    bool flood_to_multicast_routers;
    bool peer_link;
    bool capture_ts;
    bool mac_pkt_class;

    // Add more flags here.
}

struct switch_egress_flags_t {
    bool routed;
    bool acl_deny;
    bool mlag_member;
    bool peer_link;
    bool capture_ts;
    bool wred_drop;

    // Add more flags here.
}


// Checks
struct switch_ingress_checks_t {
    switch_bd_t same_bd;
    switch_ifindex_t same_if;
    bool mrpf;
    bool urpf;
    // Add more checks here.
}

struct switch_egress_checks_t {
    switch_bd_t same_bd;
    switch_mtu_t mtu;
    bool stp;

    // Add more checks here.
}

// IP
struct switch_ip_metadata_t {
    bool unicast_enable;
    bool multicast_enable;
    bool multicast_snooping;
    // switch_urpf_mode_t urpf_mode;
}

@pa_alias("ingress", "hdr.tcp.flags", "ig_md.lkp.tcp_flags")
struct switch_lookup_fields_t {
    switch_pkt_type_t pkt_type;

    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
    bit<16> arp_opcode;

    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_tos;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;


    bit<88> l7_udf; // extreme added

}

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
    switch_ifindex_t ingress_ifindex;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
    switch_pkt_type_t pkt_type;
    bool routed;
    //TODO(msharif) : Fix the bridged metadata fields for PTP.
    // bool capture_ts;
    bool peer_link;
    switch_tc_t tc;
    switch_cpu_reason_t cpu_reason;
    bit<48> timestamp;
    switch_qid_t qid;

    // Add more fields here.

 // ------------------------------------
 // Extreme Networks - Added
 // ------------------------------------

    // metadata
//  bit<5>                   unused; // for byte-alignment
    bit<1> orig_pkt_had_nsh; // for egr parser
    bit<1> nsh_extr_valid; // set by sfc
    bit<1> nsh_extr_end_of_chain; // set by sff

    // base: word 0

    // base: word 1
    bit<24> nsh_extr_spi;
    bit<8> nsh_extr_si;

    // ext: type 2 - word 0

    // ext: type 2 - word 1+
    bit<8> nsh_extr_srvc_func_bitmask_local; //  1 byte
    bit<8> nsh_extr_srvc_func_bitmask_remote; //  1 byte
    bit<16> nsh_extr_tenant_id; //  3 bytes
    bit<8> nsh_extr_flow_type; //  1 byte?

    // dedup stuff





}

@flexible
struct switch_bridged_metadata_acl_extension_t {
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    bit<8> tcp_flags;
    switch_l4_port_label_t l4_port_label;
}

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_index_t index;
    switch_outer_nexthop_t outer_nexthop;
    bit<16> hash;
    switch_vrf_t vrf;
    bool terminate;
}
# 674 "types.p4"
@pa_alias("ingress", "hdr.bridged_md.base_ingress_port", "ig_md.port")
@pa_alias("ingress", "hdr.bridged_md.base_ingress_ifindex", "ig_md.ifindex")
@pa_alias("ingress", "hdr.bridged_md.base_ingress_bd", "ig_md.bd")
@pa_alias("ingress", "hdr.bridged_md.base_nexthop", "ig_md.nexthop")
@pa_alias("ingress", "hdr.bridged_md.base_routed", "ig_md.flags.routed")
@pa_alias("ingress", "hdr.bridged_md.base_peer_link", "ig_md.flags.peer_link")
@pa_alias("ingress", "hdr.bridged_md.base_pkt_type", "ig_md.lkp.pkt_type")
@pa_alias("ingress", "hdr.bridged_md.base_tc", "ig_md.qos.tc")
@pa_alias("ingress", "hdr.bridged_md.base_cpu_reason", "ig_md.cpu_reason")
@pa_alias("ingress", "hdr.bridged_md.base_timestamp", "ig_md.timestamp")
@pa_alias("ingress", "hdr.bridged_md.base_qid", "ig_md.qos.qid")

@pa_alias("ingress", "hdr.bridged_md.tunnel_terminate", "ig_md.tunnel.terminate")
@pa_alias("ingress", "hdr.bridged_md.tunnel_outer_nexthop", "ig_md.outer_nexthop")
@pa_alias("ingress", "hdr.bridged_md.tunnel_index", "ig_md.tunnel.index")
@pa_alias("ingress", "hdr.bridged_md.tunnel_vrf", "ig_md.vrf")
# 703 "types.p4"
typedef bit<8> switch_bridge_type_t;

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;




    switch_bridged_metadata_tunnel_extension_t tunnel;




}

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_port_lag_label_t port_lag_label;
    switch_ifindex_t ifindex;
}

@pa_container_size("ingress", "ig_md.l4_port_label", 8)
@pa_container_size("ingress", "ig_md.mirror.src", 8)
@pa_container_size("ingress", "ig_md.mirror.type", 8)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")



@pa_container_size("ingress", "ig_md.lkp.l4_src_port", 8)
@pa_container_size("egress", "hdr.dtel_drop_report.drop_reason", 8)
// Ingress metadata
struct switch_ingress_metadata_t {
    switch_ifindex_t ifindex; /* ingress interface index */
    switch_port_t port; /* ingress port */
    switch_port_t egress_port; /* egress port */
    switch_port_lag_index_t port_lag_index; /* ingress port/lag index */
    switch_ifindex_t egress_ifindex; /* egress interface index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */
    switch_bd_t bd;
    switch_bd_t bd_nsh; // extreme added
    switch_vrf_t vrf;
    switch_vrf_t vrf_nsh; // extreme added
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;

    bit<48> timestamp;
    bit<32> hash;

    switch_ingress_flags_t flags;
    switch_ingress_checks_t checks;
    switch_ingress_bypass_t bypass;

    switch_ip_metadata_t ipv4;
    switch_ip_metadata_t ipv4_nsh; // extreme added
    switch_ip_metadata_t ipv6;
    switch_ip_metadata_t ipv6_nsh; // extreme added
    switch_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_bd_label_t bd_label_nsh; // extreme added
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_port_label;

    switch_drop_reason_t drop_reason;
    switch_cpu_reason_t cpu_reason;

    switch_rmac_group_t rmac_group;
    switch_rmac_group_t rmac_group_nsh; // extreme added
    switch_lookup_fields_t lkp;
    switch_lookup_fields_t lkp_nsh; // extreme added
    switch_multicast_metadata_t multicast;
    switch_multicast_metadata_t multicast_nsh; // extreme added
    switch_stp_metadata_t stp;
    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_tunnel_metadata_t tunnel_nsh; // extreme added
    switch_learning_metadata_t learning;
    switch_learning_metadata_t learning_nsh; // extreme added
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;

 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

    bit<1> orig_pkt_had_nsh; // for egr parser
    nsh_extr_internal_lkp_t nsh_extr;
}

// Egress metadata
@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.type", 8)
struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
    switch_pkt_type_t pkt_type;

    switch_port_lag_index_t port_lag_index; /* egress port/lag index */
    switch_port_type_t port_type; /* egress port type */
    switch_port_t port; /* Mutable copy of egress port */
    switch_port_t ingress_port; /* ingress port */
    switch_ifindex_t ingress_ifindex; /* ingress interface index */
    switch_bd_t bd;
    switch_vrf_t vrf;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;

    bit<32> timestamp;
    bit<48> ingress_timestamp;

    switch_egress_flags_t flags;
    switch_egress_checks_t checks;
    switch_egress_bypass_t bypass;

    // for egress ACL
    switch_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_port_label;

    switch_lookup_fields_t lkp;
    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_mirror_metadata_t mirror;
    switch_dtel_metadata_t dtel;

    switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;

 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

    bit<1> orig_pkt_had_nsh; // for egr parser
    nsh_extr_internal_lkp_t nsh_extr;

    bit<5> action_bitmask;
//  bit<NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH_POW2> meter_id;
    bit<10 > meter_id;
    bit<8> meter_overhead;
}

// Header format for mirrored metadata fields
struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h port;
    switch_cpu_mirror_metadata_h cpu;
    switch_dtel_drop_mirror_metadata_h dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
}


struct switch_header_t {

    // ===========================
    // misc
    // ===========================

    switch_bridged_metadata_h bridged_md;
    // switch_mirror_metadata_h mirror;
    fabric_h fabric;
    cpu_h cpu;
    timestamp_h timestamp;

    // ===========================
    // outer
    // ===========================

    ethernet_h ethernet;
    e_tag_h e_tag; // extreme added
    vn_tag_h vn_tag; // extreme added
    vlan_tag_h[2] vlan_tag;
    mpls_h[4] mpls;
    ipv4_h ipv4;
    opaque_option_h opaque_option;
    ipv6_h ipv6;
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    dtel_report_v05_h dtel;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;
    rocev2_bth_h rocev2_bth;
    vxlan_h vxlan;
    gre_h gre;
    nvgre_h nvgre;
    geneve_h geneve;
    erspan_type2_h erspan_type2;
    erspan_type3_h erspan_type3;
    erspan_platform_h erspan_platform;

 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

    // underlay





    ethernet_h ethernet_underlay; // egress only
    vlan_tag_h vlan_tag_underlay; // egress only
    nsh_extr_h nsh_extr_underlay;





    sctp_h sctp;
    esp_h esp;


    gtp_v1_base_h gtp_v1_base;
    gtp_v2_base_h gtp_v2_base;
    gtp_v1_v2_teid_h gtp_v1_v2_teid;
    gtp_v1_optional_h gtp_v1_optional;


    udf_h udf;

    // ===========================
    // inner
    // ===========================

    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;

 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

    vlan_tag_h inner_vlan_tag;
    arp_h inner_arp;
    sctp_h inner_sctp;
    gre_h inner_gre;
    esp_h inner_esp;
    igmp_h inner_igmp;

    udf_h inner_udf;
}
# 42 "npb.p4" 2
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




const bit<32> PORT_TABLE_SIZE = 288 * 2;

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 4K (port, vlan[0], vlan[1]) <--> BD
const bit<32> DOUBLE_TAG_TABLE_SIZE = 4096;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// 16K MACs



const bit<32> MAC_TABLE_SIZE = 16384;
# 61 "table_sizes.p4"
// IP Hosts/Routes
const bit<32> IPV4_LPM_TABLE_SIZE = 16384;
const bit<32> IPV6_LPM_TABLE_SIZE = 1024; // 8192;
const bit<32> IPV4_HOST_TABLE_SIZE = 32768;
const bit<32> IPV6_HOST_TABLE_SIZE = 8192; // 16384;
// Multicast
const bit<32> IPV4_MULTICAST_STAR_G_TABLE_SIZE = 2048;
const bit<32> IPV4_MULTICAST_S_G_TABLE_SIZE = 4096;
const bit<32> IPV6_MULTICAST_STAR_G_TABLE_SIZE = 512;
const bit<32> IPV6_MULTICAST_S_G_TABLE_SIZE = 512;
const bit<32> RID_TABLE_SIZE = 4096;


// Tunnels - 4K IPv4 + 1K IPv6
const bit<32> DEST_TUNNEL_TABLE_SIZE = 512;
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 4096;
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 1024;
const bit<32> VNI_MAPPING_TABLE_SIZE = 4096;
const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512;
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 4096;
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 512;
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 4096;
const bit<32> TUNNEL_REWRITE_TABLE_SIZE = 512;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024;
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096;
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384;



const bit<32> NEXTHOP_TABLE_SIZE = 32768;

const bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096;

// Ingress ACLs
# 112 "table_sizes.p4"
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MAC_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_QOS_ACL_TABLE_SIZE = 512;

const bit<32> INGRESS_L4_PORT_LOU_TABLE_SIZE = 16 / 2;

const bit<32> IPV4_RACL_TABLE_SIZE = 512;
const bit<32> IPV6_RACL_TABLE_SIZE = 512;


// Egress ACL
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;

// WRED
const bit<32> WRED_SIZE = 1 << 8;

// COPP
const bit<32> COPP_METER_SIZE = 1 << 8;
const bit<32> COPP_DROP_TABLE_SIZE = 1 << (8 + 1);

// QoS
const bit<32> DSCP_TO_TC_TABLE_SIZE = 1024;
const bit<32> PCP_TO_TC_TABLE_SIZE = 1024;
const bit<32> QUEUE_TABLE_SIZE = 1024;
const bit<32> EGRESS_QOS_MAP_TABLE_SIZE = 1024;

// Policer
const bit<32> INGRESS_POLICER_TABLE_SIZE = 1 << 10;

// Storm Control
const bit<32> STORM_CONTROL_TABLE_SIZE = 512;

// System ACL
const bit<32> INGRESS_SYSTEM_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_SYSTEM_ACL_TABLE_SIZE = 512;
const bit<32> DROP_STATS_TABLE_SIZE = 1 << 8;

const bit<32> L3_MTU_TABLE_SIZE = 1024;

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Extreme Networks - Added
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------




// net intf

// sfc -- classifies non-nsh packets
const bit<32> NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_NSH_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_SCHD_TABLE_PART1_DEPTH = 1024;
const bit<32> NPB_ING_SFC_SCHD_TABLE_PART2_DEPTH = 1024; // for action_profile type table

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH = 1024;

// sf #0 -- basic / advanced
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L2_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_V4_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_V6_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SF_0_BAS_ADV_SCHD_TABLE_PART1_DEPTH = 1024;
const bit<32> NPB_ING_SF_0_BAS_ADV_SCHD_TABLE_PART2_DEPTH = 1024; // for action_profile type table

// sf #1 -- replication

// sf #2 -- tool proxy
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TABLE_DEPTH = 1024;
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

// Flow hash calculation.
Hash<bit<32>>(HashAlgorithm_t.CRC32) ip_hash;
Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;

action compute_ip_hash(in switch_lookup_fields_t lkp, out bit<32> hash) {
    hash = ip_hash.get({lkp.ip_src_addr,
                        lkp.ip_dst_addr,
                        lkp.ip_proto,
                        lkp.l4_dst_port,
                        lkp.l4_src_port});
}

action compute_non_ip_hash(in switch_lookup_fields_t lkp, out bit<32> hash) {
    hash = non_ip_hash.get({lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr});
}

// -----------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
        inout switch_bridged_metadata_h bridged_md, in switch_ingress_metadata_t ig_md) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base = {
        ig_md.port, ig_md.ifindex, ig_md.bd, ig_md.nexthop, ig_md.lkp.pkt_type,
        ig_md.flags.routed, ig_md.flags.peer_link,
        ig_md.qos.tc, ig_md.cpu_reason, ig_md.timestamp, ig_md.qos.qid,
  // -------------------------------------
     // Extreme Networks - Added
  // -------------------------------------
     // metadata
     ig_md.orig_pkt_had_nsh,
     ig_md.nsh_extr.valid,
     ig_md.nsh_extr.end_of_chain,

     // base: word 0

     // base: word 1
     ig_md.nsh_extr.spi,
     ig_md.nsh_extr.si,

     // ext: type 2 - word 0

     // ext: type 2 - word 1+
     ig_md.nsh_extr.extr_srvc_func_bitmask_local, //  1 byte
     ig_md.nsh_extr.extr_srvc_func_bitmask_remote, //  1 byte
     ig_md.nsh_extr.extr_tenant_id, //  3 bytes
     ig_md.nsh_extr.extr_flow_type //  1 byte?

     // dedup stuff






  };
# 93 "util.p4"
    bridged_md.tunnel = {ig_md.tunnel.index,
                         ig_md.outer_nexthop,
                         ig_md.hash[15:0],
                         ig_md.vrf,
                         ig_md.tunnel.terminate};





}

// -----------------------------------------------------------------------------

action set_ig_intr_md(in switch_ingress_metadata_t ig_md,
                      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                      inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

// Set PRE hash values
//XXX Compiler doesn't like this copy!!!!
//  ig_intr_md_for_tm.level1_mcast_hash = hash[12:0];
//  ig_intr_md_for_tm.level2_mcast_hash = hash[28:16];

    ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;

    ig_intr_md_for_dprsr.mirror_type = (bit<3>) ig_md.mirror.type;







}

// -----------------------------------------------------------------------------

action set_eg_intr_md(in switch_egress_metadata_t eg_md,
                      inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                      inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {





    eg_intr_md_for_dprsr.mirror_type = (bit<3>) eg_md.mirror.type;




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




//-----------------------------------------------------------------------------
// Common ACL actions.
//-----------------------------------------------------------------------------
action acl_deny(inout switch_ingress_metadata_t ig_md,
                inout switch_stats_index_t index,
                switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.acl_deny = true;
}

action acl_permit(inout switch_ingress_metadata_t ig_md,
                  inout switch_stats_index_t index,
                  switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.acl_deny = false;
}

action acl_redirect(inout switch_ingress_metadata_t ig_md,
                    inout switch_stats_index_t index,
                    switch_nexthop_t nexthop,
                    switch_stats_index_t stats_index) {





}

action acl_mirror(inout switch_ingress_metadata_t ig_md,
                  inout switch_stats_index_t index,
                  switch_stats_index_t stats_index,
                  switch_mirror_session_t session_id) {






}
# 103 "acl.p4"
//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------
control IngressIpv4Acl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_deny(ig_md, index);
            acl_permit(ig_md, index);
            acl_redirect(ig_md, index);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}


control IngressIpv6Acl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {
//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------
    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_deny(ig_md, index);
            acl_permit(ig_md, index);
            acl_redirect(ig_md, index);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}


control IngressMacAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
        }

        actions = {
            NoAction;
            acl_deny(ig_md, index);
            acl_permit(ig_md, index);
            acl_redirect(ig_md, index);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

// ----------------------------------------------------------------------------
// Comparison/Logical operation unit (LOU)
// LOU can perform logical operationis such AND and OR on tcp flags as well as comparison
// operations such as LT, GT, EQ, and NE for src/dst UDP/TCP ports.
//
// @param src_port : UDP/TCP source port.
// @param dst_port : UDP/TCP destination port.
// @param flags : TCP flags.
// @param port_label : A bit-map for L4 src/dst port ranges. Each bit is corresponding to a single
// range for src or dst port.
// @param table_size : Total number of supported ranges for src/dst ports.
// ----------------------------------------------------------------------------
control LOU(in bit<16> src_port,
            in bit<16> dst_port,
            inout bit<8> tcp_flags,
            out switch_l4_port_label_t port_label) {

    const switch_uint32_t table_size = 16 / 2;

    //TODO(msharif): Change this to bitwise OR so we can allocate bits to src/dst ports at runtime.
    action set_src_port_label(bit<8> label) {
        port_label[7:0] = label;
    }

    action set_dst_port_label(bit<8> label) {
        port_label[15:8] = label;
    }

    @entries_with_ranges(table_size)
    //TODO(msharif): Remove this when compiler checks table dependencies based on slices rather
    //than fields.
    //XXX(msharif): Remove the ifdef

    @ignore_table_dependency("SwitchIngress.acl.lou.l4_src_port")

    table l4_dst_port {
        key = {
            dst_port : range;
        }

        actions = {
            NoAction;
            set_dst_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }


    @entries_with_ranges(table_size)
    table l4_src_port {
        key = {
            src_port : range;
        }

        actions = {
            NoAction;
            set_src_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action set_tcp_flags(bit<8> flags) {
        tcp_flags = flags;
    }

    table tcp {
        key = { tcp_flags : exact; }
        actions = {
            NoAction;
            set_tcp_flags;
        }

        size = 256;
    }

    apply {
# 288 "acl.p4"
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
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ipv4_table_size=512,
        switch_uint32_t ipv6_table_size=512,
        switch_uint32_t mac_table_size=512,
        bool mac_acl_enable=false,
        bool mac_packet_class_enable=false) {

    IngressIpv4Acl(ipv4_table_size) ipv4_acl;
    IngressIpv6Acl(ipv6_table_size) ipv6_acl;
    IngressMacAcl(mac_table_size) mac_acl;
    LOU() lou;

    Counter<bit<16>, switch_stats_index_t>(
        ipv4_table_size + ipv6_table_size + mac_table_size, CounterType_t.PACKETS_AND_BYTES) stats;

    switch_stats_index_t stats_index;

    apply {
        lou.apply(lkp.l4_src_port, lkp.l4_dst_port, lkp.tcp_flags, ig_md.l4_port_label);

        if (mac_acl_enable && !(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_NONE || (mac_packet_class_enable && ig_md.flags.mac_pkt_class)) {

                mac_acl.apply(lkp, ig_md, stats_index);
            }
        }

        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0) && (!mac_packet_class_enable || !ig_md.flags.mac_pkt_class)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                ipv6_acl.apply(lkp, ig_md, stats_index);
            } else if (!mac_acl_enable || lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_acl.apply(lkp, ig_md, stats_index);
            }
        }

        stats.count(stats_index);
    }
}
//-----------------------------------------------------------------------------
// Common RACL actions.
//-----------------------------------------------------------------------------
action racl_deny(inout switch_ingress_metadata_t ig_md,
                 inout switch_stats_index_t index,
                 switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.racl_deny = true;
}

action racl_permit(inout switch_ingress_metadata_t ig_md,
                   inout switch_stats_index_t index,
                   switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.racl_deny = false;
}

action racl_redirect(inout switch_stats_index_t index,
                     inout switch_nexthop_t nexthop,
                     switch_stats_index_t stats_index,
                     switch_nexthop_t nexthop_index) {
    index = stats_index;
    nexthop = nexthop_index;
}

//-----------------------------------------------------------------------------
// IPv4 RACL
//-----------------------------------------------------------------------------
control Ipv4Racl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            racl_deny(ig_md, index);
            racl_permit(ig_md, index);
            racl_redirect(index, nexthop);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}


//-----------------------------------------------------------------------------
// IPv6 RACL
//-----------------------------------------------------------------------------
control Ipv6Racl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            racl_deny(ig_md, index);
            racl_permit(ig_md, index);
            racl_redirect(index, nexthop);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

// ----------------------------------------------------------------------------
// Router Access Control List (Router-ACL)
// @param lkp : Lookup fields used for ACL.
// @param ig_md : Ingress metadata fields.
//
// @flags PBR_ENABLE : Enable policy-based routing. PBR dictates a policy that
// determines where the packets are forwarded. Policies can be based IP address,
// port numbers and etc.
// ----------------------------------------------------------------------------
control RouterAcl(in switch_lookup_fields_t lkp,
                  inout switch_ingress_metadata_t ig_md)(
                  switch_uint32_t ipv4_table_size=512,
                  switch_uint32_t ipv6_table_size=512,
                  bool stats_enable=false) {

    switch_stats_index_t stats_index;
    switch_nexthop_t nexthop;

    Counter<bit<16>, switch_stats_index_t>(
        ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;

    Ipv4Racl(ipv4_table_size) ipv4_racl;
    Ipv6Racl(ipv6_table_size) ipv6_racl;

    apply {
# 479 "acl.p4"
    }
}

// ----------------------------------------------------------------------------
// IPv4 Mirror ACL.
// @param lkp : Lookup fields used for ACL.
// @param ig_md : Ingress metadata fields.
// @param index : ACL stats index.
// @param table_size
// ----------------------------------------------------------------------------
control Ipv4MirrorAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_mirror(ig_md, index);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

// ----------------------------------------------------------------------------
// IPv6 Mirror ACL.
// @param lkp : Lookup fields used for ACL.
// @param ig_md : Ingress metadata fields.
// @param index : ACL stats index.
// @param table_size
// ----------------------------------------------------------------------------
control Ipv6MirrorAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_mirror(ig_md, index);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

// ----------------------------------------------------------------------------
// Unified IPv4/v6 Mirror ACL.
// @param lkp : Lookup fields used for ACL.
// @param ig_md : Ingress metadata fields.
// @param index : ACL stats index.
// @param table_size
// ----------------------------------------------------------------------------

control IpMirrorAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.mac_type : ternary; lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_mirror(ig_md, index);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

// ----------------------------------------------------------------------------
// Mirror Access Control List (ACL)
//
// @param lkp : Lookup fields used for lookups.
// @param ig_md : Ingress metadata.
// ----------------------------------------------------------------------------
control MirrorAcl(
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ipv4_table_size=512,
        switch_uint32_t ipv6_table_size=512,
        bool stats_enable=false) {

    Ipv4MirrorAcl(ipv4_table_size) ipv4;
    Ipv6MirrorAcl(ipv6_table_size) ipv6;

    Counter<bit<16>, switch_stats_index_t>(
        ipv4_table_size + ipv6_table_size, CounterType_t.PACKETS_AND_BYTES) stats;
    switch_stats_index_t stats_index;

    apply {
# 618 "acl.p4"
    }
}


//-----------------------------------------------------------------------------
// System ACL
//
// @flag COPP_ENABLE
// @flag
//-----------------------------------------------------------------------------
control IngressSystemAcl(
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    const switch_uint32_t drop_stats_table_size = 8192;

    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;

    Meter<bit<8>>(1 << 8, MeterType_t.PACKETS) copp_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

    switch_copp_meter_id_t copp_meter_id;

    action drop(switch_drop_reason_t drop_reason, bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;
        ig_md.drop_reason = drop_reason;
    }

    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_qid_t qid,
                       switch_copp_meter_id_t meter_id,
                       bool disable_learning) {
        ig_md.qos.qid = qid;
        // ig_md.qos.icos = icos;
        ig_intr_md_for_tm.copy_to_cpu = 1;
        ig_intr_md_for_dprsr.digest_type =
            disable_learning ? SWITCH_DIGEST_TYPE_INVALID : ig_intr_md_for_dprsr.digest_type;




        ig_md.cpu_reason = reason_code;
    }

    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_qid_t qid,
                           switch_copp_meter_id_t meter_id,
                           bool disable_learning) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid, meter_id, disable_learning);
    }

    table system_acl {
        key = {
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.ifindex : ternary;

            // Lookup fields
            ig_md.lkp.pkt_type : ternary;
            ig_md.lkp.mac_type : ternary;
            ig_md.lkp.mac_dst_addr : ternary;
            ig_md.lkp.ip_type : ternary;
            ig_md.lkp.ip_ttl : ternary;
            ig_md.lkp.ip_proto : ternary;
            ig_md.lkp.ip_dst_addr : ternary;
            ig_md.lkp.l4_src_port : ternary;
            ig_md.lkp.l4_dst_port : ternary;
            ig_md.lkp.arp_opcode : ternary;

            // Flags
            ig_md.flags.port_vlan_miss : ternary;
            ig_md.flags.acl_deny : ternary;
            ig_md.flags.racl_deny : ternary;
            ig_md.flags.rmac_hit : ternary;
            ig_md.flags.dmac_miss : ternary;
            ig_md.flags.myip : ternary;
            ig_md.flags.glean : ternary;
            ig_md.flags.routed : ternary;
            ig_md.flags.storm_control_drop : ternary;
            ig_md.flags.qos_policer_drop : ternary;
            ig_md.flags.link_local : ternary;
# 713 "acl.p4"
            ig_md.ipv4.unicast_enable : ternary;
            ig_md.ipv6.unicast_enable : ternary;


            ig_md.checks.mrpf : ternary;
            ig_md.ipv4.multicast_enable : ternary;
            ig_md.ipv4.multicast_snooping : ternary;
            ig_md.ipv6.multicast_enable : ternary;
            ig_md.ipv6.multicast_snooping : ternary;

            ig_md.drop_reason : ternary;
        }

        actions = {
            NoAction;
            drop;
            copy_to_cpu;
            redirect_to_cpu;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action copp_drop() {
        ig_intr_md_for_tm.copy_to_cpu = 0;
        copp_stats.count();
    }

    action copp_permit() {
        copp_stats.count();
    }

    table copp {
        key = {
            ig_intr_md_for_tm.packet_color : ternary;
            copp_meter_id : ternary;
        }

        actions = {
            copp_permit;
            copp_drop;
        }

        const default_action = copp_permit;
        size = (1 << 8 + 1);
        counters = copp_stats;
    }

    action count() { stats.count(); }

    table drop_stats {
        key = {
            ig_md.drop_reason : exact @name("drop_reason");
            ig_md.port : exact @name("port");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = drop_stats_table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SYSTEM_ACL != 0))
            system_acl.apply();




        drop_stats.apply();
    }
}

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------
control EgressMacAcl(in switch_header_t hdr,
                     inout switch_egress_metadata_t eg_md,
                     out switch_stats_index_t index)(
                     switch_uint32_t table_size=512) {
    action acl_deny(switch_stats_index_t stats_index) {
        index = stats_index;
        eg_md.flags.acl_deny = true;
    }

    action acl_permit(switch_stats_index_t stats_index) {
        index = stats_index;
    }

    table acl {
        key = {
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.ethernet.ether_type : ternary;
        }

        actions = {
            NoAction;
            acl_deny;
            acl_permit;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------
control EgressIpv4Acl(in switch_header_t hdr,
                      in switch_lookup_fields_t lkp,
                      inout switch_egress_metadata_t eg_md,
                      out switch_stats_index_t index)(
                      switch_uint32_t table_size=512) {
    action acl_deny(switch_stats_index_t stats_index) {
        index = stats_index;
        eg_md.flags.acl_deny = true;
    }

    action acl_permit(switch_stats_index_t stats_index) {
        index = stats_index;
        eg_md.flags.acl_deny = false;
    }

    table acl {
        key = {
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            eg_md.l4_port_label : ternary;
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv4.protocol : ternary;
            hdr.ipv4.diffserv : ternary;
            lkp.l4_src_port : ternary;
            lkp.l4_dst_port : ternary;
        }

        actions = {
            NoAction;
            acl_deny;
            acl_permit;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------
control EgressIpv6Acl(in switch_header_t hdr,
                      in switch_lookup_fields_t lkp,
                      inout switch_egress_metadata_t eg_md,
                      out switch_stats_index_t index)(
                      switch_uint32_t table_size=512) {
    action acl_deny(switch_stats_index_t stats_index) {
        index = stats_index;
        eg_md.flags.acl_deny = true;
    }

    action acl_permit(switch_stats_index_t stats_index) {
        index = stats_index;
        eg_md.flags.acl_deny = true;
    }

    table acl {
        key = {
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            eg_md.l4_port_label : ternary;
            hdr.ipv6.src_addr : ternary;
            hdr.ipv6.dst_addr : ternary;
            hdr.ipv6.next_hdr : ternary;
            hdr.ipv6.traffic_class : ternary;
            lkp.l4_src_port : ternary;
            lkp.l4_dst_port : ternary;
        }

        actions = {
            NoAction;
            acl_deny;
            acl_permit;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}


control EgressAcl(in switch_header_t hdr,
                  in switch_lookup_fields_t lkp,
                  inout switch_egress_metadata_t eg_md)(
                  switch_uint32_t mac_table_size=512,
                  switch_uint32_t ipv4_table_size=512,
                  switch_uint32_t ipv6_table_size=512,
                  bool stats_enable=false,
                  switch_uint32_t stats_table_size=2048) {
    EgressIpv4Acl(ipv4_table_size) ipv4_acl;
    EgressIpv6Acl(ipv6_table_size) ipv6_acl;
    EgressMacAcl(mac_table_size) mac_acl;

    Counter<bit<16>, switch_stats_index_t>(
        stats_table_size, CounterType_t.PACKETS_AND_BYTES) stats;

    switch_stats_index_t stats_index;

    apply {
# 956 "acl.p4"
    }
}

control EgressSystemAcl(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    const switch_uint32_t drop_stats_table_size = 8192;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;

    action drop(switch_drop_reason_t reason_code) {
        eg_md.drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action copy_to_cpu(switch_cpu_reason_t reason_code) {
        eg_md.cpu_reason = reason_code;
        eg_intr_md_for_dprsr.mirror_type = 2;
        eg_md.mirror.type = 2;
        eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action redirect_to_cpu(switch_cpu_reason_t reason_code) {
        copy_to_cpu(reason_code);
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action insert_timestamp() {




    }

    table system_acl {
        key = {
            eg_intr_md.egress_port : ternary;
            eg_md.flags.acl_deny : ternary;





            eg_md.checks.mtu : ternary;







            //TODO add more
        }

        actions = {
            NoAction;
            drop;
            copy_to_cpu;
            redirect_to_cpu;
            insert_timestamp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action count() { stats.count(); }

    table drop_stats {
        key = {
            eg_md.drop_reason : exact @name("drop_reason");
            eg_intr_md.egress_port : exact @name("port");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        counters = stats;
        size = drop_stats_table_size;
    }


    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_SYSTEM_ACL != 0))
            system_acl.apply();
        drop_stats.apply();
    }
}
# 24 "l3.p4" 2
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
// Spanning Tree Protocol
// @param ig_md : Ingress metadata fields.
// @param stp_md : Spanning tree metadata.
// @param multiple_stp_enable : Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
// @param table_size : Size of the mstp table. Only used if multiple stp is enabled.
//
// @flag MULTIPLE_STP: Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
//-----------------------------------------------------------------------------
control IngressSTP(in switch_ingress_metadata_t ig_md,
                   inout switch_stp_metadata_t stp_md)(
                   bool multiple_stp_enable=false,
                   switch_uint32_t table_size=4096) {
    // This register is used to check the stp state of the ingress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the indes.
    const bit<32> stp_state_size = 1 << 19;
    Register<bit<1>, bit<32>>(stp_state_size, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    action set_stp_state(switch_stp_state_t stp_state) {
        stp_md.state_ = stp_state;
    }

    table mstp {
        key = {
            ig_md.port : exact;
            stp_md.group: exact;
        }

        actions = {
            NoAction;
            set_stp_state;
        }

        size = table_size;
        const default_action = NoAction;
    }

    apply {
# 86 "l2.p4"
    }
}

//-----------------------------------------------------------------------------
// Spanning Tree Protocol
// @param eg_md : Egress metadata fields.
// @param port : Egress port.
// @param stp_state : Spanning tree state.
//-----------------------------------------------------------------------------
control EgressSTP(in switch_egress_metadata_t eg_md, in switch_port_t port, inout bool stp_state) {
    // This register is used to check the stp state of the egress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the index.
    Register<bit<1>, bit<32>>(1 << 19, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    apply {
# 117 "l2.p4"
    }
}


//-----------------------------------------------------------------------------
// Source MAC lookup
//
// @param src_addr : Source MAC address.
// @param ig_md : Ingress metadata
// @param table_size : Size of SMAC table.
//
// MAC learning
// - Trigger a new MAC learn if MAC address is unknown.
// - Trigger a new MAC learn if MAC address is known but attached to a different interface.
//-----------------------------------------------------------------------------
control SMAC(in mac_addr_t src_addr,
             inout switch_ingress_metadata_t ig_md,
             inout switch_digest_type_t digest_type)(
             switch_uint32_t table_size) {
    // local variables for MAC learning
    bool src_miss;
    switch_ifindex_t src_move;

    action smac_miss() {
        src_miss = true;
    }

    action smac_hit(switch_ifindex_t ifindex) {
        src_move = ig_md.ifindex ^ ifindex;
    }

    table smac {
        key = {
            ig_md.bd : exact;
            src_addr : exact;
        }

        actions = {
            @defaultonly smac_miss;
            smac_hit;
        }

        const default_action = smac_miss;
        size = table_size;
        idle_timeout = true;
    }

    action notify() {
        digest_type = SWITCH_DIGEST_TYPE_MAC_LEARNING;
        // ig_md.learning.digest.bd = ig_md.bd;
        // ig_md.learning.digest.src_addr = src_addr;
        // ig_md.learning.digest.ifindex = ig_md.ifindex;
    }

    table learning {
        key = {
            src_miss : exact;
            src_move : ternary;
        }

        actions = {
            NoAction;
            notify;
        }

        const default_action = NoAction;
    }


    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SMAC != 0)) {
         smac.apply();
        }

        if (ig_md.learning.bd_mode == SWITCH_LEARNING_MODE_LEARN &&
                ig_md.learning.port_mode == SWITCH_LEARNING_MODE_LEARN) {
            learning.apply();
        }
    }
}

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
control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);

control DMAC(
        in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {

    action dmac_miss() {
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.flags.dmac_miss = true;
    }

    action dmac_hit(switch_ifindex_t ifindex,
                    switch_port_lag_index_t port_lag_index) {
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.ifindex ^ ifindex;
    }

    action dmac_multicast(switch_mgid_t index) {
        ig_md.multicast.id = index;
    }

    action dmac_redirect(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
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

        const default_action = dmac_miss;
        size = table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {
            dmac.apply();
        }
    }
}

control IngressBd(in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {

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

control EgressBd(in switch_header_t hdr,
                 in switch_bd_t bd,
                 in switch_pkt_type_t pkt_type,
                 out switch_bd_label_t label,
                 out switch_smac_index_t smac_idx,
                 out switch_mtu_t mtu_idx)(
                 switch_uint32_t table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action count() {
        stats.count();
    }

    table bd_stats {
        key = {
            bd : exact;
            pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        size = 3 * table_size;
        counters = stats;
    }

    action set_bd_properties(switch_bd_label_t bd_label,
                             switch_smac_index_t smac_index,
                             switch_mtu_t mtu_index) {
        label = bd_label;
        smac_idx = smac_index;
        mtu_idx = mtu_index;
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
        bd_mapping.apply();
        bd_stats.apply();
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
control VlanDecap(inout switch_header_t hdr, in switch_egress_metadata_t eg_md) {
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }

    action remove_double_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[1].ether_type;
        hdr.vlan_tag.pop_front(2);
    }

    table vlan_decap {
        key = {



            hdr.vlan_tag[0].isValid() : ternary;



        }

        actions = {
            NoAction;
            remove_vlan_tag;
            remove_double_tag;
        }

        const default_action = NoAction;
    }

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
control VlanXlate(inout switch_header_t hdr,
                  in switch_egress_metadata_t eg_md)(
                  switch_uint32_t bd_table_size,
                  switch_uint32_t port_bd_table_size) {
    action set_vlan_untagged() {
        //NoAction.
    }

    action set_double_tagged(vlan_id_t vid0, vlan_id_t vid1) {
# 427 "l2.p4"
   }

    // extreme added
    vlan_id_t vid_temp;

    // extreme added
    action set_vlan_tagged(vlan_id_t vid) {
        vid_temp = vid;
    }

    // extreme changed name
    action set_vlan_tagged_orig(vlan_id_t vid) {



        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;

        hdr.vlan_tag[0].pcp = eg_md.lkp.pcp;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
    }

    // --------------------- 
    // Extreme Added
    // ---------------------

    action set_vlan_tagged_nsh(vlan_id_t vid) {



        hdr.vlan_tag_underlay.setValid();
        hdr.vlan_tag_underlay.ether_type = hdr.ethernet_underlay.ether_type;

        hdr.vlan_tag_underlay.pcp = eg_md.lkp.pcp;
        hdr.vlan_tag_underlay.cfi = 0;
        hdr.vlan_tag_underlay.vid = vid;
        hdr.ethernet_underlay.ether_type = 0x8100;
    }

    // ---------------------

    table port_bd_to_vlan_mapping {
        key = {
            eg_md.port_lag_index : exact @name("port_lag_index");
            eg_md.bd : exact @name("bd");
        }

        actions = {
            set_vlan_untagged;
//          set_vlan_tagged; // extreme modified
            set_vlan_tagged_orig; // extreme added
            set_double_tagged;

            set_vlan_tagged_nsh; // extreme added
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

    action set_type_vlan() {
        hdr.ethernet.ether_type = 0x8100;
    }

    action set_type_qinq() {
        hdr.ethernet.ether_type = 0x8100;
    }

    // --------------------- 
    // Extreme Networks - Added
    // ---------------------

    action set_type_vlan_nsh() {
        hdr.ethernet_underlay.ether_type = 0x8100;
    }

    // ---------------------

    table set_ether_type {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[1].isValid() : exact;

   hdr.vlan_tag_underlay.isValid() : exact; // extreme added
        }

        actions = {
            NoAction;
            set_type_vlan;
            set_type_qinq;

   set_type_vlan_nsh; // extreme added
        }

        const default_action = NoAction;
        const entries = {
   // extreme modified
/*
            (true, false) : set_type_vlan();
            (true, true) : set_type_qinq();
*/
            (true, false, false) : set_type_vlan();
            (true, true, false) : set_type_qinq();

            (_, _, true ) : set_type_vlan_nsh();
        }
    }

    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
            if (!port_bd_to_vlan_mapping.apply().hit) {
                bd_to_vlan_mapping.apply();
            }

      // --------------------- 
      // Extreme Networks - Added
      // ---------------------
/*
	        // Derek: I think this is still wrong.  I really need to see
	        // both .hit and .action_run, which you can't do.  I think
	        // 'default' is not the same as .hit, and so this doesn't
	        // actually work the way it needs to....
	        switch(port_bd_to_vlan_mapping.apply().action_run) {
	            set_vlan_untagged : {
	            }
	            set_double_tagged : {
	            }
	            set_vlan_tagged : {
	                if(hdr.vlan_tag_underlay.isValid()) {
	                    set_vlan_tagged_nsh(vid_temp);
	                } else {
	                    set_vlan_tagged_orig(vid_temp);
	                }
	            }
	            default : {
	                // extreme reworked
	                switch(bd_to_vlan_mapping.apply().action_run) {
	                    set_vlan_tagged : {
	                        if(hdr.vlan_tag_underlay.isValid()) {
	                            set_vlan_tagged_nsh(vid_temp);
	                        } else {
	                            set_vlan_tagged_orig(vid_temp);
	                        }
	                    }
	                }
	            }
	        }
*/




        }
    }
}
# 25 "l3.p4" 2

//-----------------------------------------------------------------------------
// FIB lookup
//
// @param dst_addr : Destination IPv4 address.
// @param vrf
// @param flags
// @param nexthop : Nexthop index.
// @param host_table_size : Size of the host table.
// @param lpm_table_size : Size of the IPv4 route table.
//-----------------------------------------------------------------------------
control Fib<T>(in ipv4_addr_t dst_addr,
               in switch_vrf_t vrf,
               out switch_ingress_flags_t flags,
               out switch_nexthop_t nexthop)(
               switch_uint32_t host_table_size,
               switch_uint32_t lpm_table_size,
               bool local_host_enable=false,
               switch_uint32_t local_host_table_size=1024) {
    action fib_hit(switch_nexthop_t nexthop_index) {
        nexthop = nexthop_index;
        flags.routed = true;
    }

    action fib_miss() {
        flags.routed = false;
    }

    action fib_myip() {
        flags.myip = true;
    }

    table fib {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    table fib_local_host {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = local_host_table_size;
    }

    @alpm(1)




    @alpm_partitions(1024)
    @alpm_subtrees_per_partition(2)

    table fib_lpm {
        key = {
            vrf : exact;
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }

    apply {
        if (local_host_enable) {
            if (!fib_local_host.apply().hit) {
                if (!fib.apply().hit) {
                    fib_lpm.apply();
                }
            }
        } else {
            if (!fib.apply().hit) {
                fib_lpm.apply();
            }
        }
    }
}

control Fibv6<T>(in ipv6_addr_t dst_addr,
                 in switch_vrf_t vrf,
                 out switch_ingress_flags_t flags,
                 out switch_nexthop_t nexthop)(
                 switch_uint32_t host_table_size,
                 switch_uint32_t lpm_table_size) {
    action fib_hit(switch_nexthop_t nexthop_index) {
        nexthop = nexthop_index;
        flags.routed = true;
    }

    action fib_miss() {
        flags.routed = false;
    }

    action fib_myip() {
        flags.myip = true;
    }

    table fib {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    @alpm(1)
    @alpm_partitions(1024)
    @alpm_subtrees_per_partition(2)
    table fib_lpm {
        key = {
            vrf : exact;
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }

    apply {
        if (!fib.apply().hit) {
            fib_lpm.apply();
        }
    }
}

control MTU(in switch_header_t hdr,
            in switch_egress_metadata_t eg_md,
            inout switch_mtu_t mtu_check)(
            switch_uint32_t table_size=1024) {

    action ipv4_mtu_check(switch_mtu_t mtu) {
        mtu_check = mtu |-| hdr.ipv4.total_len;
    }

    action ipv6_mtu_check(switch_mtu_t mtu) {
        mtu_check = mtu |-| hdr.ipv6.payload_len;
    }

    action mtu_miss() {
        mtu_check = 16w0xffff;
    }

    table mtu {
        key = {
            mtu_check : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            ipv4_mtu_check;
            ipv6_mtu_check;
            mtu_miss;
        }

        const default_action = mtu_miss;
        size = table_size;
    }

    apply {
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_MTU != 0))
            mtu.apply();
    }
}

//-----------------------------------------------------------------------------
// @param lkp : Lookup fields used to perform L2/L3 lookups.
// @param ig_md : Ingress metadata fields.
// @param dmac : DMAC instance (See l2.p4)
//-----------------------------------------------------------------------------
control IngressUnicast(in switch_lookup_fields_t lkp,
                       inout switch_ingress_metadata_t ig_md)(
                       DMAC_t dmac,
                       switch_uint32_t ipv4_host_table_size,
                       switch_uint32_t ipv4_route_table_size,
                       switch_uint32_t ipv6_host_table_size=1024,
                       switch_uint32_t ipv6_route_table_size=512,
                       bool local_host_enable=false,
                       switch_uint32_t ipv4_local_host_table_size=1024) {

    Fib<ipv4_addr_t>(ipv4_host_table_size,
                     ipv4_route_table_size,
                     local_host_enable,
                     ipv4_local_host_table_size) ipv4_fib;
    Fibv6<ipv6_addr_t>(ipv6_host_table_size, ipv6_route_table_size) ipv6_fib;

    action rmac_hit() {
        ig_md.flags.rmac_hit = true;
    }

    action rmac_miss() {
        ig_md.flags.rmac_hit = false;
    }

//-----------------------------------------------------------------------------
// Router MAC lookup
// key: destination MAC address.
// - Route the packet if the destination MAC address is owned by the switch.
//-----------------------------------------------------------------------------
    table rmac {
        key = {
            ig_md.rmac_group : exact;
            lkp.mac_dst_addr : exact;
        }

        actions = {
            rmac_hit;
            @defaultonly rmac_miss;
        }

        const default_action = rmac_miss;
        size = 1024;
    }

    apply {
        if (rmac.apply().hit) {
            if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0)) {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4.unicast_enable) {

                    ipv4_fib.apply(lkp.ip_dst_addr[31:0],
                                   ig_md.vrf,
                                   ig_md.flags,
                                   ig_md.nexthop);
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.unicast_enable) {


                    ipv6_fib.apply(lkp.ip_dst_addr,
                                   ig_md.vrf,
                                   ig_md.flags,
                                   ig_md.nexthop);

                } else {
                    // Non-ip packets with router MAC address will be dropped by system ACL.
                }
            }
        } else {
            dmac.apply(lkp.mac_dst_addr, ig_md);
        }
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
// @param lkp : Lookup fields used for hash calculation.
// @param ig_md : Ingress metadata fields
// @param hash : Hash value used for ECMP selection.
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control Nexthop(inout switch_lookup_fields_t lkp,
                inout switch_ingress_metadata_t ig_md,
                in bit<16> hash)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_table_size,
                switch_uint32_t ecmp_selection_table_size) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(
        ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;

    action set_nexthop_properties(switch_ifindex_t ifindex,
                                  switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd) {
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.ifindex ^ ifindex;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
    }

    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid) {
        ig_md.egress_ifindex = 0;
        ig_md.egress_port_lag_index = 0;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
        ig_md.multicast.id = mgid;
    }

    action set_nexthop_properties_glean() {
        ig_md.flags.glean = true;
        ig_md.checks.same_bd = 0xffff;
    }

    action set_nexthop_properties_drop() {
        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }

    action set_ecmp_properties(switch_ifindex_t ifindex,
                               switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(ifindex, port_lag_index, bd);
    }

    action set_ecmp_properties_post_routed_flood(
            switch_bd_t bd,
            switch_mgid_t mgid,
            switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid);
    }

    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }

    action set_tunnel_properties(switch_bd_t bd, switch_tunnel_index_t tunnel_index) {
        // TODO(msharif) : Disable cut-through for non-ip packets.
        ig_md.tunnel.index = tunnel_index;
        ig_md.egress_ifindex = 0;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
    }

    table ecmp {
        key = {
            ig_md.nexthop : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;
            set_tunnel_properties;
        }

        const default_action = NoAction;
        size = ecmp_table_size;
        implementation = ecmp_selector;
    }

    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
            set_nexthop_properties_drop;
            set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;
            set_tunnel_properties;
        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
        }
    }
}

control OuterNexthop(inout switch_ingress_metadata_t ig_md,
                     in bit<16> hash)(
                     switch_uint32_t nexthop_table_size,
                     switch_uint32_t ecmp_table_size,
                     switch_uint32_t ecmp_selection_table_size) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;


    action set_nexthop_properties(switch_ifindex_t ifindex,
                                  switch_port_lag_index_t port_lag_index,
                                  switch_outer_nexthop_t nexthop_index) {
        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
    }

    table ecmp {
        key = {
            ig_md.tunnel.index : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        const default_action = NoAction;
        implementation = ecmp_selector;
        size = ecmp_table_size;
    }

    table nexthop {
        key = {
            ig_md.tunnel.index : exact;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        size = nexthop_table_size;
        const default_action = NoAction;
    }

    apply {

        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
        }

    }
}
# 47 "npb.p4" 2
# 1 "parde.p4" 1
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
# 22 "parde.p4" 2
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
# 23 "parde.p4" 2

# 1 "npb_ing_parser.p4" 1



# 1 "npb_sub_parsers.p4" 1



//-----------------------------------------------------------------------------
// Underlay - Layer 2
//-----------------------------------------------------------------------------

parser ParserUnderlayL2(
    packet_in pkt,
    inout switch_header_t hdr,
    out bit<16> ether_type) {

    state start {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_br;
            0x8926 : parse_vn;
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }

    state parse_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }

    state parse_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }

    state parse_vlan {
     pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_vlan;
            0x8100 : parse_vlan;
            default : accept;
        }
    }
}


// //-----------------------------------------------------------------------------
// // Underlay - Network Service Headers (NSH)
// //-----------------------------------------------------------------------------
// // For now, we'll just assume a fixed 20Bytes of opaque Extreme metadata and
// // parse the whole thing as one big (fixed sized) header. We're also assuming
// // the next header will always be ethernet.
// 
// parser ParserUnderlayNsh(
//     packet_in pkt,
//     inout switch_header_t hdr) {
// 
//     state start {
// 	    pkt.extract(hdr.nsh_extr);
//         // verify base header md-type = 2
//         // verify base header length matches expected
//         // verify base header next_proto = ethernet
//         // verify md2 context header type = "extreme"
//         // verify md2 context header md_len matches expected
//         transition accept;
//     }
// }


// //-----------------------------------------------------------------------------
// // Layer3 - IPv4
// //-----------------------------------------------------------------------------
// 
// parser ParserIPv4(
//     packet_in pkt,
//     inout switch_ingress_metadata_t ig_md,
//     inout switch_header_t hdr) {
// 
//     Checksum<bit<16>>(HashAlgorithm_t.CRC16) ipv4_checksum;
// 
//     state start {
//         pkt.extract(hdr.ipv4);
//          // todo: Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum.add(hdr.ipv4);
//         transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
//             (5, 0, 0) : parse_ipv4_no_options_frags;
//             (5, 2, 0) : parse_ipv4_no_options_frags;
//             default : accept;
//         }
//     }
// 
//     state parse_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
//         // bit slicing like this not supported in v8.6.0
//         //ig_md.parser_scratch[15:8] = 0x4;
//         //ig_md.parser_scratch[7:0] = hdr.ipv4.protocol;
//         //ig_md.parser_scratch_b = 0x0004;
//         //ig_md.parser_scratch_proto = hdr.ipv4.protocol;
//         ig_md.parser_protocol = 0xFF;
//         transition accept;
//     }
// 
// 
// //     state start {
// //          // todo: Flag packet (to be sent to host) if it's a frag or has options.
// //         ig_md.parser_scratch = 0xFFFF; // can we flag it like this?
// //         //ig_md.parser_scratch = -1; // can we flag it like this?
// //         ipv4_h snoop = pkt.lookahead<ipv4_h>();
// //         transition select(snoop.ihl, snoop.flags, snoop.frag_offset) {
// //             (5, 0, 0) : parse_ipv4_no_options_frags;
// //             (5, 2, 0) : parse_ipv4_no_options_frags;
// //             default : accept;
// //         }
// //     }
// // 
// //     state parse_ipv4_no_options_frags {
// //         pkt.extract(hdr.ipv4);
// //         ipv4_checksum.add(hdr.ipv4);
// //         ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
// //         // bit slicing like this not supported in v8.6.0
// //         //ig_md.parser_scratch[15:8] = 0x4;
// //         //ig_md.parser_scratch[7:0] = hdr.ipv4.protocol;
// //         //ig_md.parser_scratch_b = 4;
// //         //ig_md.parser_scratch_b = hdr.ipv4.version;
// //         ig_md.parser_scratch = (bit<16>)hdr.ipv4.protocol;
// //         transition accept;
// //     }
// 
// 
// }
// 
// 
// 
// //-----------------------------------------------------------------------------
// // Layer3 - IPv6
// //-----------------------------------------------------------------------------
// 
// parser ParserIPv6(
//     packet_in pkt,
//     inout switch_ingress_metadata_t ig_md,
//     inout switch_header_t hdr) {
// 
//     state start {
//         pkt.extract(hdr.ipv6);
//         // bit slicing like this not supported in v8.6.0
//         //ig_md.parser_scratch[15:8] = 0x6;
//         //ig_md.parser_scratch[7:0] = hdr.ipv6.next_hdr;
//         //ig_md.parser_scratch_b = 0x0006;
//         //ig_md.parser_scratch = (bit<16>)hdr.ipv6.next_hdr;
//         transition accept;
//     }
// }




// //-------------------------------------------------------------------------
// // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
// //-------------------------------------------------------------------------
// // Based on pseudo code from Glenn (see email from 02/11/2019):
// // Does not support parsing GTP optional word
// // Does not support parsing (TLV) extension headers
// 
// parser ParserGtp(
//     packet_in pkt,
//     //inout switch_ingress_metadata_t ig_md,
//     inout bit<2> md_tunnel_type,
//     inout switch_header_t hdr) {
// 
//     state start {
// 
//         // todo: Flag frame (to be trapped) if version > 2
// #ifdef GTP_ENABLE
//         transition select(pkt.lookahead<bit<4>>()) { //version,PT
//             3: parse_gtp_u;
//             5: parse_gtp_c; // does PT matter w/ gtp-c?
//             //1,4: parse_gtp_prime;
//             default: accept;
//         }
// #else
//         transition reject;
// #endif  /* GTP_ENABLE */
//     }
// 
// #ifdef GTP_ENABLE
//     state parse_gtp_u {
//         pkt.extract(hdr.gtp_v1_base);
//     	transition select(
//             hdr.gtp_v1_base.E,
//             hdr.gtp_v1_base.S,
//             hdr.gtp_v1_base.PN) {
//             (0,0,0): parse_gtp_u_end;
//             default: accept;
//         }
//     }
// 
//     state parse_gtp_c {
//         pkt.extract(hdr.gtp_v1_base);
//         //ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_C;
//         md_tunnel_type = SWITCH_TUNNEL_TYPE_GTP_C;
//     	transition accept;
//     }
// 
//     state parse_gtp_u_end {
//         //ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_U;
//         md_tunnel_type = SWITCH_TUNNEL_TYPE_GTP_U;
//     	transition accept;
//     }
// #endif  /* GTP_ENABLE */
// 
// }
# 5 "npb_ing_parser.p4" 2

parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;

 bit<16> ether_type;
 bit<16> inner_ether_type;
 bit<8> protocol;
 bit<8> inner_protocol;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //     1 : parse_resubmit;
        //     0 : parse_port_metadata;
        // }
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
        ig_md.port_lag_label = port_md.port_lag_label;
        ig_md.ifindex = port_md.ifindex;
        //transition parse_ethernet;
        transition snoop_underlay;
    }

    // todo: need to understand interaction w/ cpu better.
    // todo: can we assume no vlan-tags after cpu header?
    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        ig_md.bypass = hdr.cpu.reason_code;
        ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;
        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            //ETHERTYPE_VLAN : parse_vlan;
            //ETHERTYPE_QINQ : parse_vlan;
            //ETHERTYPE_MPLS : parse_mpls;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2
    ///////////////////////////////////////////////////////////////////////////

    // Subparsers are broken in v8.7.0:
    // Any data set down in the subparser, except maybe header extractions,
    // will not be visible up here in the main parser.
    // 
    // // shared fanout/branch state to save tcam resource
    // state parse_ethernet {
    //     parser_underlay_l2_md_backup.apply(pkt, hdr, ig_md);
    //     transition select(ig_md.scratch_ether_type) {
    //         ETHERTYPE_NSH : parse_nsh_underlay;
    //         ETHERTYPE_ARP : parse_arp;
    //         ETHERTYPE_MPLS : parse_mpls;
    //         ETHERTYPE_IPV4 : parse_ipv4;
    //         ETHERTYPE_IPV6 : parse_ipv6;
    //         ETHERTYPE_BFN : parse_cpu;
    //         default : accept;
    //     }
    // }
# 122 "npb_ing_parser.p4"
    // Snoop ahead here to determine type of underlay
    state snoop_underlay {
        ethernet_tagged_h snoop = pkt.lookahead<ethernet_tagged_h>();
        transition select(snoop.ether_type, snoop.ether_type_tag) {
            (0x894F, _): parse_underlay_nsh;
            (0x8100, 0x894F): parse_underlay_nsh_tagged;
            default: parse_underlay_l2_ethernet;
        }
    }

    state parse_underlay_nsh {
        // todo: is this enet used  - can we advance past it? not emit?
        // pkt.extract(hdr.ethernet_underlay);
        pkt.extract<ethernet_h>(_); // drop it
     pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }

    state parse_underlay_nsh_tagged {
        // todo: is this enet used  - can we advance past it? not emit?
        // pkt.extract(hdr.ethernet_underlay);
        // pkt.extract(hdr.vlan_tag_underlay);
        pkt.extract<ethernet_h>(_); // drop it
        pkt.extract<vlan_tag_h>(_); // drop it
     pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }






    ///////////////////////////////////////////////////////////////////////////
    state parse_underlay_l2_ethernet {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_underlay_l2_br;
            0x8926 : parse_underlay_l2_vn;
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vlan {
     pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    // shared fanout/branch state to save tcam resource
    state parse_underlay_l2_ether_type {
        transition select(ether_type) {
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x9000 : parse_cpu;
            default : accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5
    ///////////////////////////////////////////////////////////////////////////

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_ipv4_no_options_frags;
            default : accept;
        }
    }

    state parse_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            1: parse_icmp;
            2: parse_igmp;
            default: parse_l3_protocol;
        }
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        protocol = hdr.ipv6.next_hdr;
        transition select(hdr.ipv6.next_hdr) {
            58: parse_icmp;
            default: parse_l3_protocol;
        }



    }

    // shared fanout/branch state to save tcam resource
    state parse_l3_protocol {
        transition select(protocol) {
           4: parse_ipinip;
           41: parse_ipv6inip;
           17: parse_udp;
           6: parse_tcp;
           0x84: parse_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_esp;
           47: parse_gre;
           default : accept;
       }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.src_port, hdr.udp.dst_port) {
            (_, 4789): parse_vxlan;
            //(_, udp_port_vxlan): parse_vxlan;

            (_, 2123): parse_gtp_c;
            (2123, _): parse_gtp_c;
            (_, 2152): parse_gtp_u;
            (2152, _): parse_gtp_u;

            default : parse_udf;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition parse_udf;
    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        transition parse_udf;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X
    ///////////////////////////////////////////////////////////////////////////////

    state parse_mpls {
# 333 "npb_ing_parser.p4"
        transition accept;

    }
# 346 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels
    ///////////////////////////////////////////////////////////////////////////

    state parse_vxlan {

        pkt.extract(hdr.vxlan);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
// derek: can't get this to compile!?!?
//      ig_md.tunnel.id = (bit<32>)hdr.vxlan.vni;
        transition parse_inner_ethernet;



    }

    state parse_ipinip {

        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;



    }

    state parse_ipv6inip {
//#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)

        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;



    }

    state parse_gre {
     pkt.extract(hdr.gre);
        // todo: verify(hdr.gre.version == 0, error.GreVersionNotZero);
        transition select(
            hdr.gre.C,
            hdr.gre.R,
            hdr.gre.K,
            hdr.gre.S,
            hdr.gre.s,
            hdr.gre.recurse,
            hdr.gre.version,
            hdr.gre.proto) {

            (0,0,1,0,0,0,0,0x6558): parse_nvgre;
            (0,0,0,0,0,0,0,0x8847): parse_mpls;
            (0,0,0,0,0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6;
// #ifdef ERSPAN_UNDERLAY_ENABLE
//             (0,0,0,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t1_underlay;
//             (0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t2_underlay;
//             //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_erspan_t3_underlay;
// #endif /* ERSPAN_UNDERLAY_ENABLE */
            default: accept;
        }
    }

    state parse_nvgre {
     pkt.extract(hdr.nvgre);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_NVGRE; // extreme added
// derek: can't get this to compile!?!?
//		ig_md.tunnel.id =  (bit<32>)hdr.nvgre.vsid; // extreme added
     transition parse_inner_ethernet;
    }

    state parse_esp {
        pkt.extract(hdr.esp);
        transition accept;
    }



    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    ///////////////////////////////////////////////////////////////////////////
    // GTP-C
    ///////////////////////////////////////////////////////////////////////////

    // state parse_gtp_c {
    //     pkt.extract(hdr.gtp_v2_base);
    //     transition select(hdr.gtp_v2_base.version, hdr.gtp_v2_base.T) {
    //         (2, 1): parse_gtp_c_tied;
    //         default: accept;
    //     }
    // }
    // 
    // state parse_gtp_c_teid {
    //     pkt.extract(hdr.teid);
    // 	transition accept;
    // }

    state parse_gtp_c {
        gtp_v2_base_h snoop_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        transition select(snoop_gtp_v2_base.version, snoop_gtp_v2_base.T) {
            (2, 1): extract_gtp_c;
            default: accept;
        }
    }

    state extract_gtp_c {
        pkt.extract(hdr.gtp_v2_base);
        pkt.extract(hdr.gtp_v1_v2_teid);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTPC; // extreme added
        ig_md.tunnel.id = hdr.gtp_v1_v2_teid.teid; // extreme added
     transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // GTP-U
    ///////////////////////////////////////////////////////////////////////////
    // Does not support parsing GTP v1 optional word
    // Does not support parsing (TLV) extension headers

    // state parse_gtp_u {
    //     pkt.extract(hdr.gtp_v1_base);
    //     transition select(
    //         hdr.gtp_v1_base.version,
    //         hdr.gtp_v1_base.PT,
    //         hdr.gtp_v1_base.E,
    //         hdr.gtp_v1_base.S,
    //         hdr.gtp_v1_base.PN
    //         pkt.lookahead<bit<4>>()) {
    // 
    //         (1, 1, 0, 0, 0, 4): parse_inner_ipv4;
    //         (1, 1, 0, 0, 0, 6): parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

    state parse_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_gtp_u;
            default: accept;
        }
    }

    state extract_gtp_u {
        pkt.extract(hdr.gtp_v1_base);
        pkt.extract(hdr.gtp_v1_v2_teid);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTPU; // extreme added
        ig_md.tunnel.id = hdr.gtp_v1_v2_teid.teid; // extreme added
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: accept;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    // Layer 7 (ie. UDF)
    ///////////////////////////////////////////////////////////////////////////

    state parse_udf {

        pkt.extract(hdr.udf);

        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 2 (ETH-T)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        inner_ether_type = hdr.inner_ethernet.ether_type;
        transition select(hdr.inner_ethernet.ether_type) {
            0x8100 : parse_inner_vlan;
            default : parse_inner_ether_type;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        inner_ether_type = hdr.inner_vlan_tag.ether_type;
        transition parse_inner_ether_type;
    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_ether_type {
        transition select(inner_ether_type) {
            0x0806 : parse_inner_arp;
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner - Layer 2.5
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_arp {
        pkt.extract(hdr.inner_arp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////
    // todo: When barefoot fixes case#8406, we should be able to use a common
    //       subparser for L3 parsing across both outer and inner. This will
    //       result in additional (tcam) resource savings. That being said,
    //       a subparser here can be a little tricky: We may need to use
    //       additional metadata or check valid bits to distinguish between
    //       v4 and v6 when exiting the subparser (into the famout branch).
    //       Also, would we need to indicate that we're finished parsing in
    //       the case of icmp/igmp (if these are done in the subparser(s)).

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_protocol = hdr.inner_ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        transition select(
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_ipv4_no_options_frags;
            //(5, 2, 0): parse_inner_ipv4_no_options_frags;
            (5, 3w2 &&& 3w5, 0): parse_inner_ipv4_no_options_frags;
            default: accept;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            1: parse_inner_icmp;
            2: parse_inner_igmp;
            default: parse_inner_l3_protocol;
        }
    }

    state parse_inner_ipv6 {

        pkt.extract(hdr.inner_ipv6);
        inner_protocol = hdr.inner_ipv6.next_hdr;
        transition select(hdr.inner_ipv6.next_hdr) {
            58: parse_inner_icmp;
            default: parse_inner_l3_protocol;
        }



    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_l3_protocol {
        transition select(inner_protocol) {
           17: parse_inner_udp;
           6: parse_inner_tcp;
           0x84: parse_inner_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_inner_esp;
           47: parse_inner_gre;
           default : accept;
       }
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }

    state parse_inner_igmp {
        pkt.extract(hdr.inner_igmp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition parse_inner_udf;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition parse_inner_udf;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition parse_inner_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Tunnels
    ///////////////////////////////////////////////////////////////////////////

    // todo: do we need to parse this? extract?
    state parse_inner_esp {
        pkt.extract(hdr.inner_esp);
        transition accept;
    }

    // todo: do we need to parse this? extract?
    state parse_inner_gre {
        pkt.extract(hdr.inner_gre);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 7 (ie. UDF)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udf {

        pkt.extract(hdr.inner_udf);

        transition accept;
    }

}
# 25 "parde.p4" 2
# 1 "npb_egr_parser.p4" 1





parser NpbEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    //ParserUnderlayL2() parser_underlay_l2;

 bit<16> ether_type;
 bit<16> inner_ether_type;
 bit<8> protocol;
 bit<8> inner_protocol;

    value_set<bit<16>>(1) udp_port_vxlan;
 value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;
        eg_md.qos.qdepth = eg_intr_md.enq_qdepth;
# 39 "npb_egr_parser.p4"
        transition parse_bridged_pkt;

    }

    state parse_bridged_pkt {
  pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.ingress_ifindex = hdr.bridged_md.base.ingress_ifindex;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
        eg_md.qos.tc = hdr.bridged_md.base.tc;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
        eg_md.flags.routed = hdr.bridged_md.base.routed;
        eg_md.flags.peer_link = hdr.bridged_md.base.peer_link;
//      eg_md.flags.capture_ts = hdr.bridged_md.base.capture_ts;
        eg_md.pkt_type = hdr.bridged_md.base.pkt_type;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        eg_md.qos.qid = hdr.bridged_md.base.qid;
//#ifdef EGRESS_ACL_ENABLE







        eg_md.outer_nexthop = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel.index = hdr.bridged_md.tunnel.index;
        eg_md.tunnel.hash = hdr.bridged_md.tunnel.hash;
  eg_md.vrf = hdr.bridged_md.tunnel.vrf;
        eg_md.tunnel.terminate = hdr.bridged_md.tunnel.terminate;







        //transition parse_ethernet;

        // -----------------------------
        // ----- EXTREME NETWORKS -----
        // -----------------------------
        eg_md.orig_pkt_had_nsh = hdr.bridged_md.base.orig_pkt_had_nsh;

        eg_md.nsh_extr.valid = hdr.bridged_md.base.nsh_extr_valid;
        eg_md.nsh_extr.end_of_chain = hdr.bridged_md.base.nsh_extr_end_of_chain;

        // base: word 0

        // base: word 1
        eg_md.nsh_extr.spi = hdr.bridged_md.base.nsh_extr_spi;
        eg_md.nsh_extr.si = hdr.bridged_md.base.nsh_extr_si;

        // ext: type 2 - word 0

        // ext: type 2 - word 1+
        eg_md.nsh_extr.extr_srvc_func_bitmask_local = hdr.bridged_md.base.nsh_extr_srvc_func_bitmask_local; //  1 byte
        eg_md.nsh_extr.extr_srvc_func_bitmask_remote = hdr.bridged_md.base.nsh_extr_srvc_func_bitmask_remote; //  1 byte
        eg_md.nsh_extr.extr_tenant_id = hdr.bridged_md.base.nsh_extr_tenant_id; //  3 bytes
        eg_md.nsh_extr.extr_flow_type = hdr.bridged_md.base.nsh_extr_flow_type; //  1 byte?

  // dedup stuff






        // -----------------------------

        //transition accept;
        //transition snoop_underlay;
        //transition select(eg_md.nsh_extr.valid) {
        transition select(eg_md.orig_pkt_had_nsh) {
            0: parse_underlay_l2_ethernet;
            1: parse_underlay_nsh;
        }
    }

    state parse_deflected_pkt {
# 139 "npb_egr_parser.p4"
    }

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.type = port_md.type;
        eg_md.mirror.session_id = port_md.session_id;
        eg_md.ingress_timestamp = port_md.timestamp;
  eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = cpu_md.src;
        eg_md.mirror.type = cpu_md.type;
  eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        eg_md.bd = cpu_md.bd;
        // eg_md.ingress_port = cpu_md.md.port;
        // eg_md.ingress_ifindex = cpu_md.md.ifindex;
        eg_md.cpu_reason = cpu_md.reason_code;
        transition accept;
    }

    state parse_dtel_drop_metadata {
# 188 "npb_egr_parser.p4"
        transition reject;

    }

    state parse_dtel_switch_local_metadata {
# 214 "npb_egr_parser.p4"
        transition reject;

    }


    state parse_underlay_nsh {
        pkt.extract(hdr.nsh_extr_underlay);
        transition parse_underlay_l2_ethernet;
    }


    ///////////////////////////////////////////////////////////////////////////
    // L2 Underlay (L2-U)
    ///////////////////////////////////////////////////////////////////////////

    // Subparsers are broken in v8.7.0:
    // Any data set down in the subparser, except maybe header extractions,
    // will not be visible up here in the main parser.
    // 
    // // shared fanout/branch state to save tcam resource
    // state parse_underlay_l2 {
    //     parser_underlay_l2.apply(pkt, hdr, ether_type);
    //     transition select(ether_type) {
    //         ETHERTYPE_MPLS : parse_mpls;
    //         ETHERTYPE_IPV4 : parse_ipv4;
    //         ETHERTYPE_IPV6 : parse_ipv6;
    //         default : accept;
    //     }
    // }

    ///////////////////////////////////////////////////////////////////////////
    state parse_underlay_l2_ethernet {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_underlay_l2_br;
            0x8926 : parse_underlay_l2_vn;
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vlan {
     pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x8100 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    // shared fanout/branch state to save tcam resource
    state parse_underlay_l2_ether_type {
        transition select(ether_type) {
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            //(5, 0, 0) : parse_l3_protocol;
            //(5, 2, 0) : parse_l3_protocol;
            (5, 3w2 &&& 3w5, 0): parse_l3_protocol;
            default : accept;
        }
    }

    state parse_ipv6 {

        pkt.extract(hdr.ipv6);
        protocol = hdr.ipv6.next_hdr;
        transition parse_l3_protocol;



    }

    // shared fanout/branch state to save tcam resource
    state parse_l3_protocol {
        transition select(protocol) {
//#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)
           4: parse_inner_ipv4;
           41: parse_inner_ipv6;
//#endif
           17: parse_udp;
           6: parse_tcp;
           0x84: parse_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_esp;
           47: parse_gre;
           default : accept;
       }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.src_port, hdr.udp.dst_port) {
            (_, 4789): parse_vxlan;

            (_, 2123): parse_gtp_c;
            (2123, _): parse_gtp_c;
            (_, 2152): parse_gtp_u;
            (2152, _): parse_gtp_u;

            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X
    ///////////////////////////////////////////////////////////////////////////////

    state parse_mpls {
# 386 "npb_egr_parser.p4"
        transition accept;

    }
# 400 "npb_egr_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels
    ///////////////////////////////////////////////////////////////////////////

    state parse_vxlan {

        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;



    }

    state parse_gre {
     pkt.extract(hdr.gre);
        //todo: verify(hdr.gre.version == 0, error.GreVersionNotZero);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        transition select(
            hdr.gre.C,
            hdr.gre.R,
            hdr.gre.K,
            hdr.gre.S,
            hdr.gre.s,
            hdr.gre.recurse,
            hdr.gre.version,
            hdr.gre.proto) {

            (0,0,1,0,0,0,0,0x6558): parse_nvgre;
            (0,0,0,0,0,0,0,0x8847): parse_mpls;
            (0,0,0,0,0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6;
            //(0,0,0,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t1;
            //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t2;
            //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_erspan_t3;
            default: accept;
        }
    }

    state parse_nvgre {
     pkt.extract(hdr.nvgre);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_NVGRE;
     transition parse_inner_ethernet;
    }

    state parse_esp {
        pkt.extract(hdr.esp);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_ESP;
        transition accept;
    }



    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    ///////////////////////////////////////////////////////////////////////////
    // GTP-C
    ///////////////////////////////////////////////////////////////////////////

    // state parse_gtp_c {
    //     pkt.extract(hdr.gtp_v2_base);
    //     transition select(hdr.gtp_v2_base.version, hdr.gtp_v2_base.T) {
    //         (2, 1): parse_gtp_c_tied;
    //         default: accept;
    //     }
    // }
    // 
    // state parse_gtp_c_teid {
    //     pkt.extract(hdr.gtp_v1_v2_teid);
    // 	transition accept;
    // }

    state parse_gtp_c {
        gtp_v2_base_h snoop_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        transition select(snoop_gtp_v2_base.version, snoop_gtp_v2_base.T) {
            (2, 1): extract_gtp_c;
            default: accept;
        }
    }

    state extract_gtp_c {
        pkt.extract(hdr.gtp_v2_base);
        pkt.extract(hdr.gtp_v1_v2_teid);
     transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // GTP-U
    ///////////////////////////////////////////////////////////////////////////
    // Does not support parsing GTP v1 optional word
    // Does not support parsing (TLV) extension headers

    // state parse_gtp_u {
    //     pkt.extract(hdr.gtp_v1_base);
    //     transition select(
    //         hdr.gtp_v1_base.version,
    //         hdr.gtp_v1_base.PT,
    //         hdr.gtp_v1_base.E,
    //         hdr.gtp_v1_base.S,
    //         hdr.gtp_v1_base.PN
    //         pkt.lookahead<bit<4>>()) {
    // 
    //         (1, 1, 0, 0, 0, 4): parse_inner_ipv4;
    //         (1, 1, 0, 0, 0, 6): parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

    state parse_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_gtp_u;
            default: accept;
        }
    }

    state extract_gtp_u {
        pkt.extract(hdr.gtp_v1_base);
        pkt.extract(hdr.gtp_v1_v2_teid);
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: accept;
        }
    }
# 544 "npb_egr_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 2 (ETH-T)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        inner_ether_type = hdr.inner_ethernet.ether_type;
        transition select(hdr.inner_ethernet.ether_type) {
            0x8100 : parse_inner_vlan;
            default : parse_inner_ether_type;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        inner_ether_type = hdr.inner_vlan_tag.ether_type;
        transition parse_inner_ether_type;
    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_ether_type {
        transition select(inner_ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////
    // todo: When barefoot fixes case#8406, we should be able to use a common
    //       subparser for L3 parsing across both outer and inner. This will
    //       result in additional (tcam) resource savings. That being said,
    //       a subparser here can be a little tricky: We may need to use
    //       additional metadata or check valid bits to distinguish between
    //       v4 and v6 when exiting the subparser (into the famout branch).
    //       Also, would we need to indicate that we're finished parsing in
    //       the case of icmp/igmp (if these are done in the subparser(s)).

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_protocol = hdr.inner_ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_l3_protocol;
            //(5, 2, 0): parse_inner_l3_protocol;
            (5, 3w2 &&& 3w5, 0): parse_inner_l3_protocol;
            default: accept;
        }
    }

    state parse_inner_ipv6 {

        pkt.extract(hdr.inner_ipv6);
        inner_protocol = hdr.inner_ipv6.next_hdr;
        transition parse_inner_l3_protocol;



    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_l3_protocol {
        transition select(inner_protocol) {
           17: parse_inner_udp;
           6: parse_inner_tcp;
           0x84: parse_inner_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_inner_esp;
           47: parse_inner_gre;
           default : accept;
       }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Tunnels
    ///////////////////////////////////////////////////////////////////////////

    // todo: do we need to parse this? extract?
    state parse_inner_esp {
        pkt.extract(hdr.inner_esp);
        transition accept;
    }

    // todo: do we need to parse this? extract?
    state parse_inner_gre {
        pkt.extract(hdr.inner_gre);
        transition accept;
    }



// 
// ///////////////////////////////////////////////////////////////////////////////
// // Underlay Encaps
// ///////////////////////////////////////////////////////////////////////////////
// 
// //-----------------------------------------------------------------------------
// // Encapsulated Remote Switch Port Analyzer (ERSPAN)
// //-----------------------------------------------------------------------------
// 
// state parse_erspan_t1 {
//     pkt.extract(hdr.erspan_type1);
//     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T1
//     transition parse_inner_ethernet;
// }
// 
// state parse_erspan_t2 {
//     pkt.extract(hdr.erspan_type2);
//     //verify(hdr.erspan_typeII.version == 1, error.Erspan2VersionNotOne);
//     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T2
//     transition parse_inner_ethernet;
// }
// 
// // state parse_erspan_t3 {
// //     pkt.extract(hdr.erspan_type3);
// //     //verify(hdr.erspan_typeIII.version == 2, error.Erspan3VersionNotTwo);
// //     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T3
// //     transition select(hdr.erspan_type3.o) {
// //         1: parse_erspan_type3_platform;
// //         default: parse_inner_ethernet;
// //     }
// // }
// // 
// // state parse_erspan_type3_platform {
// //     pkt.extract(hdr.erspan_platform);
// //     transition parse_inner_ethernet;
// // }
// 
// 


}
# 26 "parde.p4" 2

//-----------------------------------------------------------------------------
// Pktgen parser
//-----------------------------------------------------------------------------

// -------------------------------------
// Extreme Networks - Added
// -------------------------------------

parser PktgenParser<H>(packet_in pkt,
                       inout switch_header_t hdr,
                       inout H md) {
    state start {



        transition reject;

    }

    state parse_pktgen {
        transition reject;
    }
}

//-----------------------------------------------------------------------------
// Segment routing extension header parser
//-----------------------------------------------------------------------------
parser SRHParser(packet_in pkt, inout switch_header_t hdr) {
    state start {



        transition accept;

    }

    state parse_srh {
        //TODO(msharif) : implement SRH parser.
        transition accept;
    }
}



//=============================================================================
// Ingress parser
//=============================================================================

// -------------------------------------
// Extreme Networks - Modified
// -------------------------------------


/*
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) inner_ipv4_checksum;
    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //    1 : parse_resubmit;
        //    0 : parse_port_metadata;
        // }
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition accept;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
        ig_md.port_lag_label = port_md.port_lag_label;
        ig_md.ifindex = port_md.ifindex;
        transition parse_packet;
    }

    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, ig_intr_md.ingress_port) {
            (ETHERTYPE_IPV4, _) : parse_ipv4;
            (ETHERTYPE_ARP, _) : parse_arp;
            (ETHERTYPE_IPV6, _) : parse_ipv6;
            (ETHERTYPE_VLAN, _) : parse_vlan;
            (ETHERTYPE_QINQ, _) : parse_vlan;
            (ETHERTYPE_FCOE, _) : parse_fcoe;
            cpu_port  : parse_cpu;
            default : accept;
        }
    }

    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        ig_md.bypass = hdr.cpu.reason_code;
        ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;
        transition select(hdr.cpu.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_QINQ : parse_vlan;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            //TODO (ipv4.ihl > 6)
            (5, _, _) : parse_ipv4_no_options;
            //(6, _, _) : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.opaque_option);
        // ipv4_checksum.add(hdr.opaque_option);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_ICMP : parse_icmp;
            IP_PROTOCOLS_IGMP : parse_igmp;
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            IP_PROTOCOLS_IPV4 : parse_ipinip;
            IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6 : parse_icmp;
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            IP_PROTOCOLS_IPV4 : parse_ipinip;
            IP_PROTOCOLS_IPV6 : parse_ipv6inip;
            default : accept;
        }
#else
        transition accept;
#endif
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            udp_port_vxlan : parse_vxlan;
            UDP_PORT_ROCEV2 : parse_rocev2;
	        default : accept;
	    }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }

    state parse_rocev2 {
#ifdef ROCEV2_ACL_ENABLE
        pkt.extract(hdr.rocev2_bth);
#else
        transition accept;
#endif
    }

    state parse_fcoe {
#ifdef FCOE_ACL_ENABLE
        pkt.extract(hdr.fcoe_fc);
#else
        transition accept;
#endif
    }

    state parse_vxlan {
#ifdef VXLAN_ENABLE
        pkt.extract(hdr.vxlan);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.tunnel.id = hdr.vxlan.vni;
        transition parse_inner_ethernet;
#else
        transition accept;
#endif
    }

    state parse_ipinip {
#ifdef IPINIP_ENABLE
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;
#else
        transition accept;
#endif
    }

    state parse_ipv6inip {
#if defined(IPINIP_ENABLE) && defined(IPV6_TUNNEL_ENABLE)
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;
#else
        transition accept;
#endif
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTOCOLS_ICMP : parse_inner_icmp;
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
#ifdef IPV6_TUNNEL_ENABLE
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            IP_PROTOCOLS_ICMPV6 : parse_inner_icmp;
            IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
#else
        transition accept;
#endif
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }

}
*/

//----------------------------------------------------------------------------
// Egress parser
//----------------------------------------------------------------------------

// -------------------------------------
// Extreme Networks - Modified
// -------------------------------------

/*
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    value_set<bit<16>>(1) udp_port_vxlan;
    value_set<switch_cpu_port_value_set_t>(1) cpu_port;

    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;
        eg_md.qos.qdepth = eg_intr_md.enq_qdepth;

#ifdef MIRROR_ENABLE
        switch_port_mirror_metadata_h mirror_md = pkt.lookahead<switch_port_mirror_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (1, _, _) : parse_deflected_pkt;
            (_, SWITCH_PKT_SRC_BRIDGED, _) : parse_bridged_pkt;
            (_, _, SWITCH_MIRROR_TYPE_PORT) : parse_port_mirrored_metadata;
            (_, SWITCH_PKT_SRC_CLONED_EGRESS, SWITCH_MIRROR_TYPE_CPU) : parse_cpu_mirrored_metadata;
            (_, _, SWITCH_MIRROR_TYPE_DTEL_DROP) : parse_dtel_drop_metadata;
            (_, _, SWITCH_MIRROR_TYPE_DTEL_SWITCH_LOCAL) : parse_dtel_switch_local_metadata;
        }
#else
        transition parse_bridged_pkt;
#endif
    }

    state parse_bridged_pkt {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.ingress_ifindex = hdr.bridged_md.base.ingress_ifindex;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
        eg_md.qos.tc = hdr.bridged_md.base.tc;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
        eg_md.flags.routed = hdr.bridged_md.base.routed;
        eg_md.flags.peer_link = hdr.bridged_md.base.peer_link;
//      eg_md.flags.capture_ts = hdr.bridged_md.base.capture_ts;
        eg_md.pkt_type = hdr.bridged_md.base.pkt_type;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        eg_md.qos.qid = hdr.bridged_md.base.qid;

#ifdef EGRESS_ACL_ENABLE
        eg_md.l4_port_label = hdr.bridged_md.acl.l4_port_label;
        eg_md.lkp.l4_src_port = hdr.bridged_md.acl.l4_src_port;
        eg_md.lkp.l4_dst_port = hdr.bridged_md.acl.l4_dst_port;
        eg_md.lkp.tcp_flags = hdr.bridged_md.acl.tcp_flags;
#endif
#ifdef TUNNEL_ENABLE
        eg_md.outer_nexthop = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel.index = hdr.bridged_md.tunnel.index;
        eg_md.tunnel.hash = hdr.bridged_md.tunnel.hash;
        eg_md.vrf = hdr.bridged_md.tunnel.vrf;
        eg_md.tunnel.terminate = hdr.bridged_md.tunnel.terminate;
#endif
#ifdef DTEL_ENABLE
        eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        eg_md.dtel.hash = hdr.bridged_md.dtel.hash;
        eg_md.dtel.session_id = hdr.bridged_md.dtel.session_id;
#endif

        transition parse_ethernet;
    }

    state parse_deflected_pkt {
#ifdef DTEL_ENABLE
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_DEFLECTED;
        eg_md.dtel.report_type = hdr.bridged_md.dtel.report_type;
        eg_md.dtel.hash = hdr.bridged_md.dtel.hash;
        eg_md.mirror.session_id = hdr.bridged_md.dtel.session_id;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        hdr.dtel_drop_report = {
            0,
            0, //XXX hdr.bridged_md.base.ingress_port;
            0,
            SWITCH_PORT_INVALID,
            0,
            0, //XXX hdr.bridged_md.base.qid,
            SWITCH_DROP_REASON_TRAFFIC_MANAGER,
            0};
        transition accept;
#endif
    }

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = port_md.src;
        eg_md.mirror.type = port_md.type;
        eg_md.mirror.session_id = port_md.session_id;
        eg_md.ingress_timestamp = port_md.timestamp;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = cpu_md.src;
        eg_md.mirror.type = cpu_md.type;
        eg_md.bypass = ~SWITCH_EGRESS_BYPASS_MTU;
        eg_md.bd = cpu_md.bd;
        // eg_md.ingress_port = cpu_md.md.port;
        // eg_md.ingress_ifindex = cpu_md.md.ifindex;
        eg_md.cpu_reason = cpu_md.reason_code;
        transition accept;
    }

    state parse_dtel_drop_metadata {
#ifdef DTEL_ENABLE
        switch_dtel_drop_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        eg_md.mirror.session_id = dtel_md.session_id;
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_drop_report = {
            0,
            dtel_md.ingress_port,
            0,
            SWITCH_PORT_INVALID,
            0,
            dtel_md.qid,
            dtel_md.drop_reason,
            0};
        transition accept;
#else
        transition reject;
#endif
    }

    state parse_dtel_switch_local_metadata {
#ifdef DTEL_ENABLE
        switch_dtel_switch_local_mirror_metadata_h dtel_md;
        pkt.extract(dtel_md);
        eg_md.pkt_src = dtel_md.src;
        eg_md.mirror.type = dtel_md.type;
        eg_md.dtel.report_type = dtel_md.report_type;
        eg_md.dtel.hash = dtel_md.hash;
        eg_md.mirror.session_id = dtel_md.session_id;
        eg_md.ingress_timestamp = dtel_md.timestamp;
        hdr.dtel_switch_local_report = {
            0,
            dtel_md.ingress_port,
            0,
            dtel_md.egress_port,
            0,
            dtel_md.qid,
            0,
            dtel_md.qdepth,
            dtel_md.egress_timestamp};
        transition accept;
#else
        transition reject;
#endif
    }


    state parse_packet {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type, eg_intr_md.egress_port) {
            cpu_port : parse_cpu;
            (ETHERTYPE_IPV4, _) : parse_ipv4;
            (ETHERTYPE_IPV6, _) : parse_ipv6;
            (ETHERTYPE_VLAN, _) : parse_vlan;
            (ETHERTYPE_QINQ, _) : parse_vlan;
            default : accept;
        }
    }

    state parse_cpu {
        eg_md.bypass = SWITCH_EGRESS_BYPASS_ALL;
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol, hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
#ifdef TUNNEL_ENABLE
            (IP_PROTOCOLS_UDP, 5, 0, 0) : parse_udp;
#ifdef IPINIP_ENABLE
            (IP_PROTOCOLS_IPV4, 5, 0, 0) : parse_inner_ipv4;
            (IP_PROTOCOLS_IPV6, 5, 0, 0) : parse_inner_ipv6;
#endif
#endif
            (_, 6, _, _) : parse_ipv4_options;
            default : accept;
        }
    }

    state parse_ipv4_options {
        //TODO(msharif) : Add support for ipv4.ihl > 6.
        pkt.extract(hdr.opaque_option);
        transition select(hdr.ipv4.protocol) {
#ifdef TUNNEL_ENABLE
            // IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
#ifdef IPINIP_ENABLE
            IP_PROTOCOLS_IPV4 : parse_inner_ipv4;
            IP_PROTOCOLS_IPV6 : parse_inner_ipv6;
#endif
#endif
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
#ifdef IPV6_ENABLE
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
#ifdef IPV6_TUNNEL_ENABLE
            // IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
#ifdef IPINIP_ENABLE
            IP_PROTOCOLS_IPV4 : parse_inner_ipv4;
            IP_PROTOCOLS_IPV6 : parse_inner_ipv6;
#endif // IPINIP_ENABLE
#endif // IPV6_TUNNEL_ENABLE
            default : accept;
        }
#else
        transition accept;
#endif // IPV6_ENABLE
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
          udp_port_vxlan : parse_vxlan;
	        default : accept;
	    }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_vxlan {
#ifdef VXLAN_ENABLE
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
#else
        transition accept;
#endif
    }

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            ETHERTYPE_IPV6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            // IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
#ifdef IPV6_TUNNEL_ENABLE
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.next_hdr) {
            // IP_PROTOCOLS_TCP : parse_inner_tcp;
            IP_PROTOCOLS_UDP : parse_inner_udp;
            default : accept;
        }
#else
        transition accept;
#endif
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }
}
*/


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.
    Mirror() mirror;

    apply {
# 708 "parde.p4"
    }
}

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.
    Mirror() mirror;

    apply {
# 761 "parde.p4"
    }
}

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IngressMirror() mirror;
    Digest<switch_learning_digest_t>() digest;

    apply {
        mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING) {
            digest.pack({ig_md.bd, ig_md.ifindex, ig_md.lkp.mac_src_addr});
        }

  // -------------------------------------
  // Extreme Networks - Modified
  // -------------------------------------

/*
        pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.opaque_option);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.rocev2_bth); // Ingress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
*/

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.

        // ***** UNDERLAY *****
        pkt.emit(hdr.nsh_extr_underlay);
// #ifdef ERSPAN_UNDERLAY_ENABLE
//         pkt.emit(hdr.erspan_type1_underlay);
//         pkt.emit(hdr.erspan_type2_underlay);
// #endif /* ERSPAN_UNDERLAY_ENABLE */

        // ***** OUTER *****
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.e_tag);
        pkt.emit(hdr.vn_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre);

        pkt.emit(hdr.nvgre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.esp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.vxlan);

        pkt.emit(hdr.gtp_v1_base);
        pkt.emit(hdr.gtp_v2_base);
        pkt.emit(hdr.gtp_v1_v2_teid);
        pkt.emit(hdr.gtp_v1_optional);
# 850 "parde.p4"
        pkt.emit(hdr.udf);


        // ***** INNER *****
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_gre);
        pkt.emit(hdr.inner_sctp);
        pkt.emit(hdr.inner_esp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);

        pkt.emit(hdr.inner_udf);

    }
}


//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() mirror;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});
            // hdr.opaque_option.type,
            // hdr.opaque_option.length,
            // hdr.opaque_option.value});


        hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
            hdr.inner_ipv4.version,
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.diffserv,
            hdr.inner_ipv4.total_len,
            hdr.inner_ipv4.identification,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset,
            hdr.inner_ipv4.ttl,
            hdr.inner_ipv4.protocol,
            hdr.inner_ipv4.src_addr,
            hdr.inner_ipv4.dst_addr});


  // -------------------------------------
  // Extreme Networks - Modified
  // -------------------------------------

/*
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress only.
        pkt.emit(hdr.cpu); // Egress only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.dtel); // Egress only.
        pkt.emit(hdr.dtel_switch_local_report); // Egress only.
        pkt.emit(hdr.dtel_drop_report); // Egress only.
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        pkt.emit(hdr.erspan_type3); // Egress only.
        pkt.emit(hdr.erspan_platform); // Egress only.
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
*/

        // ***** UNDERLAY *****





        pkt.emit(hdr.ethernet_underlay);
        pkt.emit(hdr.vlan_tag_underlay);
        pkt.emit(hdr.nsh_extr_underlay);

        // ***** OUTER *****
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress Only.
        pkt.emit(hdr.cpu); // Egress Only.
        pkt.emit(hdr.timestamp); // Egress only.

        pkt.emit(hdr.e_tag);
        pkt.emit(hdr.vn_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre); // Egress Only.
# 975 "parde.p4"
        pkt.emit(hdr.nvgre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.esp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.vxlan);

        pkt.emit(hdr.gtp_v1_base);
        pkt.emit(hdr.gtp_v2_base);
        pkt.emit(hdr.gtp_v1_v2_teid);
        pkt.emit(hdr.gtp_v1_optional);






        // ***** INNER *****
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_gre);
        pkt.emit(hdr.inner_sctp);
        pkt.emit(hdr.inner_esp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
    }
}
# 48 "npb.p4" 2
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

//-----------------------------------------------------------------------------
// @param hdr : Parsed headers. For mirrored packet only Ethernet header is parsed.
// @param eg_md : Egress metadata fields.
// @param table_size : Number of mirror sessions.
//
// @flags PACKET_LENGTH_ADJUSTMENT : For mirrored packet, the length of the mirrored
// metadata fields is also accounted in the packet length. This flags enables the
// calculation of the packet length excluding the mirrored metadata fields.
//-----------------------------------------------------------------------------
control MirrorRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md)(
                      switch_uint32_t table_size=1024) {
    bit<16> length;

    action add_ethernet_header(in mac_addr_t src_addr,
                               in mac_addr_t dst_addr,
                               in bit<16> ether_type) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = ether_type;
        hdr.ethernet.src_addr = src_addr;
        hdr.ethernet.dst_addr = dst_addr;
    }

    action add_vlan_tag(vlan_id_t vid, bit<3> pcp, bit<16> ether_type) {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].pcp = pcp;
        // hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.vlan_tag[0].ether_type = ether_type;
    }

    action add_ipv4_header(in bit<8> diffserv,
                           in bit<8> ttl,
                           in bit<8> protocol,
                           in ipv4_addr_t src_addr,
                           in ipv4_addr_t dst_addr) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        hdr.ipv4.diffserv = diffserv;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.ttl = ttl;
        hdr.ipv4.protocol = protocol;
        hdr.ipv4.src_addr = src_addr;
        hdr.ipv4.dst_addr = dst_addr;
    }

    action add_gre_header(in bit<16> proto) {
        hdr.gre.setValid();
        // hdr.gre.C = 0;
        // hdr.gre.K = 0;
        // hdr.gre.S = 0;
        // hdr.gre.s = 0;
        // hdr.gre.recurse = 0;
        hdr.gre.flags = 0;
        hdr.gre.version = 0;
        hdr.gre.proto = proto;
    }

    action add_erspan_type2(bit<10> session_id) {
        //TODO(msharif): Support for GRE sequence number.
        hdr.erspan_type2.setValid();
        hdr.erspan_type2.version = 4w0x1;
        hdr.erspan_type2.vlan = 0;
        hdr.erspan_type2.cos_en_t = 0;
        hdr.erspan_type2.session_id = session_id;
    }

    action add_erspan_type3(bit<10> session_id, bit<32> timestamp, bool opt_sub_header) {
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.version = 4w0x2;
        hdr.erspan_type3.vlan = 0;
        hdr.erspan_type3.cos_bso_t = 0;
        hdr.erspan_type3.session_id = session_id;
        hdr.erspan_type3.timestamp = timestamp;
        hdr.erspan_type3.sgt = 0;
        hdr.erspan_type3.p = 0;
        hdr.erspan_type3.ft = 0; // Ethernet frame
        hdr.erspan_type3.hw_id = 0;
        //TODO(msharif): Set direction flag if EGRESS_PORT_MIRRORING is enabled.
        hdr.erspan_type3.d = 0;
        hdr.erspan_type3.gra = 0b10;
        if (opt_sub_header) {
            hdr.erspan_type3.o = 1;
            hdr.erspan_platform.setValid();
            hdr.erspan_platform.id = 0;
            hdr.erspan_platform.info = 0;
        } else {
            hdr.erspan_type3.o = 0;
        }
    }

    action rewrite_(switch_qid_t qid) {
        eg_md.qos.qid = qid;
    }

    action rewrite_rspan(switch_qid_t qid, bit<3> pcp, vlan_id_t vid) {





    }

    action rewrite_erspan_type2(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
        //TODO(msharif): Support for GRE sequence number.
# 158 "rewrite.p4"
    }

    action rewrite_erspan_type2_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
# 182 "rewrite.p4"
    }

    action rewrite_erspan_type3(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
# 205 "rewrite.p4"
    }

    action rewrite_erspan_type3_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
# 229 "rewrite.p4"
    }

    action rewrite_erspan_type3_platform_specific(
            switch_qid_t qid,
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
# 252 "rewrite.p4"
    }

    action rewrite_erspan_type3_platform_specific_with_vlan(
            switch_qid_t qid,
            bit<16> ether_type, mac_addr_t smac, mac_addr_t dmac,
            bit<3> pcp, vlan_id_t vid,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl) {
# 278 "rewrite.p4"
    }

    action rewrite_dtel_report(
            mac_addr_t smac, mac_addr_t dmac,
            ipv4_addr_t sip, ipv4_addr_t dip, bit<8> tos, bit<8> ttl,
            bit<16> udp_dst_port) {
# 304 "rewrite.p4"
    }


    table rewrite {
        key = { eg_md.mirror.session_id : exact; }
        actions = {
            NoAction;
            rewrite_;
            rewrite_rspan;
            rewrite_erspan_type2;
            rewrite_erspan_type3;
            rewrite_erspan_type3_platform_specific;
            rewrite_erspan_type2_with_vlan;
            rewrite_erspan_type3_with_vlan;
            rewrite_erspan_type3_platform_specific_with_vlan;
            rewrite_dtel_report;
        }

        const default_action = NoAction;
        size = table_size;
    }


    action adjust_length(bit<16> length_offset) {
        eg_md.pkt_length = eg_md.pkt_length + length_offset;
        eg_md.mirror.type = 0;
    }

    table pkt_length {
        key = { eg_md.mirror.type : exact; }
        actions = { adjust_length; }
        const entries = {
            1 : adjust_length(-14); // switch_port_mirror_metadata_h + 4 bytes of CRC
            2 : adjust_length(-14);
            3 : adjust_length(-14);
            4 : adjust_length(-15);
        }
    }

    apply {
# 352 "rewrite.p4"
    }
}

control Rewrite(inout switch_header_t hdr,
                inout switch_egress_metadata_t eg_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t bd_table_size) {
    EgressBd(bd_table_size) egress_bd;
    switch_smac_index_t smac_index;

    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {

        eg_md.flags.routed = false;
        eg_md.tunnel.type = type;

    }

    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
    }

    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id, bit<8> flow_id) {

        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        eg_md.tunnel.type = type;
        eg_md.tunnel.id = id;
        eg_md.tunnel.flow_id = flow_id; // extreme added

    }

    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {

        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
        eg_md.tunnel.type = type;

    }

    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {

        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.tunnel.type = type;
        eg_md.bd = eg_md.vrf;

    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    // For MAC-in-MAC, we want a hybrid of their above L2/L3 schemes.
    // In other words, we want to:
    //
    // - Retain the SA -- so clear the 'routed' flag (like l2).
    // - Change the DA                               (like l3).

/*
    action rewrite_l2_redirect_nsh(mac_addr_t dmac) {
        eg_md.flags.routed = false;
        hdr.ethernet_underlay.dst_addr = dmac;
    }

    // derek: is this needed?
    action rewrite_l2_redirect_bd_nsh(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.flags.routed = false;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = bd;
    }
*/

    table nexthop_rewrite {
        key = { eg_md.nexthop : exact; }
        actions = {
            NoAction;
            rewrite_l2_with_tunnel;
            rewrite_l3;
            rewrite_l3_with_tunnel;
            rewrite_l3_with_tunnel_bd;
            rewrite_l3_with_tunnel_id;
/*
            rewrite_l2_redirect_nsh; // extreme added
            rewrite_l2_redirect_bd_nsh; // extreme added
*/
        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

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

    // RFC 1112
    action rewrite_ipv4_multicast() {
        //XXX might be possible on Tofino as dst_addr[23] is 0.
        //hdr.ethernet.dst_addr[22:0] = hdr.ipv4.dst_addr[22:0];
        //hdr.ethernet.dst_addr[47:24] = 0x01005E;
    }

    // RFC 2464
    action rewrite_ipv6_multicast() {
        //hdr.ethernet.dst_addr[31:0] = hdr.ipv6.dst_addr[31:0];
        //hdr.ethernet.dst_addr[47:32] = 16w0x3333;
    }

    table multicast_rewrite {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv4.dst_addr[31:28] : ternary;
            //hdr.ipv6.isValid() : exact;
            //hdr.ipv6.dst_addr[127:96] : ternary;
        }

        actions = {
            NoAction;
            rewrite_ipv4_multicast;
            rewrite_ipv6_multicast;
        }

        const default_action = NoAction;
    }


    action rewrite_ipv4() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action rewrite_ipv6() {

        hdr.ipv6.hop_limit = hdr.ipv6.hop_limit - 1;

    }

    table ip_rewrite {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;

   hdr.nsh_extr_underlay.isValid() : exact; // extreme added
        }

        actions = {
            rewrite_ipv4;
            rewrite_ipv6;
        }

        const entries = {
   // extreme modified
/*
            (true, false) : rewrite_ipv4();
            (false, true) : rewrite_ipv6();
*/
            (true, false, false) : rewrite_ipv4(); // extreme added
            (false, true, false) : rewrite_ipv6(); // extreme added
        }
    }

    apply {
        // Should not rewrite packets redirected to CPU.
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0)) {
            nexthop_rewrite.apply();
        }

        egress_bd.apply(hdr, eg_md.bd, eg_md.pkt_type, eg_md.bd_label,
            smac_index, eg_md.checks.mtu);

        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.flags.routed) {
            ip_rewrite.apply();
            smac_rewrite.apply();
        }
    }
}
# 24 "port.p4" 2

//-----------------------------------------------------------------------------
// Ingress port mirroring
//-----------------------------------------------------------------------------
control PortMirror(
        in switch_port_t port,
        in switch_pkt_src_t src,
        inout switch_mirror_metadata_t mirror_md)(
        switch_uint32_t table_size=288) {

    action set_mirror_id(switch_mirror_session_t session_id) {
        mirror_md.type = 1;
        mirror_md.src = src;
        mirror_md.session_id = session_id;
    }

    table port_mirror {
        key = { port : exact; }
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

control IngressPortMapping(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t port_vlan_table_size,
        switch_uint32_t bd_table_size,
        switch_uint32_t port_table_size=288,
        switch_uint32_t vlan_table_size=4096,
        switch_uint32_t double_tag_table_size=1024) {

    PortMirror(port_table_size) port_mirror;
    ActionProfile(bd_table_size) bd_action_profile;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;

    // This register is used to check whether a port is a mermber of a vlan (bd)
    // or not. (port << 12 | vid) is used as the index to read the membership
    // status.To save resources, only 7-bit local port id is used to calculate
    // the indes.
    const bit<32> vlan_membership_size = 1 << 19;
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_membership) check_vlan_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    action terminate_cpu_packet() {
        // ig_md.bypass = hdr.cpu.reason_code;
        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_intr_md_for_tm.ucast_egress_port =
            (switch_port_t) hdr.fabric.dst_port_or_group;
        //XXX(msharif) : Fix this for Tofino2
        // ig_intr_md_for_tm.qid = hdr.cpu.egress_queue;
        ig_intr_md_for_tm.bypass_egress = hdr.cpu.tx_bypass;
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }

    action set_cpu_port_properties(
            switch_port_lag_index_t port_lag_index,
            switch_port_lag_label_t port_lag_label,
            switch_yid_t exclusion_id,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc) {
        ig_md.port_lag_index = port_lag_index;
        ig_md.port_lag_label = port_lag_label;
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

        terminate_cpu_packet();
    }

    action set_port_properties(
            switch_yid_t exclusion_id,
            switch_learning_mode_t learning_mode,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc,
            bool mac_pkt_class) {
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        ig_md.learning.port_mode = learning_mode;
        ig_md.checks.same_if = 0xffff;
        ig_md.flags.mac_pkt_class = mac_pkt_class;
    }

    table port_mapping {
        key = {
            ig_md.port : exact;
            hdr.cpu.isValid() : exact;
            hdr.cpu.ingress_port : exact;
        }

        actions = {
            set_port_properties;
            set_cpu_port_properties;
        }

        size = port_table_size * 2;
    }

    action port_vlan_miss() {
        //ig_md.flags.port_vlan_miss = true;
    }

    action set_bd_properties(switch_bd_t bd,
                             switch_vrf_t vrf,
                             switch_bd_label_t bd_label,
                             switch_rid_t rid,
                             switch_stp_group_t stp_group,
                             switch_learning_mode_t learning_mode,
                             bool ipv4_unicast_enable,
                             bool ipv4_multicast_enable,
                             bool igmp_snooping_enable,
                             bool ipv6_unicast_enable,
                             bool ipv6_multicast_enable,
                             bool mld_snooping_enable,
                             switch_multicast_rpf_group_t mrpf_group,
                             switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        ig_intr_md_for_tm.rid = rid;
        ig_md.rmac_group = rmac_group;
        ig_md.stp.group = stp_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = learning_mode;
        ig_md.ipv4.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6.unicast_enable = ipv6_unicast_enable;
        ig_md.ipv6.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6.multicast_snooping = mld_snooping_enable;
    }

    // (port, vlan[0], vlan[1]) --> bd mapping
    table port_double_tag_to_bd_mapping {
        key = {
            ig_md.port_lag_index : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[0].vid : exact;
            hdr.vlan_tag[1].isValid() : exact;
            hdr.vlan_tag[1].vid : exact;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = NoAction;
        implementation = bd_action_profile;
        size = double_tag_table_size;
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
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].vid : ternary;
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
            hdr.vlan_tag[0].vid : exact;
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
        key = { hdr.cpu.ingress_bd : exact; }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = bd_table_size;
    }

    action set_interface_properties(switch_ifindex_t ifindex, switch_if_label_t if_label) {
        ig_md.ifindex = ifindex;
        ig_md.checks.same_if = 0xffff;
        ig_md.if_label = if_label;
    }

    table port_vlan_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index : exact;
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            NoAction;
            set_interface_properties;
        }

        const default_action = NoAction;
        size = port_vlan_table_size;
    }

    table port_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index : exact;
        }

        actions = {
            NoAction;
            set_interface_properties;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    action set_peer_link_properties() {
        ig_intr_md_for_tm.rid = SWITCH_RID_DEFAULT;
        ig_md.flags.peer_link = true;
    }

    table peer_link {
        key = { ig_md.port_lag_index : exact; }
        actions = {
            NoAction;
            set_peer_link_properties;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    apply {
        switch (port_mapping.apply().action_run) {
            set_cpu_port_properties : {
                cpu_to_bd_mapping.apply();
            }

            set_port_properties : {



                    if (!port_vlan_to_bd_mapping.apply().hit) {
                        if (hdr.vlan_tag[0].isValid())
                            vlan_to_bd_mapping.apply();
                    }
                }
            }
# 341 "port.p4"
        // Check vlan membership
        if (hdr.vlan_tag[0].isValid() && !hdr.vlan_tag[1].isValid() && (bit<1>) ig_md.flags.port_vlan_miss == 0) {
            bit<32> pv_hash_ = hash.get({ig_md.port[6:0], hdr.vlan_tag[0].vid});
            ig_md.flags.port_vlan_miss =
                (bool)check_vlan_membership.execute(pv_hash_);
        }
# 355 "port.p4"
    }
}

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
//
// @flag MLAG_ENABLE : Enable multi-chassis LAG.
// ----------------------------------------------------------------------------

control LAG(inout switch_ingress_metadata_t ig_md,
            in bit<16> hash,
            out switch_port_t egress_port) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(1024, selector_hash, SelectorMode_t.FAIR) lag_selector;

    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }

    action set_peer_link_port(switch_port_t port, switch_ifindex_t ifindex) {





    }

    action lag_miss() { }

    table lag {
        key = {



            ig_md.egress_ifindex : exact @name("port_lag_index");

            hash : selector;
        }

        actions = {
            lag_miss;
            set_lag_port;
            set_peer_link_port;
        }

        const default_action = lag_miss;
        size = 1024;
        implementation = lag_selector;
    }

    apply {
        lag.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress port lookup
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param port : Egress port.
//
// @flag EGRESS_PORT_MIRROR_ENABLE: Enables egress port-base mirroring.
//-----------------------------------------------------------------------------
control EgressPortMapping(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {
    PortMirror(table_size) port_mirror;

    action port_normal(switch_port_lag_index_t port_lag_index,
                       switch_port_lag_label_t port_lag_label,
                       switch_qos_group_t qos_group,
                       bool mlag_member) {
        eg_md.port_lag_index = port_lag_index;
        eg_md.port_lag_label = port_lag_label;
        eg_md.qos.group = qos_group;
        eg_md.flags.mlag_member = mlag_member;
    }

    action cpu_rewrite() {
        hdr.fabric.setValid();
        hdr.fabric.reserved = 0;
        hdr.fabric.color = 0;
        hdr.fabric.qos = 0;
        hdr.fabric.reserved2 = 0;
        hdr.fabric.dst_port_or_group = 0;

        hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.reserved = 0;
        hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
        hdr.cpu.ingress_ifindex = (bit<16>) eg_md.ingress_ifindex;
        hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
        hdr.cpu.reason_code = eg_md.cpu_reason;
        hdr.cpu.ether_type = hdr.ethernet.ether_type;

        hdr.ethernet.ether_type = 0x9000;
    }

    action port_cpu(switch_port_lag_index_t port_lag_index) {
        cpu_rewrite();
    }

    @ignore_table_dependency("SwitchEgress.mirror_rewrite.rewrite")
    table port_mapping {
        key = { port : exact; }

        actions = {
            port_normal;
            port_cpu;
        }

        size = table_size;
    }

    apply {
        port_mapping.apply();




    }
}
# 49 "npb.p4" 2
# 1 "validation.p4" 1
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
// Packet validaion
// Validate ethernet, Ipv4 or Ipv6 headers and set the common lookup fields.
// ============================================================================
control PktValidation(
        in switch_header_t hdr,
        inout switch_ingress_flags_t flags,
        inout switch_lookup_fields_t lkp,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        out switch_drop_reason_t drop_reason) {
//-----------------------------------------------------------------------------
// Validate outer packet header
// - Drop the packet if src addr is zero or multicast or dst addr is zero.
//-----------------------------------------------------------------------------
    const switch_uint32_t table_size = 64;

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    action valid_unicast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }

    action valid_multicast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }

    action valid_broadcast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }

    action valid_unicast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }

    action valid_multicast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }

    action valid_broadcast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }

    action valid_unicast_pkt_double_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[1].ether_type;
        lkp.pcp = hdr.vlan_tag[1].pcp;
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;



        }

        actions = {
            malformed_pkt;
            valid_unicast_pkt_untagged;
            valid_multicast_pkt_untagged;
            valid_broadcast_pkt_untagged;
            valid_unicast_pkt_tagged;
            valid_multicast_pkt_tagged;
            valid_broadcast_pkt_tagged;



        }

        size = table_size;
        /* const entries = {
            (_, _, _) : malformed_pkt(SWITCH_DROP_SRC_MAC_MULTICAST);
            (0, _, _) : malformed_pkt(SWITCH_DROP_SRC_MAC_ZERO);
            (_, 0, _) : malformed_pkt(SWITCH_DROP_DST_MAC_ZERO);
        } */
    }

//-----------------------------------------------------------------------------
// Validate outer IPv4 header and set the lookup fields.
// - Drop the packet if ttl is zero, ihl is invalid, src addr is multicast, or
// - version is invalid.
//-----------------------------------------------------------------------------
    action valid_ipv4_pkt() {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ip_src_addr = (bit<128>) hdr.ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) hdr.ipv4.dst_addr;
    }

    table validate_ipv4 {
        key = {
            flags.ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            //TODO(msharif) This is the right place to set some flags to detect
            // IP fragmentation.
            // hdr.ipv4.flags : ternary;
            // hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:24] : ternary; //TODO define the bit range.
        }

        actions = {
            valid_ipv4_pkt;
            malformed_pkt;
        }

        size = table_size;
        /* XXX Driver does not support static entries for TCAM tables
        const default_action = malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        const entries = {
            (_, _, _, _, 0x7f) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK);
            (_, _, _, _, 0xe0 &&& 0xf0) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST);
            (_, _, _, 0, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO);
            (_, _, 0 &&& 0xc, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (_, _, 4 &&& 0xf, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (false, 4 &&& 0xf, _, _, _) : valid_ipv4_pkt();
            (true, 4 &&& 0xf, _, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        }
        */
    }


//-----------------------------------------------------------------------------
// Validate outer IPv6 header and set the lookup fields.
// - Drop the packet if hop_limit is zero, src addr is multicast or version is
// invalid.
//-----------------------------------------------------------------------------

    action valid_ipv6_pkt(bool is_link_local) {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.ipv6.traffic_class;
        lkp.ip_proto = hdr.ipv6.next_hdr;
        lkp.ip_ttl = hdr.ipv6.hop_limit;
        lkp.ip_src_addr = hdr.ipv6.src_addr;
        lkp.ip_dst_addr = hdr.ipv6.dst_addr;
        flags.link_local = is_link_local;
    }

    table validate_ipv6 {
        key = {
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.ipv6.src_addr[127:96] : ternary; //TODO define the bit range.
        }

        actions = {
            valid_ipv6_pkt;
            malformed_pkt;
        }

        size = table_size;
        /* XXX Driver does not support static entries for TCAM tables
        const default_action = malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        const entries = {
            (_, _, 0xff) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST);
            (_, 0, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO);
            (6, _, _) : valid_ipv6_pkt(false);
        }
        */
    }

//-----------------------------------------------------------------------------
// Set L4 and other lookup fields
//-----------------------------------------------------------------------------
    action set_tcp_ports() {
        lkp.l4_src_port = hdr.tcp.src_port;
        lkp.l4_dst_port = hdr.tcp.dst_port;
        lkp.tcp_flags = hdr.tcp.flags;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.udp.src_port;
        lkp.l4_dst_port = hdr.udp.dst_port;
        lkp.tcp_flags = 0;
    }

    action set_icmp_type() {
        lkp.l4_src_port[7:0] = hdr.icmp.type;
        lkp.l4_src_port[15:8] = hdr.icmp.code;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
    }

    action set_igmp_type() {






    }

    action set_arp_opcode() {
        lkp.l4_src_port = 0;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
        lkp.arp_opcode = hdr.arp.opcode;
    }

    // Not much of a validation as it only sets the lookup fields.
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid() : exact;
            hdr.igmp.isValid() : exact;
            hdr.arp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_icmp_type;
            set_igmp_type;
            set_arp_opcode;
        }

        const default_action = NoAction;
        const entries = {
            (true, false, false, false, false) : set_tcp_ports();
            (false, true, false, false, false) : set_udp_ports();
            (false, false, true, false, false) : set_icmp_type();
            (false, false, false, true, false) : set_igmp_type();
            (false, false, false, false, true) : set_arp_opcode();
        }
    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    // Validate Extreme NSH underlay header.
    //
    // Currently, we only support parsing of our own, fixed length Extreme
    // (MD-Type2), NSH. This validation logic will drop any NSH pkt that does
    // not conform. In the future, when PHV resources are less tight, we plan
    // to add support for parsing non-Extreme NSH as well.
    //
    //   Drop the packet if:
    //
    //        version != 0                     -> Base Header          
    //              o == 1  (oam)                     :                
    //            ttl == 0                            :                
    //            len != 5  (4B words)                :                
    //        md_type != 2                            :                
    //     next_proto != 3  (enet)                    :                
    //             si == 0                     -> Service Path Header      
    //       md_class != ?  (todo)             -> Variable Length Context Header
    //           type != ?  (todo)                    :                
    //         md_len != 8  (bytes)                   :                
    //           todo == ?  (any checks here?) -> Variable Length Metadata   

    table validate_nsh {

        key = {
            hdr.nsh_extr_underlay.version : range;
            hdr.nsh_extr_underlay.o : ternary;
            hdr.nsh_extr_underlay.ttl : ternary;
            hdr.nsh_extr_underlay.len : range;
            hdr.nsh_extr_underlay.md_type : range;
            hdr.nsh_extr_underlay.next_proto : range;
            hdr.nsh_extr_underlay.si : ternary;
            //hdr.nsh_extr_underlay.md_class : ternary;
            //hdr.nsh_extr_underlay.type : ternary;
            hdr.nsh_extr_underlay.md_len : range;
            //hdr.nsh_extr_underlay.extr_xxx : ternary;
        }

        actions = {
            NoAction;
            malformed_pkt;
        }

        size = table_size;
        const default_action = NoAction;
        const entries = {
            // Can a range match type be a don't care? (it compiles..)
            (2w1 .. 2w3, _, _, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_VERSION_INVALID);
            (_, 1, _, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_OAM);
            (_, _, 0, _, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_TTL_ZERO);
            (_, _, _, 6w0 .. 6w4, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_LEN_INVALID);
            (_, _, _, 6w6 .. 6w63, _, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_LEN_INVALID);
            (_, _, _, _, 4w0 .. 4w1, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_MDTYPE_INVALID);
            (_, _, _, _, 4w3 .. 4w15, _, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_MDTYPE_INVALID);
            (_, _, _, _, _, 8w0 .. 8w2, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_NEXT_PROTO_INVALID);
            (_, _, _, _, _, 8w4 .. 8w255, _, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_NEXT_PROTO_INVALID);
            (_, _, _, _, _, _, 0, _):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_SI_ZERO);
            (_, _, _, _, _, _, _, 7w0 .. 7w7):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_MD_LEN_INVALID);
            (_, _, _, _, _, _, _, 7w9 .. 7w127):
            malformed_pkt(SWITCH_DROP_REASON_UNDERLAY_NSH_MD_LEN_INVALID);
            // todo: Instead of all the above ranges, would it be better to
            // create a single bit key field (len_eq_5) based on a length
            // compare?
        }
    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    action set_udf() {

        lkp.l7_udf = hdr.udf.opaque;

    }

    // Not much of a validation as it only sets the lookup fields.
    table validate_udf {
        key = {
            hdr.udf.isValid() : exact;
        }

        actions = {
            NoAction;
            set_udf;
        }

        const default_action = NoAction;
        const entries = {
            (true) : set_udf();
        }
    }

 // -------------------------------------

    apply {
  // -------------------------------------
     // Extreme Networks - Modified
  // -------------------------------------

        if (hdr.nsh_extr_underlay.isValid()) { // extreme added
            switch(validate_nsh.apply().action_run) { // extreme added
                malformed_pkt : {} // extreme added
                default: { // extreme added
           switch(validate_ethernet.apply().action_run) {
               malformed_pkt : {}
               default : {
                   if (hdr.ipv4.isValid()) {
                       validate_ipv4.apply();
                   } else if (hdr.ipv6.isValid()) {

                       validate_ipv6.apply();

                   }

                   validate_other.apply();

                      validate_udf.apply(); // extreme added

               }
     }
    } // extreme added
   } // extreme added
  } else { // extreme added
           switch(validate_ethernet.apply().action_run) {
               malformed_pkt : {}
               default : {
                   if (hdr.ipv4.isValid()) {
                       validate_ipv4.apply();
                   } else if (hdr.ipv6.isValid()) {

                       validate_ipv6.apply();

                   }

                   validate_other.apply();

                      validate_udf.apply(); // extreme added

               }
           }
  } // extreme added
    }
}

// ============================================================================
// Inner packet validaion
// Validate ethernet, Ipv4 or Ipv6 common lookup fields.
// ============================================================================
control InnerPktValidation(
        in switch_header_t hdr,
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_flags_t flags,
        inout switch_drop_reason_t drop_reason) {

    action valid_unicast_pkt() {
        // Set the common L2 lookup fields
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;

    }

    action valid_multicast_pkt() {
        // Set the common L2 lookup fields
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
    }

    action valid_broadcast_pkt() {
        // Set the common L2 lookup fields
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
    }

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    table validate_ethernet {
        key = {
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ethernet.dst_addr : ternary;
        }

        actions = {
            NoAction;
            valid_unicast_pkt;
            valid_multicast_pkt;
            valid_broadcast_pkt;
            malformed_pkt;
        }
    }

    action valid_ipv4_pkt() {
        // Set the common IP lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.inner_ipv4.diffserv;
        lkp.ip_ttl = hdr.inner_ipv4.ttl;
        lkp.ip_proto = hdr.inner_ipv4.protocol;
        lkp.ip_src_addr = (bit<128>) hdr.inner_ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) hdr.inner_ipv4.dst_addr;
    }

    table validate_ipv4 {
        key = {
            flags.inner_ipv4_checksum_err : ternary;
            hdr.inner_ipv4.version : ternary;
            hdr.inner_ipv4.ihl : ternary;
            hdr.inner_ipv4.ttl : ternary;
        }

        actions = {
            valid_ipv4_pkt;
            malformed_pkt;
        }
        /*
        const default_action = malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        const entries = {
            (_, _, _, _, 0x7f) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK);
            (_, _, _, _, 0xe0 &&& 0xf0) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST);
            (_, _, _, 0, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO);
            (_, _, 0 &&& 0xc, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (_, _, 4 &&& 0xf, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (false, 4 &&& 0xf, _, _, _) : valid_ipv4_pkt();
            (true, 4 &&& 0xf, _, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        }
        */
    }

    action valid_ipv6_pkt() {

        // Set the common IP lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.inner_ipv6.traffic_class;
        lkp.ip_ttl = hdr.inner_ipv6.hop_limit;
        lkp.ip_proto = hdr.inner_ipv6.next_hdr;
        lkp.ip_src_addr = hdr.inner_ipv6.src_addr;
        lkp.ip_dst_addr = hdr.inner_ipv6.dst_addr;
        flags.link_local = false;

    }

    table validate_ipv6 {
        key = {
            hdr.inner_ipv6.version : ternary;
            hdr.inner_ipv6.hop_limit : ternary;
        }

        actions = {
            valid_ipv6_pkt;
            malformed_pkt;
        }
        const entries = {
            (0 &&& 0, 0) : malformed_pkt(SWITCH_DROP_REASON_IP_IHL_INVALID);
            (6, 0 &&& 0) : valid_ipv6_pkt();
            (0 &&& 0, 0 &&& 0) : malformed_pkt(SWITCH_DROP_REASON_IP_VERSION_INVALID);
        }
    }

    action set_tcp_ports() {
        lkp.l4_src_port = hdr.inner_tcp.src_port;
        lkp.l4_dst_port = hdr.inner_tcp.dst_port;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.inner_udp.src_port;
        lkp.l4_dst_port = hdr.inner_udp.dst_port;
    }

    table validate_other {
        key = {
            hdr.inner_tcp.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
        }

        const default_action = NoAction;
        const entries = {
            (true, false) : set_tcp_ports();
            (false, true) : set_udp_ports();
        }
    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    action set_udf() {

        lkp.l7_udf = hdr.inner_udf.opaque;

    }

    table validate_udf {
        key = {
            hdr.inner_udf.isValid() : exact;
        }

        actions = {
            NoAction;
            set_udf;
        }

        const default_action = NoAction;
        const entries = {
            (true) : set_udf();
        }
    }

    // -----------------------------

    apply {
        switch(validate_ethernet.apply().action_run) {
            malformed_pkt : {}
            default : {
                if (hdr.inner_ipv4.isValid()) {
                    validate_ipv4.apply();
                } else if (hdr.inner_ipv6.isValid()) {



                }

                validate_other.apply();

                validate_udf.apply(); // extreme added

            }
        }
    }
}
# 50 "npb.p4" 2
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
# 51 "npb.p4" 2
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





//-----------------------------------------------------------------------------
// Tunnel processing
// Outer router MAC
// IP source and destination VTEP
//-----------------------------------------------------------------------------
control IngressTunnel(in switch_header_t hdr,
                      inout switch_ingress_metadata_t ig_md,
                      inout switch_lookup_fields_t lkp,
                      inout switch_lookup_fields_t lkp_nsh)(
                      switch_uint32_t ipv4_src_vtep_table_size=1024,
                      switch_uint32_t ipv6_src_vtep_table_size=1024,
                      switch_uint32_t ipv4_dst_vtep_table_size=1024,
                      switch_uint32_t ipv6_dst_vtep_table_size=1024,
                      switch_uint32_t vni_mapping_table_size=1024) {
    InnerPktValidation() pkt_validation;
    InnerPktValidation() pkt_validation_nsh; // extreme added

 // -------------------------------------
 // RMAC
 // -------------------------------------

    action rmac_hit() { }

    table rmac {
        key = {
            ig_md.rmac_group : exact;
            lkp.mac_dst_addr : exact;
        }

        actions = {
            NoAction;
            rmac_hit;
        }

        const default_action = NoAction;
        size = 1024;
    }

 // -------------------------------------

    action rmac_hit_nsh() { }

    table rmac_nsh {
        key = {
            ig_md.rmac_group : exact;
            lkp.mac_dst_addr : exact;

//          hdr.nsh_extr_underlay.isValid(): exact;
        }

        actions = {
            NoAction;
            rmac_hit_nsh;
        }

        const default_action = NoAction;
        size = 1024;
    }

 // -------------------------------------
 // Src VTEP
 // -------------------------------------

 // Derek note: These tables are unused in latest switch.p4 code from barefoot

    action src_vtep_hit(switch_ifindex_t ifindex) {
        ig_md.tunnel.ifindex = ifindex;
    }

    action src_vtep_miss() {}

    table src_vtep {
        key = {
            lkp.ip_src_addr[31:0] : exact @name("src_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }

        const default_action = src_vtep_miss;
        size = ipv4_src_vtep_table_size;
    }

    table src_vtepv6 {
        key = {
            lkp.ip_src_addr : exact @name("src_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }

        const default_action = src_vtep_miss;
        size = ipv6_src_vtep_table_size;
    }

 // -------------------------------------

 // Derek note: These tables are unused in latest switch.p4 code from barefoot

    action src_vtep_hit_nsh(switch_ifindex_t ifindex) {
        ig_md.tunnel_nsh.ifindex = ifindex;
    }

    action src_vtep_miss_nsh() {}

    table src_vtep_nsh {
        key = {
            lkp_nsh.ip_src_addr[31:0] : exact @name("src_addr");
            ig_md.vrf_nsh : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            src_vtep_miss_nsh;
            src_vtep_hit_nsh;
        }

        const default_action = src_vtep_miss_nsh;
        size = ipv4_src_vtep_table_size;
    }

    table src_vtepv6_nsh {
        key = {
            lkp_nsh.ip_src_addr : exact @name("src_addr");
            ig_md.vrf_nsh : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            src_vtep_miss_nsh;
            src_vtep_hit_nsh;
        }

        const default_action = src_vtep_miss_nsh;
        size = ipv6_src_vtep_table_size;
    }

 // -------------------------------------
 // Dst VTEP
 // -------------------------------------

    action dst_vtep_hit() {}

    //TODO(msharif): Add exclusion id.
    action set_vni_properties(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_bd_label_t bd_label,
            switch_rid_t rid,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv4_multicast_enable,
            bool igmp_snooping_enable,
            bool ipv6_unicast_enable,
            bool ipv6_multicast_enable,
            bool mld_snooping_enable,
            switch_multicast_rpf_group_t mrpf_group,
            switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        // ig_intr_md_for_tm.rid = rid;
        // ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        ig_md.rmac_group = rmac_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = learning_mode;
        ig_md.ipv4.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel.terminate = true;
    }

    table dst_vtep {
        key = {
            lkp.ip_src_addr[31:0] : ternary @name("src_addr");
            lkp.ip_dst_addr[31:0] : ternary @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            set_vni_properties;
        }

        const default_action = NoAction;
    }

    table dst_vtepv6 {
        key = {
            lkp.ip_src_addr : ternary @name("src_addr");
            lkp.ip_dst_addr : ternary @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            set_vni_properties;
        }

        const default_action = NoAction;
    }

    // Tunnel id -> BD Translation
    table vni_to_bd_mapping {
//      key = { ig_md.tunnel.id : exact; }
        key = {
   ig_md.tunnel_nsh.id : exact;
            ig_md.tunnel_nsh.type : exact;
  }

        actions = {
            NoAction;
            set_vni_properties;
        }

        default_action = NoAction;
        size = vni_mapping_table_size;
    }

 // -------------------------------------

    action dst_vtep_hit_nsh() {}

    //TODO(msharif): Add exclusion id.
    action set_vni_properties_nsh(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_bd_label_t bd_label,
            switch_rid_t rid,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv4_multicast_enable,
            bool igmp_snooping_enable,
            bool ipv6_unicast_enable,
            bool ipv6_multicast_enable,
            bool mld_snooping_enable,
            switch_multicast_rpf_group_t mrpf_group,
            switch_rmac_group_t rmac_group) {
        ig_md.bd_nsh = bd;
        ig_md.bd_label_nsh = bd_label;
        ig_md.vrf_nsh = vrf;
        // ig_intr_md_for_tm.rid = rid;
        // ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        ig_md.rmac_group_nsh = rmac_group;
        ig_md.multicast_nsh.rpf_group = mrpf_group;
        ig_md.learning_nsh.bd_mode = learning_mode;
        ig_md.ipv4_nsh.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4_nsh.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4_nsh.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6_nsh.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6_nsh.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6_nsh.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel_nsh.terminate = true;
    }

    table dst_vtep_nsh {
        key = {
            lkp_nsh.ip_src_addr[31:0] : ternary @name("src_addr");
            lkp_nsh.ip_dst_addr[31:0] : ternary @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit_nsh;
            set_vni_properties_nsh;
        }

        const default_action = NoAction;
    }

    table dst_vtepv6_nsh {
        key = {
            lkp_nsh.ip_src_addr : ternary @name("src_addr");
            lkp_nsh.ip_dst_addr : ternary @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit_nsh;
            set_vni_properties_nsh;
        }

        const default_action = NoAction;
    }

    // Tunnel id -> BD Translation
    table vni_to_bd_mapping_nsh {
//      key = { ig_md.tunnel_nsh.id : exact; }
        key = {
   ig_md.tunnel_nsh.id : exact;
            ig_md.tunnel_nsh.type : exact;
  }

        actions = {
            NoAction;
            set_vni_properties_nsh;
        }

        default_action = NoAction;
        size = vni_mapping_table_size;
    }

 // -------------------------------------
 // Apply
 // -------------------------------------

    apply {
# 394 "tunnel.p4"
  // -------------------------------------
  // Extreme Added
  // -------------------------------------

        // outer RMAC lookup for tunnel termination.
        switch(rmac_nsh.apply().action_run) {
            rmac_hit_nsh : {
                if (lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV4) {
                    // src_vtep_nsh.apply();
                    switch(dst_vtep_nsh.apply().action_run) {
                        dst_vtep_hit_nsh : {
                            // Vxlan
                            vni_to_bd_mapping_nsh.apply();
                            pkt_validation_nsh.apply(hdr, lkp_nsh, ig_md.flags, ig_md.drop_reason);
                        }

                        set_vni_properties_nsh : {
                            // IPinIP
                            pkt_validation_nsh.apply(hdr, lkp_nsh, ig_md.flags, ig_md.drop_reason);
                        }
                    }
                } else if (lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV6) {
# 431 "tunnel.p4"
                }
            }
        }


    }
}

//-----------------------------------------------------------------------------
// Tunnel decapsulation
//
// @param hdr : Parsed headers.
// @param mode :  Specify the model for tunnel decapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying from the outer header on decapsulation. In the PIPE mode, ttl,
// and dscp fields of the inner header are independent of that in the outer header and remain the
// same on decapsulation.
//
//-----------------------------------------------------------------------------
control TunnelDecap(inout switch_header_t hdr,
                    in switch_egress_metadata_t eg_md)(
                    switch_tunnel_mode_t mode) {

 // -------------------------------------

    action decap_inner_udp() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }

    action decap_inner_tcp() {
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
        hdr.udp.setInvalid();
    }

    action decap_inner_unknown() {
        hdr.udp.setInvalid();
    }

    table decap_inner_l4 {
        key = { hdr.inner_udp.isValid() : exact; }
        actions = {
            decap_inner_udp;
            decap_inner_unknown;
        }

        const default_action = decap_inner_unknown;
        const entries = {
            (true) : decap_inner_udp();
        }
    }

 // -------------------------------------

    action copy_ipv4_header() {
        hdr.ipv4.setValid();
        hdr.ipv4.version = hdr.inner_ipv4.version;
        hdr.ipv4.ihl = hdr.inner_ipv4.ihl;
        hdr.ipv4.total_len = hdr.inner_ipv4.total_len;
        hdr.ipv4.identification = hdr.inner_ipv4.identification;
        hdr.ipv4.flags = hdr.inner_ipv4.flags;
        hdr.ipv4.frag_offset = hdr.inner_ipv4.frag_offset;
        hdr.ipv4.protocol = hdr.inner_ipv4.protocol;
        // hdr.ipv4.hdr_checksum = hdr.inner_ipv4.hdr_checksum;
        hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
        hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
            hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;
        }

        hdr.inner_ipv4.setInvalid();
    }

    action copy_ipv6_header() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = hdr.inner_ipv6.version;
        hdr.ipv6.flow_label = hdr.inner_ipv6.flow_label;
        hdr.ipv6.payload_len = hdr.inner_ipv6.payload_len;
        hdr.ipv6.next_hdr = hdr.inner_ipv6.next_hdr;
        hdr.ipv6.src_addr = hdr.inner_ipv6.src_addr;
        hdr.ipv6.dst_addr = hdr.inner_ipv6.dst_addr;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv6.hop_limit = hdr.inner_ipv6.hop_limit;
            hdr.ipv6.traffic_class = hdr.inner_ipv6.traffic_class;
        }

        hdr.inner_ipv6.setInvalid();
    }

    action invalidate_tunneling_headers() {
        // Removing tunneling headers by default.
        hdr.vxlan.setInvalid();

        hdr.gre.setInvalid(); // extreme added
        hdr.nvgre.setInvalid(); // extreme added


  hdr.gtp_v1_base.setInvalid(); // extreme added
  hdr.gtp_v2_base.setInvalid(); // extreme added
  hdr.gtp_v1_v2_teid.setInvalid(); // extreme added
  hdr.gtp_v1_optional.setInvalid(); // extreme added

    }

    action decap_inner_ethernet_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ethernet_ipv6() {







    }

    action decap_inner_ethernet_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ipv4() {
        hdr.ethernet.ether_type = 0x0800;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ipv6() {






    }

    table decap_inner_ip {
        key = {
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            decap_inner_ethernet_ipv4;
            decap_inner_ethernet_ipv6;
            decap_inner_ethernet_non_ip;
            decap_inner_ipv4;
            decap_inner_ipv6;
        }

        const entries = {
            (true, true, false) : decap_inner_ethernet_ipv4();
            (true, false, true) : decap_inner_ethernet_ipv6();
            (true, false, false) : decap_inner_ethernet_non_ip();
            (false, true, false) : decap_inner_ipv4();
            (false, false, true) : decap_inner_ipv6();
        }
    }

 // -------------------------------------

    apply {

        // Copy L3 headers into inner headers.
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel.terminate)
            decap_inner_ip.apply();

        // Copy L4 headers into inner headers.
        if (!(eg_md.bypass & SWITCH_EGRESS_BYPASS_REWRITE != 0) && eg_md.tunnel.terminate)
            decap_inner_l4.apply();

    }
}

//-----------------------------------------------------------------------------
// Tunnel rewrite
//
//-----------------------------------------------------------------------------

control TunnelRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md)(
                      switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024,//XXX
                      switch_uint32_t ipv6_dst_addr_rewrite_table_size=1024,//XXX
                      switch_uint32_t src_addr_rewrite_table_size=1024,//XXX
                      switch_uint32_t nexthop_rewrite_table_size=512,
                      switch_uint32_t smac_rewrite_table_size=1024) {

    EgressBd(BD_TABLE_SIZE) egress_bd;
    switch_bd_label_t bd_label;
    switch_smac_index_t smac_index;

 // -------------------------------------

    // extreme added
    switch_bd_t bd_temp;
    mac_addr_t dmac_temp;

    // extreme added
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        bd_temp = bd;
        dmac_temp = dmac;
    }

    // Outer nexthop rewrite
    action rewrite_tunnel_orig(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet.dst_addr = dmac;
    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    action rewrite_tunnel_nsh(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet_underlay.dst_addr = dmac;
    }

 // -------------------------------------

    table nexthop_rewrite {
        key = {
            eg_md.outer_nexthop : exact;
        }

        actions = {
            NoAction;
//          rewrite_tunnel; // extreme modified
            rewrite_tunnel_orig; // extreme added

   rewrite_tunnel_nsh;
        }

        const default_action = NoAction;
        size = nexthop_rewrite_table_size;
    }

 // -------------------------------------

    // Tunnel source IP rewrite
    action rewrite_ipv4_src(ipv4_addr_t src_addr) {
        hdr.ipv4.src_addr = src_addr;
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

    // Tunnel destination IP rewrite
    action rewrite_ipv4_dst(ipv4_addr_t dst_addr) {
        hdr.ipv4.dst_addr = dst_addr;
    }

    action rewrite_ipv6_dst(ipv6_addr_t dst_addr) {
        hdr.ipv6.dst_addr = dst_addr;
    }

    table ipv4_dst_addr_rewrite {
        key = { eg_md.tunnel.index : exact; }
        actions = { rewrite_ipv4_dst; }
        const default_action = rewrite_ipv4_dst(0);
        size = ipv4_dst_addr_rewrite_table_size;
    }

    table ipv6_dst_addr_rewrite {
        key = { eg_md.tunnel.index : exact; }
        actions = { rewrite_ipv6_dst; }
        const default_action = rewrite_ipv6_dst(0);
        size = ipv6_dst_addr_rewrite_table_size;
    }

 // -------------------------------------

    // extreme added
    mac_addr_t smac_temp;

    // extreme added
    action rewrite_smac(mac_addr_t smac) {
        smac_temp = smac;
    }

    // Tunnel source MAC rewrite
    action rewrite_smac_orig(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    action rewrite_smac_nsh(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }

 // -------------------------------------

    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
//          rewrite_smac; // extreme modified
            rewrite_smac_orig; // extreme added

            rewrite_smac_nsh;
        }

        const default_action = NoAction;
        size = smac_rewrite_table_size;
    }

 // -------------------------------------

    apply {

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
   // extreme reworked
            nexthop_rewrite.apply();
/*
            switch(nexthop_rewrite.apply().action_run) {
                rewrite_tunnel : {
                    if(hdr.vlan_tag_underlay.isValid()) {
                        rewrite_tunnel_nsh(bd_temp, dmac_temp);
                    } else {
                        rewrite_tunnel_orig(bd_temp, dmac_temp);
                    }
                }
            }
*/

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
            egress_bd.apply(hdr, eg_md.bd, eg_md.pkt_type, bd_label, smac_index, eg_md.checks.mtu);

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
            src_addr_rewrite.apply();

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            ipv4_dst_addr_rewrite.apply();



        }

  // extreme reworked
        smac_rewrite.apply();
/*
        switch(smac_rewrite.apply().action_run) {
            rewrite_smac : {
                if(hdr.vlan_tag_underlay.isValid()) {
                    rewrite_smac_nsh(smac_temp);
                } else {
                    rewrite_smac_orig(smac_temp);
                }
            }
        }
*/


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
control TunnelEncap(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md)(
                    switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
                    switch_uint32_t vni_mapping_table_size=1024) {
    bit<16> payload_len;
    bit<8> ip_proto;

 // -------------------------------------

    action set_vni(switch_tunnel_id_t id) {
        eg_md.tunnel.id = id;
    }

    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }

        actions = {
            NoAction;
            set_vni;
        }

        size = vni_mapping_table_size;
    }

 // -------------------------------------

    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields.
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        // hdr.inner_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        hdr.ipv4.setInvalid();
    }

    action copy_ipv6_header() {
        hdr.inner_ipv6.version = hdr.ipv6.version;
        hdr.inner_ipv6.flow_label = hdr.ipv6.flow_label;
        hdr.inner_ipv6.payload_len = hdr.ipv6.payload_len;
        hdr.inner_ipv6.src_addr = hdr.ipv6.src_addr;
        hdr.inner_ipv6.dst_addr = hdr.ipv6.dst_addr;
        hdr.inner_ipv6.hop_limit = hdr.ipv6.hop_limit;
        hdr.inner_ipv6.traffic_class = hdr.ipv6.traffic_class;
        hdr.ipv6.setInvalid();
    }


    action rewrite_inner_ipv4_udp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        ip_proto = 4;
    }

    action rewrite_inner_ipv4_tcp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        ip_proto = 4;
    }

    action rewrite_inner_ipv4_unknown() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        ip_proto = 4;
    }

    action rewrite_inner_ipv6_udp() {
# 923 "tunnel.p4"
    }

    action rewrite_inner_ipv6_tcp() {
# 934 "tunnel.p4"
    }

    action rewrite_inner_ipv6_unknown() {






    }

    table encap_outer {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            // hdr.tcp.isValid() : exact;

   hdr.nsh_extr_underlay.isValid() : exact; // extreme added
        }

        actions = {
            rewrite_inner_ipv4_udp;
            // rewrite_inner_ipv4_tcp;
            rewrite_inner_ipv4_unknown;
            rewrite_inner_ipv6_udp;
            // rewrite_inner_ipv6_tcp;
            rewrite_inner_ipv6_unknown;
        }

        const entries = {
   // extreme modified
/*
            (true, false, false) : rewrite_inner_ipv4_unknown();
            (false, true, false) : rewrite_inner_ipv6_unknown();
            (true, false, true) : rewrite_inner_ipv4_udp();
            (false, true, true) : rewrite_inner_ipv6_udp();
*/
            (true, false, false, false) : rewrite_inner_ipv4_unknown();
            (false, true, false, false) : rewrite_inner_ipv6_unknown();
            (true, false, true, false) : rewrite_inner_ipv4_udp();
            (false, true, true, false) : rewrite_inner_ipv6_udp();
        }
    }

//-----------------------------------------------------------------------------
// Helper actions to add various headers.
//-----------------------------------------------------------------------------
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
        // hdr.udp.length = 0;
    }

    action add_vxlan_header(bit<24> vni) {

        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        // hdr.vxlan.reserved = 0;
        hdr.vxlan.vni = vni;
        // hdr.vxlan.reserved2 = 0;

    }

 // -------------------------------------
    // Extreme Networks - Modified
 // -------------------------------------

    action add_gre_header(bit<16> proto, bit<1> K) {

        hdr.gre.setValid();
        hdr.gre.proto = proto;
        hdr.gre.C = 0;
        hdr.gre.R = 0;
//      hdr.gre.K = 0;
        hdr.gre.K = K;
        hdr.gre.S = 0;
        hdr.gre.s = 0;
        hdr.gre.recurse = 0;
        hdr.gre.flags = 0;
        hdr.gre.version = 0;

    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    action add_nvgre_header(bit<24> vsid, bit<8> flow_id) {

        hdr.nvgre.setValid();
        hdr.nvgre.vsid = vsid;
        hdr.nvgre.flow_id = flow_id;

    }

// DEREK
    action add_gtpc_header(bit<32> teid) { // aka gtp v2

/*
		// derek: uncommenting this code produces a compiler bug in 8.9!
        hdr.gtp_v2_base.setValid();
		hdr.gtp_v2_base.version    = 2;
	    hdr.gtp_v2_base.P          = 0;
	    hdr.gtp_v2_base.T          = 1;
	    hdr.gtp_v2_base.reserved   = 0;
	    hdr.gtp_v2_base.msg_type   = 0;
	    hdr.gtp_v2_base.msg_len    = 0;

        hdr.gtp_v1_v2_teid.setValid();
		hdr.gtp_v1_v2_teid.teid    = teid;
*/

 }

    action add_gtpu_header(bit<32> teid) { // aka gtp v1

/*
		// derek: uncommenting this code produces a compiler bug in 8.9!
        hdr.gtp_v1_base.setValid();
	    hdr.gtp_v1_base.version    = 1;
	    hdr.gtp_v1_base.PT         = 1;
	    hdr.gtp_v1_base.reserved   = 0;
	    hdr.gtp_v1_base.E          = 0;
	    hdr.gtp_v1_base.S          = 0;
	    hdr.gtp_v1_base.PN         = 0;
	    hdr.gtp_v1_base.msg_type   = 0;
	    hdr.gtp_v1_base.msg_len    = 0;

        hdr.gtp_v1_v2_teid.setValid();
		hdr.gtp_v1_v2_teid.teid    = teid;
*/

 }

 // -------------------------------------

    action add_erspan_header(bit<32> timestamp, switch_mirror_session_t session_id) {
# 1082 "tunnel.p4"
    }

    action add_ipv4_header(bit<8> proto) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.protocol = proto;
        // hdr.ipv4.src_addr = 0;
        // hdr.ipv4.dst_addr = 0;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = 8w64;
            hdr.ipv4.diffserv = 0;
        }
    }

    action add_ipv6_header(bit<8> proto) {

        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w6;
        hdr.ipv6.flow_label = 0;
        // hdr.ipv6.payload_len = 0;
        hdr.ipv6.next_hdr = proto;
        // hdr.ipv6.src_addr = 0;
        // hdr.ipv6.dst_addr = 0;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv6.hop_limit = 8w64;
            hdr.ipv6.traffic_class = 0;
        }

    }

 // =====================================
 // ----- Rewrite, IPv4 Stuff -----
 // =====================================

    action rewrite_ipv4_vxlan(bit<16> vxlan_port) {
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv4_header(17);
        // Total length = packet length + 50
        //   IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv4.total_len = payload_len + 16w50;

        add_udp_header(eg_md.tunnel.hash, vxlan_port);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + 16w30;

        add_vxlan_header(eg_md.tunnel.id[23:0]); // extreme changed bitwidth
        hdr.ethernet.ether_type = 0x0800;
    }

    action rewrite_ipv4_ip() {
        add_ipv4_header(ip_proto);
        // Total length = packet length + 20
        //   IPv4 (20)
        hdr.ipv4.total_len = payload_len + 16w20;
        hdr.ethernet.ether_type = 0x0800;
    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    action rewrite_ipv4_nvgre() {
  // ----- l3 -----
        add_ipv4_header(47);
        // Total length = packet length + 28
        //   IPv4 (20) + NVGRE (8)
        hdr.ipv4.total_len = payload_len + 16w28;

  // ----- tunnel -----
        add_gre_header(0x6558, 1);
        add_nvgre_header((bit<24>)eg_md.tunnel.id, 0);

  // ----- l2 -----
        hdr.ethernet.ether_type = 0x0800;
    }

// DEREK
    action rewrite_ipv4_gtpc() { // aka gtp v2
  // ----- l3 -----
        add_ipv4_header(17);
        // Total length = packet length + 8
        //   IPv4 (20) + GTP Base (4) + GTP TEID (4)
        hdr.ipv4.total_len = payload_len + 16w28;

  // ----- tunnel -----
  add_gtpc_header(eg_md.tunnel.id);

  // ----- l2 -----
        hdr.ethernet.ether_type = 0x0800;
 }

    action rewrite_ipv4_gtpu() { // aka gtp v1
  // ----- l3 -----
        add_ipv4_header(17);
        // Total length = packet length + 8
        //   IPv4 (20) + GTP Base (4) + GTP TEID (4)
        hdr.ipv4.total_len = payload_len + 16w28;

  // ----- tunnel -----
  add_gtpu_header(eg_md.tunnel.id);

  // ----- l2 -----
        hdr.ethernet.ether_type = 0x0800;
 }

 // =====================================
 // ----- Rewrite, IPv6 Stuff -----
 // =====================================

    action rewrite_ipv6_vxlan(bit<16> vxlan_port) {
# 1219 "tunnel.p4"
    }

    action rewrite_ipv6_ip() {






    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    action rewrite_ipv6_nvgre() {
# 1250 "tunnel.p4"
    }

// DEREK
    action rewrite_ipv6_gtpc() { // aka gtp v2
# 1267 "tunnel.p4"
 }

    action rewrite_ipv6_gtpu() { // aka gtp v1
# 1283 "tunnel.p4"
 }

 // -------------------------------------

    // extreme added
    action rewrite_mac_in_mac() {
    }

 // -------------------------------------
    // Extreme Networks - Added
 // -------------------------------------

    action rewrite_mac_in_mac_nsh_() {
        hdr.ethernet_underlay.setValid();

        hdr.ethernet_underlay.ether_type = 0x894F;
    }

    action rewrite_mac_in_mac_nsh() {
    }

 // -------------------------------------

    table tunnel {
        key = {
            eg_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            rewrite_ipv4_vxlan;
            rewrite_ipv6_vxlan;
            rewrite_ipv4_ip;
            rewrite_ipv6_ip;

   rewrite_mac_in_mac; // extreme added
            rewrite_ipv4_nvgre; // extreme added
            rewrite_ipv6_nvgre; // extreme added
            rewrite_ipv4_gtpc; // extreme added
            rewrite_ipv6_gtpc; // extreme added
            rewrite_ipv4_gtpu; // extreme added
            rewrite_ipv6_gtpu; // extreme added
        }

        const default_action = NoAction;
    }

 // -------------------------------------

    apply {

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE && eg_md.tunnel.id == 0)
            bd_to_vni_mapping.apply();

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            // Copy L3/L4 header into inner headers.
            encap_outer.apply();

            // Add outer L3/L4/Tunnel headers.

   // extreme reworked
//          tunnel.apply();
            switch(tunnel.apply().action_run) {
                rewrite_mac_in_mac : {
                    if(hdr.nsh_extr_underlay.isValid()) {
                        rewrite_mac_in_mac_nsh_();
                    } else {
                        // nothing, barefoot had no original code for this case
                    }
                }
            }
        }

    }
}
# 52 "npb.p4" 2
# 1 "multicast.p4" 1
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
// IP Multicast
// @param src_addr : IP source address.
// @param grp_addr : IP group address.
// @param bd : Bridge domain.
// @param group_id : Multicast group id.
// @param s_g_table_size : (s, g) table size.
// @param star_g_table_size : (*, g) table size.
//-----------------------------------------------------------------------------
control MulticastBridge<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_miss() {
        multicast_hit = 0;
    }

    table s_g {
        key = {
            bd : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
    }

    table star_g {
        key = {
            bd : exact;
            grp_addr : exact;
        }

        actions = {
            star_g_miss;
            star_g_hit;
        }

        const default_action = star_g_miss;
        size = star_g_table_size;
    }

    apply {

        switch(s_g.apply().action_run) {
            NoAction : { star_g.apply(); }
        }

    }
}

control MulticastBridgev6<T>(
        in ipv6_addr_t src_addr,
        in ipv6_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_miss() {
        multicast_hit = 0;
    }

    table s_g {
        key = {
            bd : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
    }

    table star_g {
        key = {
            bd : exact;
            grp_addr : exact;
        }

        actions = {
            star_g_miss;
            star_g_hit;
        }

        const default_action = star_g_miss;
        size = star_g_table_size;
    }

    apply {

        switch(s_g.apply().action_run) {
            NoAction : { star_g.apply(); }
        }

    }
}

control MulticastRoute<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_vrf_t vrf,
        inout switch_multicast_metadata_t multicast_md,
        out switch_multicast_rpf_group_t rpf_check,
        out switch_mgid_t multicast_group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;

    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        s_g_stats.count();
    }

    action star_g_hit_bidir(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check != 0
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }

    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check == 0
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }

    // Source and Group address pair (S, G) lookup
    table s_g {
        key = {
            vrf : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }

    // Group address (*, G) lookup
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
            star_g_hit_bidir;
        }

        const default_action = NoAction;
        size = star_g_table_size;
        counters = star_g_stats;
    }

    apply {

        if (!s_g.apply().hit) {
            star_g.apply();
        }

    }
}


control MulticastRoutev6<T>(
        in ipv6_addr_t src_addr,
        in ipv6_addr_t grp_addr,
        in switch_vrf_t vrf,
        inout switch_multicast_metadata_t multicast_md,
        out switch_multicast_rpf_group_t rpf_check,
        out switch_mgid_t multicast_group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;

    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        s_g_stats.count();
    }

    action star_g_hit_bidir(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check != 0
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }

    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check == 0
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }

    // Source and Group address pair (S, G) lookup
    table s_g {
        key = {
            vrf : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }

    // Group address (*, G) lookup
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
            star_g_hit_bidir;
        }

        const default_action = NoAction;
        size = star_g_table_size;
        counters = star_g_stats;
    }

    apply {

        if (!s_g.apply().hit) {
            star_g.apply();
        }

    }
}

control IngressMulticast(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ipv4_s_g_table_size,
        switch_uint32_t ipv4_star_g_table_size,
        switch_uint32_t ipv6_s_g_table_size,
        switch_uint32_t ipv6_star_g_table_size) {

    // For each rendezvous point (RP), there is a list of interfaces for which
    // the switch is the designated forwarder (DF).

    MulticastBridge<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_bridge;
    MulticastRoute<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_route;
    MulticastBridgev6<ipv6_addr_t>(
        ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_bridge;
    MulticastRoutev6<ipv6_addr_t>(ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_route;

    switch_multicast_rpf_group_t rpf_check;
    bit<1> multicast_hit;

    action set_multicast_route() {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = true;
        ig_md.flags.routed = true;
        ig_md.flags.flood_to_multicast_routers = false;
        ig_md.checks.same_bd = 0x3fff;
    }

    action set_multicast_bridge(bool mrpf) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = false;
    }

    action set_multicast_flood(bool mrpf, bool flood) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = flood;
    }

    table fwd_result {
        key = {
            multicast_hit : ternary;
            lkp.ip_type : ternary;
            ig_md.ipv4.multicast_snooping : ternary;
            ig_md.ipv6.multicast_snooping : ternary;
            ig_md.multicast.mode : ternary;
            rpf_check : ternary;
        }

        actions = {
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
        }
    }

    apply {

        if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4.multicast_enable) {
            ipv4_multicast_route.apply(lkp.ip_src_addr[31:0],
                                       lkp.ip_dst_addr[31:0],
                                       ig_md.vrf,
                                       ig_md.multicast,
                                       rpf_check,
                                       ig_md.multicast.id,
                                       multicast_hit);
        } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6.multicast_enable) {

            ipv6_multicast_route.apply(lkp.ip_src_addr,
                                       lkp.ip_dst_addr,
                                       ig_md.vrf,
                                       ig_md.multicast,
                                       rpf_check,
                                       ig_md.multicast.id,
                                       multicast_hit);

        }

        if (multicast_hit == 0 ||
            (ig_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_SM && rpf_check != 0) ||
            (ig_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_BIDIR && rpf_check == 0)) {

            if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_multicast_bridge.apply(lkp.ip_src_addr[31:0],
                                            lkp.ip_dst_addr[31:0],
                                            ig_md.bd,
                                            ig_md.multicast.id,
                                            multicast_hit);
            } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

                ipv6_multicast_bridge.apply(lkp.ip_src_addr,
                                            lkp.ip_dst_addr,
                                            ig_md.bd,
                                            ig_md.multicast.id,
                                            multicast_hit);

            }
        }

        fwd_result.apply();

    }
}


//-----------------------------------------------------------------------------
// Multicast flooding
//-----------------------------------------------------------------------------
control MulticastFlooding(inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {

    action flood(switch_mgid_t mgid) {
        ig_md.multicast.id = mgid;
    }

    table bd_flood {
        key = {
            ig_md.bd : exact @name("bd");
            ig_md.lkp.pkt_type : exact @name("pkt_type");

            ig_md.flags.flood_to_multicast_routers : exact @name("flood_to_multicast_routers");

        }

        actions = { flood; }
        size = table_size;
    }

    apply {
        bd_flood.apply();
    }
}

//-----------------------------------------------------------------------------

control MulticastReplication(in switch_rid_t replication_id,
                             in switch_port_t port,
                             inout switch_egress_metadata_t eg_md)(
                             switch_uint32_t table_size=4096) {
    action rid_hit(
  switch_bd_t bd,

        // -------------------------------------
        // Extreme Networks - Added
        // -------------------------------------

        bit<24> spi,
        bit<8> si,
        bit<8> sf_bitmask_local,
        bit<8> sf_bitmask_remote,
        bit<16> tenant_id,
        bit<8> flow_type
 ) {
        eg_md.checks.same_bd = bd ^ eg_md.bd;
        eg_md.bd = bd;

        // -------------------------------------
        // Extreme Networks - Added
        // -------------------------------------

        eg_md.nsh_extr.spi = spi;
        eg_md.nsh_extr.si = si;
        eg_md.nsh_extr.extr_srvc_func_bitmask_local = sf_bitmask_local;
        eg_md.nsh_extr.extr_srvc_func_bitmask_remote = sf_bitmask_remote;
        eg_md.nsh_extr.extr_tenant_id = tenant_id;
        eg_md.nsh_extr.extr_flow_type = flow_type;
    }

    action rid_miss() {
        eg_md.flags.routed = false;
    }

    table rid {
        key = { replication_id : exact; }
        actions = {
            rid_miss;
            rid_hit;
        }

        size = table_size;
        const default_action = rid_miss;
    }

    apply {

        if (replication_id != 0)
            rid.apply();

        if (eg_md.checks.same_bd == 0)
            eg_md.flags.routed = false;

    }
}
# 53 "npb.p4" 2
# 1 "qos.p4" 1
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
# 27 "qos.p4" 2
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




//-------------------------------------------------------------------------------------------------
// Ingress Policer
//
// Monitors the data rate for a particular class of service and drops the traffic
// when the rate exceeds a user-defined thresholds.
//
// @param ig_md : Ingress metadata fields.
// @param qos_md : QoS related metadata fields.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the ingress policer table.
//-------------------------------------------------------------------------------------------------
control IngressPolicer(in switch_ingress_metadata_t ig_md,
                       inout switch_qos_metadata_t qos_md,
                       out bool flag)(
                       switch_uint32_t table_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;
    DirectMeter(MeterType_t.BYTES) meter;

    // Requires 3 entries per meter index for unicast/broadcast/multicast packets.
    //XXX compiler fails with error : Cannot evaluate initializer to a compiler-time constant.
    // const switch_uint32_t meter_action_table_size = 3 * table_size;

    action meter_deny() {
        stats.count();
        flag = true;
    }

    action meter_permit() {
        stats.count();
        flag = false;
    }

    table meter_action {
        key = {
            qos_md.color : exact;
            qos_md.meter_index : exact;
        }

        actions = {
            meter_permit;
            meter_deny;
        }

        const default_action = meter_permit;
        // size = meter_action_table_size;
        counters = stats;
    }

    action set_color() {
        qos_md.color = (bit<2>) meter.execute();
    }

    table meter_index {
        key = {
            qos_md.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            set_color;
        }

        const default_action = NoAction;
        size = table_size;
        meters = meter;
    }

    apply {







    }
}

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
// @param table_size : Size of the storm control table.
//-------------------------------------------------------------------------------------------------
control StormControl(in switch_ingress_metadata_t ig_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=512) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;

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
            color: exact;
            pkt_type : ternary;
            ig_md.port: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size;
        counters = storm_control_stats;
    }

    action set_meter(bit<16> index) {
        color = (bit<2>) meter.execute(index);
    }

    table storm_control {
        key = {
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







    }
}
# 28 "qos.p4" 2

//-----------------------------------------------------------------------------
// Common QoS related actions used by QoS ACL slices or QoS dscp/pcp mappings.
//-----------------------------------------------------------------------------
action set_ingress_tc(inout switch_qos_metadata_t qos_md, switch_tc_t tc) {
    qos_md.tc = tc;
}

action set_ingress_color(inout switch_qos_metadata_t qos_md, switch_pkt_color_t color) {
    qos_md.color = color;
}

action set_ingress_tc_and_color(
        inout switch_qos_metadata_t qos_md, switch_tc_t tc, switch_pkt_color_t color) {
    set_ingress_tc(qos_md, tc);
    set_ingress_color(qos_md, color);
}

action set_ingress_tc_color_and_meter(
        inout switch_qos_metadata_t qos_md,
        switch_tc_t tc,
        switch_pkt_color_t color,
        switch_policer_meter_index_t index) {




}

control MacQosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            lkp.pcp : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv4QosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv6QosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_qos_metadata_t qos_md,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// ECN Access control list
//
// @param ig_md : Ingress metadata fields.
// @param lkp : Lookup fields.
// @param qos_md : QoS metadata fields.
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control ECNAcl(in switch_ingress_metadata_t ig_md,
               in switch_lookup_fields_t lkp,
               inout switch_pkt_color_t pkt_color)(
               switch_uint32_t table_size=512) {
    action set_ingress_color(switch_pkt_color_t color) {
        pkt_color = color;
    }

    table acl {
        key = {
            ig_md.port_lag_label : ternary;
            lkp.ip_tos : ternary;
            lkp.tcp_flags : ternary;
        }

        actions = {
            NoAction;
            set_ingress_color;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// PFC Watchdog
// Once PFC storm is detected on a queue, the PFC watchdog can drop or forward at per queue level.
// On drop action, all existing packets in the output queue and all subsequent packets destined to
// the output queue are discarded.
//
// @param ig_md : Ingress metadata fields.
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control PFCAcl(in switch_port_t egress_port,
               in switch_qid_t qid,
               out bool flag)(switch_uint32_t table_size=512) {
    action acl_deny() {
        flag = true;
    }

    table acl {
        key = {
            qid : exact;
            egress_port : exact;
        }

        actions = {
            NoAction;
            acl_deny;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control IngressQoS(
        in switch_header_t hdr,
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t dscp_map_size=1024,
        switch_uint32_t pcp_map_size=1024) {

    const bit<32> ppg_table_size = 1024;
    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
    IngressPolicer(1 << 10) policer;
    MacQosAcl() mac_acl;
    Ipv4QosAcl() ipv4_acl;
    Ipv6QosAcl() ipv6_acl;

    table dscp_tc_map {
        key = {
            ig_md.qos.group : exact;
            lkp.ip_tos : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }

        size = dscp_map_size;
    }

    table pcp_tc_map {
        key = {
            ig_md.qos.group : ternary;
            lkp.pcp : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc(ig_md.qos);
            set_ingress_color(ig_md.qos);
            set_ingress_tc_and_color(ig_md.qos);
            set_ingress_tc_color_and_meter(ig_md.qos);
        }

        size = pcp_map_size;
    }


    action set_icos(switch_cos_t icos) {
        ig_md.qos.icos = icos;
    }

    action set_queue(switch_qid_t qid) {
        ig_md.qos.qid = qid;
    }

    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }

    table traffic_class {
        key = {
            ig_md.port : ternary @name("port");
            ig_md.qos.color : ternary @name("color");
            ig_md.qos.tc : exact @name("tc");
        }

        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }

        size = queue_table_size;
    }

    action count() {
        ppg_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and cos pair.
    table ppg {
        key = {
            ig_md.port : exact @name("port");
            ig_md.qos.icos : exact @name("icos");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = ppg_table_size;
        counters = ppg_stats;
    }

    apply {
# 348 "qos.p4"
    }
}


control EgressQoS(inout switch_header_t hdr,
                  in switch_port_t port,
                  inout switch_egress_metadata_t eg_md)(
                  switch_uint32_t table_size=1024) {

    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) queue_stats;

    // Overwrites 6-bit dscp only.
    action set_ipv4_dscp(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }

    action set_ipv4_tos(switch_uint8_t tos) {
        hdr.ipv4.diffserv = tos;
    }

    // Overwrites 6-bit dscp only.
    action set_ipv6_dscp(bit<6> dscp) {

        hdr.ipv6.traffic_class[7:2] = dscp;

    }

    action set_ipv6_tos(switch_uint8_t tos) {

        hdr.ipv6.traffic_class = tos;

    }

    action set_vlan_pcp(bit<3> pcp) {
        eg_md.lkp.pcp = pcp;
    }

    table qos_map {
        key = {
            eg_md.qos.group : exact @name("group");
            eg_md.qos.tc : exact @name("tc");
            eg_md.qos.color : exact @name("color");
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            NoAction;
            set_ipv4_dscp;
            set_ipv4_tos;
            set_ipv6_dscp;
            set_ipv6_tos;
            set_vlan_pcp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action count() {
        queue_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and queue pair. This table does NOT
    // take care of packets that get dropped or sent to cpu by system acl.
    table queue {
        key = {
            port : exact;
            eg_md.qos.qid : exact @name("qid");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        size = queue_table_size;
        const default_action = NoAction;
        counters = queue_stats;
    }

    apply {





    }
}
# 54 "npb.p4" 2
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
# 55 "npb.p4" 2
# 1 "wred.p4" 1
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

//-------------------------------------------------------------------------------------------------
// Weighted Random Early Dropping (WRED)
//
// @param hdr : Parse headers. Only ipv4.diffserv or ipv6.traffic_class are modified.
// @param eg_md : Egress metadata fields.
// @param eg_intr_md
// @param flag : A flag indicating that the packet should get dropped by system ACL.
//-------------------------------------------------------------------------------------------------
control WRED(inout switch_header_t hdr,
             in switch_egress_metadata_t eg_md,
             in egress_intrinsic_metadata_t eg_intr_md,
             out bool flag) {

    switch_wred_index_t index;

    // Flag indicating that the packet needs to be marked/dropped.
    bit<1> wred_flag;
    const switch_uint32_t wred_size = 1 << 8;
    // Per color/qid/port counter. 7-bit local port is used to save resources.
    const switch_uint32_t wred_index_table_size = 2048;

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    Wred<bit<19>, switch_wred_index_t>(wred_size, 1 /* drop value*/, 0 /* no drop value */) wred;

    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = SWITCH_ECN_CODEPOINT_CE;
        flag = false;
    }

    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = SWITCH_ECN_CODEPOINT_CE;
        flag = false;
    }

    action drop() {
        flag = true;
    }

    // Packets from flows that are not ECN capable will continue to be dropped by RED (as was the
    // case before ECN) -- RFC2884
    table wred_action {
        key = {
            index : exact;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.diffserv : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.traffic_class : ternary;
        }

        actions = {
            NoAction;
            drop;
            set_ipv4_ecn;
            set_ipv6_ecn;
        }

        // Requires 4 entries per WRED profile to drop or mark IPv4/v6 packets.
        size = 4 * wred_size;
    }

    action set_wred_index(switch_wred_index_t wred_index) {
        index = wred_index;
        wred_flag = (bit<1>) wred.execute(eg_md.qos.qdepth, wred_index);
    }

    // Asymmetric table to get the attached WRED profile.
    table wred_index {
        key = {
           eg_intr_md.egress_port : exact @name("port");
           eg_md.qos.qid : exact @name("qid");
           eg_md.qos.color : exact @name("color");
        }

        actions = {
            NoAction;
            set_wred_index;
        }

        const default_action = NoAction;
        size = wred_index_table_size;
    }

    action count() { stats.count(); }

    table wred_stats {
        key = {
            eg_intr_md.egress_port : exact @name("port");
            eg_md.qos.qid : exact @name("qid");
            eg_md.qos.color : exact @name("color");
            flag : exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = 2 * wred_index_table_size;
        counters = stats;
    }

    apply {
# 138 "wred.p4"
    }
}
# 56 "npb.p4" 2
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
// DTel ACL for v4/v6 traffic that specifies which flows to monitor.
//
// @param lkp : Lookup fields.
// @param ig_md : Ingress metadata fields.
// @param report_type : Telemetry report type is a bit-map that indicates which type of telemetry
// reports (D/Q/F) can be generated for the tracked flow.
//-----------------------------------------------------------------------------
control DtelAcl(in switch_lookup_fields_t lkp,
                in switch_ingress_metadata_t ig_md,
                out switch_dtel_report_type_t report_type)(
                switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }

    table acl {
        key = {
            lkp.mac_type : ternary; lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            acl_hit;
        }

        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv4DtelAcl(in switch_lookup_fields_t lkp,
                    in switch_ingress_metadata_t ig_md,
                    out switch_dtel_report_type_t report_type)(
                    switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }

    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            acl_hit();
        }

        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv6DtelAcl(in switch_lookup_fields_t lkp,
                    in switch_ingress_metadata_t ig_md,
                    out switch_dtel_report_type_t report_type)(
                    switch_uint32_t table_size=512) {
    action acl_hit(switch_dtel_report_type_t type) {
        report_type = type;
    }

    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            acl_hit();
        }

        const default_action = acl_hit(SWITCH_DTEL_REPORT_TYPE_NONE);
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

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
        ig_intr_md_for_tm.deflect_on_drop = 1;
    }

    action disable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 0;
    }

    table config {
        key = {
            ig_md.dtel.report_type : ternary;
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
            ig_md.qos.qid: ternary @name("qid");
            ig_md.multicast.id : ternary;
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

    table config {
        key = {
            drop_reason : ternary;
            dtel_md.report_type : ternary;
        }

        actions = {
            NoAction;
            mirror;
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
control DropReport(in switch_dtel_metadata_t dtel_md, in bit<32> hash, inout bit<2> flag) {
    // Two bit arrays of 128K bits.
    Register<bit<1>, bit<17>>(1 << 17, 1) array1;
    Register<bit<1>, bit<17>>(1 << 17, 1) array2;
    RegisterAction<bit<1>, bit<17>, bit<1>>(array1) filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    RegisterAction<bit<1>, bit<17>, bit<1>>(array2) filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    apply {
        if (dtel_md.report_type & SWITCH_DTEL_REPORT_TYPE_FLOW == SWITCH_DTEL_REPORT_TYPE_FLOW)
            flag[0:0] = filter1.execute(hash[16:0]);
        if (dtel_md.report_type & SWITCH_DTEL_REPORT_TYPE_FLOW == SWITCH_DTEL_REPORT_TYPE_FLOW)
            flag[1:1] = filter2.execute(hash[31:15]);
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
    const bit<32> queue_table_size = 2048;

    // Register to store latency/qdepth thresholds per (port, queue) pair.
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_table_size) thresholds;
    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            // Set the flag if either of qdepth or latency exceeds the threshold.
            if (reg.latency < eg_md.dtel.latency || reg.qdepth < (bit<32>) eg_intr_md.enq_qdepth) {
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
            eg_md.qos.qid : exact @name("qid");
            eg_intr_md.egress_port : exact @name("port");
        }

        actions = {
            set_qalert;
            set_qmask;
        }

        size = queue_table_size;
    }

    // Register to store last observed quantized latency and a counter to track available quota.
    Register<switch_queue_report_quota_t, bit<16>>(queue_table_size) quotas;
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) reset_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            reg.counter = (bit<32>) quota_[15:0];
        }
    };

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;

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
            flag = 0;
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
            qalert : exact;
            eg_md.qos.qid : exact @name("qid");
            eg_intr_md.egress_port : exact @name("port");
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







    }
}


control FlowReport(inout switch_egress_metadata_t eg_md, out bit<2> flag) {
    bit<16> digest;

    //TODO(msharif): Use a better hash
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;

    // Two bit arrays of 32K bits. The probability of false positive is about 1% for 4K flows.
    Register<bit<16>, bit<16>>(1 << 16, 1) array1;
    Register<bit<16>, bit<16>>(1 << 16, 1) array2;

    // Encodes 2 bit information for flow state change detection
    // rv = 0b1* : New flow.
    // rv = 0b01 : No change in digest is detected.

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array1) filter1 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == digest) {
                rv = 1;
            } // else if (reg == 16w0) {
              //   rv = 2;
              // }
            reg = digest;
        }
    };

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<16>, bit<2>>(array2) filter2 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == digest) {
                rv = 0b01;
            } // else if (reg == 16w0) {
              //  rv = 0b10;
              // }
            reg = digest;
        }
    };

    apply {







    }
}

control IngressDtel(in switch_header_t hdr,
                    in switch_lookup_fields_t lkp,
                    inout switch_ingress_metadata_t ig_md,
                    in bit<16> hash,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm) {

    Ipv4DtelAcl() ipv4_dtel_acl;
    DtelAcl() dtel_acl;

    DeflectOnDrop() dod;
    MirrorOnDrop() mod;

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(120, selector_hash, SelectorMode_t.FAIR) session_selector;
    action set_mirror_session(switch_mirror_session_t session_id) {
        ig_md.dtel.session_id = session_id;
    }

    table mirror_session {
        key = { hash : selector; }
        actions = {
            NoAction;
            set_mirror_session;
        }

        implementation = session_selector;
    }

    apply {
# 476 "dtel.p4"
    }
}


control EgressDtel(inout switch_header_t hdr,
                   inout switch_egress_metadata_t eg_md,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   in bit<32> hash,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report;

    bit<2> drop_report_flag;
    bit<2> flow_report_flag;
    bit<1> queue_report_flag;

    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
            reg = reg + 1;
            rv = reg;
        }
    };

    action mirror() {
        // Generate switch local telemetry report for flow/queue reports.
        eg_md.mirror.type = 4;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action drop() {
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update(
            switch_uint32_t switch_id,
            bit<6> hw_id,
            bit<4> next_proto,
            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.d_q_f = report_type;
        hdr.dtel.reserved = 0;
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.dtel.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;
        hdr.dtel.switch_id = switch_id;
    }

    // config table is responsible for triggering the flow/queue report generation for normal
    // traffic and updating the dtel report headers for telemetry reports.
    // pkt_src         report_type drop_report_flag flow_report_flag queue_report_flag  action
    // CLONED_INGRESS  DROP        0                *                *                  update
    // CLONED_INGRESS  DROP        1                *                *                  drop
    // DEFLECTED       DROP        0                *                *                  update
    // DEFLECTED       DROP        1                *                *                  drop
    // BRIDGED         DROP        *                *                *                  NoAction
    // This table is asymmetric as hw_id is pipe specific.

    table config {
        key = {
            eg_md.pkt_src : ternary;
            eg_md.dtel.report_type : ternary;
            drop_report_flag : ternary;
            flow_report_flag : ternary;
            queue_report_flag : ternary;
        }

        actions = {
            NoAction;
            drop;
            mirror;
            update;
        }

        const default_action = NoAction;
    }

    action convert_ingress_port(switch_port_t port) {
        eg_md.ingress_port = port;
    }

    action convert_egress_port(switch_port_t port) {
        eg_md.port = port;
    }

    //TODO(msharif) :  Convert h/w port to front panel port for telemetry reports.
    table egress_port_conversion {
        key = { eg_md.port : exact @name("port"); }
        actions = {
            NoAction;
            convert_egress_port;
        }

        const default_action = NoAction;
    }

    table ingress_port_conversion {
        key = { eg_md.ingress_port : exact @name("port"); }
        actions = {
            NoAction;
            convert_ingress_port;
        }

        const default_action = NoAction;
    }

    apply {
# 605 "dtel.p4"
    }
}
# 57 "npb.p4" 2

// -------------------------------------
// Extreme Networks - Added
// -------------------------------------

# 1 "npb_ing_sfc_top.p4" 1

control npb_ing_sfc_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // temporary internal variables
 bit<8> service_func_chain_internal;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: local and remote bitmasks defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy 

 // =========================================================================
 // Table #1/2/3: FlowType Classifier
 // =========================================================================

 action ing_sfc_sfc_classifier_123_hit (
  bit<24> nsh_sph_spi,
  bit<8> nsh_sph_si,

  bit<8> flow_type,
  bit<8> srvc_func_bitmask_local,
  bit<8> srvc_func_bitmask_remote,

  bit<8> service_func_chain
 ) {
  ig_md.nsh_extr.valid = 1;

  // base - word 0

  // base - word 1
  ig_md.nsh_extr.spi = nsh_sph_spi;
  ig_md.nsh_extr.si = nsh_sph_si;

  // ext type 1 - word 0
  ig_md.nsh_extr.extr_flow_type = flow_type;
  ig_md.nsh_extr.extr_srvc_func_bitmask_local = srvc_func_bitmask_local; // set this in same table as service_func_chain is set
  ig_md.nsh_extr.extr_srvc_func_bitmask_remote = srvc_func_bitmask_remote; // set this in same table as service_func_chain is set

  // change metadata
//		service_func_chain_internal                  = service_func_chain;
 }

 // ---------------------------------

 table ing_sfc_sfc_class_123 {
  key = {
   // l3
   ig_md.lkp_nsh.ip_type : exact;
   ig_md.lkp_nsh.ip_proto : exact;

   // l4
   ig_md.lkp_nsh.l4_src_port : ternary;
   ig_md.lkp_nsh.l4_dst_port : ternary;

   ig_md.nsh_extr.extr_tenant_id : exact;
  }

  actions = {
   NoAction;
   ing_sfc_sfc_classifier_123_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #1: FlowType Classifier
 // =========================================================================

 action ing_sfc_flowtype_classifier_1_hit (
  bit<8> flow_type
 ) {
  // ext type 1 - word 0
  ig_md.nsh_extr.extr_flow_type = flow_type;
 }

 // ---------------------------------

 table ing_sfc_flowtype_class_1 {
  key = {
   // l3
   ig_md.lkp_nsh.ip_type : exact;
   ig_md.lkp_nsh.ip_proto : exact;

   // l4
   ig_md.lkp_nsh.l4_src_port : ternary;
   ig_md.lkp_nsh.l4_dst_port : ternary;

   ig_md.nsh_extr.extr_tenant_id : exact;
  }

  actions = {
   NoAction;
   ing_sfc_flowtype_classifier_1_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #2/3: Combined SFC Classifier / Simple Flow Scheduler
 // =========================================================================

 action ing_sfc_sfc_classifier_23_hit (
  bit<24> nsh_sph_spi,
  bit<8> nsh_sph_si,

  bit<8> srvc_func_bitmask_local,
  bit<8> srvc_func_bitmask_remote,

  bit<8> service_func_chain
 ) {
  ig_md.nsh_extr.valid = 1;

  // base - word 0

  // base - word 1
  ig_md.nsh_extr.spi = nsh_sph_spi;
  ig_md.nsh_extr.si = nsh_sph_si;

  // ext type 1 - word 0
  ig_md.nsh_extr.extr_srvc_func_bitmask_local = srvc_func_bitmask_local;
  ig_md.nsh_extr.extr_srvc_func_bitmask_remote = srvc_func_bitmask_remote;

  // change metadata
//		service_func_chain_internal                  = service_func_chain;
 }

 // ---------------------------------

 table ing_sfc_sfc_class_23 {
  key = {
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   ing_sfc_sfc_classifier_23_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFC_NSH_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #2: SFC Classifier
 // =========================================================================

 action ing_sfc_sfc_classifier_2_hit (
  bit<8> nsh_sph_si,

  bit<8> srvc_func_bitmask_local,
  bit<8> srvc_func_bitmask_remote,

  bit<8> service_func_chain
 ) {
  // base - word 0

  // base - word 1
  ig_md.nsh_extr.si = nsh_sph_si;

  // ext type 1 - word 0
  ig_md.nsh_extr.extr_srvc_func_bitmask_local = srvc_func_bitmask_local;
  ig_md.nsh_extr.extr_srvc_func_bitmask_remote = srvc_func_bitmask_remote;

  // change metadata
  service_func_chain_internal = service_func_chain;
 }

 // ---------------------------------

 table ing_sfc_sfc_class_2 {
  key = {
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   ing_sfc_sfc_classifier_2_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFC_NSH_TABLE_DEPTH;
 }



 // =========================================================================
 // Table #3: Simple Flow Scheduler
 // =========================================================================

 action ing_sfc_flow_schd_3_hit (
  bit<24> nsh_sph_spi
 ) {
  ig_md.nsh_extr.valid = 1;

  // change metadata


  // base - word 1

  ig_md.nsh_extr.spi = nsh_sph_spi;

  // ext type 1 - word 0


 }

 // ---------------------------------






 // ---------------------------------

 table ing_sfc_flow_schd_3 {
  key = {
   service_func_chain_internal : exact;
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   ing_sfc_flow_schd_3_hit;

  }

  const default_action = NoAction;
  size = NPB_ING_SFC_NSH_TABLE_DEPTH;
 }
# 334 "npb_ing_sfc_top.p4"
 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // ---------------------------------------------------------------------
  // Classify Packet
  // ---------------------------------------------------------------------

  if(hdr.nsh_extr_underlay.isValid()) {

   // -----------------------------------------------------------------
   // Packet does    have a NSH header on it --> just copy it to internal NSH structure
   // -----------------------------------------------------------------

   // metadata
   ig_md.nsh_extr.valid = 1;

   // base: word 0

   // base: word 1
   ig_md.nsh_extr.spi = hdr.nsh_extr_underlay.spi;
   ig_md.nsh_extr.si = hdr.nsh_extr_underlay.si;

   // ext: type 2 - word 0

   // ext: type 2 - word 1+
   ig_md.nsh_extr.extr_srvc_func_bitmask_local = hdr.nsh_extr_underlay.extr_srvc_func_bitmask; //  1 byte (i.e. local bitmask = remote bitmask)
   ig_md.nsh_extr.extr_tenant_id = hdr.nsh_extr_underlay.extr_tenant_id; //  3 bytes
   ig_md.nsh_extr.extr_flow_type = hdr.nsh_extr_underlay.extr_flow_type; //  1 byte?

  } else {

   // -----------------------------------------------------------------
   // Packet doesn't have a NSH header on it --> try to classify / populate internal NSH structure
   // -----------------------------------------------------------------



   // one table
   ing_sfc_sfc_class_123.apply(); // note: this will always be simple
# 399 "npb_ing_sfc_top.p4"
  }

  // -----------------------------------------------------------------
  // Set Tenant ID (6th tuple)
  // -----------------------------------------------------------------

//		ig_md.nsh_extr.extr_tenant_id                = ig_md.tunnel.id;
  ig_md.nsh_extr.extr_tenant_id = (bit<16>)ig_md.bd_nsh;


// Moved teid extraction to parser....
//		if(hdr.gtp_v1_v2_teid.isValid()) {
//			ig_md.nsh_extr.extr_tenant_id                = (bit<TENANT_ID_WIDTH>)hdr.gtp_v1_v2_teid.teid;
//		}


 }

}
# 63 "npb.p4" 2
# 1 "npb_ing_sff_top.p4" 1
# 1 "npb_ing_sf_npb_basic_adv_top.p4" 1
//#include "npb_ing_sf_npb_basic_adv_dedup.p4"

control npb_ing_sf_npb_basic_adv_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // candidate values (used if all tables have hits)
 bit<8> flow_type_new;
 bit<8> nsh_sph_si_new;
 bit<8> nsh_srvc_func_bitmask_local_new; // set this in same table as service_func_chain is set
 bit<8> nsh_srvc_func_bitmask_remote_new; // set this in same table as service_func_chain is set

 // temporary internal variables
 bit<8> service_func_chain_internal;
 bit<1> action_bitmask_internal;

 bit<1> table_1_hit_internal;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: local and remote bitmasks defined as follows....
 //
 //   [0:0] sf #1:  ingress basic/advanced
 //   [1:1] sf #2:  unused (was multicast)
 //   [2:2] sf #3:  egress proxy 

 // Note: ingress action_bitmask defined as follows....
 //
 //   [0:0] act #1: unused (was dedup, now moved to egress)

 // =========================================================================
 // Table #1: Policy
 // =========================================================================

 action npb_ing_sf_policy_hit (
  bit<8> flow_type,

  bit<8> nsh_sph_si,

  bit<8> srvc_func_bitmask_local,
  bit<8> srvc_func_bitmask_remote,

  bit<8> service_func_chain,

  bit<1> action_bitmask,
  bit<3> discard
 ) {
  // change nsh

  // change metadata
  flow_type_new = flow_type;

  // base - word 1
  nsh_sph_si_new = nsh_sph_si;

  // ext type 1 - word 0
  nsh_srvc_func_bitmask_local_new = srvc_func_bitmask_local; // set this in same table as service_func_chain is set
  nsh_srvc_func_bitmask_remote_new = srvc_func_bitmask_remote; // set this in same table as service_func_chain is set

  // change metadata
  service_func_chain_internal = service_func_chain;

  action_bitmask_internal = action_bitmask;
  ig_intr_md_for_dprsr.drop_ctl = discard; // drop packet

  table_1_hit_internal = 1;
 }

 // ---------------------------------
 // Combined l2 / L3/4 / L7: v4
 // ---------------------------------

 table npb_ing_sf_policy_l2347_v4 {
  key = {
   // l2
   ig_md.lkp_nsh.mac_src_addr : ternary;
   ig_md.lkp_nsh.mac_dst_addr : ternary;
   ig_md.lkp_nsh.mac_type : ternary;

   // l3
   ig_md.lkp_nsh.ip_type : ternary;
   ig_md.lkp_nsh.ip_proto : ternary;
   ig_md.lkp_nsh.ip_src_addr[31:0] : ternary;
   ig_md.lkp_nsh.ip_dst_addr[31:0] : ternary;

   // l4
   ig_md.lkp_nsh.l4_src_port : ternary;
   ig_md.lkp_nsh.l4_dst_port : ternary;

   // l7

   ig_md.lkp_nsh.l7_udf : ternary;


   // metadata
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   npb_ing_sf_policy_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L2_TABLE_DEPTH;
 }

 // ---------------------------------
 // l2 / L3/4 / L7: v6
 // ---------------------------------

 table npb_ing_sf_policy_l2347_v6 {
  key = {
   // l2
   ig_md.lkp_nsh.mac_src_addr : ternary;
   ig_md.lkp_nsh.mac_dst_addr : ternary;
   ig_md.lkp_nsh.mac_type : ternary;

   // l3
   ig_md.lkp_nsh.ip_type : ternary;
   ig_md.lkp_nsh.ip_proto : ternary;
   ig_md.lkp_nsh.ip_src_addr : ternary;
   ig_md.lkp_nsh.ip_dst_addr : ternary;

   // l4
   ig_md.lkp_nsh.l4_src_port : ternary;
   ig_md.lkp_nsh.l4_dst_port : ternary;

   // l7

   ig_md.lkp_nsh.l7_udf : ternary;


   // metadata
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   npb_ing_sf_policy_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L2_TABLE_DEPTH;
 }

 // ---------------------------------
 // l2:
 // ---------------------------------

 table npb_ing_sf_policy_l2 {
  key = {
   // l2
   ig_md.lkp_nsh.mac_src_addr : ternary;
   ig_md.lkp_nsh.mac_dst_addr : ternary;
   ig_md.lkp_nsh.mac_type : ternary;

   // metadata
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   npb_ing_sf_policy_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L2_TABLE_DEPTH;
 }

 // ---------------------------------
 // l3/l4: v4 lpm
 // ---------------------------------

 table npb_ing_sf_policy_l34_v4 {
  key = {
   // l3
   ig_md.lkp_nsh.ip_type : ternary;
   ig_md.lkp_nsh.ip_proto : ternary;
   ig_md.lkp_nsh.ip_src_addr[31:0] : ternary;
   ig_md.lkp_nsh.ip_dst_addr[31:0] : ternary;

   // l4
   ig_md.lkp_nsh.l4_src_port : ternary;
   ig_md.lkp_nsh.l4_dst_port : ternary;



   // l7

   ig_md.lkp_nsh.l7_udf : ternary;




   // metadata
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   npb_ing_sf_policy_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_V4_TABLE_DEPTH;
 }

 // ---------------------------------
 // l3/l4: v6 lpm
 // ---------------------------------


 table npb_ing_sf_policy_l34_v6 {
  key = {
   // l3
   ig_md.lkp_nsh.ip_type : ternary;
   ig_md.lkp_nsh.ip_proto : ternary;
   ig_md.lkp_nsh.ip_src_addr : ternary;
   ig_md.lkp_nsh.ip_dst_addr : ternary;

   // l4
   ig_md.lkp_nsh.l4_src_port : ternary;
   ig_md.lkp_nsh.l4_dst_port : ternary;



   // l7

   ig_md.lkp_nsh.l7_udf : ternary;




   // metadata
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   npb_ing_sf_policy_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_V6_TABLE_DEPTH;
 }


 // ---------------------------------
 // l7:
 // ---------------------------------

 table npb_ing_sf_policy_l7 {
  key = {
   // l4
   ig_md.lkp_nsh.l4_src_port : ternary;
   ig_md.lkp_nsh.l4_dst_port : ternary;

   // l7

   ig_md.lkp_nsh.l7_udf : ternary;


   // metadata
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   npb_ing_sf_policy_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_V6_TABLE_DEPTH;
 }



 // =========================================================================
 // Table #2: Simple Flow Scheduler
 // =========================================================================

 action npb_ing_sf_flow_schd_hit (
  bit<24> nsh_sph_path_identifier
 ) {
  // change nsh

  // change metadata
  ig_md.nsh_extr.extr_flow_type = flow_type_new;

  // base - word 1
  ig_md.nsh_extr.spi = nsh_sph_path_identifier;
  ig_md.nsh_extr.si = nsh_sph_si_new;

  // ext type 1 - word 0
  ig_md.nsh_extr.extr_srvc_func_bitmask_local = nsh_srvc_func_bitmask_local_new;
  ig_md.nsh_extr.extr_srvc_func_bitmask_remote = nsh_srvc_func_bitmask_remote_new;
 }

 // ---------------------------------

 action npb_ing_sf_flow_schd_miss (
 ) {
  // do nothing on a miss, I think?
 }

 // ---------------------------------

 table npb_ing_sf_flow_schd {
  key = {
   service_func_chain_internal : exact;
   ig_md.nsh_extr.extr_tenant_id : exact;
//			ig_md.nsh_extr.extr_flow_type : exact;
   flow_type_new : exact;
  }

  actions = {
   NoAction;
   npb_ing_sf_flow_schd_hit;
   npb_ing_sf_flow_schd_miss;
  }

  const default_action = npb_ing_sf_flow_schd_miss;
  size = NPB_ING_SF_0_BAS_ADV_SCHD_TABLE_PART1_DEPTH;
 }
# 424 "npb_ing_sf_npb_basic_adv_top.p4"
 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  ig_md.nsh_extr.si = ig_md.nsh_extr.si - 1; // decrement sp_index

  // -------------------------------------
  // Action Lookup
  // -------------------------------------
# 449 "npb_ing_sf_npb_basic_adv_top.p4"
  // -------------------------------------



  // Glenn wants l2 policy to have priority over l3, so only apply l3 if
  // l2 had a miss....

  // ----- l3/4 -----
  if (ig_md.lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV4) {
   npb_ing_sf_policy_l34_v4.apply();

  } else if(ig_md.lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV6) {
   npb_ing_sf_policy_l34_v6.apply();

  }

  // ----- l2 -----
//		if(ig_md.lkp_nsh.ip_type == SWITCH_IP_TYPE_NONE) {
   npb_ing_sf_policy_l2.apply();
//		}
# 498 "npb_ing_sf_npb_basic_adv_top.p4"
  // -------------------------------------
  // Action(s)
  // -------------------------------------
  if(action_bitmask_internal[0:0] == 1) {

   // -------------------------------------
   // Action #0 - Deduplication
   // -------------------------------------
/*
#ifdef SF_0_DEDUP_ENABLE
			npb_ing_sf_npb_basic_adv_dedup.apply (
				hdr,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
#endif
*/
  }

  // -------------------------------------
  // Flow Scheduler
  // -------------------------------------
  if(table_1_hit_internal == 1) {
   npb_ing_sf_flow_schd.apply();
  }

 }
}
# 2 "npb_ing_sff_top.p4" 2
//#include "npb_ing_sf_repli_top.p4"

control npb_ing_sff_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: local bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy 

 // =========================================================================
 // Table #1: ARP
 // =========================================================================

 // Derek TODO:
 //
 // What should be the default action on a miss -- the l2 miss action, or the
 // l3 miss action?  It seems like anything that got here would have been
 // addressed to us, so I'm thinking the l3 miss action....

 // =====================================
 // L2 Actions
 // =====================================

 action dmac_miss(
 ) {
  ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;

  ig_md.nsh_extr.end_of_chain = 1;
 }

 // =====================================

 action dmac_hit(
  switch_ifindex_t ifindex,
  switch_port_lag_index_t port_lag_index,

  bit<1> end_of_chain
 ) {
  ig_md.egress_ifindex = ifindex;
  ig_md.egress_port_lag_index = port_lag_index;
  ig_md.checks.same_if = ig_md.ifindex ^ ifindex;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================

 action dmac_multicast(
  switch_mgid_t index,

  bit<1> end_of_chain
 ) {
  ig_intr_md_for_tm.mcast_grp_b = index;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================

 action dmac_redirect(
  switch_nexthop_t nexthop_index,

  bit<1> end_of_chain
 ) {
  ig_md.nexthop = nexthop_index;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================

 action dmac_drop(
  bit<1> end_of_chain
 ) {
  //TODO(msharif): Drop the packet.

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================
 // L3 Unicast Actions
 // =====================================

 action fib_hit(
  switch_nexthop_t nexthop_index,

  bit<1> end_of_chain
 ) {
  ig_md.nexthop = nexthop_index;
  ig_md.flags.routed = true;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================

 action fib_miss(
 ) {
  ig_md.flags.routed = false;

  ig_md.nsh_extr.end_of_chain = 1;
 }

 // =====================================

 action fib_myip(
  bit<1> end_of_chain
 ) {
  ig_md.flags.myip = true;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================
 // L3 Multicast Actions
 // =====================================

    action set_multicast_route(
  switch_multicast_mode_t mode,
  switch_mgid_t index,
  bit<1> end_of_chain
 ) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = true;
        ig_md.flags.routed = true;
        ig_md.flags.flood_to_multicast_routers = false;
        ig_md.checks.same_bd = 0x3fff;

  ig_md.multicast.mode = mode;
  ig_intr_md_for_tm.mcast_grp_b = index;
  ig_md.nsh_extr.end_of_chain = end_of_chain;
    }

 // =====================================

    action set_multicast_bridge(
  bool mrpf,

  switch_mgid_t index,
  bit<1> end_of_chain
 ) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = false;

  ig_intr_md_for_tm.mcast_grp_b = index;
  ig_md.nsh_extr.end_of_chain = end_of_chain;
    }

 // =====================================

    action set_multicast_flood(
  bool mrpf,
  bool flood,

  bit<1> end_of_chain
 ) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = flood;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
    }

 // =====================================
 // Table
 // =====================================

 table nbp_ing_sff_arp {
  key = {
   ig_md.nsh_extr.spi : exact;
   ig_md.nsh_extr.si : exact;
  }

  actions = {
   // l2 actions
   dmac_miss;
   dmac_hit;
   dmac_multicast;
   dmac_redirect;
   dmac_drop;

   // l3 unicast actions
   fib_miss;
   fib_hit;
   fib_myip;

   // l3 multicast actions
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
  }

//		const default_action = dmac_miss;
  const default_action = fib_miss;
  size = NPB_ING_SFF_ARP_TABLE_DEPTH;
 }

 // =========================================================================
 // Table - TTL Decrement
 // =========================================================================

/*
    action new_ttl(bit<6> ttl) {
        ig_md.nsh_extr.ttl = ttl;
    }

    action discard() {
        ig_intr_md_for_dprsr.drop_ctl = 1;
    }

    table nbp_ing_sff_dec_ttl {
        key = { ig_md.nsh_extr.ttl : exact; }
        actions = { new_ttl; discard; }
        const entries = {
            0  : new_ttl(63);
            1  : discard();
            2  : new_ttl(1);
            3  : new_ttl(2);
            4  : new_ttl(3);
            5  : new_ttl(4);
            6  : new_ttl(5);
            7  : new_ttl(6);
            8  : new_ttl(7);
            9  : new_ttl(8);
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
*/

 // =========================================================================
 // Apply
 // =========================================================================

 // Need to do two table lookups here?
 //
 // 1: service func lookup to get sf bitmask.
 // 2: forwarding lookup, after any sf's have reclassified the packet.

 apply {

  if(ig_md.nsh_extr.valid == 1) {

   // -------------------------------------
   // Decrement and Check TTL
   // -------------------------------------

   // Note: From RFC 8300, page 9: "each SFF MUST decrement the TTL
   // value "prior to the NSH forwarding lookup".
   //
   // Derek: However, why does it matter where the decrement is done,
   // since TTL isn't part of the forwarding lookup anyway???

//        	npb_ing_sff_dec_ttl.apply();

   // -------------------------------------
   // SF(s)
   // -------------------------------------

   if(ig_md.nsh_extr.extr_srvc_func_bitmask_local[0:0] == 1) {

    // -------------------------------------
    // SF #0
    // -------------------------------------

    npb_ing_sf_npb_basic_adv_top.apply (
     hdr,
     ig_md,
     ig_intr_md,
     ig_intr_md_from_prsr,
     ig_intr_md_for_dprsr,
     ig_intr_md_for_tm
    );

    // check sp index
    if(ig_md.nsh_extr.si == 0) {
     ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
    }
   }

   // -------------------------------------
   // Forwarding Lookup
   // -------------------------------------

   // table here:

   nbp_ing_sff_arp.apply();

  }

 }

}
# 64 "npb.p4" 2

# 1 "npb_egr_sff_top_part1.p4" 1
# 1 "npb_egr_sf_proxy_top_part1.p4" 1
//#include "npb_egr_sf_proxy_hdr_strip.p4"
//#include "npb_egr_sf_proxy_hdr_edit.p4"
//#include "npb_egr_sf_proxy_truncate.p4"
//#include "npb_egr_sf_proxy_meter.p4"

control npb_egr_sf_proxy_top_part1 (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: unused (was header strip)
 //   [1:1] act #2: unused (was header edit)
 //   [2:2] act #3: unused (reserved for truncate)
 //   [3:3] act #4: meter
 //   [4:4] act #5: dedup

 // =========================================================================
 // Table #1: Proxy Action Select
 // =========================================================================

 action egr_sf_action_sel_hit(
  bit<5> action_bitmask,
  bit<10> meter_id,
  bit<8> meter_overhead,
  bit<3> discard
 ) {
  eg_md.action_bitmask = action_bitmask;

  eg_md.meter_id = meter_id;
  eg_md.meter_overhead = meter_overhead;

  eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet

 }

 // =====================================

 action egr_sf_action_sel_miss(
 ) {
  eg_md.action_bitmask = 0;
 }

 // =====================================

 table egr_sf_action_sel {
  key = {
      hdr.nsh_extr_underlay.spi : exact;
      hdr.nsh_extr_underlay.si : exact;
  }

  actions = {
      egr_sf_action_sel_hit;
      egr_sf_action_sel_miss;
  }

  const default_action = egr_sf_action_sel_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_TABLE_DEPTH;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // ----------------------------------
  // Remove NSH
  // ----------------------------------

  hdr.nsh_extr_underlay.setInvalid(); // proxy removes the nsh

  // ----------------------------------
  // Action Lookup
  // ----------------------------------

  egr_sf_action_sel.apply();

  // ----------------------------------
  // Actions(s)
  // ----------------------------------

  // Commented out, because all reframing is done using existing switch.p4
  // reframing code....

/*
		if(action_bitmask[0:0] == 1) {

			// ----------------------------------
			// Action #0 - Hdr Strip
			// ----------------------------------
			npb_egr_sf_proxy_hdr_strip.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

		if(action_bitmask[1:1] == 1) {

			// ----------------------------------
			// Action #1 - Hdr Edit
			// ----------------------------------
			npb_egr_sf_proxy_hdr_edit.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

		if(action_bitmask[2:2] == 1) {

			// ----------------------------------
			// Action #2 - Truncate
			// ----------------------------------
			npb_egr_sf_proxy_truncate.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

		if(action_bitmask[3:3] == 1) {

			// ----------------------------------
			// Action #3 - Meter
			// ----------------------------------
#ifdef SF_2_METER_ENABLE
			npb_egr_sf_proxy_meter.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport,

				meter_id,
				meter_overhead
			);
#endif
		}
*/
 }

}
# 2 "npb_egr_sff_top_part1.p4" 2

control npb_egr_sff_top_part1 (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

    // Note: local bitmask defined as follows....
    //
    //   [0:0] sf  #1: ingress basic/advanced
    //   [1:1] sf  #2: unused (was multicast)
    //   [2:2] sf  #3: egress proxy 

 // =========================================================================
 // Table
 // =========================================================================

    action new_ttl(bit<6> ttl) {
        hdr.nsh_extr_underlay.ttl = ttl;
    }

    action discard() {
        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table npb_egr_sff_dec_ttl {
        key = { hdr.nsh_extr_underlay.ttl : exact; }
        actions = { new_ttl; discard; }
        const entries = {
            0 : new_ttl(63);
            1 : discard();
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

  // -----------------------------------------------------------------------------
  // Copy internal NSH structure --> Packet NSH structure
  // -----------------------------------------------------------------------------

  // Note: do this here and not in the first state of the parser, because they will
  // get overwritten in the parser if the packet already has an nsh header on it.

  // base: word 0
  // (nothing to do)

  // base: word 1
  hdr.nsh_extr_underlay.spi = eg_md.nsh_extr.spi;
  hdr.nsh_extr_underlay.si = eg_md.nsh_extr.si;

  // ext: type 2 - word 0
  // (nothing to do)

  // ext: type 2 - word 1+
  hdr.nsh_extr_underlay.extr_srvc_func_bitmask = eg_md.nsh_extr.extr_srvc_func_bitmask_remote; //  1 byte
  hdr.nsh_extr_underlay.extr_tenant_id = eg_md.nsh_extr.extr_tenant_id; //  3 bytes
  hdr.nsh_extr_underlay.extr_flow_type = eg_md.nsh_extr.extr_flow_type; //  1 byte?

  // ----------------------------------------

  if(hdr.nsh_extr_underlay.isValid()) {
   // ----------------------------------------
   // Packet has a NSH header on it --> fix it up
   // ----------------------------------------

   // Note: From RFC 8300, page 9: "each SFF MUST decrement the TTL
   // value "prior to the NSH forwarding lookup".
   //
   // Derek: However, why does it matter where the decrement is done,
   // since TTL isn't part of the forwarding lookup anyway???

   npb_egr_sff_dec_ttl.apply();

  } else {
   // ----------------------------------------
   // Packet does not have NSH header on it --> fix it up
   // ----------------------------------------

   if(eg_md.nsh_extr.valid == 1) {
     hdr.nsh_extr_underlay.setValid();
   }

   // base: word 0
   hdr.nsh_extr_underlay.version = 0x0;
   hdr.nsh_extr_underlay.o = 0x0;
   hdr.nsh_extr_underlay.reserved = 0x0;
   hdr.nsh_extr_underlay.ttl = 0x0;
   hdr.nsh_extr_underlay.len = 0x5; // in 4-byte words
   hdr.nsh_extr_underlay.reserved2 = 0x0;
   hdr.nsh_extr_underlay.md_type = 0x2;
   hdr.nsh_extr_underlay.next_proto = 0x3;

   // base: word 1
   // (nothing to do -- these fields get set in the parser from the bridged metadata)

   // ext: type 2 - word 0
   hdr.nsh_extr_underlay.md_class = 0x0;
   hdr.nsh_extr_underlay.type = 0x0;
   hdr.nsh_extr_underlay.reserved3 = 0x0;
   hdr.nsh_extr_underlay.md_len = 0x8;

   // ext: type 2 - word 1+
   // (nothing to do -- these fields get set in the parser from the bridged metadata)

   hdr.nsh_extr_underlay.extr_rsvd = 0x0;

  }

  // ----------------------------

  // Regardless if the packet already had an nsh header on it or we added one,
  // invalidate it if we're at the end of the chain....
  if(eg_md.nsh_extr.end_of_chain == 1) {
   hdr.nsh_extr_underlay.setInvalid();
  }

  // -----------------------------------------------------------------------------
  // Do some work
  // -----------------------------------------------------------------------------

  if(eg_md.nsh_extr.valid == 1) {

   // -------------------------------------
   // SF(s)
   // -------------------------------------

   if(eg_md.nsh_extr.extr_srvc_func_bitmask_local[2:2] == 1) {

    // -------------------------------------
    // SF #0
    // -------------------------------------

    npb_egr_sf_proxy_top_part1.apply (
     hdr,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

    // DON"T NEED TO DO THIS.  THE PROXY DELETES THE NSH HEADER SO THERES NO POINT IN CHECKING.
    // check sp index
//				if(eg_md.nsh_extr_underlay.si == 0) {
//					eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//				}

   } else {
    eg_md.action_bitmask = 0;
   }

  } else {
   eg_md.action_bitmask = 0;
  }

 }

}
# 66 "npb.p4" 2
# 1 "npb_egr_sff_tunnel.p4" 1

// =============================================================================
// =============================================================================
// Taken from l2.p4 ============================================================
// =============================================================================
// =============================================================================

// THIS IS NOW UNUSED!

control npb_egr_sff_vlan_decap(inout switch_header_t hdr, in switch_port_t port) {

 // ----------------------------------------

 action remove_vlan_tag() {
  hdr.ethernet_underlay.ether_type = hdr.vlan_tag_underlay.ether_type;
//		hdr.vlan_tag_underlay.pop_front(1);
 }

 table vlan_decap {
  key = {
   port : ternary;
   hdr.vlan_tag_underlay.isValid() : exact;
  }

  actions = {
   NoAction;
   remove_vlan_tag;
  }

  const default_action = NoAction;
 }

 // ----------------------------------------

 apply {



  // Remove the vlan tag by default.
  if (hdr.vlan_tag_underlay.isValid()) {
   hdr.ethernet_underlay.ether_type = hdr.vlan_tag_underlay.ether_type;
   hdr.vlan_tag_underlay.setInvalid();
  }

 }
}

// =============================================================================
// =============================================================================
// Taken from tunnel.p4 ========================================================
// =============================================================================
// =============================================================================

// THIS IS NOW UNUSED!

control npb_egr_sff_tunnel_decap (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // ----------------------------------------

 action invalidate_tunneling_headers() {
  // Removing tunneling headers by default.
 }

 // ----------------------------------------

 action decap_inner_ethernet_non_ip() {
  hdr.ethernet_underlay.setInvalid();
  invalidate_tunneling_headers();
 }

 table decap_inner_ip {
  key = {
   hdr.ethernet_underlay.isValid() : exact;
  }

  actions = {
   decap_inner_ethernet_non_ip;
  }

  const entries = {
   (true) : decap_inner_ethernet_non_ip();
  }
 }

 // ----------------------------------------

 apply {
  // Copy L3 headers into outer headers.
  decap_inner_ip.apply();
 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_rewrite (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

    EgressBd(
        EGRESS_BD_MAPPING_TABLE_SIZE, EGRESS_BD_STATS_TABLE_SIZE) egress_bd;
    switch_smac_index_t smac_index;

	// =========================================================================
	// Table
	// =========================================================================

    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = false;
        eg_md.tunnel.type = type;
#endif
    }

    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = bd;
    }

    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        eg_md.tunnel.type = type;
        eg_md.tunnel.id = id;
#endif
    }

    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = bd;
        eg_md.tunnel.type = type;
#endif
    }

    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.tunnel.type = type;
#endif
    }

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
        size = NEXTHOP_TABLE_SIZE;
    }

	// =========================================================================
	// Table
	// =========================================================================

    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }

    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        const default_action = NoAction;
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

        // Should not rewrite packets redirected to CPU.
        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
            nexthop_rewrite.apply();
        }

        egress_bd.apply(
			hdr,             // in
			eg_md.bd,        // in
			eg_md.pkt_type,  // in
			eg_md.bd_label,  // out
            smac_index,      // out
			eg_md.checks.mtu // out
		);

        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL && eg_md.flags.routed) {
            smac_rewrite.apply();
        }

	}

}
*/

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_tunnel_rewrite (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	EgressBd(EGRESS_OUTER_BD_MAPPING_TABLE_SIZE,
	         EGRESS_BD_STATS_TABLE_SIZE) egress_bd;
	switch_bd_label_t bd_label;
	switch_smac_index_t smac_index;

	// =========================================================================
	// Table - DA & BD
	// =========================================================================

    // Outer nexthop rewrite
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet_underlay.dst_addr = dmac;
    }

    table nexthop_rewrite {
        key = {
            eg_md.nexthop : exact;
        }

        actions = {
            rewrite_tunnel;
        }
    }

	// =========================================================================
	// Table, SA
	// =========================================================================

    // Tunnel source MAC rewrite
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }
    
    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        size = TUNNEL_SMAC_REWRITE_TABLE_SIZE;
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		nexthop_rewrite.apply(); // sets l2 da, eg_md.bd

		egress_bd.apply(
			hdr,             // in
			eg_md.bd,        // in
			eg_md.pkt_type,  // in
			bd_label,        // out --> currently unused!?!?
			smac_index,      // out
			eg_md.checks.mtu // out
		);

		smac_rewrite.apply(); // sets l2 sa

	}

}
*/

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_tunnel_encap (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Table - Set VNI
	// =========================================================================

    action set_vni(switch_tunnel_id_t id) {
        eg_md.tunnel.id = id;
    }

    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }

        actions = {
            NoAction;
            set_vni;
        }

        size = VNI_MAPPING_TABLE_SIZE;
    }

	// =========================================================================
	// Table - Tunnel Type
	// =========================================================================

	action rewrite_eth_nsh() {

			hdr.ethernet_underlay.setValid();
			hdr.vlan_tag_underlay.setValid();

			hdr.ethernet_underlay.ether_type = ETHERTYPE_NSH;
	}

	// -----------------------------------------------

    table tunnel {
        key = {
            eg_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            rewrite_eth_nsh;
        }

        const default_action = NoAction;
        const entries = {
            SWITCH_TUNNEL_TYPE_MACINMAC_NSH : rewrite_eth_nsh();
        }
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		if(eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE && eg_md.tunnel.id == 0) {
			bd_to_vni_mapping.apply();
		}

		if(eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {

			// Add outer Tunnel headers.
			tunnel.apply();

			npb_egr_sff_tunnel_rewrite.apply(
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			); 

		}

	}

}
*/
# 67 "npb.p4" 2
# 1 "npb_egr_sff_top_part2.p4" 1
# 1 "npb_egr_sf_proxy_top_part2.p4" 1
# 1 "npb_egr_sf_proxy_meter.p4" 1

control npb_egr_sf_proxy_meter (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 bit<8> temp;

 // -----------------------------------------------------------------

 DirectMeter(MeterType_t.BYTES) direct_meter;

 action set_color_direct() {
  // Execute the Direct meter and write the color to the ipv4 header diffserv field
//		hdr.ipv4.diffserv = direct_meter.execute();
  temp = direct_meter.execute();
 }

 table direct_meter_color {
  key = {
//			hdr.ethernet.src_addr : exact;
   eg_md.meter_id : exact;
  }

  actions = {
   set_color_direct;
  }
  meters = direct_meter;
  size = 1024;
 }

 // -----------------------------------------------------------------

 apply {

  // logic here

  direct_meter_color.apply();

  if(temp == 0) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1;
  }

 }

}
# 2 "npb_egr_sf_proxy_top_part2.p4" 2
# 1 "npb_ing_sf_npb_basic_adv_dedup.p4" 1
/* -*- P4_16 -*- */

//#define DEPTH      32w65536
//#define DEPTH_POW2 16




//#define DEPTH      32w262144
//#define DEPTH_POW2 18



// =============================================================================
// =============================================================================
// Example register code, taken from "P4 Language Cheat Sheet"
// =============================================================================
// =============================================================================

struct pair_t {
 bit<16> hash;
 bit<16> data;
};

// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup_reg (
 in switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,

 in bit<17> flowtable_hash_lo,
 in bit<16> flowtable_hash_hi // always 16 bits
) {

 // =========================================================================
 // The Register Array
 // =========================================================================

 Register <pair_t, bit<17>>(32w131072) test_reg; // syntax seems to be <data type, index type>

 // =========================================================================

 RegisterAction<pair_t, bit<17>, bit<8>>(test_reg) register_array = { // syntax seems to be <data type, index type, return type>
  void apply(
   inout pair_t reg_value, // register entry
   out bit<8> return_value // return value
  ) {
   if(reg_value.hash == flowtable_hash_hi) {
    // existing flow
    // --------
    if(reg_value.data == (bit<16>)(eg_md.ingress_port)) {
     // same port
     // --------
     return_value = 0; // pass packet
    } else {
     // different port
     // --------
     return_value = 1; // drop packet
    }
   } else {
    // new flow (entry collision, overwrite old flow)
    // --------
    // update entry
    reg_value.hash = flowtable_hash_hi;
    reg_value.data = (bit<16>)(eg_md.ingress_port);

    return_value = 0; // pass packet
   }
  }
 };

 // =========================================================================
 // The Apply Block
 // =========================================================================

 apply {

  bit<8> return_value;

  // ***** hash the key *****
//		flowtable_hash_lo = flowtable_hash[15: 0];
//		flowtable_hash_hi = flowtable_hash[31:16];

  // ***** use hashed key to index register *****
  return_value = register_array.execute(flowtable_hash_lo);

  // ***** drop packet? *****
  if(return_value != 0) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
  }

 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup (
 in switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
 npb_ing_sf_npb_basic_adv_dedup_reg() npb_ing_sf_npb_basic_adv_dedup_reg_0;

 bit<32> flowtable_hash;

 bit<17> flowtable_hash_lo;
 bit<16> flowtable_hash_hi; // always 16 bits

 // =========================================================================
 // The Hash Function
 // =========================================================================




 Hash<bit<17>>(HashAlgorithm_t.CRC32) h_lo;
 Hash<bit<16 >>(HashAlgorithm_t.CRC16) h_hi; // always 16 bits


 // =========================================================================
 // The Apply Block
 // =========================================================================

 apply {
  // ***** hash the key *****





  flowtable_hash_lo = h_lo.get({eg_md.lkp.ip_src_addr, eg_md.lkp.ip_dst_addr, eg_md.lkp.ip_proto, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port});
  flowtable_hash_hi = h_hi.get({eg_md.lkp.ip_src_addr, eg_md.lkp.ip_dst_addr, eg_md.lkp.ip_proto, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port});


  // note: the register code has been structured such that multiple
  // registers can be laid down, perhaps using the upper bits of the hash
  // to select between them....

  // ***** call dedup function *****
  npb_ing_sf_npb_basic_adv_dedup_reg_0.apply (
   hdr,
   eg_md,
   eg_intr_md,
   eg_intr_md_from_prsr,
   eg_intr_md_for_dprsr,
   eg_intr_md_for_oport,

   flowtable_hash_lo,
   flowtable_hash_hi
  );

 }
}
# 3 "npb_egr_sf_proxy_top_part2.p4" 2

control npb_egr_sf_proxy_top_part2 (

 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: unused (was header strip)
 //   [1:1] act #2: unused (was header edit)
 //   [2:2] act #3: unused (reserved for truncate)
 //   [3:3] act #4: meter
 //   [4:4] act #5: deduplication

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // ----------------------------------
  // Action Lookup
  // ----------------------------------

  // ----------------------------------
  // Actions(s)
  // ----------------------------------

  if(eg_md.action_bitmask[3:3] == 1) {

   // ----------------------------------
   // Action #3 - Meter
   // ----------------------------------
# 55 "npb_egr_sf_proxy_top_part2.p4"
  }

  if(eg_md.action_bitmask[4:4] == 1) {

   // ----------------------------------
   // Action #4 - Deduplication
   // ----------------------------------
# 72 "npb_egr_sf_proxy_top_part2.p4"
  }

 }

}
# 2 "npb_egr_sff_top_part2.p4" 2

control npb_egr_sff_top_part2 (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

    // Note: local bitmask defined as follows....
    //
    //   [0:0] sf  #1: ingress basic/advanced
    //   [1:1] sf  #2: unused (was multicast)
    //   [2:2] sf  #3: egress proxy 

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // ---------------------------------------------------------------------
  // Do some work
  // ---------------------------------------------------------------------

  if(eg_md.nsh_extr.valid == 1) {

   // -------------------------------------
   // SF(s)
   // -------------------------------------

   if(eg_md.nsh_extr.extr_srvc_func_bitmask_local[2:2] == 1) {

    // -------------------------------------
    // SF #0
    // -------------------------------------

    npb_egr_sf_proxy_top_part2.apply (
     hdr,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

    // DON"T NEED TO DO THIS.  THE PROXY DELETES THE NSH HEADER SO THERES NO POINT IN CHECKING.
    // check sp index
//				if(eg_md.nsh_extr_underlay.si == 0) {
//					eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//				}

   }

  }

 }

}
# 68 "npb.p4" 2





// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

@pa_auto_init_metadata
control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {


 // ---------------------------------------------------------------------

    IngressPortMapping(PORT_VLAN_TABLE_SIZE,
                       BD_TABLE_SIZE,
                       DOUBLE_TAG_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    IngressSTP() stp;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressTunnel(IPV4_SRC_TUNNEL_TABLE_SIZE) tunnel;
    IngressBd(BD_TABLE_SIZE) bd_stats;
    IngressMulticast(IPV4_MULTICAST_S_G_TABLE_SIZE,
                     IPV4_MULTICAST_STAR_G_TABLE_SIZE,
                     IPV6_MULTICAST_S_G_TABLE_SIZE,
                     IPV6_MULTICAST_STAR_G_TABLE_SIZE) multicast;
    IngressUnicast(dmac,
                   IPV4_HOST_TABLE_SIZE,
                   IPV4_LPM_TABLE_SIZE,
                   IPV6_HOST_TABLE_SIZE,
                   IPV6_LPM_TABLE_SIZE) unicast;
    IngressAcl(INGRESS_IPV4_ACL_TABLE_SIZE,
               INGRESS_IPV6_ACL_TABLE_SIZE,
               INGRESS_MAC_ACL_TABLE_SIZE,
               true /* mac_acl */) acl;
    MirrorAcl(stats_enable=true) mirror_acl;
    RouterAcl(IPV4_RACL_TABLE_SIZE, IPV6_RACL_TABLE_SIZE, true) racl;

    IngressDtel() dtel;
    IngressQoS() qos;
    StormControl(STORM_CONTROL_TABLE_SIZE) storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterNexthop(
        OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) outer_nexthop;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;

 // ---------------------------------------------------------------------

// meta_t meta;

    apply {

        // -----------------------------------------------------
  // Extreme Networks - Added
        // -----------------------------------------------------

        // derek: just set the tx-port to the rx-port, for debug!


        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;


/*
        Ctrl.apply(
            hdr,
            meta
        );
*/

        // -----------------------------------------------------
  // Extreme Networks - Added
        // -----------------------------------------------------

        // cmace: header stack id experiment





        // -----------------------------------------------------


        pkt_validation.apply(hdr, ig_md.flags, ig_md.lkp, ig_intr_md_for_tm, ig_md.drop_reason);

        // =====================================
        // Make a copy for npb
        // =====================================

        ig_md.lkp_nsh = ig_md.lkp; // extreme added
  ig_md.tunnel_nsh = ig_md.tunnel; // extreme added

        // =====================================

        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
//      stp.apply(ig_md, ig_md.stp);

        tunnel.apply(hdr, ig_md, ig_md.lkp, ig_md.lkp_nsh);
//      smac.apply(ig_md.lkp.mac_src_addr, ig_md, ig_intr_md_for_dprsr.digest_type);
//      bd_stats.apply(ig_md.bd, ig_md.lkp.pkt_type);
//      acl.apply(ig_md.lkp, ig_md);
        mirror_acl.apply(ig_md.lkp, ig_md);

        // =====================================
        // Paths Fork
        // =====================================

        // =====================================
        // Path A: NSH Processing
        // =====================================

        // -------------------------------------
        // SFC
        // -------------------------------------

        npb_ing_sfc_top.apply (
            hdr,
            ig_md,
            ig_intr_md,
            ig_intr_from_prsr,
            ig_intr_md_for_dprsr,
            ig_intr_md_for_tm
        );

        // -------------------------------------
        // SFF and SF(s)
        // -------------------------------------

        npb_ing_sff_top.apply (
            hdr,
            ig_md,
            ig_intr_md,
            ig_intr_from_prsr,
            ig_intr_md_for_dprsr,
            ig_intr_md_for_tm
        );

        // =====================================
        // Path B: Switch Processing
        // =====================================
# 233 "npb.p4"
        // =====================================
        // Paths Join
        // =====================================

        // Give higher priority to nsh forwarding than switch forwarding....







        ig_md.lkp = ig_md.lkp_nsh;

        // nsh tunnel settings become switch tunnel settings (see tunnel.p4), as follows....

  // --> from tunnel.p4, "action src_vtep_hit";
        ig_md.tunnel.ifindex = ig_md.tunnel_nsh.ifindex;

  // --> from tunnel.p4, "action set_vni_properties":
        ig_md.bd = ig_md.bd_nsh;
        ig_md.bd_label = ig_md.bd_label_nsh;
        ig_md.vrf = ig_md.vrf_nsh;
        // ig_intr_md_for_tm.rid         = ig_intr_md_for_tm.rid;
  // ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        ig_md.rmac_group = ig_md.rmac_group_nsh;
        ig_md.multicast.rpf_group = ig_md.multicast_nsh.rpf_group;
        ig_md.learning.bd_mode = ig_md.learning_nsh.bd_mode;
        ig_md.ipv4.unicast_enable = ig_md.ipv4_nsh.unicast_enable;
        ig_md.ipv4.multicast_enable = ig_md.ipv4_nsh.multicast_enable;
        ig_md.ipv4.multicast_snooping = ig_md.ipv4_nsh.multicast_snooping;
        ig_md.ipv6.unicast_enable = ig_md.ipv6_nsh.unicast_enable;
        ig_md.ipv6.multicast_enable = ig_md.ipv6_nsh.multicast_enable;
        ig_md.ipv6.multicast_snooping = ig_md.ipv6_nsh.multicast_snooping;
        ig_md.tunnel.terminate = ig_md.tunnel_nsh.terminate;







        // =====================================

        racl.apply(ig_md.lkp, ig_md);
        if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE)
            compute_non_ip_hash(ig_md.lkp, ig_md.hash);
        else
            compute_ip_hash(ig_md.lkp, ig_md.hash);

        nexthop.apply(ig_md.lkp, ig_md, ig_md.hash[15:0]);
        qos.apply(hdr, ig_md.lkp, ig_md);
        storm_control.apply(ig_md, ig_md.lkp.pkt_type, ig_md.flags.storm_control_drop);
        outer_nexthop.apply(ig_md, ig_md.hash[31:16]);

        if (ig_md.egress_ifindex == SWITCH_IFINDEX_FLOOD) {
//          flood.apply(ig_md);
        } else {
            lag.apply(ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
        }

//      system_acl.apply(ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
        dtel.apply(hdr, ig_md.lkp, ig_md, ig_md.hash[15:0], ig_intr_md_for_dprsr, ig_intr_md_for_tm);

        // Only add bridged metadata if we are NOT bypassing egress pipeline.
        if (ig_intr_md_for_tm.bypass_egress == 0) {
            add_bridged_md(hdr.bridged_md, ig_md);
        }

        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
# 314 "npb.p4"
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
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

 // -------------------------------------------------------------------------

    EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
    EgressSTP() stp;
    EgressAcl() acl;
    EgressQoS(EGRESS_QOS_MAP_TABLE_SIZE) qos;
    EgressSystemAcl() system_acl;
    Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
    EgressDtel() dtel;
    MirrorRewrite() mirror_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
    VlanDecap() vlan_decap;
    TunnelDecap(switch_tunnel_mode_t.PIPE) tunnel_decap;
    TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
    TunnelRewrite() tunnel_rewrite;

    MTU() mtu;
    WRED() wred;
    MulticastReplication(RID_TABLE_SIZE) multicast_replication;

 // -------------------------------------------------------------------------

    apply {



        eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
        egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
        mirror_rewrite.apply(hdr, eg_md);
        multicast_replication.apply(eg_intr_md.egress_rid, eg_intr_md.egress_port, eg_md);

        // -------------------------------------
        // SFF and SF(s): Part 1
        // -------------------------------------

        npb_egr_sff_top_part1.apply (
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        // -------------------------------------

        stp.apply(eg_md, eg_intr_md.egress_port, eg_md.checks.stp);
        vlan_decap.apply(hdr, eg_md);
        tunnel_decap.apply(hdr, eg_md);

        // -------------------------------------
        // Delete NSH Header
        // -------------------------------------

/*
        // not needed if decap being done in ingress parser
        npb_egr_sff_vlan_decap.apply(hdr, eg_md.ingress_port);

        if(eg_md.nsh_extr.end_of_chain == 1) {
            npb_egr_sff_tunnel_decap.apply(
                hdr,
                eg_md,
                eg_intr_md,
                eg_intr_md_from_prsr,
                eg_intr_md_for_dprsr,
                eg_intr_md_for_oport
            );
        };
*/

        // -------------------------------------

        qos.apply(hdr, eg_intr_md.egress_port, eg_md);
        wred.apply(hdr, eg_md, eg_intr_md, eg_md.flags.wred_drop);

        // -------------------------------------
        // SFF and SF(s): Part 2
        // -------------------------------------

        npb_egr_sff_top_part2.apply (
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        // -------------------------------------

        rewrite.apply(hdr, eg_md);

        // -------------------------------------
        // Rewrite NSH Header
        // -------------------------------------

/*
        // not needed if decap being done in ingress parser
        npb_egr_sff_rewrite.apply(
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
*/

        // -------------------------------------

//      acl.apply(hdr, eg_md.lkp, eg_md);
        tunnel_encap.apply(hdr, eg_md);
        tunnel_rewrite.apply(hdr, eg_md);

        // -------------------------------------
        // Insert NSH Header
        // -------------------------------------

/*
        // not needed if decap being done in ingress parser
        npb_egr_sff_tunnel_encap.apply(
            hdr,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
*/

        // -------------------------------------

        mtu.apply(hdr, eg_md, eg_md.checks.mtu);
        vlan_xlate.apply(hdr, eg_md);

        dtel.apply(hdr, eg_md, eg_intr_md, eg_md.dtel.hash, eg_intr_md_for_dprsr);
//      system_acl.apply(hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);

        set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);


    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

Pipeline(
//		SwitchIngressParser(), // extreme modified
  NpbIngressParser(), // extreme added
        SwitchIngress(),
        SwitchIngressDeparser(),
//      SwitchEgressParser(), // extreme modified
  NpbEgressParser(), // extreme added
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
