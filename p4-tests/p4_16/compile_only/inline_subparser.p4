#include <core.p4>
#include <tna.p4>

/*
 * Ether types
 */
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_DP_CTRL = 16w0x99ff; // Used for to/from CPU packets for now
//#define ETHERTYPE_ARP  0x0806

/*
 *  Port Definitions
 */


/*
 * Header minimum size
 */
typedef bit<16> size_t;
const size_t ETH_MIN_SIZE = 0x0E;
const size_t IPV4_MIN_SIZE = 0x14;
const size_t UDP_SIZE = 0x08;
const size_t GTP_MIN_SIZE = 0x08;
const size_t VLAN_SIZE = 0x04;

/*
 *  Port number definition
 */
typedef bit<16> port_t;
const port_t PORT_GTP_U = 2152;

/*
 *  IP Protocol definition
 */
typedef bit<8> ip_protocol_t;
const ip_protocol_t PROTO_UDP = 17;
//#define IP_PROTOCOLS_ICMP   1
//#define IP_PROTOCOLS_IPV4   4
//#define IP_PROTOCOLS_TCP    6
//#define IP_PROTOCOLS_IPV6   41
//#define IP_PROTOCOLS_ICMPV6 58

// FIXME: temporary, until we introduce lookups
# 68 "types.p4"
typedef bit<8> switch_pkt_src_t;
typedef MirrorId_t switch_mirror_id_t;
const bit<32> INT_SESSION_NUM = 15;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGE = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_EGRESS = 2;
# 14 "headers.p4" 2

/*************************************************************************

********************************** L2  ***********************************

*************************************************************************/
# 19 "headers.p4"
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header vlan_t {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vlanId;
    bit<16> etherType;
}

/*************************************************************************

********************************** L3  ***********************************

*************************************************************************/
# 36 "headers.p4"
// header ipv4_t {
//     bit<4>      version;
//     bit<4>      ihl;
//     bit<8>      diffserv;
//     bit<16>     totalLen;
//     bit<16>     identification;
//     bit<3>      flags;
//     bit<13>     fragOffset;
//     bit<8>      ttl;
//     bit<8>      protocol;
//     bit<16>     hdrChecksum;
//     bit<32>     srcAddr;
//     bit<32>     dstAddr;
// }

header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

/* TODO :  Add IPV6 headers*/

/*************************************************************************

********************************** L4  ***********************************

*************************************************************************/
# 68 "headers.p4"
header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdrLen;
    bit<16> checksum;
}

header vxlan_t {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

/* Metadata for packets that are forwarded to/from CPU */
/*

 *TODO : Decide what metadata should be fowarded. Padding added for this purpose.

 */
# 86 "headers.p4"
header dp_ctrl_header_t {
    bit<5> _pad0;
    bit<3> ring_id;
    bit<72> _pad1;
    bit<9> port;
    bit<7> _pad3;
    bit<16> etherType;
}

header inter_pipes_header_t {
    bit<9> ingress_port;
    bit<1> postcard_en;
    bit<6> pad0;
    bit<32> ingress_tstamp; // TODO: to become 48 bit
    bit<8> int_session_id; // INT config session id
    bit<7> pad1;
    bit<9> egress_port;
    bit<32> flow_hash;
    bit<32> reg_value;
}

@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.int_session_id", 8)
@pa_container_size("egress", "eg_md.mirror.ingress_port_id", 8)
@pa_container_size("egress", "eg_md.mirror.egress_port_id", 8)
header switch_mirror_metadata_t {
    switch_pkt_src_t src; // bit<8>
    bit<32> hop_latency;
    bit<32> ingress_tstamp;
    bit<32> egress_tstamp;
    bit<32> q_congestion;
    bit<32> egress_port_tx_utilization;
    bit<24> q_occupancy0;
    bit<8> int_session_id;
    // INT data
    bit<8> ingress_port_id;
    bit<8> egress_port_id;
    bit<8> qid;
    // bit<1>              pad_1;
    // bit<6>              _pad;
    // switch_mirror_id_t  session_id;
    // bit<8>              _pad2;
}

// phase0 header that is added by the ingress parser
header phase_0_metatdata_t {
    bit<7> _pad;
    bit<9> port_lag_index;
    bit<16> port_lag_label;
    bit<1> port_type;
    bit<31> _pad1;
}

/*************************************************************************

************************* Headers declaration ****************************

*************************************************************************/
# 142 "headers.p4"
/** INTSW meta-value headers - different header for each value type ****/
// INT headers
// header int_header_t {
//     bit<4>      ver;
//     bit<2>      rep; // Replication requested (e.g. replicat INT information for all possible passes, ECMP for example)
//     bit<1>      c; // Copy (e.g. broadcast or multicast)
//     bit<1>      e; // Max Hop Count exceeded
//     bit<1>      d;
//     bit<2>      rsvd1;
//     bit<5>      ins_cnt;
//     bit<8>      max_hop_cnt;
//     bit<8>      total_hop_cnt;
//     bit<4>      instruction_bitmap_0003;  // split the bits for lookup
//     bit<4>      instruction_bitmap_0407;
//     bit<4>      instruction_bitmap_0811;
//     bit<4>      instruction_bitmap_1215;
//     bit<16>     rsvd2_digest;
// }
// INT meta-value headers - different header for each value type
header int_switch_id_header_t {
    bit<32> switch_id;
}
header int_port_ids_header_t {
    bit<8> pad_1;
    bit<8> ingress_port_id;
    bit<8> egress_port_id;
    bit<8> pad_2;
}
// header int_ingress_port_id_header_t {
//     bit<16>    ingress_port_id_1;
//     bit<16>    ingress_port_id_0;
// }
header int_hop_latency_header_t {
    bit<32> hop_latency;
}
header int_q_occupancy_header_t {
    // bit<3>      rsvd;
    bit<8> qid;
    bit<24> q_occupancy0;
}
header int_ingress_tstamp_header_t {
    bit<32> ingress_tstamp;
}
header int_egress_tstamp_header_t {
    bit<32> egress_tstamp;
}
header int_q_congestion_header_t {
    bit<32> q_congestion;
}
header int_egress_port_tx_utilization_header_t {
    bit<32> egress_port_tx_utilization;
}

/***************** INT report ********************/
header dtel_report_header_t {
        bit<8> ver_Len;
        /*

        bit<3>   next_proto; // 0: Ethernet, 1: IPv4, 2: IPv6

        bit<1>   d; // dropped

        bit<1>   q; // congested_queue

        bit<1>   f; // path_tracking_flow

        bit<6>   reserved;

        bit<6>  reserved2;

        bit<6>   hw_id;

        */
# 207 "headers.p4"
        bit<24> merged_fields;
        bit<32> sequence_number;
        // timestamp;
}

/**************************** INTSW meta-value headers *******************************/

// FIXME: Does this belong here?
struct intSw_headers_t {
    ethernet_t encap_ethernet;
    ipv6_t encap_ipv6;
    udp_t encap_udp;

    dtel_report_header_t dtel_report_header;
    int_switch_id_header_t int_switch_id_header;
    int_port_ids_header_t int_port_ids_header;
    int_hop_latency_header_t int_hop_latency_header;
    int_q_occupancy_header_t int_q_occupancy_header;
    int_ingress_tstamp_header_t int_ingress_tstamp_header;
    int_egress_tstamp_header_t int_egress_tstamp_header;
    int_q_congestion_header_t int_q_congestion_header;
    int_egress_port_tx_utilization_header_t int_egress_port_tx_utilization_header;

    ethernet_t ethernet;
    vlan_t vlan;
    ipv6_t outer_ipv6;
    ipv6_t inner_ipv6;
    udp_t outer_udp;
    udp_t inner_udp;
    dp_ctrl_header_t dp_ctrl; // To/from CPU
    inter_pipes_header_t inter_pipes_hdr;
    // int_header_t                            int_header;
}
# 16 "intSw.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "intSw.p4" 2


# 1 "parde.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "headers.p4" 1
/****************************************************************

 * Copyright (c) Kaloom Inc., 2018

 *

 * This unpublished material is property of Kaloom Inc.

 * All rights reserved.

 * Reproduction or distribution, in whole or in part, is

 * forbidden except by express written permission of Kaloom Inc.

 ****************************************************************/
# 14 "parde.p4" 2
# 1 "metadata.p4" 1
/****************************************************************

 * Copyright (c) Kaloom Inc., 2018

 *

 * This unpublished material is property of Kaloom Inc.

 * All rights reserved.

 * Reproduction or distribution, in whole or in part, is

 * forbidden except by express written permission of Kaloom Inc.

 ****************************************************************/
# 13 "metadata.p4"
# 1 "headers.p4" 1
/****************************************************************

 * Copyright (c) Kaloom Inc., 2018

 *

 * This unpublished material is property of Kaloom Inc.

 * All rights reserved.

 * Reproduction or distribution, in whole or in part, is

 * forbidden except by express written permission of Kaloom Inc.

 ****************************************************************/
# 14 "metadata.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "metadata.p4" 2

@pa_container_size("egress", "eg_md.egress_port", 16)
// @pa_container_size("egress", "intSw_egress_metadata_t.egress_port", 16)
struct intSw_egress_metadata_t {
    // bit<16>     pkt_length;
    switch_mirror_metadata_t mirror;
    PortId_t egress_port; // bit<9>
    switch_mirror_id_t session_id; // bit<10>
    bit<5> pad;
    bit<4> instruction_bitmap_0003; // split the bits for lookup
    bit<4> instruction_bitmap_0407;
    bit<4> instruction_bitmap_0811;
    bit<4> instruction_bitmap_1215;
    bit<16> int_len;
}


struct intSw_ingress_metadata_t {
    bit<1> resubmit_flag;
    bit<2> packet_version;
    bit<5> _pad1;
    bit<16> nexthop_id;
    bit<32> flow_hash;
}
# 15 "parde.p4" 2


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
//XXX This is a temporary workaround to make sure mirror metadata do not share
// the PHV containers with any other fields or paddings.
// @pa_container_size("ingress", "ig_md.mirror.session_id", 16)
control EgressMirror(
    in intSw_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend
// the prepend the mirror header.
    Mirror() mirror; // BAHNASY: I imagine this creates the mirror clone of the original packet.

    apply {
        if (eg_intr_md_for_dprsr.mirror_type == 0x4) {
            mirror.emit<switch_mirror_metadata_t>(eg_md.session_id, {
                         eg_md.mirror.src,
                         eg_md.mirror.hop_latency,
                         eg_md.mirror.ingress_tstamp,
                         eg_md.mirror.egress_tstamp,
                         eg_md.mirror.q_congestion,
                         eg_md.mirror.egress_port_tx_utilization,
                         eg_md.mirror.q_occupancy0,
                         eg_md.mirror.int_session_id,
                         eg_md.mirror.ingress_port_id,
                         eg_md.mirror.egress_port_id,
                         eg_md.mirror.qid
                         });
        }
    }
}

parser INTSWCommonParser(
            packet_in pkt,
            out intSw_headers_t hdr) {
    state start {
        transition parse_ethernet;
    }
    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
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
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  IPv6 parsing.
     */
    state parse_outer_ipv6 {
        pkt.extract(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr) {
            PROTO_UDP : parse_outer_udp;
            default : accept;
        }
    }

    /*
     *  UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        transition accept;
        // transition select(hdr.outer_udp.dstPort) {
        //     PORT_GTP_U      : parse_gtp_u;
        //     default         : accept;
        // }
    }

    /********* Parse VXLAN *********
    parser parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_vxlan_inner_ethernet;
    }

    parser parse_vxlan_inner_ethernet {
        extract(vxlan_inner_ethernet);
        transition select(latest.etherType) {
            //ETHERTYPE_IPV6    : parse_vxlan_inner_ipv6;
            ETHERTYPE_IPV6    : parse_inner_ipv6;
            default           : accept;
        }
    }
    ******************/
}
//=============================================================================
// Ingress Parser
//=============================================================================
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_port", 16)
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_tstamp", 16)
// @pa_no_overlay("ingress", "hdr.inter_pipes_hdr.ingress_port")
// @pa_no_overlay("ingress", "hdr.inter_pipes_hdr.ingress_tstamp")
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_tstamp", 32)
parser INTSWIngressParser(
            packet_in pkt,
            out intSw_headers_t hdr,
            out intSw_ingress_metadata_t ig_md,
            out ingress_intrinsic_metadata_t ig_intr_md) {

    INTSWCommonParser() prsr;
    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(ig_intr_md);
        // hdr.inter_pipes_hdr.ingress_port = ig_intr_md.ingress_port;
        // hdr.inter_pipes_hdr.ingress_tstamp = ig_intr_md.ingress_mac_tstamp;
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit; // Need criteria for resubmitting
            0 : parse_phase_0_metadata; // default
        }
    }

    state parse_resubmit {
        // Parse resubmit packet mirrored or notice
        //TODO : add necessary actions in resubmit case
        transition reject;
    }

    state parse_phase_0_metadata {
        //Parse port metadata appended by tofino
        phase_0_metatdata_t phase_0_md;
        pkt.extract(phase_0_md);
        transition parse_packet;
    }

    state parse_packet {
            prsr.apply(pkt, hdr);
            transition accept;
        }
}

//=============================================================================
// Ingress Deparser
//=============================================================================
control INTSWIngressDeparser(
            packet_out pkt,
            inout intSw_headers_t hdr,
            in intSw_ingress_metadata_t ig_md,
            in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply{
        pkt.emit(hdr.inter_pipes_hdr);
        // pkt.emit(hdr.dp_ctrl);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.outer_udp);
        // pkt.emit(hdr.gtp_u);
        // pkt.emit(hdr.inner_ipv6);
        // pkt.emit(hdr.inner_udp);
    }
}

//=============================================================================
// Egress Parser
//=============================================================================
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_port", 16)
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_tstamp", 16)
// @pa_no_overlay("ingress", "hdr.inter_pipes_hdr.ingress_port")
// @pa_no_overlay("ingress", "hdr.inter_pipes_hdr.ingress_tstamp")

// @pa_container_size("egress", "hdr.int_ingress_tstamp_header.ingress_tstamp", 32)
parser INTSWEgressParser(
            packet_in pkt,
            out intSw_headers_t hdr,
            out intSw_egress_metadata_t eg_md,
            out egress_intrinsic_metadata_t eg_intr_md) {

    INTSWCommonParser() prsr;
    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(eg_intr_md);
        switch_pkt_src_t src = pkt.lookahead<switch_pkt_src_t>();
        transition select(src) {
            SWITCH_PKT_SRC_BRIDGE : parse_metadata;
            default : parse_mirrored_packet;
        }
    }

    state parse_mirrored_packet {
        pkt.extract(eg_md.mirror);
        // eg_md.pkt_src = eg_md.mirror.src;
        transition parse_packet;
    }
    /*
     *  Parse metadata. FIXME: Is this right ?
     */
    state parse_metadata {
        // eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.mirror.src = SWITCH_PKT_SRC_BRIDGE; // Added to force normal packet processing at the egress pipe
        transition parse_inter_pipes_hdr;
    }

    state parse_inter_pipes_hdr {
        pkt.extract(hdr.inter_pipes_hdr);
        eg_md.egress_port = hdr.inter_pipes_hdr.egress_port;
        transition parse_packet;
    }

    state parse_packet {
            prsr.apply(pkt, hdr);
            transition accept;
        }
}

//=============================================================================
// Egress Deparser
//=============================================================================
control INTSWEgressDeparser(
            packet_out pkt,
            inout intSw_headers_t hdr,
            in intSw_egress_metadata_t eg_md,
            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() egress_mirror;

    Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) encap_udp_checksum;
    // Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) inner_ipv4_checksum;

    apply {
        hdr.encap_udp.checksum = encap_udp_checksum.update({
        //         hdr.encap_ipv6.version,
        //         hdr.encap_ipv6.ihl,
        //         hdr.encap_ipv6.diffserv,
        //         hdr.encap_ipv6.totalLen,
        //         hdr.encap_ipv6.identification,
        //         hdr.encap_ipv6.flags,
        //         hdr.encap_ipv6.fragOffset,
        //         hdr.encap_ipv6.ttl,
                hdr.encap_ipv6.nextHdr,
                hdr.encap_ipv6.srcAddr,
                hdr.encap_ipv6.dstAddr,
                hdr.encap_udp.hdrLen
                // FIXME: to add the payload.
        });
        pkt.emit(hdr.encap_ethernet);
        pkt.emit(hdr.encap_ipv6);
        pkt.emit(hdr.encap_udp);

        pkt.emit(hdr.dtel_report_header);
        pkt.emit(hdr.int_switch_id_header);
        pkt.emit(hdr.int_port_ids_header);
        pkt.emit(hdr.int_hop_latency_header);
        pkt.emit(hdr.int_q_occupancy_header);
        pkt.emit(hdr.int_ingress_tstamp_header);
        pkt.emit(hdr.int_egress_tstamp_header);
        pkt.emit(hdr.int_q_congestion_header);
        pkt.emit(hdr.int_egress_port_tx_utilization_header);

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.outer_udp);
       // pkt.emit(hdr.gtp_u);
        // pkt.emit(hdr.inner_ipv6);
        // pkt.emit(hdr.inner_udp);
        egress_mirror.apply(eg_md, eg_intr_md_for_dprsr);
    }
}

//=============================================================================
// Ingress control
//=============================================================================
control INTSWIngress(
        inout intSw_headers_t hdr,
        inout intSw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    apply {}
}
//=============================================================================
// Egress control
//=============================================================================
control INTSWEgress(
        inout intSw_headers_t hdr,
        inout intSw_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

Pipeline(INTSWIngressParser(),
        INTSWIngress(),
        INTSWIngressDeparser(),
        INTSWEgressParser(),
        INTSWEgress(),
        INTSWEgressDeparser()) pipe;

Switch(pipe) main;
