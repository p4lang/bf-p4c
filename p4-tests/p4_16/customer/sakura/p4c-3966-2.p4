#include <tna.p4>  /* TOFINO1_ONLY */

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16> l4_port_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;

typedef bit<16> arp_opcode_t;
const arp_opcode_t ARP_OPCODE_REQUEST = 16w0x0001;
const arp_opcode_t ARP_OPCODE_REPLY = 16w0x0002;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;

typedef bit<8> icmp_type_t;
const icmp_type_t ICMP_TYPE_ECHO_REPLY = 0;
const icmp_type_t ICMP_TYPE_ECHO_REQUEST = 8;

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
    bit<8> diffserv;
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
    bit<1> cwr;
    bit<1> ece;
    bit<1> urg;
    bit<1> ack;
    bit<1> psh;
    bit<1> rst;
    bit<1> syn;
    bit<1> fin;
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
    icmp_type_t type_;
    bit<8> code;
    bit<16> hdr_checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    arp_opcode_t opcode;
    mac_addr_t hw_src_addr;
    ipv4_addr_t proto_src_addr;
    mac_addr_t hw_dst_addr;
    ipv4_addr_t proto_dst_addr;
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}

// This annotation is necessary for onos to send packet-out!
@controller_header("packet_out")
header packet_out_t {
    PortId_t egress_port;
    bit<7> _pad;
}

struct header_t {
    packet_out_t packet_out;
    ethernet_h ethernet;
    ipv4_h ipv4;
    icmp_h icmp;
}

struct empty_header_t {}

struct empty_metadata_t {}
# 19 "/mnt/sakura_files_05272022/p4/main.p4" 2
# 1 "/mnt/sakura_files_05272022/p4/util.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// Skip egress
control BypassEgress(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action set_bypass_egress() {
        ig_tm_md.bypass_egress = 1w1;
    }

    table bypass_egress {
        actions = {
            set_bypass_egress();
        }
        const default_action = set_bypass_egress;
    }

    apply {
        bypass_egress.apply();
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
# 20 "/mnt/sakura_files_05272022/p4/main.p4" 2

struct metadata_t {
    bit<12> register_position_one;
    bit<12> register_position_two;
    bit<1> register_write_val;
    bit<1> register_cell_one;
    bit<1> register_cell_two;
}

# 1 "/mnt/sakura_files_05272022/p4/reg_rw.p4" 1
control RegRw(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    Counter<bit<32>, bit<1>>(512, CounterType_t.PACKETS) write_cpu_cntr;
    Counter<bit<32>, bit<1>>(512, CounterType_t.PACKETS) write_icmp_cntr;
    Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS) read_cntr;

    Register<bit<1>, bit<12>>(1 << 12, 0) reg_one;
    Register<bit<1>, bit<12>>(1 << 12, 0) reg_two;

    // reister actions
    RegisterAction<bit<1>, bit<12>, bit<1>>(reg_one) write_0_one = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };
    RegisterAction<bit<1>, bit<12>, bit<1>>(reg_two) write_0_two = {
        void apply(inout bit<1> value) {
            value = 1w0;
        }
    };
    RegisterAction<bit<1>, bit<12>, bit<1>>(reg_one) write_1_one = {
        void apply(inout bit<1> value) {
            value = 1w1;
        }
    };
    RegisterAction<bit<1>, bit<12>, bit<1>>(reg_two) write_1_two = {
        void apply(inout bit<1> value) {
            value = 1w1;
        }
    };
    RegisterAction<bit<1>, bit<12>, bit<1>>(reg_one) read_one = {
        void apply(inout bit<1> value, out bit<1> read_value) {
            read_value = value;
        }
    };
    RegisterAction<bit<1>, bit<12>, bit<1>>(reg_two) read_two = {
        void apply(inout bit<1> value, out bit<1> read_value) {
            read_value = value;
        }
    };

    // table actions
    action reg_write_cpu() {
        // dst_addr: 0x5eaaabbb
        // src_addr: 0x5e000000 or 0x5e000001
        ig_md.register_position_one = hdr.ethernet.dst_addr[23:12]; // 0xaaa
        ig_md.register_position_two = hdr.ethernet.dst_addr[11:0]; // 0xbbb
        ig_md.register_write_val = hdr.ethernet.src_addr[0:0]; // 0 or 1
        write_cpu_cntr.count(ig_md.register_write_val);
    }
    action reg_write_icmp() {
        // dst_addr: 10.170.171.187
        // src_addr: 172.16.0.1 or 172.16.0.2
        ig_md.register_position_one = hdr.ipv4.dst_addr[23:12]; // 0xaaa
        ig_md.register_position_two = hdr.ipv4.dst_addr[11:0]; // 0xbbb
        ig_md.register_write_val = hdr.ipv4.src_addr[0:0]; // 1 or 0
        write_icmp_cntr.count(ig_md.register_write_val);
    }
    action reg_read_cpu() {
        // dst_addr: 0x5eaaabbb
        // ingress_port: 320
        ig_md.register_position_one = hdr.ethernet.dst_addr[23:12]; // 0xaaa
        ig_md.register_position_two = hdr.ethernet.dst_addr[11:0]; // 0xbbb
        read_cntr.count(ig_intr_md.ingress_port);
    }
    action reg_read_icmp() {
        // dst_addr: 10.170.171.187
        // ingress_port: 4
        ig_md.register_position_one = hdr.ipv4.dst_addr[23:12]; // 0xaaa
        ig_md.register_position_two = hdr.ipv4.dst_addr[11:0]; // 0xbbb
        read_cntr.count(ig_intr_md.ingress_port);
    }

    // tables
    // egress_port: 511, ether_type: 0x100a
    table reg_write_cpu_tbl {
        key = {
            hdr.packet_out.egress_port: exact;
            hdr.ethernet.ether_type: exact;
        }
        actions = {
            reg_write_cpu;
        }
        size = 1;
    }

    // src_addr: 172.16.0.0/30, protocol: 1, type_: 8
    table reg_write_icmp_tbl {
        key = {
            hdr.ipv4.src_addr: lpm;
            hdr.ipv4.protocol: exact;
            hdr.icmp.type_: exact;
        }
        actions = {
            reg_write_icmp;
        }
        size = 1;
    }

    // egress_port: 511, ether_type: 0x100b
    table reg_read_cpu_tbl {
        key = {
            hdr.packet_out.egress_port: exact;
            hdr.ethernet.ether_type: exact;
        }
        actions = {
            reg_read_cpu;
        }
        size = 1;
    }

    // src_addr: 192.168.0.3, protocol: 1, type_: 8
    table reg_read_icmp_tbl {
        key = {
            hdr.ipv4.src_addr: exact;
            hdr.ipv4.protocol: exact;
            hdr.icmp.type_: exact;
        }
        actions = {
            reg_read_icmp;
        }
        size = 1;
    }

    apply {
        bit<1> v_one;
        bit<1> v_two;
        // packet-out from controller
        if (hdr.packet_out.isValid()) {
            if (reg_write_cpu_tbl.apply().hit) {
                // these register actions DO NOT seem to be executed.
                if (ig_md.register_write_val == 1) {
                    write_1_one.execute(ig_md.register_position_one);
                    write_1_two.execute(ig_md.register_position_two);
                }
                else if (ig_md.register_write_val == 0) {
                    write_0_one.execute(ig_md.register_position_one);
                    write_0_two.execute(ig_md.register_position_two);
                }
            }
            else if (reg_read_cpu_tbl.apply().hit) {
                // 
                v_one = read_one.execute(ig_md.register_position_one);
                v_two = read_two.execute(ig_md.register_position_two);
                if (v_one == 1) {
                    ig_md.register_cell_one = v_one;
                }
                if (v_two == 1) {
                    ig_md.register_cell_two = v_two;
                }
            }
        }
        else if (hdr.icmp.isValid()) {
            if (reg_write_icmp_tbl.apply().hit) {
                // these two register actions DO seem to be executed.
                if (ig_md.register_write_val == 1) {
                    write_1_one.execute(ig_md.register_position_one);
                    write_1_two.execute(ig_md.register_position_two);
                }
                else if (ig_md.register_write_val == 0) {
                    write_0_one.execute(ig_md.register_position_one);
                    write_0_two.execute(ig_md.register_position_two);
                }
            }
            else if (reg_read_icmp_tbl.apply().hit) {
                // 
                v_one = read_one.execute(ig_md.register_position_one);
                v_two = read_two.execute(ig_md.register_position_two);
                if (v_one == 1) {
                    ig_md.register_cell_one = v_one;
                }
                if (v_two == 1) {
                    ig_md.register_cell_two = v_two;
                }
            }
        }

        ig_dprsr_md.drop_ctl = 0x1;
    }
}
# 30 "/mnt/sakura_files_05272022/p4/main.p4" 2

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition select(ig_intr_md.ingress_port) {
            64: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        pkt.extract(hdr.packet_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_ICMP: parse_icmp;
            default: accept;
        }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------

control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Ingress Control Block
// ---------------------------------------------------------------------------

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    RegRw() reg_rw;

    apply {
        ig_tm_md.bypass_egress = 1w1;
        reg_rw.apply(hdr, ig_md, ig_intr_md, ig_prsr_md, ig_dprsr_md, ig_tm_md);
    }
}


// ---------------------------------------------------------------------------
// Target Switch Installation
// ---------------------------------------------------------------------------

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) pipe;

Switch(pipe) main;
