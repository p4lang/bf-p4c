# 1 "upf/p4src/pipe1/upf_1.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "upf/p4src/pipe1/upf_1.p4"
/*******************************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/

#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

// Test program exceeds Tof1 egress parse depth
@command_line("--disable-parse-max-depth-limit")


# 15 "upf/p4src/pipe1/upf_1.p4" 2


# 1 "upf/include/hw_defs/hw_defs.h" 1
/****************************************************************
 * Copyright (c) Kaloom, 2020
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ***************************************************************/

/* This file defines the size of the P4 tables. It is shared by the P4 code
 * and the C++ host code.
 */




/* UPLINK */






/* DOWNLINK */
# 18 "upf/p4src/pipe1/upf_1.p4" 2
# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/*
 * Default constants and table sizes
 */
const PortId_t DEFAULT_CPU_PORT = 320;
const bit<8> DEFAULT_PUNT_TYPE = 0;

typedef bit<3> ring_id_t;
const ring_id_t KC_RINGID = 0x7;
const ring_id_t POLICY_RINGID = 0x6;
const ring_id_t GTP_RINGID = 0x5;
const ring_id_t DEFAULT_RINGID_SPAN = 0x4;

typedef bit<32> table_size_t;





/*
 *  Ether types
 */
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_DP_CTRL = 16w0x99ff; // Used for to/from CPU packets for now

/*
 *  Header minimum size
 */
typedef bit<16> size_t;
const size_t ETH_MIN_SIZE = 0x0E;
const size_t IPV4_MIN_SIZE = 0x14;
const size_t IPV6_MIN_SIZE = 0x28;
const size_t UDP_SIZE = 0x08;
const size_t GTP_MIN_SIZE = 0x08;
const size_t VLAN_SIZE = 0x04;

/*
 *  Port number definitions
 */
typedef bit<16> port_t;
const port_t PORT_GTP_U = 2152;

/*
 *  IP Protocol definitions
 */
typedef bit<8> ip_protocol_t;
const ip_protocol_t PROTO_ICMP = 1;
const ip_protocol_t PROTO_UDP = 17;
const ip_protocol_t PROTO_TCP = 6;
const ip_protocol_t PROTO_IPV6 = 41;
const ip_protocol_t PROTO_ICMPV6 = 58;

/*
 * GTP definitions
 */
typedef bit<8> gtp_ie_type_t;
const gtp_ie_type_t GTP_IE_TYPE_RECOVERY = 14;

/*
 *  Type definitions
 */
typedef bit<16> knid_t;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<8> protocol_t;

/*
 * Single index indirect counters
 */
typedef bit<1> single_indirect_counter_t;
const single_indirect_counter_t SINGLE_INDIRECT_COUNTER = 1;

/*
 * Action index indirect counters
 */
typedef bit<16> dl_flow_id_indirect_counter_t;
const dl_flow_id_indirect_counter_t DL_FLOW_ID_INDIRECT_COUNTER = 16;
typedef bit<16> ul_flow_id_indirect_counter_t;
const ul_flow_id_indirect_counter_t UL_FLOW_ID_INDIRECT_COUNTER = 16;
typedef bit<16> port_stats_indirect_counter_t;
const ul_flow_id_indirect_counter_t UL_PORT_STATS_INDIRECT_COUNTER = 16;

/*
 *  Padding for extended IPV4
 */
typedef bit<32> padding_32b_t;
const padding_32b_t ZEROS_PADDING_4B = 32w0x00000000;
const padding_32b_t ONES_PADDING_4B = 32w0xFFFFFFFF;
const padding_32b_t MIXED_PADDING_4B = 32w0x0000FFFF;

/*
* Padding for IPV6
*/
typedef bit<64> padding_64b_t;
const padding_64b_t ZEROS_PADDING_8B = 64w0x0000000000000000;
const padding_64b_t ONES_PADDING_8B = 64w0xFFFFFFFFFFFFFFFF;
const padding_64b_t MIXED_PADDING_8B = 64w0x00000000FFFFFFFF;
const padding_64b_t MIXED_SINGLE_FFFF_PADDING_8B = 64w0x000000000000FFFF;

typedef bit<96> padding_96b_t;
const padding_96b_t MIXED_PADDING_12B = 96w0x00000000000000000000FFFF;


/*
 *  Mirroring
 */
typedef MirrorId_t mirror_id_t; // Defined in tna.p4
typedef bit<3> mirror_type_t;

/*
 *  Source of the packet received
 */
typedef bit<3> pkt_src_t;
const pkt_src_t PKT_SRC_BRIDGE = 0;
const pkt_src_t PKT_SRC_CLONE_INGRESS = 1;
const pkt_src_t PKT_SRC_CLONE_EGRESS = 2;

typedef bit<9> port_comp_t;
const port_comp_t PORT_BIT_OR = 0x80;
# 14 "common/p4lib/core/headers/headers.p4" 2

/*************************************************************************
********************************** L2  ***********************************
*************************************************************************/

header ethernet_t {
    mac_addr_t dstAddr;
    mac_addr_t srcAddr;
    bit<16> etherType;
}

header vlan_t {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vlanId;
    bit<16> etherType;
}

// Address Resolution Protocol
header arp_t {
    bit<16> hwType;
    bit<16> protoType;
    bit<8> hwAddrLen;
    bit<8> protoAddrLen;
    bit<16> opcode;
}

/*************************************************************************
********************************** L3  ***********************************
*************************************************************************/

header ipv4_t { //Enhanced IP
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    protocol_t protocol;
    bit<16> hdrChecksum;
    ipv4_addr_t srcAddr;
    ipv4_addr_t dstAddr;
}

header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    protocol_t nextHdr;
    bit<8> hopLimit;
    ipv6_addr_t srcAddr;
    ipv6_addr_t dstAddr;
}

header icmp_t {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    //bit<32>    restOfHeader;
}


/*************************************************************************
********************************** L4  ***********************************
*************************************************************************/
@pa_no_overlay("egress", "hdr.outer_udp.checksum")
@pa_no_overlay("ingress", "hdr.outer_udp.checksum")
header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdrLen;
    bit<16> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seq;
    bit<32> ack;
    bit<4> dataOffset;
    bit<3> res;
    bit<9> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

/*************************************************************************
******************************* Tunneling  *******************************
*************************************************************************/

header gtp_u_t {
    bit<3> version;
    bit<1> pt;
    bit<1> spare;
    bit<1> extFlag;
    bit<1> seqFlag;
    bit<1> pn;
    bit<8> msgType;
    bit<16> totalLen;
    bit<32> teid;
}

header gtp_u_options_t {
    bit<16> seqNumb;
    bit<8> npdu;
    bit<8> neh;
}

header gtp_u_ext_header_len_t {
    bit<8> len;
}

/*
 * PDU session container (GTP header extension). More details in 3GPP
 * spec. 38415 and 29281.
 * Type 0 for downlink (8 bytes)
 * Type 1 for uplink (4 bytes)
 * neh value: 0x85
 * Length of this header should be 4n, thus the padding.
 */
header gtp_u_pdu_sess_cont_dl_t {
    bit<4> type;
    bit<4> spare0;
    bit<1> ppp;
    bit<1> rqi;
    bit<6> qfi;
    bit<3> ppi;
    bit<5> spare1;
    bit<24> pad0;

    bit<8> neh;
}

header gtp_u_pdu_sess_cont_ul_t {
    bit<4> type;
    bit<4> spare0;
    bit<1> ppp;
    bit<1> rqi;
    bit<6> qfi;

    bit<8> neh;
}

/* The GTP Recovery information element */
header gtp_u_recovery_ie_t {
    gtp_ie_type_t type;
    bit<8> restart_counter;
}

/*************************************************************************
*************************  DP Control Header  ****************************
*************************************************************************/

/* Metadata for packets that are forwarded to/from CPU */
header dp_ctrl_header_t {
    bit<5> _pad0; /* This padding is needed because the ring identifier corresponds
                    * to the 3 lower bits in the first byte of the packet
                    */
    ring_id_t ring_id; /* Ring Identifier */
    bit<72> _pad1; /* 9 Bytes of padding needed to match a regular Ethernet Header size */
    bit<16> port; /* input/output port */
    bit<16> etherType; /* Ethertype of ETHERTYPE_DP_CTRL */
}

/*************************************************************************
******************** Ingress/Egress bridge Header  ***********************
*************************************************************************/

header upf_bridged_metadata_t {
// user-defined metadata carried over from ingress to egress. 128 bits.
    bit<8> session_miss; // Counter of session tables missed
                                    // Could be 3 bits, but for alignement
                                    // purposes we allocate 8 bits
    knid_t ingress_iid; // IID on which the packet arrived
    knid_t iid; // IID where the packet is forwarded
    bit<1> _pad0;
    bit<1> flow_sess_lookup;
    bit<1> policy_table; // Record if policy table has been hit
    bit<1> flow_table; // Record if flow table has been hit
    bit<1> drop; // If packet must be dropped
    bit<2> punt_type; // Used to know what kind of punt it is
                                    // Punt type:
                                    // 00: other (0x0)
                                    // 01: kc_punt (0x01)
                                    // 10: policy_punt (0x2)
                                    // 11: gtp_punt (0x3)
    bit<1> punt; // Used to know if packet must be punted
    bit<7> _pad1;
    PortId_t ucast_egress_port; // Used to transport egress port
    bit<7> _pad2;
    PortId_t ingress_port; // Store ingress prot number for counters
    bit<4> _pad3;
    bit<20> flowId; // Store flowId for action table and counters
// add more fields here.
}

/* For dependency that rely on this size, in bytes and hexadecimal */


/*************************************************************************
************************* Headers declaration ****************************
*************************************************************************/

struct headers {
    upf_bridged_metadata_t bridged_md;
    dp_ctrl_header_t dp_ctrl;
    ethernet_t ethernet;
    vlan_t vlan;
    arp_t arp;
    ipv4_t outer_ipv4;
    ipv6_t outer_ipv6;
    icmp_t icmp;
    udp_t outer_udp;
    tcp_t outer_tcp;
    gtp_u_t gtp_u;
    gtp_u_options_t gtp_u_options;
    gtp_u_ext_header_len_t gtp_u_ext_header_len;
    gtp_u_pdu_sess_cont_ul_t gtp_u_pdu_sess_cont_ul;
    gtp_u_pdu_sess_cont_dl_t gtp_u_pdu_sess_cont_dl;
    gtp_u_recovery_ie_t gtp_u_recovery_ie;
    ipv4_t inner_ipv4;
    ipv6_t inner_ipv6;
    udp_t inner_udp;
    tcp_t inner_tcp;
}
# 19 "upf/p4src/pipe1/upf_1.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 20 "upf/p4src/pipe1/upf_1.p4" 2

# 1 "upf/p4src/pipe1/UPFIngress3_1.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2019
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/pipe1/UPFIngress3_1.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "upf/p4src/pipe1/UPFIngress3_1.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/metadata.p4" 2

header upf_port_metatdata_t {
    bit<7> _pad ;
    bit<9> port_lag_index;
    bit<16> port_lag_label;
    bit<1> port_type;
    bit<31> _pad1;
}

struct local_metadata_t {
    bit<1> policy_hit;
    bit<64> dstPrefix;
}

//=============================================================================
// Egress metadata
//=============================================================================

enum bit<2> GtpAction {
    forward = 0,
    decap = 1,
    encap = 2
}

struct upf_egress_metadata_t {
    bit<16> pkt_length; // Used to store pkt_length out of the TM
    bit<32> srcAddrv4; // Src IPv4 of egress port, given in egress port table
    bit<128> srcAddrv6; // Src IPv6 of egress port, given in egress port table
    bit<128> dstAddrv6; // Used to store original dst addr for session lookup
    protocol_t nextHdrv6; // Use to store next header for policy lookup
    ipv6_addr_t dstAddr; // Dst IP (v4 or v6) given in action id table
    bit<32> teid; // Used to store TEID given by action id table
    bit<1> protoEncap; // Given by action id table, to select encap
                                   // 0: ipv4 1: ipv6
    bit<1> n9; // Given by action id table in uplink and set
                                   // in apply block in downlink. Used for encap
                                   // purposes.
    GtpAction gtpAction; // Work to be performed by GTP
    bit<1> inner_dst_rewrite; // Used by action rewritre_inner_dst
                                   // in case of inner packet matching
                                   // in uplink.
    bit<20> flowId; // Store flow ID for counters
    ipv6_addr_t innerSrcAddrv6; // Used for inner packet matching
    ipv6_addr_t innerDstAddrv6; // Used for inner packet matching
    protocol_t innerNextHdrv6; // Used for inner packet matching
}


//=============================================================================
// Ingres metadata
//=============================================================================
struct upf_ingress_metadata_t {
    bit<1> drop; // Used to know if packet must be dropped
    bit<9> cpu_port; // Used to store CPU port
    ring_id_t ring_span; // Punt ring mechanism
    ring_id_t kc_ring_id; // Punt ring mechanism
    ring_id_t policy_ring_id; // Punt ring mechanism
    ring_id_t gtp_ring_id; // Punt ring mechanism
    bit<2> color; // Punt ring mechanism, for meters
    bit<1> activate_meters; // Punt ring mechanism, for meters
    bit<1> gtp_echo; // For GTP echo messages
    mac_addr_t srcMac; // For GTP echo messages
    mac_addr_t dstMac; // For GTP echo messages
    ipv6_addr_t srcAddrv6; // Used for GTP echo messages, and for
                                    // flow table and policy lookup. Store
                                    // original ipv6 src addr.
    ipv6_addr_t dstAddrv6; // Used to store original dst addr for
                                    // session, policy and flow lookup
    protocol_t nextHdrv6; // Use to store next header for policy
                                    // and flow lookup
    bit<32> srcAddr; // Used to store original src IPv4 for GTP
                                    // echo messages
    bit<32> dstAddr; // Used to store original dst IPv4 for GTP
                                    // echo messages

    ipv6_addr_t innerSrcAddrv6; // Used for inner packet matching
    ipv6_addr_t innerDstAddrv6; // Used for inner packet matching
    protocol_t innerNextHdrv6; // Used for inner packet matching
}
# 17 "upf/p4src/pipe1/UPFIngress3_1.p4" 2
# 1 "upf/p4src/common/session_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/





# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "upf/p4src/common/session_table.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "upf/p4src/common/session_table.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 18 "upf/p4src/common/session_table.p4" 2
//=============================================================================
// Session port table
//=============================================================================
control SessionTableDownlink(inout headers hdr, in bit<128> dstAddrv6)(table_size_t table_size) {

    /* Tables counters */
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) session_cntr;

    action punt() {
        hdr.bridged_md.session_miss = hdr.bridged_md.session_miss + 2;
    }

    action session_fwd_encap(knid_t iid, bit<20> flowId) {
        session_cntr.count();
        hdr.bridged_md.iid = iid;
        hdr.bridged_md.flowId = flowId;
    }

    @pragma user_annotation "linked_table:session_table_downlink"
    table session_table {
        key = {
            hdr.bridged_md.ingress_iid : exact;
            dstAddrv6 : exact;
            /* Keep teid for downlink in the case of N9/N9 fowarding */
            hdr.gtp_u.teid : exact;
        }
        actions = {
            session_fwd_encap;
            @defaultonly punt;
        }
        size = table_size;
        default_action = punt;
        counters = session_cntr;
    }

    apply {
        session_table.apply();
    }
}

control SessionTableUplink(inout headers hdr, in bit<128> addrv6)(table_size_t table_size) {

    /* Tables counters */
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) session_cntr;

    action punt() {
        hdr.bridged_md.session_miss = hdr.bridged_md.session_miss + 2;
    }

    action fwd_decap(knid_t iid, bit<20> flowId) {
        session_cntr.count();
        hdr.bridged_md.iid = iid;
        hdr.bridged_md.flowId = flowId;
    }

    action session_fwd_N9(knid_t iid, bit<20> flowId) {
        session_cntr.count();
        hdr.bridged_md.iid = iid;
        hdr.bridged_md.flowId = flowId;
    }

    action flow_check_and_forward() {
        session_cntr.count();
    }

    @pragma user_annotation "linked_table:session_table_uplink"
    table session_table {
        key = {
            hdr.bridged_md.ingress_iid : exact;
            addrv6 : exact;
            /* Keep teid for downlink in the case of N9/N9 fowarding */
            hdr.gtp_u.teid : exact;
        }
        actions = {
            fwd_decap;
            session_fwd_N9;
            flow_check_and_forward;
            @defaultonly punt;
        }
        size = table_size;
        default_action = punt;
        counters = session_cntr;
    }

    apply {
        session_table.apply();
    }
}
# 18 "upf/p4src/pipe1/UPFIngress3_1.p4" 2
# 1 "upf/p4src/common/punt.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/punt.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "upf/p4src/common/punt.p4" 2
# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "upf/p4src/common/punt.p4" 2
//=============================================================================
// Send to CPU / Punting mechanism
//=============================================================================
// This code includes the send to cpu function + punt channels definition.
// By default RR ring span: 0-4
// Dedicated channels 5: GTP  6:Policy  7:KC

control Punt(inout headers hdr,
    inout upf_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    /* CPU counters */
    Counter<bit<32>,single_indirect_counter_t>(64, CounterType_t.PACKETS_AND_BYTES) send_to_cpu_cntr;

    /*
    * Meters fo rate limiting
    * Defined in RFC 2698 (https://tools.ietf.org/html/rfc2698)
    */
    DirectMeter(MeterType_t.BYTES) direct_meter_rate_limit;

    action drop_pkt() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action accept_pkt() {
    }

    action activate_meters(bit<1> value){
        ig_md.activate_meters = value;
    }

    table activate_meters_table{
        actions = {
            activate_meters;
        }
        size = 1;
        default_action = activate_meters(0);
    }

    table rate_limit_table {
        key = {
            ig_md.color : exact;
            ig_md.activate_meters : exact;
        }
        actions = {
            drop_pkt;
            accept_pkt;
        }
        const entries = {
            (0x0, 0x0) : accept_pkt(); // Green accept
            (0x1, 0x0) : accept_pkt(); // Yellow accept
            (0x3, 0x0) : accept_pkt(); // Red accept

            // TODO(fabien): repair this
            (0x3, 0x1) : drop_pkt(); // Red drop
        }
        const default_action = accept_pkt;
        size = 4; // 2^2
    }

    /* ring_id register
    * Round-Robin
    */
    Register<bit<8>, bit<1>> (1) ring_id_reg;
    RegisterAction< bit<8>, bit<1>, bit<8>>(ring_id_reg) ring_id_reg_action = {
        void apply(inout bit<8> value, out bit<8> read_value){
            if(value < (bit<8>) ig_md.ring_span){
                read_value = 0;
                value = value + 1;
            } else {
                value = 0;
            }
            read_value = value;
        }
    };


    /*
    * Control header and actions for send_to_cpu and drop.
    */
    action set_cpu_port(PortId_t cpu_port) {
        ig_md.cpu_port = cpu_port;
    }

    table read_cpu_port_table {
        actions = {
            set_cpu_port;
        }
        default_action = set_cpu_port(DEFAULT_CPU_PORT);
        size = 1;
    }

    /*
    * Control header and actions for set_ring_id.
    */
    action set_ring_id_span(ring_id_t ring_span) {
        ig_md.ring_span = ring_span;
    }

    table read_ring_span_table {
        actions = {
            set_ring_id_span;
        }
        default_action = set_ring_id_span(DEFAULT_RINGID_SPAN);
        size = 1;
    }

    action add_dp_header() {
        hdr.dp_ctrl.setValid();
        hdr.dp_ctrl.port = (bit<16>)hdr.bridged_md.ingress_port;
        hdr.dp_ctrl.etherType = ETHERTYPE_DP_CTRL;
    }

    action add_ring_id() {
        hdr.dp_ctrl.ring_id = (bit<3>)ring_id_reg_action.execute(0);
    }

    action send_to_cpu(){
        /*
        * TODO: Configure metadata/header fields when sending packets to CPU
        */
        add_dp_header();
        ig_intr_md_for_tm.ucast_egress_port = ig_md.cpu_port;
        send_to_cpu_cntr.count(SINGLE_INDIRECT_COUNTER);
        ig_intr_md_for_tm.bypass_egress = 1;
    }

    action set_kc_ring(ring_id_t ring_id) {
        ig_md.kc_ring_id = ring_id;
    }
    action set_policy_ring(ring_id_t ring_id) {
        ig_md.policy_ring_id = ring_id;
    }
    action set_gtp_ring(ring_id_t ring_id) {
        ig_md.gtp_ring_id = ring_id;
    }


    /*
    * Tables for punting to CPU.
    * Include Revervation of dedicated channels
    */

    //If Kubernetes Vlan hit, punt to cpu with dedicated ring ID.
    table kc_ring_table{
        actions = {
            set_kc_ring;
        }
        size = 1;
        default_action = set_kc_ring(KC_RINGID);
    }

    table policy_ring_table{
        actions = {
            set_policy_ring;
        }
        size = 1;
        default_action = set_policy_ring(POLICY_RINGID);
    }

    table gtp_ring_table{
        actions = {
            set_gtp_ring;
        }
        size = 1;
        default_action = set_gtp_ring(GTP_RINGID);
    }

    /*
    * Set the hdr.dp_ctrl.ring_id
    */
    action set_color() {
        ig_md.color = (bit<2>) direct_meter_rate_limit.execute();
    }
    action set_kc_punt(){
        hdr.dp_ctrl.ring_id = ig_md.kc_ring_id;
        set_color();
    }
    action set_policy_punt(){
        hdr.dp_ctrl.ring_id = ig_md.policy_ring_id;
        set_color();
    }
    action set_gtp_punt(){
        hdr.dp_ctrl.ring_id = ig_md.gtp_ring_id;
        set_color();
    }
    action set_default_punt(){
        set_color();
    }

    // This table needs to be initialized at runtime
    table punt_meter_table{
        key = {
            hdr.bridged_md.punt_type: exact;
        }
        actions = {
            set_kc_punt;
            set_policy_punt;
            set_gtp_punt;
            set_default_punt;
        }
        default_action = set_default_punt();
        // TODO(fabien): repair
        meters = direct_meter_rate_limit;
        size = 4; // 2^2
    }

    apply {
        read_cpu_port_table.apply();
        /* Reserve rings for punt channels */
        kc_ring_table.apply();
        policy_ring_table.apply();
        gtp_ring_table.apply();

        /* Read configurable ringid round-robin span */
        read_ring_span_table.apply();

        punt_meter_table.apply();

        if (hdr.bridged_md.punt_type == 0x0) {
            add_ring_id();
        }

        activate_meters_table.apply();
        rate_limit_table.apply();
        send_to_cpu();
    }
}
# 19 "upf/p4src/pipe1/UPFIngress3_1.p4" 2
# 1 "upf/p4src/common/lag.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/common/lag.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "upf/p4src/common/lag.p4" 2
# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "upf/p4src/common/lag.p4" 2


//=============================================================================
//  Link Aggregation
//=============================================================================
// This code includes the LAGs and the scheduling algorthim for the groups.
// By default a CRC32 will be used to cycles the ports per groups.

control LAGUplink(inout headers hdr,
            inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Hash<bit<7>>(HashAlgorithm_t.CRC32) crc32;
    ActionSelector(256, crc32, SelectorMode_t.FAIR) lag_port_selector;

    action set_egress_port(PortId_t port){
        hdr.bridged_md.ucast_egress_port = port;
    }

    // Lag miss drop the packet
    action lag_miss(){
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    //Lag group tables, to assign a Group to a
    table lag_table{
        key = {
            hdr.bridged_md.iid : exact;
            hdr.inner_tcp.srcPort : selector;
            hdr.inner_ipv6.srcAddr : selector;
        }
        actions = {
            set_egress_port;
            lag_miss;
        }
        size = 128;
        const default_action = lag_miss;
        implementation = lag_port_selector;
    }

    action single_port_table_miss() {}

    table single_port_table {
        key = {
            hdr.bridged_md.iid : exact;
        }
        actions = {
            set_egress_port;
            single_port_table_miss;
        }
        size = 256;
        const default_action = single_port_table_miss();
    }

    apply {
        switch(single_port_table.apply().action_run) {
            single_port_table_miss : {
                // Apply LAG Port selector. Take group to specific port
                lag_table.apply();
            }
        }
    }
}

control LAGDownlink(inout headers hdr,
            inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    Hash<bit<7>>(HashAlgorithm_t.CRC32) crc32;
    ActionSelector(256, crc32, SelectorMode_t.FAIR) lag_port_selector;

    action set_egress_port(PortId_t port){
        hdr.bridged_md.ucast_egress_port = port;
    }

    // Lag miss drop the packet
    action lag_miss(){
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    //Lag group tables, to assign a Group to a
    table lag_table{
        key = {
            hdr.bridged_md.iid : exact;
            hdr.outer_tcp.dstPort : selector;
            hdr.outer_ipv6.dstAddr : selector;
        }
        actions = {
            set_egress_port;
            lag_miss;
        }
        size = 128;
        const default_action = lag_miss;
        implementation = lag_port_selector;
    }

    action single_port_table_miss() {}

    table single_port_table {
        key = {
            hdr.bridged_md.iid : exact;
        }
        actions = {
            set_egress_port;
            single_port_table_miss;
        }
        size = 256;
        const default_action = single_port_table_miss();
    }

    apply {
        switch(single_port_table.apply().action_run) {
            single_port_table_miss : {
                // Apply LAG Port selector. Take group to specific port
                lag_table.apply();
            }
        }
    }
}
# 20 "upf/p4src/pipe1/UPFIngress3_1.p4" 2







//=============================================================================
// Parser 3_1 (uplink)
//=============================================================================

parser UPFIngress3_1Parser(
            packet_in pkt,
            out headers hdr,
            out upf_ingress_metadata_t ig_md,
            out ingress_intrinsic_metadata_t ig_intr_md) {
    /*
    *  Packet entry point.
    */
    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
    }

    state parse_port_metadata {
        //Parse port metadata appended by tofino
        upf_port_metatdata_t port_md;
        pkt.extract(port_md);
        transition parse_ethernet;
    }

    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition parse_bridged_metadata;
    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  ARP parsing.
     */
    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }

    /*
     *  IPv4 parsing.
     */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_ICMP : parse_icmp;
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     *  IPv6 parsing.
     */
    state parse_outer_ipv6 {
        pkt.extract(hdr.outer_ipv6);
        ig_md.dstAddrv6 = hdr.outer_ipv6.dstAddr;
        ig_md.srcAddrv6 = hdr.outer_ipv6.srcAddr;
        ig_md.nextHdrv6 = hdr.outer_ipv6.nextHdr;
        transition select(hdr.outer_ipv6.nextHdr) {
            PROTO_ICMPV6 : parse_icmp;
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     * Parse outer TCP (downlink).
     * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort
     */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        transition accept;
    }

    /*
     *  Outer UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        hdr.outer_tcp.srcPort = hdr.outer_udp.srcPort;
        hdr.outer_tcp.dstPort = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }

    /*
     * Parse ICMP
     */
    state parse_icmp {
        pkt.extract(hdr.icmp);
        //hdr.bridged_md.punt = 0x1;
        transition accept;
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition select(hdr.gtp_u.extFlag, hdr.gtp_u.seqFlag, hdr.gtp_u.pn, hdr.gtp_u.msgType) {
            (1,_,_,_) : parse_gtp_u_options;
            (_,1,_,_) : parse_gtp_u_options;
            (_,_,1,_) : parse_gtp_u_options;
            (_,_,_,0xFF) : parse_inner_ip;
            default : accept;
        }
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u_options {
        pkt.extract(hdr.gtp_u_options);
        transition select(hdr.gtp_u.msgType) {
            0xFF : accept;
            default : accept;
        }
    }

    state parse_inner_ip {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version){
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_ipv4 {
         pkt.extract(hdr.inner_ipv4);
         transition select(hdr.inner_ipv4.protocol) {
            PROTO_UDP : parse_inner_udp;
            PROTO_TCP : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        ig_md.innerSrcAddrv6 = hdr.inner_ipv6.srcAddr;
        ig_md.innerDstAddrv6 = hdr.inner_ipv6.dstAddr;
        ig_md.innerNextHdrv6 = hdr.inner_ipv6.nextHdr;
         transition select(hdr.inner_ipv6.nextHdr) {
            PROTO_UDP : parse_inner_udp;
            PROTO_TCP : parse_inner_tcp;
            default : accept;
        }
    }

    /*
    * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort
    */
    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        hdr.inner_tcp.srcPort = hdr.inner_udp.srcPort;
        hdr.inner_tcp.dstPort = hdr.inner_udp.dstPort;
        transition accept;
    }
}

//=============================================================================
// Ingress 3_1 control (uplink)
//=============================================================================

control UPFIngress_Uplink_3_1(
        inout headers hdr,
        inout upf_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    SessionTableUplink(100000) session_table;
    Punt() punt;
    LAGUplink() lag;

    // Ingress portTable stats
    Counter<bit<32>, port_stats_indirect_counter_t>(65536, CounterType_t.PACKETS_AND_BYTES) iid_cntr;
    Counter<bit<32>, bit<9>>(512, CounterType_t.PACKETS_AND_BYTES) port_cntr;

    action set_ip_lkpv4() {
        ig_md.srcAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.srcAddrv6[95:64] = hdr.outer_ipv4.srcAddr;
        ig_md.srcAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;

        ig_md.dstAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.dstAddrv6[95:64] = hdr.outer_ipv4.dstAddr;
        ig_md.dstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        ig_md.nextHdrv6 = hdr.outer_ipv4.protocol;
    }

    action set_inner_ip_lkpv4_flow_sess() {
        ig_md.srcAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.srcAddrv6[95:64] = hdr.inner_ipv4.dstAddr;
        ig_md.srcAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;;

        ig_md.dstAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.dstAddrv6[95:64] = hdr.inner_ipv4.srcAddr;
        ig_md.dstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        ig_md.nextHdrv6 = hdr.inner_ipv4.protocol;
    }

    action set_inner_ip_lkpv6_flow_sess() {
        ig_md.srcAddrv6 = hdr.inner_ipv6.dstAddr;
        ig_md.dstAddrv6 = hdr.inner_ipv6.srcAddr;
        ig_md.nextHdrv6 = hdr.inner_ipv4.protocol;
    }

    action set_inner_ip_lkpv4() {
        ig_md.innerSrcAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.innerSrcAddrv6[95:64] = hdr.inner_ipv4.srcAddr;
        ig_md.innerSrcAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;;

        ig_md.innerDstAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.innerDstAddrv6[95:64] = hdr.inner_ipv4.dstAddr;
        ig_md.innerDstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        ig_md.innerNextHdrv6 = hdr.inner_ipv4.protocol;
    }


    action set_v4v4(){
        set_ip_lkpv4();
        set_inner_ip_lkpv4();
    }

    action set_v4v6(){
        set_ip_lkpv4();
    }

    action set_v6v4(){
        set_inner_ip_lkpv4();
    }

    action set_v6v6(){
    }

    table extract_info_table{
        key = {
            hdr.outer_ipv4.isValid() : exact;
            hdr.outer_ipv6.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.bridged_md.flow_sess_lookup : exact;
        }
        actions = {
            set_ip_lkpv4;
            set_v4v4;
            set_v4v6;
            set_v6v4;
            set_v6v6;
            set_inner_ip_lkpv6_flow_sess;
            set_inner_ip_lkpv4_flow_sess;
        }
        const entries = {
            (true, false, false, false, 0x0): set_ip_lkpv4();
            (true, false, true, false, 0x0): set_v4v4();
            (true, false, false, true, 0x0): set_v4v6();
            (false, true, true, false, 0x0): set_v6v4();
            (false, true, false, true, 0x0): set_v6v6();
            (false, true, false, true, 0x1): set_inner_ip_lkpv6_flow_sess();
            (true, false, false, true, 0x1): set_inner_ip_lkpv6_flow_sess();
            (true, false, true, false, 0x1): set_inner_ip_lkpv4_flow_sess();
            (false, true, true, false, 0x1): set_inner_ip_lkpv4_flow_sess();
        }
        size = 32; // 2^5
    }

    action del_bridged_md() {
        hdr.bridged_md.setInvalid();
    }

    action send_on_folded(){
        ig_intr_md_for_tm.ucast_egress_port = hdr.bridged_md.ucast_egress_port;
    }

    apply {
        iid_cntr.count(hdr.bridged_md.ingress_iid);
        port_cntr.count(hdr.bridged_md.ingress_port);

        extract_info_table.apply();
        if (hdr.bridged_md.flow_table == 0x0 && hdr.bridged_md.policy_table == 0x0) {
            session_table.apply(hdr, ig_md.dstAddrv6);
        }

        if (hdr.bridged_md.punt == 0x1 || hdr.bridged_md.session_miss == 0x4) {
            punt.apply(hdr,ig_md,ig_intr_md,ig_intr_md_for_dprsr,ig_intr_md_for_tm);
        }

        if (ig_intr_md_for_tm.bypass_egress == 1) {
            del_bridged_md();
        } else {
            lag.apply(hdr, ig_intr_md_for_dprsr);
            send_on_folded();
        }
    }
}

//=============================================================================
// Deparser 3_1
//=============================================================================

control UPFIngress3_1Deparser(
        packet_out pkt,
        inout headers hdr,
        in upf_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.dp_ctrl);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.gtp_u_options);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);

    }
}
# 22 "upf/p4src/pipe1/upf_1.p4" 2
# 1 "upf/p4src/pipe1/UPFEgress2_1.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2019
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "upf/p4src/pipe1/UPFEgress2_1.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "upf/p4src/pipe1/UPFEgress2_1.p4" 2

# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "upf/p4src/pipe1/UPFEgress2_1.p4" 2
# 1 "upf/p4src/common/session_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/
# 18 "upf/p4src/pipe1/UPFEgress2_1.p4" 2
# 1 "upf/p4src/common/policy_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/

# 1 "common/p4lib/core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 11 "upf/p4src/common/policy_table.p4" 2
# 1 "common/p4lib/core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 12 "upf/p4src/common/policy_table.p4" 2
# 1 "upf/p4src/common/metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 13 "upf/p4src/common/policy_table.p4" 2

//=============================================================================
// Policy table control
//=============================================================================

control PolicyTableDownlink(inout headers hdr,
    inout bit<128> srcAddrv6, inout bit<128> dstAddrv6,
    inout protocol_t nextHdrv6)(table_size_t table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) policy_cntr;

    action policy_fwd_encap(knid_t iid, bit<20> flowId) {
        policy_cntr.count();
        hdr.bridged_md.iid = iid;
        hdr.bridged_md.flowId = flowId;

        hdr.bridged_md.policy_table = 0x1;
    }

    action default_fwd() {
    }

    table policy_table {
        key = {
            hdr.bridged_md.ingress_iid : ternary;
            srcAddrv6 : ternary;
            dstAddrv6 : ternary;
            hdr.outer_tcp.srcPort : ternary;
            hdr.outer_tcp.dstPort : ternary;
            nextHdrv6 : ternary;
        }
        actions = {
            @defaultonly default_fwd;
            policy_fwd_encap;
        }
        size = table_size;
        default_action = default_fwd;
        counters = policy_cntr;
    }

    apply {
        policy_table.apply();
    }

}

control PolicyTableUplink(inout headers hdr,
    inout bit<128> srcAddrv6, inout bit<128> dstAddrv6,
    inout protocol_t nextHdrv6)(table_size_t table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) policy_cntr;

    action policy_fwd_decap(knid_t iid, bit<20> flowId) {
        policy_cntr.count();
        hdr.bridged_md.iid = iid;
        hdr.bridged_md.flowId = flowId;

        hdr.bridged_md.policy_table = 0x1;
    }

    action default_fwd() {
    }

    table policy_table {
        key = {
            hdr.bridged_md.ingress_iid : ternary;
            srcAddrv6 : ternary;
            dstAddrv6 : ternary;
            hdr.inner_tcp.srcPort : ternary;
            hdr.inner_tcp.dstPort : ternary;
            nextHdrv6 : ternary;
        }
        actions = {
            @defaultonly default_fwd;
            policy_fwd_decap;
        }
        size = table_size;
        default_action = default_fwd;
        counters = policy_cntr;
    }

    apply {
        policy_table.apply();
    }

}
# 19 "upf/p4src/pipe1/UPFEgress2_1.p4" 2

//=============================================================================
// Parser 2_1 (uplink)
//=============================================================================

parser UPFEgress2_1Parser(
            packet_in pkt,
            out headers hdr,
            out upf_egress_metadata_t eg_md,
            out egress_intrinsic_metadata_t eg_intr_md) {

    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(eg_intr_md);
        transition parse_ethernet;
     }

    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition parse_bridged_metadata;
    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  ARP parsing.
     */
    state parse_arp {
        pkt.extract(hdr.arp);
        hdr.bridged_md.punt = 0x1;
        transition accept;
    }

    /*
     *  IPv4 parsing.
     */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_ICMP : parse_icmp;
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     *  IPv6 parsing.
     */
    state parse_outer_ipv6 {
        pkt.extract(hdr.outer_ipv6);
        eg_md.dstAddrv6 = hdr.outer_ipv6.dstAddr;
        eg_md.srcAddrv6 = hdr.outer_ipv6.srcAddr;
        eg_md.nextHdrv6 = hdr.outer_ipv6.nextHdr;
        transition select(hdr.outer_ipv6.nextHdr) {
            PROTO_ICMPV6 : parse_icmp;
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     * Parse outer TCP (downlink).
     * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort
     */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        transition accept;
    }

    /*
     *  Outer UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        hdr.outer_tcp.srcPort = hdr.outer_udp.srcPort;
        hdr.outer_tcp.dstPort = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }

    /*
     * Parse ICMP
     */
    state parse_icmp {
        pkt.extract(hdr.icmp);
        //hdr.bridged_md.punt = 0x1;
        transition accept;
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition select(hdr.gtp_u.extFlag, hdr.gtp_u.seqFlag, hdr.gtp_u.pn, hdr.gtp_u.msgType) {
            (1,_,_,_) : parse_gtp_u_options;
            (_,1,_,_) : parse_gtp_u_options;
            (_,_,1,_) : parse_gtp_u_options;
            (_,_,_,0xFF) : parse_inner_ip;
            default : accept;
        }
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u_options {
        pkt.extract(hdr.gtp_u_options);
        transition select(hdr.gtp_u.msgType) {
            0xFF : accept;
            default : accept;
        }
    }

    state parse_inner_ip {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version){
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
         pkt.extract(hdr.inner_ipv4);
         transition select(hdr.inner_ipv4.protocol) {
            PROTO_UDP : parse_inner_udp;
            PROTO_TCP : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        eg_md.innerSrcAddrv6 = hdr.inner_ipv6.srcAddr;
        eg_md.innerDstAddrv6 = hdr.inner_ipv6.dstAddr;
        eg_md.innerNextHdrv6 = hdr.inner_ipv6.nextHdr;
         transition select(hdr.inner_ipv6.nextHdr) {
            PROTO_UDP : parse_inner_udp;
            PROTO_TCP : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    /*
    * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort
    */
    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        hdr.inner_tcp.srcPort = hdr.inner_udp.srcPort;
        hdr.inner_tcp.dstPort = hdr.inner_udp.dstPort;
        transition accept;
    }
}
//=============================================================================
// Egress 2_1 control (uplink)
//=============================================================================

control UPFEgress_Uplink_2_1(
        inout headers hdr,
        inout upf_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    SessionTableUplink(105000) session_table;
    PolicyTableUplink(4096) policy_table;

    action set_ip_lkpv4() {
        eg_md.srcAddrv6[127:96] = ZEROS_PADDING_4B;
        eg_md.srcAddrv6[95:64] = hdr.outer_ipv4.srcAddr;
        eg_md.srcAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;

        eg_md.dstAddrv6[127:96] = ZEROS_PADDING_4B;
        eg_md.dstAddrv6[95:64] = hdr.outer_ipv4.dstAddr;
        eg_md.dstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        eg_md.nextHdrv6 = hdr.outer_ipv4.protocol;
    }

    action set_inner_ip_lkpv4_flow_sess() {
        eg_md.srcAddrv6[127:96] = ZEROS_PADDING_4B;
        eg_md.srcAddrv6[95:64] = hdr.inner_ipv4.srcAddr;
        eg_md.srcAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;;

        eg_md.dstAddrv6[127:96] = ZEROS_PADDING_4B;
        eg_md.dstAddrv6[95:64] = hdr.inner_ipv4.dstAddr;
        eg_md.dstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        eg_md.nextHdrv6 = hdr.inner_ipv4.protocol;
    }

    action set_inner_ip_lkpv6_flow_sess() {
        eg_md.srcAddrv6 = hdr.inner_ipv6.dstAddr;
        eg_md.dstAddrv6 = hdr.inner_ipv6.srcAddr;
        eg_md.nextHdrv6 = hdr.inner_ipv4.protocol;
    }

    action set_inner_ip_lkpv4() {
        eg_md.innerSrcAddrv6[127:96] = ZEROS_PADDING_4B;
        eg_md.innerSrcAddrv6[95:64] = hdr.inner_ipv4.srcAddr;
        eg_md.innerSrcAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;;

        eg_md.innerDstAddrv6[127:96] = ZEROS_PADDING_4B;
        eg_md.innerDstAddrv6[95:64] = hdr.inner_ipv4.dstAddr;
        eg_md.innerDstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        eg_md.innerNextHdrv6 = hdr.inner_ipv4.protocol;
    }


    action set_v4v4(){
        set_ip_lkpv4();
        set_inner_ip_lkpv4();
    }

    action set_v4v6(){
        set_ip_lkpv4();
    }

    action set_v6v4(){
        set_inner_ip_lkpv4();
    }

    action set_v6v6(){
    }

    table extract_info_table{
        key = {
            hdr.outer_ipv4.isValid() : exact;
            hdr.outer_ipv6.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
            hdr.bridged_md.flow_sess_lookup : exact;
        }
        actions = {
            set_ip_lkpv4;
            set_v4v4;
            set_v4v6;
            set_v6v4;
            set_v6v6;
            set_inner_ip_lkpv6_flow_sess;
            set_inner_ip_lkpv4_flow_sess;
        }
        const entries = {
            (true, false, false, false, 0x0): set_ip_lkpv4();
            (true, false, true, false, 0x0): set_v4v4();
            (true, false, false, true, 0x0): set_v4v6();
            (false, true, true, false, 0x0): set_v6v4();
            (false, true, false, true, 0x0): set_v6v6();
            (false, true, false, true, 0x1): set_inner_ip_lkpv6_flow_sess();
            (true, false, false, true, 0x1): set_inner_ip_lkpv6_flow_sess();
            (true, false, true, false, 0x1): set_inner_ip_lkpv4_flow_sess();
            (false, true, true, false, 0x1): set_inner_ip_lkpv4_flow_sess();
        }
        size = 32; // 2^5
    }

    apply {
        extract_info_table.apply();

        if(hdr.bridged_md.flow_table == 0x0 && hdr.bridged_md.flow_sess_lookup == 0x0){
            policy_table.apply(hdr,eg_md.innerSrcAddrv6, eg_md.innerDstAddrv6, eg_md.innerNextHdrv6);
        }

        if (hdr.bridged_md.flow_table == 0x0 && hdr.bridged_md.policy_table == 0x0) {
            session_table.apply(hdr,eg_md.dstAddrv6);
        }
    }
}

//=============================================================================
// Deparser 2_1
//=============================================================================

control UPFEgress2_1Deparser(
            packet_out pkt,
            inout headers hdr,
            in upf_egress_metadata_t eg_md,
            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply{
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.gtp_u_options);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
    }
}
# 23 "upf/p4src/pipe1/upf_1.p4" 2

Pipeline(UPFIngress3_1Parser(),
  UPFIngress_Uplink_3_1(),
  UPFIngress3_1Deparser(),
  UPFEgress2_1Parser(),
  UPFEgress_Uplink_2_1(),
  UPFEgress2_1Deparser()) pipe;

Switch(pipe) main;
