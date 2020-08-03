#include <tna.p4>

struct metadata {
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
    bit<8>  b3;
}

header bridged_md_t {
    bit<8> bmd1;
    bit<8> bmd2;
}

struct headers {
    data_t data;
    bridged_md_t bridged_md;
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

    action set_bmd() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.bmd1 = 0x11;
        hdr.bridged_md.bmd2 = 0x22;
    }

    table set_bridged {
        actions = { set_bmd; NoAction; }
        key = { hdr.data.f1: exact; }
        default_action = NoAction;
    }

    action act(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    table set_port {
        actions = { act; NoAction; }
        key = { hdr.data.f1: exact; }
        default_action = NoAction;
    }

    // @adjust_byte_count(6 /* STF 4 byte trailer */)
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ICounterDirect;

    action update() {
        ICounterDirect.count(4);
    }

    action nop() {
        ICounterDirect.count();
    }

    table update_ingress_counter {
        actions = { update; nop; }
        key = { hdr.data.f1: exact; }
        default_action = nop;
        counters = ICounterDirect;
    }

    // @adjust_byte_count(4 /* STF 4 byte trailer */)
    Counter<bit<64>, bit<10>>(1024, CounterType_t.PACKETS_AND_BYTES) ICounter;
action update2(bit<10> idx) { ICounter.count(idx, 4);
    }

    table update_ingress_counter2 {
        actions = { update2; NoAction; }
        key = { hdr.data.f1: exact; }
        default_action = NoAction;
    }

    apply {
        set_bridged.apply();
        set_port.apply();
        update_ingress_counter.apply();
        update_ingress_counter2.apply();
    }

}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { 
        b.emit(hdr.data); 
        b.emit(hdr.bridged_md);
    }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(eg_intr_md);
        b.extract(hdr.data);
        b.extract(hdr.bridged_md);
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

    // @adjust_byte_count(sizeInBytes(hdr.bridged_md) + 4 /* STF 4 byte trailer */)
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) ECounterDirect;

    action update() {
        ECounterDirect.count(sizeInBytes(hdr.bridged_md) + 4);
        hdr.data.b1 = hdr.bridged_md.bmd1;
    }

    action nop() {
        ECounterDirect.count(sizeInBytes(hdr.bridged_md) + 4);
    }

    table update_egress_counter {
        actions = { update; nop; }
        key = { hdr.data.f1: exact; }
        default_action = nop;
        counters = ECounterDirect;
    }

    // @adjust_byte_count(sizeInBytes(hdr.bridged_md) + 4 /* STF 4 byte trailer */)
    Counter<bit<64>, bit<10>>(1024, CounterType_t.PACKETS_AND_BYTES) ECounter;
    action update2(bit<10> idx) {
        ECounter.count(idx, sizeInBytes(hdr.bridged_md) + 4);
        hdr.data.b2 = hdr.bridged_md.bmd2;
    }

    table update_egress_counter2 {
        actions = { update2; NoAction; }
        key = { hdr.data.f1: exact; }
        default_action = NoAction;
    }

    apply { 
        update_egress_counter.apply();
        update_egress_counter2.apply();
    }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
