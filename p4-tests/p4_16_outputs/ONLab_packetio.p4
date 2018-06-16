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
        packet.extract(hdr.packet_out);
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
    state start {
        transition select(standard_metadata.ingress_port) {
            320: parse_packet_out;
            default: parse_ethernet;
        }
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    action send_to_cpu() {
        standard_metadata.egress_spec = 320;
    }
    action set_egress_port(PortId port) {
        standard_metadata.egress_spec = port;
    }
    table table0 {
        support_timeout = false;
        key = {
            standard_metadata.ingress_port: ternary;
            hdr.ethernet.dstAddr          : ternary;
            hdr.ethernet.srcAddr          : ternary;
            hdr.ethernet.etherType        : ternary;
        }
        actions = {
            set_egress_port();
            send_to_cpu();
        }
        default_action = send_to_cpu();
    }
    apply {
        if (hdr.packet_out.isValid()) {
            standard_metadata.egress_spec = hdr.packet_out.egress_port;
        }
        else {
            table0.apply();
        }
    }
}

control PacketIoEgressControl(inout headers_t hdr, inout standard_metadata_t standard_metadata) {
    apply {
        hdr.packet_out.setInvalid();
        if (standard_metadata.egress_port == 320) {
            hdr.packet_in.setValid();
            hdr.packet_in.ingress_port = standard_metadata.ingress_port;
        }
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    PacketIoEgressControl() packet_io_egress_control;
    apply {
        packet_io_egress_control.apply(hdr, standard_metadata);
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.packet_in);
        packet.emit(hdr.ethernet);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

