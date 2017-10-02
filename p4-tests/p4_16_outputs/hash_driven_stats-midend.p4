#include <core.p4>
#include <v1model.p4>

struct metadata_t {
}

struct headers_t {
}

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    state start {
        transition accept;
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    @name("egress_port_counter") counter(32w512, CounterType.bytes) egress_port_counter;
    @name("ingress_port_counter") counter(32w512, CounterType.bytes) ingress_port_counter;
    @hidden action act() {
        egress_port_counter.count((bit<32>)standard_metadata.egress_spec);
    }
    @hidden action act_0() {
        ingress_port_counter.count((bit<32>)standard_metadata.ingress_port);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        if (standard_metadata.egress_port < 9w511) 
            tbl_act.apply();
        if (standard_metadata.ingress_port < 9w511) 
            tbl_act_0.apply();
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
    }
}

control verifyChecksum(in headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

V1Switch<headers_t, metadata_t>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
