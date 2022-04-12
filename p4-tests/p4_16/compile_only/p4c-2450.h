/* -*- P4_16 -*- */
// vim: ft=p4
#include <core.p4>

struct my_md_t {
#if HAVE_SIGNED
    int<16> a;
#else
    bit<16> a;
#endif
}

struct metadata {
    my_md_t my_md;
}

struct headers { }

parser ParserImpl(packet_in packet,
                  out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
#if HAVE_SIGNED && !HAVE_OVERFLOW
        meta.my_md.a = 0x7123;
#else
        meta.my_md.a = 0xf123;
#endif
        transition accept;
    }
}

control ingress(inout headers hdr,
                inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action set_qid() { }
    table select_q {
        actions = {
            set_qid;
        }
        key = {
#if HAVE_SIGNED && !HAVE_OVERFLOW
            meta.my_md.a & 0x4000: exact;
#else
            meta.my_md.a & 0x8000: exact;
#endif
        }
        default_action = set_qid();
        size = 2;
    }
    apply {
        select_q.apply();
    }
}
