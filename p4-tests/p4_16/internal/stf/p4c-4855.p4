#include <core.p4>
#include <tna.p4>

header ipv4_t {
    bit<8> f;
    bit<8> b1;
}

header meta_t {
}
struct header_t {
    ipv4_t ipv4;
}
struct metadata_t {
    meta_t meta;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser IngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control IngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}

control Ingress1(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action a8bit_add(bit<8> value)      { hdr.ipv4.b1 =  hdr.ipv4.b1 +  value; }
    action a8bit_bit_and(bit<8> value)  { hdr.ipv4.b1 =  hdr.ipv4.b1 &  value; }
    action a8bit_bit_andca(bit<8> value){ hdr.ipv4.b1 = ~hdr.ipv4.b1 &  value; }
    action a8bit_bit_andcb(bit<8> value){ hdr.ipv4.b1 =  hdr.ipv4.b1 & ~ value; }

    action a8bit_bit_nand(bit<8> value) { hdr.ipv4.b1 = ~(hdr.ipv4.b1 & value); }
    action a8bit_bit_nor(bit<8> value)  { hdr.ipv4.b1 = ~(hdr.ipv4.b1 | value); }
    action a8bit_bit_not()              { hdr.ipv4.b1 = ~ hdr.ipv4.b1;          }
    action a8bit_bit_or(bit<8> value)   { hdr.ipv4.b1 =   hdr.ipv4.b1 | value; }

    action a8bit_bit_orca(bit<8> value) { hdr.ipv4.b1 =  ~hdr.ipv4.b1 |  value; }
    action a8bit_bit_orcb(bit<8> value) { hdr.ipv4.b1 =   hdr.ipv4.b1 | ~value; }
    action a8bit_bit_xnor(bit<8> value) { hdr.ipv4.b1 = ~(hdr.ipv4.b1 ^  value); }
    action a8bit_bit_xor(bit<8> value)  { hdr.ipv4.b1 =   hdr.ipv4.b1 ^  value; }

    table t8bit {
        key = {
             hdr.ipv4.f : exact;
        }
        actions = {
            a8bit_add;
            a8bit_bit_and;
            a8bit_bit_andca;
            a8bit_bit_andcb;

            a8bit_bit_nand;
            a8bit_bit_nor;
            a8bit_bit_not;
            a8bit_bit_or;

            a8bit_bit_orca;
            a8bit_bit_orcb;
            a8bit_bit_xnor;
            a8bit_bit_xor;
        }
    }

    apply {
        t8bit.apply();
        ig_tm_md.ucast_egress_port = 8;
    }
}

parser EmptyEgressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}
control EmptyEgress(
        inout header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}


Pipeline(IngressParser(), Ingress1(), IngressDeparser(),
         EmptyEgressParser(), EmptyEgress(), EmptyEgressDeparser()) pipe1;

Switch(pipe1) main;
