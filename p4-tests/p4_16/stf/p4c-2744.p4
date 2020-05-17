
#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct metadata {
}

header ingress_skip_t {
    bit<64> pad;
}

struct headers {
    data_t data;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        b.extract(ig_intr_md);
        b.extract(skip);
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Hash<bit<16>>(HashAlgorithm_t.CRC16) my_hash;

    action act() {
	hdr.data.h1 = my_hash.get({hdr.data.f1, hdr.data.f2, hdr.data.f3});
    }

    table test {
        actions = { @defaultonly act; }
        const default_action = act;
    }

    action set_port_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table set_port {
        key = { hdr.data.f1 : ternary; }
        actions = { set_port_act; }
    }

    apply {
        test.apply();
        set_port.apply();
    }

}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { b.emit(hdr.data); }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(eg_intr_md);
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
