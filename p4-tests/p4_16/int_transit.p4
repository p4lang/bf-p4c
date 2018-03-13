#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ethertype;
}

header ipv4_t {
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

// INT headers
header int_header_t {
    bit<4> ver;
    bit<2> rep;
    bit<1> c;
    bit<1> e;
    bit<1> m;
    bit<7> rsvd1;
    bit<3> rsvd2;
    bit<5> ins_cnt;
    bit<8> remaining_hop_cnt;
    bit<4> instruction_mask_0003; // split the bits for lookup
    bit<4> instruction_mask_0407;
    bit<4> instruction_mask_0811;
    bit<4> instruction_mask_1215;
    bit<16> rsvd3;
}

// INT meta-value headers - different header for each value type
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
    bit<8> q_id;
    bit<24> q_occupancy;
}

header int_ingress_tstamp_t {
    bit<32> ingress_tstamp;
}

header int_egress_tstamp_t {
    bit<32> egress_tstamp;
}

header int_q_congestion_t {
    bit<8> q_id;
    bit<24> q_congestion;
}

header int_egress_port_tx_util_t {
    bit<32> egress_port_tx_util;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t ipv4;
    udp_t udp;
    intl4_shim_t intl4_shim;
    int_header_t int_header;
    int_switch_id_t int_switch_id;
    int_port_ids_t int_port_ids;
    int_hop_latency_t int_hop_latency;
    int_q_occupancy_t int_q_occupancy;
    int_ingress_tstamp_t int_ingress_tstamp;
    int_egress_tstamp_t int_egress_tstamp;
    int_q_congestion_t int_q_congestion;
    int_egress_port_tx_util_t int_egress_port_tx_util;
}

struct int_metadata_t {
    bit<16> insert_byte_cnt;
    bit<8> int_hdr_word_len;
    bit<32> switch_id;
    bit<5> ins_cnt_tmp;
}

struct metadata_t {
    int_metadata_t int_metadata;
}

const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<8> PROTO_UDP = 17;

// indicate INT at LSB of DSCP
const bit<6> DSCP_INT = 0x1;

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta,
                  inout standard_metadata_t standard_metadata) {
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ethertype) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            PROTO_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.ipv4.dscp) {
            DSCP_INT &&& DSCP_INT: parse_intl4_shim;
            default: accept;
        }
    }

    state parse_intl4_shim {
        packet.extract(hdr.intl4_shim);
        // TODO(antonin): I do not need this transition but without it I run
        // into BRIG-513
        transition select(hdr.intl4_shim.int_type) {
            1: parse_int_header;
            default: accept;
        }
    }

    state parse_int_header {
        packet.extract(hdr.int_header);
        // extra metadata field necesaary to satisfy PH alignment constraints
        // meta.int_metadata.insert_byte_cnt and
        // meta.int_metadata.int_hdr_word_len cannot be assigned from the same
        // source in int_egress.int_transit
        meta.int_metadata.ins_cnt_tmp = hdr.int_header.ins_cnt;
        transition accept;
    }

    state start {
        transition parse_ethernet;
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        // Nothing to do
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        update_checksum(hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.dscp,
                hdr.ipv4.ecn,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            },
            hdr.ipv4.hdr_checksum,
            HashAlgorithm.csum16
        );
    }
}

control int_metadata_insert(inout headers_t hdr,
                            in int_metadata_t int_metadata,
                            inout standard_metadata_t standard_metadata) {
    // this implementation covers only INT instructions 0, 1, 2, 4, 5
    action int_set_header_0() {
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = int_metadata.switch_id;
    }

    action int_set_header_1() {
        hdr.int_port_ids.setValid();
        hdr.int_port_ids.ingress_port_id =
            (bit<16>) standard_metadata.ingress_port;
        hdr.int_port_ids.egress_port_id =
            (bit<16>) standard_metadata.egress_port;
    }

    action int_set_header_2() {
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency = 0xffffffff;
        // See BRIG-511
        // hdr.int_hop_latency.hop_latency =
        //     (bit<32>) (standard_metadata.egress_global_timestamp - standard_metadata.ingress_global_timestamp);
    }

    action int_set_header_3() { // Queue ID + Queue occupancy, not supported
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id = 0x00;
        hdr.int_q_occupancy.q_occupancy = (bit<24>) standard_metadata.deq_qdepth;
    }

    action int_set_header_4() {
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp =
            (bit<32>) standard_metadata.ingress_global_timestamp;
    }

    action int_set_header_5() {
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp =
            (bit<32>) standard_metadata.egress_global_timestamp;
    }

    action int_set_header_6() { // Queue ID + Queue congestion status, not supported
        hdr.int_q_congestion.setValid();
        hdr.int_q_congestion.q_id = 0xff;
        hdr.int_q_congestion.q_congestion = 0xffffff;
    }

    action int_set_header_7() { // Egress port tx utilization, not supported
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 0xffffffff;
    }

    action int_set_header_0003_i0() {
    }
    action int_set_header_0003_i1() {
        int_set_header_3();
    }
    action int_set_header_0003_i2() {
        int_set_header_2();
    }
    action int_set_header_0003_i3() {
        int_set_header_3();
        int_set_header_2();
    }
    action int_set_header_0003_i4() {
        int_set_header_1();
    }
    action int_set_header_0003_i5() {
        int_set_header_3();
        int_set_header_1();
    }
    action int_set_header_0003_i6() {
        int_set_header_2();
        int_set_header_1();
    }
    action int_set_header_0003_i7() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
    }
    action int_set_header_0003_i8() {
        int_set_header_0();
    }
    action int_set_header_0003_i9() {
        int_set_header_3();
        int_set_header_0();
    }
    action int_set_header_0003_i10() {
        int_set_header_2();
        int_set_header_0();
    }
    action int_set_header_0003_i11() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_0();
    }
    action int_set_header_0003_i12() {
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i13() {
        int_set_header_3();
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i14() {
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i15() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }

    table int_inst_0003 {
        key = {
            hdr.int_header.instruction_mask_0003 : exact;
        }
        actions = {
            int_set_header_0003_i0;
            int_set_header_0003_i1;
            int_set_header_0003_i2;
            int_set_header_0003_i3;
            int_set_header_0003_i4;
            int_set_header_0003_i5;
            int_set_header_0003_i6;
            int_set_header_0003_i7;
            int_set_header_0003_i8;
            int_set_header_0003_i9;
            int_set_header_0003_i10;
            int_set_header_0003_i11;
            int_set_header_0003_i12;
            int_set_header_0003_i13;
            int_set_header_0003_i14;
            int_set_header_0003_i15;
        }
        default_action = int_set_header_0003_i0();
        size = 17;
    }

    action int_set_header_0407_i0() {
    }
    action int_set_header_0407_i1() {
        int_set_header_7();
    }
    action int_set_header_0407_i2() {
        int_set_header_6();
    }
    action int_set_header_0407_i3() {
        int_set_header_7();
        int_set_header_6();
    }
    action int_set_header_0407_i4() {
        int_set_header_5();
    }
    action int_set_header_0407_i5() {
        int_set_header_7();
        int_set_header_5();
    }
    action int_set_header_0407_i6() {
        int_set_header_6();
        int_set_header_5();
    }
    action int_set_header_0407_i7() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
    }
    action int_set_header_0407_i8() {
        int_set_header_4();
    }
    action int_set_header_0407_i9() {
        int_set_header_7();
        int_set_header_4();
    }
    action int_set_header_0407_i10() {
        int_set_header_6();
        int_set_header_4();
    }
    action int_set_header_0407_i11() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_4();
    }
    action int_set_header_0407_i12() {
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i13() {
        int_set_header_7();
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i14() {
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i15() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
    }

    table int_inst_0407 {
        key = {
            hdr.int_header.instruction_mask_0407 : exact;
        }
        actions = {
            int_set_header_0407_i0;
            int_set_header_0407_i1;
            int_set_header_0407_i2;
            int_set_header_0407_i3;
            int_set_header_0407_i4;
            int_set_header_0407_i5;
            int_set_header_0407_i6;
            int_set_header_0407_i7;
            int_set_header_0407_i8;
            int_set_header_0407_i9;
            int_set_header_0407_i10;
            int_set_header_0407_i11;
            int_set_header_0407_i12;
            int_set_header_0407_i13;
            int_set_header_0407_i14;
            int_set_header_0407_i15;
        }
        default_action = int_set_header_0407_i0();
        size = 17;
    }

    apply {
        int_inst_0003.apply();
        int_inst_0407.apply();
    }
}

control int_outer_encap(inout headers_t hdr,
                        in int_metadata_t int_metadata) {
    action int_update_ipv4() {
        hdr.ipv4.total_len = hdr.ipv4.total_len + int_metadata.insert_byte_cnt;
    }
    action int_update_udp() {
        hdr.udp.len = hdr.udp.len + int_metadata.insert_byte_cnt;
        hdr.udp.checksum = 0;
    }
    action int_update_shim() {
        hdr.intl4_shim.len = hdr.intl4_shim.len + int_metadata.int_hdr_word_len;
    }

    apply{
        if (hdr.ipv4.isValid()) {
            int_update_ipv4();
        }
        if (hdr.udp.isValid()) {
            int_update_udp();
        }
        if (hdr.intl4_shim.isValid()) {
            int_update_shim();
        }
    }
}

control int_egress(inout headers_t hdr, inout metadata_t meta,
                   inout standard_metadata_t standard_metadata) {
    action int_transit(bit<32> switch_id) {
        meta.int_metadata.switch_id = switch_id;
        meta.int_metadata.insert_byte_cnt = (bit<16>) (hdr.int_header.ins_cnt << 2);
        meta.int_metadata.int_hdr_word_len = (bit<8>) meta.int_metadata.ins_cnt_tmp;
    }
    table int_prep {
        key = {}
        actions = {int_transit;}
    }

    action int_hop_cnt_decrement() {
        hdr.int_header.remaining_hop_cnt = hdr.int_header.remaining_hop_cnt - 1;
    }
    action int_hop_cnt_exceeded() {
        hdr.int_header.e = 1;
    }

    apply{
        if(hdr.int_header.isValid()) {
            if(hdr.int_header.remaining_hop_cnt != 0 && hdr.int_header.e == 0) {
                int_hop_cnt_decrement();
                int_prep.apply();
                int_metadata_insert.apply(hdr, meta.int_metadata, standard_metadata);
                int_outer_encap.apply(hdr, meta.int_metadata);
            } else {
                int_hop_cnt_exceeded();
            }
        }
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply {
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply {
        int_egress.apply(hdr, meta, standard_metadata);
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.intl4_shim);
        packet.emit(hdr.int_header);
        packet.emit(hdr.int_switch_id);
        packet.emit(hdr.int_port_ids);
        packet.emit(hdr.int_hop_latency);
        packet.emit(hdr.int_q_occupancy);
        packet.emit(hdr.int_ingress_tstamp);
        packet.emit(hdr.int_egress_tstamp);
        packet.emit(hdr.int_q_congestion);
        packet.emit(hdr.int_egress_port_tx_util);
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
