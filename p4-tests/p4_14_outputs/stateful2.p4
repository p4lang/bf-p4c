#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<32> tmp;
}

struct pair32_t {
    bit<32> lo;
    bit<32> hi;
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<16> h4;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
}

struct metadata {
    @name("meta") 
    meta_t meta;
}

struct headers {
    @name("data") 
    data_t data;
}

extern stateful_alu {
    void execute_stateful_alu(@optional in bit<32> index);
    void execute_stateful_alu_from_hash<FL>(in FL hash_field_list);
    void execute_stateful_log();
    stateful_alu();
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".accum") register<pair32_t>(32w2048) accum;
    stateful_alu() sful;
    @name(".act1") action act1(bit<9> port, bit<32> idx) {
        standard_metadata.egress_spec = port;
        sful.execute_stateful_alu(idx);
    }
    @name(".test1") table test1 {
        actions = {
            act1;
        }
        key = {
            hdr.data.f1: exact;
        }
    }
    apply {
        test1.apply();
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

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
