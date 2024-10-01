
#include <t2na.p4>

// ---------------------------------------------------------------------------
// Network protocols
// ---------------------------------------------------------------------------


typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<24> roce_qp_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}



// ---------------------------------------------------------------------------
// Instrumentation
// ---------------------------------------------------------------------------


header instrumentation_h {
    bit<8> sep_0f;
    bit<8> afc_xonoff; // 0 = None, 1 = Xoff, 2 = Xon
    bit<8> capture_start; // 0 = No, 1 = Yes
    bit<8> capture; // 0 = No, 1 = Yes
    bit<8> sep_1f;
    bit<16> packet_id;
    bit<8> sep_2f; // 6f
    bit<8> pipe_id; // 2 bits
    bit<8> port_id; // 7 bits relative to pipe
    bit<8> port_queue_id; // 7 bits relative to port
    bit<8> sep_3f; // 7f
    bit<8> mac_id; // 4 bits mac id relative to pipe
    bit<8> mac_queue_id; // 7 bits relative to mac
    bit<8> sep_4f; // 8f
    bit<32> qd_ghost; // 18 bits
    bit<8> sep_5f; // 9f
    bit<32> qd_enq; // 19 bits
    bit<8> sep_6f; // af
    bit<32> qd_dq; // 19 bits
    bit<8> sep_7f; // bf
    bit<48> ts_ingress;
    bit<8> sep_8f; // cf
    bit<32> ts_enq;
    bit<8> sep_9f; // df
    bit<32> ts_dq_td;
    bit<8> sep_af; // ef
    bit<48> ts_egress;
    bit<8> sep_bf; // ff
    bit<8> hw_queue_id; // 7 bits relative to MAC
    bit<8> sep_cf;
    bit<32> ghost_msg_cnt_queue;
    bit<8> sep_df;
    bit<32> ghost_msg_cnt_total;
    bit<8> sep_ef;
    bit<16> register_idx; // 13 bits for tm queue id + pipe id
    bit<8> sep_f0;
    bit<8> buffer_pool_id;
    bit<8> sep_f1;
    bit<8> buffer_pool_capacity;
    bit<8> sep_f2;
    bit<8> buffer_pool_utilization;
    bit<8> sep_f3;
    bit<8> buffer_pool_available;
    bit<8> sep_f4;
    bit<8> buffer_pool_watermark;
    bit<8> sep_f5;
    bit<8> packet_length_bytes;
    bit<8> sep_f6;
    bit<8> packet_length_cells;
    bit<8> sep_f7;
}



// ---------------------------------------------------------------------------
// Header structs
// ---------------------------------------------------------------------------


struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
    instrumentation_h instrumentation;
}

struct empty_header_t {}

struct empty_metadata_t {}


// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------



control instrumentation(header_t hdr) {
    action do_collect_data() {
        // tbd
    }

    apply {
        if (hdr.instrumentation.isValid()) {
            do_collect_data();
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------


control get_packet_size_cells(bit<16> packet_length_bytes,
                              out bit<8> packet_length_cells)(bit<10> ENTRY_CNT) {

    action do_set_packet_size_cells(bit<8> bytes_to_cells) {
        packet_length_cells = bytes_to_cells;
    }

    table tbl_set_packet_size_cells {
        key = {
            packet_length_bytes[15:4] : ternary;
        }
        actions = {
            do_set_packet_size_cells;
            NoAction;
        }
        const default_action = NoAction;
        size = ENTRY_CNT;
    }

    apply {
        tbl_set_packet_size_cells.apply();
    }
}
const MirrorType_t MIRROR_TYPE_I2E = 1;

const bit<10> routing_entry_cnt = 64;

typedef bit<18> buffer_memory_t;


typedef bit<10> queue_idx_t;
//#define QUEUE_ID_CNT 513
const bit<32> queue_id_cnt = 513;

typedef bit<3> buffer_pool_idx_t;
//#define BUFFER_POOL_CNT 4
const bit<32> buffer_pool_cnt = 4;


enum bit<4> PortSpeed_t {
    None = 0x0,
    GBE10 = 0x1,
    GBE25 = 0x2,
    GBE40 = 0x3,
    GBE50 = 0x4,
    GBE100 = 0x5,
    GBE200 = 0x6,
    GBE400 = 0x7,
    GBE800 = 0x8
}


typedef bit<16> SfcPauseTime_t;
typedef bit<8> SfcNwTc_t;



const bit<10> pkt_size_lookup_table_tofino1 = 569;
const bit<10> pkt_size_lookup_table_tofino2 = 190;
const bit<10> pkt_size_lookup_table = pkt_size_lookup_table_tofino2;
// TODO: which size is appropriate?
const bit<32> sfc_pause_time_lut_size = 8192;
const bit<32> sfc_enable_table_size = 1024;

// Ghost with buffer pool
struct sfc_t {
    bool enabled;
    bit<16> packet_length_bytes;
    bit<8> packet_length_cells;
    queue_idx_t queue_id_idx;
    buffer_pool_idx_t buffer_pool_idx;
    bit<3> baf_shift;
    bit<1> baf_shift_sign; // 0 == positive, 1 == negative
    buffer_memory_t queue_depth; // Based on ghost depth reporting, with last bit dropped
    buffer_memory_t new_queue_depth; // Based on ghost depth reporting, with last bit dropped
    buffer_memory_t buffer_pool_capacity;
    buffer_memory_t buffer_pool_utilization;
    buffer_memory_t buffer_pool_available;
    bit<32> ghost_msg_cnt_queue;
    bit<32> ghost_msg_cnt_total;
    PortId_t signaling_port;
    QueueId_t signaling_qid;
    bit<3> signaling_icos;
    MirrorId_t signaling_mirror_id;
    ipv4_addr_t dst_ip;
    SfcNwTc_t nw_tc;
    bool port_connects_to_server;
    PortSpeed_t egress_port_speed;
    SfcPauseTime_t pause_duration;
}

header sfc_signal_t {
    SfcPauseTime_t pause_duration;
    bit<1> signal_type; // SFC or PFC
    bit<7> pad_1;
}


control sfc_init(out sfc_t sfc) {
    apply {
        sfc = (sfc_t){
        enabled = false,
        packet_length_bytes = 0,
        packet_length_cells = 0,
        queue_id_idx = 0,
        buffer_pool_idx = 0,
        baf_shift = 0,
        baf_shift_sign = 0,
        queue_depth = 0,
        new_queue_depth = 0,
        buffer_pool_capacity = 0,
        buffer_pool_utilization = 0,
        buffer_pool_available = 0,
        ghost_msg_cnt_queue = 0,
        ghost_msg_cnt_total = 0,
        signaling_port = 0,
        signaling_qid = 0,
        signaling_icos = 0,
        signaling_mirror_id = 0,
        dst_ip = 0,
        nw_tc = 0,
        port_connects_to_server = false,
        egress_port_speed = PortSpeed_t.None,
        pause_duration = 0
        };
    }
}

/**
 * Set static settings for SFC: Which qid, icos, and mirror_id to use to
 * create a signaling packet.
 **/
control sfc_config_prepare(in PortId_t ingress_port,
                           in PortId_t egress_port,
                           in QueueId_t egress_qid,
                           inout sfc_t sfc) {


    action do_set_configuration(QueueId_t signaling_qid,
                                bit<3> signaling_icos,
                                MirrorId_t signaling_mirror_id) {
        sfc.signaling_qid = signaling_qid;
        sfc.signaling_icos = signaling_icos;
        sfc.signaling_mirror_id = signaling_mirror_id;
    }

    table tbl_configure {
        actions = {
            do_set_configuration;
        }
        size = 1;
    }

    action do_sfc_enable(SfcNwTc_t nw_tc,
                         PortSpeed_t egress_port_speed) {
        sfc.enabled = true;
        sfc.nw_tc = nw_tc;
        sfc.egress_port_speed = egress_port_speed; // Can be done anywhere
    }

    table tbl_activate_sfc {
        key = {
            egress_port : exact;
            egress_qid : exact;
        }
        actions = {
            do_sfc_enable;
            NoAction;
        }
        size = sfc_enable_table_size;
    }

    apply {
        if (tbl_activate_sfc.apply().hit) {
            tbl_configure.apply();
            sfc.signaling_port = ingress_port;
        }
    }
}

// ---------------------------------------------------------------------------
// Preprocessor
// ---------------------------------------------------------------------------

typedef bit<5> stage_idx_t;
const stage_idx_t QUEUE_REG_STAGE_QD = 3;
const stage_idx_t QUEUE_REG_STAGE_BP = 4;
const stage_idx_t QUEUE_REG_STAGE_CNT = 5;



// ---------------------------------------------------------------------------
// Common registers and variables for ping-pong tables
// ---------------------------------------------------------------------------

const bit<1> ghost_total_cnt_idx = 1;

const bit<1> ping_pong_ingress = 0;
const bit<1> ping_pong_ghost = 1;

// Ghost thread: queue depth value
@stage(QUEUE_REG_STAGE_QD)
Register<bit<32>, queue_idx_t>(queue_id_cnt) reg_qd_ping;
@stage(QUEUE_REG_STAGE_QD)
Register<bit<32>, queue_idx_t>(queue_id_cnt) reg_qd_pong;

// Ghost thread: buffer pool memory utilization
@stage(QUEUE_REG_STAGE_BP)
Register<bit<32>, buffer_pool_idx_t>(buffer_pool_cnt) reg_bpmu_ping;
@stage(QUEUE_REG_STAGE_BP)
Register<bit<32>, buffer_pool_idx_t>(buffer_pool_cnt) reg_bpmu_pong;

// Ghost thread: per-queue message counter
@stage(QUEUE_REG_STAGE_CNT)
Register<bit<32>, queue_idx_t>(queue_id_cnt) ping_ghost_cnt_reg;
@stage(QUEUE_REG_STAGE_CNT)
Register<bit<32>, queue_idx_t>(queue_id_cnt) pong_ghost_cnt_reg;

// Ghost thread: total messages counter
@stage(QUEUE_REG_STAGE_CNT)
Register<bit<32>, bit<1>>(2) ping_ghost_total_cnt_reg;
@stage(QUEUE_REG_STAGE_CNT)
Register<bit<32>, bit<1>>(2) pong_ghost_total_cnt_reg;



// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------


control set_tm_data_from_ghost(in ghost_intrinsic_metadata_t g_intr_md) {
    bit<32> qlength = 0;
    bit<1> ping_pong = 0;
    bit<2> pipe_id = 0;
    bit<11> qid = 0;
    queue_idx_t queue_register_idx = 0;
    buffer_pool_idx_t buffer_pool_idx = 0;
    int<32> qd_delta = 0;

    action set_register_bp_idx(queue_idx_t q_idx,
                               buffer_pool_idx_t bp_idx) {
        queue_register_idx = q_idx;
        buffer_pool_idx = bp_idx;
    }

    table ghost_set_register_idx_tbl {
        key = {
            pipe_id : exact;
            qid : exact;
        }
        actions = {
            set_register_bp_idx;
            NoAction;
        }
        const default_action = NoAction;
        size = queue_id_cnt;
    }

    // Ghost thread: queue depth value
    RegisterAction<bit<32>, queue_idx_t, int<32>>(reg_qd_ping) qd_upd_ping = {
        void apply(inout bit<32> value, out int<32> rv) {
            value = (bit<32>)qlength;
            rv = ((int<32>)(bit<32>)qlength) - (int<32>)value;
        }
    };
    RegisterAction<bit<32>, queue_idx_t, int<32>>(reg_qd_pong) qd_upd_pong = {
        void apply(inout bit<32> value, out int<32> rv) {
            value = (bit<32>)qlength;
            rv = ((int<32>)(bit<32>)qlength) - (int<32>)value;
        }
    };

    action do_qd_upd_ping() {
        qd_delta = qd_upd_ping.execute(queue_register_idx);
    }
    action do_qd_upd_pong() {
        qd_delta = qd_upd_pong.execute(queue_register_idx);
    }

    @stage(QUEUE_REG_STAGE_QD)
    table tbl_qd_upd_ping {
        key = { }
        actions = {
            do_qd_upd_ping;
        }
        const default_action = do_qd_upd_ping;
        size = queue_id_cnt;
    }

    @stage(QUEUE_REG_STAGE_QD)
    table tbl_qd_upd_pong {
        key = { }
        actions = {
            do_qd_upd_pong;
        }
        const default_action = do_qd_upd_pong;
        size = queue_id_cnt;
    }


    // Ghost thread: track available memory per buffer pool
    RegisterAction<bit<32>, buffer_pool_idx_t, bit<32>>(reg_bpmu_ping) bpmu_upd_ping = {
        void apply(inout bit<32> value) {
            value = (bit<32>)((int<32>)value |+| qd_delta);
        }
    };
    RegisterAction<bit<32>, buffer_pool_idx_t, bit<32>>(reg_bpmu_pong) bpmu_upd_pong = {
        void apply(inout bit<32> value) {
            value = (bit<32>)((int<32>)value |+| qd_delta);
        }
    };

    action do_bpmu_upd_ping() {
        bpmu_upd_ping.execute(buffer_pool_idx);
    }
    action do_bpmu_upd_pong() {
        bpmu_upd_pong.execute(buffer_pool_idx);
    }

    @stage(QUEUE_REG_STAGE_BP)
    table tbl_bpmu_upd_ping {
        key = { }
        actions = {
            do_bpmu_upd_ping;
        }
        const default_action = do_bpmu_upd_ping;
        size = buffer_pool_cnt;
    }

    @stage(QUEUE_REG_STAGE_BP)
    table tbl_bpmu_upd_pong {
        key = { }
        actions = {
            do_bpmu_upd_pong;
        }
        const default_action = do_bpmu_upd_pong;
        size = buffer_pool_cnt;
    }

    // Ghost thread: message counter
    RegisterAction<bit<32>, queue_idx_t, bit<32>>(ping_ghost_cnt_reg) ping_ghost_cnt = {
        void apply(inout bit<32> value) { value = value + 1; } };
    RegisterAction<bit<32>, queue_idx_t, bit<32>>(pong_ghost_cnt_reg) pong_ghost_cnt = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action ping_do_ghost_cnt() {
        ping_ghost_cnt.execute(queue_register_idx);
    }
    action pong_do_ghost_cnt() {
        pong_ghost_cnt.execute(queue_register_idx);
    }

    @stage(QUEUE_REG_STAGE_CNT)
    table ping_ghost_cnt_tbl {
        key = { }
        actions = {
            ping_do_ghost_cnt;
        }
        const default_action = ping_do_ghost_cnt;
        size = queue_id_cnt;
    }

    @stage(QUEUE_REG_STAGE_CNT)
    table pong_ghost_cnt_tbl {
        key = { }
        actions = {
            pong_do_ghost_cnt;
        }
        const default_action = pong_do_ghost_cnt;
        size = queue_id_cnt;
    }

    // Ghost thread: total message counter
    RegisterAction<bit<32>, bit<1>, bit<32>>(ping_ghost_total_cnt_reg) ping_ghost_total_cnt = {
        void apply(inout bit<32> value) { value = value + 1; } };
    RegisterAction<bit<32>, bit<1>, bit<32>>(pong_ghost_total_cnt_reg) pong_ghost_total_cnt = {
        void apply(inout bit<32> value) { value = value + 1; } };

    action ping_do_ghost_total_cnt(bit<1> should_count) {
        ping_ghost_total_cnt.execute(should_count);
    }
    action pong_do_ghost_total_cnt(bit<1> should_count) {
        pong_ghost_total_cnt.execute(should_count);
    }

    @stage(QUEUE_REG_STAGE_CNT)
    table ping_ghost_total_cnt_tbl {
        key = {
            g_intr_md.isValid() : exact;
        }
        actions = {
            ping_do_ghost_total_cnt;
            NoAction;
        }
        const default_action = NoAction;
        size = 2;
    }

    @stage(QUEUE_REG_STAGE_CNT)
    table pong_ghost_total_cnt_tbl {
        key = {
            g_intr_md.isValid() : exact;
        }
        actions = {
            pong_do_ghost_total_cnt;
            NoAction;
        }
        const default_action = NoAction;
        size = 2;
    }

    apply {
        qlength = (bit<32>)g_intr_md.qlength;
        ping_pong = g_intr_md.ping_pong;
        pipe_id = g_intr_md.pipe_id;
        qid = g_intr_md.qid;
        ghost_set_register_idx_tbl.apply();

        if (g_intr_md.ping_pong == ping_pong_ghost) {
            tbl_qd_upd_ping.apply();
            tbl_bpmu_upd_ping.apply();
            ping_ghost_cnt_tbl.apply();
            ping_ghost_total_cnt_tbl.apply();
        } else {
            tbl_qd_upd_pong.apply();
            tbl_bpmu_upd_pong.apply();
            pong_ghost_cnt_tbl.apply();
            pong_ghost_total_cnt_tbl.apply();
        }
    }
}


control get_tm_data_from_ingress(
        in ghost_intrinsic_metadata_t g_intr_md,
        in PortId_t port_id,
        in bit<7> qid,
        in header_t hdr,
        inout sfc_t sfc
        ) {

    sfc_init() ctrl_sfc_init;

    action set_ingress_reg_bp_idx(queue_idx_t reg_idx,
                                  buffer_pool_idx_t bp_idx) {
        sfc.queue_id_idx = reg_idx;
        sfc.buffer_pool_idx = bp_idx;
    }

    table ingress_set_register_idx_tbl {
        key = {
           port_id : exact;
           qid : exact;
        }
        actions = {
            set_ingress_reg_bp_idx;
            NoAction;
        }
        const default_action = NoAction;
        size = queue_id_cnt;
    }

    // Ghost thread: queue depth value
    RegisterAction<bit<32>, queue_idx_t, bit<32>>(reg_qd_ping) qd_get_ping = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };
    RegisterAction<bit<32>, queue_idx_t, bit<32>>(reg_qd_pong) qd_get_pong = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };

    action do_qd_get_ping() {
        sfc.queue_depth = (buffer_memory_t)qd_get_ping.execute(sfc.queue_id_idx);
    }

    action do_qd_get_pong() {
        sfc.queue_depth = (buffer_memory_t)qd_get_pong.execute(sfc.queue_id_idx);
    }

    @stage(QUEUE_REG_STAGE_QD)
    table tbl_qd_get_ping {
        key = {}
        actions = {
            do_qd_get_ping;
        }
        const default_action = do_qd_get_ping;
        size = queue_id_cnt;
    }

    @stage(QUEUE_REG_STAGE_QD)
    table tbl_qd_get_pong {
        key = {}
        actions = {
            do_qd_get_pong;
        }
        const default_action = do_qd_get_pong;
        size = queue_id_cnt;
    }

    // Ghost thread: buffer pool memory utilization
    RegisterAction<bit<32>, buffer_pool_idx_t, bit<32>>(reg_bpmu_ping) bpmu_get_ping = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };
    RegisterAction<bit<32>, buffer_pool_idx_t, bit<32>>(reg_bpmu_pong) bpmu_get_pong = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };

    action do_bpmu_get_ping() {
        sfc.buffer_pool_utilization = (buffer_memory_t)bpmu_get_ping.execute(sfc.buffer_pool_idx);
    }

    action do_bpmu_get_pong() {
        sfc.buffer_pool_utilization = (buffer_memory_t)bpmu_get_pong.execute(sfc.buffer_pool_idx);
    }

    @stage(QUEUE_REG_STAGE_QD)
    table tbl_bpmu_get_ping {
        key = {}
        actions = {
            do_bpmu_get_ping;
        }
        const default_action = do_bpmu_get_ping;
        size = queue_id_cnt;
    }

    @stage(QUEUE_REG_STAGE_QD)
    table tbl_bpmu_get_pong {
        key = {}
        actions = {
            do_bpmu_get_pong;
        }
        const default_action = do_bpmu_get_pong;
        size = queue_id_cnt;
    }

    // Ghost thread: message counter
    RegisterAction<bit<32>, queue_idx_t, bit<32>>(ping_ghost_cnt_reg) ping_ghost_cnt = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };
    RegisterAction<bit<32>, queue_idx_t, bit<32>>(pong_ghost_cnt_reg) pong_ghost_cnt = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = value; } };

    action ping_get_ghost_cnt() {
        sfc.ghost_msg_cnt_queue = ping_ghost_cnt.execute(sfc.queue_id_idx);
    }

    action pong_get_ghost_cnt() {
        sfc.ghost_msg_cnt_queue = pong_ghost_cnt.execute(sfc.queue_id_idx);
    }

    @stage(QUEUE_REG_STAGE_CNT)
    table ping_ghost_cnt_tbl {
        key = {}
        actions = {
            ping_get_ghost_cnt;
        }
        const default_action = ping_get_ghost_cnt;
        size = queue_id_cnt;
    }

    @stage(QUEUE_REG_STAGE_CNT)
    table pong_ghost_cnt_tbl {
        key = {}
        actions = {
            pong_get_ghost_cnt;
        }
        const default_action = pong_get_ghost_cnt;
        size = queue_id_cnt;
    }

    // Ghost thread: total message counter
    // We need to explicitely define the table inorder to make the @stage pragma
    // work, which, according to the documentation, attaches only to tables, not to actions.
    RegisterAction<bit<32>, bit<1>, bit<32>>(ping_ghost_total_cnt_reg) ping_ghost_total_cnt = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = (bit<32>) value; } };
    RegisterAction<bit<32>, bit<1>, bit<32>>(pong_ghost_total_cnt_reg) pong_ghost_total_cnt = {
        void apply(inout bit<32> value, out bit<32> rv) { rv = (bit<32>) value; } };

    action ping_get_ghost_total_cnt(bit<1> should_get) {
        sfc.ghost_msg_cnt_total = ping_ghost_total_cnt.execute(should_get);
    }

    action pong_get_ghost_total_cnt(bit<1> should_get) {
        sfc.ghost_msg_cnt_total = pong_ghost_total_cnt.execute(should_get);
    }

    @stage(QUEUE_REG_STAGE_CNT)
    table ping_ghost_total_cnt_tbl {
        // Yes, the match key is useless. However, if it is removed, the compile will complain
        // about an inintelligible issue, so I should stay for now.
        key = {
            hdr.instrumentation.isValid() : exact;
        }
        actions = {
            ping_get_ghost_total_cnt;
            NoAction;
        }
        const default_action = NoAction;
        size = 2;
    }

    @stage(QUEUE_REG_STAGE_CNT)
    table pong_ghost_total_cnt_tbl {
        // Yes, the match key is useless. However, if it is removed, the compiler will complain
        // about an inintelligible issue, so I should stay for now.
        key = {
            hdr.instrumentation.isValid() : exact;
        }
        actions = {
            pong_get_ghost_total_cnt;
            NoAction;
        }
        const default_action = NoAction;
        size = 2;
    }

    apply {
        ctrl_sfc_init.apply(sfc);
        ingress_set_register_idx_tbl.apply();

        if (g_intr_md.ping_pong == ping_pong_ingress) {
            tbl_qd_get_ping.apply();
            tbl_bpmu_get_ping.apply();
            ping_ghost_cnt_tbl.apply();
            ping_ghost_total_cnt_tbl.apply();
        } else {
            tbl_qd_get_pong.apply();
            tbl_bpmu_get_pong.apply();
            pong_ghost_cnt_tbl.apply();
            pong_ghost_total_cnt_tbl.apply();
        }
        sfc.new_queue_depth = sfc.queue_depth + (buffer_memory_t)sfc.packet_length_cells;
    }
}

// ---------------------------------------------------------------------------
// Handover to signaling component
// ---------------------------------------------------------------------------


control handover_to_signaling(in sfc_t sfc,
                              inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                              out sfc_signal_t signal_hdr
                              ){

    // TODO: Truncate: in session or here?
    apply {
        signal_hdr.pause_duration = sfc.pause_duration;
        // Set fixed to SFC for now
        signal_hdr.signal_type = 0;
        signal_hdr.setValid();
        ig_intr_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
        ig_intr_dprsr_md.mirror_egress_port = sfc.signaling_port;
        ig_intr_dprsr_md.mirror_qid = sfc.signaling_qid;
        ig_intr_dprsr_md.mirror_io_select = 1;
        ig_intr_dprsr_md.mirror_ingress_cos = sfc.signaling_icos;
        ig_intr_dprsr_md.mirror_deflect_on_drop = 0;
    }
}


// ---------------------------------------------------------------------------
// SFC trigger suppression
// This function must be called only if a SFC pause packet should be send.
// Requires the reset of the bloom filter regularily.
// TODO: Determine minimmum bloom filter back switching time
// TODO: How to handle long pauses, with t > 2**32?
//
// @param sfc: sfc meta data
// @param tstamp: lsb 32bit of ingress packet timestamp
// @param send_sfc_pause: should a SFC Pause packet be sent?
// ---------------------------------------------------------------------------

struct sfc_pause_epoch_reg_t {
    bit<32> epoch_end_tstamp;
    bit<32> epoch_duration;
}

control sfc_pause_suppression(in sfc_t sfc,
                              in bit<32> tstamp,
                              out bool send_sfc_pause) {

    bit<1> fr1 = 0;
    bit<1> fr2 = 0;
    bit<1> fr3 = 0;
    bit<16> dst_hash1 = 0;
    bit<16> dst_hash2 = 0;
    bit<16> dst_hash3 = 0;

    bit<1> switch_filter_bank = 0;
    bit<1> filter_bank_idx = 0;

    // The filter clearing could be moved to a more general part of the program.
    // Thereby, also non-pfc-pause packet would trigger a filter reset.
    // Not sure if that would significantly improve things though.
    // epoch_end_timestamp = timestamp of current epoch
    // epoch_duration = duration of new epoch, can be configured from the control plane (?)
    Register<sfc_pause_epoch_reg_t, bit<1>>(32w1, {32w0, 32w0}) reg_filter_epoch;

    /**
     * Determine if the epoch is run out and if the filter banks should be switched.
     *
     * @param tstamp: the current timestamp
     * @param time_to_switch_filter_bank: returns 1 iff filter banks should be switched, 0 otherwise
     **/
    RegisterAction<sfc_pause_epoch_reg_t, bit<1>, bit<32>>(reg_filter_epoch) filter_epoch = {
        void apply(inout sfc_pause_epoch_reg_t value, out bit<32> time_to_switch_filter_bank){
            if (tstamp > value.epoch_end_tstamp) {
                // Time to reset the filters, set new epoch end time.
                // Works for initialization too, when epoch_end_stamp is 0
                value.epoch_end_tstamp = tstamp + value.epoch_duration;
                time_to_switch_filter_bank = 1;
            } else {
                // No reset, nothing to do.
                time_to_switch_filter_bank = 0;
            }
        }
    };

    Register<bit<32>, bit<1>>(1, 0) reg_filter_select;
    // Switch bloom filter idx
    RegisterAction<bit<32>, bit<1>, bit<32>>(reg_filter_select) filter_select = {
        void apply(inout bit<32> value, out bit<32> current_filter_bank_idx){
            if (switch_filter_bank == 1) {
                value = ~value;
            }
            current_filter_bank_idx = value;
        }
    };


    // Use pre-defined algorithms from there:
    // http://crcmod.sourceforge.net/crcmod.predefined.html#predefined-crc-algorithms
    // TODO: Selection is made for every hash to have a different polynomial, not sure if that
    // is sufficient for our use case?
    CRCPolynomial<bit<16>>(16w0x0589, // polynomial
                           false, // reversed
                           true, // use msb?
                           false, // extended?
                           16w0x0001, // initial shift register value
                           16w0x0001 // result xor
                           ) crc_16_dect;
    CRCPolynomial<bit<16>>(16w0x3d65, // polynomial
                           true, // reversed
                           true, // use msb?
                           false, // extended?
                           16w0xffff, // initial shift register value
                           16w0xffff // result xor
                           ) crc_16_dnp;

    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash1;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, crc_16_dect) hash2;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, crc_16_dnp) hash3;

    Register<bit<1>, bit<16>>(1 << 16, 0) pause_filter_bank0_reg1;
    Register<bit<1>, bit<16>>(1 << 16, 0) pause_filter_bank0_reg2;
    Register<bit<1>, bit<16>>(1 << 16, 0) pause_filter_bank0_reg3;

    Register<bit<1>, bit<16>>(1 << 16, 0) pause_filter_bank1_reg1;
    Register<bit<1>, bit<16>>(1 << 16, 0) pause_filter_bank1_reg2;
    Register<bit<1>, bit<16>>(1 << 16, 0) pause_filter_bank1_reg3;

    RegisterAction<bit<1>, bit<16>, bit<1>>(pause_filter_bank0_reg1) bank0_filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<16>, bit<1>>(pause_filter_bank0_reg2) bank0_filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<16>, bit<1>>(pause_filter_bank0_reg3) bank0_filter3 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<16>, bit<1>>(pause_filter_bank1_reg1) bank1_filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<16>, bit<1>>(pause_filter_bank1_reg2) bank1_filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<16>, bit<1>>(pause_filter_bank1_reg3) bank1_filter3 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    apply {
        //
        // Clearing: 1 cycle per SRAM line (128 bit) per stage? Per memory?
        // Compiler should pack registers without wasted memory
        // Ask Mike Ferrara
        //
        dst_hash1 = hash1.get({sfc.dst_ip, sfc.nw_tc});
        dst_hash2 = hash2.get({sfc.dst_ip, sfc.nw_tc});
        dst_hash3 = hash3.get({sfc.dst_ip, sfc.nw_tc});

        switch_filter_bank = (bit<1>)filter_epoch.execute(1w0);
        filter_bank_idx = (bit<1>)filter_select.execute(1w0);

        if (filter_bank_idx == 0) {
            fr1 = bank0_filter1.execute(dst_hash1);
            fr2 = bank0_filter2.execute(dst_hash2);
            fr3 = bank0_filter3.execute(dst_hash3);

            if (switch_filter_bank == 1) {
                // We switched filters, clear the old one
                pause_filter_bank1_reg1.clear(1w0,1w0);
                pause_filter_bank1_reg2.clear(1w0,1w0);
                pause_filter_bank1_reg3.clear(1w0,1w0);
            }
        } else if (filter_bank_idx == 1) {
            fr1 = bank1_filter1.execute(dst_hash1);
            fr2 = bank1_filter2.execute(dst_hash2);
            fr3 = bank1_filter3.execute(dst_hash3);

            if (switch_filter_bank == 1) {
                // We switched filters, clear the old one
                pause_filter_bank0_reg1.clear(1w0,1w0);
                pause_filter_bank0_reg2.clear(1w0,1w0);
                pause_filter_bank0_reg3.clear(1w0,1w0);
            }
        }

        send_sfc_pause = ! ((fr1 ++ fr2 ++ fr3) == 0b111);
    }
}


// ---------------------------------------------------------------------------
// Simple queue depth threshold trigger with static pause time
// ---------------------------------------------------------------------------
control sfc_trigger_qthreshold(inout sfc_t sfc) {

    SfcPauseTime_t tmp_pause_duration = 0;
    buffer_memory_t queue_threshold = 0;

    action do_set_threshold(buffer_memory_t threshold,
                            SfcPauseTime_t duration) {
        queue_threshold = threshold;
        tmp_pause_duration = duration;
    }

    table tbl_select_threshold {
        key = {
            sfc.queue_id_idx : exact;
        }
        actions = {
            do_set_threshold;
            NoAction;
        }
        const default_action = NoAction;
        size = queue_id_cnt;
    }

    action do_set_pause_time(SfcPauseTime_t pause_time) {
        sfc.pause_duration = pause_time;
    }

    table tbl_set_pause_time {
        key = {
            sfc.egress_port_speed : exact;
            sfc.new_queue_depth : exact;
        }
        actions = {
            do_set_pause_time;
            NoAction;
        }
        size = sfc_pause_time_lut_size;
    }

    apply {
        tbl_select_threshold.apply();

        // TODO: Change back from == to >
        // if (sfc.new_queue_depth > queue_threshold) {
        if (sfc.new_queue_depth == queue_threshold) {
            tbl_set_pause_time.apply();
        }
    }
}


// ---------------------------------------------------------------------------
// Simple queue depth threshold trigger with calculated pause time
// ---------------------------------------------------------------------------

struct SfcPauseThresholdSpeed_t {
    bit<32> queue_threshold;
    bit<32> port_cells_per_time; // Depends on the configuration, can be ns, us
}

control sfc_trigger_qthreshold_ptc(inout sfc_t sfc) {

    SfcPauseTime_t tmp_pause_duration = 0;
    buffer_memory_t queue_threshold = 0;

    // This clearly does not work. The constant is stored once per SALU only, not once per register value.
    // Therefore, we cannot use the port speed idx to identify the corresponding register.
    Register<SfcPauseThresholdSpeed_t, PortSpeed_t>(9) reg_check_threshold;
    RegisterAction<SfcPauseThresholdSpeed_t, PortSpeed_t, SfcPauseTime_t>(reg_check_threshold) check_threshold = {
        // @param PortSpeed_t: Port speed, each register contains the values for a single port speed
        // @param sfc.new_queue_depth: Check this value if it has crossed the threshold
        // @return pause_time: The time to pause the port/tc, 0 otherwise
        void apply(inout SfcPauseThresholdSpeed_t reg_val, out SfcPauseTime_t pause_time) {
            if ((bit<32>)sfc.new_queue_depth > reg_val.queue_threshold) {
                pause_time = (bit<16>)((bit<32>)sfc.new_queue_depth / 100); // Divisor dummy value, to be set by the control plane.
            } else {
                pause_time = 0;
            }
        }
    };

    action do_set_threshold(buffer_memory_t threshold,
                            SfcPauseTime_t duration) {
        queue_threshold = threshold;
        tmp_pause_duration = duration;
    }

    table tbl_select_threshold {
        key = {
            sfc.queue_id_idx : exact;
        }
        actions = {
            do_set_threshold;
            NoAction;
        }
        const default_action = NoAction;
        size = queue_id_cnt;
    }

    apply {
        tbl_select_threshold.apply();

        if (sfc.new_queue_depth > queue_threshold) {
            sfc.pause_duration = tmp_pause_duration;
        }
    }
}



// ---------------------------------------------------------------------------
// Dual-RED SFC Trigger
// ---------------------------------------------------------------------------


// Dual ingress RED
// Run RED on the queue and the pool and trigger SFC on either.
control sfc_trigger_di_red(inout sfc_t sfc) {


    Wred<buffer_memory_t, buffer_pool_idx_t>(buffer_pool_cnt, 1 /* drop value*/, 0 /* no drop value */) pool_red;
    // We use
    // (new_queue_depth) >> BAF + buffer_pool_utilization < buffer_pool_capacity
    Wred<buffer_memory_t, queue_idx_t>(queue_id_cnt, 1 /* drop value*/, 0 /* no drop value */) queue_red;

    buffer_memory_t queue_util_comp;
    bool qr;
    bool pr;

    apply {
        if (sfc.baf_shift_sign == 0) {
            queue_util_comp = sfc.new_queue_depth << sfc.baf_shift;
        } else {
            queue_util_comp = sfc.new_queue_depth >> sfc.baf_shift;
        }
        queue_util_comp = queue_util_comp + sfc.buffer_pool_utilization;

        qr = (bool)(bit<1>)queue_red.execute(queue_util_comp, sfc.queue_id_idx);
        pr = (bool)(bit<1>)pool_red.execute(sfc.buffer_pool_utilization, sfc.buffer_pool_idx);

        if (qr || pr) {
            // TODO: Calculate duration
            sfc.pause_duration = 127;
        }
    }
}


// ---------------------------------------------------------------------------
// Ghost
// ---------------------------------------------------------------------------


control ghost(in ghost_intrinsic_metadata_t g_intr_md) {

    set_tm_data_from_ghost() ctrl_set_tm_data_from_ghost;

    apply {
        ctrl_set_tm_data_from_ghost.apply(g_intr_md);
    }
}



// ---------------------------------------------------------------------------
// Ingress
// ---------------------------------------------------------------------------

struct metadata_t {
    sfc_t sfc;
    sfc_signal_t sfc_signal;
    MirrorId_t ing_mir_ses;
}

parser iPrsr(packet_in packet, out header_t hdr, out metadata_t meta,
             out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(128);
        packet.advance(64);
        transition parse_ethernet;
    }

    state parse_ethernet {
        meta.sfc.packet_length_bytes = 14;
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            17 : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4711 : parse_instrumentation;
            default : accept;
        }
    }

    state parse_instrumentation {
        packet.extract(hdr.instrumentation);
        transition accept;
    }
}


control ingress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
        in ghost_intrinsic_metadata_t g_intr_md) {

    get_tm_data_from_ingress() ctrl_get_tm_data_from_ingress;
    sfc_config_prepare() ctrl_config_prepare;
    sfc_pause_suppression() pause_suppression;
    handover_to_signaling() trigger_sfc;
    // Select one of the trigger algorithms
    sfc_trigger_qthreshold() ctrl_sfc_trigger;
    // sfc_trigger_dired() ctrl_sfc_trigger;

    // Should an SFC Pause Packet be sent, or should it be suppressed?
    bool send_pause = false;

    action do_update_packet_length_ipv4() {
        ig_md.sfc.packet_length_bytes = ig_md.sfc.packet_length_bytes + hdr.ipv4.total_len;
    }

    action do_set_packet_length_cells(bit<8> packet_length_cells) {
        ig_md.sfc.packet_length_cells = packet_length_cells;
    }

    table tbl_set_packet_length_cells {
        key = {
            ig_md.sfc.packet_length_bytes : ternary;
        }
        actions = {
            do_set_packet_length_cells;
        }
        size = pkt_size_lookup_table;
    }

    action do_set_out_port(PortId_t egress_port) {
        ig_intr_tm_md.ucast_egress_port = egress_port;
    }

    table tbl_set_out_port {
        key = {
            ig_intr_md.ingress_port : ternary;
        }
        actions = {
            do_set_out_port;
            NoAction;
        }
        const default_action = NoAction;
        size = routing_entry_cnt;
    }

    action do_classify(QueueId_t qid,
                       bit<3> icos) {
        ig_intr_tm_md.qid = qid;
        ig_intr_tm_md.ingress_cos = icos;
    }

    table tbl_classify_packet {
        key = {
            ig_intr_md.ingress_port : ternary;
            hdr.ipv4.dscp : ternary;
        }
        actions = {
            do_classify;
            NoAction;
        }
        const default_action = NoAction;
        size = routing_entry_cnt;
    }

    apply {
        tbl_set_out_port.apply();
        tbl_classify_packet.apply();


        if (hdr.ipv4.isValid()) {
            // Determine packet size in cells
            do_update_packet_length_ipv4();
            tbl_set_packet_length_cells.apply();

            // DEPENDENCY: Routing tabel before here

            // Set required SFC configuration data
            ctrl_config_prepare.apply(ig_intr_md.ingress_port,
                                      ig_intr_tm_md.ucast_egress_port,
                                      ig_intr_tm_md.qid,
                                      ig_md.sfc);

            // Get queue depth information on queue and buffer pool
            ctrl_get_tm_data_from_ingress.apply(
                g_intr_md,
                ig_intr_tm_md.ucast_egress_port,
                ig_intr_tm_md.qid,
                hdr,
                ig_md.sfc);

            // Run SFC trigger algorithm
            ctrl_sfc_trigger.apply(ig_md.sfc);

            if (ig_md.sfc.pause_duration != 0) {
                // SFC pause was trigger, check if a packet has been sent recently
                pause_suppression.apply(ig_md.sfc, ig_intr_prsr_md.global_tstamp[31:0], send_pause);

                if (send_pause) {
                    // Create a mirrored packet and hand over to the SFC pause signaling component.
                    trigger_sfc.apply(ig_md.sfc,
                                      ig_intr_dprsr_md,
                                      ig_md.sfc_signal);
                }
            }
        }
    }
}

control iDprsr(packet_out packet, inout header_t hdr, in metadata_t ig_md,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {

    Mirror() mirror;

    apply {

        if (ig_intr_md_for_dprs.mirror_type == MIRROR_TYPE_I2E) {
            mirror.emit<sfc_signal_t>(ig_md.ing_mir_ses, ig_md.sfc_signal);
        }

        packet.emit(hdr);
    }
}



// ---------------------------------------------------------------------------
// Egress
// ---------------------------------------------------------------------------


parser ePrsr(packet_in packet,
             out header_t hdr,
             out metadata_t meta,
             out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        meta.sfc.packet_length_bytes = 14;
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x0800 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            17 : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4711 : parse_instrumentation;
            default : accept;
        }
    }

    state parse_instrumentation {
        packet.extract(hdr.instrumentation);
        transition accept;
    }
}


control egress(inout header_t hdr,
               inout metadata_t meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    action do_instrument() {
        // TBD
    }

    apply {
        if (hdr.instrumentation.isValid()) {
            do_instrument();
        }
    }
}


control eDprsr(packet_out packet, inout header_t hdr, in metadata_t meta,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
         packet.emit(hdr);
    }
}



// ---------------------------------------------------------------------------
// Pipe
// ---------------------------------------------------------------------------


Pipeline(iPrsr(), ingress(), iDprsr(), ePrsr(), egress(), eDprsr(), ghost()) pipe;
Switch(pipe) main;
