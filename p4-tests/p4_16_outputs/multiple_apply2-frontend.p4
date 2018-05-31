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
    ingress_skip_t skip;
    state start {
        b.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        b.extract<ingress_skip_t>(skip);
        b.extract<data_t>(hdr.data);
        transition accept;
    }
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    bool tmp;
    bool inner_multiple_tmp_1;
    @name("IngressP.inner_multiple.noop") action inner_multiple_noop() {
    }
    @name("IngressP.inner_multiple.noop") action inner_multiple_noop_0() {
    }
    @name("IngressP.inner_multiple.t2_act") action inner_multiple_t2_act(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name("IngressP.inner_multiple.t3_act") action inner_multiple_t3_act(bit<8> b5) {
        hdr.data.b5 = b5;
    }
    @name("IngressP.inner_multiple.t2") table inner_multiple_t2_1 {
        actions = {
            inner_multiple_t2_act();
            inner_multiple_noop();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = inner_multiple_noop();
    }
    @name("IngressP.inner_multiple.t3") table inner_multiple_t3_1 {
        actions = {
            inner_multiple_t3_act();
            inner_multiple_noop_0();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = inner_multiple_noop_0();
    }
    bool inner_multiple_tmp_2;
    @name("IngressP.inner_multiple.noop") action inner_multiple_noop_5() {
    }
    @name("IngressP.inner_multiple.noop") action inner_multiple_noop_6() {
    }
    @name("IngressP.inner_multiple.t2_act") action inner_multiple_t2_act_0(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name("IngressP.inner_multiple.t3_act") action inner_multiple_t3_act_0(bit<8> b5) {
        hdr.data.b5 = b5;
    }
    @name("IngressP.inner_multiple.t2") table inner_multiple_t2_2 {
        actions = {
            inner_multiple_t2_act_0();
            inner_multiple_noop_5();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = inner_multiple_noop_5();
    }
    @name("IngressP.inner_multiple.t3") table inner_multiple_t3_2 {
        actions = {
            inner_multiple_t3_act_0();
            inner_multiple_noop_6();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = inner_multiple_noop_6();
    }
    @name("IngressP.noop") action noop_1() {
    }
    @name("IngressP.noop") action noop_2() {
    }
    @name("IngressP.set_port") action set_port_0(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("IngressP.t1_act") action t1_act_0(bit<8> b3) {
        hdr.data.b3 = b3;
    }
    @name("IngressP.t1") table t1 {
        actions = {
            t1_act_0();
            noop_1();
        }
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
        }
        default_action = noop_1();
    }
    @name("IngressP.port_setter") table port_setter {
        actions = {
            set_port_0();
            noop_2();
        }
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = noop_2();
    }
    apply {
        if (hdr.data.b1 == 8w0) {
            tmp = t1.apply().hit;
            if (!tmp) 
                if (hdr.data.b2 == 8w0) {
                    inner_multiple_tmp_1 = inner_multiple_t2_1.apply().hit;
                    if (!inner_multiple_tmp_1) 
                        inner_multiple_t3_1.apply();
                }
                else 
                    inner_multiple_t3_1.apply();
        }
        else 
            if (hdr.data.b2 == 8w0) {
                inner_multiple_tmp_2 = inner_multiple_t2_2.apply().hit;
                if (!inner_multiple_tmp_2) 
                    inner_multiple_t3_2.apply();
            }
            else 
                inner_multiple_t3_2.apply();
        port_setter.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
        b.emit<data_t>(hdr.data);
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
    apply {
        b.emit<data_t>(hdr.data);
    }
}

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

