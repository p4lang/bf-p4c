#include <tna.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

error {
    CustomError
}

struct metadata {
    bit<16> ethType;
}

struct headers {
    ethernet_t ethernet;
}

parser ingressParserImpl(packet_in packet, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        // verify(false, error.CounterRange);
        transition accept;
    }
}

parser egressParserImpl(packet_in packet, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    action prsr_error() { ig_intr_md_for_dprsr.drop_ctl = 7; }
    action prsr_no_error() {
        meta.ethType = 16w0;
    }
    table check_prsr_error {
        key = { ig_intr_md_from_prsr.parser_err : exact; }
        actions = { prsr_no_error; prsr_error; }
        const default_action = prsr_error();
        size = 1;
        const entries = {
            (0) : prsr_no_error();
        }
    }

    action set_nexthop() {
        meta.ethType = 16w1;
    }
    table nexthop {
        key = { hdr.ethernet.etherType: exact; }
        actions = { set_nexthop; }
        size = 1024;
    }
    apply {
        check_prsr_error.apply();
        /* Set the drop_ctl bits if the packet had a parser error. */
        if (ig_intr_md_from_prsr.parser_err & PARSER_ERROR_MULTIWRITE == 0) {
            nexthop.apply();
        }
    }
}

control ingressDeparserImpl(packet_out packet, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control egressDeparserImpl(packet_out packet, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
    }
}

Pipeline(ingressParserImpl(), ingress(), ingressDeparserImpl(), egressParserImpl(), egress(), egressDeparserImpl()) pipe;

Switch(pipe) main;

