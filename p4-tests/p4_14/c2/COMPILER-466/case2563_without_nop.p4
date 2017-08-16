/*
gcc -E -x c -w -I/tmp/_MEIDUocqD/p4_lib -D__TARGET_TOFINO__ -I/tmp/_MEIDUocqD/p4_hlir/p4_lib /media/psf/Home/trees/bfn/p4examples/cases/002563/p4src/balancer.p4
*/



#include "tofino/constants.p4"
#include "tofino/intrinsic_metadata.p4"
#include "tofino/primitives.p4"
#include "tofino/pktgen_headers.p4"
#include "tofino/stateful_alu_blackbox.p4"









header_type ethernet_t {
 fields {
  dstAddr : 48;
  srcAddr : 48;
  etherType : 16;
 }
}

header_type ecolog_t {
 fields {
  unused : 96;
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
  flags_unused_bits : 4;
  is_fragment : 1;
  need_parse : 1;
  is_nat : 1;
  is_lan : 1;
  offset_ip1 : 8;
  offset_ip2 : 8;
  offset_mpls : 8;
  offset_payload : 8;
  ethertype_eb : 8;
  rss_queue : 8;
  flowhash_hi : 32;
  flowhash_lo : 32;
 }
}

header_type slow_proto_t {
 fields {
  subtype : 8;
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
  portSrc : 16;
  portDst : 16;
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

header_type need_parse_t {
 fields {
  useless : 8;
 }
}

header ethernet_t outer_ethernet;
header ethernet_t inner_ethernet;
header ebheader_t ebheader;
header ecolog_t ecolog;
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
header slow_proto_t slow_proto;
header need_parse_t need_parse;


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
header_type skip_60_t { fields { useless : 480; } }
header_type skip_64_t { fields { useless : 512; } }

header skip_4_t skip_4[3];
header skip_8_t skip_8[3];
header skip_12_t skip_12[3];
header skip_16_t skip_16[3];
header skip_20_t skip_20[3];
header skip_24_t skip_24[3];
header skip_28_t skip_28[3];
header skip_32_t skip_32[3];
header skip_36_t skip_36[3];
header skip_40_t skip_40[3];


parser start {
 return determine_first_parser;
}

parser determine_first_parser {
 return select(current(96, 8)) {
  0xEC : parse_ecolog;
  0xEB : parse_ebheader;
  default : parse_outer_ethernet;
 }
}

parser parse_need_parse {
 extract(need_parse);
 return ingress;
}

parser parse_ecolog {
 extract(ecolog);
 return ingress;
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
  0x0800 : parse_outer_ipv4;
  0x86DD : parse_outer_ipv6;
  0x8864 : parse_pppoe;
  0x8809 : parse_slow;
  default: ingress;
 }
}

parser parse_slow {
 extract(slow_proto);
 return ingress;
}

parser parse_inner_ethernet {
 extract(inner_ethernet);
 return select(inner_ethernet.etherType) {
  0x0800 : parse_outer_ipv4;
  0x86DD : parse_outer_ipv6;
  0x8864 : parse_pppoe;
  default : ingress;
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
  0x0800 : parse_outer_ipv4;
  0x86DD : parse_outer_ipv6;
  0x8864 : parse_pppoe;
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
  default : parse_inner_ethernet;
 }
}

parser parse_mpls_cw {
 extract(mpls_cw);
 return select (current(0, 8)) {
  0x45 : cw_try_ipv4;
  0x46 mask 0xFE : cw_try_ipv4;
  0x48 mask 0xF8 : cw_try_ipv4;
  0x60 mask 0xF0 : cw_try_ipv6;
  default : parse_inner_ethernet;
 }
}

parser cw_try_ipv4 {
 return select(current(72, 8)) {
  0x04 : parse_outer_ipv4;
  0x29 : parse_outer_ipv4;
  0x88 : parse_outer_ipv4;
  0x84 : parse_outer_ipv4;
  0x06 : parse_outer_ipv4;
  0x11 : parse_outer_ipv4;
  0x2F : parse_outer_ipv4;
  default : parse_inner_ethernet;
 }
}

parser cw_try_ipv6 {
 return select(current(48, 8)) {
  0x04 : parse_outer_ipv6;
  0x29 : parse_outer_ipv6;
  0x88 : parse_outer_ipv6;
  0x84 : parse_outer_ipv6;
  0x06 : parse_outer_ipv6;
  0x11 : parse_outer_ipv6;
  0x2F : parse_outer_ipv6;
  0 : parse_outer_ipv6;
  43 : parse_outer_ipv6;
  44 : parse_outer_ipv6;
  50 : parse_outer_ipv6;
  51 : parse_outer_ipv6;
  60 : parse_outer_ipv6;
  135 : parse_outer_ipv6;
  59 : parse_outer_ipv6;
  default : parse_inner_ethernet;
 }
}

parser parse_outer_ipv4 {
 extract(outer_ipv4);
 return select(outer_ipv4.ihl) {
  0x6: outer_ipv4_determine_after_skip_4;
  0x7: outer_ipv4_determine_after_skip_8;
  0x8: outer_ipv4_determine_after_skip_12;
  0x9: outer_ipv4_determine_after_skip_16;
  0xA: outer_ipv4_determine_after_skip_20;
  0xB: outer_ipv4_determine_after_skip_24;
  0xC: outer_ipv4_determine_after_skip_28;
  0xD: outer_ipv4_determine_after_skip_32;
  0xE: outer_ipv4_determine_after_skip_36;
  0xF: outer_ipv4_determine_after_skip_40;
  default: outer_ipv4_determine_after;
 }
}

parser parse_outer_ipv6 {
 extract(outer_ipv6);
 return select(outer_ipv6.nextHeader) {
  0x04 : parse_inner_ipv4;
  0x29 : parse_inner_ipv6;
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
  0x11 : parse_udp;
  default : parse_need_parse;
 }
}

parser outer_ipv4_determine_after {
 return select(outer_ipv4.protocol) {
  0x04 : parse_inner_ipv4;
  0x29 : parse_inner_ipv6;
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
  0x11 : parse_udp;
  default : ingress;
 }
}

parser outer_ipv4_determine_after_skip_4 {
 extract(skip_4[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_8 {
 extract(skip_8[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_12 {
 extract(skip_12[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_16 {
 extract(skip_16[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_20 {
 extract(skip_20[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_24 {
 extract(skip_24[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_28 {
 extract(skip_28[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_32 {
 extract(skip_32[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_36 {
 extract(skip_36[0]);
 return outer_ipv4_determine_after;
}

parser outer_ipv4_determine_after_skip_40 {
 extract(skip_40[0]);
 return outer_ipv4_determine_after;
}

parser parse_inner_ipv4 {
 extract(inner_ipv4);
 return select(inner_ipv4.ihl) {
  0x6: inner_ipv4_determine_after_skip_4;
  0x7: inner_ipv4_determine_after_skip_8;
  0x8: inner_ipv4_determine_after_skip_12;
  0x9: inner_ipv4_determine_after_skip_16;
  0xA: inner_ipv4_determine_after_skip_20;
  0xB: inner_ipv4_determine_after_skip_24;
  0xC: inner_ipv4_determine_after_skip_28;
  0xD: inner_ipv4_determine_after_skip_32;
  0xE: inner_ipv4_determine_after_skip_36;
  0xF: inner_ipv4_determine_after_skip_40;
  default: inner_ipv4_determine_after;
 }
}

parser inner_ipv4_determine_after {
 return select(inner_ipv4.protocol) {
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
  0x11 : parse_udp;
  default : ingress;
 }
}

parser parse_inner_ipv6 {
 extract(inner_ipv6);
 return select(inner_ipv6.nextHeader) {
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
  0x11 : parse_udp;
  default : parse_need_parse;
 }
}

parser parse_pppoe {
 extract(pppoe);
 return select (pppoe.protocol) {
  0x0021 : parse_outer_ipv4;
  0x0057 : parse_outer_ipv6;
  default : ingress;
 }
}

parser inner_ipv4_determine_after_skip_4 {
 extract(skip_4[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_8 {
 extract(skip_8[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_12 {
 extract(skip_12[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_16 {
 extract(skip_16[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_20 {
 extract(skip_20[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_24 {
 extract(skip_24[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_28 {
 extract(skip_28[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_32 {
 extract(skip_32[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_36 {
 extract(skip_36[1]);
 return inner_ipv4_determine_after;
}

parser inner_ipv4_determine_after_skip_40 {
 extract(skip_40[1]);
 return inner_ipv4_determine_after;
}

parser parse_tcp {
 extract(tcp);
 return ingress;
}
parser parse_udp {
 extract(udp);
 return ingress;
}
parser parse_sctp {
 extract(sctp);
 return ingress;
}
parser parse_udplite {
 extract(udplite);
 return ingress;
}



field_list list_lan_outer_mac_mag_hash {
 outer_ethernet.srcAddr;
 outer_ethernet.dstAddr;
}
field_list_calculation port_lan_outer_mac_mag_hash {
 input { list_lan_outer_mac_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_outer_mac_mag_hash {
 outer_ethernet.dstAddr;
 outer_ethernet.srcAddr;
}
field_list_calculation port_wan_outer_mac_mag_hash {
 input { list_wan_outer_mac_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_outer_mac_nat_hash {
 outer_ethernet.srcAddr;
}
field_list_calculation port_lan_outer_mac_nat_hash {
 input { list_lan_outer_mac_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_outer_mac_nat_hash {
 outer_ethernet.dstAddr;
}
field_list_calculation port_wan_outer_mac_nat_hash {
 input { list_wan_outer_mac_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_inner_mac_mag_hash {
 inner_ethernet.srcAddr;
 inner_ethernet.dstAddr;
}
field_list_calculation port_lan_inner_mac_mag_hash {
 input { list_lan_inner_mac_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_inner_mac_mag_hash {
 inner_ethernet.dstAddr;
 inner_ethernet.srcAddr;
}
field_list_calculation port_wan_inner_mac_mag_hash {
 input { list_wan_inner_mac_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_inner_mac_nat_hash {
 inner_ethernet.srcAddr;
}
field_list_calculation port_lan_inner_mac_nat_hash {
 input { list_lan_inner_mac_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_inner_mac_nat_hash {
 inner_ethernet.dstAddr;
}
field_list_calculation port_wan_inner_mac_nat_hash {
 input { list_wan_inner_mac_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_ipv4_nat_hash {
 outer_ipv4.srcAddr;
}
field_list_calculation port_lan_ipv4_nat_hash {
 input { list_lan_ipv4_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_ipv4_nat_hash {
 outer_ipv4.dstAddr;
}
field_list_calculation port_wan_ipv4_nat_hash {
 input { list_wan_ipv4_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_ipv4_mag_hash {
 outer_ipv4.srcAddr;
 outer_ipv4.dstAddr;
}
field_list_calculation port_lan_ipv4_mag_hash {
 input { list_lan_ipv4_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_ipv4_mag_hash {
 outer_ipv4.dstAddr;
 outer_ipv4.srcAddr;
}
field_list_calculation port_wan_ipv4_mag_hash {
 input { list_wan_ipv4_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_ipv6_nat_hash {
 outer_ipv6.srcAddr;
}
field_list_calculation port_lan_ipv6_nat_hash {
 input { list_lan_ipv6_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_ipv6_nat_hash {
 outer_ipv6.dstAddr;
}
field_list_calculation port_wan_ipv6_nat_hash {
 input { list_wan_ipv6_nat_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_lan_ipv6_mag_hash {
 outer_ipv6.srcAddr;
 outer_ipv6.dstAddr;
}
field_list_calculation port_lan_ipv6_mag_hash {
 input { list_lan_ipv6_mag_hash; }
 algorithm : crc16; output_width : 16;
}

field_list list_wan_ipv6_mag_hash {
 outer_ipv6.dstAddr;
 outer_ipv6.srcAddr;
}
field_list_calculation port_wan_ipv6_mag_hash {
 input { list_wan_ipv6_mag_hash; }
 algorithm : crc16; output_width : 16;
}


field_list flow_ipv4_hash_lan {
 outer_ipv4.srcAddr;
 outer_ipv4.dstAddr;
 ebmeta.flow_srcPort;
 ebmeta.flow_dstPort;
 ebmeta.flow_proto;
 ebmeta.is_nat;
}
field_list_calculation flow_lan_ipv4_calc_hi {
 input { flow_ipv4_hash_lan; }
 algorithm : crc32; output_width : 32;
}
field_list_calculation flow_lan_ipv4_calc_lo {
 input { flow_ipv4_hash_lan; }
 algorithm : crc_32c; output_width : 32;
}


field_list flow_ipv4_hash_wan {
 outer_ipv4.dstAddr;
 outer_ipv4.srcAddr;
 ebmeta.flow_dstPort;
 ebmeta.flow_srcPort;
 ebmeta.flow_proto;
 ebmeta.is_nat;
}
field_list_calculation flow_wan_ipv4_calc_hi {
 input { flow_ipv4_hash_wan; }
 algorithm : crc32; output_width : 32;
}
field_list_calculation flow_wan_ipv4_calc_lo {
 input { flow_ipv4_hash_wan; }
 algorithm : crc_32c; output_width : 32;
}


field_list flow_ipv6_hash_lan {
 outer_ipv6.srcAddr;
 outer_ipv6.dstAddr;
 ebmeta.flow_srcPort;
 ebmeta.flow_dstPort;
 ebmeta.flow_proto;
 ebmeta.is_nat;
}
field_list_calculation flow_lan_ipv6_calc_hi {
 input { flow_ipv6_hash_lan; }
 algorithm : crc32; output_width : 32;
}
field_list_calculation flow_lan_ipv6_calc_lo {
 input { flow_ipv6_hash_lan; }
 algorithm : crc_32c; output_width : 32;
}


field_list flow_ipv6_hash_wan {
 outer_ipv6.dstAddr;
 outer_ipv6.srcAddr;
 ebmeta.flow_dstPort;
 ebmeta.flow_srcPort;
 ebmeta.flow_proto;
 ebmeta.is_nat;
}
field_list_calculation flow_wan_ipv6_calc_hi {
 input { flow_ipv6_hash_wan; }
 algorithm : crc32; output_width : 32;
}
field_list_calculation flow_wan_ipv6_calc_lo {
 input { flow_ipv6_hash_wan; }
 algorithm : crc_32c; output_width : 32;
}


field_list flow_imac_hash_lan {
 inner_ethernet.srcAddr;
 inner_ethernet.dstAddr;
 ebmeta.is_nat;
}
field_list_calculation flow_lan_imac_calc_hi {
 input { flow_imac_hash_lan; }
 algorithm : crc32; output_width : 32;
}
field_list_calculation flow_lan_imac_calc_lo {
 input { flow_imac_hash_lan; }
 algorithm : crc_32c; output_width : 32;
}


field_list flow_imac_hash_wan {
 inner_ethernet.dstAddr;
 inner_ethernet.srcAddr;
 ebmeta.is_nat;
}
field_list_calculation flow_wan_imac_calc_hi {
 input { flow_imac_hash_wan; }
 algorithm : crc32; output_width : 32;
}
field_list_calculation flow_wan_imac_calc_lo {
 input { flow_imac_hash_wan; }
 algorithm : crc_32c; output_width : 32;
}


field_list flow_omac_hash_lan {
 outer_ethernet.srcAddr;
 outer_ethernet.dstAddr;
 ebmeta.is_nat;
}
field_list_calculation flow_lan_omac_calc_hi {
 input { flow_omac_hash_lan; }
 algorithm : crc32; output_width : 32;
}
field_list_calculation flow_lan_omac_calc_lo {
 input { flow_omac_hash_lan; }
 algorithm : crc_32c; output_width : 32;
}


field_list flow_omac_hash_wan {
 outer_ethernet.dstAddr;
 outer_ethernet.srcAddr;
 ebmeta.is_nat;
}
field_list_calculation flow_wan_omac_calc_hi {
 input { flow_omac_hash_wan; }
 algorithm : crc32; output_width : 32;
}
field_list_calculation flow_wan_omac_calc_lo {
 input { flow_omac_hash_wan; }
 algorithm : crc_32c; output_width : 32;
}



table outer_ipv4_is_fragment {
 reads {
  outer_ipv4 : valid;
  outer_ipv4.fragOffset : ternary;
 }
 actions {
  set_is_fragment;
  _nop;
 }
 size : 2;
}

table inner_ipv4_is_fragment {
 reads {
  inner_ipv4 : valid;
  inner_ipv4.fragOffset : ternary;
 }
 actions {
  set_is_fragment;
  _nop;
 }
 size : 2;
}


table calc_mpls_offset {
 reads {
  mpls[0] : valid;
  outer_vlan[0] : valid;
  outer_vlan[1] : valid;
  outer_vlan[2] : valid;
  outer_vlan[3] : valid;
  outer_vlan[4] : valid;
 }
 actions {
  set_mpls_offset;
 }
 size : 5;
}

table calc_outer_ip_offset {
 reads {
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  outer_vlan[0] : valid;
  outer_vlan[1] : valid;
  outer_vlan[2] : valid;
  outer_vlan[3] : valid;
  outer_vlan[4] : valid;
  mpls[0] : valid;
  mpls[1] : valid;
  mpls[2] : valid;
  mpls[3] : valid;
  mpls[4] : valid;
  mpls_cw : valid;
  inner_ethernet : valid;
  pppoe : valid;
 }
 actions {
  set_outer_ip_offset;
 }
 size : 32768;
}

table calc_inner_ip_offset_from_4 {
 reads {
  outer_ipv4 : valid;
  inner_ipv4 : valid;
  inner_ipv6 : valid;
  outer_ipv4.ihl : exact;
 }
 actions {
  set_inner_ip_offset;
  set_inner_ip_offset_same_as_outer;
 }
 default_action : set_inner_ip_offset_same_as_outer;
 size : 32;
}

table calc_inner_ip_offset_from_6 {
 reads {
  outer_ipv6 : valid;
  inner_ipv4 : valid;
  inner_ipv6 : valid;
 }
 actions {
  set_inner_ip_offset;
  set_inner_ip_offset_same_as_outer;
 }
 default_action : set_inner_ip_offset_same_as_outer;
 size : 2;
}

table calc_offsets_from_ipv4_to_l4 {
 reads {
  inner_ipv4 : valid;
  inner_ipv4.ihl : exact;
 }
 actions {
  set_payload_offset_l4;
 }
 size : 16;
}

table calc_offsets_from_ipv6_to_l4 {
 reads {
  inner_ipv6 : valid;
 }
 actions {
  set_payload_offset_l4;
 }
 size : 1;
}

table calc_offsets_from_l4_tcp {
 reads {
  tcp : valid;
  tcp.headerLen : exact;
 }
 actions {
  set_payload_offset;
 }
 size : 16;
}

table calc_offsets_from_l4 {
 reads {
  udp : valid;
  udplite : valid;
  sctp : valid;
 }
 actions {
  set_payload_offset;
 }
 size : 3;
}



table set_port_metadata {
 reads {
  ig_intr_md.ingress_port : exact;
 }
 actions {
  do_set_port_metadata;
  _drop;
 }
 default_action: _drop;
 size : 256;
}

table set_need_parse {
 reads {
  ebmeta.is_lanwan : exact;
  need_parse : valid;
 }
 actions {
  do_set_need_parse;
 }
 size : 1;
}



table bypass_mode {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  mark_bypass_mode;
 }
 size : 2;
}

table forward_lacp_bfd {
 reads {
  ebmeta.port_type : exact;
  slow_proto : valid;
  slow_proto.subtype : exact;
  udp : valid;
  udp.portDst : exact;
 }
 actions {
  mark_bypass_lacp_bfd;
 }
 size : 8;
}

table forward_multicast_mpls {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ethernet.etherType : exact;
 }
 actions {
  mark_bypass_multi_mpls;
 }
 size : 200;
}

table forward_multicast_ipv4 {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv4 : valid;
  outer_ipv4.dstAddr : lpm;
 }
 actions {
  mark_bypass_multi4;
 }
 size : 200;
}

table forward_multicast_ipv6 {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv6 : valid;
  outer_ipv6.dstAddr : lpm;
 }
 actions {
  mark_bypass_multi6;
 }
 size : 200;
}

table aggregate_bypass {
 reads {
  bypass_meta.mode_enabled : exact;
  bypass_meta.lacp_bfd : exact;
  bypass_meta.multi4 : exact;
  bypass_meta.multi6 : exact;
  bypass_meta.multi_mpls : exact;
 }
 actions {
  do_bypass;
 }
 size : 16;
}

table get_flow_ports {
 reads {
  tcp : valid;
  udp : valid;
  sctp : valid;
  udplite : valid;
 }
 actions {
  set_tcp_flow_data;
  set_udp_flow_data;
  set_sctp_flow_data;
  set_udplite_flow_data;
 }
 size : 4;
}


table tbl_dpi_lan_ipv4_hash {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv4 : valid;
 }
 actions {
  calc_dpi_lan_ipv4_nat_hash;
  calc_dpi_lan_ipv4_mag_hash;
 }
 size : 100;
}

table tbl_dpi_wan_ipv4_hash {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv4 : valid;
 }
 actions {
  calc_dpi_wan_ipv4_nat_hash;
  calc_dpi_wan_ipv4_mag_hash;
 }
 size : 100;
}

table tbl_dpi_lan_ipv6_hash {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv6 : valid;
 }
 actions {
  calc_dpi_lan_ipv6_nat_hash;
  calc_dpi_lan_ipv6_mag_hash;
 }
 size : 100;
}

table tbl_dpi_wan_ipv6_hash {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv6 : valid;
 }
 actions {
  calc_dpi_wan_ipv6_nat_hash;
  calc_dpi_wan_ipv6_mag_hash;
 }
 size : 100;
}

table tbl_dpi_lan_imac_hash {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_dpi_lan_inner_mac_nat_hash;
  calc_dpi_lan_inner_mac_mag_hash;
 }
 size : 100;
}

table tbl_dpi_wan_imac_hash {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_dpi_wan_inner_mac_nat_hash;
  calc_dpi_wan_inner_mac_mag_hash;
 }
 size : 100;
}

table tbl_dpi_lan_omac_hash {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_dpi_lan_outer_mac_nat_hash;
  calc_dpi_lan_outer_mac_mag_hash;
 }
 size : 100;
}

table tbl_dpi_wan_omac_hash {
 reads {
  ig_intr_md.ingress_port : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_dpi_wan_outer_mac_nat_hash;
  calc_dpi_wan_outer_mac_mag_hash;
 }
 size : 100;
}

table set_valid_hash {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  choose_lan_outer_mac_hash;
  choose_wan_outer_mac_hash;
  choose_lan_inner_mac_hash;
  choose_wan_inner_mac_hash;
  choose_lan_ipv4_hash;
  choose_wan_ipv4_hash;
  choose_lan_ipv6_hash;
  choose_wan_ipv6_hash;
 }
 size : 16;
}


table update_byte_counters {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_update_byte_counters;
 }
 size : 3;
}

table update_packet_counters {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_update_packet_counters;
 }
 size : 3;
}


table tbl_flow_hash_lan_ipv4_hi {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
 }
 actions {
  calc_flow_lan_ipv4_hi;
 }
 size : 1;
}
table tbl_flow_hash_lan_ipv4_lo {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
 }
 actions {
  calc_flow_lan_ipv4_lo;
 }
 size : 1;
}
table tbl_flow_hash_wan_ipv4_hi {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
 }
 actions {
  calc_flow_wan_ipv4_hi;
 }
 size : 1;
}
table tbl_flow_hash_wan_ipv4_lo {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
 }
 actions {
  calc_flow_wan_ipv4_lo;
 }
 size : 1;
}

table tbl_flow_hash_lan_ipv6_hi {
 reads {
  ebmeta.port_type : exact;
  outer_ipv6 : valid;
 }
 actions {
  calc_flow_lan_ipv6_hi;
 }
 size : 1;
}
table tbl_flow_hash_lan_ipv6_lo {
 reads {
  ebmeta.port_type : exact;
  outer_ipv6 : valid;
 }
 actions {
  calc_flow_lan_ipv6_lo;
 }
 size : 1;
}
table tbl_flow_hash_wan_ipv6_hi {
 reads {
  ebmeta.port_type : exact;
  outer_ipv6 : valid;
 }
 actions {
  calc_flow_wan_ipv6_hi;
 }
 size : 1;
}
table tbl_flow_hash_wan_ipv6_lo {
 reads {
  ebmeta.port_type : exact;
  outer_ipv6 : valid;
 }
 actions {
  calc_flow_wan_ipv6_lo;
 }
 size : 1;
}

table tbl_flow_hash_lan_imac_hi {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_flow_lan_imac_hi;
 }
 size : 1;
}
table tbl_flow_hash_lan_imac_lo {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_flow_lan_imac_lo;
 }
 size : 1;
}
table tbl_flow_hash_wan_imac_hi {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_flow_wan_imac_hi;
 }
 size : 1;
}
table tbl_flow_hash_wan_imac_lo {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_flow_wan_imac_lo;
 }
 size : 1;
}

table tbl_flow_hash_lan_omac_hi {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_flow_lan_omac_hi;
 }
 size : 1;
}
table tbl_flow_hash_lan_omac_lo {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_flow_lan_omac_lo;
 }
 size : 1;
}
table tbl_flow_hash_wan_omac_hi {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_flow_wan_omac_hi;
 }
 size : 1;
}
table tbl_flow_hash_wan_omac_lo {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  calc_flow_wan_omac_lo;
 }
 size : 1;
}


table set_flow_hash {
 reads {
  ebmeta.port_type : exact;
  outer_ipv4 : valid;
  outer_ipv6 : valid;
  inner_ethernet : valid;
 }
 actions {
  set_flow_hash_ipv4_lan;
  set_flow_hash_ipv4_wan;
  set_flow_hash_ipv6_lan;
  set_flow_hash_ipv6_wan;
  set_flow_hash_imac_lan;
  set_flow_hash_imac_wan;
  set_flow_hash_omac_lan;
  set_flow_hash_omac_wan;
 }
 size : 16;
}

table set_dpi_output {
 reads {
  ebmeta.is_lanwan : exact;
  ebmeta.port_hash : exact;
 }
 actions {
  set_dpi_out_and_queue;
 }
 size : 65536;
}


table forward_log {
 reads {
  ebmeta.port_type : exact;
  ecolog : valid;
  ecolog.etherType : exact;
 }
 actions {
  do_forward_log;
 }
 size : 32;
}

table drop_if_no_ebheader {
 reads {
  ebmeta.port_type : exact;
  ebheader : valid;
  ecolog : valid;
 }
 actions {
  _drop;
 }
 size : 2;
}

table dpi_set_egress_port {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  dpi_egress_port;
 }
 size : 2;
}


table add_ebheader {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_add_ebheader;
 }
 size : 2;
}


table remove_ebheader {
 reads {
  ebmeta.port_type : exact;
  ebheader : valid;
 }
 actions {
  do_remove_ebheader;
 }
 size : 2;
}


header_type ebmeta_t {
 fields {
  _pad1 : 12;
  lanwan_out_port : 9;
  dpi_port : 9;
  dst_mirror_agg : 9;
  dst_mirror_out : 9;
  _pad2 : 12;
  is_fragment : 1;
  need_parse : 1;
  is_nat : 1;
  is_lan : 1;
  offset_ip1 : 8;
  offset_ip2 : 8;
  offset_mpls : 8;
  offset_payload : 8;
  rss_queue : 8;
  port_type : 3;
  is_lanwan : 1;
  _pad3 : 4;
  port_hash : 16;
  flowhash : 32;
  flowhash_hi : 16;
  flowhash_lo : 16;
  flow_proto : 3;
  flow_srcPort : 16;
  flow_dstPort : 16;
 }
}

header_type bypass_meta_t {
 fields {
  mode_enabled : 1;
  lacp_bfd : 1;
  multi4 : 1;
  multi6 : 1;
  multi_mpls : 1;
 }
}

header_type dpihash_meta_t {
 fields {
  ipv4_lan_hash : 16;
  ipv4_wan_hash : 16;
  ipv6_lan_hash : 16;
  ipv6_wan_hash : 16;
  imac_lan_hash : 16;
  imac_wan_hash : 16;
  omac_lan_hash : 16;
  omac_wan_hash : 16;
 }
}

header_type flowhash_meta_t {
 fields {
  ipv4_lan_hi : 32;
  ipv4_lan_lo : 32;
  ipv4_wan_hi : 32;
  ipv4_wan_lo : 32;
  ipv6_lan_hi : 32;
  ipv6_lan_lo : 32;
  ipv6_wan_hi : 32;
  ipv6_wan_lo : 32;
  imac_lan_hi : 32;
  imac_lan_lo : 32;
  imac_wan_hi : 32;
  imac_wan_lo : 32;
  omac_lan_hi : 32;
  omac_lan_lo : 32;
  omac_wan_hi : 32;
  omac_wan_lo : 32;
 }
}

header_type offset_meta_t {
 fields {
  vlan_length : 8;
  mpls_length : 8;
  pppoe_length : 8;
  inner_ethernet_length : 8;
  outer_ip_length : 8;
  inner_ip_length : 8;
 }
}

@pragma pa_solitary ingress ebmeta.lanwan_out_port
metadata ebmeta_t ebmeta;
metadata bypass_meta_t bypass_meta;
metadata flowhash_meta_t flowhash_meta;
metadata dpihash_meta_t dpihash_meta;
metadata offset_meta_t offset_meta;


counter per_hash_bytes_ctr {
 type : bytes;
 static : update_byte_counters;
 instance_count : 65536;
}

counter per_hash_packets_ctr {
 type : packets;
 static : update_packet_counters;
 instance_count : 65536;
}


action _nop() { no_op(); }
action _drop() { drop(); }



action set_is_fragment() {
 modify_field(ebmeta.is_fragment, 1);
}



action set_mpls_offset(off) {
 modify_field(ebmeta.offset_mpls, off);
}

action set_outer_ip_offset(off) {
 modify_field(ebmeta.offset_ip1, off);
}

action set_inner_ip_offset(off) {
 add(ebmeta.offset_ip2, ebmeta.offset_ip1, off);
}

action set_inner_ip_offset_same_as_outer() {
 modify_field(ebmeta.offset_ip2, ebmeta.offset_ip1);
}

action set_payload_offset_l4(len) {
 add(ebmeta.offset_payload, ebmeta.offset_ip2, len);
}

action set_payload_offset(len) {
 add(ebmeta.offset_payload, ebmeta.offset_payload, len);
}



action do_set_need_parse() {
 modify_field(ebmeta.need_parse, 1);
}

action do_set_port_metadata(port_type, is_lan, is_nat, linked_port, is_lanwan) {
 modify_field(ebmeta.port_type, port_type);
 modify_field(ebmeta.is_lan, is_lan);
 modify_field(ebmeta.is_nat, is_nat);
 modify_field(ebmeta.lanwan_out_port, linked_port);
 modify_field(ebmeta.is_lanwan, is_lanwan);
}

action do_forward_log(out_port) {
 modify_field(ebmeta.port_type, 4);
 modify_field(ig_intr_md_for_tm.ucast_egress_port, out_port);
}

action do_bypass() {
 modify_field(ebmeta.port_type, 4);
 modify_field(ig_intr_md_for_tm.ucast_egress_port, ebmeta.lanwan_out_port);
}

action mark_bypass_mode() {
 modify_field(bypass_meta.mode_enabled, 1);
}

action mark_bypass_lacp_bfd() {
 modify_field(bypass_meta.lacp_bfd, 1);
}

action mark_bypass_multi4() {
 modify_field(bypass_meta.multi4, 1);
}

action mark_bypass_multi6() {
 modify_field(bypass_meta.multi6, 1);
}

action mark_bypass_multi_mpls() {
 modify_field(bypass_meta.multi_mpls, 1);
}


action calc_dpi_lan_outer_mac_nat_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.omac_lan_hash, 0, port_lan_outer_mac_nat_hash, 65536);
}
action calc_dpi_lan_outer_mac_mag_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.omac_lan_hash, 0, port_lan_outer_mac_mag_hash, 65536);
}
action calc_dpi_wan_outer_mac_nat_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.omac_wan_hash, 0, port_wan_outer_mac_nat_hash, 65536);
}
action calc_dpi_wan_outer_mac_mag_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.omac_wan_hash, 0, port_wan_outer_mac_mag_hash, 65536);
}
action calc_dpi_lan_inner_mac_nat_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.imac_lan_hash, 0, port_lan_inner_mac_nat_hash, 65536);
}
action calc_dpi_lan_inner_mac_mag_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.imac_lan_hash, 0, port_lan_inner_mac_mag_hash, 65536);
}
action calc_dpi_wan_inner_mac_nat_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.imac_wan_hash, 0, port_wan_inner_mac_nat_hash, 65536);
}
action calc_dpi_wan_inner_mac_mag_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.imac_wan_hash, 0, port_wan_inner_mac_mag_hash, 65536);
}
action calc_dpi_lan_ipv4_nat_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.ipv4_lan_hash, 0, port_lan_ipv4_nat_hash, 65536);
}
action calc_dpi_lan_ipv4_mag_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.ipv4_lan_hash, 0, port_lan_ipv4_mag_hash, 65536);
}
action calc_dpi_wan_ipv4_nat_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.ipv4_wan_hash, 0, port_wan_ipv4_nat_hash, 65536);
}
action calc_dpi_wan_ipv4_mag_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.ipv4_wan_hash, 0, port_wan_ipv4_mag_hash, 65536);
}
action calc_dpi_lan_ipv6_nat_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.ipv6_lan_hash, 0, port_lan_ipv6_nat_hash, 65536);
}
action calc_dpi_lan_ipv6_mag_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.ipv6_lan_hash, 0, port_lan_ipv6_mag_hash, 65536);
}
action calc_dpi_wan_ipv6_nat_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.ipv6_wan_hash, 0, port_wan_ipv6_nat_hash, 65536);
}
action calc_dpi_wan_ipv6_mag_hash() {
 modify_field_with_hash_based_offset(dpihash_meta.ipv6_wan_hash, 0, port_wan_ipv6_mag_hash, 65536);
}

action choose_lan_outer_mac_hash() {
 modify_field(ebmeta.port_hash, dpihash_meta.omac_lan_hash);
}
action choose_wan_outer_mac_hash() {
 modify_field(ebmeta.port_hash, dpihash_meta.omac_wan_hash);
}
action choose_lan_inner_mac_hash() {
 modify_field(ebmeta.port_hash, dpihash_meta.imac_lan_hash);
}
action choose_wan_inner_mac_hash() {
 modify_field(ebmeta.port_hash, dpihash_meta.imac_wan_hash);
}
action choose_lan_ipv4_hash() {
 modify_field(ebmeta.port_hash, dpihash_meta.ipv4_lan_hash);
}
action choose_wan_ipv4_hash() {
 modify_field(ebmeta.port_hash, dpihash_meta.ipv4_wan_hash);
}
action choose_lan_ipv6_hash() {
 modify_field(ebmeta.port_hash, dpihash_meta.ipv6_lan_hash);
}
action choose_wan_ipv6_hash() {
 modify_field(ebmeta.port_hash, dpihash_meta.ipv6_wan_hash);
}


action do_update_byte_counters() {
    count(per_hash_bytes_ctr, ebmeta.port_hash);
}


action do_update_packet_counters() {
    count(per_hash_packets_ctr, ebmeta.port_hash);
}


action set_tcp_flow_data() {
 modify_field(ebmeta.flow_proto, 1);
 modify_field(ebmeta.flow_srcPort, tcp.portSrc);
 modify_field(ebmeta.flow_dstPort, tcp.portDst);
}

action set_udp_flow_data() {
 modify_field(ebmeta.flow_proto, 2);
 modify_field(ebmeta.flow_srcPort, udp.portSrc);
 modify_field(ebmeta.flow_dstPort, udp.portDst);
}

action set_sctp_flow_data() {
 modify_field(ebmeta.flow_proto, 3);
 modify_field(ebmeta.flow_srcPort, sctp.portSrc);
 modify_field(ebmeta.flow_dstPort, sctp.portDst);
}

action set_udplite_flow_data() {
 modify_field(ebmeta.flow_proto, 4);
 modify_field(ebmeta.flow_srcPort, udplite.portSrc);
 modify_field(ebmeta.flow_dstPort, udplite.portDst);
}

action calc_flow_lan_ipv4_hi() {
 modify_field_with_hash_based_offset(flowhash_meta.ipv4_lan_hi, 0, flow_lan_ipv4_calc_hi, 4294967296);
}
action calc_flow_lan_ipv4_lo() {
 modify_field_with_hash_based_offset(flowhash_meta.ipv4_lan_lo, 0, flow_lan_ipv4_calc_lo, 4294967296);
}
action calc_flow_wan_ipv4_hi() {
 modify_field_with_hash_based_offset(flowhash_meta.ipv4_wan_hi, 0, flow_wan_ipv4_calc_hi, 4294967296);
}
action calc_flow_wan_ipv4_lo() {
 modify_field_with_hash_based_offset(flowhash_meta.ipv4_wan_lo, 0, flow_wan_ipv4_calc_lo, 4294967296);
}
action calc_flow_lan_ipv6_hi() {
 modify_field_with_hash_based_offset(flowhash_meta.ipv6_lan_hi, 0, flow_lan_ipv6_calc_hi, 4294967296);
}
action calc_flow_lan_ipv6_lo() {
 modify_field_with_hash_based_offset(flowhash_meta.ipv6_lan_lo, 0, flow_lan_ipv6_calc_lo, 4294967296);
}
action calc_flow_wan_ipv6_hi() {
 modify_field_with_hash_based_offset(flowhash_meta.ipv6_wan_hi, 0, flow_wan_ipv6_calc_hi, 4294967296);
}
action calc_flow_wan_ipv6_lo() {
 modify_field_with_hash_based_offset(flowhash_meta.ipv6_wan_lo, 0, flow_wan_ipv6_calc_lo, 4294967296);
}
action calc_flow_lan_imac_hi() {
 modify_field_with_hash_based_offset(flowhash_meta.imac_lan_hi, 0, flow_lan_imac_calc_hi, 4294967296);
}
action calc_flow_lan_imac_lo() {
 modify_field_with_hash_based_offset(flowhash_meta.imac_lan_lo, 0, flow_lan_imac_calc_lo, 4294967296);
}
action calc_flow_wan_imac_hi() {
 modify_field_with_hash_based_offset(flowhash_meta.imac_wan_hi, 0, flow_wan_imac_calc_hi, 4294967296);
}
action calc_flow_wan_imac_lo() {
 modify_field_with_hash_based_offset(flowhash_meta.imac_wan_lo, 0, flow_wan_imac_calc_lo, 4294967296);
}
action calc_flow_lan_omac_hi() {
 modify_field_with_hash_based_offset(flowhash_meta.omac_lan_hi, 0, flow_lan_omac_calc_hi, 4294967296);
}
action calc_flow_lan_omac_lo() {
 modify_field_with_hash_based_offset(flowhash_meta.omac_lan_lo, 0, flow_lan_omac_calc_lo, 4294967296);
}
action calc_flow_wan_omac_hi() {
 modify_field_with_hash_based_offset(flowhash_meta.omac_wan_hi, 0, flow_wan_omac_calc_hi, 4294967296);
}
action calc_flow_wan_omac_lo() {
 modify_field_with_hash_based_offset(flowhash_meta.omac_wan_lo, 0, flow_wan_omac_calc_lo, 4294967296);
}

action set_flow_hash_ipv4_lan() {
 modify_field(ebmeta.flowhash_hi, flowhash_meta.ipv4_lan_hi);
 modify_field(ebmeta.flowhash_lo, flowhash_meta.ipv4_lan_lo);
}
action set_flow_hash_ipv4_wan() {
 modify_field(ebmeta.flowhash_hi, flowhash_meta.ipv4_wan_hi);
 modify_field(ebmeta.flowhash_lo, flowhash_meta.ipv4_wan_lo);
}
action set_flow_hash_ipv6_lan() {
 modify_field(ebmeta.flowhash_hi, flowhash_meta.ipv6_lan_hi);
 modify_field(ebmeta.flowhash_lo, flowhash_meta.ipv6_lan_lo);
}
action set_flow_hash_ipv6_wan() {
 modify_field(ebmeta.flowhash_hi, flowhash_meta.ipv6_wan_hi);
 modify_field(ebmeta.flowhash_lo, flowhash_meta.ipv6_wan_lo);
}
action set_flow_hash_imac_lan() {
 modify_field(ebmeta.flowhash_hi, flowhash_meta.imac_lan_hi);
 modify_field(ebmeta.flowhash_lo, flowhash_meta.imac_lan_lo);
}
action set_flow_hash_imac_wan() {
 modify_field(ebmeta.flowhash_hi, flowhash_meta.imac_wan_hi);
 modify_field(ebmeta.flowhash_lo, flowhash_meta.imac_wan_lo);
}
action set_flow_hash_omac_lan() {
 modify_field(ebmeta.flowhash_hi, flowhash_meta.omac_lan_hi);
 modify_field(ebmeta.flowhash_lo, flowhash_meta.omac_lan_lo);
}
action set_flow_hash_omac_wan() {
 modify_field(ebmeta.flowhash_hi, flowhash_meta.omac_wan_hi);
 modify_field(ebmeta.flowhash_lo, flowhash_meta.omac_wan_lo);
}

action set_dpi_out_and_queue(port, queue) {
 modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
 modify_field(ebmeta.rss_queue, queue);
}

action dpi_egress_port() {
 modify_field(ig_intr_md_for_tm.ucast_egress_port, ebheader.dst_main_out);
}

action do_add_ebheader() {
 add_header(ebheader);
 modify_field(ebheader.ethertype_eb, 0xEB);
 modify_field(ebheader.dst_main_out, ebmeta.lanwan_out_port);
 modify_field(ebheader.is_fragment, ebmeta.is_fragment);
 modify_field(ebheader.need_parse, ebmeta.need_parse);
 modify_field(ebheader.is_nat, ebmeta.is_nat);
 modify_field(ebheader.is_lan, ebmeta.is_lan);
 modify_field(ebheader.rss_queue, ebmeta.rss_queue);
 modify_field(ebheader.offset_mpls, ebmeta.offset_mpls);
 modify_field(ebheader.offset_payload, ebmeta.offset_payload);
 modify_field(ebheader.offset_ip1, ebmeta.offset_ip1);
 modify_field(ebheader.offset_ip2, ebmeta.offset_ip2);
 modify_field(ebheader.flowhash_hi, ebmeta.flowhash_hi);
 modify_field(ebheader.flowhash_lo, ebmeta.flowhash_lo);
}

action do_remove_ebheader() {
 modify_field(ebmeta.dst_mirror_agg, ebheader.dst_mirror_agg);
 modify_field(ebmeta.dst_mirror_out, ebheader.dst_mirror_out);
 remove_header(ebheader);
}


control update_counters {
 apply(update_byte_counters);
 apply(update_packet_counters);
}

control calculate_offsets {
 if (ebmeta.is_lanwan == 1) {
  apply(calc_mpls_offset);
  apply(calc_outer_ip_offset);
  apply(calc_inner_ip_offset_from_4);
  apply(calc_inner_ip_offset_from_6);
  apply(calc_offsets_from_ipv4_to_l4);
  apply(calc_offsets_from_ipv6_to_l4);
  apply(calc_offsets_from_l4_tcp);
  apply(calc_offsets_from_l4);
 }
}

control ingress {


 apply(tbl_dpi_lan_ipv4_hash);
 apply(tbl_dpi_wan_ipv4_hash);
 apply(tbl_dpi_lan_ipv6_hash);
 apply(get_flow_ports);
 apply(set_port_metadata);


 apply(set_need_parse);
 apply(bypass_mode);
 apply(forward_lacp_bfd);
 apply(forward_multicast_mpls);
 apply(forward_multicast_ipv4);
 apply(forward_multicast_ipv6);

 apply(tbl_dpi_wan_ipv6_hash);
 apply(tbl_dpi_lan_imac_hash);
 apply(tbl_dpi_lan_omac_hash);


 apply(aggregate_bypass);
 apply(tbl_dpi_wan_imac_hash);
 apply(tbl_dpi_wan_omac_hash);


 apply(outer_ipv4_is_fragment);
 apply(tbl_flow_hash_lan_ipv4_hi);
 apply(tbl_flow_hash_lan_ipv4_lo);
 apply(tbl_flow_hash_wan_ipv4_hi);
 apply(set_valid_hash);


 apply(inner_ipv4_is_fragment);
 apply(tbl_flow_hash_lan_ipv6_hi);
 apply(tbl_flow_hash_lan_ipv6_lo);
 apply(tbl_flow_hash_wan_ipv4_lo);
 update_counters();
 apply(set_dpi_output);


 apply(tbl_flow_hash_wan_ipv6_hi);
 apply(tbl_flow_hash_wan_ipv6_lo);
 apply(tbl_flow_hash_lan_imac_lo);


 apply(tbl_flow_hash_lan_imac_hi);
 apply(tbl_flow_hash_wan_imac_lo);
 apply(tbl_flow_hash_wan_imac_hi);


 apply(tbl_flow_hash_lan_omac_hi);
 apply(tbl_flow_hash_lan_omac_lo);
 apply(tbl_flow_hash_wan_omac_hi);


 apply(tbl_flow_hash_wan_omac_lo);


 apply(set_flow_hash);


 apply(forward_log);
 apply(drop_if_no_ebheader);
 apply(dpi_set_egress_port);
}

control egress {
 calculate_offsets();


 apply(add_ebheader);

 apply(remove_ebheader);
}
