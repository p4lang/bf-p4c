/* -*- P4_16 -*- */
/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <t2na.p4>

/** Ethernet **/
typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;

const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;

header ethernet_h {
    mac_addr_t dst_addr; /*> Destination MAC address */
    mac_addr_t src_addr; /*> Source MAC address      */
    ether_type_t ether_type; /*> L3 Header type          */
}

/** IPv4 **/
typedef bit<32> ipv4_addr_t;

enum bit<8> ip_protocol_t {
    TCP = 6,
    UDP = 17
}

header ipv4_h {
    bit<8> v_hl; /*> Version / Header Length */
    bit<8> tos; /*> Type of Service         */
    bit<16> len; /*> Total Length            */
    bit<16> id; /*> Identification          */
    bit<3> flags; /*> IPv4 Flags              */
    bit<13> offset; /*> Fragment Offset         */
    bit<8> ttl; /*> Time-to-live            */
    ip_protocol_t proto; /*> L4 Header type          */
    bit<16> checksum; /*> Header Checksum         */
    ipv4_addr_t src; /*> Source IP address       */
    ipv4_addr_t dst; /*> Destination IP address  */
}

/** UDP **/
typedef bit<16> udp_port_t;

header udp_h {
    udp_port_t src_port; /*> UDP source port         */
    udp_port_t dst_port; /*> UDP destination port    */
    bit<16> len; /*> Packet length           */
    bit<16> checksum; /*> Checksum                */
}

/** TCP **/
typedef bit<16> tcp_port_t;
header tcp_h {
    tcp_port_t src_port; /*> TCP source port         */
    tcp_port_t dst_port; /*> TCP destination port    */
    bit<32> seq_no; /*> Sequence number         */
    bit<32> ack_no; /*> Acknowledgment number   */
    bit<4> off; /*> Data offset             */
    bit<3> rsvd; /*> Reserved                */
    bit<9> flags; /*> TCP flags               */
    bit<16> window; /*> Window size             */
    bit<16> checksum; /*> Checksum                */
    bit<16> urp; /*> Urgent pointer          */
}

/** IB/RoCEv2 specific types **/
typedef bit<128> roce_gid_t;
typedef bit<24> roce_qp_t;
typedef bit<24> roce_seqn_t;

enum bit<8> roce_opcode_t {
    RC_SEND_FIRST = 8w0b00000000,
    RC_SEND_MIDDLE = 8w0b00000001,
    RC_SEND_LAST = 8w0b00000010,
    RC_SEND_LAST_IMMEDIATE = 8w0b00000011,
    RC_SEND_ONLY = 8w0b00000100,
    RC_SEND_ONLY_IMMEDIATE = 8w0b00000101,
    RC_RDMA_WRITE_FIRST = 8w0b00000110,
    RC_RDMA_WRITE_MIDDLE = 8w0b00000111,
    RC_RDMA_WRITE_LAST = 8w0b00001000,
    RC_RDMA_WRITE_LAST_IMMEDIATE = 8w0b00001001,
    RC_RDMA_WRITE_ONLY = 8w0b00001010,
    RC_RDMA_WRITE_ONLY_IMMEDIATE = 8w0b00001011,
    RC_RDMA_READ_REQ = 8w0b00001100,
    RC_RDMA_READ_RESP_FIRST = 8w0b00001101,
    RC_RDMA_READ_RESP_MIDDLE = 8w0b00001110,
    RC_RDMA_READ_RESP_LAST = 8w0b00001111,
    RC_RDMA_READ_ONLY = 8w0b00010000,
    RC_ACKNOWLEDGE = 8w0b00010001,

    UC_SEND_FIRST = 8w0b00100000,
    UC_SEND_MIDDLE = 8w0b00100001,
    UC_SEND_LAST = 8w0b00100010,
    UC_SEND_LAST_IMMEDIATE = 8w0b00100011,
    UC_SEND_ONLY = 8w0b00100100,
    UC_SEND_ONLY_IMMEDIATE = 8w0b00100101,
    UC_RDMA_WRITE_FIRST = 8w0b00100110,
    UC_RDMA_WRITE_MIDDLE = 8w0b00100111,
    UC_RDMA_WRITE_LAST = 8w0b00101000,
    UC_RDMA_WRITE_LAST_IMMEDIATE = 8w0b00101001,
    UC_RDMA_WRITE_ONLY = 8w0b00101010,
    UC_RDMA_WRITE_ONLY_IMMEDIATE = 8w0b00101011
}

/* RoCEv2 Base Transport Header */
header roce_bth_h {
    roce_opcode_t opcode; /*> OpCode                  */
    bit<1> se; /*> Solicited Event         */
    bit<1> m; /*> Migration state         */
    bit<2> pad_cnt; /*> Pad Count               */
    bit<4> tver; /*> Transport Hdr Ver       */
    bit<16> p_key; /*> Partition Key           */
    bit<1> f_resv; /*> Forward ECN             */
    bit<1> b_resv; /*> Backward ECN            */
    bit<6> reserved; /*> Reserved                */
    roce_qp_t dest_qp; /*> Destination Queue Pair  */
    bit<1> ack_req; /*> Acknowledge Request     */
    bit<7> reserved2; /*> Reserved                */
    roce_seqn_t psn; /*> Packet Sequence Number  */
}

/* RoCEv2 RDMA Extended Transport Header */
header roce_reth_h {
    bit<40> vaddr_prefix; /*> Virtual address prefix (per connection) */
    bit<24> vaddr_offset; /*> Virtual address payload offset */
    bit<32> r_key; /*> Remote memory region key */
    bit<32> len; /*> Op length                */
}

/* RoCEv2 RDMA Immediate Header */
header roce_imm_h {
    bit<8> flow; /*> Flow identifier          */
    bit<24> update; /*> Buffer update            */
}

/* RoCEv2 ACK Extended Transport Header */
header roce_aeth_h {
    bit<8> syndrome; /*> ACK/NACK                 */
    roce_seqn_t msn; /*> Message Sequence Number  */
}

/* Abstract RoCE header (udp+bth+reth+imm) */
header roce_h {
    bit<64> _udp; /*> Unused                   */
    bit<72> _bth; /*> Unused                   */
    roce_seqn_t psn; /*> Packet Sequence Number   */
    bit<128> _reth; /*> Unused                   */
    bit<8> _imm; /*> Unused                   */
    bit<24> update; /*> Buffer update            */
}


typedef bit<24> flowid_t;
typedef bit<16> appctxid_t;

header switchtoe_bridge_h {
    /* Common type info */
    bit<8> phase;

    flowid_t f_id;
    appctxid_t ctx_id;

    /* TCP summary */
    bit<32> seq;
    bit<32> ack;
    bit<16> window;
    bit<32> payload_len;
}

header switchtoe_mirror_h {
    /* Common type info */
    bit<8> phase;

    flowid_t f_id;

    bit<32> ticket;
    bit<32> rx_next_seq_delta;
    bit<32> rx_ooo_off_delta;
    bit<32> rx_ooo_len_delta;

    // bit<8>      condition;
    // bit<32>     update;
}

struct ingress_hdr_t {
    switchtoe_bridge_h internal;
    ethernet_h eth;
    ipv4_h ip;
    tcp_h tcp;
    udp_h udp;
    roce_bth_h rdma_bth;
    roce_reth_h rdma_reth;
    roce_imm_h rdma_imm;
}

struct ingress_metadata_t {
    bit<1> tcp_ctrlflags;
    bit<40> buf_addr_prefix;
    bit<8> appctx_f_id;
}


struct tcprx_snapshot {
    bit<32> ticket;

    bit<32> rx_avail;
    bit<32> rx_next_seq;
    bit<32> rx_ooo_off;
    bit<32> rx_ooo_len;
}

struct tcprx_precompute {
    bit<32> rx_ooo_end;
    bit<32> rx_ooo_off_plen_cmp;
    bit<32> rx_avail_seq_endoff_cmp;

    bit<32> pkt_seq_off;
    bit<32> pkt_seq_end_off;
}

struct egress_hdr_t {
    ethernet_h eth;
    ipv4_h ip;
    roce_h rdma;
}

struct egress_metadata_t {
    switchtoe_bridge_h internal_bridge;
    switchtoe_mirror_h internal_mirror;

    tcprx_snapshot state;
    tcprx_precompute precompute;

    bit<8> condition;
    bit<32> update;

    bit<32> rx_next_seq_delta;
    bit<32> rx_ooo_off_delta;
    bit<32> rx_ooo_len_delta;

    MirrorId_t session_id;
    appctxid_t ctx_id;
}

parser TcpIngressParser(
    packet_in pkt,
    out ingress_hdr_t hdr,
    out ingress_metadata_t meta,
    out ingress_intrinsic_metadata_t intr_meta)
{
    state start {
        pkt.extract(intr_meta); /*> Required by Tofino Architecture */

        transition parse_port_metadata;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_eth;
    }

    state parse_eth {
        pkt.extract(hdr.eth);

        transition select(hdr.eth.ether_type) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ip);

        transition select(hdr.ip.proto) {
            ip_protocol_t.TCP: parse_tcp;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);

        transition select(hdr.tcp.flags) {
            9w0x1FF &&& (9w1 << 0): parse_tcp_ctrlflags;
            9w0x1FF &&& (9w1 << 1): parse_tcp_ctrlflags;
            9w0x1FF &&& (9w1 << 2): parse_tcp_ctrlflags;
            default: parse_tcp_dataflags;
        }
    }

    state parse_tcp_ctrlflags {
        meta.tcp_ctrlflags = 1;
        transition accept;
    }

    state parse_tcp_dataflags {
        meta.tcp_ctrlflags = 0;
        transition accept;
    }
}

control TcpIngressDeparser(
    packet_out pkt,
    inout ingress_hdr_t hdr,
    in ingress_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t intr_deparser_meta)
{
    Checksum() ipv4_checksum;

    apply {
        hdr.ip.checksum = ipv4_checksum.update({
            hdr.ip.v_hl,
            hdr.ip.tos,
            hdr.ip.len,
            hdr.ip.id,
            hdr.ip.flags,
            hdr.ip.offset,
            hdr.ip.ttl,
            hdr.ip.proto,
            hdr.ip.src,
            hdr.ip.dst
        });

        pkt.emit(hdr);
    }
}

parser TcpEgressParser(
    packet_in pkt,
    out egress_hdr_t hdr,
    out egress_metadata_t meta,
    out egress_intrinsic_metadata_t intr_meta)
{
    state start {
        pkt.extract(intr_meta);
        transition parse_internal;
    }

    state parse_internal {
        bit<8> phase = pkt.lookahead<bit<8>>();

        transition select(phase) {
            0: parse_bridge;
            1: parse_mirror;
            _: reject;
        }
    }

    state parse_bridge {
        pkt.extract(meta.internal_bridge);
        transition parse_eth;
    }

    state parse_mirror {
        pkt.extract(meta.internal_mirror);
        transition parse_eth;
    }

    state parse_eth {
        pkt.extract(hdr.eth);
        transition parse_ipv4;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ip);
        transition parse_rdma;
    }

    state parse_rdma {
        pkt.extract(hdr.rdma);
        transition accept;
    }
}

control TcpEgressDeparser(
    packet_out pkt,
    inout egress_hdr_t hdr,
    in egress_metadata_t meta,
    in egress_intrinsic_metadata_for_deparser_t intr_deparser_meta)
{
    Mirror() mirror;

    apply {
        if (intr_deparser_meta.mirror_type == 1) {
            mirror.emit<switchtoe_mirror_h>(meta.session_id, meta.internal_mirror);
        }
        pkt.emit(hdr);
    }
}

control Routing(
    inout ingress_hdr_t hdr,
    inout ingress_metadata_t meta,
    in ingress_intrinsic_metadata_t intr_meta,
    inout ingress_intrinsic_metadata_for_deparser_t intr_deparser_meta,
    inout ingress_intrinsic_metadata_for_tm_t intr_tm_meta)
{
    action drop() {
        intr_deparser_meta.drop_ctl = 1;
    }

    /** L3 (IPv4) ROUTING **/
    action forward_ipv4(PortId_t port, mac_addr_t dst_mac) {
        intr_tm_meta.ucast_egress_port = port;

        hdr.eth.dst_addr = dst_mac;
        hdr.ip.ttl = hdr.ip.ttl |-| 8w1;
    }

    table ipv4_route {
        key = {
            hdr.ip.dst : lpm;
        }

        actions = {
            forward_ipv4;
            drop;
        }

        size = (12 * 1024);
    }

    /** SOURCE MAC REWRITE **/
    action set_port_addr(mac_addr_t mac) {
        hdr.eth.src_addr = mac;
    }

    table port_lookup {
        key = {
            intr_tm_meta.ucast_egress_port : exact;
        }

        actions = {
            set_port_addr;
        }

        size = 256;
    }

    /** L2 (ETH) SWITCHING **/
    action forward_eth(PortId_t port) {
        intr_tm_meta.ucast_egress_port = port;
    }

    action flood_eth(MulticastGroupId_t mgid) {
        intr_tm_meta.mcast_grp_a = mgid;

        /*> We use 0x8000 + dev_port as the RID and XID */
        intr_tm_meta.level1_exclusion_id = 7w0b1000000 ++ intr_meta.ingress_port;
    }

    table eth_switch {
        key = {
            hdr.eth.dst_addr : exact;
        }

        actions = {
            forward_eth;
            flood_eth;
            drop;
        }

        default_action = drop;

        size = 1024;
    }

    apply {
        if (hdr.ip.isValid()) {
            if (ipv4_route.apply().hit) {
                port_lookup.apply();
                return;
            }
        }

        eth_switch.apply();
    }
}



control RdmaUcWrite(
    inout ingress_hdr_t hdr,
    inout ingress_metadata_t meta)
{
    action prepare_rdma_hdrs(ipv4_addr_t src_ip, roce_qp_t qp, bit<32> remote_key) {
        hdr.ip.tos = 0;
        hdr.ip.len = (bit<16>) (hdr.internal.payload_len
                        + hdr.ip.minSizeInBytes()
                        + hdr.udp.minSizeInBytes()
                        + hdr.rdma_bth.minSizeInBytes()
                        + hdr.rdma_reth.minSizeInBytes()
                        + hdr.rdma_imm.minSizeInBytes()
                        + 4);
        hdr.ip.id = 0x0001;
        hdr.ip.flags = 0b010;
        hdr.ip.offset = 0;
        hdr.ip.ttl = 64;
        hdr.ip.proto = ip_protocol_t.UDP;
        hdr.ip.src = src_ip;

        hdr.udp.setValid();
        hdr.udp.src_port = hdr.internal.ctx_id;
        hdr.udp.dst_port = 16w4791;
        hdr.udp.len = (bit<16>) (hdr.internal.payload_len
                        + hdr.udp.minSizeInBytes()
                        + hdr.rdma_bth.minSizeInBytes()
                        + hdr.rdma_reth.minSizeInBytes()
                        + hdr.rdma_imm.minSizeInBytes()
                        + 4);
        hdr.udp.checksum = 0;

        hdr.rdma_bth.setValid();
        hdr.rdma_bth.opcode = roce_opcode_t.UC_RDMA_WRITE_ONLY_IMMEDIATE;
        hdr.rdma_bth.se = 0;
        hdr.rdma_bth.m = 1;
        hdr.rdma_bth.pad_cnt = 0;
        hdr.rdma_bth.tver = 0;
        hdr.rdma_bth.p_key = 0xFFFF;
        hdr.rdma_bth.f_resv = 0;
        hdr.rdma_bth.b_resv = 0;
        hdr.rdma_bth.reserved = 0;
        hdr.rdma_bth.dest_qp = qp;
        hdr.rdma_bth.ack_req = 0;
        hdr.rdma_bth.reserved2 = 0;
        hdr.rdma_bth.psn = 0; /*> patched later in egress */

        hdr.rdma_reth.setValid();
        hdr.rdma_reth.vaddr_prefix = meta.buf_addr_prefix;
        hdr.rdma_reth.vaddr_offset = hdr.internal.seq[23:0];
        hdr.rdma_reth.r_key = remote_key;
        hdr.rdma_reth.len = hdr.internal.payload_len;

        hdr.rdma_imm.setValid();
        hdr.rdma_imm.flow = meta.appctx_f_id;
        hdr.rdma_imm.update = 0;
    }

    table appctx_lookup {
        key = {
            hdr.internal.ctx_id : exact;
        }

        actions = {
            prepare_rdma_hdrs;
        }

        size = 1024;
    }

    apply {
        appctx_lookup.apply();
    }
}

control RdmaUcWritePatch(
    inout egress_hdr_t hdr,
    inout egress_metadata_t meta)
{
    Register<bit<32>, bit<16>> (1024) reg_rdma_qp_psn;

    RegisterAction<bit<32>, bit<16>, bit<32>> (reg_rdma_qp_psn)
    assign_rdma_psn = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            bit<32> in_value = register_data;

            result = in_value;
            register_data = in_value + 1;
        }
    };

    apply {
        hdr.rdma.psn = (bit<24>) assign_rdma_psn.execute(meta.ctx_id);
        hdr.rdma.update = meta.rx_next_seq_delta[23:0];
    }
}

control TcpIngress(
    inout ingress_hdr_t hdr,
    inout ingress_metadata_t meta,
    in ingress_intrinsic_metadata_t intr_meta,
    in ingress_intrinsic_metadata_from_parser_t intr_parser_meta,
    inout ingress_intrinsic_metadata_for_deparser_t intr_deparser_meta,
    inout ingress_intrinsic_metadata_for_tm_t intr_tm_meta)
{
    Routing() routing;
    RdmaUcWrite() rdma_write;

    /** UTILITIES **/
    action bypass_egress(bit<1> bypass) {
        intr_tm_meta.bypass_egress = bypass;
    }

    action forward_to_cpu() {
        intr_tm_meta.ucast_egress_port = 64;
    }

    /** FLOW LOOKUP **/
    action set_flow_meta(flowid_t f_id, appctxid_t ctx_id, bit<40> buf_addr_prefix, bit<8> appctx_f_id, bit<32> local_seq_neg, bit<32> remote_seq_neg) {
        hdr.internal.setValid();

        hdr.internal.phase = 0;
        hdr.internal.f_id = f_id;
        hdr.internal.ctx_id = ctx_id;

        meta.buf_addr_prefix = buf_addr_prefix;
        meta.appctx_f_id = appctx_f_id;

        hdr.tcp.seq_no = hdr.tcp.seq_no + remote_seq_neg;
        hdr.tcp.ack_no = hdr.tcp.ack_no + local_seq_neg;
    }

    table flow_lookup {
        key = {
            hdr.ip.src : exact;
            hdr.ip.dst : exact;
            hdr.tcp.src_port : exact;
            hdr.tcp.dst_port : exact;
        }

        actions = {
            set_flow_meta;
        }

        size = 0x3FFF;
    }

    /** Strip header **/
    action summarize_tcp() {
        hdr.internal.seq = hdr.tcp.seq_no;
        hdr.internal.ack = hdr.tcp.ack_no;
        hdr.internal.window = hdr.tcp.window;
        hdr.internal.payload_len = (bit<32>) (hdr.ip.len |-| (hdr.ip.minSizeInBytes() + hdr.tcp.minSizeInBytes()));
        hdr.tcp.setInvalid();
    }

    apply {

        bypass_egress(1);

        if (hdr.tcp.isValid()) {
            if (flow_lookup.apply().hit) {
                /* Filter datapath only packets */
                if (meta.tcp_ctrlflags == 1) {
                    hdr.internal.setInvalid();
                    forward_to_cpu();
                    return;
                }

                bypass_egress(0);

                summarize_tcp();
                rdma_write.apply(hdr, meta);
            }
        }

        routing.apply(hdr, meta, intr_meta, intr_deparser_meta, intr_tm_meta);
    }
}


struct tlock_32bit {
    bit<32> ticket; /*> Ticket lock     */
    bit<32> value; /*> Stateful value  */
}
control TcpReassemblyPrecompute(
    inout egress_hdr_t hdr,
    inout egress_metadata_t meta)
{
    action step1() {
        meta.precompute.rx_ooo_end = meta.state.rx_ooo_off + meta.state.rx_ooo_len;
        meta.precompute.rx_ooo_off_plen_cmp = meta.state.rx_ooo_off |-| meta.internal_bridge.payload_len;
        meta.precompute.pkt_seq_off = meta.internal_bridge.seq - meta.state.rx_next_seq;
    }

    action step2() {
        meta.precompute.pkt_seq_end_off = meta.precompute.pkt_seq_off + meta.internal_bridge.payload_len;
    }

    action step3() {
        meta.precompute.rx_avail_seq_endoff_cmp = meta.state.rx_avail |-| meta.precompute.pkt_seq_end_off;
    }

    apply {
        step1();
        step2();
        step3();
    }
}

enum bit<8> tcp_reassembly_cond {
    REASSEMBLY_CASE0 = 8w0, /* DROP */
    REASSEMBLY_CASE1 = 8w1,
    REASSEMBLY_CASE2 = 8w2,
    REASSEMBLY_CASE3 = 8w3,
    REASSEMBLY_CASE4 = 8w4,
    REASSEMBLY_CASE5 = 8w5
}

control TcpReassembly(
    inout egress_hdr_t hdr,
    inout egress_metadata_t meta)
{
    // Need case, update0, update1
    action compute_update_case0() {
        meta.condition = tcp_reassembly_cond.REASSEMBLY_CASE0;
        meta.update = 0;
        // meta.rx_next_seq_delta = 0;

        // hdr.internal.base.rx_next_seq_delta = 0;
        // hdr.internal.base.rx_ooo_off_delta = 0;
        // hdr.internal.base.rx_ooo_len_delta = 0;
    }

    action compute_update_case1() {
        meta.condition = tcp_reassembly_cond.REASSEMBLY_CASE1;
        meta.update = 0;
        // meta.rx_next_seq_delta = meta.payload_len;

        // hdr.internal.base.rx_next_seq_delta = meta.payload_len;
        // hdr.internal.base.rx_ooo_off_delta = -meta.payload_len;
        // hdr.internal.base.rx_ooo_len_delta = 0;
    }

    action compute_update_case2() {
        meta.condition = tcp_reassembly_cond.REASSEMBLY_CASE2;
        meta.update = meta.precompute.rx_ooo_end;
        // meta.rx_next_seq_delta = meta.precompute.rx_ooo_end;

        // hdr.internal.base.rx_next_seq_delta = meta.precompute.rx_ooo_end;
        // hdr.internal.base.rx_ooo_off_delta = -meta.state.rx_ooo_off;
        // hdr.internal.base.rx_ooo_len_delta = -meta.state.rx_ooo_len;
    }

    action compute_update_case3() {
        meta.condition = tcp_reassembly_cond.REASSEMBLY_CASE3;
        meta.update = meta.precompute.pkt_seq_off;
        // meta.rx_next_seq_delta = 0;

        // hdr.internal.base.rx_next_seq_delta = 0;
        // hdr.internal.base.rx_ooo_off_delta = meta.precompute.pkt_seq_off;
        // hdr.internal.base.rx_ooo_len_delta = meta.payload_len;
    }

    action compute_update_case4() {
        meta.condition = tcp_reassembly_cond.REASSEMBLY_CASE4;
        meta.update = 0;
        // meta.rx_next_seq_delta = 0;

        // hdr.internal.base.rx_next_seq_delta = 0;
        // hdr.internal.base.rx_ooo_off_delta = 0;
        // hdr.internal.base.rx_ooo_len_delta = meta.payload_len;
    }

    action compute_update_case5() {
        meta.condition = tcp_reassembly_cond.REASSEMBLY_CASE5;
        meta.update = 0;
        // meta.rx_next_seq_delta = 0;

        // hdr.internal.base.rx_next_seq_delta = 0;
        // hdr.internal.base.rx_ooo_off_delta = -meta.payload_len;
        // hdr.internal.base.rx_ooo_len_delta = meta.payload_len;
    }

    apply {
        if (meta.precompute.rx_avail_seq_endoff_cmp == 0) {
            compute_update_case0();
        }
        else if (meta.precompute.pkt_seq_off == 0) {
            if (meta.state.rx_ooo_len != 0 && meta.precompute.rx_ooo_off_plen_cmp == 0) {
                compute_update_case2();
            }
            else {
                compute_update_case1();
            }
        }
        else if (meta.state.rx_ooo_len == 0) {
            compute_update_case3();
        }
        else if (meta.precompute.rx_ooo_end == meta.precompute.pkt_seq_off) {
            compute_update_case4();
        }
        else if (meta.precompute.pkt_seq_end_off == meta.state.rx_ooo_off) {
            compute_update_case5();
        }
        else {
            compute_update_case0();
        }
    }
}

control TcpReassemblyPostcompute(
    inout egress_hdr_t hdr,
    inout egress_metadata_t meta)
{
    action compute_update_case0() {
        meta.rx_next_seq_delta = 0;
        meta.rx_ooo_off_delta = 0;
        meta.rx_ooo_len_delta = 0;
    }

    action compute_update_case1() {
        meta.rx_next_seq_delta = meta.internal_bridge.payload_len;
        meta.rx_ooo_off_delta = -meta.internal_bridge.payload_len;
        meta.rx_ooo_len_delta = 0;
    }

    action compute_update_case2() {
        meta.rx_next_seq_delta = meta.update;
        meta.rx_ooo_off_delta = -meta.state.rx_ooo_off;
        meta.rx_ooo_len_delta = -meta.state.rx_ooo_len;
    }

    action compute_update_case3() {
        meta.rx_next_seq_delta = 0;
        meta.rx_ooo_off_delta = meta.update;
        meta.rx_ooo_len_delta = meta.internal_bridge.payload_len;
    }

    action compute_update_case4() {
        meta.rx_next_seq_delta = 0;
        meta.rx_ooo_off_delta = 0;
        meta.rx_ooo_len_delta = meta.internal_bridge.payload_len;
    }

    action compute_update_case5() {
        meta.rx_next_seq_delta = 0;
        meta.rx_ooo_off_delta = -meta.internal_bridge.payload_len;
        meta.rx_ooo_len_delta = meta.internal_bridge.payload_len;
    }

    table tcp_reassembly_compute {
        key = {
            meta.condition : exact;
        }

        actions = {
            compute_update_case0;
            compute_update_case1;
            compute_update_case2;
            compute_update_case3;
            compute_update_case4;
            compute_update_case5;
        }

        default_action = compute_update_case0;

        const entries = {
            (tcp_reassembly_cond.REASSEMBLY_CASE0) : compute_update_case0();
            (tcp_reassembly_cond.REASSEMBLY_CASE1) : compute_update_case1();
            (tcp_reassembly_cond.REASSEMBLY_CASE2) : compute_update_case2();
            (tcp_reassembly_cond.REASSEMBLY_CASE3) : compute_update_case3();
            (tcp_reassembly_cond.REASSEMBLY_CASE4) : compute_update_case4();
            (tcp_reassembly_cond.REASSEMBLY_CASE5) : compute_update_case5();
        }

        size = 6;
    }

    apply {
        tcp_reassembly_compute.apply();
    }
}

control TcpAckPrepare(
    inout egress_hdr_t hdr,
    inout egress_metadata_t meta)
{

    apply {

    }
}

control TcpEgress(
    inout egress_hdr_t hdr,
    inout egress_metadata_t meta,
    in egress_intrinsic_metadata_t intr_meta,
    in egress_intrinsic_metadata_from_parser_t intr_parser_meta,
    inout egress_intrinsic_metadata_for_deparser_t intr_deparser_meta,
    inout egress_intrinsic_metadata_for_output_port_t intr_oport_meta)
{
    /** TCP state **/
    Register<bit<32>, bit<24>> (0x3FFF) reg_flow_rx_ticket;
    Register<bit<32>, bit<24>> (0x3FFF) reg_flow_rx_next_seq;
    Register<bit<32>, bit<24>> (0x3FFF) reg_flow_rx_ooo_off;
    Register<bit<32>, bit<24>> (0x3FFF) reg_flow_rx_ooo_len;
    Register<bit<32>, bit<24>> (0x3FFF) reg_flow_rx_avail;

    /* TCP state ops */
    /* Snapshot Actions */
    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_ticket)
    acquire_ticket = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + 1;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_next_seq)
    snapshot_rx_next_seq = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            result = register_data;
        }
    };

    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_ooo_off)
    snapshot_rx_ooo_off = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            result = register_data;
        }
    };

    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_ooo_len)
    snapshot_rx_ooo_len = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            result = register_data;
        }
    };

    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_avail)
    snapshot_rx_avail = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            result = register_data;
        }
    };

    /** Commit actions **/
    RegisterAction<bit<32>, bit<24>, bit<1>> (reg_flow_rx_ticket)
    validate_ticket = {
        void apply(inout bit<32> register_data, out bit<1> result) {
            if (register_data == meta.internal_mirror.ticket) {
                result = 1;
            }
            else {
                result = 0;
            }
        }
    };

    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_next_seq)
    inc_rx_next_seq = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            bit<32> in_value = register_data;
            register_data = in_value + meta.internal_mirror.rx_next_seq_delta;
            result = register_data;
        }
    };

    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_ooo_off)
    inc_rx_ooo_off = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            bit<32> in_value = register_data;
            register_data = in_value + meta.internal_mirror.rx_ooo_off_delta;
            result = register_data;
        }
    };

    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_ooo_len)
    inc_rx_ooo_len = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            bit<32> in_value = register_data;
            register_data = in_value + meta.internal_mirror.rx_ooo_len_delta;
            result = register_data;
        }
    };

    RegisterAction<bit<32>, bit<24>, bit<32>> (reg_flow_rx_avail)
    dec_rx_avail = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            bit<32> in_value = register_data;
            register_data = in_value - meta.internal_mirror.rx_next_seq_delta;
            result = register_data;
        }
    };

    action prepare_mirror_hdr(MirrorId_t session_id) {
        meta.session_id = session_id;
        meta.ctx_id = meta.internal_bridge.ctx_id;
        intr_deparser_meta.mirror_type = 1; /*> Enable mirroring */
        intr_deparser_meta.mirror_io_select = 1; /*> Mirror egress packet */

        meta.internal_mirror.setValid();
        meta.internal_mirror.phase = 1;
        meta.internal_mirror.f_id = meta.internal_bridge.f_id;
        meta.internal_mirror.ticket = meta.state.ticket;
        meta.internal_mirror.rx_next_seq_delta = meta.rx_next_seq_delta;
        meta.internal_mirror.rx_ooo_off_delta = meta.rx_ooo_off_delta;
        meta.internal_mirror.rx_ooo_len_delta = meta.rx_ooo_len_delta;

        meta.internal_bridge.setInvalid();
    }

    table flow_mirror_lookup {
        key = {
            meta.internal_bridge.f_id : exact;
        }

        actions = {
            prepare_mirror_hdr;
        }

        size = 0x3FFF;
    }

    // TcpState() tcp_state;
    TcpReassemblyPrecompute() tcp_precompute;
    TcpReassembly() tcp_reassembly;
    TcpReassemblyPostcompute() tcp_postcompute;
    RdmaUcWritePatch() rdma_patch;

    apply {
        if (meta.internal_bridge.isValid()) {
            /* Phase 1: Snapshot */
            meta.state.ticket = acquire_ticket.execute(meta.internal_bridge.f_id);
            meta.state.rx_next_seq = snapshot_rx_next_seq.execute(meta.internal_bridge.f_id);
            meta.state.rx_ooo_off = snapshot_rx_ooo_off.execute(meta.internal_bridge.f_id);
            meta.state.rx_ooo_len = snapshot_rx_ooo_len.execute(meta.internal_bridge.f_id);
            meta.state.rx_avail = snapshot_rx_avail.execute(meta.internal_bridge.f_id);

            tcp_precompute.apply(hdr, meta);
            tcp_reassembly.apply(hdr, meta);
            tcp_postcompute.apply(hdr, meta);

            flow_mirror_lookup.apply();
            rdma_patch.apply(hdr, meta);
        }
        else if (meta.internal_mirror.isValid()) {
            /* Phase 2: Commit */
            bit<1> isSeq = validate_ticket.execute(meta.internal_mirror.f_id);
            if (isSeq == 1w1) {
                meta.state.rx_next_seq = inc_rx_next_seq.execute(meta.internal_mirror.f_id);
                inc_rx_ooo_off.execute(meta.internal_mirror.f_id);
                inc_rx_ooo_len.execute(meta.internal_mirror.f_id);
                meta.state.rx_avail = dec_rx_avail.execute(meta.internal_mirror.f_id);
            }

            intr_deparser_meta.mirror_type = 0; /*> Disable mirroring */
            hdr.rdma.setInvalid();

            /* TODO: Prepare TCP ack header */
        }
    }
}

Pipeline(
    TcpIngressParser(),
    TcpIngress(),
    TcpIngressDeparser(),
    TcpEgressParser(),
    TcpEgress(),
    TcpEgressDeparser()
) pipe;

Switch(pipe) main;
