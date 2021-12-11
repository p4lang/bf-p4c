#include <tna.p4>

struct metadata { }

struct burst_data {
    bit<32> timestamp;
    bit<32> count;
};
#define BURST_INTERPACKET_DELAY 10
#define BURST_SIZE 4

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    Register<burst_data,_>(8192) reg;
    RegisterAction<burst_data,_,bit<1>>(reg) bursts = {
        void apply(inout burst_data data, out bit<1> burst) {
            burst = 0;
            if (hdr.data.f2 - data.timestamp <= BURST_INTERPACKET_DELAY) {
                if (data.count >= BURST_SIZE)
                    burst = 1;
                data.count = data.count + 1;
            } else {
                data.count = 1; }
            data.timestamp = hdr.data.f2;
        }
    };

    apply {
        bit<1> is_burst = bursts.execute(hdr.data.f1[12:0]);
        if (is_burst == 1) {
            ig_intr_tm_md.ucast_egress_port = 4;
        } else {
            ig_intr_tm_md.ucast_egress_port = 2;
        }
    }
}

#include "common_tna_test.h"
