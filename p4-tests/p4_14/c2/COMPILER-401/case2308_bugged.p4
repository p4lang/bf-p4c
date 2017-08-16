/*
gcc -E -x c -w -I/tmp/_MEI4yCbtW/p4_lib -D__TARGET_TOFINO__ -DBUGGED -I/tmp/_MEI4yCbtW/p4_hlir/p4_lib /media/psf/Home/trees/bfn/p4examples/cases/002308/p4src/balancer.p4
*/

#include "tofino/constants.p4"
#include "tofino/intrinsic_metadata.p4"
#include "tofino/primitives.p4"
#include "tofino/pktgen_headers.p4"
#include "tofino/stateful_alu_blackbox.p4"



header_type ebmeta_t {
 fields {
  _pad1 : 12;
  lanwan_out_port : 9;
  dpi_port : 9;
  dst_mirror_agg : 9;
  dst_mirror_out : 9;
  _pad2 : 14;
  is_nat : 1;
  is_lan : 1;
  offset_ip1 : 8;
  offset_ip2 : 8;
  offset_mpls : 8;
  offset_payload : 8;
  rss_queue : 8;
  port_type : 3;
  _pad3 : 5;
  port_hash : 16;

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
  unused1 : 12;
  dst_main_agg : 9;
  dst_main_out : 9;
  dst_mirror_agg : 9;
  dst_mirror_out : 9;
  unused2 : 8;
  flags_unused_bits : 6;
  is_nat : 1;
  is_lan : 1;
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

header_type ipv4_t {
 fields {
  version : 4;
  ihl : 4;
  diffserv : 8;
  totalLen : 16;
  identification : 16;
  flags : 3;
  fragOffset : 13;
  ttl : 8;
  protocol : 8;
  hdrChecksum : 16;
  srcAddr : 32;
  dstAddr : 32;
 }
}

header_type tcp_t {
 fields {
  portSrc : 16;
  portDst : 16;
  seqNum: 32;
  ackNum : 32;
  headerLen : 4;
  reserved : 6;
  controlBits : 6;
  window : 16;
  checksum : 16;
  urgentPtr : 16;

 }
}
header_type udp_t {
 fields {
  portSrc : 16;
  portDst : 16;
  len : 16;
  csum : 16;
 }
}
header_type udplite_t {
 fields {
  portSrc : 16;
  portDst : 16;
  ccover : 16;
  csum : 16;
 }
}
header_type sctp_t {
 fields {
  srcPort : 16;
  dstPort : 16;
  tag : 32;
  csum : 32;
 }
}
header_type pppoe_t {
 fields {
  version : 4;
  ptype : 4;
  code : 8;
  session : 16;
  payloadLen : 16;
  protocol : 16;
 }
}

header_type ipv6_t {
 fields {
  ver : 4;
  tclass : 8;
  flowl : 20;
  payloadLen : 16;
  nextHeader : 8;
  hopLimit : 8;
  srcAddr : 128;
  dstAddr : 128;
 }
}

metadata ebmeta_t ebmeta;
header ethernet_t outer_ethernet;
header ethernet_t inner_ethernet;
header ebheader_t ebheader;
header vlan_t outer_vlan[5];
header mpls_t mpls[5];
header mpls_cw_t mpls_cw;
header ipv4_t outer_ipv4;
header ipv4_t inner_ipv4;
header ipv6_t inner_ipv6;
header ipv6_t outer_ipv6;
header tcp_t tcp;
header udp_t udp;
header sctp_t sctp;
header udplite_t udplite;
header pppoe_t pppoe;


header_type skip_4_t { fields { useless : 32; } }
header_type skip_8_t { fields { useless : 64; } }
header_type skip_12_t { fields { useless : 96; } }
header_type skip_16_t { fields { useless : 128; } }
header_type skip_20_t { fields { useless : 160; } }
header_type skip_24_t { fields { useless : 192; } }
header_type skip_28_t { fields { useless : 224; } }
header_type skip_32_t { fields { useless : 256; } }
header_type skip_36_t { fields { useless : 288; } }
header_type skip_40_t { fields { useless : 320; } }
header_type skip_44_t { fields { useless : 352; } }
header_type skip_48_t { fields { useless : 384; } }
header_type skip_52_t { fields { useless : 416; } }
header_type skip_56_t { fields { useless : 448; } }
header_type skip_60_t { fields { useless : 384; } }
header_type skip_64_t { fields { useless : 384; } }

header skip_4_t skip_4_i;
header skip_8_t skip_8_i;
header skip_12_t skip_12_i;
header skip_16_t skip_16_i;
header skip_20_t skip_20_i;
header skip_24_t skip_24_i;
header skip_28_t skip_28_i;
header skip_32_t skip_32_i;
header skip_36_t skip_36_i;
header skip_40_t skip_40_i;
header skip_4_t skip_4_o;
header skip_8_t skip_8_o;
header skip_12_t skip_12_o;
header skip_16_t skip_16_o;
header skip_20_t skip_20_o;
header skip_24_t skip_24_o;
header skip_28_t skip_28_o;
header skip_32_t skip_32_o;
header skip_36_t skip_36_o;
header skip_40_t skip_40_o;
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
 return ingress;
}
field_list port_lan_mac_hash {
 outer_ethernet.srcAddr;
}

field_list port_wan_mac_hash {
 outer_ethernet.dstAddr;
}

field_list_calculation port_lan_mac_hash_calc {
 input {
  port_lan_mac_hash;
 }
 algorithm : crc16;
 output_width : 16;
}

field_list_calculation port_wan_mac_hash_calc {
 input {
  port_wan_mac_hash;
 }
 algorithm : crc16;
 output_width : 16;
}

table determine_port_type {
 reads {

  ig_intr_md.ingress_port : exact;



 }
 actions {
  set_port_type;
  _drop;
 }
}


table determine_nat_lanwan_flag_and_linked_port {
 reads {

  ig_intr_md.ingress_port : exact;



 }
 actions {
  set_nat_lanwan_flag_and_linked_port;
  _nop;
 }
}

table calc_dpi_hash {
 reads {
  ebmeta.port_type : exact;


  ebmeta.is_nat : exact;



 }
 actions {
  calc_dpi_lan_mac_hash;
  calc_dpi_wan_mac_hash;
  _nop;
 }

}

table set_dpi_output {
 reads {
  ebmeta.port_type : exact;
  ebmeta.port_hash : exact;
 }
 actions {
  set_dpi_out_and_queue;
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

action set_nat_lanwan_flag_and_linked_port(is_lan, is_nat, linked_port) {
 modify_field(ebmeta.is_lan, is_lan);
 modify_field(ebmeta.is_nat, is_nat);
 modify_field(ebmeta.lanwan_out_port, linked_port);
}

action calc_dpi_lan_mac_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_lan_mac_hash_calc, 256);
}

action calc_dpi_wan_mac_hash() {
 modify_field_with_hash_based_offset(ebmeta.port_hash, 0, port_wan_mac_hash_calc, 256);
}

action set_dpi_out_and_queue(port, queue) {

 modify_field(ig_intr_md_for_tm.ucast_egress_port, port);



 modify_field(ebmeta.rss_queue, queue);
}

action do_add_ebheader() {
 add_header(ebheader);
 modify_field(ebheader.ethertype_eb, 0xEB);
 modify_field(ebheader.dst_main_out, ebmeta.lanwan_out_port);
 modify_field(ebheader.is_nat, ebmeta.is_nat);


 modify_field(ebheader.rss_queue, ebmeta.rss_queue);
 modify_field(ebheader.offset_mpls, ebmeta.offset_mpls);
 modify_field(ebheader.offset_payload, ebmeta.offset_payload);
 modify_field(ebheader.offset_ip1, ebmeta.offset_ip1);
 modify_field(ebheader.offset_ip2, ebmeta.offset_ip2);
}

action do_remove_ebheader() {
 modify_field(ebmeta.dst_mirror_agg, ebheader.dst_mirror_agg);
 modify_field(ebmeta.dst_mirror_out, ebheader.dst_mirror_out);
 remove_header(ebheader);
}


control ingress {

 apply(determine_port_type);


 apply(determine_nat_lanwan_flag_and_linked_port);
 apply(calc_dpi_hash);
 apply(set_dpi_output);



}

control egress {

 apply(add_ebheader);

 apply(remove_ebheader);
}
