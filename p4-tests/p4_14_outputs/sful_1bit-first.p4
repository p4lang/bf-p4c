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

@name(".reg") register<bit<1>>(32w1000) reg;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".sful1") RegisterAction<bit<1>, bit<1>>(reg) sful1 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            rv = in_value;
            value = 1w1;
        }
    };
    @name(".sful2") RegisterAction<bit<1>, bit<1>>(reg) sful2 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            rv = in_value;
            value = 1w0;
        }
    };
    @name(".sful3") RegisterAction<bit<1>, bit<1>>(reg) sful3 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            rv = in_value;
            value = in_value;
        }
    };
    @name(".sful4") RegisterAction<bit<1>, bit<1>>(reg) sful4 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            rv = ~in_value;
            value = in_value;
        }
    };
    @name(".output") action output(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    @name(".set") action set_0() {
        hdr.data.bit1 = sful1.execute(32w1);
    }
    @name(".clr") action clr() {
        hdr.data.bit1 = sful2.execute(32w1);
    }
    @name(".read") action read() {
        hdr.data.bit1 = sful3.execute(32w1);
    }
    @name(".readc") action readc() {
        hdr.data.bit1 = sful4.execute(32w1);
    }
    @name(".noop") action noop() {
    }
    @name(".do_out") table do_out {
        actions = {
            output();
            @defaultonly NoAction();
        }
        key = {
            hdr.data.f1: exact @name("data.f1") ;
        }
        default_action = NoAction();
    }
    @name(".test1") table test1 {
        actions = {
            set_0();
            clr();
            read();
            readc();
            noop();
        }
        key = {
            hdr.data.b1: exact @name("data.b1") ;
        }
        default_action = noop();
    }
    apply {
        test1.apply();
        do_out.apply();
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

