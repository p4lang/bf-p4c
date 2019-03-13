#include <core.p4>
#include <v1model.p4>

header read_values_t {
    bit<32> f1;
}

header write_values_t {
    bit<4> u1;
    bit<2> v1;
    bit<4> u2;
    bit<2> v2;
    bit<4> u3;
    bit<4> w1;
    bit<2> x1;
    bit<4> w2;
    bit<2> x2;
    bit<4> w3;
    bit<4> y1;
    bit<8> z1;
    bit<4> y2;
}

struct metadata {
}

struct headers {
    @name(".read_values") 
    read_values_t  read_values;
    @name(".write_values") 
    write_values_t write_values;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @pa_container_size("ingress", "write_values.u1", 16) @pa_container_size("ingress", "write_values.w1", 16) @pa_container_size("ingress", "write_values.y1", 16) @name(".start") state start {
        packet.extract<read_values_t>(hdr.read_values);
        packet.extract<write_values_t>(hdr.write_values);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".noop") action noop() {
    }
    @name(".noop") action noop_2() {
    }
    @name(".port_set") action port_set(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".bm_set1") action bm_set1(bit<4> param1, bit<4> param2, bit<4> param3) {
        hdr.write_values.u1 = param1;
        hdr.write_values.u2 = param2;
        hdr.write_values.u3 = param3;
        hdr.write_values.w1 = param1;
        hdr.write_values.y1 = param1;
    }
    @name(".bm_set2") action bm_set2(bit<4> param1, bit<4> param2, bit<4> param3) {
        hdr.write_values.u1 = param1;
        hdr.write_values.u2 = param2;
        hdr.write_values.u3 = param3;
        hdr.write_values.w2 = param1;
        hdr.write_values.y2 = param1;
    }
    @name(".bm_set3") action bm_set3(bit<4> param1, bit<4> param2, bit<4> param3) {
        hdr.write_values.u1 = param1;
        hdr.write_values.u2 = param2;
        hdr.write_values.u3 = param3;
        hdr.write_values.w1 = param2;
        hdr.write_values.w3 = param3;
    }
    @name(".bm_set4") action bm_set4(bit<4> param1, bit<4> param2, bit<4> param3) {
        hdr.write_values.u1 = param1;
        hdr.write_values.u2 = param2;
        hdr.write_values.u3 = param3;
        hdr.write_values.w1 = param1;
        hdr.write_values.w2 = param2;
        hdr.write_values.w3 = param3;
    }
    @name(".bm_set5") action bm_set5(bit<4> param1, bit<4> param2, bit<4> param3) {
        hdr.write_values.u1 = param1;
        hdr.write_values.u2 = param2;
        hdr.write_values.u3 = param3;
        hdr.write_values.w1 = param3;
        hdr.write_values.w2 = param2;
        hdr.write_values.w3 = param1;
    }
    @name(".bm_set6") action bm_set6(bit<4> param1, bit<4> param2, bit<4> param3) {
        hdr.write_values.u1 = param1;
        hdr.write_values.u2 = param2;
        hdr.write_values.u3 = param3;
        hdr.write_values.w1 = param1;
        hdr.write_values.w2 = param2;
        hdr.write_values.w3 = param3;
        hdr.write_values.y1 = param3;
    }
    @name(".bm_set7") action bm_set7(bit<4> param1, bit<4> param2, bit<4> param3) {
        hdr.write_values.u1 = param1;
        hdr.write_values.u2 = param2;
        hdr.write_values.u3 = param3;
        hdr.write_values.w1 = param1;
        hdr.write_values.w2 = param2;
        hdr.write_values.w3 = param3;
        hdr.write_values.y1 = param1;
        hdr.write_values.y2 = param3;
    }
    @name(".set_port") table set_port_0 {
        actions = {
            noop();
            port_set();
        }
        key = {
            hdr.read_values.f1: ternary @name("read_values.f1") ;
        }
        default_action = noop();
    }
    @name(".test1") table test1_0 {
        actions = {
            noop_2();
            bm_set1();
            bm_set2();
            bm_set3();
            bm_set4();
            bm_set5();
            bm_set6();
            bm_set7();
        }
        key = {
            hdr.read_values.f1: exact @name("read_values.f1") ;
        }
        default_action = noop_2();
    }
    apply {
        set_port_0.apply();
        test1_0.apply();
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

