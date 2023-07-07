#include <tna.p4>

#define NS_ACL_TABLE_SIZE       (10*1024)
#define GW_BYPASS(X)            false
#define METADATA_INIT(meta) meta.meter_id = 0;  meta.color = 0;

struct metadata {
    bit<24>     meter_id;
    bit<2>      color;
}

#include "trivial_parser.h"

control NsAclMeter(
        in headers hdr,
        in metadata local_md,
        inout bit<2> packet_color) {

    DirectMeter(MeterType_t.BYTES) meter;

    @name(".ns_acl_set_color")
    action set_color() {
        packet_color = (bit<2>) meter.execute(adjust_byte_count=sizeInBytes(hdr.data)-4);
    }

    @name(".ns_acl_meter")
    table acl_meter {
        key = {
            local_md.meter_id : exact @name("meter_id");
        }

        actions = {
            set_color;
        }

        default_action = set_color;
        meters = meter;
        size = NS_ACL_TABLE_SIZE * 2;
    }

    apply {
        if (!GW_BYPASS(METER) && local_md.meter_id != 0) {
            acl_meter.apply();
        }
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    NsAclMeter() acl_meter;
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        meta.meter_id = hdr.data.f1[23:0];
        acl_meter.apply(hdr, meta, meta.color);
        hdr.data.b1[1:0] = meta.color;
    }
}

#include "common_tna_test.h"
