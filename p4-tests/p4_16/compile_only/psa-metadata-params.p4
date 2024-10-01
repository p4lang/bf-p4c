#include <psa.p4>

struct EMPTY { };

typedef bit<48>  EthernetAddress;
typedef psa_ingress_output_metadata_t ostd_ig_t;
typedef psa_egress_input_metadata_t istd_eg_t;
typedef psa_egress_output_metadata_t ostd_eg_t;
typedef psa_ingress_input_metadata_t istd_ig_t;

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

parser MyIP(
    packet_in buffer,
    out ethernet_t a,
    inout EMPTY b,
    in psa_ingress_parser_input_metadata_t c,
    in EMPTY d,
    in EMPTY e) {

    state start {
        buffer.extract(a);
        transition accept;
    }
}

parser MyEP(
    packet_in buffer,
    out ethernet_t a,
    inout EMPTY b,
    in psa_egress_parser_input_metadata_t c,
    in EMPTY d,
    in EMPTY e,
    in EMPTY f) {
    state start {
        transition accept;
    }
}

control MyIC(
    inout ethernet_t a,
    inout EMPTY b,
    in istd_ig_t c,
    inout ostd_ig_t d) {

    action a1(PortId_t port) {
        send_to_port(d, port);
    }

    table ig_tbl {
        key = {
            a.srcAddr : exact;
        }
        actions = { a1; }
    }

    apply {
        ig_tbl.apply();
    }
}

control MyEC(
    inout ethernet_t a,
    inout EMPTY b,
    in istd_eg_t c,
    inout ostd_eg_t d) {

    action a2() {
        egress_drop(d);
    }

    table eg_tbl {
        key = {
            a.srcAddr : exact;
        }
        actions = { a2; }
    }

    apply {
        eg_tbl.apply();
    }

}

control MyID(
    packet_out buffer,
    out EMPTY a,
    out EMPTY b,
    out EMPTY c,
    inout ethernet_t d,
    in EMPTY e,
    in ostd_ig_t f) {
    apply { 
        buffer.emit(d);
    }
}

control MyED(
    packet_out buffer,
    out EMPTY a,
    out EMPTY b,
    inout ethernet_t c,
    in EMPTY d,
    in ostd_eg_t e,
    in psa_egress_deparser_input_metadata_t f) {
    apply { 
        buffer.emit(d);
    }
}

IngressPipeline(MyIP(), MyIC(), MyID()) ip;
EgressPipeline(MyEP(), MyEC(), MyED()) ep;

PSA_Switch(
    ip,
    PacketReplicationEngine(),
    ep,
    BufferingQueueingEngine()) main;
