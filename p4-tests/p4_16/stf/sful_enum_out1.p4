#include <tna.p4>

struct metadata { }

enum burst_state { NEW, SMALL, LARGE };

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

    Register<burst_data, bit<13>>(8192) reg;
    RegisterAction<burst_data, bit<13>, burst_state>(reg) bursts = {
        void apply(inout burst_data data, out burst_state burst) {
            if (hdr.data.f2 - data.timestamp <= BURST_INTERPACKET_DELAY) {
                if (data.count >= BURST_SIZE)
                    burst = burst_state.LARGE;
                else
                    burst = burst_state.SMALL;
                data.count = data.count + 1;
            } else {
                burst = burst_state.NEW;
                data.count = 1; }
            data.timestamp = hdr.data.f2;
        }
    };

    apply {
        burst_state is_burst = bursts.execute(hdr.data.f1[12:0]);
        if (is_burst == burst_state.NEW) {
            ig_intr_tm_md.ucast_egress_port = 2;
        } else if (is_burst == burst_state.SMALL) {
            ig_intr_tm_md.ucast_egress_port = 4;
        } else if (is_burst == burst_state.LARGE) {
            ig_intr_tm_md.ucast_egress_port = 6;
        }
    }
}

#include "common_tna_test.h"
