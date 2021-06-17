
#include <core.p4>
#include <tna.p4>

header data_t {
    bit<12> f1;
    @padding bit<4>  __pad1;
    bit<12> f2;
    @padding bit<4>  __pad2;
    bit<12> d1;
    @padding bit<4>  __pad3;
    bit<32> d2;
    bit<10> d3;
    @padding bit<6>  __pad4;
    bit<4>  d4;
    @padding bit<4>  __pad5;
}

struct metadata {
}

header ingress_skip_t {
    bit<64> pad;
}

struct headers {
    data_t data;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        b.extract(ig_intr_md);
        b.extract(skip);
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter;

    action act(bit<32> p1, bit<10> p2, bit<4> p3) {
        hdr.data.d1 = hdr.data.f1;
        hdr.data.d3 = p2;
        hdr.data.d2 = p1;
        hdr.data.d4 = p3;
    }

    action act2(bit<32> a1) {
        hdr.data.d2 = a1;
    }

    action act3() {
        direct_counter.count();
    }

    table test1 {
        actions = { @tableonly act; act2; NoAction; }
        key = { hdr.data.f1: exact; }
        // Identity Hash = Yes, 
        // Reason = Const default uses immediate but no Action Data
        const default_action = act2(32w0); 
        size = 4096;
    }

    table test2 {
        actions = { @tableonly act; act2; NoAction; }
        key = { hdr.data.f1: exact; }
        // Identity Hash = Yes, 
        // Reason = If other action(s) are tableonly and default actions do not use Action Data
        default_action = NoAction; 
    }

    table test3 {
        actions = { act; act2; NoAction; }
        key = { hdr.data.f1: exact; }
        // Identity Hash = No, 
        // Reason = If other action can be default and uses Action Data
        default_action = NoAction; 
    }

    table test4 {
        actions = { act; act2; NoAction; }
        key = { hdr.data.f1: exact; }
        // Identity Hash = No, 
        // Reason = Default Action Uses Action Data
        default_action = act(32w0, 10w0, 4w0); 
    }

    table test5 {
        actions = { act; act2; NoAction; }
        key = { hdr.data.f1: exact; }
        // Identity Hash = No, 
        // Reason = Const Default Action Uses Action Data
        const default_action = act(32w0, 10w0, 4w0); 
    }

    table test6 {
        actions = { act; act2; NoAction; }
        key = { hdr.data.f1: exact; }
        // Identity Hash = Yes,
        // Reason = Const Default Action Does not Use Action Data
        const default_action = NoAction; 
    }

    table test7 {
        actions = { @tableonly act; act2; NoAction; }
        key = { hdr.data.f1: exact; }
        // Identity Hash = No, 
        // Reason = Idletime on table is a direct resource for all actions 
        idle_timeout = true; 
    }

    table test8 {
        actions = { act3; }
        key = { hdr.data.f1: exact; }
        // Identity Hash = No, 
        // Reason = Direct resource on default action - counter 
        counters = direct_counter;
    }

    apply {
        test1.apply();
        test2.apply();
        test3.apply();
        test4.apply();
        test5.apply();
        test6.apply();
        test7.apply();
        test8.apply();
    }

}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { b.emit(hdr.data); }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(eg_intr_md);
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
