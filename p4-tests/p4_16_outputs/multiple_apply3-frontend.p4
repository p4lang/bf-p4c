#include <core.p4>
#include <tofino.p4>

header data_t {
    bit<16> h1;
    bit<16> h2;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
    bit<8>  b4;
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
    bool tmp;
    @name("noop") action noop_0() {
    }
    @name("set_port") action set_port_0(bit<9> port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("t1_act") action t1_act_0(bit<8> b3) {
        hdr.data.b3 = b3;
    }
    @name("t2_act") action t2_act_0(bit<8> b4) {
        hdr.data.b4 = b4;
    }
    @name("t1") table t1_0 {
        actions = {
            t1_act_0();
            noop_0();
        }
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
        }
        default_action = noop_0();
    }
    @name("t2") table t2_0 {
        actions = {
            t2_act_0();
            noop_0();
        }
        key = {
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = noop_0();
    }
    @name("port_setter") table port_setter_0 {
        actions = {
            set_port_0();
            noop_0();
        }
        key = {
            hdr.data.h1: exact @name("hdr.data.h1") ;
            hdr.data.h2: exact @name("hdr.data.h2") ;
        }
        default_action = noop_0();
    }
    apply {
        if (hdr.data.b1 == 8w0) {
            tmp = t1_0.apply().hit;
            if (!tmp) 
                if (hdr.data.b2 == 8w0 && hdr.data.b3 == 8w0) 
                    t2_0.apply();
        }
        else 
            if (hdr.data.b2 == 8w0 && hdr.data.b3 == 8w0) 
                t2_0.apply();
        port_setter_0.apply();
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

