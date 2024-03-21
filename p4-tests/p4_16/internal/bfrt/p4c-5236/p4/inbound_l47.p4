/*!
 * @file inbound_l47.p4
 * @brief lookup table for queue range, queue offset and queue mask
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"


control inbound_l47_gen_lookup(inout header_t hdr, 
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
        in ingress_metadata_t meta, 
        in  bit<16> ethertype,
       
        out bit<1> l47_match,
        out bit<1> timestamp_calc,
        out stats_index_t stat_index) {

  const bit<32> table_sz = 8192;// 16384 if we do exact match with SRAM
  stats_index_t index = 0;
  // need to implement 8K for v4 range, 2K or v6 range
  bit<9> lookup_5;
  bit<11> lookup_6;
  bit<14> lookup_7;
  bit<16> remap_addr_0 = 0;
  bit<16> remap_addr_1 = 0;
  bit<16> remap_addr_2 = 0;
  bit<16> remap_addr_3 = 0;
  bit<16> remap_addr_4 = 0;
  bit<16> remap_addr_5 = 0;
  bit<16> remap_addr_6;
  bit<16> remap_addr_7;
  bit<16> ternary_match_6 = 0;
  bit<1>  mac_match = 0;
  bit<32> range_addr = 0;
  bit<16> range_result = 0;
  bit<16> range_result_2 = 0;
  bit<1>  skip_range = 0;
  bit<4>  ingress_cos = 0;
  bit<4>  ingress_cos2 = 0;
  bit<1>  timestamp_calc_local;
  PortId_t local_mac_egPort;
  PortId_t local_ip_egPort;
  stats_index_t stat_index_local;

  Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identity_hash32_l;
  Register<range_pair, bit<16>>(size=1<<13, initial_value={0, 0}) range_reg;
  RegisterAction<range_pair, bit<16>, bit<16>>(range_reg)
  compare_range = {
      void apply(inout range_pair value, out bit<16> rv) {
          rv = this.predicate(value.start > range_addr, value.end < range_addr);
      }
   };

  Register<range_pair, bit<16>>(size=1<<11, initial_value={0, 0}) mac_range_reg;
  RegisterAction<range_pair, bit<16>, bit<16>>(mac_range_reg)
  compare_range2 = {
      void apply(inout range_pair value, out bit<16> rv) {
          rv = this.predicate(value.start > hdr.ethernet.dst_addr[31:0], value.end < hdr.ethernet.dst_addr[31:0]);
      }
   };
 /**********************************/
  
  action map_v6_address() {
    remap_addr_0 = meta.ipv6_dst_127_96[31:16];
    remap_addr_1 = meta.ipv6_dst_127_96[15:0];
    remap_addr_2 = meta.ipv6_dst_95_64[31:16];
    remap_addr_3 = meta.ipv6_dst_95_64[15:0];
    remap_addr_4 = meta.ipv6_dst_63_32[31:16];
    remap_addr_5 = meta.ipv6_dst_63_32[15:0];
    remap_addr_6 = meta.ip_dst_31_0[31:16];
    remap_addr_7 = meta.ip_dst_31_0[15:0];
  }

  action setMacRangePort( bit<1> timestamp_ext, PortId_t egPort,
    stats_index_t stats_index, bit<4> pfc_cos, bit<16> match_index)
  {
    timestamp_calc_local = timestamp_ext;
    stat_index_local = stats_index;
    ingress_cos = pfc_cos;
    range_result = compare_range2.execute(match_index);
    local_mac_egPort = egPort;
    mac_match = 1;
  }
  
  action setQueue()
  {
    timestamp_calc_local = 0;
    stat_index_local = 0;
    index = 0;
    local_mac_egPort = 0;
    mac_match = 0;
  }

  table EgressMacRangeCnTbl {
    key = {
      meta.vid_top : exact;
      meta.vid_bot : exact;
      hdr.vlan_tag_0.isValid(): exact;
      hdr.ethernet.dst_addr[47:32] : exact;
      hdr.ethernet.dst_addr[31:16] : ternary;
      hdr.ethernet.dst_addr[15:0] :ternary;
      ig_intr_md.ingress_port : exact;
    }
    actions = {
      setMacRangePort;
      setQueue;
    }
    default_action = setQueue;
    size = 2048;
  }

  action map_ternary( bit<16> match_index ) {
     ternary_match_6 = match_index;
  }

  table EgressTernaryTbl {
    key = {
      remap_addr_6 : ternary;
      remap_addr_7 : ternary;
      hdr.vlan_tag_0.isValid(): exact; 
      ig_intr_md.ingress_port : exact;
    } 
    actions = {
       map_ternary;
       NoAction;
    }
    default_action = NoAction;
    size = 8192;
  }

  action setRangePort( bit<1> timestamp_ext, PortId_t egPort,
    stats_index_t stats_index, bit<4> pfc_cos )
  {
    timestamp_calc = timestamp_ext;
    stat_index = stats_index;
    ingress_cos2 = pfc_cos;
    range_result_2 = compare_range.execute(ternary_match_6);
    local_ip_egPort = egPort;
  }

  action setQueue2()
  {
    timestamp_calc = timestamp_calc_local;
    stat_index = stat_index_local;
    ingress_cos2 = ingress_cos;
    range_result_2 = range_result;
    local_ip_egPort = local_mac_egPort;
  }

  table EgressRangeCnTbl {
    key = {
      meta.vid_top : exact;
      meta.vid_bot : exact;
      hdr.vlan_tag_0.isValid(): exact;
      remap_addr_0 : exact;
      remap_addr_1 : exact;
      remap_addr_2 : exact;
      remap_addr_3 : exact;
      remap_addr_4 : exact;
      remap_addr_5 : exact;
      ternary_match_6: exact;
      ig_intr_md.ingress_port : exact;
      mac_match               : exact;
    }
    actions = {
      setRangePort;
      setQueue2;
    }
    default_action = setQueue2;
    size = 8192;
  }

  action matchRangeEport()
  {
    l47_match = 1;
    ig_intr_tm_md.ucast_egress_port = local_ip_egPort;
  }

  action matchRangeWithVlan()
  {
    matchRangeEport();
    hdr.vlan_tag_0.pcp_cfi  = ingress_cos2;
  }

 action matchRangeInsertVlan()
  {
    matchRangeEport();
    hdr.ethernet.ether_type = 0x8100;
    hdr.vlan_tag_0.setValid();
    hdr.vlan_tag_0.vlan_top = 0xf;
    hdr.vlan_tag_0.vlan_bot = 0xff;
    hdr.vlan_tag_0.pcp_cfi  = ingress_cos2;
    hdr.vlan_tag_0.ether_type = ethertype;
  }
  
  table EgressRangecompare {
    key = {
      range_result_2  : exact;
      hdr.vlan_tag_0.isValid(): exact; 
    }
    actions = {
      matchRangeInsertVlan;
      matchRangeWithVlan;
      matchRangeEport;
      NoAction;
    }
    default_action = NoAction;
    size = 4;
  }

  /******************************/
  apply 
  {
    map_v6_address();
    range_addr = identity_hash32_l.get({remap_addr_6 +++ remap_addr_7});
    EgressMacRangeCnTbl.apply();
    EgressTernaryTbl.apply();
    EgressRangeCnTbl.apply();
    EgressRangecompare.apply();
  }
}

control inbound_l47_insert_vlan(inout header_t hdr, in bit<16> ethertype) {
  
  action map_ethertype()
  {
    hdr.vlan_tag_0.ether_type = ethertype;
    hdr.vlan_tag_0.vlan_top = 0xf;
    hdr.vlan_tag_0.vlan_bot = 0xff;
  }
  // push vlan label as the first label then swap the ethertype 
  action insertVlanOverhead() {
    hdr.ethernet.ether_type = 0x8100;
    hdr.vlan_tag_0.setValid();
    map_ethertype();
  }

  action insertVlan_1() {
    hdr.vlan_tag_1 = hdr.vlan_tag_0;
  }

  action insertVlan_2() {
    hdr.vlan_tag_2 = hdr.vlan_tag_1;
    hdr.vlan_tag_1 = hdr.vlan_tag_0;
  }

  /******************************/
  apply
  {
    if (hdr.vlan_tag_1.isValid())
    {
      insertVlan_2();
    }
    else if (hdr.vlan_tag_0.isValid())
    {
      insertVlan_1();
    }
    insertVlanOverhead();
    //map_ethertype();
  }
} 


control inbound_l47_calc_latency( inout header_t hdr,
                                  in ingress_intrinsic_metadata_t ig_intr_md,
                                  in bit<32> rx_tstamp,
                                  out bit<32> latency) {
  action calc_udp_timestamp() {
    latency = rx_tstamp - hdr.first_payload.signature_top;
  }

  action calc_udp_l47_timestamp() {
    latency = rx_tstamp - hdr.l47_tstamp.l47_tstamp;
  }

  action calc_tcp_timestamp() {
    latency = rx_tstamp - hdr.first_payload.signature_bot;
  }

  /*****************************************/
  apply
  {
    if ( hdr.l47_tstamp.isValid())
        calc_udp_l47_timestamp();
    else if (hdr.inner_tcp.isValid() || hdr.tcp.isValid() )
    {
        calc_tcp_timestamp();
    }
    else if (hdr.inner_udp.isValid() || hdr.udp.isValid() || hdr.icmp.isValid())
    {
        calc_udp_timestamp();
    }
  }
}
