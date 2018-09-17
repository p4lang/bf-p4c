#include <t2na.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<128>, bit<10>>(1024) accum;
    RegisterAction<bit<128>, bit<10>, bit<8>>(accum) rmax = {
        void apply(inout bit<128> value, out bit<8> rv) {
            rv = this.max8(value, 0xffff);
        }
    };
    RegisterAction<bit<128>, bit<10>, bit<8>>(accum) load = {
        void apply(inout bit<128> value) {
            value[31:0] = hdr.data.f1;
        }
    };

    action nop() {}
    action doload(bit<10> idx) {
        ig_intr_tm_md.ucast_egress_port = 1;
        load.execute(idx); }
    action domax(bit<10> idx) {
        ig_intr_tm_md.ucast_egress_port = 2;
        hdr.data.b2 = rmax.execute(idx); }

    table test {
        key = { hdr.data.b1 : exact; }
        actions = { nop;  doload; domax; }
        default_action = nop;
    }

    apply {
        test.apply();
    }
}

#include "common_jna_test.h"
