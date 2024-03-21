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

control l2_offset_map(inout header_t hdr, in bit<8> mpls_offset, 
in ingress_metadata_t meta) {

   bit<8> l2_offset;
   action map_1()
   {
      l2_offset = mpls_offset + 1;
   }

   action map_2()
   {
      l2_offset = mpls_offset + 2;
   }

   action map_3()
   {
      l2_offset = mpls_offset + 3;
   }

   action map_4()
   {
      l2_offset = mpls_offset + 4;
   }

   action map_0()
   {
      l2_offset = mpls_offset ;
   }

    action map_0_noip() {
        l2_offset = mpls_offset;
    }

    action map_l2_offset()
    {
        hdr.bridge.l2_offset = l2_offset;
    }

   table map_l2offset_tbl{
      key = {
        hdr.vlan_tag_0.isValid(): ternary;
        hdr.vlan_tag_1.isValid(): ternary;
        hdr.vlan_tag_2.isValid(): ternary;
        hdr.snap.isValid(): exact;
      }
      actions = {
        map_1;
        map_2;
        map_3;
        map_4;
        map_0;
        map_0_noip;
      }
      const entries = {
        (true,  false, false, false): map_1();
        (false, true,  false, false): map_1();
        (true,  true,  false, false): map_2();
        (_,     true,  true,  false): map_2();
        (true,  false, false, true): map_3();
        (false, true,  false, true): map_3();
        (_,     true,  true,  true): map_4();
        (true,  true,  false, true): map_4();
        (false, false, false, false): map_0();
        (false, false, false, true): map_2();
        (false, false, false, false): map_0_noip;
      }
   }

    action map_udp () { hdr.bridge.flags_l3_protocol = 1;}
    action map_tcp() { hdr.bridge.flags_l3_protocol = 2;}
    action map_gre() { hdr.bridge.flags_l3_protocol = 3;}
    action map_gtp() { hdr.bridge.flags_l3_protocol = 4;}
    action map_inner_v4() { hdr.bridge.flags_l3_protocol = 5;}
    action map_inner_v6() { hdr.bridge.flags_l3_protocol = 6;}
    action map_icmp () { hdr.bridge.flags_l3_protocol = 7;}
    action no_l4() { hdr.bridge.flags_l3_protocol = 0;}

    table map_l3_offset_tbl {
      key = {
         hdr.udp.isValid(): exact;
         hdr.tcp.isValid(): exact;
         hdr.gre.isValid(): exact;
         hdr.gtp1.isValid(): exact;
         hdr.icmp.isValid(): exact;
         hdr.ipv4.isValid(): ternary;
         hdr.ipv6.isValid(): ternary;
         hdr.inner_ipv4.isValid(): ternary;
         hdr.inner_ipv6.isValid(): ternary;
         
      }
      actions = {
         map_udp;
         map_tcp;
         map_gre;
         map_gtp;
         map_inner_v4;
         map_inner_v6;
         map_icmp;
         no_l4;
      }
      const entries = {
         (true,  false, false, false, false, _, _, _, _): map_udp;
         (false, true,  false, false, false, _, _, _, _): map_tcp;
         (false, false, true,  false, false, _, _, _, _): map_gre;
         (true,  false, false, true,  false, _, _, _, _): map_gtp;
         (false,  false, false, false,  true, _, _, _, _): map_icmp;
         (true,  false, false, false, false, false, true, true, false): map_inner_v4;
         (false, false, false, false, false, true, false, false, true): map_inner_v6;
      }
      default_action = no_l4;
      size = 8;
   }


  /***************************************************/
  apply
   {
      map_l3_offset_tbl.apply();
      map_l2offset_tbl.apply();
      map_l2_offset();
   }
}
