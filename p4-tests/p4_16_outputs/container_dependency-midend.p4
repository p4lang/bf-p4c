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
    ingress_skip_t skip;
    state start {
        b.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        b.extract<ingress_skip_t>(skip);
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name("IngressP.set_port_act") action set_port_act_0(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("IngressP.setx1") action setx1_0(bit<4> x1) {
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
    @name("IngressP.setx2") action setx2_0(bit<4> x2) {
        hdr.data.x2 = x2;
    }
    @name("IngressP.setx2") action setx2_2(bit<4> x2) {
        hdr.data.x2 = x2;
    }
    @name("IngressP.setboth") action setboth_0(bit<4> x1, bit<4> x2) {
        hdr.data.x1 = x1;
        hdr.data.x2 = x2;
    }
    @name("IngressP.noop") action noop_0() {
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
    @name("IngressP.t1") table t1 {
        actions = {
            setx1_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_0();
    }
    @name("IngressP.t2") table t2 {
        actions = {
            setx2_0();
            noop_9();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_9();
    }
    @name("IngressP.t3") table t3 {
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
    @ignore_table_dependency("t3") @name("IngressP.t4") table t4 {
        actions = {
            setx1_6();
            noop_11();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_11();
    }
    @name("IngressP.t5") table t5 {
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
    @ignore_table_dependency("t5") @name("IngressP.t6") table t6 {
        actions = {
            setx2_2();
            noop_13();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_13();
    }
    @name("IngressP.t7") table t7 {
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
    @ignore_table_dependency("t7") @name("IngressP.t8") table t8 {
        actions = {
            setboth_0();
            noop_15();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_15();
    }
    @name("IngressP.set_port") table set_port {
        actions = {
            set_port_act_0();
            noop_16();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_16();
    }
    apply {
        t1.apply();
        t2.apply();
        t3.apply();
        t4.apply();
        t5.apply();
        t6.apply();
        t7.apply();
        t8.apply();
        set_port.apply();
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

Switch<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;

