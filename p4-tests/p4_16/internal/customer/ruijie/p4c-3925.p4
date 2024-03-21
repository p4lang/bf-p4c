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
    bit<32> diff1;
    bit<32> diff2;
    bit<18> qdepth;
}

#define QUEUE_REG_STAGE 1
@stage(QUEUE_REG_STAGE)
Register<bit<32>, bit<11>>(2048) ping_reg;
@stage(QUEUE_REG_STAGE)
Register<bit<32>, bit<11>>(2048) pong_reg;

parser iPrsr_p0(packet_in packet, out headers hdr, out metadata meta,
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

control iDprsr_p0(packet_out packet, inout headers hdr, in metadata meta,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
         packet.emit(hdr);
    }
}

parser ePrsr_p0(packet_in packet, out headers hdr, out metadata meta,
             out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.ethernet);
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

control eDprsr_p0(packet_out packet, inout headers hdr, in metadata meta,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {

    Checksum() ipv4_checksum;

    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});

         packet.emit(hdr);
    }
}

parser iPrsr_p1(packet_in packet, out headers hdr, out metadata meta,
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

control iDprsr_p1(packet_out packet, inout headers hdr, in metadata meta,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
         packet.emit(hdr);
    }
}

parser ePrsr_p1(packet_in packet, out headers hdr, out metadata meta,
             out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.ethernet);
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

control eDprsr_p1(packet_out packet, inout headers hdr, in metadata meta,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {

    Checksum() ipv4_checksum;

    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});

         packet.emit(hdr);
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

    @stage(QUEUE_REG_STAGE)
    table ping_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
            g_intr_md.qid : exact;
        }
        actions = {
            ping_do_update;
        }
        size = 2048;
    }

    @stage(QUEUE_REG_STAGE)
    table pong_update_tbl {
        key = {
            g_intr_md.pipe_id : exact;
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

control ingress_p0(
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

    @stage(QUEUE_REG_STAGE)
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

    @stage(QUEUE_REG_STAGE)
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

control egress_p0(inout headers hdr,
               inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    action set_egr_md() {
        meta.qdepth = eg_intr_md.enq_qdepth[18:1];
        hdr.ipv4.identification = (bit<16>)eg_intr_md.egress_port;
        hdr.ipv4.ttl = (bit<8>)eg_intr_md.egress_qid;
    }

    table set_egr_md_tbl {
        actions = { set_egr_md; }
    }

    apply {
        set_egr_md_tbl.apply();
    }
}

control ingress_p1(
        inout headers hdr,
        inout metadata ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

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
    }
}

control egress_p1(inout headers hdr,
               inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    action set_egr_md() {
        meta.qdepth = eg_intr_md.enq_qdepth[18:1];
        hdr.ipv4.identification = (bit<16>)eg_intr_md.egress_port;
        hdr.ipv4.ttl = (bit<8>)eg_intr_md.egress_qid;
    }

    table set_egr_md_tbl {
        actions = { set_egr_md; }
    }

    action calc_diff() {
        meta.diff1 = (bit<32>)meta.qdepth |-| hdr.ipv4.src_addr;
        meta.diff2 = hdr.ipv4.src_addr |-| (bit<32>)meta.qdepth;
        hdr.ipv4.dst_addr = (bit<32>)meta.qdepth;
    }

    table calc_diff_tbl {
        actions = { calc_diff; }
    }

    DirectCounter<bit<32>>(CounterType_t.PACKETS) egr_cntr_1;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) egr_cntr_2;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) egr_match_cntr;

    action egr_cnt_1() {
        egr_cntr_1.count();
    }

    action egr_cnt_2() {
        egr_cntr_2.count();
    }

    action egr_match_cnt() {
        egr_match_cntr.count();
    }

    // Real enqueue depth > reported
    table egr_cntr_tbl_1 {
        key = {
            eg_intr_md.egress_port : exact;
            eg_intr_md.egress_qid : exact;
            meta.diff1[17:10] : exact;
        }
        actions = { egr_cnt_1; }
        counters = egr_cntr_1;
        size = 294912;
    }

    // Real enqueue depth < reported
    table egr_cntr_tbl_2 {
        key = {
            eg_intr_md.egress_port : exact;
            eg_intr_md.egress_qid : exact;
            meta.diff2[17:10] : exact;
        }
        actions = { egr_cnt_2; }
        counters = egr_cntr_2;
        size = 294912;
    }

    // Real enqueue depth == reported
    table egr_cntr_match {
        key = {
            eg_intr_md.egress_port : exact;
            eg_intr_md.egress_qid : exact;
        }
        actions = { egr_match_cnt; }
        counters = egr_match_cntr;
        size = 65536;
        default_action = egr_match_cnt();
    }

    apply {
        set_egr_md_tbl.apply();
        calc_diff_tbl.apply();
        if (meta.diff1 > 0) {
            egr_cntr_tbl_1.apply();
        } else if (meta.diff2 > 0) {
            egr_cntr_tbl_2.apply();
        } else {
            egr_cntr_match.apply();
        }
    }
}

Pipeline(iPrsr_p0(), ingress_p0(), iDprsr_p0(), ePrsr_p0(), egress_p0(), eDprsr_p0(), ghost()) pipe0;
Pipeline(iPrsr_p0(), ingress_p1(), iDprsr_p1(), ePrsr_p1(), egress_p1(), eDprsr_p1()) pipe1;
Switch(pipe0, pipe1) main;
