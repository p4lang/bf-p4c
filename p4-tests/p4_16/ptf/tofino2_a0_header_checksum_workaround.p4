#include <core.p4>
#include <tna.p4>
#define ETHERTYPE_IPV4 0x800
#define IP_PROTOCOL_UDP 0x000011

// This is a workaround suggested to calculate ip checksum in tofino2 A0.
// Instead of calculating checksum in deparser, this test calclates ip checksum
// in the parser using parser residual checksum engine. All the fields except checksum field 
// of the ipv4 header are included in the residual engine. To calculate correct checksum, automatic
// subtraction of the residual engine needs to halted. Hence the checksum.subtract_all_and_deposit()
// is called at the end of the parser so no header proceeding ip is subtracted. The resulting output of the
// parser residual engine is stored in a 16 bit metadata. Later an action is included in the MAU to copy this
// metadata into ip checksum field.

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


header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

struct Parsed_packet {
    ethernet_h ethernet;
    ipv4_h ipv4;
    udp_h udp;
}

struct ingress_metadata_t {
}

struct egress_metadata_t {
    bit<16> meta_ip_checksum;

}

//=============================INGRESS PARSER===========================

parser SwitchIngressParser(
    packet_in pkt,
    out Parsed_packet hdr,
    out ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {


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
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOL_UDP    :    parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }
}
//==============================INGRESS DEPARSER====================================

control SwitchIngressDeparser(packet_out pkt, inout Parsed_packet hdr,
                        in ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
     apply {
	
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
    }
}   

control SwitchIngress(
        inout Parsed_packet hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
		in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
		inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
		inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
        ){
    action miss_() {}
    action send(PortId_t port){
        ig_intr_md_for_tm.ucast_egress_port = port;
    }
    table forward {
        key = {hdr.udp.src_port : exact;}
        actions = {send;}
    }
    action chg_values() {
        hdr.ipv4.src_addr = 0x12346578;
        hdr.ipv4.dst_addr = 0x98765432; 
    }

    apply {
        forward.apply();
        if (hdr.ipv4.isValid()) {
            chg_values();
        }
    }
}
//=================================EGRESS PARSER====================================

parser SwitchEgressParser(
    packet_in pkt,
    out Parsed_packet hdr,
    out egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {
    Checksum() ip_checksum;

    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridged_metadata;
    }
    state parse_bridged_metadata{
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
        ip_checksum.subtract({hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv,
                              hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags,
                              hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr,
                              hdr.ipv4.dst_addr});
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOL_UDP :   parse_udp;
            default : accept;

        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        ip_checksum.subtract_all_and_deposit(eg_md.meta_ip_checksum);
        transition accept;
    }
}

control SwitchEgressDeparser(packet_out pkt, inout Parsed_packet hdr,
                        in egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr){
    
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.udp);
    }
}

control SwitchEgress(inout Parsed_packet hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
       ){
    action transfer_ip_checksum() {
         hdr.ipv4.hdr_checksum = eg_md.meta_ip_checksum;
    }
    apply{
       transfer_ip_checksum();
    }
}

Pipeline(SwitchIngressParser(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe0;

Switch(pipe0) main;

