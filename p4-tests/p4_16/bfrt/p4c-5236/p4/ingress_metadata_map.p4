/*!
 * @file ingress_metadata_map.p4
 * @brief map ingress metadata ( muxing inner ip, ip to metadata)
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"

control ingress_metadata_map(in header_t hdr, 
  in ingress_intrinsic_metadata_t ig_intr_md,
  inout ingress_metadata_t meta ) {
  
   bool inner_vlan;
   bool inner_ip;
  
   action setIpVlanMode(bool cfg_vlan, bool cfg_ip)
   {
     inner_vlan = cfg_vlan;
     inner_ip = cfg_ip;
   }
 
   action setDefaultConfig()
   {
      inner_vlan = false;
      inner_ip = false;
   }

  table FrontPanelConfigTbl {
    key = {
      ig_intr_md.ingress_port : exact;
    }
    actions = {
      setIpVlanMode;
      setDefaultConfig;
    }
    default_action = setDefaultConfig;
    size = 64;
  }
   
   action map_v4() 
   {
      meta.ip_src_31_0     = hdr.ipv4.src_addr;
      meta.ip_dst_31_0     = hdr.ipv4.dst_addr;
      meta.map_v4          = 1w1;
      meta.map_v6          = 1w0;
   }

   action map_v6() 
   {
      meta.ipv6_src_127_96 = hdr.ipv6.src_addr[127:96]; 
      meta.ipv6_src_95_64  = hdr.ipv6.src_addr[95:64];
      meta.ipv6_src_63_32  = hdr.ipv6.src_addr[63:32];
      meta.ip_src_31_0     = hdr.ipv6.src_addr[31:0];
      meta.ipv6_dst_127_96 = hdr.ipv6.dst_addr[127:96];
      meta.ipv6_dst_95_64  = hdr.ipv6.dst_addr[95:64];
      meta.ipv6_dst_63_32  = hdr.ipv6.dst_addr[63:32];
      meta.ip_dst_31_0     = hdr.ipv6.dst_addr[31:0];
      meta.map_v4          = 1w0;
      meta.map_v6          = 1w1;
   }

   action map_inner_v4()
   {
      meta.ip_src_31_0     = hdr.inner_ipv4.src_addr;
      meta.ip_dst_31_0     = hdr.inner_ipv4.dst_addr;
      meta.map_v4          = 1w1;
      meta.map_v6          = 1w0;
   }

   action map_inner_v6()
   {
      meta.ipv6_src_127_96 = hdr.inner_ipv6.src_addr[127:96]; 
      meta.ipv6_src_95_64  = hdr.inner_ipv6.src_addr[95:64];
      meta.ipv6_src_63_32  = hdr.inner_ipv6.src_addr[63:32];
      meta.ip_src_31_0     = hdr.inner_ipv6.src_addr[31:0];
      meta.ipv6_dst_127_96 = hdr.inner_ipv6.dst_addr[127:96];
      meta.ipv6_dst_95_64  = hdr.inner_ipv6.dst_addr[95:64];
      meta.ipv6_dst_63_32  = hdr.inner_ipv6.dst_addr[63:32];
      meta.ip_dst_31_0     = hdr.inner_ipv6.dst_addr[31:0];
      meta.map_v4          = 1w0;
      meta.map_v6          = 1w1;
   }

   action map_tcp()
   {
      meta.src_port = hdr.tcp.src_port & 0x7fff;
      meta.dst_port = hdr.tcp.dst_port & 0x7fff;
   }

   action map_udp()
   {
      meta.src_port = hdr.udp.src_port & 0x7fff;
      meta.dst_port = hdr.udp.dst_port & 0x7fff;
   }

   action map_inner_tcp()
   {
      meta.src_port = hdr.inner_tcp.src_port & 0x7fff;
      meta.dst_port = hdr.inner_tcp.dst_port & 0x7fff;
   }

   action map_inner_udp()
    {
      meta.src_port = hdr.inner_udp.src_port & 0x7fff;
      meta.dst_port = hdr.inner_udp.dst_port & 0x7fff;
    }

   table metadata_inner {
      key = { 
         hdr.ipv4.isValid() : ternary;
         hdr.ipv6.isValid() : ternary;
         hdr.inner_ipv4.isValid() : ternary;
         hdr.inner_ipv6.isValid() : ternary; 
      }
      actions = {
         map_v4;
         map_v6;
         map_inner_v6;
         map_inner_v4;
         NoAction; 
      }
      const entries = {
         (_,     _,    true,     _): map_inner_v4();
         (_,     _,   false,  true): map_inner_v6();
         (true,  _,   false, false): map_v4();
         (false, true,false, false): map_v6();
      }
   }

   table metadata_default {
      key = { 
         hdr.ipv4.isValid() : exact;
         hdr.ipv6.isValid() : exact;
      }
      actions = {
         map_v4;
         map_v6;
         NoAction; 
      }
      const entries = {
         (true,  false): map_v4();
         (false,  true): map_v6();
      }
   }

   table metadata_portmap {
      key = { 
         hdr.tcp.isValid() : ternary;
         hdr.udp.isValid() : ternary;
         hdr.inner_tcp.isValid() : ternary;
         hdr.inner_udp.isValid() : ternary; 
      }
      actions = {
         map_tcp;
         map_udp;
         map_inner_tcp;
         map_inner_udp;
         NoAction; 
      }
      const entries = {
         (_,     _,    true,     _): map_inner_tcp();
         (_,     _,   false,  true): map_inner_udp();
         (true,  _,   false, false): map_tcp();
         (false, true,false, false): map_udp();
      }
   }
   
   action map_vlan()
   {
      meta.vid_top = hdr.vlan_tag_0.vlan_top;
      meta.vid_bot = hdr.vlan_tag_0.vlan_bot;
   }

   action no_vlan()
   {
      meta.vid_top = 0;
      meta.vid_bot = 0;
   }

   action map_inner_vlan()
   {
      meta.vid_top = hdr.vlan_tag_1.vlan_top;
      meta.vid_bot = hdr.vlan_tag_1.vlan_bot;
   }

   table metadata_vlan {
      key = { 
         inner_vlan               : exact;
         hdr.vlan_tag_0.isValid() : exact;
         hdr.vlan_tag_1.isValid() : exact;
      }
      actions = {
         map_inner_vlan;
         map_vlan;
         no_vlan; 
      }
      const entries = {
         (true, true, true) : map_inner_vlan();
         (true, true, false): map_vlan();
         (true,  false, false): no_vlan;
         (false, true, true): map_vlan();
         (false, true, false): map_vlan();
         (false, false, false): no_vlan;
      }
   }
  /***************************************************/
  apply 
   {
      FrontPanelConfigTbl.apply();
      if (inner_ip)
         metadata_inner.apply();
      else
         metadata_default.apply();
      metadata_vlan.apply();
      //metadata_vlan.apply();
      metadata_portmap.apply();
   }
}
