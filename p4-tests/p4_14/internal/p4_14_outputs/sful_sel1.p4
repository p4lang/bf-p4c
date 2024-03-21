#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}
#include <tofino/stateful_alu.p4>

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

@name(".sel_profile") @mode("fair") action_selector(HashAlgorithm.crc16, 32w1024, 32w16) sel_profile;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".port_down") selector_action(sel_profile) port_down = {
        void apply(inout bit<1> value) {
            bit<1> in_value;
            in_value = value;
            value = 1w1;
        }
    };
    @name(".port_up") selector_action(sel_profile) port_up = {
        void apply(inout bit<1> value) {
            bit<1> in_value;
            in_value = value;
            value = 1w0;
        }
    };
    @name(".set_output") action set_output(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".set_port_up") action set_port_up() {
        port_up.execute((bit<32>)hdr.data.b4);
        standard_metadata.egress_spec = 9w0;
    }
    @name(".set_port_down") action set_port_down() {
        port_down.execute((bit<32>)hdr.data.b4);
        standard_metadata.egress_spec = 9w0;
    }
    @name(".select_output") table select_output {
        actions = {
            set_output;
        }
        key = {
            hdr.data.b1: exact;
            hdr.data.f1: selector;
            hdr.data.f2: selector;
            hdr.data.f3: selector;
            hdr.data.f4: selector;
        }
        size = 1024;
        implementation = sel_profile;
    }
    @name(".update_output") table update_output {
        actions = {
            set_port_up;
            set_port_down;
        }
        key = {
            hdr.data.b3: exact;
        }
        size = 1024;
    }
    apply {
        if (hdr.data.b2 == 8w1) {
            update_output.apply();
        }
        else {
            select_output.apply();
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.data);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

