#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<8>  b1;
    bit<8>  b2;
    bit<4>  pad;
    bit<1>  bit1;
    bit<1>  bit2;
    bit<1>  bit3;
    bit<1>  bit4;
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

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<1> tmp;
    bit<1> tmp_0;
    bit<1> tmp_1;
    bit<1> tmp_2;
    @name(".reg") register<bit<1>>(32w1000) reg_0;
    @name("sful1") register_action<bit<1>, bit<1>>(reg_0) sful1_0 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = value;
            value = 1w1;
        }
    };
    @name("sful2") register_action<bit<1>, bit<1>>(reg_0) sful2_0 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = value;
            value = 1w0;
        }
    };
    @name("sful3") register_action<bit<1>, bit<1>>(reg_0) sful3_0 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = value;
            value = value;
        }
    };
    @name("sful4") register_action<bit<1>, bit<1>>(reg_0) sful4_0 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = ~value;
            value = value;
        }
    };
    @name(".output") action output_0(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".set") action set_1() {
        tmp = sful1_0.execute(32w1);
        hdr.data.bit1 = tmp;
    }
    @name(".clr") action clr_0() {
        tmp_0 = sful2_0.execute(32w1);
        hdr.data.bit1 = tmp_0;
    }
    @name(".read") action read_0() {
        tmp_1 = sful3_0.execute(32w1);
        hdr.data.bit1 = tmp_1;
    }
    @name(".readc") action readc_0() {
        tmp_2 = sful4_0.execute(32w1);
        hdr.data.bit1 = tmp_2;
    }
    @name(".noop") action noop_0() {
    }
    @name(".do_out") table do_out_0 {
        actions = {
            output_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = NoAction();
    }
    @name(".test1") table test1_0 {
        actions = {
            set_1();
            clr_0();
            read_0();
            readc_0();
            noop_0();
        }
        key = {
            hdr.data.b1: exact @name("data.b1") ;
        }
        default_action = noop_0();
    }
    apply {
        test1_0.apply();
        do_out_0.apply();
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
