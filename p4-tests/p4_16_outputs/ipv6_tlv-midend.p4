#include <core.p4>
#include <tofino.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header ipv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4>      version;
    bit<8>      traffic_class;
    bit<20>     flow_label;
    bit<16>     payload_len;
    bit<8>      next_hdr;
    bit<8>      hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_lenght;
    bit<16> checksum;
}

header ipv6_srh_h {
    bit<8>  next_hdr;
    bit<8>  hdr_ext_len;
    bit<8>  routing_type;
    bit<8>  segment_left;
    bit<8>  last_entry;
    bit<8>  flags;
    bit<16> tag;
}

header segment_id_h {
    ipv6_addr_t sid;
}

struct switch_header_t {
    ethernet_h      ethernet;
    ipv4_h          ipv4;
    ipv6_h          ipv6;
    ipv6_srh_h      ipv6_srh;
    segment_id_h[5] ipv6_srh_segment_list;
    tcp_h           tcp;
    udp_h           udp;
}

struct switch_metadata_t {
}

parser SwitchIngressParser(packet_in pkt, out switch_header_t hdr, out switch_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    bit<8> tmp;
    @name("SwitchIngressParser.counter") ParserCounter<bit<8>>() counter_0;
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1w0: parse_port_metadata;
            1w1: reject;
            default: noMatch;
        }
    }
    state parse_port_metadata {
        pkt.advance(32w64);
        pkt.extract<ethernet_h>(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            16w0x86dd: parse_ipv6;
            default: reject;
        }
    }
    state parse_ipv6 {
        pkt.extract<ipv6_h>(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            8w43: parse_ipv6_srh;
            default: accept;
        }
    }
    state parse_ipv6_srh {
        pkt.extract<ipv6_srh_h>(hdr.ipv6_srh);
        counter_0.set(hdr.ipv6_srh.segment_left, 8w0xff, 8w0, 8w0xff, 8w1);
        transition parse_ipv6_srh_segment_list;
    }
    state parse_ipv6_srh_segment_list {
        pkt.extract<segment_id_h>(hdr.ipv6_srh_segment_list.next);
        counter_0.decrement(8w0x1);
        tmp = counter_0.get();
        transition select(tmp) {
            8w0: accept;
            default: parse_ipv6_srh_segment_list;
        }
    }
    state noMatch {
        verify(false, error.NoMatch);
        transition reject;
    }
}

struct tuple_1 {
    bit<4>  field_15;
    bit<4>  field_16;
    bit<8>  field_17;
    bit<16> field_18;
    bit<16> field_19;
    bit<3>  field_20;
    bit<13> field_21;
    bit<8>  field_22;
    bit<8>  field_23;
    bit<32> field_24;
    bit<32> field_25;
}

control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    bit<16> tmp_0;
    @name("SwitchIngressDeparser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CRC16) ipv4_checksum_0;
    @hidden action act() {
        tmp_0 = ipv4_checksum_0.update<tuple_1>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        hdr.ipv4.hdr_checksum = tmp_0;
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<udp_h>(hdr.udp);
        pkt.emit<tcp_h>(hdr.tcp);
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

control SwitchIngress(inout switch_header_t hdr, inout switch_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("SwitchIngress.forward") action forward(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }
    @name("SwitchIngress.srv6") table srv6_0 {
        key = {
            hdr.ipv6_srh.isValid(): exact @name("hdr.ipv6_srh.$valid$") ;
        }
        actions = {
            NoAction_0();
            forward();
        }
        default_action = NoAction_0();
    }
    apply {
        srv6_0.apply();
    }
}

parser EmptyEgressParser_0(packet_in pkt, out switch_header_t hdr, out switch_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    egress_intrinsic_metadata_t eg_intr_md_0;
    state start {
        eg_intr_md_0.setInvalid();
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md_0);
        eg_intr_md = eg_intr_md_0;
        transition accept;
    }
}

control EmptyEgress_0(inout switch_header_t hdr, inout switch_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control EmptyEgressDeparser_0(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
    }
}

Pipeline<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), EmptyEgressParser_0(), EmptyEgress_0(), EmptyEgressDeparser_0()) pipe0;

Switch<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

