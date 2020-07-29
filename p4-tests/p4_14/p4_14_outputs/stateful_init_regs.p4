#include <core.p4>
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<16> h2;
    bit<8>  b1;
    bit<8>  b2;
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

@name(".accum1") register<bit<16>>(32w0) accum1;

struct sful_hi_layout {
    bit<8> lo;
    bit<8> hi;
}

@name(".accum2") register<sful_hi_layout>(32w0) accum2;

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @initial_register_hi_value(1) @name(".sful_hi") RegisterAction<sful_hi_layout, bit<8>>(accum2) sful_hi = {
        void apply(inout         struct sful_hi_layout {
            bit<8> lo;
            bit<8> hi;
        }
value, out bit<8> rv) {
            rv = 8w0;
            sful_hi_layout in_value;
            in_value = value;
            rv = in_value.hi;
            value.hi = in_value.hi + 8w2;
        }
    };
    @initial_register_lo_value(5) @name(".sful_lo") RegisterAction<bit<16>, bit<16>>(accum1) sful_lo = {
        void apply(inout bit<16> value, out bit<16> rv) {
            rv = 16w0;
            bit<16> in_value;
            in_value = value;
            rv = in_value;
            value = in_value + 16w1;
        }
    };
    @name(".addb1") action addb1(bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.data.h1 = sful_lo.execute();
    }
    @name(".addb2") action addb2() {
        hdr.data.h2 = (bit<16>)sful_hi.execute();
    }
    @name(".test1") table test1 {
        actions = {
            addb1;
        }
        key = {
            hdr.data.f1: exact;
        }
    }
    @name(".test2") table test2 {
        actions = {
            addb2;
        }
        key = {
            hdr.data.f2: exact;
        }
    }
    apply {
        test1.apply();
        test2.apply();
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
