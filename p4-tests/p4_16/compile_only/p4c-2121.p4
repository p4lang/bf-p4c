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

#include <t2na.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<8> ip_protocol_t;
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

header mirror_cfg_h {
    PktType pkt_type;
    bit<1> do_ing_mirroring;  // Enable ingress mirroring
    bit<1> do_egr_mirroring;  // Enable egress mirroring
    bit<1> mirror_deflect_on_drop;      // Mirror enable deflection on drop if true.
    bit<1> mirror_copy_to_cpu_ctrl;     // Mirror enable copy-to-cpu if true.
    bit<1> mirror_multicast_ctrl;       // Mirror enable multicast if true.
    bit<1> mirror_io_select;            // Mirror incoming or outgoing packet

    bit<1> _pad1;
    bit<7> mirror_qid;                  // Mirror packet qid.

    MirrorId_t ing_mir_ses;   // Ingress mirror session ID
    MirrorId_t egr_mir_ses;   // Egress mirror session ID

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash;                // Mirror hash field.
    bit<3> mirror_ingress_cos;          // Mirror ingress cos for PG mapping.

    bit<7> _pad2;
    bit<9> mirror_egress_port;          // Mirror packet egress port.
}

struct metadata_t {
    //bit<1> do_ing_mirroring;  // Enable ingress mirroring
    //bit<1> do_egr_mirroring;  // Enable egress mirroring
    //MirrorId_t ing_mir_ses;   // Ingress mirror session ID
    //MirrorId_t egr_mir_ses;   // Egress mirror session ID
    //PktType pkt_type;
    mirror_cfg_h mirror_cfg_hdr;
}

//@flexible
/*
header mirror_bridged_metadata_h {
    PktType pkt_type;
    mirror_cfg_h mirror_cfg_hdr;
    bit<1> do_egr_mirroring;  //  Enable egress mirroring
    MirrorId_t egr_mir_ses;   // Egress mirror session ID
}
*/

/*
header mirror_h {
    mirror_cfg_h mirror_cfg_hdr;
}
*/

struct headers_t {
    //mirror_cfg_h bridged_md;
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;

    // Add more headers here.
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

    state start {
        tofino_parser.apply(pkt, ig_intr_md);

        /*
        ig_md.mirror_cfg_hdr.setValid();
        ig_md.mirror_cfg_hdr.pkt_type = PktType.NORMAL;
        ig_md.mirror_cfg_hdr.do_ing_mirroring = 0;
        ig_md.mirror_cfg_hdr.do_egr_mirroring = 0;
        ig_md.mirror_cfg_hdr.mirror_deflect_on_drop = 0;
        ig_md.mirror_cfg_hdr.mirror_copy_to_cpu_ctrl = 0;
        ig_md.mirror_cfg_hdr.mirror_multicast_ctrl = 0;
        ig_md.mirror_cfg_hdr._pad1 = 0;

        ig_md.mirror_cfg_hdr.mirror_io_select = 0;
        ig_md.mirror_cfg_hdr.mirror_qid = 0;

        ig_md.mirror_cfg_hdr.ing_mir_ses = 0;
        ig_md.mirror_cfg_hdr.egr_mir_ses = 0;

        // Setting the following metadata will override the value in mirror table
        ig_md.mirror_cfg_hdr.mirror_hash = 0;
        ig_md.mirror_cfg_hdr.mirror_ingress_cos = 0;

        ig_md.mirror_cfg_hdr._pad2 = 0;
        ig_md.mirror_cfg_hdr.mirror_egress_port = 0;
        */

        transition parse_ethernet;
    }

    state parse_ethernet {
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
        pkt.extract(ig_md.mirror_cfg_hdr);

        transition accept;
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

        pkt.emit(hdr);
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

    action set_mirror_type() {
        ig_dprsr_md.mirror_type = (bit<4>) MirrorType.I2E;
        ig_md.mirror_cfg_hdr.pkt_type = PktType.MIRROR;
    }

    action set_normal_pkt() {
        ig_md.mirror_cfg_hdr.pkt_type = PktType.NORMAL;
    }

    action set_md(PortId_t dest_port, 
                  bit<1> ing_mir, 
                  MirrorId_t ing_ses, 
                  bit<1> egr_mir, 
                  MirrorId_t egr_ses) {
        ig_tm_md.ucast_egress_port = dest_port;
        ig_md.mirror_cfg_hdr.do_ing_mirroring = ing_mir;
        ig_md.mirror_cfg_hdr.ing_mir_ses = ing_ses;
        ig_md.mirror_cfg_hdr.do_egr_mirroring = egr_mir;
        ig_md.mirror_cfg_hdr.egr_mir_ses = egr_ses;
    }

    table  mirror_fwd {
        key = {
            ig_intr_md.ingress_port  : exact;
        }

        actions = {
            set_md;
        }

        size = 512;
    }

    apply {
        if (ig_intr_md.resubmit_flag == 0) {
            mirror_fwd.apply();
        }

        if (ig_md.mirror_cfg_hdr.do_ing_mirroring == 1) {
            set_mirror_type();
        }

        set_normal_pkt();
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
        pkt.extract(eg_md.mirror_cfg_hdr);
        transition parse_ethernet;
    }

    state parse_mirror_md {
        //mirror_cfg_h mirror_md;
        pkt.extract(eg_md.mirror_cfg_hdr);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
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

    action set_mirror() {
        eg_md.mirror_cfg_hdr.pkt_type = PktType.MIRROR;
        eg_dprsr_md.mirror_type = (bit<4>) MirrorType.E2E;
        eg_dprsr_md.mirror_io_select = (bit<1>) MirrorPktSelect.OUT; // E2E mirroring for Tofino2 & future ASICs
    }

    apply {
        if (eg_md.mirror_cfg_hdr.do_egr_mirroring == 1) {
            set_mirror();
        }
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
            mirror.emit(eg_md.mirror_cfg_hdr.egr_mir_ses, eg_md.mirror_cfg_hdr);
        }

        pkt.emit(hdr.ethernet);
        pkt.emit(eg_md.mirror_cfg_hdr);
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
