#include <core.p4>
#include <tna.p4>


typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;
typedef bit<12> vlan_id_t;



typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<8> protocol_t;


typedef bit<16> port_t;


header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    ether_type_t ether_type;
}


header vlan_tag_h {
    bit<3> pcp;
    bit<1> dei;
    vlan_id_t vid;
    ether_type_t ether_type;
}


const bit<8> ipv4_h_size = 20;
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
    protocol_t protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}


header ipv4_opt_h {
        varbit<320> data;
}



const bit<8> ipv6_h_size = 40;
header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_length;
    protocol_t next_header;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}


header ipv6_hop_by_hop_h {
    bit<8> next_header;
    bit<8> header_extension_length;
    varbit<112> options;
}


typedef ipv6_hop_by_hop_h ipv6_opt_destination_h;


header ipv6_routing_h {
    bit<8> next_header;
    bit<8> header_extension_length;
    bit<8> routing_type;
    bit<8> segments_left;
    varbit<96> type_specific_data;
}


const bit<8> ipv6_fragment_h_size = 8;
header ipv6_fragment_h {
    bit<8> next_header;
    bit<8> reserved;
    bit<13> fragment_offset;
    bit<2> res;
    bit<1> M;
    bit<32> identification;
}


header ipv6_partial_option_h {
    bit<8> next_header;
    bit<8> header_extension_length;
}



struct ipv6_opt_t {
    ipv6_hop_by_hop_h hop_by_hop;
    ipv6_routing_h routing;
    ipv6_fragment_h fragment;
    ipv6_opt_destination_h destination;
}


const bit<8> udp_h_size = 8;
header udp_h {
    port_t src_port;
    port_t dst_port;
    bit<16> length;
    bit<16> checksum;
}





struct tcp_flags_t {
    bit<1> NS;
    bit<1> CWR;
    bit<1> ECE;
    bit<1> URG;
    bit<1> ACK;
    bit<1> PSH;
    bit<1> RST;
    bit<1> SYN;
    bit<1> FIN;
}


const bit<8> tcp_h_size = 20;
header tcp_h {
    port_t src_port;
    port_t dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<3> reserved;
    tcp_flags_t flags;
    bit<16> window_size;
    bit<16> checksum;
    bit<16> urgent_ptr;
}



header tcp_opt_h {
    varbit<320> options;
}



struct headers {

    ethernet_h ethernet;
    vlan_tag_h vlan;

    ipv4_h ipv4;
    ipv4_opt_h ipv4_opt;
    ipv6_h ipv6;
    ipv6_opt_t ipv6_opt;

    tcp_h tcp;
    udp_h udp;
    tcp_opt_h tcp_opt;
}


struct metadata_t {

    port_t src_port;
    port_t dst_port;
}


parser IngressParser(
        packet_in packet,
        out headers hdr,
        out metadata_t meta,
        out ingress_intrinsic_metadata_t ig_intr_md)
{

    state start {
        meta = {0, 0};

        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);

        packet.extract(hdr.ethernet);

        transition select(hdr.ethernet.ether_type) {
            0x8100: vlan;

        }
    }

    state vlan {

        packet.extract(hdr.vlan);

        transition select(hdr.vlan.ether_type) {
            0x0800: ipv4;
            0x86DD: ipv6;
            0x0806: accept;

        }
    }

    state ipv4 {
        packet.extract(hdr.ipv4);

        transition select(hdr.ipv4.ihl) {
            5: ipv4_no_option;
            6..15: ipv4_options;

        }
    }

    state ipv4_options {
        packet.extract(hdr.ipv4_opt, (bit<32>)(hdr.ipv4.ihl - 5)*32);
        transition ipv4_no_option;
    }

    state ipv4_no_option {

        transition select(hdr.ipv4.protocol) {
            0x11: udp;
            0x06: tcp;

        }
    }

    state ipv6 {

        packet.extract(hdr.ipv6);


        transition select(hdr.ipv6.next_header) {
            0x00: ipv6_hop_by_hop;
            0x2B: ipv6_routing;
            0x2C: ipv6_fragment;
            0x3C: ipv6_destination;
            0x11: udp;
            0x06: tcp;

        }
    }

    state ipv6_hop_by_hop {

        packet.extract(hdr.ipv6_opt.hop_by_hop, ((bit<32>)packet.lookahead<ipv6_partial_option_h>().header_extension_length + 8) * 8);


        transition select(hdr.ipv6_opt.hop_by_hop.next_header) {
            0x2B: ipv6_routing;
            0x2C: ipv6_fragment;
            0x3C: ipv6_destination;
            0x11: udp;
            0x06: tcp;

        }
    }

    state ipv6_routing {

        packet.extract(hdr.ipv6_opt.routing, ((bit<32>)packet.lookahead<ipv6_partial_option_h>().header_extension_length + 8) * 8);


        transition select(hdr.ipv6_opt.routing.next_header) {
            0x2C: ipv6_fragment;
            0x3C: ipv6_destination;
            0x11: udp;
            0x06: tcp;

        }
    }

    state ipv6_fragment {
        packet.extract(hdr.ipv6_opt.fragment);


        transition select(hdr.ipv6_opt.fragment.next_header) {
            0x3C: ipv6_destination;
            0x11: udp;
            0x06: tcp;

        }
    }

    state ipv6_destination {

        packet.extract(hdr.ipv6_opt.destination, ((bit<32>)packet.lookahead<ipv6_partial_option_h>().header_extension_length + 8) * 8);


        transition select(hdr.ipv6_opt.destination.next_header) {
            0x11: udp;
            0x06: tcp;

        }
    }

    state udp {
        packet.extract(hdr.udp);


        meta.src_port = hdr.udp.src_port;
        meta.dst_port = hdr.udp.dst_port;

        transition accept;
    }

    state tcp {
        packet.extract(hdr.tcp);


        meta.src_port = hdr.tcp.src_port;
        meta.dst_port = hdr.tcp.dst_port;


        packet.extract(hdr.tcp_opt, (bit<32>)(hdr.tcp.data_offset - 5) * 32);

        transition accept;
    }
}

control IngressProcessing(
        inout headers hdr,
        inout metadata_t meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md)
{
    bit<16> id = 0;

    action drop() {

        ig_intr_dprsr_md.drop_ctl = 0x1;
    }

    action filter4_stage1(bit<16> next_id) {

        id = next_id;
    }

    action filter4_stage2(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table ipv4_src_filter {
        key = {
            hdr.vlan.vid: exact;
            hdr.ipv4.src_addr: lpm;
            meta.src_port: range;
        }

        actions = {
            drop;
            filter4_stage1;
        }

        const default_action = drop;
        size = 1024;
    }

    table ipv4_dst_filter {
        key = {
            id: exact;
            hdr.ipv4.dst_addr: lpm;
            meta.dst_port: range;
        }

        actions = {
            drop;
            filter4_stage2;
        }

        const default_action = drop;
        size = 1024;
    }

    action filter6_stage1(bit<16> next_id) {
        id = next_id;
    }

    action filter6_stage2(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    table ipv6_src_filter {
        key = {
            hdr.vlan.vid: exact;
            hdr.ipv6.src_addr: lpm;
            meta.src_port: range;
        }

        actions = {
            drop;
            filter6_stage1;
        }

        const default_action = drop;
        size = 1024;
    }

    table ipv6_dst_filter {
        key = {
            id: exact;
            hdr.ipv6.dst_addr: lpm;
            meta.dst_port: range;
        }

        actions = {
            drop;
            filter6_stage2;
        }

        const default_action = drop;
        size = 1024;
    }

    apply {
        id = 0;

        if (hdr.ipv4.isValid()) {
            if (ipv4_src_filter.apply().hit) {
                ipv4_dst_filter.apply();
            }
        } else if (hdr.ipv6.isValid()) {
            if (ipv6_src_filter.apply().hit) {
                ipv6_dst_filter.apply();
            }
        } else {
            drop();
        }
    }
}


control IngressDeparser(
        packet_out packet,
        inout headers hdr,
        in metadata_t meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md)
{
    apply {

        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan);

        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv4_opt);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.ipv6_opt);

        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp_opt);
    }
}






parser EgressParser(
        packet_in pkt,
        out headers hdr,
        out metadata_t meta,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control EgressProcessing(
        inout headers hdr,
        inout metadata_t meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {

    }
}

control EgressDeparser(
        packet_out pkt,
        inout headers hdr,
        in metadata_t meta,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {

    }
}

Pipeline(
    IngressParser(),
    IngressProcessing(),
    IngressDeparser(),
    EgressParser(),
    EgressProcessing(),
    EgressDeparser()) pipe;

Switch(pipe) main;
