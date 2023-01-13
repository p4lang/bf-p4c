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
            value = -value | hdr.test.input_field_1; /* expect error: "Unary negation \(-\) in Stateful \
ALU is only possible if it is the only operation in an expression\. Try simplifying your expression\." */
            ret = 0;
        }
    };

    action do_reg_action1() {
        hdr.test.output_field_0 = reg1_action_1.execute(hdr.test.input_field_0);
    }

    table t {
        key = { hdr.test.type : exact; }
        actions = {
            do_reg_action1;
        }
        const entries = {
            1 : do_reg_action1();
        }
        size = 5;
    }

    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = 0x000000000001;

        if (hdr.test.isValid()) {
            t.apply();
        }
    }
}

#include "common_tna_test.h"
