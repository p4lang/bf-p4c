#include <core.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_TEST = 16w0x8822;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header test_h {
    bit<16> id;
    bit<8> type;
    bit<8> input_field_0;
    bit<8> input_field_1;
    bit<8> output_field_0;
    bit<8> output_field_1;
}

struct headers {
    ethernet_h ethernet;
    test_h test;
}

struct metadata {

}

parser ParserImpl(
        packet_in pkt,
        out headers hdr,
        out metadata ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        transition reject;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_TEST : parse_test;
            default : reject;
        }
    }

    state parse_test {
        pkt.extract(hdr.test);
        transition accept;
    }
}

control ingress(
        inout headers hdr,
        inout metadata ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<bit<8>, bit<8>>(256, 0) reg1;
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg1) reg1_action_1 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = value | hdr.test.input_field_1;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg1) reg1_action_2 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = value | hdr.test.input_field_1;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg1) reg1_action_3 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = hdr.test.input_field_1 | value;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg1) reg1_action_4 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = hdr.test.input_field_1 | value;
        }
    };

    Register<bit<8>, bit<8>>(256, 0) reg2;
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg2) reg2_action_1 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = value | ~hdr.test.input_field_1;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg2) reg2_action_2 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = value | ~hdr.test.input_field_1;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg2) reg2_action_3 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = hdr.test.input_field_1 | ~value;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg2) reg2_action_4 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = hdr.test.input_field_1 | ~value;
        }
    };

    Register<bit<8>, bit<8>>(256, 0) reg3;
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg3) reg3_action_1 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = ~hdr.test.input_field_1;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg3) reg3_action_2 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = ~hdr.test.input_field_1;
        }
    };

    Register<bit<8>, bit<8>>(256, 0) reg4;
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg4) reg4_action_1 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = value ^ ~hdr.test.input_field_1;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg4) reg4_action_2 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = value ^ ~hdr.test.input_field_1;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg4) reg4_action_3 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = hdr.test.input_field_1 ^ ~value;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg4) reg4_action_4 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = hdr.test.input_field_1 ^ ~value;
        }
    };

    Register<bit<8>, bit<8>>(256, 0) reg5;
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg5) reg5_action_1 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = -hdr.test.input_field_1;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg5) reg5_action_2 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = -hdr.test.input_field_1;
        }
    };

    Register<bit<8>, bit<8>>(256, 0xff) reg6;
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg6) reg6_action_1 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = value & ~hdr.test.input_field_1;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg6) reg6_action_2 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = value & ~hdr.test.input_field_1;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg6) reg6_action_3 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            value = hdr.test.input_field_1 & ~value;
            ret = 0;
        }
    };
    RegisterAction<bit<8>, bit<8>, bit<8>>(reg6) reg6_action_4 = {
        void apply(inout bit<8> value, out bit<8> ret) {
            ret = hdr.test.input_field_1 & ~value;
        }
    };

    action do_reg_action1() {
        hdr.test.output_field_0 = reg1_action_1.execute(hdr.test.input_field_0);
    }
    action do_reg_action2() {
        hdr.test.output_field_0 = reg1_action_2.execute(hdr.test.input_field_0);
    }
    action do_reg_action3() {
        hdr.test.output_field_0 = reg1_action_3.execute(hdr.test.input_field_0);
    }
    action do_reg_action4() {
        hdr.test.output_field_0 = reg1_action_4.execute(hdr.test.input_field_0);
    }

    action do_reg2_action1() {
        hdr.test.output_field_0 = reg2_action_1.execute(hdr.test.input_field_0);
    }
    action do_reg2_action2() {
        hdr.test.output_field_0 = reg2_action_2.execute(hdr.test.input_field_0);
    }
    action do_reg2_action3() {
        hdr.test.output_field_0 = reg2_action_3.execute(hdr.test.input_field_0);
    }
    action do_reg2_action4() {
        hdr.test.output_field_0 = reg2_action_4.execute(hdr.test.input_field_0);
    }

    action do_reg3_action1() {
        hdr.test.output_field_0 = reg3_action_1.execute(hdr.test.input_field_0);
    }
    action do_reg3_action2() {
        hdr.test.output_field_0 = reg3_action_2.execute(hdr.test.input_field_0);
    }

    action do_reg4_action1() {
        hdr.test.output_field_0 = reg4_action_1.execute(hdr.test.input_field_0);
    }
    action do_reg4_action2() {
        hdr.test.output_field_0 = reg4_action_2.execute(hdr.test.input_field_0);
    }
    action do_reg4_action3() {
        hdr.test.output_field_0 = reg4_action_3.execute(hdr.test.input_field_0);
    }
    action do_reg4_action4() {
        hdr.test.output_field_0 = reg4_action_4.execute(hdr.test.input_field_0);
    }

    action do_reg5_action1() {
        hdr.test.output_field_0 = reg5_action_1.execute(hdr.test.input_field_0);
    }
    action do_reg5_action2() {
        hdr.test.output_field_0 = reg5_action_2.execute(hdr.test.input_field_0);
    }

    action do_reg6_action1() {
        hdr.test.output_field_0 = reg6_action_1.execute(hdr.test.input_field_0);
    }
    action do_reg6_action2() {
        hdr.test.output_field_0 = reg6_action_2.execute(hdr.test.input_field_0);
    }
    action do_reg6_action3() {
        hdr.test.output_field_0 = reg6_action_3.execute(hdr.test.input_field_0);
    }
    action do_reg6_action4() {
        hdr.test.output_field_0 = reg6_action_4.execute(hdr.test.input_field_0);
    }

    table t {
        key = { hdr.test.type : exact; }
        actions = {
            do_reg_action1;
            do_reg_action2;
            do_reg_action3;
            do_reg_action4;
        }
        const entries = {
            1 : do_reg_action1();
            2 : do_reg_action2();
            3 : do_reg_action3();
            4 : do_reg_action4();
        }
        size = 5;
    }

    table t2 {
        key = { hdr.test.type : exact; }
        actions = {
            do_reg2_action1;
            do_reg2_action2;
            do_reg2_action3;
            do_reg2_action4;
        }
        const entries = {
            5 : do_reg2_action1();
            6 : do_reg2_action2();
            7 : do_reg2_action3();
            8 : do_reg2_action4();
        }
        size = 5;
    }

    table t3 {
        key = { hdr.test.type : exact; }
        actions = {
            do_reg3_action1;
            do_reg3_action2;
        }
        const entries = {
            9  : do_reg3_action1();
            10 : do_reg3_action2();
        }
        size = 5;
    }

    table t4 {
        key = { hdr.test.type : exact; }
        actions = {
            do_reg4_action1;
            do_reg4_action2;
            do_reg4_action3;
            do_reg4_action4;
        }
        const entries = {
            11 : do_reg4_action1();
            12 : do_reg4_action2();
            13 : do_reg4_action3();
            14 : do_reg4_action4();
        }
        size = 5;
    }

    table t5 {
        key = { hdr.test.type : exact; }
        actions = {
            do_reg5_action1;
            do_reg5_action2;
        }
        const entries = {
            15 : do_reg5_action1();
            16 : do_reg5_action2();
        }
        size = 5;
    }

    table t6 {
        key = { hdr.test.type : exact; }
        actions = {
            do_reg6_action1;
            do_reg6_action2;
            do_reg6_action3;
            do_reg6_action4;
        }
        const entries = {
            17 : do_reg6_action1();
            18 : do_reg6_action2();
            19 : do_reg6_action3();
            20 : do_reg6_action4();
        }
        size = 5;
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = 0x000000000001;

        if (hdr.test.isValid()) {
            if (t.apply().miss) {
                if (t2.apply().miss) {
                    if (t3.apply().miss) {
                        if (t4.apply().miss) {
                            if (t5.apply().miss) {
                                t6.apply();
                            }
                        }
                    }
                }
            }
        }
    }
}

#include "common_tna_test.h"
