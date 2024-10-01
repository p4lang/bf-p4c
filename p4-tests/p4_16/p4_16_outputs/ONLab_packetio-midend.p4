#include <core.p4>
#include <v1model.p4>

typedef bit<9> PortId;
@controller_header("packet_in") header packet_in_header_t {
    PortId ingress_port;
    bit<7> _padding0;
}

@not_extracted_in_egress @controller_header("packet_out") header packet_out_header_t {
    PortId egress_port;
    bit<7> _padding0;
}

struct metadata_t {
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct headers_t {
    ethernet_t          ethernet;
    packet_out_header_t packet_out;
    packet_in_header_t  packet_in;
}

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    state parse_packet_out {
        packet.extract<packet_out_header_t>(hdr.packet_out);
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
    state start {
        transition select(standard_metadata.ingress_port) {
            9w320: parse_packet_out;
            default: parse_ethernet;
        }
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    @name("ingress.send_to_cpu") action send_to_cpu() {
        standard_metadata.egress_spec = 9w320;
    }
    @name("ingress.set_egress_port") action set_egress_port(PortId port) {
        standard_metadata.egress_spec = port;
    }
    @name("ingress.table0") table table0_0 {
        support_timeout = false;
        key = {
            standard_metadata.ingress_port: ternary @name("standard_metadata.ingress_port") ;
            hdr.ethernet.dstAddr          : ternary @name("hdr.ethernet.dstAddr") ;
            hdr.ethernet.srcAddr          : ternary @name("hdr.ethernet.srcAddr") ;
            hdr.ethernet.etherType        : ternary @name("hdr.ethernet.etherType") ;
        }
        actions = {
            set_egress_port();
            send_to_cpu();
        }
        default_action = send_to_cpu();
    }
    @hidden action act() {
        standard_metadata.egress_spec = hdr.packet_out.egress_port;
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        if (hdr.packet_out.isValid()) 
            tbl_act.apply();
        else 
            table0_0.apply();
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    @hidden action act_0() {
        hdr.packet_in.setValid();
        hdr.packet_in.ingress_port = standard_metadata.ingress_port;
    }
    @hidden action act_1() {
        hdr.packet_out.setInvalid();
    }
    @hidden table tbl_act_0 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    @hidden table tbl_act_1 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        tbl_act_0.apply();
        if (standard_metadata.egress_port == 9w320) {
            tbl_act_1.apply();
        }
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit<packet_in_header_t>(hdr.packet_in);
        packet.emit<ethernet_t>(hdr.ethernet);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

V1Switch<headers_t, metadata_t>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

