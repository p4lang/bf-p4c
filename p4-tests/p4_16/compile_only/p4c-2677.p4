#include <tna.p4>
typedef bit<16> MulticastGroup_t;
typedef bit<10> CloneSessionId_t;
typedef bit<3> ClassOfService_t;
typedef bit<16> EgressInstance_t;
typedef bit<48> Timestamp_t;
struct psa_ingress_parser_input_metadata_t {
    PortId_t ingress_port;
    bit<8>   packet_path;
}

struct psa_egress_parser_input_metadata_t {
    PortId_t egress_port;
    bit<8>   packet_path;
}

struct psa_ingress_input_metadata_t {
    PortId_t      ingress_port;
    bit<8>        packet_path;
    Timestamp_t   ingress_timestamp;
    ParserError_t parser_error;
}

struct psa_ingress_output_metadata_t {
    ClassOfService_t class_of_service;
    bool             clone;
    CloneSessionId_t clone_session_id;
    bool             drop;
    bool             resubmit;
    MulticastGroup_t multicast_group;
    PortId_t         egress_port;
}

struct psa_egress_input_metadata_t {
    ClassOfService_t class_of_service;
    PortId_t         egress_port;
    bit<8>           packet_path;
    EgressInstance_t instance;
    Timestamp_t      egress_timestamp;
    ParserError_t    parser_error;
}

struct psa_egress_deparser_input_metadata_t {
    PortId_t egress_port;
}

struct psa_egress_output_metadata_t {
    bool             clone;
    CloneSessionId_t clone_session_id;
    bool             drop;
}

struct EMPTY {
}

typedef bit<48> EthernetAddress;
header ethernet_t {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

parser ingressParserImpl(packet_in buffer, out ethernet_t eth, out EMPTY b, out ingress_intrinsic_metadata_t ig_intr_md, out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm, out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr) {
    state start {
        buffer.extract<ethernet_t>(eth);
        transition accept;
    }
}

parser egressParserImpl(packet_in buffer, out EMPTY a, out EMPTY b, out egress_intrinsic_metadata_t eg_intr_md, out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    state start {
        transition accept;
    }
}

control ingress(inout ethernet_t a, inout EMPTY b, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_parser, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @noWarn("unused") @name(".NoAction") action NoAction_0() {
    }
    @name("MyIC.meter0") Meter<bit<12>>(32w1024, MeterType_t.PACKETS) meter0_0;
    @name("MyIC.meter1") Meter<bit<12>>(32w1024, MeterType_t.PACKETS) meter1_0;
    @name("MyIC.meter2") Meter<bit<12>>(32w1024, MeterType_t.PACKETS) meter2_0;
    @name("MyIC.tbl") table tbl_0 {
        key = {
            a.srcAddr: exact @name("a.srcAddr") ;
        }
        actions = {
            NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("MyIC.tbl_1") table tbl_1 {
        key = {
            a.srcAddr: exact @name("a.srcAddr") ;
        }
        actions = {
            NoAction_0();
        }
        default_action = NoAction_0();
    }

    apply {
        if (meter0_0.execute(12w0) == (bit<8>)MeterColor_t.GREEN) {
            tbl_0.apply();
            if (meter1_0.execute(12w0) == (bit<8>)MeterColor_t.GREEN) {
                NoAction();
            }
        } else if (meter2_0.execute(12w0) == (bit<8>)MeterColor_t.GREEN) {
            tbl_1.apply();
        }
    }
}

control ingressDeparserImpl(packet_out buffer, inout ethernet_t d, in EMPTY e, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, in ingress_intrinsic_metadata_t ig_intr_md) {
    apply {
    }
}

control egress(inout EMPTY a, inout EMPTY b, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control egressDeparserImpl(packet_out buffer, inout EMPTY c, in EMPTY d, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    apply {
    }
}

Pipeline<ethernet_t, EMPTY, EMPTY, EMPTY>(ingressParserImpl(), ingress(), ingressDeparserImpl(), egressParserImpl(), egress(), egressDeparserImpl()) pipe;

Switch(pipe) main;

