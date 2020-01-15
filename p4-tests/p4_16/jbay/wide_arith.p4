#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#error Unsupported target
#endif

typedef bit<128> ipv6_addr_t;

header ethernet_h {
    bit<48> dst_addr;
    bit<48> src_addr;
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
    bit<32> src_addr;
    bit<32> dst_addr;
}

header ptp_h {
    bit<4> transport_specific;
    bit<4> type;
    bit<4> reserved;
    bit<4> version;
    bit<16> length;
    bit<8> domain_number;
    bit<8> reserved2;
    bit<16> flags;
    // ...
}

header ptp_correction_field_t {
    bit<64> correction_field;
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

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

struct switch_header_t {
    ptp_metadata_t ptp_md; // Defined in tofino.p4
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    udp_h udp;
    ptp_h ptp;
    ptp_correction_field_t ptp_correction_field;
}

struct switch_metadata_t {
    bit<64> timestamp;
    bit<16> udp_checksum;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    Checksum() udp_checksum;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            0x88F7 : parse_ptp;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            17 : parse_udp;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        udp_checksum.subtract(hdr.udp.checksum);
        transition select(hdr.udp.dst_port) {
            319 : parse_ptp;
            default : accept;
        }
    }

    state parse_ptp {
        pkt.extract(hdr.ptp);
        pkt.extract(hdr.ptp_correction_field);
        udp_checksum.subtract(hdr.ptp_correction_field.correction_field);
        ig_md.udp_checksum = udp_checksum.get();
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(packet_out pkt,
                              inout switch_header_t hdr,
                              in switch_metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { pkt.emit(hdr); }
}

// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(packet_out pkt,
                             inout switch_header_t hdr,
                             in switch_metadata_t eg_md,
                             in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}


control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {


    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;

        // Make a copy of the MAC timestamp. This is needed to make sure the upper 16 bits are zero.
        ig_md.timestamp = (bit<64>) ig_intr_md.ingress_mac_tstamp;

        // Update PTP correction field.
        if (hdr.ptp.isValid())
            hdr.ptp_correction_field.correction_field =
                hdr.ptp_correction_field.correction_field - ig_md.timestamp;
    }
}


control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
        if (hdr.ptp.isValid()) {
            // Insert PTP metadata ahead of the ethernet header.
            hdr.ptp_md.setValid();
            hdr.ptp_md.cf_byte_offset = 50;
            hdr.ptp_md.udp_cksum_byte_offset = 40;
            hdr.ptp_md.updated_cf = (bit<48>) hdr.ptp_correction_field.correction_field;

            // Remove PTP correction field
            hdr.ptp_correction_field.setInvalid();
        }
    }
}

Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe;

Switch(pipe) main;
