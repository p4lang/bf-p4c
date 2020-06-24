#include <core.p4>
#include <tna.p4>

header data_t {
    bit<32> f1; 
    bit<8> b1;
    bit<8> b2;
}

struct metadata {
}

struct headers {
    data_t data;
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(ig_intr_md);
        b.advance(PORT_METADATA_SIZE);
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

    bit<10> index;
    action set_port(PortId_t port, bit<10> index_) {
        ig_intr_tm_md.ucast_egress_port = port;
        index = index_;
    }

    table set_metadata {
        key = { hdr.data.f1 : ternary; }
        actions = { set_port; }
    }

    Register<bit<8>, bit<10>>(1024) accum;

    RegisterAction<bit<8>, bit<10>, bit<8>>(accum) add_one = {
        void apply(inout bit<8> value, out bit<8> rv) {
            value = value + 1;
            rv = value;
        }
    };

    RegisterAction<bit<8>, bit<10>, bit<8>> (accum) add_b1 = {
        void apply(inout bit<8> value, out bit<8> rv) {
            value = value + hdr.data.b1;
            rv = value;
        }
    };

    RegisterAction<bit<8>, bit<10>, bit<8>>(accum) sub_one = {
        void apply(inout bit<8> value, out bit<8> rv) {
            value = value - 1;
            rv = value;
        }
    };

    RegisterAction<bit<8>, bit<10>, bit<8>>(accum) sub_b1 = {
        void apply(inout bit<8> value, out bit<8> rv) {
            value = value - hdr.data.b1;
            rv = value;
        }
    };

    action add_one_act() {
        hdr.data.b2 = add_one.execute(index);
    }

    action add_b1_act() {
        hdr.data.b2 = add_b1.execute(index);
    }

    action sub_one_act() {
        hdr.data.b2 = sub_one.execute(index);
    }

    action nop() {}

    table case1 {
        actions = { add_one_act;
                    add_b1_act;
                    sub_one_act;
                    nop; }
        key = { hdr.data.f1 : exact; }
        
        const entries = {
            (0x10101010) : add_one_act();
            (0x20202020) : add_b1_act();
            (0x30303030) : nop;
            (0x40404040) : sub_one_act();
        }
        size = 4;
        default_action = nop;
    }

    Counter<bit<32>, bit<10>>(1024, CounterType_t.PACKETS) ind_counter;
    action count() {
        ind_counter.count(index);
    }

    table case2 {
        actions = { count; nop; }
        key = { hdr.data.f1 : exact; }
        const entries = {
            (0x10101010) : count();
            (0x20202020) : nop;
            (0x30303030) : nop;
            (0x40404040) : count();
        }
        size = 4;
        default_action = nop;
    }
    

    apply {
        set_metadata.apply();
        case1.apply();
        case2.apply();
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
