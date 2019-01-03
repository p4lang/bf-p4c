#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

header data_t {
    bit<32> f1;
    bit<4>  x1;
    bit<4>  x2;
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
    @name("IngressP.set_port_act") action set_port_act(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("IngressP.setx1") action setx1(bit<4> x1) {
        hdr.data.x1 = x1;
    }
    @name("IngressP.setx1") action setx1_5(bit<4> x1) {
        hdr.data.x1 = x1;
    }
    @name("IngressP.setx1") action setx1_6(bit<4> x1) {
        hdr.data.x1 = x1;
    }
    @name("IngressP.setx1") action setx1_7(bit<4> x1) {
        hdr.data.x1 = x1;
    }
    @name("IngressP.setx1") action setx1_8(bit<4> x1) {
        hdr.data.x1 = x1;
    }
    @name("IngressP.setx2") action setx2(bit<4> x2) {
        hdr.data.x2 = x2;
    }
    @name("IngressP.setx2") action setx2_2(bit<4> x2) {
        hdr.data.x2 = x2;
    }
    @name("IngressP.setboth") action setboth(bit<4> x1, bit<4> x2) {
        hdr.data.x1 = x1;
        hdr.data.x2 = x2;
    }
    @name("IngressP.noop") action noop() {
    }
    @name("IngressP.noop") action noop_9() {
    }
    @name("IngressP.noop") action noop_10() {
    }
    @name("IngressP.noop") action noop_11() {
    }
    @name("IngressP.noop") action noop_12() {
    }
    @name("IngressP.noop") action noop_13() {
    }
    @name("IngressP.noop") action noop_14() {
    }
    @name("IngressP.noop") action noop_15() {
    }
    @name("IngressP.noop") action noop_16() {
    }
    @name("IngressP.t1") table t1_0 {
        actions = {
            setx1();
            noop();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop();
    }
    @name("IngressP.t2") table t2_0 {
        actions = {
            setx2();
            noop_9();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_9();
    }
    @name("IngressP.t3") table t3_0 {
        actions = {
            setx1_5();
            noop_10();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.x1: exact @name("hdr.data.x1") ;
            hdr.data.x2: exact @name("hdr.data.x2") ;
        }
        default_action = noop_10();
    }
    @ignore_table_dependency("t3") @name("IngressP.t4") table t4_0 {
        actions = {
            setx1_6();
            noop_11();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_11();
    }
    @name("IngressP.t5") table t5_0 {
        actions = {
            setx1_7();
            noop_12();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.x1: exact @name("hdr.data.x1") ;
            hdr.data.x2: exact @name("hdr.data.x2") ;
        }
        default_action = noop_12();
    }
    @ignore_table_dependency("t5") @name("IngressP.t6") table t6_0 {
        actions = {
            setx2_2();
            noop_13();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_13();
    }
    @name("IngressP.t7") table t7_0 {
        actions = {
            setx1_8();
            noop_14();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.x1: exact @name("hdr.data.x1") ;
            hdr.data.x2: exact @name("hdr.data.x2") ;
        }
        default_action = noop_14();
    }
    @ignore_table_dependency("t7") @name("IngressP.t8") table t8_0 {
        actions = {
            setboth();
            noop_15();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_15();
    }
    @name("IngressP.set_port") table set_port_0 {
        actions = {
            set_port_act();
            noop_16();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_16();
    }
    apply {
        t1_0.apply();
        t2_0.apply();
        t3_0.apply();
        t4_0.apply();
        t5_0.apply();
        t6_0.apply();
        t7_0.apply();
        t8_0.apply();
        set_port_0.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    @hidden action act() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
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
    @hidden action act_0() {
        b.emit<data_t>(hdr.data);
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        tbl_act_0.apply();
    }
}

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

