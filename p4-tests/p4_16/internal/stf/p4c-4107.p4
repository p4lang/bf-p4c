/*
 * The program triggers the following error when egress tables created in
 * the InsertTableToResetInvalidatedHeaders pass in post-midend are inserted
 * into an ingress table sequence. The error reads:
 *
 * Compiler Bug: TableSeq consists of tables of different gress?
 *
 * The following conditions must be satisfied to trigger the error:
 *
 * 1. The program is compiled for Tofino 1.
 * 2. Egress->ingress bridging with @flexible is used
 *    (emit in ingress, extract in egress).
 * 3. Checksum is computed for a header, which may be invalidated
 *    (there is header.setInvalid() called somewhere in the program).
 * 4. The checksum is stored in another header than it is computed
 *    for.
 *
 * The folded pipeline looks like this:
 *
 * pipe0ingress -> pipe1egress -> bridged metadata here -> pipe1ingress -> pipe0egress
 *
 * See the comment in the STF file for checksum computation.
 */

#include <tna.p4>       /* TOFINO1_ONLY */

header header1_h {
    bit<32> data;  // Used to track the progress of a packet thru the folded pipeline
    bit<16> csum;
}

header header2_h {
    bit<32> data;
}

@flexible
header bridged_metadata_h {
    bit<32> data;
}

struct ingress_metadata_t {
}

struct egress_metadata_t {
}

struct header_t {
    bridged_metadata_h bridged_md;
    header1_h header1;
    header2_h header2;
}

// pipe0ingress

parser IngressParser0(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        pkt.extract(hdr.header1);
        pkt.extract(hdr.header2);
        transition accept;
    }
}

control Ingress0(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    apply {
        hdr.header1.data = hdr.header1.data | 0x00000010;
        ig_intr_md_for_tm.ucast_egress_port = 128;  // pipe0ingress -> pipe1egress
    }
}

control IngressDeparser0(
    packet_out pkt,
    inout header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.header1);
        pkt.emit(hdr.header2);
    }
}

// pipe1egress

parser EgressParser1(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.header1);
        pkt.extract(hdr.header2);
        transition accept;
    }
}

control Egress1(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply {
        hdr.header2.setInvalid();
        hdr.bridged_md.setValid();
        hdr.bridged_md.data = 0x01234567;
        hdr.header1.data = hdr.header1.data | 0x00001000;
    }
}

control EgressDeparser1(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() checksum;

    apply {
        hdr.header1.csum = checksum.update({hdr.header1.data, hdr.header2.data});
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.header1);
        pkt.emit(hdr.header2);
    }
}

// pipe1ingress

parser IngressParser1(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        pkt.extract(hdr.bridged_md);
        pkt.extract(hdr.header1);
        transition accept;
    }
}

control Ingress1(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    apply { 
        hdr.header1.data = hdr.header1.data | 0x00100000;
        ig_intr_md_for_tm.ucast_egress_port = 0;  // Ingress1 -> Egress0
    }
}

control IngressDeparser1(
    packet_out pkt,
    inout header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.header1);
    }
}

// pipe0egress

parser EgressParser0(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.header1);
        transition accept;
    }
}

control Egress0(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply {
        hdr.header1.data = hdr.header1.data | 0x10000000;
    }
}

control EgressDeparser0(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.header1);
    }
}

Pipeline(IngressParser0(),
         Ingress0(),
         IngressDeparser0(),
         EgressParser0(),
         Egress0(),
         EgressDeparser0()) pipe0;

Pipeline(IngressParser1(),
         Ingress1(),
         IngressDeparser1(),
         EgressParser1(),
         Egress1(),
         EgressDeparser1()) pipe1;

Switch(pipe0, pipe1) main;
