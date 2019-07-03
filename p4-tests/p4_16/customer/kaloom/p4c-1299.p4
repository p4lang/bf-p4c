#include <core.p4>
#include <tna.p4>

/*************************************************************************
********************************** L2  ***********************************
*************************************************************************/

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

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

/* TODO:  Add IPV6 headers*/

/*************************************************************************
********************************** L4  ***********************************
*************************************************************************/

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
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<32> checksum;
    // FIXME: We merged checksum and urgentPtr since we don't use the later, to
    // allow us to copy the checksum. It is clearly a bug.
    //bit<16>     urgentPtr;
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

/*
 * TODO: Extended header GTP_U, take it into account
 */
header gtp_u_extended_t {
    bit<16> seqNumb;
    bit<8> npdu;
    bit<8> neh;
}

/*************************************************************************
*************************  DP Control Header  ****************************
*************************************************************************/

/* Metadata for packets that are forwarded to/from CPU */
/*
 * TODO: Decide what metadata should be fowarded. Padding added for this purpose.
 */
header dp_ctrl_header_t {
    bit<5> _pad0;
    bit<3> ring_id;
    bit<79> _pad1;
    PortId_t port;
    bit<16> etherType;
}

/*************************************************************************
******************** Ingress/Egress bridge Header  ***********************
*************************************************************************/
header upf_bridged_metadata_t {
// user-defined metadata carried over from ingress to egress. 168 bits.
    bit<11> _pad0;
    bit<9> ingress_port;
    bit<12> vlanId;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<8> protocol;
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<32> teid;
// add more fields here.
}

/*************************************************************************
************************* Headers declaration ****************************
*************************************************************************/

// FIXME: Does this belong here?
struct headers {
    upf_bridged_metadata_t bridged_md;
    dp_ctrl_header_t dp_ctrl;
    ethernet_t ethernet;
    vlan_t vlan;
    ipv4_t outer_ipv4;
    udp_t outer_udp;
    tcp_t outer_tcp;
    gtp_u_t gtp_u;
    ipv4_t inner_ipv4;
    udp_t inner_udp;
    tcp_t inner_tcp;
}
# 14 "upf.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/*
 * Ether types
 */
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_DP_CTRL = 16w0x99ff; // Used for to/from CPU packets for now

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
const ip_protocol_t PROTO_TCP = 6;
# 15 "upf.p4" 2


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
# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "metadata.p4" 2

// TODO: explaining each metadata (like BF)

struct upf_egress_metadata_t {
    bit<16> pkt_length;
    bit<9> ingress_port;
    bit<12> vlanId;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<8> protocol;
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<32> teid;
}

header upf_port_metatdata_t {
    bit<7> _pad ;
    bit<9> port_lag_index;
    bit<16> port_lag_label;
    bit<1> port_type;
    bit<31> _pad1;
}

struct upf_ingress_metadata_t {
    bit<1> resubmit_flag;
    bit<1> _pad1;
    bit<2> packet_version;
    bit<3> _pad2;
    bit<9> cpu_port;
    bit<48> ingress_mac_tstamp;
    bit<16> dlSrcPort; // To abstract TCP/UDP src port
    bit<16> dlDstPort; // To abstract TCP/UDP dst port
}
# 15 "parde.p4" 2

//=============================================================================
// Ingress Parser
//=============================================================================
parser UPFIngressParser(
            packet_in pkt,
            out headers hdr,
            out upf_ingress_metadata_t ig_md,
            out ingress_intrinsic_metadata_t ig_intr_md) {

    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(ig_intr_md);
        ig_md.ingress_mac_tstamp = ig_intr_md.ingress_mac_tstamp;
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit; // Need criteria for resubmitting
            0 : parse_port_metadata; // default
        }
    }

    state parse_resubmit {
        // Parse resubmit packet mirrored or notice
        // TODO: add necessary actions in resubmit case
        transition reject;
    }

    state parse_port_metadata {
        //Parse port metadata appended by tofino
        upf_port_metatdata_t port_md;
        pkt.extract(port_md);
        transition parse_packet;
    }

    state parse_packet {
        dp_ctrl_header_t ether = pkt.lookahead<dp_ctrl_header_t>();
        transition select(ether.etherType) {
            ETHERTYPE_DP_CTRL : parse_dp_ctrl;
            default : parse_ethernet;
        }
/*         dp_ctrl_header_t dp_ctrl_hdr;
        transition parse_ethernet; */
    }

    state parse_dp_ctrl {
        pkt.extract(hdr.dp_ctrl);
        transition select(hdr.dp_ctrl.etherType) {
            ETHERTYPE_DP_CTRL : parse_ethernet;
            default : accept;
        }
    }


    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  IPv4 parsing.
     */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     * Parse outer TCP (downlink).
     */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        ig_md.dlSrcPort = hdr.outer_tcp.srcPort;
        ig_md.dlDstPort = hdr.outer_tcp.dstPort;
        transition accept;
    }

    /*
     *  Outer UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        ig_md.dlSrcPort = hdr.outer_udp.srcPort;
        ig_md.dlDstPort = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition accept;
    }
}

//=============================================================================
// Ingress Deparser
//=============================================================================
control UPFIngressDeparser(
            packet_out pkt,
            inout headers hdr,
            in upf_ingress_metadata_t ig_md,
            in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply{

        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.dp_ctrl);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_udp);
    }
}

//=============================================================================
// Egress Parser
//=============================================================================
parser UPFEgressParser(
            packet_in pkt,
            out headers hdr,
            out upf_egress_metadata_t eg_md,
            out egress_intrinsic_metadata_t eg_intr_md) {

    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridged_metadata;
    }

    /*
     *  Parse metadata. FIXME: Is this right ?
     */
    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.ingress_port = hdr.bridged_md.ingress_port ;
        eg_md.vlanId = hdr.bridged_md.vlanId ;
        eg_md.srcPort = hdr.bridged_md.srcPort ;
        eg_md.dstPort = hdr.bridged_md.dstPort ;
        eg_md.protocol = hdr.bridged_md.protocol;
        eg_md.srcAddr = hdr.bridged_md.srcAddr ;
        eg_md.dstAddr = hdr.bridged_md.dstAddr;
        eg_md.teid = hdr.bridged_md.teid;
        transition parse_packet;
    }

    state parse_packet {
        pkt.extract(hdr.dp_ctrl);
        transition select(hdr.dp_ctrl.etherType) {
            ETHERTYPE_DP_CTRL : parse_ethernet;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  IPv4 parsing.
     */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     * Parse outer TCP (downlink).
     */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        transition accept;
    }

    /*
     *  UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition accept;
    }
}

//=============================================================================
// Egress Deparser
//=============================================================================
control UPFEgressDeparser(
            packet_out pkt,
            inout headers hdr,
            in upf_egress_metadata_t eg_md,
            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() outer_ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
        hdr.outer_ipv4.hdrChecksum = outer_ipv4_checksum.update({
                hdr.outer_ipv4.version,
                hdr.outer_ipv4.ihl,
                hdr.outer_ipv4.diffserv,
                hdr.outer_ipv4.totalLen,
                hdr.outer_ipv4.identification,
                hdr.outer_ipv4.flags,
                hdr.outer_ipv4.fragOffset,
                hdr.outer_ipv4.ttl,
                hdr.outer_ipv4.protocol,
                hdr.outer_ipv4.srcAddr,
                hdr.outer_ipv4.dstAddr
        });

        hdr.inner_ipv4.hdrChecksum = inner_ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.totalLen,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.fragOffset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.srcAddr,
                hdr.inner_ipv4.dstAddr
        });

        pkt.emit(hdr.dp_ctrl);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_udp);
    }
}
# 18 "upf.p4" 2
# 1 "uplink.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control Uplink(inout headers hdr,
            inout upf_egress_metadata_t eg_md) {

    action decap_gtp() {
        // If we need to decap VLAN, should be here
        hdr.outer_ipv4.setInvalid();
        hdr.outer_udp.setInvalid();
        hdr.gtp_u.setInvalid();
    }

    apply {
        decap_gtp();
    }
}
# 19 "upf.p4" 2
# 1 "downlink.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control Downlink(inout headers hdr,
            inout upf_egress_metadata_t eg_md) {

    action sub_fcs_tofino() {
        /* Subtract 4 from the packet length to account for the 4 bytes of Ethernet
         * FCS that is included in Tofino's packet length metadata.
         */
        eg_md.pkt_length = eg_md.pkt_length - 0x4;
    }

    action payload_vlan_len() {
        eg_md.pkt_length = eg_md.pkt_length - VLAN_SIZE;
    }

    action payload_len() {
        eg_md.pkt_length = eg_md.pkt_length - ETH_MIN_SIZE;
    }

    action compute_len() {
        hdr.outer_ipv4.totalLen = IPV4_MIN_SIZE + UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
        hdr.outer_udp.hdrLen = UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
        hdr.gtp_u.totalLen = eg_md.pkt_length;
    }

    action copy_outer_ip_to_inner_ip() {
        // Copy outer IP to inner IP
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4 = hdr.outer_ipv4;
        hdr.outer_ipv4.protocol = PROTO_UDP;
    }

    action add_gtp() {
        // Add GTP
        hdr.gtp_u.setValid();
        hdr.gtp_u.version = 1;
        hdr.gtp_u.pt = 1;
        hdr.gtp_u.msgType = 255;
        // TODO: To be changed when the tables will be done
        hdr.gtp_u.teid = 0;
    }

    action copy_outer_tcp_to_inner_tcp() {
        /*
         * If we parsed a outer tcp we need to copy it to inner tcp
         * and delet it.
         */
        hdr.inner_tcp.setValid();
        hdr.inner_tcp = hdr.outer_tcp;
        //hdr.inner_tcp.checksum = hdr.outer_tcp.checksum;
        hdr.outer_tcp.setInvalid();
    }

    action copy_outer_udp_to_inner_udp() {
        hdr.inner_udp.setValid();
        hdr.inner_udp = hdr.outer_udp;
        hdr.inner_udp.checksum = hdr.outer_udp.checksum;
    }

    action add_outer_udp() {
        // ADD outer UDP
        hdr.outer_udp.setValid();
        // Tofino does not support UDP checksum
        hdr.outer_udp.checksum = 0;
        hdr.outer_udp.dstPort = PORT_GTP_U;
        hdr.outer_udp.srcPort = PORT_GTP_U;
    }

    apply {
        copy_outer_ip_to_inner_ip();
        add_gtp();
        if (hdr.outer_tcp.isValid()){
            copy_outer_tcp_to_inner_tcp();
        } else if (hdr.outer_udp.isValid()){
            copy_outer_udp_to_inner_udp();
        }
        add_outer_udp();
        if (hdr.vlan.isValid()) {
            payload_vlan_len();
        }
        sub_fcs_tofino();
        payload_len();
        compute_len();
    }
}
# 20 "upf.p4" 2
# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 21 "upf.p4" 2

// FIXME: temporary, until we introduce lookups


//=============================================================================
// Ingress control
//=============================================================================
control UPFIngress(
        inout headers hdr,
        inout upf_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    // Stateful objects
    // If need to use for p4 conditions use Registers instead of counters
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ig_drp_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) send_cpu_cntr;

    /*
     * Control header and actions for send_to_cpu and drop.
     * (FIXME: need a file commun.p4?)
     */

    action set_cpu_port(PortId_t cpu_port) {
        ig_md.cpu_port = cpu_port;
    }

    table read_cpu_port_table {
        key = {
            ig_md.cpu_port : ternary;
        }
        actions = {
            set_cpu_port;
        }

        default_action = set_cpu_port(1);



        size = 1;
    }

    action add_dp_header() {
        hdr.dp_ctrl.setValid();
        hdr.dp_ctrl.port = ig_intr_md.ingress_port;
        hdr.dp_ctrl.etherType = ETHERTYPE_DP_CTRL;
    }

    action send_to_cpu(){
        /*
         * TODO: Configure metadata when sending packets to CPU
         */
        add_dp_header();
        ig_intr_md_for_tm.ucast_egress_port = ig_md.cpu_port;
        send_cpu_cntr.count();
          exit;
    }

    action send_from_cpu() {
        ig_intr_md_for_tm.ucast_egress_port = hdr.dp_ctrl.port;
        exit;
    }

    action drop_pkt_ingress() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_drp_cntr.count();
          exit;
    }

    //-----------------------------------------------------------------------------------------------------
    //               GTP Tables
    //-----------------------------------------------------------------------------------------------------

    action forward(PortId_t eg_port) {
        /*
         * TODO: should we set vlan ID for egress packet? If so it should be set
         * in egress.
         */
         ig_intr_md_for_tm.ucast_egress_port = eg_port;
    }

    table ul_dl_session_table {
        key = {
            // TODO: adapt to IPv6
            ig_intr_md.ingress_port : exact;
            hdr.vlan.vlanId : exact;
            hdr.outer_ipv4.dstAddr : exact;
            hdr.gtp_u.teid : exact;
        }
        actions = {
            // policy_lookup;
            forward;
            NoAction;
        }
        size = 100;
        default_action = NoAction;
    }

    table flow_table {
        key = {
            // TODO: adapt to IPv6
            ig_intr_md.ingress_port : exact;
            hdr.vlan.vlanId : exact;
            hdr.outer_ipv4.srcAddr : exact;
            hdr.outer_ipv4.dstAddr : exact;
            ig_md.dlSrcPort : exact;
            ig_md.dlDstPort : exact;
            hdr.outer_ipv4.protocol : exact;
        }
        actions = {
            NoAction;
        }
        size = 100;
        default_action = NoAction;
    }

    table policy_table {
        key = {
            ig_intr_md.ingress_port : exact;
            hdr.vlan.vlanId : exact;
            hdr.outer_ipv4.srcAddr : ternary;
            hdr.outer_ipv4.protocol : ternary;
            ig_md.dlSrcPort : ternary;
            ig_md.dlDstPort : ternary;
        }
        actions = {
            // ul_drop;
            // ul_fwd;
            // dl_policy;
            forward;
            NoAction;
        }
        size = 100;
        default_action = NoAction;
    }

    //-----------------------------------------------------------------------------------------------------
    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.ingress_port = ig_intr_md.ingress_port;
        hdr.bridged_md.vlanId = hdr.vlan.vlanId;
        hdr.bridged_md.srcPort = ig_md.dlSrcPort;
        hdr.bridged_md.dstPort = ig_md.dlDstPort;
        hdr.bridged_md.protocol = hdr.outer_ipv4.protocol;
        hdr.bridged_md.srcAddr = hdr.outer_ipv4.srcAddr;
        hdr.bridged_md.dstAddr = hdr.outer_ipv4.dstAddr;
        hdr.bridged_md.teid = hdr.gtp_u.teid;
    }


    apply {
        switch(ul_dl_session_table.apply().action_run){
            NoAction: {
                read_cpu_port_table.apply();
                if (ig_intr_md.ingress_port == ig_md.cpu_port) {
                    send_from_cpu();
                } else {
                    send_to_cpu();
                }
            }
        }
        // Only add bridged metadata if we are NOT bypassing egress pipeline.
        add_bridged_md();
    }
}

//=============================================================================
// Egress control
//=============================================================================
control UPFEgress(
        inout headers hdr,
        inout upf_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    Uplink() uplink;
    Downlink() downlink;

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) eg_drp_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) dl_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ul_cntr;

    // Should be in commun.p4 ?
    action drop_pkt_egress() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1; // Drop packet.
        eg_drp_cntr.count();
        exit;
    }

    apply {
        if (hdr.dp_ctrl.isValid() && hdr.ethernet.isValid()) {
            hdr.dp_ctrl.setInvalid();
        } else if (hdr.gtp_u.isValid()) {
            ul_cntr.count();
            uplink.apply(hdr, eg_md);
        }
        else {
            dl_cntr.count();
            downlink.apply(hdr, eg_md);
        }
    }
}

Pipeline(UPFIngressParser(),
        UPFIngress(),
        UPFIngressDeparser(),
        UPFEgressParser(),
        UPFEgress(),
        UPFEgressDeparser()) pipe;

Switch(pipe) main;
