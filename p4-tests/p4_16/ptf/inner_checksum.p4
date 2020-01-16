#include <core.p4> 
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#elif __TARGET_TOFINO__ == 1
#include <tna.p4>
#endif
#define ETHERTYPE_IPV4 0x800
#define IP_PROTOCOL_TCP 0x000006
#define IP_PROTOCOL_UDP 0x000011
#define UDP_PORT_VXLAN  0x4118

header bridged_meta_h {
 bit<16> outer_udp_checksum_b_md;

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
    bit<32> src_addr;
    bit<32>  dst_addr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header ethernet_h {
    bit<48> dst_addr;
    bit<48>  src_addr;
    bit<16> ether_type;
}

header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}
struct Parsed_packet {
    bridged_meta_h brid_md;
    ethernet_h outer_ethernet;
    ipv4_h outer_ipv4;
    udp_h outer_udp;
    vxlan_h vxlan; 
    ethernet_h inner_ethernet;   
    ipv4_h inner_ipv4;
}

struct metadata_t {
    bridged_meta_h eg_brid_md;
    bridged_meta_h ig_brid_md;
}

//=============================INGRESS PARSER===========================

parser SwitchIngressParser(packet_in pkt,
                           out Parsed_packet hdr,
                           out metadata_t ig_md,
                           out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() outer_udp_checksum;

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_outer_ethernet;
    }

    state parse_outer_ethernet {
        pkt.extract(hdr.outer_ethernet);
        transition select(hdr.outer_ethernet.ether_type){
            ETHERTYPE_IPV4    :    parse_outer_ipv4;
            default    :    accept;
        }
    }

    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        outer_udp_checksum.subtract({hdr.outer_ipv4.src_addr,
                               hdr.outer_ipv4.dst_addr,
                               8w0, hdr.outer_ipv4.protocol,
                               hdr.outer_ipv4.total_len});
        transition select(hdr.outer_ipv4.protocol){
            IP_PROTOCOL_UDP : parse_outer_udp;
        }
    }

    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        outer_udp_checksum.subtract({hdr.outer_udp.dst_port,
                                     hdr.outer_udp.src_port,
                                     hdr.outer_udp.length, 
                                     hdr.outer_udp.checksum
                    });
        ig_md.ig_brid_md.outer_udp_checksum_b_md = outer_udp_checksum.get();
        transition select(hdr.outer_udp.dst_port) {
            UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }
    
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition accept;
    }
}
//==============================INGRESS DEPARSER====================================

control SwitchIngressDeparser(packet_out pkt,
                              inout Parsed_packet hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr.brid_md);
        pkt.emit(hdr.outer_ethernet);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
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
    action send(PortId_t port){
        hdr.brid_md.setValid();
        hdr.brid_md.outer_udp_checksum_b_md = ig_md.ig_brid_md.outer_udp_checksum_b_md;
        hdr.inner_ipv4.dst_addr = 0x6f6f0101;
        ig_intr_md_for_tm.ucast_egress_port = port;
    }
    table forward {
        key = {hdr.outer_udp.src_port : exact;}
        actions = {send;}
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
        eg_md.eg_brid_md.outer_udp_checksum_b_md = hdr.brid_md.outer_udp_checksum_b_md;
        eg_md.eg_brid_md.setValid();
        transition parse_outer_ethernet;
    }

    state parse_outer_ethernet {
        pkt.extract(hdr.outer_ethernet);
        transition select(hdr.outer_ethernet.ether_type){
            ETHERTYPE_IPV4    :    parse_outer_ipv4;
            default    :    accept;
        }
    }

    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol){
            IP_PROTOCOL_UDP : parse_outer_udp;
        }
    }

    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        transition select(hdr.outer_udp.dst_port) {
            UDP_PORT_VXLAN : parse_vxlan;
            default : accept;
        }
    }

    state parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;
    }
    
    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_inner_ipv4;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition accept;
    }
} 

control SwitchEgressDeparser(packet_out pkt,
                             inout Parsed_packet hdr,
                             in metadata_t eg_md,
                             in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Checksum() inner_ipv4_checksum;
    Checksum() outer_udp_checksum;
    apply {
        hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({hdr.inner_ipv4.version,
                                                                  hdr.inner_ipv4.ihl,
                                                                  hdr.inner_ipv4.diffserv,
                                                                  hdr.inner_ipv4.total_len,
                                                                  hdr.inner_ipv4.identification,
                                                                  hdr.inner_ipv4.flags,
                                                                  hdr.inner_ipv4.frag_offset,
                                                                  hdr.inner_ipv4.ttl,
                                                                  hdr.inner_ipv4.protocol,
                                                                  hdr.inner_ipv4.src_addr,
                                                                  hdr.inner_ipv4.dst_addr});
         hdr.outer_udp.checksum = outer_udp_checksum.update({hdr.outer_ipv4.src_addr,
                                                             hdr.outer_ipv4.dst_addr,
                                                             8w0, hdr.outer_ipv4.protocol,
                                                             hdr.outer_ipv4.total_len,
                                                             hdr.outer_udp.src_port,
                                                             hdr.outer_udp.dst_port,
                                                             hdr.outer_udp.length,
  
                                                             hdr.vxlan.flags,
                                                             hdr.vxlan.reserved,
                                                             hdr.vxlan.vni,
                                                             hdr.vxlan.reserved2,

                                                             hdr.inner_ethernet.dst_addr,
                                                             hdr.inner_ethernet.src_addr,
                                                             hdr.inner_ethernet.ether_type,
                                                             hdr.inner_ipv4.version,
                                                             hdr.inner_ipv4.ihl,
                                                             hdr.inner_ipv4.diffserv,
                                                             hdr.inner_ipv4.total_len,
                                                             hdr.inner_ipv4.identification,
                                                             hdr.inner_ipv4.flags,
                                                             hdr.inner_ipv4.frag_offset,
                                                             hdr.inner_ipv4.ttl,
                                                             hdr.inner_ipv4.protocol,
                                                             hdr.inner_ipv4.hdr_checksum,
                                                             hdr.inner_ipv4.src_addr,
                                                             hdr.inner_ipv4.dst_addr,
                                                             eg_md.eg_brid_md.outer_udp_checksum_b_md});
        pkt.emit(hdr.outer_ethernet);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
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
