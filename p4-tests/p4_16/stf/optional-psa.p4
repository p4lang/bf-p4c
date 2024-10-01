#include <core.p4>
#include <psa.p4>

struct EMPTY { };
header data_t {
    bit<8> f1;
    bit<8> f2;
    bit<16> h1;
    bit<16> h2;
    bit<8>  b1;
    bit<8>  b2;
}

struct header_t {
    data_t data;
}

struct user_meta_t {
}

parser MyIP(
    packet_in buffer,
    out header_t a,
    inout user_meta_t b,
    in psa_ingress_parser_input_metadata_t c,
    in EMPTY d,
    in EMPTY e) {

    state start {
        buffer.extract(a.data);
        transition accept;
    }
}

parser MyEP(
    packet_in buffer,
    out header_t a,
    inout EMPTY b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY d,
    in EMPTY e,
    in EMPTY f) {
    state start {
        buffer.extract(a.data);
        transition accept;
    }
}

control MyIC(
    inout header_t a,
    inout user_meta_t b,
    in psa_ingress_input_metadata_t c,
    inout psa_ingress_output_metadata_t ostd) {

    action a1(bit<16> id) {
        a.data.h1 = id;
    }

    table test1 {
        actions = {
            a1();
        }
        key = {
            a.data.f1: optional;
            a.data.f2: exact;
        }
    }

    action a2(bit<16> id, PortId_t port) {
        a.data.h2 = id;
        send_to_port(ostd, port);
    }

    table test2 {
        actions = {
            a2();
        }
        key = {
            a.data.f1: optional;
            // a.data.f2: exact;
        }
    }

    apply {
        test1.apply();
        test2.apply();
    }
}

control MyEC(
    inout header_t a,
    inout EMPTY b,
    in psa_egress_input_metadata_t c,
    inout psa_egress_output_metadata_t d) {
    apply { }
}

control MyID(
    packet_out buffer,
    out EMPTY a,
    out EMPTY b,
    out EMPTY c,
    inout header_t d,
    in user_meta_t e,
    in psa_ingress_output_metadata_t f) {
    apply { 
        buffer.emit(d.data);
    }
}

control MyED(
    packet_out buffer,
    out EMPTY a,
    out EMPTY b,
    inout header_t c,
    in EMPTY d,
    in psa_egress_output_metadata_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { 
        buffer.emit(c.data);
    }
}

IngressPipeline(MyIP(), MyIC(), MyID()) ipipe;
EgressPipeline(MyEP(), MyEC(), MyED()) epipe;

PSA_Switch(
    ipipe,
    PacketReplicationEngine(),
    epipe,
    BufferingQueueingEngine()) main;
