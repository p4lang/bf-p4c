
#include <core.p4>
#include <t2na.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<16> h2;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

struct metadata {
}


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
    action a1() {}
    action a2() {}
    action setf2(bit <32> f2) { hdr.data.f2 = f2; }

    @stage(4)
    table t1 {
        key = { hdr.data.f1 : exact; }
        actions = { a1; a2; }
    }

    table t2 {
        key = { hdr.data.f1 : exact; }
        actions = { a1; a2; }
    }

    @stage(2)
    table t3 {
        key = { hdr.data.f1 : exact; }
        actions = { setf2; }
    }
    
    @stage(6)
    table t4 {
        key = { hdr.data.f2 : exact; }
        actions = { a1; a2; }
    }

    table t5 {
        key = { hdr.data.f2 : exact; }
        actions = { a1; a2; }
    }

    apply {
        if (hdr.data.h1 == 0) {
            if (hdr.data.h2 == 0) {
                t1.apply();
            }
            switch (t2.apply().action_run) {
                a1 : { }
                default : {
                    t3.apply();
                    t4.apply();
                }
            }
        }
        t5.apply();
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
