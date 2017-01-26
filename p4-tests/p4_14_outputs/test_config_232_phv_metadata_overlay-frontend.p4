#include <core.p4>
#include <v1model.p4>

struct meta_t {
    bit<16> tbl0_tbl1;
    bit<16> tbl0_tbl2;
    bit<16> tbl0_tbl3;
    bit<16> tbl1_tbl2;
    bit<16> tbl1_tbl3;
    bit<16> tbl2_tbl3;
    bit<16> tbl0;
    bit<16> tbl1;
    bit<16> tbl2;
    bit<16> tbl3;
    bit<16> tbl4;
}

header hdr0_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

header hdr1_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

header hdr2_t {
    bit<16> a;
    bit<8>  b;
    bit<8>  c;
}

struct metadata {
    @name("meta") 
    meta_t meta;
}

struct headers {
    @name("hdr0") 
    hdr0_t hdr0;
    @name("hdr1") 
    hdr1_t hdr1;
    @name("hdr2") 
    hdr2_t hdr2;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("p_hdr0") state p_hdr0 {
        packet.extract<hdr0_t>(hdr.hdr0);
        transition select(hdr.hdr0.c) {
            8w0: p_hdr1;
            8w1: p_hdr2;
        }
    }
    @name("p_hdr1") state p_hdr1 {
        packet.extract<hdr1_t>(hdr.hdr1);
        transition p_hdr2;
    }
    @name("p_hdr2") state p_hdr2 {
        packet.extract<hdr2_t>(hdr.hdr2);
        transition accept;
    }
    @name("start") state start {
        transition p_hdr0;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("cnt_0") counter(32w2048, CounterType.packets_and_bytes) cnt;
    @name("do_nothing") action do_nothing_0() {
    }
    @name("action_0") action action_5(bit<11> idx) {
        meta.meta.tbl0_tbl1 = 16w1;
        meta.meta.tbl0_tbl2 = 16w1;
        meta.meta.tbl0_tbl3 = 16w1;
        meta.meta.tbl0 = 16w1;
        cnt.count((bit<32>)idx);
    }
    @name("action_1") action action_6() {
        meta.meta.tbl0_tbl1 = 16w1;
        meta.meta.tbl1_tbl2 = 16w1;
        meta.meta.tbl1_tbl3 = 16w1;
        meta.meta.tbl1 = 16w1;
    }
    @name("action_2") action action_7() {
        meta.meta.tbl0_tbl2 = 16w1;
        meta.meta.tbl1_tbl2 = 16w1;
        meta.meta.tbl2_tbl3 = 16w1;
        meta.meta.tbl2 = 16w1;
    }
    @name("action_3") action action_8() {
        meta.meta.tbl0_tbl3 = 16w1;
        meta.meta.tbl1_tbl3 = 16w1;
        meta.meta.tbl2_tbl3 = 16w1;
        meta.meta.tbl3 = 16w1;
    }
    @name("action_4") action action_9() {
        meta.meta.tbl4 = 16w1;
    }
    @name("table_i0") table table_i0_0() {
        actions = {
            do_nothing_0();
            action_5();
            @default_only NoAction();
        }
        key = {
            hdr.hdr0.a    : ternary;
            meta.meta.tbl0: exact;
        }
        size = 512;
        default_action = NoAction();
    }
    @name("table_i1") table table_i1_0() {
        actions = {
            do_nothing_0();
            action_6();
            @default_only NoAction();
        }
        key = {
            hdr.hdr0.a         : ternary;
            meta.meta.tbl1     : exact;
            meta.meta.tbl0_tbl1: exact;
        }
        size = 512;
        default_action = NoAction();
    }
    @name("table_i2") table table_i2_0() {
        actions = {
            do_nothing_0();
            action_7();
            @default_only NoAction();
        }
        key = {
            hdr.hdr0.a         : ternary;
            meta.meta.tbl2     : exact;
            meta.meta.tbl0_tbl2: exact;
            meta.meta.tbl1_tbl2: exact;
        }
        size = 512;
        default_action = NoAction();
    }
    @name("table_i3") table table_i3_0() {
        actions = {
            do_nothing_0();
            action_8();
            @default_only NoAction();
        }
        key = {
            hdr.hdr0.a         : ternary;
            meta.meta.tbl3     : exact;
            meta.meta.tbl0_tbl3: exact;
            meta.meta.tbl1_tbl3: exact;
            meta.meta.tbl2_tbl3: exact;
        }
        size = 512;
        default_action = NoAction();
    }
    @name("table_i4") table table_i4_0() {
        actions = {
            do_nothing_0();
            action_9();
            @default_only NoAction();
        }
        key = {
            hdr.hdr0.a    : ternary;
            hdr.hdr1.b    : exact;
            meta.meta.tbl4: exact;
        }
        size = 512;
        default_action = NoAction();
    }
    apply {
        if (hdr.hdr0.c == 8w0) {
            table_i0_0.apply();
            table_i1_0.apply();
            table_i2_0.apply();
            table_i3_0.apply();
        }
        else 
            table_i4_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr0_t>(hdr.hdr0);
        packet.emit<hdr1_t>(hdr.hdr1);
        packet.emit<hdr2_t>(hdr.hdr2);
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

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
