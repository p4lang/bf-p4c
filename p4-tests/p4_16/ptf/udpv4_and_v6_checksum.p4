#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#endif
#define ETHERTYPE_IPV4 0x800
#define ETHERTYPE_IPV6 0x86DD
#define next_hdr_TCP 0x06
#define next_hdr_UDP 0x11
#define IP_PROTOCOL_TCP 0x000006
#define IP_PROTOCOL_UDP 0x000011

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
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
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header bridged_meta_h {
 bit<16> udp_checksum_b_md;


}
struct Parsed_packet {
    bridged_meta_h brid_md;
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcpv4;
    udp_h udpv4;
    tcp_h tcpv6;
    udp_h udpv6;
}

struct metadata_t {
    bool checksum_err;
    bridged_meta_h eg_brid_md;
    bridged_meta_h ig_brid_md;

}

//=============================INGRESS PARSER===========================

parser SwitchIngressParser(
    packet_in pkt,
    out Parsed_packet hdr,
    out metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) udp_checksum;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type){
            ETHERTYPE_IPV4    :    parse_ipv4;
            ETHERTYPE_IPV6    :    parse_ipv6;
            default    :    accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        udp_checksum.subtract({hdr.ipv4.src_addr,
                               hdr.ipv4.dst_addr,
                               8w0, hdr.ipv4.protocol,
                               hdr.ipv4.total_len});
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOL_TCP    :    parse_tcpv4;
            IP_PROTOCOL_UDP    :    parse_udpv4;
            default : accept;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        udp_checksum.subtract({hdr.ipv6.src_addr,
                               hdr.ipv6.dst_addr,
                               hdr.ipv6.payload_len,
                               8w0, hdr.ipv6.next_hdr});

        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOL_TCP : parse_tcpv6;
            IP_PROTOCOL_UDP : parse_udpv6;
            default : accept;
        }

    }
    state parse_tcpv4 {
        pkt.extract(hdr.tcpv4);
        transition accept;
    }
    state parse_tcpv6 {
        pkt.extract(hdr.tcpv6);
        transition accept;
    }

    state parse_udpv4 {
        pkt.extract(hdr.udpv4);
        udp_checksum.subtract({hdr.udpv4.src_port,
                               hdr.udpv4.dst_port,
                               hdr.udpv4.checksum});
        ig_md.ig_brid_md.udp_checksum_b_md = udp_checksum.get();
        transition accept;
    }
    state parse_udpv6 {
        pkt.extract(hdr.udpv6);
        udp_checksum.subtract({hdr.udpv6.src_port,
                               hdr.udpv6.dst_port,
                               hdr.udpv6.checksum});
        ig_md.ig_brid_md.udp_checksum_b_md = udp_checksum.get();
        transition accept;
    }
}
//==============================INGRESS DEPARSER====================================

control SwitchIngressDeparser(packet_out pkt, inout Parsed_packet hdr,
                        in metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
     apply {
	
        pkt.emit(hdr.brid_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udpv4);
        pkt.emit(hdr.tcpv4);
        pkt.emit(hdr.udpv6);
        pkt.emit(hdr.tcpv6);
    }
}   

control SwitchIngress(
        inout Parsed_packet hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
		in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
		inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
		inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
        ){
    action miss_() {}
    action chg_src_send(PortId_t port){
     hdr.brid_md.setValid();
     hdr.brid_md.udp_checksum_b_md = ig_md.ig_brid_md.udp_checksum_b_md;
     ig_intr_md_for_tm.ucast_egress_port = port;
        }
// ****************** OUTER LAYERS***********************************

    table forward {
        key = {hdr.ethernet.src_addr : exact;}
        actions = { 
            chg_src_send;
            miss_;
        }
        const default_action = miss_;
    }
    apply {
        forward.apply();
    }
}
//=================================EGRESS PARSER====================================

parser SwitchEgressParser(
    packet_in pkt,
    out Parsed_packet hdr,
    out metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridged_metadata;
    }
    state parse_bridged_metadata{
        pkt.extract(hdr.brid_md);
        eg_md.eg_brid_md.udp_checksum_b_md = hdr.brid_md.udp_checksum_b_md;
        transition parse_ethernet;

    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type){
            ETHERTYPE_IPV4  :   parse_ipv4;
            ETHERTYPE_IPV6  :   parse_ipv6;
            default :   accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOL_TCP :   parse_tcpv4;
            IP_PROTOCOL_UDP :   parse_udpv4;
            default : accept;

        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOL_TCP : parse_tcpv6;
            IP_PROTOCOL_UDP : parse_udpv6;
            default : accept;
        }

    }
   state parse_tcpv4 {
        pkt.extract(hdr.tcpv4);
        transition accept;
    }
    state parse_tcpv6 {
        pkt.extract(hdr.tcpv6);
        transition accept;
    }

    state parse_udpv4 {
        pkt.extract(hdr.udpv4);
        transition accept;
    }
    state parse_udpv6 {
        pkt.extract(hdr.udpv6);
        transition accept;
    }   
}

control SwitchEgressDeparser(packet_out pkt, inout Parsed_packet hdr,
                        in metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr){
    

    Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) udp_checksum;
    apply {
        if (hdr.ipv4.isValid()) {
            hdr.udpv4.checksum = udp_checksum.update({hdr.ipv4.src_addr,
                                                    hdr.ipv4.dst_addr,
                                                    8w0,
                                                    hdr.ipv4.protocol,
                                                    hdr.ipv4.total_len,
                                                    hdr.udpv4.src_port,
                                                    hdr.udpv4.dst_port,
                                                    eg_md.eg_brid_md.udp_checksum_b_md});
        }
        if (hdr.ipv6.isValid()){
            hdr.udpv6.checksum = udp_checksum.update({hdr.ipv6.src_addr,
                                                    hdr.ipv6.dst_addr,
                                                    hdr.ipv6.payload_len,
                                                    8w0,
                                                    hdr.ipv6.next_hdr,
                                                    hdr.udpv6.src_port,
                                                    hdr.udpv6.dst_port,
                                                    eg_md.eg_brid_md.udp_checksum_b_md});
 
        }
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udpv4);
        pkt.emit(hdr.tcpv4);
        pkt.emit(hdr.udpv6);
        pkt.emit(hdr.tcpv6);
    }
}

control SwitchEgress(inout Parsed_packet hdr,
        inout metadata_t ig_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
       ){
    apply{}
}

Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe0;

Switch(pipe0) main;

