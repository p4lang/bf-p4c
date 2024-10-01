#include <tna.p4>

#define DATA_T_OVERRIDE
header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<32> f3;
    bit<32> f4;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
}

struct metadata {
}

#include "trivial_parser.h"

// We have to force b2 to be placed in 8-bit container because our STF test code,
// for now, have hard-coded action_addr: 0x100. This address needs to be changed if we
// allocate differently. For example, if we allocate b2 to 16-bit container, then it
// needs to be 0x200.
@pa_container_size("ingress", "hdr.data.b2", 8)
control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_fn;
    ActionProfile(1024) ap;
    ActionSelector(ap, hash_fn, SelectorMode_t.FAIR, 120, 16) sel_profile;
    action sel_miss() { hdr.data.b3 = 0xff; }
    action set_b2(bit<8> v) { hdr.data.b2 = v; }
    table select_output {
        actions = { set_b2; @defaultonly sel_miss; }
        key = {
            hdr.data.b1: exact;
            hdr.data.f1: selector;
            hdr.data.f2: selector;
            hdr.data.f3: selector;
            hdr.data.f4: selector;
        }
        size = 1024;
        implementation = sel_profile;
        const default_action = sel_miss;
    }
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        select_output.apply();
    }
}

#include "common_tna_test.h"
