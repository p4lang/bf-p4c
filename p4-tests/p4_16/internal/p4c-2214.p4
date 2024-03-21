#include <core.p4>
#include <v1model.p4>

struct metadata {
    bool        flag1;
    bool        flag2;
}

//#define METADATA_INIT(M) M.flag1 = (bool)0; M.flag2 = (bool)0;

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action setb1(bit<8> val) { hdr.data.b1 = val; }
    action noop() { }
    action set_flag1() { meta.flag1 = true; }
    action set_flag2() { meta.flag2 = true; }
    @disable_atomic_modify(0)
    table flg1 {
        key = { hdr.data.f1: exact; }
        actions = { set_flag1; noop; } }
    @disable_atomic_modify(1)
    table flg2 {
        key = { hdr.data.f1: exact; }
        actions = { set_flag2; noop; } }
    @disable_atomic_modify(55)
    table test {
        key = { hdr.data.f1: ternary; }
        actions = { setb1; noop; }
        default_action = setb1(0xaa); }

    apply {
        standard_metadata.egress_spec = 2;
        flg1.apply();
        flg2.apply();
        if (hdr.data.f2[7:0] == 2 && hdr.data.f2[15:12] == 0 && meta.flag1 && meta.flag2) {
            test.apply(); } }
}

#include "common_v1_test.h"
