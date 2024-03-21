/*
 * Copyright 2017-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "tna.p4"

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
//typedef bit<12>  vlan_id_t;

const ipv4_addr_t DNS_SERVER = 0x08080808;

typedef bit<16> ether_type_t;
const ether_type_t ETH_TYPE_IPV4 = 16w0x0800;
const ether_type_t ETH_TYPE_ARP = 16w0x0806;
const ether_type_t ETH_TYPE_IPV6 = 16w0x86dd;
const ether_type_t ETH_TYPE_VLAN = 16w0x8100;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTO_ICMP = 1;
const ip_protocol_t IP_PROTO_TCP = 6;
const ip_protocol_t IP_PROTO_UDP = 17;

const bit<8> DEFAULT_IPV4_TTL = 64;
const bit<4> IPV4_MIN_IHL = 5;

/* SPGW */






typedef bit<2> direction_t;
const direction_t SPGW_DIR_UNKNOWN = 0;
const direction_t SPGW_DIR_UPLINK = 1;
const direction_t SPGW_DIR_DOWNLINK = 2;

/*
@controller_header("packet_in")
header packet_in_header_t {
    bit<9> ingress_port;
    bit<7> _padding;
}

_PKT_OUT_HDR_ANNOT_
@controller_header("packet_out")
header packet_out_header_t {
    bit<9> egress_port;
    bit<7> _padding;
}
*/

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<3> res;
    bit<3> ecn;
    bit<6> ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
    bit<16> checksum;
}

header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}

header icmp_h {
    bit<8> icmp_type;
    bit<8> icmp_code;
    bit<16> checksum;
    bit<16> identifier;
    bit<16> sequence_number;
    bit<64> timestamp;
}

// GTP-U v1
header gtpu_h {
    bit<3> version;
    bit<1> pt;
    bit<1> spare;
    bit<1> ex_flag;
    bit<1> seq_flag;
    bit<1> npdu_flag;
    bit<8> msgtype;
    bit<16> msglen;
    bit<32> teid;
}

header bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress
    bool do_spgw;
    bit<7> _pad;
    direction_t direction;
    bit<6> _pad2;
    bit<16> ipv4_len;
    bit<32> teid;
    bit<32> s1u_enb_addr;
    bit<32> s1u_sgw_addr;
}

struct headers_t {
    bridged_metadata_t bridged_md;
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    udp_h udp;
    gtpu_h gtpu;
    ipv4_h inner_ipv4;
    udp_h inner_udp;
}


struct spgw_meta_t {
    bool do_spgw;
    direction_t direction; //2
    bit<16> ipv4_len;
    bit<32> teid;
    bit<32> s1u_enb_addr;
    bit<32> s1u_sgw_addr;
}

struct local_metadata_t {
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    spgw_meta_t spgw;
}

/* Tofino-defined header and metadata */
parser TofinoIngressParser(
        packet_in packet,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        packet.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1: parse_resubmit;
            0: parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Not implemented
        transition reject;
    }

    state parse_port_metadata {



        packet.advance(64);

        transition accept;
    }

}

parser TofinoEgressParser(
        packet_in packet,
        out egress_intrinsic_metadata_t eg_intr_md ) {

    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

/* Parser defined by ourself */
parser SwitchIngressParser(
        packet_in packet,
        out headers_t hdr,
        out local_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(packet, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
//            ETH_TYPE_ARP:  parse_arp;
            ETH_TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

//    state parse_arp {
//        packet.extract(hdr.arp);
//        transition accept;
//    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTO_TCP: parse_tcp;
            IP_PROTO_UDP: parse_udp;
            //IP_PROTO_ICMP: parse_icmp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        ig_md.l4_src_port = hdr.tcp.src_port;
        ig_md.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
        ig_md.l4_src_port = hdr.udp.src_port;
        ig_md.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.udp.dst_port) {
            2152: parse_gtpu;
            default: accept;
        }
    }

    state parse_gtpu {
        packet.extract(hdr.gtpu);
        transition parse_gtpu_inner_ipv4;
    }

    state parse_gtpu_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTO_UDP: parse_gtpu_inner_udp;
            default: accept;
        }
    }

    state parse_gtpu_inner_udp {
        packet.extract(hdr.inner_udp);
        transition accept;
    }
}

control SwitchIngressDeparser(
        packet_out packet,
        inout headers_t hdr,
        in local_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Checksum() ipv4_checksum;

    apply {
        /* Count IPv4 checksum here */
        hdr.ipv4.hdr_checksum = ipv4_checksum.update(
                {hdr.ipv4.version,
                 hdr.ipv4.ihl,
                 hdr.ipv4.dscp,
                 hdr.ipv4.ecn,
                 hdr.ipv4.len,
                 hdr.ipv4.identification,
                 hdr.ipv4.flags,
                 hdr.ipv4.frag_offset,
                 hdr.ipv4.ttl,
                 hdr.ipv4.protocol,
                 hdr.ipv4.src_addr,
                 hdr.ipv4.dst_addr});

        packet.emit(hdr.bridged_md); // Tofino arch.
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.gtpu);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_udp);
    }

}

parser SwitchEgressParser(
        packet_in packet,
        out headers_t hdr,
        out local_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(packet, eg_intr_md);
        transition parse_bridged_metadata;
    }

    state parse_bridged_metadata {
        packet.extract(hdr.bridged_md);
        eg_md.spgw.do_spgw = hdr.bridged_md.do_spgw;
        eg_md.spgw.direction = hdr.bridged_md.direction;
        eg_md.spgw.ipv4_len = hdr.bridged_md.ipv4_len;
        eg_md.spgw.s1u_enb_addr = hdr.bridged_md.s1u_enb_addr;
        eg_md.spgw.s1u_sgw_addr = hdr.bridged_md.s1u_sgw_addr;
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
//            ETH_TYPE_ARP:  parse_arp;
            ETH_TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

//    state parse_arp {
//        packet.extract(hdr.arp);
//        transition accept;
//    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTO_TCP: parse_tcp;
            IP_PROTO_UDP: parse_udp;
            //IP_PROTO_ICMP: parse_icmp;
            default: accept;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        eg_md.l4_src_port = hdr.tcp.src_port;
        eg_md.l4_dst_port = hdr.tcp.dst_port;
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
        eg_md.l4_src_port = hdr.udp.src_port;
        eg_md.l4_dst_port = hdr.udp.dst_port;
        transition select(hdr.udp.dst_port) {
            2152: parse_gtpu;
            default: accept;
        }
    }

    state parse_gtpu {
        packet.extract(hdr.gtpu);
        transition parse_gtpu_inner_ipv4;
    }

    state parse_gtpu_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            IP_PROTO_UDP: parse_gtpu_inner_udp;
            default: accept;
        }
    }

    state parse_gtpu_inner_udp {
        packet.extract(hdr.inner_udp);
        eg_md.l4_src_port = hdr.inner_udp.src_port;
        eg_md.l4_dst_port = hdr.inner_udp.dst_port;
        transition accept;
    }

}

control SwitchEgressDeparser(
        packet_out packet,
        inout headers_t hdr,
        in local_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    Checksum() ipv4_checksum;

    apply {
        /* Count IPv4 checksum here */
        hdr.ipv4.hdr_checksum = ipv4_checksum.update(
                {hdr.ipv4.version,
                 hdr.ipv4.ihl,
                 hdr.ipv4.dscp,
                 hdr.ipv4.ecn,
                 hdr.ipv4.len,
                 hdr.ipv4.identification,
                 hdr.ipv4.flags,
                 hdr.ipv4.frag_offset,
                 hdr.ipv4.ttl,
                 hdr.ipv4.protocol,
                 hdr.ipv4.src_addr,
                 hdr.ipv4.dst_addr});


        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.gtpu);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_udp);
    }

}

control PortCountersIngress(
        inout headers_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md) {

    Counter<bit<32>, PortId_t>(
        6, CounterType_t.PACKETS) ingress_port_counter;

    apply {
        ingress_port_counter.count(ig_intr_md.ingress_port);
    }
}

control PortCountersEgress(
        inout headers_t hdr,
        in egress_intrinsic_metadata_t eg_intr_md) {

    Counter<bit<32>, PortId_t>(
        6, CounterType_t.PACKETS) egress_port_counter;

    apply {
        egress_port_counter.count(eg_intr_md.egress_port);
    }
}

control Table0Control(
        inout headers_t hdr,
        inout local_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    //DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) table0_counter;

    action send_to_cpu() {
        ig_intr_tm_md.ucast_egress_port = 192;
    }

    action set_egress_port(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
        ig_intr_dprsr_md.drop_ctl = 0x0;
    }

    action miss_drop() {
        ig_intr_dprsr_md.drop_ctl = 0x1;
    }

    table table0 {
        key = {
            ig_intr_md.ingress_port : ternary;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.ethernet.ether_type : ternary;
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv4.protocol : ternary;
            ig_md.l4_src_port : ternary;
            ig_md.l4_dst_port : ternary;
        }

        actions = {
            set_egress_port;
            send_to_cpu;
            miss_drop;
        }

        size = 1024;
        const default_action = miss_drop;
        //counters = table0_counter;
    }

    apply {
        table0.apply();
     }
}

control SpgwIngress(
        inout headers_t hdr,
        inout spgw_meta_t spgw_meta,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    bit<32> tmp_teid = 32w0;

    Register<bit<32>, bit<32>>(32w65536) teid_table;
    RegisterAction<bit<32>, bit<32>, bit<32>>(teid_table) teid_record = {
        void apply(inout bit<32> teid) {
            teid = hdr.gtpu.teid;
        }
    };
    RegisterAction<bit<32>, bit<32>, bit<32>>(teid_table) teid_extract = {
        void apply(inout bit<32> teid, out bit<32> val) {
            val = teid;
        }
    };

    //Register<bit<32>, bit<32>>(table_size, 0) dns_server_table;
    //RegisterAction<bit<32>, bit<32>, bit<32>>(dns_server_table) dns_server_record = {
    //    void apply(inout bit<32> server_ip) {
    //        server_ip = hdr.inner_ipv4.dst_addr;
    //    }
    //};
    //RegisterAction<bit<32>, bit<32>, bit<32>>(dns_server_table) dns_server_extract = {
    //    void apply(inout bit<32> server_ip, out bit<32> val) {
    //        val = server_ip;
    //    }
    //};

    Hash<bit<32>>(HashAlgorithm_t.CRC32) ip_hash;
    Hash<bit<32>>(HashAlgorithm_t.CRC32) ip_hash2;

    action add_void_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.do_spgw = false;
        hdr.bridged_md.direction = SPGW_DIR_UNKNOWN;
        hdr.bridged_md.ipv4_len = 0;
        hdr.bridged_md.s1u_enb_addr = 0xffffffff;
        hdr.bridged_md.s1u_sgw_addr = 0xffffffff;
    }

    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.do_spgw = spgw_meta.do_spgw;
        hdr.bridged_md.direction = spgw_meta.direction;
        hdr.bridged_md.ipv4_len = spgw_meta.ipv4_len;
        hdr.bridged_md.s1u_enb_addr = spgw_meta.s1u_enb_addr;
        hdr.bridged_md.s1u_sgw_addr = spgw_meta.s1u_sgw_addr;
    }

    action gtpu_decap() {
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        hdr.gtpu.setInvalid();
    }

    action set_outer_header_info(ipv4_addr_t s1u_enb_addr,
                                 ipv4_addr_t s1u_sgw_addr) {
        spgw_meta.s1u_enb_addr = s1u_enb_addr;
        spgw_meta.s1u_sgw_addr = s1u_sgw_addr;

        bit<32> tmp = ip_hash.get({hdr.ipv4.dst_addr});
        tmp_teid = teid_extract.execute(tmp);
    }

    action set_teid_info() {
        spgw_meta.do_spgw = true;
        spgw_meta.teid = tmp_teid;

        //bit<32> tmp = ip_hash.get({hdr.ipv4.dst_addr});
        //target_server = dns_server_extract.execute(tmp);
    }

    action change_dns_server_back() {
        hdr.ipv4.src_addr = DNS_SERVER;
    }

    action miss_drop() {
        ig_intr_dprsr_md.drop_ctl = 0x1;
    }

    action record_teid_mapping() {
       bit<32> tmp = ip_hash2.get({hdr.inner_ipv4.dst_addr});
       teid_record.execute(tmp);
    }

    action set_egress_to_mec(PortId_t port){
       ig_intr_tm_md.ucast_egress_port = port;
       ig_intr_dprsr_md.drop_ctl = 0x0;
    }

    action set_dns_to_mec(PortId_t port, ipv4_addr_t mec_addr) {
       ig_intr_tm_md.ucast_egress_port = port;
       ig_intr_dprsr_md.drop_ctl = 0x0;

       // Change destination ip to mec ip
       hdr.inner_ipv4.dst_addr = mec_addr;

       //bit<32> tmp = ip_hash.get({hdr.inner_ipv4.src_addr});
       //dns_server_record.execute(tmp);
    }

    @stage(2)
    table dl_mec_sess_lookup {
        key = {
            // MEC addr for downlink
            hdr.ipv4.src_addr : exact;
        }
        actions = {
            set_outer_header_info;
            NoAction;
        }
        //counters = ue_counter;
    }

    /* Check inner packet if destination is  MEC */
    table s1u_ul_mec_sess_lookup {
        key = {
            hdr.ipv4.src_addr: exact;
            hdr.inner_ipv4.dst_addr : exact;
            hdr.inner_udp.dst_port : exact;
        }
        actions = {
            set_egress_to_mec;
            set_dns_to_mec;
            NoAction;
        }
    }

    @stage(2)
    table s1u_dl_sess_lookup {
        key = {
            hdr.ipv4.src_addr : exact; // Outer IP addr.
        }
        actions = {
            record_teid_mapping;
            NoAction;
        }
    }


    table ue_filter_table {
        key = {
            // IP prefixes of the UEs managed by this switch (when downlink)
            hdr.ipv4.dst_addr : lpm;
        }
        actions = {
            NoAction;
        }
    }

    apply {
        spgw_meta.do_spgw = false;
        if (hdr.gtpu.isValid()) { // Packet with encapsulation
            // Here if packets from registered eNB, to registered MEC
            if (s1u_ul_mec_sess_lookup.apply().hit) {
                // TODO: check also that gtpu.msgtype == GTP_GPDU
                // Move inner IP header to correct position and remove outer IP header
                spgw_meta.direction = SPGW_DIR_UPLINK;
                gtpu_decap();
            // Here if packets from registered SGW, record the downlink TEID
            } else {
                s1u_dl_sess_lookup.apply();
            }
        } else if (ue_filter_table.apply().hit) { // Check UE in managed prefix
            spgw_meta.direction = SPGW_DIR_DOWNLINK;

            if (dl_mec_sess_lookup.apply().hit) { // Packet from MEC, without encapsulation
                // Retrive the downlink TEID from register
                // Encapsulate the GTP-U tunnel on egress
                if(tmp_teid != 0) {
                    set_teid_info();
                    if(hdr.udp.src_port == 53) {
                        change_dns_server_back();
                    }
                } else {
                    miss_drop();
                    return;
                }
            } else {
                miss_drop(); // Abnormal packets
                return;
            }
        } // Left normal packets (w/ dst not in ue's prefix) alone ... not sure if this ok

        if (!spgw_meta.do_spgw) {
            // Exit this control block.
            add_void_bridged_md();
            return;
        }

        // Don't ask why... we'll need this later.
        spgw_meta.ipv4_len = hdr.ipv4.len;

        // Set spgw_meta to bridged_metadata
        add_bridged_md();
    }
}

control SpgwEgress(
        in ipv4_h inner_ipv4,
        inout ipv4_h ipv4,
        inout udp_h udp,
        inout gtpu_h gtpu,
        in spgw_meta_t spgw_meta
    ) {

    action gtpu_encap() {

        ipv4.setValid();
        ipv4.version = 4;
        ipv4.ihl = IPV4_MIN_IHL;
        ipv4.dscp = 0;
        ipv4.ecn = 0;
        ipv4.len = inner_ipv4.len
                 + (20 + 8 + 8);
        ipv4.identification = 0x1513; /* From NGIC */
        ipv4.flags = 0;
        ipv4.frag_offset = 0;
        ipv4.ttl = DEFAULT_IPV4_TTL;
        ipv4.protocol = IP_PROTO_UDP;
        ipv4.dst_addr = spgw_meta.s1u_enb_addr;
        ipv4.src_addr = spgw_meta.s1u_sgw_addr;
        ipv4.hdr_checksum = 0; // Updated later

        udp.setValid();
        udp.src_port = 2152;
        udp.dst_port = 2152;
        udp.len = spgw_meta.ipv4_len
                + (8 + 8);
        udp.checksum = 0; // Updated later

        gtpu.setValid();
        gtpu.version = 0x01;
        gtpu.pt = 0x01;
        gtpu.spare = 0;
        gtpu.ex_flag = 0;
        gtpu.seq_flag = 0;
        gtpu.npdu_flag = 0;
        gtpu.msgtype = 0xff;
        gtpu.msglen = spgw_meta.ipv4_len;
        gtpu.teid = spgw_meta.teid;

    }

    apply {
        if (spgw_meta.do_spgw && spgw_meta.direction == SPGW_DIR_DOWNLINK) {
            gtpu_encap();
        }
    }
}
//------------------------------------------------------------------------------
// INGRESS PIPELINE
//------------------------------------------------------------------------------

control SwitchIngress(
        inout headers_t hdr,
        inout local_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    // Declare control block
    PortCountersIngress() port_counters_ingress;
    Table0Control() table0_control;
    SpgwIngress() spgw_ingress;

    apply {
        port_counters_ingress.apply(hdr, ig_intr_md);
        table0_control.apply(hdr, ig_md, ig_intr_md, ig_intr_dprsr_md, ig_intr_tm_md);
        spgw_ingress.apply(hdr, ig_md.spgw, ig_intr_dprsr_md, ig_intr_tm_md);
    }
}

//------------------------------------------------------------------------------
// EGRESS PIPELINE
//------------------------------------------------------------------------------

control SwitchEgress(
        inout headers_t hdr,
        inout local_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    // Declare control block
    PortCountersEgress() port_counters_egress;
    SpgwEgress() spgw_egress;

    apply {
        port_counters_egress.apply(hdr, eg_intr_md);
        spgw_egress.apply(hdr.inner_ipv4, hdr.ipv4,
                          hdr.udp, hdr.gtpu, eg_md.spgw);
    }
}

//------------------------------------------------------------------------------
// SWITCH INSTANTIATION
//------------------------------------------------------------------------------

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
