#include <core.p4>
#include <v1model.p4>

header Hdr {
    bit<8> is_green_0;
    bit<8> is_green_1;
    bit<8> is_green_2;
    bit<8> _pad;
}

struct Headers { Hdr hdr; }

struct Meta {
    bit<2> mtr_out;
}

parser p(packet_in b, out Headers h,
         inout Meta m, inout standard_metadata_t sm) {
    state start {
        transition accept;
    }
}

control vrfy(inout Headers h, inout Meta m) { apply {} }
control update(inout Headers h, inout Meta m) { apply {} }

control ingress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    meter(512, MeterType.bytes) mtr_0;
    meter(512, MeterType.bytes) mtr_1;
    meter(512, MeterType.bytes) mtr_2;

    action a_mtr_0(bit<32> idx) {
        mtr_0.execute_meter(idx, m.mtr_out);
    }

    table t_mtr_0 {
        key = { sm.ingress_port: exact; }
        actions = { a_mtr_0; }
    }

    apply {
        h.hdr.setValid();

        t_mtr_0.apply();
        if (m.mtr_out == 0) {  // green
            h.hdr.is_green_0 = 1;
        } else {
            h.hdr.is_green_0 = 0;
        }

        mtr_1.execute_meter((bit<32>)sm.ingress_port, m.mtr_out);
        if (m.mtr_out == 0) {  // green
            h.hdr.is_green_1 = 1;
        } else {
            h.hdr.is_green_1 = 0;
        }

        mtr_2.execute_meter(0, m.mtr_out);
        if (m.mtr_out == 0) {  // green
            h.hdr.is_green_2 = 1;
        } else {
            h.hdr.is_green_2 = 0;
        }

        sm.egress_spec = sm.ingress_port;
    }
}

control egress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    apply { }
}

control deparser(packet_out b, in Headers h) {
    apply { b.emit(h); }
}

V1Switch(p(), vrfy(), ingress(), egress(), update(), deparser()) main;
