#include <t2na.p4>

header ethernet_h {
    bit<48> dst;
    bit<48> src;
    bit<16> etype;
}

struct headers {
    ethernet_h  ethernet;
}

struct metadata {
}

parser iPrsr(packet_in packet, out headers hdr, out metadata meta,
             out ingress_intrinsic_metadata_t ig_intr_md) {
  state start {
    packet.extract(ig_intr_md);
    packet.advance(PORT_METADATA_SIZE);
    packet.extract(hdr.ethernet);
    transition accept;
  }
}

Register<bit<16>, bit<13>>(8192) ping_table;
Register<bit<16>, bit<13>>(8192) pong_table;

control ingress(
        inout headers hdr,
        inout metadata ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
        in ghost_intrinsic_metadata_t g_intr_md) {

    MinMaxAction<bit<16>, bit<10>, bit<16>>(ping_table) ping_rmax = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.max16(value, 0xfc, subindex[2:0]);
        }
    };
    MinMaxAction<bit<16>, bit<10>, bit<16>>(pong_table) pong_rmax = {
        void apply(inout bit<128> value, out bit<16> rv, out bit<16> subindex) {
            subindex = 0;
            rv = this.max16(value, 0xfc, subindex[2:0]);
        }
    };

    apply {
        bit<16> idx;
        if (g_intr_md.ping_pong == 0) {
            ping_rmax.execute(0, idx);
        } else {
            pong_rmax.execute(0, idx);
        }
        ig_intr_tm_md.ucast_egress_port[8:1] = (bit<8>)idx;
    }
}

control ghost(in ghost_intrinsic_metadata_t g_intr_md) {
    RegisterAction<bit<16>, bit<13>, bit<16>>(ping_table) ping_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };
    RegisterAction<bit<16>, bit<13>, bit<16>>(pong_table) pong_update = {
        void apply(inout bit<16> value) { value = g_intr_md.qlength[15:0]; } };

    apply {
        if (g_intr_md.ping_pong == 1) {
            ping_update.execute((bit<13>)g_intr_md.qid);
        } else {
            pong_update.execute((bit<13>)g_intr_md.qid);
        }
    }
}

control iDprsr(packet_out packet, inout headers hdr, in metadata meta,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
  apply {
    packet.emit(hdr);
  }
}

parser ePrsr(packet_in packet, out headers hdr, out metadata meta,
             out egress_intrinsic_metadata_t eg_intr_md) {
  state start { transition accept; }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
  apply {}
}

control eDprsr(packet_out packet, inout headers hdr, in metadata meta,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
  apply {}
}

Pipeline(iPrsr(), ingress(), iDprsr(), ePrsr(), egress(), eDprsr(), ghost()) pipe;
Switch(pipe) main;
