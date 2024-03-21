/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

#include <core.p4>
#include <t2na.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

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
    bit<16> hdr_length;
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

struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;

    // Add more headers here.
}

struct empty_header_t {}

struct empty_metadata_t {}

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
        pkt.advance(PORT_METADATA_SIZE);
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
parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

// From https://github.com/barefootnetworks/bf-p4c-compilers/blob/master/bf-p4c/p4include/tofino2.p4
    // bit<4> mirror_type;

    // bit<1> coalesce_flush;              // Flush the coalesced mirror buffer

    // bit<7> coalesce_length;             // The number of bytes in the current
    //                                     // packet to collect in the mirror
    //                                     // buffer

    // bit<1> mirror_io_select;            // Mirror incoming or outgoing packet

    // // Setting the following metadata will override the value in mirror table
    // bit<13> mirror_hash;                // Mirror hash field.
    // bit<3> mirror_ingress_cos;          // Mirror ingress cos for PG mapping.
    // bit<1> mirror_deflect_on_drop;      // Mirror enable deflection on drop if true.
    // bit<1> mirror_copy_to_cpu_ctrl;     // Mirror enable copy-to-cpu if true.
    // bit<1> mirror_multicast_ctrl;       // Mirror enable multicast if true.
    // bit<9> mirror_egress_port;          // Mirror packet egress port.
    // bit<7> mirror_qid;                  // Mirror packet qid.
    // bit<8> mirror_coalesce_length;      // Mirror coalesced packet max sample
    //                                     // length. Unit is quad bytes.

enum bit<2> PktType {
    INGRESS = 0,
    NORMAL = 1,
    MIRROR = 2
}

enum bit<4> MirrorType {
    I2E = 1,
    E2E = 2
}

enum bit<1> MirrorPktSelect {
    IN = 0,
    OUT = 1
}

enum bit<7> PipeProcessState {
    NONE = 0,
    ING_PRSR = 1,
    ING_MAU = 2,
    EGR_PSR = 3,
    EGR_MAU = 4
}


header mirror_cfg_h {
    PktType pkt_type;
    bit<1> do_ing_mirroring;            // Enable ingress mirroring
    bit<1> do_egr_mirroring;            // Enable egress mirroring
    bit<1> mirror_deflect_on_drop;      // Mirror enable deflection on drop if true.
    bit<1> mirror_copy_to_cpu_ctrl;     // Mirror enable copy-to-cpu if true.
    bit<1> mirror_multicast_ctrl;       // Mirror enable multicast if true.
    bit<1> ing_mirror_io_select;        // Mirror incoming or outgoing packet
    bit<1> egr_mirror_io_select;        // Mirror incoming or outgoing packet
    bit<7> mirror_qid;                  // Mirror packet qid.

    MirrorId_t ing_mir_ses;             // Ingress mirror session ID
    MirrorId_t egr_mir_ses;             // Egress mirror session ID

    bit<7> pipe_process_state;          // Track the path of the packet through the pipeline
    bit<9> mirror_egress_port;          // Mirror packet egress port

    bit<13> mirror_hash;                // Mirror hash field.
    bit<3> mirror_ingress_cos;          // Mirror ingress cos for PG mapping
}

header test_h {
    bit<16> test;
}

header bridged_h {
    PktType pkt_type;
    bit<6> _pad;
}

struct metadata_t {
    mirror_cfg_h mirror_cfg_hdr;
    test_h test_hdr1;
    test_h test_hdr2;
    bridged_h bridged_md;
    PktType pkt_type;
}

struct headers_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    mirror_cfg_h mirror_cfg_hdr;
}

parser MirrorCfgHdrParser(packet_in pkt,
                         inout headers_t hdr,
                         inout metadata_t ig_md) {
    state start {
        pkt.extract(hdr.ethernet);

        transition select(hdr.ethernet.ether_type) {
            0x0800: parse_ipv4;
            default: reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_UDP: parse_udp;
            default: reject;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);

        transition select(hdr.udp.dst_port) {
            0xabcd: parse_mirror_cfg;
            default: reject;
        }
    }

    state parse_mirror_cfg {
        pkt.extract(hdr.mirror_cfg_hdr);
#if 0
        hdr.mirror_cfg_hdr.pipe_process_state = (bit<7>) PipeProcessState.ING_PRSR;
#endif
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Counters for in-data plane self checking
// ---------------------------------------------------------------------------

control MirrorTestStats(in egress_intrinsic_metadata_t eg_intr_md,
                        in metadata_t eg_md) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter;

    table per_port_stats {
        key = {
            eg_intr_md.egress_port : exact;
            eg_md.pkt_type : exact;
        }

        actions = {}
    }

    apply {
    }
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out headers_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;
    MirrorCfgHdrParser() mirror_cfg_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        mirror_cfg_parser.apply(pkt, hdr, ig_md);

        transition accept;
    }

}

// ---------------------------------------------------------------------------
// Switch Ingress MAU
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout headers_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply {
        ig_md.mirror_cfg_hdr = hdr.mirror_cfg_hdr;

        if (ig_intr_md.resubmit_flag == 0) {
            ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        }

        if (ig_md.mirror_cfg_hdr.do_ing_mirroring == 1) {
            ig_dprsr_md.mirror_type = (bit<4>) MirrorType.I2E;
            ig_md.mirror_cfg_hdr.pkt_type = PktType.MIRROR;
            ig_dprsr_md.mirror_io_select = ig_md.mirror_cfg_hdr.ing_mirror_io_select;
        }
//        ig_md.test_hdr1.setValid();
//        ig_md.test_hdr1.test = 0xeffe;
//        ig_md.test_hdr2.setValid();
//        //ig_md.test_hdr2.test = 0xfeef;
//        ig_md.test_hdr2.test = hdr.mirror_cfg_hdr.minSizeInBits();

        hdr.mirror_cfg_hdr.pipe_process_state = (bit<7>) PipeProcessState.ING_MAU;
        ig_md.bridged_md.setValid();
        ig_md.bridged_md.pkt_type = PktType.NORMAL;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout headers_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() mirror;

    apply {

        if (ig_dprsr_md.mirror_type == (bit<4>) MirrorType.I2E) {
            mirror.emit(ig_md.mirror_cfg_hdr.ing_mir_ses, ig_md.mirror_cfg_hdr);
        }

        //pkt.emit(ig_md.test_hdr1);
        //pkt.emit(hdr.mirror_cfg_hdr);
        //pkt.emit(ig_md.test_hdr2);
        //pkt.emit<bridged_md>({PktType.NORMAL});
        pkt.emit(ig_md.bridged_md);
        pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out headers_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;
    MirrorCfgHdrParser() mirror_cfg_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition parse_metadata;
    }

    state parse_metadata {
        PktType pkt_type = pkt.lookahead<PktType>();
        transition select(pkt_type) {
            PktType.MIRROR : parse_mirror_md;
            PktType.NORMAL : parse_bridged_md;
            default : accept;
        }
    }

    state parse_bridged_md {
        pkt.extract(eg_md.bridged_md);
        eg_md.pkt_type = eg_md.bridged_md.pkt_type;
        transition parse_mirror_cfg;
    }

    state parse_mirror_md {
        pkt.extract(eg_md.mirror_cfg_hdr);
        eg_md.pkt_type = eg_md.mirror_cfg_hdr.pkt_type;
        transition parse_mirror_cfg;
    }

    state parse_mirror_cfg {
        mirror_cfg_parser.apply(pkt, hdr, eg_md);

        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Switch Egress MAU
// ---------------------------------------------------------------------------
control SwitchEgress(
        inout headers_t hdr,
        inout metadata_t eg_md,
        in    egress_intrinsic_metadata_t                 eg_intr_md,
        in    egress_intrinsic_metadata_from_parser_t     eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t    eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

    apply {
        if (eg_md.mirror_cfg_hdr.pkt_type == PktType.NORMAL) {
            if (hdr.mirror_cfg_hdr.do_egr_mirroring == 1) {
                eg_dprsr_md.mirror_type = (bit<4>) MirrorType.E2E;
                eg_md.mirror_cfg_hdr.pkt_type = PktType.MIRROR;
                //eg_dprsr_md.mirror_io_select = eg_md.mirror_cfg_hdr.egr_mirror_io_select;
                eg_dprsr_md.mirror_io_select = hdr.mirror_cfg_hdr.egr_mirror_io_select;
            }
            hdr.mirror_cfg_hdr.pipe_process_state = (bit<7>) PipeProcessState.EGR_MAU;
        } else if (eg_md.mirror_cfg_hdr.pkt_type == PktType.MIRROR) {
        }

        eg_md.test_hdr1.setValid();
        eg_md.test_hdr1.test = 0xffff;
    }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout headers_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    Mirror() mirror;

    apply {

        if (eg_dprsr_md.mirror_type == (bit<4>) MirrorType.E2E) {
            mirror.emit(eg_md.mirror_cfg_hdr.egr_mir_ses, hdr.mirror_cfg_hdr);
        }

        pkt.emit(hdr);
        //pkt.emit(eg_md.test_hdr);
        //pkt.emit(eg_md.mirror_cfg_hdr);
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
