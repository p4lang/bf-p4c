# 1 "../capture/capture.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "../capture/capture.p4"
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019 Barefoot Networks, Inc.
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
 *
 ******************************************************************************/

#include "core.p4"
#include "tna.p4"

# 28 "../capture/capture.p4" 2


# 1 "../capture/common/util.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2018-2019 Barefoot Networks, Inc.
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
 *
 ******************************************************************************/



parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {



        pkt.advance(64);

        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser<H, M>(
        packet_in pkt,
        out H hdr,
        out M eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser<H, M>(
        packet_out pkt,
        inout H hdr,
        in M eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress<H, M>(
        inout H hdr,
        inout M eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
# 31 "../capture/capture.p4" 2
# 1 "../capture/common/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2018-2019 Barefoot Networks, Inc.

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
 *
 ******************************************************************************/




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_ROCE = 16w0x8915;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

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
    bit<16> hdr_lenght;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
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

/* Global Route Header (Same as IPv6 header) */
header roce_grh_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    ipv6_addr_t srcAddr;
    ipv6_addr_t dstAddr;
}

enum bit<8> roce_opcode_t {
    UC_RDMA_WRITE_ONLY = 0b00101010
}

/* Base Transport Header */
header roce_bth_t {
    roce_opcode_t opcode;
    bit<1> solicitedEvent;
    bit<1> migReq;
    bit<2> padCount;
    bit<4> hdrVersion;
    bit<16> partitionKey;
    bit<24> dstQp;
    bit<8> res1;
    bit<8> res2;
    bit<24> psn;
}

/* RDMA Extended Transport Header */
header roce_reth_t {
    bit<64> virtualAddress;
    bit<32> remoteKey;
    bit<32> dmaLen;
}
# 32 "../capture/capture.p4" 2

enum bit<8> PktType {
    NORMAL = 0,
    CAPTURE = 1
}

struct ig_metadata_t {
    MirrorId_t mirror_session_id;
    PktType pkt_type;
}

struct eg_metadata_t {
    bool do_rdma;
    bit<32> write_addr;
}

header bridged_md_t {
    PktType pkt_type;
}

header mirror_hdr_t {
    PktType pkt_type;
}

struct header_t {
    bridged_md_t bridged_md;
    ethernet_h roce_ethernet;
    roce_grh_t roce_grh;
    roce_bth_t roce_bth;
    roce_reth_t roce_reth;
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    mirror_hdr_t mirror;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ig_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_ROCE : parse_roce;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_roce {
        transition reject;
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out eg_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition select (pkt.lookahead<PktType>()) {
            PktType.NORMAL : parse_bridged;
            PktType.CAPTURE : parse_mirrored;
            default : reject;
        }
    }

    state parse_bridged {
        transition accept;
    }

    state parse_mirrored {
        pkt.extract(hdr.mirror);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ig_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    Mirror() mirror;
    apply {
        if (ig_intr_dprsr_md.mirror_type == 3w1) {
            mirror.emit<mirror_hdr_t>(ig_md.mirror_session_id, {ig_md.pkt_type});
        }
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
    }
}

const bit<32> RDMA_ADDR_INCR = 9000;

control VirtualAddress(inout eg_metadata_t eg_md) {
    Register<bit<32> /* stored type */ , bit<1> /* index */>(32w1) address_reg;
    RegisterAction<bit<32>, bit<1>, bit<32> /* out value */>(address_reg)
    address_reg_alu = {
        void apply(inout bit<32> value, out bit<32> out_value) {
            out_value = value;
            value = out_value + RDMA_ADDR_INCR;
        }
    };
    apply {
        eg_md.write_addr = address_reg_alu.execute(0);
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout ig_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        if (hdr.roce_grh.isValid()) return;
        hdr.bridged_md.setValid();
        hdr.bridged_md.pkt_type = PktType.NORMAL;
        ig_md.pkt_type = PktType.CAPTURE;
        ig_intr_dprsr_md.mirror_type = 1;
        ig_md.mirror_session_id = 1;
    }
}

control SwitchEgress(
        inout header_t hdr,
        inout eg_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {

    action doEncapPacket(mac_addr_t smac, mac_addr_t dmac,
                         ipv6_addr_t src, ipv6_addr_t dst,
                         bit<24> dstQp,
                         bit<64> addrBase,
                         bit<32> remoteKey) {
        hdr.roce_ethernet.setValid();
        hdr.roce_ethernet.dst_addr = dmac;
        hdr.roce_ethernet.src_addr = smac;
        hdr.roce_ethernet.ether_type = ETHERTYPE_ROCE;

        hdr.roce_grh.setValid();
        hdr.roce_grh.version = 6;
        hdr.roce_grh.trafficClass = 0;
        hdr.roce_grh.flowLabel = 0;
        hdr.roce_grh.payloadLen = eg_intr_md.pkt_length + 28;
        hdr.roce_grh.nextHdr = 0x1b;
        hdr.roce_grh.hopLimit = 0xff;
        hdr.roce_grh.srcAddr = src;
        hdr.roce_grh.dstAddr = dst;

        hdr.roce_bth.setValid();
        hdr.roce_bth.opcode = roce_opcode_t.UC_RDMA_WRITE_ONLY;
        hdr.roce_bth.solicitedEvent = 0;
        hdr.roce_bth.migReq = 0;
        hdr.roce_bth.padCount = 0;
        hdr.roce_bth.hdrVersion = 0;
        // default partition (full membership)
        // https://community.mellanox.com/s/article/in-between-ethernet-vlans-and-infiniband-pkeys
        hdr.roce_bth.partitionKey = 0xffff;
        hdr.roce_bth.dstQp = dstQp;
        hdr.roce_bth.res1 = 0;
        hdr.roce_bth.res2 = 0;
        hdr.roce_bth.psn = 0;

        hdr.roce_reth.setValid();
        hdr.roce_reth.virtualAddress = addrBase + (bit<64>)eg_md.write_addr;
        hdr.roce_reth.remoteKey = remoteKey;
        hdr.roce_reth.dmaLen = (bit<32>)eg_intr_md.pkt_length;
    }

    table encapPacket {
        actions = { doEncapPacket; }
    }

    apply {
        if (!hdr.mirror.isValid()) return;
        VirtualAddress.apply(eg_md);
        encapPacket.apply();
    }
}

control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in eg_metadata_t ig_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
        pkt.emit(hdr.roce_ethernet);
        pkt.emit(hdr.roce_grh);
        pkt.emit(hdr.roce_bth);
        pkt.emit(hdr.roce_reth);
    }
}


Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
