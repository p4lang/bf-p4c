/*******************************************************************************
 *
 *  parser_scratch_reg_3.p4
 *
 *  Targets: tofino2, tofino3
 *
 ******************************************************************************/
#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#else
#include <t2na.p4>
#endif

header fpga_prefix_t {
    bit<8>  type;
    bit<8>  f1;
    bit<8>  f2;
    bit<8>  f3;
    bit<32> f4;
    bit<32> f5;
    bit<32> f6;
    bit<32> f7;
    bit<32> f8;
    bit<32> f9;
    bit<32> f10;
}

header fabric_base_t {
    bit<8>  pkt_type;
    bit<8>  pad0;
    bit<8>  pkt_sub_type;
    bit<8>  pad1;
    bit<8>  pkt_sub_sub_type;
    bit<8>  pad2;
    bit<8>  pkt_sub_sub_sub_type;
    bit<8>  pad3;
}

header fabric_qos_t {
    bit<1> BA;
    bit<1> chgDSCP_disable;
    bit<2> color;
    bit<3> tc;
    bit<1> track;
}

header fabric_igfpga_2_t {
    bit<16> f1;
    bit<16> f2;
    bit<16> f3;
    bit<16> f4;
}

header fabric_igfpga_3_t {
    bit<32> f0;
    bit<32> f1;
    bit<16> f2;
    bit<8>  f3;
    bit<24> f3_;
}

header fabric_igfpga_3a_t {
    bit<8>  f1;
    bit<8>  f2;
}

header fabric_igfpga_4_t {
    bit<32> f1;
    bit<32> f2;
}

struct metadata_t {
}

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    bit<32>   srcAddr;
    bit<32>   dstAddr;
}

header ipv6_t {
    bit<4>      version;
    bit<8>      trafficClass;
    bit<20>     flowLabel;
    bit<16>     payloadLen;
    bit<8>      nextHdr;
    bit<8>      hopLimit;
    bit<128>    srcAddr;
    bit<128>    dstAddr;
}

struct header_t {
    fpga_prefix_t       fpga_prefix;
    fabric_base_t       fabric_base;
    fabric_qos_t        fabric_qos;
    fabric_igfpga_2_t   fabric_igfpga_2;
    fabric_igfpga_3_t   fabric_igfpga_3;
    fabric_igfpga_3a_t  fabric_igfpga_3a;
    fabric_igfpga_4_t   fabric_igfpga_4;
    ethernet_t          ethernet;
    ipv4_t              ipv4;
    ipv6_t              ipv6;
}

// ---------------------------------------------------------------------------
// Ingress Parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_igfpga_packet;
    }

    state parse_igfpga_packet {
        pkt.extract(hdr.fabric_base);
        pkt.extract(hdr.fabric_qos);
        transition select(hdr.fabric_base.pkt_type) {
            0x80: parse_fabric_ig_ext_0;
            default: accept;
        }
    }

    state parse_fabric_ig_ext_0 {
        pkt.extract(hdr.fabric_igfpga_3);
        transition select(hdr.fabric_igfpga_3.f0) {
            0x9f000000: parse_fabric_ig_ext_1;
            0xa0000000: parse_fabric_uc_end;
            default: accept;
        }
    }

    state parse_fabric_ig_ext_1 {
        pkt.extract(hdr.fabric_igfpga_3a);
        transition select(hdr.fabric_igfpga_3a.f1) {
            0xbb: parse_fabric_uc_end;
            default: accept;
        }
    }

    state parse_fabric_uc_end {
        transition select(hdr.fabric_base.pkt_type,
                          hdr.fabric_base.pkt_sub_type,
                          hdr.fabric_base.pkt_sub_sub_type,
                          hdr.fabric_base.pkt_sub_sub_sub_type) {
            (0x1, 0x2, 0x3, 0x4) : parse_ipv4;
            (0x80, 0x2, 0x3, 0x4) : parser_igfpga_eth_ac;
            default: accept;
        }
    }

    state parser_igfpga_eth_ac {
        pkt.extract(hdr.fabric_igfpga_4);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action hit() {
        hdr.ethernet.dst_addr = hdr.ethernet.src_addr;
    }
    table table1 {
        key = {
            hdr.ethernet.dst_addr: exact;
            hdr.ethernet.src_addr: exact;
            hdr.ipv4.srcAddr: exact;
            hdr.ipv4.dstAddr: exact;
            hdr.ipv6.srcAddr: exact;
            hdr.ipv6.dstAddr: exact;
            ig_intr_md.ingress_port: exact;
        }
        actions = {
            hit;
            NoAction;
        }
    }

    table fpga1 {
        key = {
            hdr.fabric_base.pkt_type: exact;
            hdr.fabric_igfpga_2.f1: exact;
            hdr.fabric_igfpga_2.f2: exact;
            hdr.fabric_igfpga_2.f3: exact;
            hdr.fabric_igfpga_2.f4: exact;
            hdr.fabric_igfpga_3.f1: exact;
            hdr.fabric_igfpga_3.f2: exact;
            hdr.fabric_igfpga_4.f1: exact;
            hdr.fabric_igfpga_4.f2: exact;
        }
        actions = {
            hit;
            NoAction;
        }
    }

    action bridge_add_example_hdr(bit<16> dst_mac_addr_low,
                                  bit<16> src_mac_addr_low) {
    }

    table bridge_md_ctrl {
        actions = {
            NoAction;
            bridge_add_example_hdr;
        }

        default_action = NoAction;
    }

    action ethernet_parsed() {
        ig_tm_md.ucast_egress_port = 4;
    }

    action ethernet_parsed_with_fpga3a() {
        ig_tm_md.ucast_egress_port = 8;
    }

    action ethernet_not_parsed() {}

    table forward_if_ethernet_parsed {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.fabric_igfpga_3a.isValid() : exact;
        }

        actions = {
            ethernet_parsed;
            ethernet_parsed_with_fpga3a;
            ethernet_not_parsed;
        }

        default_action = ethernet_not_parsed;

        const entries = {
            (false, false) : ethernet_not_parsed;
            (true, false) : ethernet_parsed;
            (true, true) : ethernet_parsed_with_fpga3a;
        }
    }

    apply {
        table1.apply();
        fpga1.apply();
        forward_if_ethernet_parsed.apply();

    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md
                              ) {
    apply {
        pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Egress Parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Egress
// ---------------------------------------------------------------------------
control SwitchEgress(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply {}
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t eg_md,
                              in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}


Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe;

Switch(pipe) main;
