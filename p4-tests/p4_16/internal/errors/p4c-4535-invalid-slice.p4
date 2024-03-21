#include <core.p4>
#include <t2na.p4>

typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;

header ethernet_h {
    mac_addr_t    dst_addr;
    mac_addr_t    src_addr;
    ether_type_t  ether_type;
}

struct headers {
    ethernet_h ethernet;
}

struct metadata {}

struct pair {
    bit<64>     first;
    bit<64>     second;
}

parser ParserImpl(
        packet_in pkt,
        out headers hdr,
        out metadata ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control ingress(
        inout headers hdr,
        inout metadata ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    pair input;
    pair output;
    
    Register<pair, bit<32>>(size=32w1024, initial_value={5, 7}) test_reg;

    RegisterAction<pair, bit<32>, bit<32>>(test_reg) test_reg_read = {
        void apply(inout pair value, out bit<32> rv1){
            rv1 = value.second[47:16]; /* expect error: "Slices assigned to outputs of register actions \
cannot cross the 32-bit boundary" */
        }
    };

    apply {
            hdr.ethernet.src_addr[47:16] = test_reg_read.execute(0);
            ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"
