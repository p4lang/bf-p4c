/*******************************************************************************
 *
 *  parser_scratch_reg_5.p4
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

header fabric_base_t {
    bit<6>  pkt_type;
    bit<1>  is_mirror;
    bit<1>  is_mcast;
}

header fabric_qos_t {
    bit<1> BA;
    bit<1> chgDSCP_disable;
    bit<2> color;
    bit<3> tc;
    bit<1> track;
}

header fabric_igfpga_2_t {
    bit<1> extend;
    bit<1> from_cpu;
    bit<1> diag;
    bit<1> tstamp_flag;
    bit<1> svi_flag;
    bit<1> gleaned;
    bit<1> vflag1;
    bit<1> vflag2;
    bit<8> src_port;
}

header fabric_igfpga_3_t {
    bit<32> f0;
    bit<32> f1;
    bit<32> f2;
    bit<8>  f3;
    bit<24> f3_;
}

header fabric_igfpga_3a_t {
    bit<3>  f0;
    bit<5>  f0_;
    bit<8>  f1;
}

header fabric_igfpga_4_t {
    bit<8> f0;
    bit<8> f1;
}

header fabric_tunnel_ext_t {
    bit<8> f0;
    bit<8> f1;
}

header fabric_nexthop_ext_t {
    bit<8> f0;
    bit<8> f1;
    bit<8> f2;
    bit<8> f3;
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
    fabric_base_t       fabric_base;
    fabric_qos_t        fabric_qos;
    fabric_igfpga_2_t   fabric_igfpga_2;
    fabric_igfpga_3_t   fabric_igfpga_3;
    fabric_igfpga_3a_t  fabric_igfpga_3a;
    fabric_igfpga_4_t   fabric_igfpga_4;
    fabric_tunnel_ext_t fabric_tunnel_ext;
    fabric_nexthop_ext_t fabric_nexthop;
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
        transition select(  hdr.fabric_base.pkt_type,
                            hdr.fabric_base.is_mcast) {
            (0x01, 1) : parse_igfpga_ipmc;
            (0x02, 1) : parse_igfpga_ipmc;
            (0x04, 0) : parse_igfpga_eth_uc;
            (0x04, 1) : parse_igfpga_eth_bc;
            (0x20, 0) : parse_igfpga_eth_ac_uc;
            (0x20, 1) : parse_igfpga_eth_ac_bc;
            default: accept;
        }
    }

    state parse_igfpga_ipmc {
        pkt.extract(hdr.fabric_igfpga_2);
        transition parse_ethernet;
    }

    state parse_igfpga_eth_uc {
        pkt.extract(hdr.fabric_igfpga_2);
        transition select(hdr.fabric_igfpga_2.extend) {
            1: parse_fabric_ig_ext_0;
            default: parse_fabric_uc_end;
        }
    }

    state parse_igfpga_eth_bc {
        pkt.extract(hdr.fabric_igfpga_2);
        transition select(hdr.fabric_igfpga_2.extend) {
            1: parse_fabric_ig_ext_0;
            default: parse_fabric_uc_end;
        }
    }

    state parse_igfpga_eth_ac_uc {
        pkt.extract(hdr.fabric_igfpga_2);
        transition select(hdr.fabric_igfpga_2.extend) {
            1: parse_fabric_ig_ext_0;
            default: parser_igfpga_eth_ac;
        }
    }

    state parse_igfpga_eth_ac_bc {
        pkt.extract(hdr.fabric_igfpga_2);
        transition select(hdr.fabric_igfpga_2.extend) {
            1: parse_fabric_ig_ext_0;
            default: parser_igfpga_eth_ac;
        }
    }

    state parse_fabric_ig_ext_0 {
        pkt.extract(hdr.fabric_igfpga_3);
        transition select(hdr.fabric_igfpga_3.f0) {
            // 6: parse_extension_l5encap;
            1: parse_extension_nexthop;
            0: parse_extension_tunnel_decap;
            // 4: parse_extension_flow_spec;
            3: parse_fabric_uc_end;
            2: parse_fabric_uc_end;
            default: accept;
        }
    }

    state parse_fabric_ig_ext_1 {
        pkt.extract(hdr.fabric_igfpga_3a);
        transition select(hdr.fabric_igfpga_3a.f0) {
            0 : parse_extension_tunnel_decap;
            3 : parse_fabric_uc_end;
            default: accept;
        }
    }

    state parse_extension_nexthop {
        pkt.extract(hdr.fabric_nexthop);
        transition select( hdr.fabric_nexthop.f0) {
            0: parse_ethernet;
            1: parse_ipv4;
            2: parse_ipv6;
            default: accept;
        }
    }

    state parse_extension_tunnel_decap {
        pkt.extract(hdr.fabric_tunnel_ext);
        transition select( hdr.fabric_tunnel_ext.f0) {
            0: parse_ethernet;
            1: parse_ipv4;
            2: parse_ipv6;
            default: accept;
        }
    }

    state parse_fabric_uc_end {
        transition select(  hdr.fabric_base.pkt_type,
                            hdr.fabric_base.is_mcast) {
            (0x04, 0) : parse_ethernet;
            (0x01, 0) : parse_ipv4;
            (0x03, 0) : parse_ipv6;
            (0x20, 0) : parser_igfpga_eth_ac;
            (_, 1)    : parse_ethernet;
            default   : accept;
        }
    }

    state parser_igfpga_eth_ac {
        pkt.extract(hdr.fabric_igfpga_4);
        transition select(hdr.fabric_igfpga_4.f0) {
            1: parse_ethernet;
            default: accept;
        }
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x800: parse_ipv4;
            0x86dd: parse_ipv6;
            default: accept;
        }
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
            hdr.fabric_igfpga_2.extend: exact;
            hdr.fabric_igfpga_2.from_cpu: exact;
            hdr.fabric_igfpga_2.diag: exact;
            hdr.fabric_igfpga_2.tstamp_flag: exact;
            hdr.fabric_igfpga_2.svi_flag: exact;
            hdr.fabric_igfpga_2.gleaned: exact;
            hdr.fabric_igfpga_2.vflag1: exact;
            hdr.fabric_igfpga_2.vflag2: exact;
            hdr.fabric_igfpga_2.src_port: exact;
            hdr.fabric_igfpga_3.f0: exact;
            hdr.fabric_igfpga_3.f1: exact;
            hdr.fabric_igfpga_4.f0: exact;
            hdr.fabric_igfpga_4.f1: exact;
        }
        actions = {
            hit;
            NoAction;
        }
    }

    action fabric_igfpga_4_not_parsed() {}

    action fabric_igfpga_4_parsed() {
        ig_tm_md.ucast_egress_port = 4;
    }

    table check_fabric_igfpga_4 {
        key = {
            hdr.fabric_igfpga_4.isValid(): exact;
        }
        actions = {
            fabric_igfpga_4_not_parsed;
            fabric_igfpga_4_parsed;
        }
        const entries = {
            false: fabric_igfpga_4_not_parsed;
            true: fabric_igfpga_4_parsed;
        }
    }

    apply {
        table1.apply();
        fpga1.apply();
        check_fabric_igfpga_4.apply();
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
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
                              in egress_intrinsic_metadata_for_deparser_t
                                eg_intr_dprsr_md
                              ) {

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
