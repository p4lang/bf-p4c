#include <core.p4>
#include <psa.p4>

struct EMPTY {
}

typedef bit<48> EthernetAddress;
struct user_meta_t {
    bit<16> data1;
    bit<16> data2;
}

header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct headers_t {
    ethernet_t ethernet;
}

parser MyIP(packet_in buffer, out headers_t hdr, inout user_meta_t b, in psa_ingress_parser_input_metadata_t c, in EMPTY d, in EMPTY e) {
    state start {
        buffer.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
}

parser MyEP(packet_in buffer, out EMPTY a, inout EMPTY b, in psa_egress_parser_input_metadata_t c, in EMPTY d, in EMPTY e, in EMPTY f) {
    state start {
        transition accept;
    }
}

control MyIC(inout headers_t hdr, inout user_meta_t b, in psa_ingress_input_metadata_t c, inout psa_ingress_output_metadata_t d) {
    @noWarn("unused") @name(".NoAction") action NoAction_0() {
    }
    @name("MyIC.as") ActionSelector(PSA_HashAlgorithm_t.CRC32, 32w1024, 32w16) as_0;
    @name("MyIC.a1") action a1(@name("param") bit<48> param) {
        hdr.ethernet.dstAddr = param;
    }
    @name("MyIC.a2") action a2(@name("param") bit<16> param_2) {
        hdr.ethernet.etherType = param_2;
    }
    @name("MyIC.tbl") table tbl_0 {
        key = {
            hdr.ethernet.srcAddr: exact @name("hdr.ethernet.srcAddr") ;
            b.data1             : selector @name("b.data1") ;
            b.data2             : selector @name("b.data2") ;
        }
        actions = {
            NoAction_0();
            a1();
            a2();
        }
        psa_implementation = as_0;
        default_action = NoAction_0();
    }
    apply {
        tbl_0.apply();
    }
}

control MyEC(inout EMPTY a, inout EMPTY b, in psa_egress_input_metadata_t c, inout psa_egress_output_metadata_t d) {
    apply {
    }
}

control MyID(packet_out buffer, out EMPTY a, out EMPTY b, out EMPTY c, inout headers_t hdr, in user_meta_t e, in psa_ingress_output_metadata_t f) {
    @hidden action psaactionselector2l91() {
        buffer.emit<ethernet_t>(hdr.ethernet);
    }
    @hidden table tbl_psaactionselector2l91 {
        actions = {
            psaactionselector2l91();
        }
        const default_action = psaactionselector2l91();
    }
    apply {
        tbl_psaactionselector2l91.apply();
    }
}

control MyED(packet_out buffer, out EMPTY a, out EMPTY b, inout EMPTY c, in EMPTY d, in psa_egress_output_metadata_t e, in psa_egress_deparser_input_metadata_t f) {
    apply {
    }
}

IngressPipeline<headers_t, user_meta_t, EMPTY, EMPTY, EMPTY, EMPTY>(MyIP(), MyIC(), MyID()) ip;

EgressPipeline<EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY>(MyEP(), MyEC(), MyED()) ep;

PSA_Switch<headers_t, user_meta_t, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY>(ip, PacketReplicationEngine(), ep, BufferingQueueingEngine()) main;
