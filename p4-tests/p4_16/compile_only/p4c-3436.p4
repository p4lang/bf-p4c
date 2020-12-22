#include <tna.p4>

struct Cassa {
    bit<16> Chugwater;
    bit<16> Charco;
    bit<16> Pawtucket;
    bit<16> Buckhorn;
    bit<16> Montross;
    bit<16> Glenmora;
    bit<8>  Colona;
    bit<8>  Naruna;
    bit<8>  Sewaren;
    bit<8>  Rainelle;
    bit<1>  Paulding;
    bit<6>  Denhoff;
}

struct metadata {
    Cassa       Daisytown;
}

#include "trivial_parser.h"

header simple_struct {
    bit<16> a;
}

control ingress(inout headers h, inout metadata m,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action setup() {
        m.Daisytown.Chugwater = h.data.f1[31:16];
        m.Daisytown.Charco = h.data.f1[15:0];
        m.Daisytown.Montross = h.data.f1[31:16];
        m.Daisytown.Glenmora = h.data.f1[15:0];
        m.Daisytown.Colona = h.data.h1[15:8];
        m.Daisytown.Denhoff = h.data.h1[5:0];
        m.Daisytown.Naruna = h.data.b2;
        m.Daisytown.Sewaren = h.data.b1 + h.data.b2 ;
        m.Daisytown.Paulding = h.data.h1[6:6];
    }

    action Turney(bit<32> Tehachapi) {
        h.data.f1 = max<bit<32>>(h.data.f1, Tehachapi);
    }
    @ways(1) @pack(1) @force_immediate(1) @disable_atomic_modify(1) table Macungie {
        key = {
            h.data.b1            : exact;
            m.Daisytown.Chugwater: exact;
            m.Daisytown.Charco   : exact;
            m.Daisytown.Montross : exact;
            m.Daisytown.Glenmora : exact;
            m.Daisytown.Colona   : exact;
            m.Daisytown.Denhoff  : exact;
            m.Daisytown.Naruna   : exact;
            m.Daisytown.Sewaren  : exact;
            m.Daisytown.Paulding : exact;
        }
        actions = {
            Turney();
            @defaultonly NoAction();
        }
        size = 8192;
        default_action = NoAction();
    }



    apply {
        ig_tm_md.ucast_egress_port = 3;
        setup();
        Macungie.apply();
    }
}

#include "common_tna_test.h"
