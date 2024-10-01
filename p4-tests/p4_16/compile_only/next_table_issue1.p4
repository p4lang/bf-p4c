#include <tna.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

struct metadata {}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
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
    action noop() {}
    action a1(bit<16> param) {
        hdr.data.h1 = param;
    }

    action a2(bit<16> param) {
        hdr.data.h2 = param;
    }

    action a3(bit<16> param) {
        hdr.data.h3 = param;
    }

    table t_a {
        key = { hdr.data.f1 : exact; }
        actions = { noop; }
    }

    table t_b {
        key = { hdr.data.f1 : exact; }
        actions = { a1; a2; a3; }
    }

    table t_c {
        key = { hdr.data.f1 : exact; }
        actions = { noop; }
    }

    table t_d {
        key = { hdr.data.f1 : exact; }
        actions = { noop; }
    }

    table t_e {
        key = { hdr.data.f1 : exact; }
        actions = { a1; }
    }

    table t_f {
        key = { hdr.data.f1 : exact; }
        actions = { noop; }
    }

    table t_g {
        key = {
            hdr.data.h1 : exact;
            hdr.data.h2 : exact;
            hdr.data.h3 : exact;
        }
        actions = { noop; }
    }
   
    apply {
        if (hdr.data.f1 != 0) {
            t_a.apply();
            switch (t_b.apply().action_run) {
                a1 : { t_c.apply(); t_d.apply(); }
                a2 : { t_d.apply(); }
            }
        } else {
            if (t_e.apply().miss) {
                t_f.apply();
            }
        }
        t_g.apply();
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
