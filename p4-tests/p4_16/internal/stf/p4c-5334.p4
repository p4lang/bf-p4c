#include <core.p4>
#include <t2na.p4>

header test_h {
    bit<32>      flag;
}

struct headers {
    test_h       test;
}

struct metadata { 
    PortId_t      port;
    bit<1>        usi_state;
}

parser ParserImpl(packet_in        pkt,
    out headers          hdr,
    out metadata         meta,
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_header;
    }

    state parse_header {
        pkt.extract(hdr.test);
        transition accept;
    }
}

control ingress(
    inout headers                       hdr,
    inout metadata                      meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    Register<bit<1>, bit<10>>(1024, 0) ipv4_fib_usi_reg;
    RegisterAction<bit<1>, bit<10>, bit<1>>(ipv4_fib_usi_reg) ipv4_fib_usi_reg_action = {
        void apply(inout bit<1> reg, out bit<1> rv) {
            rv = reg;
        }
    };

    action fib_miss() {

    }

    action ipv4_fib_hit(PortId_t port,
                        bit<10> usi){
        meta.port = port;
        meta.usi_state = ipv4_fib_usi_reg_action.execute(usi);
    }

    @force_immediate(1)
    table t {
        key = { hdr.test.flag : exact; }
        actions = {
            ipv4_fib_hit;
            @defaultonly fib_miss;
        }
        const default_action = fib_miss;
        size = 1024;
    }

    apply {
        t.apply();
        ig_tm_md.ucast_egress_port = meta.port;
    }
}

#include "common_tna_test.h"
