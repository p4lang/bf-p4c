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
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

@name(".sel_profile") @mode("fair") action_selector(HashAlgorithm.crc16, 32w1024, 32w16) sel_profile;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_3() {
    }
    @name(".port_down") selector_action(sel_profile) port_down_0 = {
        void apply(inout bit<1> value) {
            value = 1w1;
        }
    };
    @name(".port_up") selector_action(sel_profile) port_up_0 = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };
    @name(".set_output") action set_output(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".set_port_up") action set_port_up() {
        port_up_0.execute((bit<32>)hdr.data.b4);
        standard_metadata.egress_spec = 9w0;
    }
    @name(".set_port_down") action set_port_down() {
        port_down_0.execute((bit<32>)hdr.data.b4);
        standard_metadata.egress_spec = 9w0;
    }
    @name(".select_output") table select_output_0 {
        actions = {
            set_output();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.data.b1: exact @name("data.b1") ;
            hdr.data.f1: selector @name("data.f1") ;
            hdr.data.f2: selector @name("data.f2") ;
            hdr.data.f3: selector @name("data.f3") ;
            hdr.data.f4: selector @name("data.f4") ;
        }
        size = 1024;
        implementation = sel_profile;
        default_action = NoAction_0();
    }
    @name(".update_output") table update_output_0 {
        actions = {
            set_port_up();
            set_port_down();
            @defaultonly NoAction_3();
        }
        key = {
            hdr.data.b3: exact @name("data.b3") ;
        }
        size = 1024;
        default_action = NoAction_3();
    }
    apply {
        if (hdr.data.b2 == 8w1) 
            update_output_0.apply();
        else 
            select_output_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<data_t>(hdr.data);
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

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

