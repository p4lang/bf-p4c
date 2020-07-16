#include <tna.p4>
#define DATA_T_OVERRIDE

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
    int<8>  i1;
    int<8>  i2;
    bit<64> l1;
    //bit<4>  n1;
    //bit<4>  n2;
}

struct metadata {
    bool is_gtequ;
    bool is_gteqs;
    bool is_ltu;
    bool is_lts;
    bool is_lequ;
    bool is_leqs;
    bool is_gtu;
    bool is_gts;
    bool is_eq;
    bool is_neq;
    bool is_eq64;
    bool is_neq64;
    //bit<4> wide;
}

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action gtequ(bit<8> val) {
        meta.is_gtequ = hdr.data.b1 >= val;
        //meta.wide = (bit<4>)(bit<1>)(hdr.data.b1 >= val);
    }

    action gteqs(int<8> val) {
        meta.is_gteqs = hdr.data.i1 >= val;
    }

    action ltu(bit<8> val) {
        meta.is_ltu = hdr.data.b1 < val;
    }

    action lts(int<8> val) {
        meta.is_lts = hdr.data.i1 < val;
    }

    action lequ(bit<8> val) {
        meta.is_lequ = hdr.data.b1 <= val;
    }

    action leqs(int<8> val) {
        meta.is_leqs = hdr.data.i1 <= val;
    }

    action gtu(bit<8> val) {
        meta.is_gtu = hdr.data.b1 > val;
    }

    action gts(int<8> val) {
        meta.is_gts = hdr.data.i1 > val;
    }

    action eq(bit<8> val) {
        meta.is_eq = hdr.data.b1 == val;
    }

    action neq(bit<8> val) {
        meta.is_neq = hdr.data.b1 != val;
    }

    /*
    action eq64(bit<64> val) {
        meta.is_eq64 = hdr.data.l1 == val;
    }

    action neq64(bit<64> val) {
        meta.is_neq64 = hdr.data.l1 != val;
    }
    */

    table test1 {
        key = { hdr.data.f1 : exact; }
        actions = {
            NoAction;
            gtequ;
            gteqs;
            ltu;
            lts;
            lequ;
            leqs;
            gtu;
            gts;
            eq;
            neq;
            //eq64;
            //neq64;
        }

        const default_action = NoAction;
    }

    apply {
        meta.is_gtequ = false;
        meta.is_gteqs = false;
        meta.is_ltu = false;
        meta.is_lts = false;
        meta.is_lequ = false;
        meta.is_leqs = false;
        meta.is_gtu = false;
        meta.is_gts = false;
        meta.is_eq = false;
        meta.is_neq = false;
        meta.is_eq64 = false;
        meta.is_neq64 = false;

        ig_intr_tm_md.ucast_egress_port = 3;
        test1.apply();
        if (meta.is_gtequ) {
            hdr.data.f2 = 32w0x00000001;
        } else if (meta.is_gteqs) {
            hdr.data.f2 = 32w0x00000002;
        } else if (meta.is_ltu) {
            hdr.data.f2 = 32w0x00000004;
        } else if (meta.is_lts) {
            hdr.data.f2 = 32w0x00000008;
        } else if (meta.is_lequ) {
            hdr.data.f2 = 32w0x00000010;
        } else if (meta.is_leqs) {
            hdr.data.f2 = 32w0x00000020;
        } else if (meta.is_gtu) {
            hdr.data.f2 = 32w0x00000040;
        } else if (meta.is_gts) {
            hdr.data.f2 = 32w0x00000080;
        } else if (meta.is_eq) {
            hdr.data.f2 = 32w0x00000100;
        } else if (meta.is_neq) {
            hdr.data.f2 = 32w0x00000200;
        } else if (meta.is_eq64) {
            hdr.data.f2 = 32w0x00000400;
        } else if (meta.is_neq64) {
            hdr.data.f2 = 32w0x00000800;
        }
        //hdr.data.n1 = meta.wide;
    }
}

#include "common_tna_test.h"
