header_type ingress_intrinsic_metadata_t {
    fields {
        resubmit_flag : 1;
        ingress_port : 9;
    }
}
header ingress_intrinsic_metadata_t ig_intr_md;
header_type egress_intrinsic_metadata_t {
    fields {
        _pad0 : 7;
        egress_port : 9;
        egress_cos : 3;
    }
}
@pragma dont_trim
header egress_intrinsic_metadata_t eg_intr_md;
header_type ebmeta_t {
 fields {
  lanwan_out_port : 9;
  is_nat : 1;
  rss_queue : 8;
  hash1 : 32;
  hash2 : 32;
  port_type : 3;
  flow_proto : 3;
  port_hash : 16;
 }
}
header_type ecolog_t {
 fields {
  etherType : 16;
 }
}
header_type ethernet_t {
 fields {
  dstAddr_lo : 32;
  srcAddr_lo : 32;
  etherType : 16;
 }
}
header_type ebheader_t {
 fields {
  _pad1 : 7;
  dst_main_out : 9;
  _pad2 : 7;
  dst_mirror_out : 9;
  flags_unused_bits : 6;
  is_nat : 1;
  is_lan : 1;
  rss_queue : 8;
  hash1 : 32;
  hash2 : 32;
 }
}
header_type ipv4_t {
 fields {
  ihl : 4;
  protocol : 8;
 }
}
header_type tcp_t {
 fields {
  portDst : 16;
 }
}
header_type udp_t {
 fields {
  portDst : 16;
 }
}
header_type udplite_t {
 fields {
  portDst : 16;
 }
}
header_type sctp_t {
 fields {
  portDst : 16;
 }
}
header_type pppoe_t {
 fields {
  protocol : 16;
 }
}
header_type ipv6_t {
 fields {
  nextHeader : 8;
 }
}
metadata ebmeta_t ebmeta;
header ethernet_t outer_ethernet;
header ebheader_t ebheader;
header ecolog_t ecolog;
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
header_type skip_36_t { fields { useless : 288; } }
header_type skip_40_t { fields { useless : 320; } }
header skip_4_t skip_4[3];
header skip_36_t skip_36[3];
header skip_40_t skip_40[3];
parser start {
 return select(current(96, 8)) {
  0xEC : parse_ecolog;
  0xEB : parse_ebheader;
  default : parse_outer_ethernet;
 }
}
parser parse_ecolog {
 extract(ecolog);
 return ingress;
}
parser parse_ebheader {
 extract(ebheader);
 return ingress;
}
parser parse_outer_ethernet {
 extract(outer_ethernet);
 return select(outer_ethernet.etherType) {
  0x8864 : parse_pppoe;
 }
}
parser parse_outer_ipv4 {
 extract(outer_ipv4);
 return select(outer_ipv4.ihl) {
  0x6: outer_ipv4_determine_after_skip_4;
  0xF: outer_ipv4_determine_after_skip_40;
 }
}
parser parse_outer_ipv6 {
 extract(outer_ipv6);
 return ingress;
}
parser outer_ipv4_determine_after {
 return select(outer_ipv4.protocol) {
  0x04 : parse_inner_ipv4;
  0x29 : parse_inner_ipv6;
 }
}
parser outer_ipv4_determine_after_skip_4 {
 extract(skip_4[0]);
 return outer_ipv4_determine_after;
}
parser outer_ipv4_determine_after_skip_40 {
 extract(skip_40[0]);
 return outer_ipv4_determine_after;
}
parser parse_inner_ipv4 {
 extract(inner_ipv4);
 return select(inner_ipv4.ihl) {
  0xE: inner_ipv4_determine_after_skip_36;
  0xF: inner_ipv4_determine_after_skip_40;
 }
}
parser parse_inner_ipv6 {
 extract(inner_ipv6);
 return select(inner_ipv6.nextHeader) {
  0x88 : parse_udplite;
  0x84 : parse_sctp;
  0x06 : parse_tcp;
  0x11 : parse_udp;
 }
}
parser parse_pppoe {
 extract(pppoe);
 return select (pppoe.protocol) {
  0x0021 : parse_outer_ipv4;
  0x0057 : parse_outer_ipv6;
 }
}
parser inner_ipv4_determine_after_skip_36 {
 extract(skip_36[1]);
 return ingress;
}
parser inner_ipv4_determine_after_skip_40 {
 extract(skip_40[1]);
 return ingress;
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
field_list flow_wan_ip4_hash {
 ebmeta.flow_proto;
}
field_list_calculation flow_wan_ip4_calc1 {
 input {
  flow_wan_ip4_hash;
 }
 algorithm : identity;
 output_width : 32;
}
field_list_calculation flow_wan_ip4_calc2 {
 input {
  flow_wan_ip4_hash;
 }
 algorithm : crc32_msb;
 output_width : 32;
}
table determine_port_type {
 reads {
  ig_intr_md.ingress_port : exact;
 }
 actions {
  set_port_type;
 }
}
table determine_nat_lanwan_flag_and_linked_port {
 reads {
  ig_intr_md.ingress_port : exact;
 }
 actions {
  set_nat_lanwan_flag_and_linked_port;
 }
}
table tbl_flow_hash_wan_ip4_1 {
 actions { calc_flow_hash_wan_ip4_1; }
}
table tbl_flow_hash_wan_ip4_2 {
 actions { calc_flow_hash_wan_ip4_2; }
}
table set_dpi_output {
 reads {
  ebmeta.port_hash : exact;
 }
 actions {
  set_dpi_out_and_queue;
 }
}
table add_ebheader {
 reads {
  ebmeta.port_type : exact;
 }
 actions {
  do_add_ebheader;
 }
}
action set_port_type(port_type) {
 modify_field(ebmeta.port_type, port_type);
}
action set_nat_lanwan_flag_and_linked_port(is_nat, linked_port) {
 modify_field(ebmeta.is_nat, is_nat);
 modify_field(ebmeta.lanwan_out_port, linked_port);
}
action calc_flow_hash_wan_ip4_1() {
 modify_field_with_hash_based_offset(ebmeta.hash1, 0, flow_wan_ip4_calc1, 4294967296);
}
action calc_flow_hash_wan_ip4_2() {
 modify_field_with_hash_based_offset(ebmeta.hash2, 0, flow_wan_ip4_calc2, 4294967296);
}
control calculate_flow_hashes {
    if (ebmeta.port_type == 2) {
        if (valid(outer_ipv4)) {
            apply(tbl_flow_hash_wan_ip4_1);
            apply(tbl_flow_hash_wan_ip4_2);
        }
    }
}
action set_dpi_out_and_queue(queue) {
 modify_field(ebmeta.rss_queue, queue);
}
action do_add_ebheader() {
 modify_field(ebheader.dst_main_out, ebmeta.lanwan_out_port);
 modify_field(ebheader.is_nat, ebmeta.is_nat);
 modify_field(ebheader.rss_queue, ebmeta.rss_queue);
 modify_field(ebheader.hash1, ebmeta.hash1);
 modify_field(ebheader.hash2, ebmeta.hash2);
}
control ingress {
 apply(determine_port_type);
 apply(determine_nat_lanwan_flag_and_linked_port);
 calculate_flow_hashes();
 apply(set_dpi_output);
}
control egress {
 apply(add_ebheader);
}
