#include <tna.p4>

@disable_reserved_i2e_drop_implementation
struct metadata {
    MirrorId_t session_id;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action noop() {}
    action setb1(bit<8> v, PortId_t port) {
        hdr.data.b1 = v;
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table test1 {
        key = {
            hdr.data.f1 : exact;
            hdr.data.f2 : exact;
        }
        actions = { noop; setb1; }
        size = 512;
        const default_action = noop();
    }

    apply {
        test1.apply();
        // ig_intr_dprs_md.mirror_type is invalidated by the
        // @disable_reserved_i2e_drop_implementation othewise, it's in the
        // init_zero list in ingress parser to ensure mirror_type is always
        // valid to use the mirror engine to drop packet.
        // P4C-4507
        if (!is_validated(ig_intr_dprs_md.mirror_type)) {
            ig_intr_dprs_md.mirror_type = 0;
            ig_intr_tm_md.ucast_egress_port = 4;
        }
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
        packet.emit(hdr);
    }
}
#define INGRESS_DPRSR_OVERRIDE

#include "common_tna_test.h"