// mirror simple
// -------------
//
// Tests basic mirror functionality:
//  - ingress mirror
//  - egresss mirror - input pkt
//  - egresss mirror - output pkt

#include <t5na.p4>

header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<16>     h2;
    bit<8>      b1;
    bit<8>      b2;
}

struct headers {
    data_h       data;
}

struct metadata {
    MirrorId_t   mirr_sess_id;
}

#define HAVE_INGRESS
control ingress(in headers hdrs, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action set_mirror(bit<16> mirror_bitmap) {
        ig_intr_tm_md.mirror_bitmap = mirror_bitmap;
    }
    action noop() { }

    table ig_mirr_tbl {
        key = {
            hdrs.data.f1 : exact;
            hdrs.data.h1 : exact;
        }
        actions = { noop; set_mirror; }
        size = 128;
        const default_action = noop();
    }

    apply {
        ig_intr_tm_md.ucast_egress_pipe = ig_intr_md.ingress_pipe;
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        ig_mirr_tbl.apply();
    }
}

control egress(inout headers hdrs, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprs_md,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md)
{
    action set_mirror(bit<1> io_sel, MirrorType_t mirror_type, MirrorId_t sess_id) {
        eg_intr_dprs_md.mirror_io_select = io_sel;
        eg_intr_dprs_md.mirror_type = mirror_type;
        meta.mirr_sess_id = sess_id;
    }
    action noop() { }

    table eg_mirr_tbl {
        key = {
            // These two fields cause:
            //
            //   In file: /data/bf-p4c-compilers/master-git/p4c/extensions/bf-p4c/mau/flatrock/table_format.cpp:98
            //   Compiler Bug: Cannot allocate wide RAMS in Flatrock. Invalid size 2
            // hdrs.data.b1 : exact;
            // hdrs.data.b2 : exact;

            // These two fields cause:
            //
            //   In file: /data/bf-p4c-compilers/master-git/p4c/extensions/bf-p4c/logging/resources.cpp:147
            //   Compiler Bug: Hash bit resource allows only one used_by (current: ig_mirr_tbl_0, incoming: eg_mirr_tbl_0)
            hdrs.data.f2 : exact;
            hdrs.data.h2 : exact;
        }
        actions = { noop; set_mirror; }
        size = 128;
        const default_action = noop();
    }

    apply {
        eg_mirr_tbl.apply();
    }
}

#define DPRSR_OVERRIDE
control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                       in egress_intrinsic_metadata_t eg_intr_md,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    Mirror(1) mirror1;

    apply {
        if (eg_intr_md_for_dprs.mirror_type == 1) {
            mirror1.emit((MirrorId_t)meta.mirr_sess_id);
        }

        packet.emit(hdrs);
    }
}

#include "common_t5na_test.p4h"