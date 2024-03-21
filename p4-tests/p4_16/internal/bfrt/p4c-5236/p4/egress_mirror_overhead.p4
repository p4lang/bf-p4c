/*!
 * @file  egress_mirror_overhead.p4
 * @brief insert overhead in broadcast packet 
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"

control mirror_l47_insert_vlan(inout header_t hdr, in bit<4> ingress_port) {
  
  bit<16> ethertype;

  action get_ethetype()
  {
    ethertype = hdr.ethernet.ether_type;
  }

  action map_ethertype()
  {
    
    hdr.vlan_tag_0.vlan_bot = 0;
    hdr.vlan_tag_0.vlan_top = 0;
  }
  // push vlan label as the first label then swap the ethertype 
  action insertVlanOverhead() {
    hdr.vlan_tag_0.ether_type = hdr.ethernet.ether_type;
    hdr.ethernet.ether_type = 0x8100;
    hdr.vlan_tag_0.setValid();
    hdr.vlan_tag_0.pcp_cfi  = ingress_port;
    hdr.vlan_tag_0.vlan_bot = 255;
    hdr.vlan_tag_0.vlan_top = 0;
  }

  /******************************/
  apply
  {
    //get_ethetype();
    insertVlanOverhead();
    //map_ethertype();
  }
} 

