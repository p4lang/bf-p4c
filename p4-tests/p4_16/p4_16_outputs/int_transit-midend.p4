#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ethertype;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
    bit<16> checksum;
}

header intl4_shim_t {
    bit<8> int_type;
    bit<8> rsvd1;
    bit<8> len;
    bit<8> rsvd2;
}

header int_header_t {
    bit<4>  ver;
    bit<2>  rep;
    bit<1>  c;
    bit<1>  e;
    bit<1>  m;
    bit<7>  rsvd1;
    bit<3>  rsvd2;
    bit<5>  ins_cnt;
    bit<8>  remaining_hop_cnt;
    bit<4>  instruction_mask_0003;
    bit<4>  instruction_mask_0407;
    bit<4>  instruction_mask_0811;
    bit<4>  instruction_mask_1215;
    bit<16> rsvd3;
}

header int_switch_id_t {
    bit<32> switch_id;
}

header int_port_ids_t {
    bit<16> ingress_port_id;
    bit<16> egress_port_id;
}

header int_hop_latency_t {
    bit<32> hop_latency;
}

header int_q_occupancy_t {
    bit<8>  q_id;
    bit<24> q_occupancy;
}

header int_ingress_tstamp_t {
    bit<32> ingress_tstamp;
}

header int_egress_tstamp_t {
    bit<32> egress_tstamp;
}

header int_q_congestion_t {
    bit<8>  q_id;
    bit<24> q_congestion;
}

header int_egress_port_tx_util_t {
    bit<32> egress_port_tx_util;
}

struct headers_t {
    ethernet_t                ethernet;
    ipv4_t                    ipv4;
    udp_t                     udp;
    intl4_shim_t              intl4_shim;
    int_header_t              int_header;
    int_switch_id_t           int_switch_id;
    int_port_ids_t            int_port_ids;
    int_hop_latency_t         int_hop_latency;
    int_q_occupancy_t         int_q_occupancy;
    int_ingress_tstamp_t      int_ingress_tstamp;
    int_egress_tstamp_t       int_egress_tstamp;
    int_q_congestion_t        int_q_congestion;
    int_egress_port_tx_util_t int_egress_port_tx_util;
}

struct int_metadata_t {
    bit<16> insert_byte_cnt;
    bit<8>  int_hdr_word_len;
    bit<32> switch_id;
    bit<5>  ins_cnt_tmp;
    bit<5>  ins_cnt_tmp2;
}

struct metadata_t {
    int_metadata_t int_metadata;
}

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w17: parse_udp;
            default: accept;
        }
    }
    state parse_udp {
        packet.extract<udp_t>(hdr.udp);
        transition select(hdr.ipv4.dscp) {
            6w0x1 &&& 6w0x1: parse_intl4_shim;
            default: accept;
        }
    }
    state parse_intl4_shim {
        packet.extract<intl4_shim_t>(hdr.intl4_shim);
        transition select(hdr.intl4_shim.int_type) {
            8w1: parse_int_header;
            default: accept;
        }
    }
    state parse_int_header {
        packet.extract<int_header_t>(hdr.int_header);
        meta.int_metadata.ins_cnt_tmp = hdr.int_header.ins_cnt;
        meta.int_metadata.ins_cnt_tmp2 = hdr.int_header.ins_cnt;
        transition accept;
    }
    state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.ethertype) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

struct tuple_0 {
    bit<4>  field;
    bit<4>  field_0;
    bit<6>  field_1;
    bit<2>  field_2;
    bit<16> field_3;
    bit<16> field_4;
    bit<3>  field_5;
    bit<13> field_6;
    bit<8>  field_7;
    bit<8>  field_8;
    bit<32> field_9;
    bit<32> field_10;
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        update_checksum<tuple_0, bit<16>>(hdr.ipv4.isValid(), { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.dscp, hdr.ipv4.ecn, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr }, hdr.ipv4.hdr_checksum, HashAlgorithm.csum16);
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    @hidden action act() {
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i0") action int_egress_int_metadata_insert_int_set_header_0003_i0_0() {
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i1") action int_egress_int_metadata_insert_int_set_header_0003_i1_0() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 8w0x0;
        hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.deq_qdepth;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i2") action int_egress_int_metadata_insert_int_set_header_0003_i2_0() {
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 32w0xffffffff;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i3") action int_egress_int_metadata_insert_int_set_header_0003_i3_0() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 8w0x0;
        hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.deq_qdepth;
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 32w0xffffffff;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i4") action int_egress_int_metadata_insert_int_set_header_0003_i4_0() {
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i5") action int_egress_int_metadata_insert_int_set_header_0003_i5_0() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 8w0x0;
        hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.deq_qdepth;
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i6") action int_egress_int_metadata_insert_int_set_header_0003_i6_0() {
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 32w0xffffffff;
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i7") action int_egress_int_metadata_insert_int_set_header_0003_i7_0() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 8w0x0;
        hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.deq_qdepth;
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 32w0xffffffff;
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i8") action int_egress_int_metadata_insert_int_set_header_0003_i8_0() {
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = meta.int_metadata.switch_id;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i9") action int_egress_int_metadata_insert_int_set_header_0003_i9_0() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 8w0x0;
        hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.deq_qdepth;
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = meta.int_metadata.switch_id;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i10") action int_egress_int_metadata_insert_int_set_header_0003_i10_0() {
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 32w0xffffffff;
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = meta.int_metadata.switch_id;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i11") action int_egress_int_metadata_insert_int_set_header_0003_i11_0() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 8w0x0;
        hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.deq_qdepth;
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 32w0xffffffff;
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = meta.int_metadata.switch_id;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i12") action int_egress_int_metadata_insert_int_set_header_0003_i12_0() {
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = meta.int_metadata.switch_id;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i13") action int_egress_int_metadata_insert_int_set_header_0003_i13_0() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 8w0x0;
        hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.deq_qdepth;
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = meta.int_metadata.switch_id;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i14") action int_egress_int_metadata_insert_int_set_header_0003_i14_0() {
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 32w0xffffffff;
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = meta.int_metadata.switch_id;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0003_i15") action int_egress_int_metadata_insert_int_set_header_0003_i15_0() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 8w0x0;
        hdr.int_q_occupancy.q_occupancy = (bit<24>)standard_metadata.deq_qdepth;
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 32w0xffffffff;
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id = (bit<16>)standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id = (bit<16>)standard_metadata.egress_port;
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = meta.int_metadata.switch_id;
    }
    @name("egress.int_egress.int_metadata_insert.int_inst_0003") table int_egress_int_metadata_insert_int_inst {
        key = {
            hdr.int_header.instruction_mask_0003: exact @name("hdr.int_header.instruction_mask_0003") ;
        }
        actions = {
            int_egress_int_metadata_insert_int_set_header_0003_i0_0();
            int_egress_int_metadata_insert_int_set_header_0003_i1_0();
            int_egress_int_metadata_insert_int_set_header_0003_i2_0();
            int_egress_int_metadata_insert_int_set_header_0003_i3_0();
            int_egress_int_metadata_insert_int_set_header_0003_i4_0();
            int_egress_int_metadata_insert_int_set_header_0003_i5_0();
            int_egress_int_metadata_insert_int_set_header_0003_i6_0();
            int_egress_int_metadata_insert_int_set_header_0003_i7_0();
            int_egress_int_metadata_insert_int_set_header_0003_i8_0();
            int_egress_int_metadata_insert_int_set_header_0003_i9_0();
            int_egress_int_metadata_insert_int_set_header_0003_i10_0();
            int_egress_int_metadata_insert_int_set_header_0003_i11_0();
            int_egress_int_metadata_insert_int_set_header_0003_i12_0();
            int_egress_int_metadata_insert_int_set_header_0003_i13_0();
            int_egress_int_metadata_insert_int_set_header_0003_i14_0();
            int_egress_int_metadata_insert_int_set_header_0003_i15_0();
        }
        default_action = int_egress_int_metadata_insert_int_set_header_0003_i0_0();
        size = 17;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i0") action int_egress_int_metadata_insert_int_set_header_0407_i0_0() {
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i1") action int_egress_int_metadata_insert_int_set_header_0407_i1_0() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 32w0xffffffff;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i2") action int_egress_int_metadata_insert_int_set_header_0407_i2_0() {
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 8w0xff;
        hdr.int_q_congestion.q_congestion = 24w0xffffff;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i3") action int_egress_int_metadata_insert_int_set_header_0407_i3_0() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 32w0xffffffff;
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 8w0xff;
        hdr.int_q_congestion.q_congestion = 24w0xffffff;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i4") action int_egress_int_metadata_insert_int_set_header_0407_i4_0() {
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp = (bit<32>)standard_metadata.egress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i5") action int_egress_int_metadata_insert_int_set_header_0407_i5_0() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 32w0xffffffff;
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp = (bit<32>)standard_metadata.egress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i6") action int_egress_int_metadata_insert_int_set_header_0407_i6_0() {
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 8w0xff;
        hdr.int_q_congestion.q_congestion = 24w0xffffff;
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp = (bit<32>)standard_metadata.egress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i7") action int_egress_int_metadata_insert_int_set_header_0407_i7_0() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 32w0xffffffff;
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 8w0xff;
        hdr.int_q_congestion.q_congestion = 24w0xffffff;
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp = (bit<32>)standard_metadata.egress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i8") action int_egress_int_metadata_insert_int_set_header_0407_i8_0() {
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i9") action int_egress_int_metadata_insert_int_set_header_0407_i9_0() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 32w0xffffffff;
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i10") action int_egress_int_metadata_insert_int_set_header_0407_i10_0() {
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 8w0xff;
        hdr.int_q_congestion.q_congestion = 24w0xffffff;
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i11") action int_egress_int_metadata_insert_int_set_header_0407_i11_0() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 32w0xffffffff;
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 8w0xff;
        hdr.int_q_congestion.q_congestion = 24w0xffffff;
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i12") action int_egress_int_metadata_insert_int_set_header_0407_i12_0() {
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp = (bit<32>)standard_metadata.egress_global_timestamp;
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i13") action int_egress_int_metadata_insert_int_set_header_0407_i13_0() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 32w0xffffffff;
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp = (bit<32>)standard_metadata.egress_global_timestamp;
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i14") action int_egress_int_metadata_insert_int_set_header_0407_i14_0() {
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 8w0xff;
        hdr.int_q_congestion.q_congestion = 24w0xffffff;
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp = (bit<32>)standard_metadata.egress_global_timestamp;
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_set_header_0407_i15") action int_egress_int_metadata_insert_int_set_header_0407_i15_0() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 32w0xffffffff;
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 8w0xff;
        hdr.int_q_congestion.q_congestion = 24w0xffffff;
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp = (bit<32>)standard_metadata.egress_global_timestamp;
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp = (bit<32>)standard_metadata.ingress_global_timestamp;
    }
    @name("egress.int_egress.int_metadata_insert.int_inst_0407") table int_egress_int_metadata_insert_int_inst_0 {
        key = {
            hdr.int_header.instruction_mask_0407: exact @name("hdr.int_header.instruction_mask_0407") ;
        }
        actions = {
            int_egress_int_metadata_insert_int_set_header_0407_i0_0();
            int_egress_int_metadata_insert_int_set_header_0407_i1_0();
            int_egress_int_metadata_insert_int_set_header_0407_i2_0();
            int_egress_int_metadata_insert_int_set_header_0407_i3_0();
            int_egress_int_metadata_insert_int_set_header_0407_i4_0();
            int_egress_int_metadata_insert_int_set_header_0407_i5_0();
            int_egress_int_metadata_insert_int_set_header_0407_i6_0();
            int_egress_int_metadata_insert_int_set_header_0407_i7_0();
            int_egress_int_metadata_insert_int_set_header_0407_i8_0();
            int_egress_int_metadata_insert_int_set_header_0407_i9_0();
            int_egress_int_metadata_insert_int_set_header_0407_i10_0();
            int_egress_int_metadata_insert_int_set_header_0407_i11_0();
            int_egress_int_metadata_insert_int_set_header_0407_i12_0();
            int_egress_int_metadata_insert_int_set_header_0407_i13_0();
            int_egress_int_metadata_insert_int_set_header_0407_i14_0();
            int_egress_int_metadata_insert_int_set_header_0407_i15_0();
        }
        default_action = int_egress_int_metadata_insert_int_set_header_0407_i0_0();
        size = 17;
    }
    @name("egress.int_egress.int_outer_encap.int_update_ipv4") action int_egress_int_outer_encap_int_update_ipv4_0() {
        hdr.ipv4.total_len = hdr.ipv4.total_len + meta.int_metadata.insert_byte_cnt;
    }
    @name("egress.int_egress.int_outer_encap.int_update_udp") action int_egress_int_outer_encap_int_update_udp_0() {
        hdr.udp.len = hdr.udp.len + meta.int_metadata.insert_byte_cnt;
        hdr.udp.checksum = 16w0;
    }
    @name("egress.int_egress.int_outer_encap.int_update_shim") action int_egress_int_outer_encap_int_update_shim_0() {
        hdr.intl4_shim.len = hdr.intl4_shim.len + meta.int_metadata.int_hdr_word_len;
    }
    @name("egress.int_egress.int_transit") action int_egress_int_transit_0(bit<32> switch_id) {
        meta.int_metadata.switch_id = switch_id;
        meta.int_metadata.insert_byte_cnt = (bit<16>)(meta.int_metadata.ins_cnt_tmp2 << 2);
        meta.int_metadata.int_hdr_word_len = (bit<8>)meta.int_metadata.ins_cnt_tmp;
    }
    @name("egress.int_egress.int_prep") table int_egress_int_prep {
        key = {
        }
        actions = {
            int_egress_int_transit_0();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @name("egress.int_egress.int_hop_cnt_decrement") action int_egress_int_hop_cnt_decrement_0() {
        hdr.int_header.remaining_hop_cnt = hdr.int_header.remaining_hop_cnt + 8w255;
    }
    @name("egress.int_egress.int_hop_cnt_exceeded") action int_egress_int_hop_cnt_exceeded_0() {
        hdr.int_header.e = 1w1;
    }
    @hidden table tbl_int_egress_int_hop_cnt_decrement {
        actions = {
            int_egress_int_hop_cnt_decrement_0();
        }
        const default_action = int_egress_int_hop_cnt_decrement_0();
    }
    @hidden table tbl_int_egress_int_outer_encap_int_update_ipv4 {
        actions = {
            int_egress_int_outer_encap_int_update_ipv4_0();
        }
        const default_action = int_egress_int_outer_encap_int_update_ipv4_0();
    }
    @hidden table tbl_int_egress_int_outer_encap_int_update_udp {
        actions = {
            int_egress_int_outer_encap_int_update_udp_0();
        }
        const default_action = int_egress_int_outer_encap_int_update_udp_0();
    }
    @hidden table tbl_int_egress_int_outer_encap_int_update_shim {
        actions = {
            int_egress_int_outer_encap_int_update_shim_0();
        }
        const default_action = int_egress_int_outer_encap_int_update_shim_0();
    }
    @hidden table tbl_int_egress_int_hop_cnt_exceeded {
        actions = {
            int_egress_int_hop_cnt_exceeded_0();
        }
        const default_action = int_egress_int_hop_cnt_exceeded_0();
    }
    apply {
        if (hdr.int_header.isValid()) 
            if (hdr.int_header.remaining_hop_cnt != 8w0 && hdr.int_header.e == 1w0) {
                tbl_int_egress_int_hop_cnt_decrement.apply();
                int_egress_int_prep.apply();
                int_egress_int_metadata_insert_int_inst.apply();
                int_egress_int_metadata_insert_int_inst_0.apply();
                if (hdr.ipv4.isValid()) 
                    tbl_int_egress_int_outer_encap_int_update_ipv4.apply();
                if (hdr.udp.isValid()) 
                    tbl_int_egress_int_outer_encap_int_update_udp.apply();
                if (hdr.intl4_shim.isValid()) 
                    tbl_int_egress_int_outer_encap_int_update_shim.apply();
            }
            else 
                tbl_int_egress_int_hop_cnt_exceeded.apply();
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<udp_t>(hdr.udp);
        packet.emit<intl4_shim_t>(hdr.intl4_shim);
        packet.emit<int_header_t>(hdr.int_header);
        packet.emit<int_switch_id_t>(hdr.int_switch_id);
        packet.emit<int_port_ids_t>(hdr.int_port_ids);
        packet.emit<int_hop_latency_t>(hdr.int_hop_latency);
        packet.emit<int_q_occupancy_t>(hdr.int_q_occupancy);
        packet.emit<int_ingress_tstamp_t>(hdr.int_ingress_tstamp);
        packet.emit<int_egress_tstamp_t>(hdr.int_egress_tstamp);
        packet.emit<int_q_congestion_t>(hdr.int_q_congestion);
        packet.emit<int_egress_port_tx_util_t>(hdr.int_egress_port_tx_util);
    }
}

V1Switch<headers_t, metadata_t>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

