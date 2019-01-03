#include <core.p4>
#include <v1model.p4>

struct metadata_values_t {
    bit<12> m1;
}

header read_values_t {
    bit<32> f1;
}

header write_values_t {
    bit<12> x1;
    bit<4>  y1;
    bit<4>  y2;
    bit<12> x2;
    bit<2>  z1;
    bit<12> x3;
    bit<2>  z2;
}

struct metadata {
    @name(".meta_values") 
    metadata_values_t meta_values;
}

struct headers {
    @name(".read_values") 
    read_values_t  read_values;
    @name(".write_values") 
    write_values_t write_values;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @pa_container_size("ingress", "write_values.x1", 16) @pa_container_size("ingress", "write_values.x2", 16) @pa_container_size("ingress", "write_values.x3", 16) @name(".start") state start {
        packet.extract<read_values_t>(hdr.read_values);
        packet.extract<write_values_t>(hdr.write_values);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".noop") action noop() {
    }
    @name(".set_test1") action set_test1(bit<12> param, bit<9> port) {
        hdr.write_values.x1 = param;
        hdr.write_values.x2 = param;
        standard_metadata.egress_spec = port;
    }
    @name(".xor_test1") action xor_test1(bit<12> param, bit<9> port) {
        meta.meta_values.m1 = hdr.write_values.x3 ^ param;
        hdr.write_values.x2 = param;
        standard_metadata.egress_spec = port;
    }
    @name(".xor_result") action xor_result() {
        hdr.write_values.x1 = meta.meta_values.m1;
    }
    @name(".test1") table test1_0 {
        actions = {
            noop();
            set_test1();
            xor_test1();
        }
        key = {
            hdr.read_values.f1: exact @name("read_values.f1") ;
        }
        default_action = noop();
    }
    @name(".test1_result2") table test1_result2_0 {
        actions = {
            xor_result();
        }
        default_action = xor_result();
    }
    apply {
        switch (test1_0.apply().action_run) {
            xor_test1: {
                test1_result2_0.apply();
            }
        }

    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<read_values_t>(hdr.read_values);
        packet.emit<write_values_t>(hdr.write_values);
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

