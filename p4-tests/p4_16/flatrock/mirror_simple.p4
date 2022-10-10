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
        // Table currently causes this error:
        //
        //   error: Table ig_mirr_tbl_0$action_data using out-of-bounds Mem 0,15,0
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

        // FIXME: re-enable this when issue in table comment is addressed
        // ig_mirr_tbl.apply();

        if (hdrs.data.f1 == 0x12345678) {
            ig_intr_tm_md.mirror_bitmap = hdrs.data.h1;
        }
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
        // Motify a field to test ingress vs egress mirror
        // hdrs.data.h2 = ~hdrs.data.h2;
        hdrs.data.h2 = hdrs.data.h1;

        // FIXME: re-enable this when issues in table comment are addressed
        // eg_mirr_tbl.apply();

        if (hdrs.data.f2 == 0x12345678) {
            eg_intr_dprs_md.mirror_io_select = hdrs.data.b1[0:0];
            eg_intr_dprs_md.mirror_type = (MirrorType_t)hdrs.data.b1[7:4];
            meta.mirr_sess_id = (MirrorId_t)hdrs.data.b2;
        }
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
