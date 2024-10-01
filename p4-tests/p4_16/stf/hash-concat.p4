
#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

header data_t {
    bit<32> read;
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

    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash1;

    action A_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
	hdr.data.h1 = hash1.get({hdr.data.f1 ++ 3w0 ++ hdr.data.f2 ++ 5w0 ++ hdr.data.f3});
    }

    table A_tbl {
        actions = { A_act; NoAction; }
        key = { hdr.data.read: exact; }
        const default_action = NoAction;
    }

    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash2;
    action B_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
	hdr.data.h1 = hash2.get({8w255 ++ hdr.data.f1 ++ 3w7 ++ hdr.data.f2 ++ 5w0 ++ hdr.data.f3});
    }

    table B_tbl {
        actions = { B_act; NoAction; }
        key = { hdr.data.read: exact; }
        const default_action = NoAction;
    }

    Hash<bit<16>>(HashAlgorithm_t.CRC32) hash3;
    action C_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
	hdr.data.h1 = hash3.get({hdr.data.f1 ++ 3w0 ++ hdr.data.f2 ++ 5w0 ++ hdr.data.f3});
    }

    table C_tbl {
        actions = { C_act; NoAction; }
        key = { hdr.data.read: exact; }
        const default_action = NoAction;
    }

    Hash<bit<16>>(HashAlgorithm_t.CRC32) hash4;
    action D_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
	hdr.data.h1 = hash4.get({8w255 ++ hdr.data.f1 ++ 3w7 ++ hdr.data.f2 ++ 5w0 ++ hdr.data.f3});
    }

    table D_tbl {
        actions = { D_act; NoAction; }
        key = { hdr.data.read: exact; }
        const default_action = NoAction;
    }

    Hash<bit<16>>(HashAlgorithm_t.IDENTITY) hash5;
    action E_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
	hdr.data.h1 = hash5.get({hdr.data.f3 ++ 8w255});
    }

    table E_tbl {
        actions = { E_act; NoAction; }
        key = { hdr.data.read: exact; }
        const default_action = NoAction;
    }

    apply {
        if (A_tbl.apply().miss) {
            if (B_tbl.apply().miss) {
                if (C_tbl.apply().miss) {
                    if (D_tbl.apply().miss) {
                        E_tbl.apply();
                    }
                }
            }
        }
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
