#include <t2na.p4>

#define ETHERTYPE_IPV4 0x0800

header ethernet_h {
    bit<48> dst;
    bit<48> src;
    bit<16> etype;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

struct headers {
    ethernet_h  ethernet;
    ipv4_h ipv4;
}

struct metadata {
    bit<32> diff;
}

parser iPrsr(packet_in packet, out headers hdr, out metadata meta,
             out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(128);
        packet.advance(64);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etype) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

#define GHOST_STAGE 1

@stage(GHOST_STAGE)
Register<bit<32>, bit<11>>(2048) ping_reg;
@stage(GHOST_STAGE)
Register<bit<32>, bit<11>>(2048) pong_reg;

control ingress(
        inout headers hdr,
        inout metadata ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
        in ghost_intrinsic_metadata_t g_intr_md) {
    RegisterAction<bit<32>, bit<11>, bit<32>>(ping_reg) ping_get = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; }
    };
    RegisterAction<bit<32>, bit<11>, bit<32>>(pong_reg) pong_get = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; }
    };

    action ping_get_depth(bit<11> idx) {
        hdr.ipv4.src_addr = ping_get.execute(idx);
    }

    action pong_get_depth(bit<11> idx) {
        hdr.ipv4.src_addr = pong_get.execute(idx);
    }

    @stage(GHOST_STAGE)
    table ping_tbl {
        key = {
            ig_intr_tm_md.ucast_egress_port : exact;
            ig_intr_tm_md.qid : exact;
        }
        actions = {
            ping_get_depth;
        }
        size = 2048;
    }

    @stage(GHOST_STAGE)
    table pong_tbl {
        key = {
            ig_intr_tm_md.ucast_egress_port : exact;
            ig_intr_tm_md.qid : exact;
        }
        actions = {
            pong_get_depth;
        }
        size = 2048;
    }

    action do_set_dest(PortId_t port, QueueId_t qid) {
        ig_intr_tm_md.ucast_egress_port = port;
        ig_intr_tm_md.qid = qid;
    }

    table set_dest {
        key = {
            hdr.ethernet.src : exact;
        }
        actions = { do_set_dest; }
        size = 2048;
    }

    apply {
        set_dest.apply();
        if (g_intr_md.ping_pong == 0) {
            ping_tbl.apply();
        } else {
            pong_tbl.apply();
        }
    }
}

control ghost(in ghost_intrinsic_metadata_t g_intr_md) {
    RegisterAction<bit<32>, bit<11>, bit<32>>(ping_reg) ping_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };
    RegisterAction<bit<32>, bit<11>, bit<32>>(pong_reg) pong_update = {
        void apply(inout bit<32> value) { value = (bit<32>)g_intr_md.qlength; } };

    action ping_do_update(bit<11> idx) {
        ping_update.execute(idx);
    }
    action pong_do_update(bit<11> idx) {
        pong_update.execute(idx);
    }

    @stage(GHOST_STAGE)
    table ping_update_tbl {
        key = {
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update;
        }
        size = 2048;
    }

    @stage(GHOST_STAGE)
    table pong_update_tbl {
        key = {
            g_intr_md.qid : exact;
        }
        actions = {
            pong_do_update;
        }
        size = 2048;
    }

    apply {
        if (g_intr_md.ping_pong == 1) {
            ping_update_tbl.apply();
        } else {
            pong_update_tbl.apply();
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
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control egress(inout headers hdr,
               inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    action calc_diff() {
        hdr.ipv4.dst_addr = (bit<32>)eg_intr_md.enq_qdepth;
        meta.diff = (bit<32>)eg_intr_md.enq_qdepth - hdr.ipv4.src_addr;
    }

    table calc_diff_tbl {
        actions = { calc_diff; }
    }

    DirectCounter<bit<32>>(CounterType_t.PACKETS) egr_cntr;

    action egr_cnt() {
        egr_cntr.count();
    }

    table egr_cntr_tbl {
        key = {
            meta.diff[31:16] : exact;
        }
        actions = { egr_cnt; }
        counters = egr_cntr;
        size = 65536;
        default_action = egr_cnt();
    }

    apply {
        calc_diff_tbl.apply();
        egr_cntr_tbl.apply();
    }
}

control eDprsr(packet_out packet, inout headers hdr, in metadata meta,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
  apply {}
}

Pipeline(iPrsr(), ingress(), iDprsr(), ePrsr(), egress(), eDprsr(), ghost()) pipe;
Switch(pipe) main;
