/*
 * Throws the following bug for me:
 *
 *   $ bf-p4c --verbose=2 -g --create-graphs bug1.p4
 *   In file: /media/ramdisk/submodules/bf-p4c-compilers/p4c/extensions/bf-p4c/parde/allocate_parser_match_register.cpp:815
 *   Compiler Bug: strip-vlan.p4(83): Parser match register not allocated for hdr.ether_type/ether_type.ether_type;
 *        transition select(hdr.ether_type.ether_type) {
 */
#include <core.p4>
#include <tna.p4>

enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800
}

typedef bit<48> mac_addr_t;

header ethernet_h {
  mac_addr_t dst;
  mac_addr_t src;
}

header ether_type_h {
  ether_type_t ether_type;
}

header vlan_tag_h {
  ether_type_t tpid;
  bit<3> pcp;
  bit<1> cfi;
  bit<12> vid;
}

header ipv4_h {
  bit<4>   version;
  bit<4>   ihl;
  bit<8>   diffserv;
  bit<16>  total_len;
  bit<16>  identification;
  bit<3>   flags;
  bit<13>  frag_offset;
  bit<8>   ttl;
  bit<8>   protocol;
  bit<16>  hdr_checksum;
  bit<32>  src_addr;
  bit<32>  dst_addr;
}

struct ingress_headers_t {
  ethernet_h ethernet;
  ether_type_h ether_type;
  ipv4_h ipv4;
}

struct ingress_metadata_t {
}

parser IngressParser(
    packet_in pkt,
    out ingress_headers_t hdr,
    out ingress_metadata_t meta,
    out ingress_intrinsic_metadata_t ig_intr_md)
{
  state start {
    pkt.extract(ig_intr_md);
    pkt.advance(PORT_METADATA_SIZE);
    transition parse_ethernet; 
  }

  state parse_ethernet {
    pkt.extract(hdr.ethernet);
    transition select(pkt.lookahead<ether_type_t>()) {
      ether_type_t.TPID: skip_vlan_tag;
      default: parse_ether_type;
    }
  }

  state skip_vlan_tag {
    pkt.advance(32);
    transition select(pkt.lookahead<ether_type_t>()) {
      ether_type_t.TPID: skip_vlan_tag;
      default: parse_ether_type;
    }
  }
  
  state parse_ether_type {
    pkt.extract(hdr.ether_type);
    transition select(hdr.ether_type.ether_type) {
      ether_type_t.IPV4: parse_ipv4;
      default: accept;
    }
  }

  state parse_ipv4 {
    pkt.extract(hdr.ipv4);
    transition accept;
  }
}

control Ingress(
    inout ingress_headers_t hdr,
    inout ingress_metadata_t meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
  apply { }
}

control IngressDeparser(packet_out pkt,
    inout ingress_headers_t hdr,
    in ingress_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

struct egress_headers_t { }
struct egress_metadata_t { }

parser EgressParser(
    packet_in pkt,
    out egress_headers_t hdr,
    out egress_metadata_t meta,
    out egress_intrinsic_metadata_t eg_intr_md)
{
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control Egress(
    inout egress_headers_t hdr,
    inout egress_metadata_t meta,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{
    apply {
    }
}

control EgressDeparser(
    packet_out pkt,
    inout egress_headers_t hdr,
    in egress_metadata_t meta,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
