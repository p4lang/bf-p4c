/* -*- P4_16 -*- */
#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

#define PORT_CPU 64

/*************************************************************************
*********************** H E A D E R S ***********************************
*************************************************************************/

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header common_t {
    bit<2> currINF;
    bit<6> currHF;
    bit value;
    bit<7> reserved;
    bit<32> data;
}

header common2_t{
    bit<8> data;
}

header tail_t {
    bit<16> data;
}

struct header_t {
    ethernet_t eth;
    common_t common;
    common2_t common2;
    tail_t tail;
}

struct metadata_t {
    bit value;
}

parser ImplInParser(
    packet_in packet,
    out header_t hdr,
    out metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        ig_md.value = 0;

        // Extract metadata and skip over recirculation info
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);

        packet.extract(hdr.eth);
        packet.extract(hdr.common);

        transition select(hdr.common.currINF, hdr.common.currHF) {
            (0, 1): selected;
            default: final;
        }
    }

    state selected {
        ig_md.value = hdr.common.value;
        transition final;
    }

    state final_1 {
        packet.extract(hdr.tail);
        transition accept;
    }

    state final {
        packet.extract(hdr.tail);
        transition accept;
    }
}

parser ImplEParser(
    packet_in packet,
    out header_t hdr,
    out metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

/*************************************************************************
************** I N G R E S S P R O C E S S I N G *******************
*************************************************************************/


control ImplIngress(
    inout header_t hdr,
    inout metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    apply {
        if (ig_md.value == 0) {
            send(0);
        } else {
            send(1);
        }
        ig_tm_md.bypass_egress = 1w1;
    }
}

/*************************************************************************
 **************** E G R E S S   P R O C E S S I N G *******************
 *************************************************************************/

control ImplEgress(
    inout header_t hdr,
    inout metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {


    apply {
    }
}

/*************************************************************************
*********************** D E P A R S E R *******************************
*************************************************************************/

control ImplInDeparser(
    packet_out packet,
    inout header_t hdr,
    in metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        packet.emit<header_t>(hdr);
    }
}

control ImplEDeparser(
    packet_out packet,
    inout header_t hdr,
    in metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    apply {
        packet.emit(hdr);
    }
}

/*************************************************************************
*********************** S W I T C H *******************************
*************************************************************************/
Pipeline(ImplInParser(),
    ImplIngress(),
    ImplInDeparser(),
    ImplEParser(),
    ImplEgress(),
    ImplEDeparser()) pipe;

Switch(pipe) main;
