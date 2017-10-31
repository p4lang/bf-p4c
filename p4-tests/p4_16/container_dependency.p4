#include <core.p4>
#include <tofino.p4>

header data_t {
    bit<32> f1;
    bit<4> x1;
    bit<4> x2;
}

struct metadata {
}

struct headers {
    data_t data;
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

control IngressP(inout headers hdr,
                 inout metadata meta,
                 in ingress_intrinsic_metadata_t ig_intr_md,
                 in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                 inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action set_port_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    action setx1(bit<4> x1) {
        hdr.data.x1 = x1;
    }

    action setx2(bit<4> x2) {
        hdr.data.x2 = x2;
    }

    action setboth(bit<4> x1, bit<4> x2) {
        hdr.data.x1 = x1;
        hdr.data.x2 = x2;
    }

    action noop() {

    }

    table t1 {
        actions = { setx1;
                    noop; }
        key = { hdr.data.f1: exact; }
        default_action = noop;
    }

    table t2 {
        actions = { setx2;
                    noop; }
        key = { hdr.data.f1: exact; }
        default_action = noop;
    }

    table t3 {
        actions = { setx1;
                    noop; }
        key = { hdr.data.f1: exact;
                hdr.data.x1: exact;
                hdr.data.x2: exact; }
        default_action = noop;
    }

    @ignore_table_dependency("t3")
    table t4 {
        actions = { setx1;
                    noop; }
        key = { hdr.data.f1: exact; }
        default_action = noop;
    }

    table t5 {
        actions = { setx1;
                    noop; }
        key = { hdr.data.f1: exact;
                hdr.data.x1: exact;
                hdr.data.x2: exact; }
        default_action = noop;
    }

    // Due to parser, containers will still be dependent
    @ignore_table_dependency("t5")
    table t6 {
        actions = { setx2;
                    noop; }
        key = { hdr.data.f1: exact; }
        default_action = noop;
    }

    table t7 {
        actions = { setx1;
                    noop; }
        key = { hdr.data.f1: exact;
                hdr.data.x1: exact;
                hdr.data.x2: exact; }
        default_action = noop;
    }

    // Due to parser, containers will still be dependent
    @ignore_table_dependency("t7")
    table t8 {
        actions = { setboth;
                    noop; }
        key = { hdr.data.f1: exact; }
        default_action = noop;
    }

    table set_port {
        actions = { set_port_act;
                    noop; }
        key = { hdr.data.f1: exact; }
        default_action = noop;
    }

    apply {
        t1.apply();
        t2.apply();       
        t3.apply();
        t4.apply();
        t5.apply();
        t6.apply();
        t7.apply();
        t8.apply();
        set_port.apply();
    }

}

control DeparserI(packet_out b,
                  in headers hdr,
                  in metadata meta) {
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

control EgressP(inout headers hdr,
                inout metadata meta,
                in egress_intrinsic_metadata_t eg_intr_md,
                in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    apply { }
}

control DeparserE(packet_out b,
                  in headers hdr,
                  in metadata meta) {
    apply { b.emit(hdr.data); }
}

Switch(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;
