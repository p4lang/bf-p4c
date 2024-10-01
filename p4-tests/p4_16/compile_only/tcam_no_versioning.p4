#include <core.p4>
#include <tna.p4>

header my_header_h {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
}

struct header_t {
    my_header_h my_header;
}

struct ingress_metadata_t {}
struct egress_metadata_t {}

parser IngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
         pkt.extract(ig_intr_md);
         pkt.extract(hdr.my_header);
         transition accept;
    }
}


parser EgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start { transition accept; }
}

control Ingress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    action nop() {}
    action set_port(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }

    table t1 {
        key = {
            hdr.my_header.f1 : ternary;
            hdr.my_header.f2[11:0] : ternary;
        }

        actions = {
            set_port;
            @defaultonly nop;
        }

        requires_versioning = false;
        const default_action = nop();
    }

    table t2 {
        key = {
            hdr.my_header.f3 : ternary;
            hdr.my_header.f2[23:16] : ternary;
            hdr.my_header.f2[31:28] : ternary;
        }
        actions = {
            set_port;
            @defaultonly nop;
        }

        requires_versioning = false;
        const default_action = nop();
    }

    table t3 {
        key = {
            hdr.my_header.h1 : ternary;
            hdr.my_header.h2 : ternary;
            hdr.my_header.h3[11:0] : ternary;
        }
        actions = {
            set_port;
            @defaultonly nop;
        }
        requires_versioning = true;
        const default_action = nop();
    }

    apply {
        t1.apply();
        t2.apply();
        t3.apply();
    }
}

control Egress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

control IngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.my_header);
    }
}


control EgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
     apply {}
}

Pipeline(IngressParser(),
         Ingress(),
         IngressDeparser(),
         EgressParser(),
         Egress(),
         EgressDeparser()) pipe;

Switch(pipe) main;
