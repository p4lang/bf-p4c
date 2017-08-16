
#include "tofino/constants.p4"
#include "tofino/intrinsic_metadata.p4"
#include "tofino/primitives.p4"
#include "tofino/pktgen_headers.p4"
#include "tofino/stateful_alu_blackbox.p4"


header_type ebmeta_t {
 fields {
  current_offset : 8;
  mpls_offset : 8;
  ip1_offset : 8;
  ip2_offset : 8;
  port_hash : 16;
  lanwan_out_port : 8;
  dpi_port : 16;
  is_nat : 1;
  is_banan : 1;
  port_type : 3;
  useless1 : 2;
  dpi_queue : 8;
  mirror_port : 16;
 }
}

header_type ethernet_t {
 fields {
  dstAddr : 48;
  srcAddr : 48;
  etherType : 16;
 }
}

header_type ebheader_t {
 fields {
  unused1 : 16;
  dst_main_agg : 8;
  dst_main_dpi : 8;
  dst_mirror : 16;
  unused2 : 8;
  flags_unused_bits : 6;
  is_nat : 1;
  is_banan : 1;
  offset_ip1 : 8;
  offset_ip2 : 8;
  offset_mpls : 8;
  offset_payload : 8;
  ethertype_eb : 8;
  rss_queue : 8;
  hash1 : 32;
  hash2 : 32;
 }
}

header_type mpls_t {
 fields {
  label : 20;
  tclass : 3;
  bottom : 1;
  ttl : 8;
 }
}

header_type mpls_cw_t {
 fields {
  useless : 32;
 }
}

header_type vlan_t {
 fields {
  prio : 3;
  cfi : 1;
  id : 12;
  etherType : 16;
 }
}

metadata ebmeta_t ebmeta;
header ethernet_t outer_ethernet;
header ebheader_t ebheader;
header vlan_t outer_vlan[5];
header mpls_t mpls[5];
header mpls_cw_t mpls_cw;
parser start {
 return determine_first_parser;
}

parser determine_first_parser {
 return select(current(96, 8)) {
  0xEC : ingress;
  0xEB : parse_ebheader;
  default : parse_outer_ethernet;
 }
}

parser parse_ebheader {
 extract(ebheader);
 return parse_fake_ethernet;
}

parser parse_fake_ethernet {
 extract(outer_ethernet);
 return ingress;
}

parser parse_outer_ethernet {
 extract(outer_ethernet);
 return select(outer_ethernet.etherType) {
  0x8100 : parse_outer_vlan;
  0x88A8 : parse_outer_vlan;
  0x9200 : parse_outer_vlan;
  0x9100 : parse_outer_vlan;
  0x8847 : parse_mpls;
  0x8848 : parse_mpls;





  default: ingress;
 }
}

parser parse_outer_vlan {
 extract(outer_vlan[next]);
 return select(latest.etherType) {
  0x8100 : parse_outer_vlan;
  0x88A8 : parse_outer_vlan;
  0x9200 : parse_outer_vlan;
  0x9100 : parse_outer_vlan;
  0x8847 : parse_mpls;
  0x8848 : parse_mpls;





  default : ingress;
 }
}

parser parse_mpls {
 extract(mpls[next]);
 return select(latest.bottom) {
  0 : parse_mpls;
  1 : parse_mpls_cw_determine;
  default : ingress;
 }
}

parser parse_mpls_cw_determine {
 return select (current(0, 8)) {
  0x00 : parse_mpls_cw;
  0x45 : cw_try_ipv4;
    0x46 mask 0xFE : cw_try_ipv4;
    0x48 mask 0xF8 : cw_try_ipv4;
  0x60 mask 0xF0 : cw_try_ipv6;
  default : ingress;



 }
}

parser parse_mpls_cw {
 extract(mpls_cw);
 return select (current(0, 8)) {
  0x45 : cw_try_ipv4;
    0x46 mask 0xFE : cw_try_ipv4;
    0x48 mask 0xF8 : cw_try_ipv4;
  0x60 mask 0xF0 : cw_try_ipv6;
  default : ingress;



 }
}

parser cw_try_ipv4 {
 return select(current(72, 8)) {
  default : ingress;
 }
}

parser cw_try_ipv6 {
 return select(current(48, 8)) {
  default : ingress;
 }
}

table determine_port_type {
 reads {
  standard_metadata.ingress_port : exact;
 }
 actions {
  set_port_type;
  _drop;
 }
}


table determine_nat_lanwan_flag_and_linked_port {
 reads {
  standard_metadata.ingress_port : exact;
 }
 actions {
  set_nat_lanwan_flag_and_linked_port;
  _nop;
 }
}


table add_ebheader {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_add_ebheader;
  _nop;
 }
}


table remove_ebheader {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_remove_ebheader;
  _nop;
 }
}
action _nop() { no_op(); }
action _drop() { drop(); }

action set_port_type(port_type) {
 modify_field(ebmeta.port_type, port_type);
}

action set_nat_lanwan_flag_and_linked_port(is_banan, is_nat, linked_port) {
 modify_field(ebmeta.is_banan, is_banan);
 modify_field(ebmeta.is_nat, is_nat);
 modify_field(ebmeta.lanwan_out_port, linked_port);
}

action do_add_ebheader() {
 add_header(ebheader);
 modify_field(ebheader.ethertype_eb, 0xEB);
 modify_field(ebheader.dst_main_dpi, ebmeta.lanwan_out_port);
        modify_field(ebheader.is_nat, ebmeta.is_nat);

 modify_field(ebheader.is_banan, ebmeta.is_banan);

        modify_field(ebheader.rss_queue, ebmeta.dpi_queue);
 modify_field(ebheader.offset_mpls, ebmeta.mpls_offset);
 modify_field(ebheader.offset_payload, ebmeta.current_offset);
 modify_field(ebheader.offset_ip1, ebmeta.ip1_offset);
 modify_field(ebheader.offset_ip2, ebmeta.ip2_offset);
}

action do_remove_ebheader() {
 modify_field(ebmeta.mirror_port, ebheader.dst_mirror);
 remove_header(ebheader);
}


control ingress {

 apply(determine_port_type);


 apply(determine_nat_lanwan_flag_and_linked_port);

}

control egress {

 apply(add_ebheader);

 apply(remove_ebheader);
}
