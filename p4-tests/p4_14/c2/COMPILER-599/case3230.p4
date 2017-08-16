



#include "constants.p4"
#include "tofino/intrinsic_metadata.p4"
#include "tofino/primitives.p4"
#include "tofino/pktgen_headers.p4"
#include "tofino/stateful_alu_blackbox.p4"



header_type goto_header_t
{
  fields
  {
    table_id : 16;
  }
}

header goto_header_t goto_header;

header_type ether_t
{
  fields
  {
    ether_dstAddr : 48;
    ether_srcAddr : 48;
  }
}

header_type ether_end_t
{
  fields
  {
    ether_etherType : 16;
  }
}

header ether_t ether;
header ether_end_t ether_end;

header_type vlan_t
{
  fields
  {
    etherType : 16;
    PCP : 3;
    CFI : 1;
    VID : 12;
  }
}

header vlan_t OXM_OF_VLAN[5];

header_type arp_t
{
  fields
  {
    arp_htype : 16;
    arp_ptype : 16;
    arp_hlen : 8;
    arp_plen : 8;
    arp_opcode : 16;
    arp_sha : 48;
    arp_spa : 32;
    arp_tha : 48;
    arp_tpa : 32;
  }
}

header arp_t arp;

header_type mpls_t
{
  fields
  {
    LABEL : 20;
    TC : 3;
    BOS : 1;
    TTL : 8;
  }
}

header mpls_t OXM_OF_MPLS[5];

header_type ipv4_t
{
  fields
  {
    ipv4_version : 4;
    ipv4_ihl : 4;
    ipv4_dscp : 6;
    ipv4_enc : 2;
    ipv4_totalLen : 16;
    ipv4_identification : 16;
    ipv4_flags : 3;
    ipv4_fragOffset : 13;
    ipv4_ttl : 8;
    ipv4_protocol : 8;
    ipv4_checksum : 16;
    ipv4_srcAddr : 32;
    ipv4_dstAddr : 32;
  }
}

header ipv4_t ipv4;

header_type ipv4_skip_4_t { fields { useless : 32; } }
header_type ipv4_skip_8_t { fields { useless : 64; } }
header_type ipv4_skip_12_t { fields { useless : 96; } }
header_type ipv4_skip_16_t { fields { useless : 128; } }
header_type ipv4_skip_20_t { fields { useless : 160; } }
header_type ipv4_skip_24_t { fields { useless : 192; } }
header_type ipv4_skip_28_t { fields { useless : 224; } }
header_type ipv4_skip_32_t { fields { useless : 256; } }
header_type ipv4_skip_36_t { fields { useless : 288; } }
header_type ipv4_skip_40_t { fields { useless : 320; } }
header_type ipv4_skip_44_t { fields { useless : 352; } }
header_type ipv4_skip_48_t { fields { useless : 384; } }
header_type ipv4_skip_52_t { fields { useless : 416; } }
header_type ipv4_skip_56_t { fields { useless : 448; } }
header_type ipv4_skip_60_t { fields { useless : 480; } }
header_type ipv4_skip_64_t { fields { useless : 512; } }

header ipv4_skip_4_t ipv4_skip_4;
header ipv4_skip_8_t ipv4_skip_8;
header ipv4_skip_12_t ipv4_skip_12;
header ipv4_skip_16_t ipv4_skip_16;
header ipv4_skip_20_t ipv4_skip_20;
header ipv4_skip_24_t ipv4_skip_24;
header ipv4_skip_28_t ipv4_skip_28;
header ipv4_skip_32_t ipv4_skip_32;
header ipv4_skip_36_t ipv4_skip_36;
header ipv4_skip_40_t ipv4_skip_40;

header_type ipv6_t
{
  fields
  {
    ipv6_version : 4;
    ipv6_trafficClass : 8;
    ipv6_flowLabel : 20;
    ipv6_payloadLen : 16;
    ipv6_nextHeader : 8;
    ipv6_hopLimit : 8;
    ipv6_srcAddr : 128;
    ipv6_dstAddr : 128;
  }
}

header ipv6_t ipv6;

header_type icmpv4_t
{
  fields
  {
    icmpv4_type : 8;
    icmpv4_code : 8;
    icmpv4_checksum : 16;
  }
}

header icmpv4_t icmpv4;

header_type icmpv6_t
{
  fields
  {
    icmpv6_type : 8;
    icmpv6_code : 8;
    icmpv6_checksum : 16;
  }
}

header icmpv6_t icmpv6;

header_type tcp_t
{
  fields
  {
    tcp_srcPort : 16;
    tcp_dstPort : 16;
    tcp_seqNum : 32;
    tcp_ackNum : 32;
    tcp_dataOffset : 4;
    tcp_reserved : 3;
    tcp_ns : 1;
    tcp_cwr : 1;
    tcp_ece : 1;
    tcp_urg : 1;
    tcp_ack : 1;
    tcp_psh : 1;
    tcp_rst : 1;
    tcp_syn : 1;
    tcp_fin : 1;
    tcp_windowSize : 16;
    tcp_checksum : 16;
    tcp_urgentPtr : 16;
  }
}

header tcp_t tcp;

header_type udp_t
{
  fields
  {
    udp_srcPort : 16;
    udp_dstPort : 16;
    udp_len : 16;
    udp_checksum : 16;
  }
}

header udp_t udp;

header_type sctp_t
{
  fields
  {
    sctp_srcPort : 16;
    sctp_dstPort : 16;
    sctp_tag : 32;
    sctp_checksum : 32;
  }
}

header sctp_t sctp;


header_type OXM_OF_t
{
  fields
  {
    TABLE_ID : 16;
    IN_PORT : 9;
    ETH_DST : 48;
    ETH_SRC : 48;
    ETH_TYPE : 16;
    IP_DSCP : 6;
    IP_ECN : 2;
    IP_PROTO : 8;
    IPV4_SRC : 32;
    IPV4_DST : 32;
    TCP_SRC : 16;
    TCP_DST : 16;
    UDP_SRC : 16;
    UDP_DST : 16;
    SCTP_SRC : 16;
    SCTP_DST : 16;
    ICMPV4_TYPE : 8;
    ICMPV4_CODE : 8;
    ARP_OP : 16;
    ARP_SPA : 32;
    ARP_TPA : 32;
    ARP_SHA : 48;
    ARP_THA : 48;
    IPV6_SRC : 128;
    IPV6_DST : 128;
    IPV6_FLABEL : 20;
    ICMPV6_TYPE : 8;
    ICMPV6_CODE : 8;

    IPV6_ND_TARGET : 128;
    IPV6_ND_SLL : 48;
    IPV6_ND_TLL : 48;
    PBB_ISID : 24;
    IPV6_EXTHDR : 9;
  }
}

metadata OXM_OF_t OXM_OF;

header_type ecometa_t
{
  fields
  {
    _pad0 : 3;
    push_vlan : 1;
    pop_vlan : 1;
    push_mpls : 1;
    pop_mpls : 1;
    forward_controller : 1;
    goto_table : 16;
    vlan_pcp : 3;
    vlan_cfi : 1;
    vlan_vid : 12;
    vlan_type : 16;
    mpls_label : 20;
    mpls_tc : 3;
    mpls_bos : 1;
    mpls_ttl : 8;
    mpls_type : 16;
  }
}

metadata ecometa_t ecometa;


parser start
{
  return select(ig_intr_md.ingress_port)
  {
    68 mask 0x7C: parser_goto_header;
    default: parser_ether;
  }
}

parser parser_goto_header
{
  extract(goto_header);
  set_metadata(OXM_OF.TABLE_ID, latest.table_id);
  return parser_ether;
}

parser parser_ether
{
  extract(ether);
  set_metadata(OXM_OF.ETH_DST, latest.ether_dstAddr);
  set_metadata(OXM_OF.ETH_SRC, latest.ether_srcAddr);
  return select(current(0, 16))
  {
    0x8100: parser_vlan;
    0x88A8: parser_vlan;
    default: parser_ether_end;
  }
}

parser parser_vlan
{
  extract(OXM_OF_VLAN[next]);
  return select(current(0, 16))
  {
    0x8100: parser_vlan;
    0x88A8: parser_vlan;
    default: parser_ether_end;
  }
}

parser parser_ether_end
{
  extract(ether_end);
  set_metadata(OXM_OF.ETH_TYPE, latest.ether_etherType);
  return select(latest.ether_etherType)
  {
    0x0806: parser_arp;
    0x8847: parser_mpls;
    0x8848: parser_mpls;
    0x0800: parser_ipv4;
    0x86DD: parser_ipv6;
    default: ingress;
  }
}

parser parser_arp
{
  extract(arp);
  set_metadata(OXM_OF.ARP_OP, latest.arp_opcode);
  set_metadata(OXM_OF.ARP_SPA, latest.arp_spa);
  set_metadata(OXM_OF.ARP_TPA, latest.arp_tpa);
  set_metadata(OXM_OF.ARP_SHA, latest.arp_sha);
  set_metadata(OXM_OF.ARP_THA, latest.arp_tha);
  return ingress;
}

parser parser_mpls
{
  extract(OXM_OF_MPLS[next]);
  return select(latest.BOS)
  {
    1: parser_try_ip;
    default: parser_mpls;
  }
}

parser parser_try_ip
{
  return select(current(0, 4))
  {
    0x4: parser_ipv4;
    0x6: parser_ipv6;
    default: ingress;
  }
}

parser parser_ipv4
{
  extract(ipv4);
  set_metadata(OXM_OF.IP_DSCP, latest.ipv4_dscp);
  set_metadata(OXM_OF.IP_ECN, latest.ipv4_enc);
  set_metadata(OXM_OF.IP_PROTO, latest.ipv4_protocol);
  set_metadata(OXM_OF.IPV4_SRC, latest.ipv4_srcAddr);
  set_metadata(OXM_OF.IPV4_DST, latest.ipv4_dstAddr);
  return select(latest.ipv4_ihl)
  {
    0x0 mask 0x4: ingress;
    0x4 mask 0xF: ingress;
    0x5: parser_ipv4_proto;
    0x6: parser_ipv4_skip_4;
    0x7: parser_ipv4_skip_8;
    0x8: parser_ipv4_skip_12;
    0x9: parser_ipv4_skip_16;
    0xA: parser_ipv4_skip_20;
    0xB: parser_ipv4_skip_24;
    0xC: parser_ipv4_skip_28;
    0xD: parser_ipv4_skip_32;
    0xE: parser_ipv4_skip_36;
    0xF: parser_ipv4_skip_40;
    default: ingress;
  }
}

parser parser_ipv6
{
  extract(ipv6);
  set_metadata(OXM_OF.IP_PROTO, latest.ipv6_nextHeader);
  set_metadata(OXM_OF.IPV6_SRC, latest.ipv6_srcAddr);
  set_metadata(OXM_OF.IPV6_DST, latest.ipv6_dstAddr);
  set_metadata(OXM_OF.IPV6_FLABEL, latest.ipv6_flowLabel);
  return select(latest.ipv6_nextHeader)
  {
    0x3A: parser_icmpv6;
    0x06: parser_tcp;
    0x11: parser_udp;
    0x84: parser_sctp;
    default: ingress;
  }
}

parser parser_ipv4_skip_4
{
  extract(ipv4_skip_4);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_8
{
  extract(ipv4_skip_8);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_12
{
  extract(ipv4_skip_12);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_16
{
  extract(ipv4_skip_16);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_20
{
  extract(ipv4_skip_20);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_24
{
  extract(ipv4_skip_24);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_28
{
  extract(ipv4_skip_28);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_32
{
  extract(ipv4_skip_32);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_36
{
  extract(ipv4_skip_36);
  return parser_ipv4_proto;
}

parser parser_ipv4_skip_40
{
  extract(ipv4_skip_40);
  return parser_ipv4_proto;
}

parser parser_ipv4_proto
{
  return select(ipv4.ipv4_protocol)
  {
    0x01: parser_icmp;
    0x06: parser_tcp;
    0x11: parser_udp;
    0x84: parser_sctp;
    default: ingress;
  }
}

parser parser_icmp
{
  extract(icmpv4);
  set_metadata(OXM_OF.ICMPV4_TYPE, latest.icmpv4_type);
  set_metadata(OXM_OF.ICMPV4_CODE, latest.icmpv4_code);
  return ingress;
}

parser parser_icmpv6
{
  extract(icmpv6);
  set_metadata(OXM_OF.ICMPV6_TYPE, latest.icmpv6_type);
  set_metadata(OXM_OF.ICMPV6_CODE, latest.icmpv6_code);
  return ingress;
}

parser parser_tcp
{
  extract(tcp);
  set_metadata(OXM_OF.TCP_SRC, latest.tcp_srcPort);
  set_metadata(OXM_OF.TCP_DST, latest.tcp_dstPort);
  return ingress;
}

parser parser_udp
{
  extract(udp);
  set_metadata(OXM_OF.UDP_SRC, latest.udp_srcPort);
  set_metadata(OXM_OF.UDP_DST, latest.udp_dstPort);
  return ingress;
}

parser parser_sctp
{
  extract(sctp);
  set_metadata(OXM_OF.SCTP_SRC, latest.sctp_srcPort);
  set_metadata(OXM_OF.SCTP_DST, latest.sctp_dstPort);
  return ingress;
}

action set_output(port)
{
  modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
  modify_field(ecometa.goto_table, 0);
}

action set_output_controller()
{
  modify_field(ecometa.forward_controller, 1);
}

action set_output_flood(mgroup)
{
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 0x1FF);
  modify_field(ig_intr_md_for_tm.mcast_grp_a, mgroup);
}

action set_goto(table_id)
{
  recirculate(68);
  modify_field(ecometa.goto_table, table_id);
}

@pragma stage 0
table l2_flow_ether
{
  reads
  {
    ig_intr_md.ingress_port : ternary;
    OXM_OF.TABLE_ID : exact;
    OXM_OF.ETH_DST : ternary;
    OXM_OF.ETH_SRC : ternary;
    OXM_OF.ETH_TYPE : ternary;
  }
  actions
  {
    set_output;
    set_output_controller;
    set_output_flood;
    set_goto;
  }
  size : 2048;
}

@pragma stage 1
table l2_flow_vlan
{
  reads
  {
    OXM_OF.TABLE_ID : exact;
    OXM_OF_VLAN[0] : valid;
    OXM_OF_VLAN[0].PCP : ternary;
    OXM_OF_VLAN[0].CFI : ternary;
    OXM_OF_VLAN[0].VID : ternary;
  }
  actions
  {
    set_output;
    set_output_controller;
    set_output_flood;
    set_goto;
  }
  size : 2048;
}

@pragma stage 2
table l2_flow_mpls
{
  reads
  {
    OXM_OF.TABLE_ID : exact;
    OXM_OF_MPLS[0] : valid;
    OXM_OF_MPLS[0].LABEL : ternary;
    OXM_OF_MPLS[0].TC : ternary;
    OXM_OF_MPLS[0].BOS : ternary;
    OXM_OF_MPLS[0].TTL : ternary;
  }
  actions
  {
    set_output;
    set_output_controller;
    set_output_flood;
    set_goto;
  }
  size : 2048;
}

@pragma stage 3
table l3_flow_arp
{
  reads
  {
    OXM_OF.TABLE_ID : exact;
    arp : valid;
    OXM_OF.ARP_OP : ternary;
    OXM_OF.ARP_SPA : ternary;
    OXM_OF.ARP_TPA : ternary;
    OXM_OF.ARP_SHA : ternary;
    OXM_OF.ARP_THA : ternary;
  }
  actions
  {
    set_output;
    set_output_controller;
    set_output_flood;
    set_goto;
  }
  size : 2048;
}

action do_forward_controller(port)
{
  modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

@pragma stage 11
table forward_controller
{
  actions
  {
    do_forward_controller;
  }
  default_action : do_forward_controller;
  size : 1;
}

action do_del_goto_table()
{
  remove_header(goto_header);
}

action do_add_goto_table()
{
  add_header(goto_header);
  modify_field(goto_header.table_id, ecometa.goto_table);
}

table del_goto_table
{
  actions
  {
    do_del_goto_table;
  }
  default_action : do_del_goto_table;
  size : 1;
}

@pragma stage 0
table add_goto_table
{
  actions
  {
    do_add_goto_table;
  }
  default_action : do_add_goto_table;
  size : 1;
}

action do_push_vlan()
{
  push(OXM_OF_VLAN, 1);

  modify_field(OXM_OF_VLAN[0].etherType, ecometa.vlan_type);
  modify_field(OXM_OF_VLAN[0].PCP, ecometa.vlan_pcp);
  modify_field(OXM_OF_VLAN[0].CFI, ecometa.vlan_cfi);
  modify_field(OXM_OF_VLAN[0].VID, ecometa.vlan_vid);
}

action do_pop_vlan()
{
  pop(OXM_OF_VLAN, 1);
}

@pragma stage 1
table push_pop_vlan
{
  reads
  {
    ecometa.push_vlan : exact;
    ecometa.pop_vlan : exact;
  }
  actions
  {
    do_push_vlan;
    do_pop_vlan;
  }
  size : 2;
}

action do_push_mpls()
{
  push(OXM_OF_MPLS, 1);
  modify_field(OXM_OF_MPLS[0].LABEL, ecometa.mpls_label);
  modify_field(OXM_OF_MPLS[0].TC, ecometa.mpls_tc);
  modify_field(OXM_OF_MPLS[0].BOS, ecometa.mpls_bos);
  modify_field(OXM_OF_MPLS[0].TTL, ecometa.mpls_ttl);
  modify_field(ether_end.ether_etherType, ecometa.mpls_type);
}

action do_pop_mpls(etherType)
{
  pop(OXM_OF_MPLS, 1);
  modify_field(ether_end.ether_etherType, etherType);
}

@pragma stage 2
table push_pop_mpls
{
  reads
  {
    ecometa.push_mpls : exact;
    ecometa.pop_mpls : exact;
    ipv4 : valid;
    ipv6 : valid;
  }
  actions
  {
    do_push_mpls;
    do_pop_mpls;
  }
  size : 4;
}

control ingress
{
  apply(l2_flow_ether);
  apply(l2_flow_vlan);
  apply(l2_flow_mpls);
  apply(l3_flow_arp);

  if (ecometa.forward_controller == 1)
  {
    apply(forward_controller);
  }
}

control egress
{
  apply(push_pop_vlan);

  apply(push_pop_mpls);
}
