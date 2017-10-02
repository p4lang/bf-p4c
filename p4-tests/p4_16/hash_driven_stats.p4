#include <core.p4>
#include <v1model.p4>

struct metadata_t { }
struct headers_t { }

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta,
                  inout standard_metadata_t standard_metadata) {
    state start {
        transition accept;
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta,
                inout standard_metadata_t standard_metadata) {
    counter(512, CounterType.bytes) egress_port_counter;
    counter(512, CounterType.bytes) ingress_port_counter;

    apply {
        if (standard_metadata.egress_port < 511) {
            egress_port_counter.count((bit<32>) standard_metadata.egress_spec);
        }
        if (standard_metadata.ingress_port < 511) {
            ingress_port_counter.count((bit<32>) standard_metadata.ingress_port);
        }
    }
}

control egress(inout headers_t hdr, inout metadata_t meta,
               inout standard_metadata_t standard_metadata) {
    apply { }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply { }
}

control verifyChecksum(in headers_t hdr, inout metadata_t meta) {
    apply { }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(),
         computeChecksum(), DeparserImpl()) main;
