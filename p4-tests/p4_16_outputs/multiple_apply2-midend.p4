#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

header data_t {
    bit<16> h1;
    bit<16> h2;
    bit<16> h3;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
    bit<8>  b5;
}

struct metadata {
}

struct headers {
    data_t data;
}

header ingress_skip_t {
    bit<64> pad;
}

parser ParserI(packet_in b, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip_0;
    state start {
        b.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        b.extract<ingress_skip_t>(skip_0);
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    bool tmp_0;
    bool inner_multiple_tmp;
    bool inner_multiple_tmp_0;
    @name("IngressP.inner_multiple.noop") action inner_multiple_noop_1() {
    }
    @name("IngressP.inner_multiple.noop") action inner_multiple_noop_2() {
    }
    @name("IngressP.inner_multiple.t2_act") action inner_multiple_t2_act_1(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name("IngressP.inner_multiple.t3_act") action inner_multiple_t3_act_1(bit<8> b5) {
        hdr.data.b5 = b5;
    }
    @name("IngressP.inner_multiple.t2") table inner_multiple_t2 {
        actions = {
            inner_multiple_t2_act_1();
            inner_multiple_noop_1();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = inner_multiple_noop_1();
    }
    @name("IngressP.inner_multiple.t3") table inner_multiple_t3 {
        actions = {
            inner_multiple_t3_act_1();
            inner_multiple_noop_2();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = inner_multiple_noop_2();
    }
    @name("IngressP.inner_multiple.noop") action inner_multiple_noop_5() {
    }
    @name("IngressP.inner_multiple.noop") action inner_multiple_noop_6() {
    }
    @name("IngressP.inner_multiple.t2_act") action inner_multiple_t2_act_2(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name("IngressP.inner_multiple.t3_act") action inner_multiple_t3_act_2(bit<8> b5) {
        hdr.data.b5 = b5;
    }
    @name("IngressP.inner_multiple.t2") table inner_multiple_t2_0 {
        actions = {
            inner_multiple_t2_act_2();
            inner_multiple_noop_5();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = inner_multiple_noop_5();
    }
    @name("IngressP.inner_multiple.t3") table inner_multiple_t3_0 {
        actions = {
            inner_multiple_t3_act_2();
            inner_multiple_noop_6();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = inner_multiple_noop_6();
    }
    @name("IngressP.noop") action noop() {
    }
    @name("IngressP.noop") action noop_2() {
    }
    @name("IngressP.set_port") action set_port(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("IngressP.t1_act") action t1_act(bit<8> b3) {
        hdr.data.b3 = b3;
    }
    @name("IngressP.t1") table t1_0 {
        actions = {
            t1_act();
            noop();
        }
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
        }
        default_action = noop();
    }
    @name("IngressP.port_setter") table port_setter_0 {
        actions = {
            set_port();
            noop_2();
        }
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = noop_2();
    }
    @hidden action act() {
        tmp_0 = true;
    }
    @hidden action act_0() {
        tmp_0 = false;
    }
    @hidden action act_1() {
        inner_multiple_tmp = true;
    }
    @hidden action act_2() {
        inner_multiple_tmp = false;
    }
    @hidden action act_3() {
        inner_multiple_tmp_0 = true;
    }
    @hidden action act_4() {
        inner_multiple_tmp_0 = false;
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    @hidden table tbl_act_2 {
        actions = {
            act_2();
        }
        const default_action = act_2();
    }
    @hidden table tbl_act_3 {
        actions = {
            act_3();
        }
        const default_action = act_3();
    }
    @hidden table tbl_act_4 {
        actions = {
            act_4();
        }
        const default_action = act_4();
    }
    apply {
        if (hdr.data.b1 == 8w0) {
            if (t1_0.apply().hit) 
                tbl_act.apply();
            else 
                tbl_act_0.apply();
            if (!tmp_0) 
                if (hdr.data.b2 == 8w0) {
                    if (inner_multiple_t2.apply().hit) 
                        tbl_act_1.apply();
                    else 
                        tbl_act_2.apply();
                    if (!inner_multiple_tmp) 
                        inner_multiple_t3.apply();
                }
                else 
                    inner_multiple_t3.apply();
        }
        else 
            if (hdr.data.b2 == 8w0) {
                if (inner_multiple_t2_0.apply().hit) 
                    tbl_act_3.apply();
                else 
                    tbl_act_4.apply();
                if (!inner_multiple_tmp_0) 
                    inner_multiple_t3_0.apply();
            }
            else 
                inner_multiple_t3_0.apply();
        port_setter_0.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    @hidden action act_5() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act_5 {
        actions = {
            act_5();
        }
        const default_action = act_5();
    }
    apply {
        tbl_act_5.apply();
    }
}

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    @hidden action act_6() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act_6 {
        actions = {
            act_6();
        }
        const default_action = act_6();
    }
    apply {
        tbl_act_6.apply();
    }
}

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

