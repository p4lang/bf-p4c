#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "util.h"

struct metadata_t {
    bit<8> value;
}

struct register_data_t {
    bit<8> data;
    bit<8> range;
}

struct header_t {
    ethernet_h ethernet;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        ig_md.value = 8w4;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    Register<register_data_t,bit<16>>(size=32w2, initial_value={0,0}) Tower;
    RegisterAction<register_data_t, bit<16>, bit<8>>(Tower) Branch1 = {
        void apply(inout register_data_t register_data, out bit<8> result) {
            if (register_data.data[3:0] < (bit<4>)ig_md.value) {
                register_data.data = register_data.data + 32;
                register_data.range = (bit<8>)register_data.data[3:0];
                result=8w0;
            }
        }
    };

    action register_action(bit<32> idx) {
        Branch1.execute((bit<16>)idx);
    }

    table reg_match {
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            register_action;
        }
        size = 1024;
    }

    apply {
        reg_match.apply();
        // Send the packet back where it came from.
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;

    }
}

struct empty_header_t {}

struct empty_metadata_t {}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser<empty_header_t,empty_metadata_t>(),
         EmptyEgress<empty_header_t,empty_metadata_t>(),
         EmptyEgressDeparser<empty_header_t,empty_metadata_t>()) pipe;

Switch(pipe) main;
