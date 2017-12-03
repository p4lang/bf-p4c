#include <core.p4>
#include <tofino.p4>

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

parser ParserI(packet_in b, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name("set_port_act") action set_port_act_0(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("setx1") action setx1_0(bit<4> x1) {
        hdr.data.x1 = x1;
    }
    @name("setx2") action setx2_0(bit<4> x2) {
        hdr.data.x2 = x2;
    }
    @name("setboth") action setboth_0(bit<4> x1, bit<4> x2) {
        hdr.data.x1 = x1;
        hdr.data.x2 = x2;
    }
    @name("noop") action noop_0() {
    }
    @name("t1") table t1_0 {
        actions = {
            setx1_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_0();
    }
    @name("t2") table t2_0 {
        actions = {
            setx2_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_0();
    }
    @name("t3") table t3_0 {
        actions = {
            setx1_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.x1: exact @name("hdr.data.x1") ;
            hdr.data.x2: exact @name("hdr.data.x2") ;
        }
        default_action = noop_0();
    }
    @ignore_table_dependency("t3") @name("t4") table t4_0 {
        actions = {
            setx1_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_0();
    }
    @name("t5") table t5_0 {
        actions = {
            setx1_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.x1: exact @name("hdr.data.x1") ;
            hdr.data.x2: exact @name("hdr.data.x2") ;
        }
        default_action = noop_0();
    }
    @ignore_table_dependency("t5") @name("t6") table t6_0 {
        actions = {
            setx2_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_0();
    }
    @name("t7") table t7_0 {
        actions = {
            setx1_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
            hdr.data.x1: exact @name("hdr.data.x1") ;
            hdr.data.x2: exact @name("hdr.data.x2") ;
        }
        default_action = noop_0();
    }
    @ignore_table_dependency("t7") @name("t8") table t8_0 {
        actions = {
            setboth_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_0();
    }
    @name("set_port") table set_port_0 {
        actions = {
            set_port_act_0();
            noop_0();
        }
        key = {
            hdr.data.f1: exact @name("hdr.data.f1") ;
        }
        default_action = noop_0();
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

control DeparserI(packet_out b, inout headers hdr, in metadata meta) {
    apply {
        b.emit<data_t>(hdr.data);
    }
}

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta) {
    apply {
        b.emit<data_t>(hdr.data);
    }
}

Switch<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) main;

