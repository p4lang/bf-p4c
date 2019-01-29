#include <core.p4>
#include <tna.p4>

typedef bit<48> MacAddr_t;

header Ethernet_t {
    MacAddr_t dmac;
    MacAddr_t smac;
    bit<16> ethertype;
}

struct headers {
    Ethernet_t ethernet;
}

struct metadata { PortId_t ig_port; }

parser ParserI(packet_in b,
               out headers h,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(ig_intr_md);
        b.advance(64);
        b.extract(h.ethernet);
        transition accept;
    }
}

struct L2_digest_t {
    MacAddr_t smac;
    PortId_t ig_port;
}

control IngressP(
        inout headers h,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action send_digest() {
        ig_intr_dprs_md.digest_type = 0;
        meta.ig_port = ig_intr_md.ingress_port;
    }
    table smac {
        key = { h.ethernet.smac : exact; }
        actions = { send_digest; NoAction; }
        const default_action = send_digest();
        size = 4096;
        idle_timeout = true;
    }

    apply {
        smac.apply();
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

control DeparserI(
        packet_out b,
        inout headers h,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    @name(".L2_digest")
    Digest<L2_digest_t>() L2_digest;
    apply {
        if (ig_intr_dprsr_md.digest_type == 0)
            L2_digest.pack({h.ethernet.smac, meta.ig_port});
        b.emit(h.ethernet);
    }
}

parser ParserE(packet_in b,
               out headers h,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(eg_intr_md);
        transition accept;
    }
}

control EgressP(
        inout headers h,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers h,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
