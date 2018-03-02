#include <core.p4>
#include <v1model.p4>

header one_byte_t {
    bit<8> a;
}

header hdr_stack_t {
    bit<8>  a;
    bit<8>  b;
    bit<16> c;
    bit<32> d;
}

struct metadata {
}

struct headers {
    @name(".one") 
    one_byte_t     one;
    @name(".hdr_stack_") 
    hdr_stack_t[3] hdr_stack_;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".oneb") state oneb {
        packet.extract<one_byte_t>(hdr.one);
        transition stck;
    }
    @name(".start") state start {
        transition oneb;
    }
    @name(".stck") state stck {
        packet.extract<hdr_stack_t>(hdr.hdr_stack_.next);
        transition select(hdr.hdr_stack_.last.b) {
            8w0: stck;
            8w1: accept;
            default: accept;
        }
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".do_nothing") action do_nothing() {
    }
    @name(".action_0") action action_0() {
        hdr.one.a = hdr.one.a + 8w1;
    }
    @name(".push_3") action push_3() {
        hdr.hdr_stack_.push_front(3);
        hdr.hdr_stack_[0].setValid();
        hdr.hdr_stack_[1].setValid();
        hdr.hdr_stack_[2].setValid();
    }
    @name(".push_2") action push_2() {
        hdr.hdr_stack_.push_front(2);
        hdr.hdr_stack_[0].setValid();
        hdr.hdr_stack_[1].setValid();
    }
    @name(".pop_2") action pop_2() {
        hdr.hdr_stack_.pop_front(2);
    }
    @name(".pop_1") action pop_1() {
        hdr.hdr_stack_.pop_front(1);
    }
    @name(".table_i0") table table_i0 {
        actions = {
            do_nothing();
            action_0();
            push_3();
            push_2();
            pop_2();
            pop_1();
            @defaultonly NoAction();
        }
        key = {
            hdr.one.a: ternary @name("one.a") ;
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
        packet.emit<one_byte_t>(hdr.one);
        packet.emit<hdr_stack_t[3]>(hdr.hdr_stack_);
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

