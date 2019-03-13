#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<32> a;
    bit<8>  b;
    bit<5>  c;
    bit<3>  d;
}

header one_byte_t {
    bit<8> a;
}

header zero_byte_t {
    bit<8> a;
}

struct metadata {
    @name(".meta") 
    meta_t meta;
}

struct headers {
    @name(".one") 
    one_byte_t  one;
    @name(".zero") 
    zero_byte_t zero;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".oneb") state oneb {
        packet.extract<one_byte_t>(hdr.one);
        meta.meta.b = hdr.one.a;
        meta.meta.a = 32w0x7;
        meta.meta.c = 5w1;
        meta.meta.d = 3w2;
        transition accept;
    }
    @name(".start") state start {
        transition zerob;
    }
    @name(".twob") state twob {
        packet.extract<one_byte_t>(hdr.one);
        meta.meta.c = 5w2;
        transition accept;
    }
    @name(".zerob") state zerob {
        packet.extract<zero_byte_t>(hdr.zero);
        transition select(hdr.zero.a) {
            8w0: oneb;
            default: twob;
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_0") action action_0(bit<32> p) {
        hdr.one.a = hdr.one.a + 8w1;
        meta.meta.a = meta.meta.a + p;
    }
    @name(".table_i0") table table_i0 {
        actions = {
            do_nothing();
            action_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.one.a  : ternary @name("one.a") ;
            meta.meta.a: exact @name("meta.a") ;
            meta.meta.b: exact @name("meta.b") ;
            meta.meta.c: exact @name("meta.c") ;
            meta.meta.d: exact @name("meta.d") ;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        table_i0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<zero_byte_t>(hdr.zero);
        packet.emit<one_byte_t>(hdr.one);
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

