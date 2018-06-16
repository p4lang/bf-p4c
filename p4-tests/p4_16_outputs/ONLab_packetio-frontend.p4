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
    @name("ingress.send_to_cpu") action send_to_cpu_0() {
        standard_metadata.egress_spec = 9w320;
    }
    @name("ingress.set_egress_port") action set_egress_port_0(PortId port) {
        standard_metadata.egress_spec = port;
    }
    @name("ingress.table0") table table0 {
        support_timeout = false;
        key = {
            standard_metadata.ingress_port: ternary @name("standard_metadata.ingress_port") ;
            hdr.ethernet.dstAddr          : ternary @name("hdr.ethernet.dstAddr") ;
            hdr.ethernet.srcAddr          : ternary @name("hdr.ethernet.srcAddr") ;
            hdr.ethernet.etherType        : ternary @name("hdr.ethernet.etherType") ;
        }
        actions = {
            set_egress_port_0();
            send_to_cpu_0();
        }
        default_action = send_to_cpu_0();
    }
    apply {
        if (hdr.packet_out.isValid()) 
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
        else 
            table0.apply();
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply {
        hdr.packet_out.setInvalid();
        if (standard_metadata.egress_port == 9w320) {
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = standard_metadata.ingress_port;
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

