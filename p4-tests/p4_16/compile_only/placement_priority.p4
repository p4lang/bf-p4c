#include <core.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
header my_header_h {
    bit<32> read;
    bit<32> f1;
    bit<32> f2;
    bit<4> n1;
    bit<4> n2;
}

struct switch_header_t {
    my_header_h my_header;
}

#define ETHERTYPE_BF_PKTGEN     0x9001

struct metadata_t {
    bool checksum_err;
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.extract(hdr.my_header);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        pkt.emit(hdr.my_header);
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {


    state start {
    }
}

// ---------------------------------------------------------------------------
// Egress deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
    }
}



// ---------------------------------------------------------------------------
// Ingress 
// ---------------------------------------------------------------------------
control SwitchIngress(
        inout switch_header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action noop() {}

    @name(".t1")
    @placement_priority(".t2", 1)
    table t1 {
        key = { hdr.my_header.read : exact; }
        actions = { noop; }
    }

    @name(".t2")
    // @placement_priority(".t1", 3)
    table t2 {
        key = { hdr.my_header.read : exact; }
        actions = { noop; }
    }

    @name(".t3")
    @placement_priority(".t1", ".t2")
    table t3 {
        key = { hdr.my_header.read : exact; }
        actions = { noop; }
    }

    apply {
        t1.apply();
        t2.apply();
        t3.apply();
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

// ---------------------------------------------------------------------------
// Egress
// ---------------------------------------------------------------------------
control SwitchEgress(
        inout switch_header_t hdr,
        inout metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply{
    }
}


Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
