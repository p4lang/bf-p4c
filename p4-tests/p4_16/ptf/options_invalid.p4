#include <core.p4>
#include <tna.p4>
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

header ipv4_options_h {
    varbit<320> options;
}
struct Parsed_packet {
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv4_options_h ipv4_options;
}

struct metadata_t {
    bool checksum_err;

}

//=============================INGRESS PARSER===========================

parser SwitchIngressParser(
    packet_in pkt,
    out Parsed_packet hdr,
    out metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() udp_checksum;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type){
            ETHERTYPE_IPV4    :    parse_ipv4;

            default    :    accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl){
            6..15 : parse_ipv4_options;
            0..5 : parse_ipv4_no_options;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_options, ((bit<32>)hdr.ipv4.ihl - 32w5) * 32);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition accept;
    }    
}
//==============================INGRESS DEPARSER====================================

control SwitchIngressDeparser(packet_out pkt, inout Parsed_packet hdr,
                        in metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
     apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_options);
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
    hdr.ipv4_options.setInvalid();
    hdr.ipv4.ihl = 5;
    hdr.ipv4.total_len = 21;
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
        transition parse_ethernet;

    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type){
            ETHERTYPE_IPV4  :   parse_ipv4;
            default :   accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl){
            6..15 : parse_ipv4_options;
            0..5 : parse_ipv4_no_options;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_options, ((bit<32>)hdr.ipv4.ihl - 32w5) * 32);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition accept;
    }
}

control SwitchEgressDeparser(packet_out pkt, inout Parsed_packet hdr,
                        in metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr){
    
    Checksum() ipv4_checksum;
    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update(
                {hdr.ipv4.version,
                 hdr.ipv4.ihl,
                 hdr.ipv4.diffserv,
                 hdr.ipv4.total_len,
                 hdr.ipv4.identification,
                 hdr.ipv4.flags,
                 hdr.ipv4.frag_offset,
                 hdr.ipv4.ttl,
                 hdr.ipv4.protocol,
                 hdr.ipv4.src_addr,
                 hdr.ipv4.dst_addr,
                 hdr.ipv4_options});
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv4_options);
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

