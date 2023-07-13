/*!
 * @file checksum_correction.p4
 * @brief checksum correcion
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"
control calculate_checksum(in egress_metadata_t eg_md, inout eg_header_t hdr,
                          in bit<32> collapsed_tstamp, in bit<32> global_tstamp) {

    //zero pad all the checksum to 32-bit
    bit<32> egress_timestamp;
    bit<32> cksm;
    bit<32> carry;
    bit<32> carry_2;  
    bit<16> org_cksm;
    bit<16> final;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_tx;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32_cksm;

    action sum_timestamp() 
    {
       egress_timestamp = collapsed_tstamp + identityHash32_tx.get(global_tstamp[31:16]);
    }

    action map_tcp_chksum()
    {
      org_cksm = hdr.tcp.checksum ;
    }

    action map_udp_chksum()
    {
      org_cksm = hdr.udp.checksum ;
    }

    action map_inner_udp_chksum() {
      org_cksm = hdr.inner_udp.checksum;
    }

    action map_inner_tcp_chksum() {
      org_cksm = hdr.inner_tcp.checksum;
    }

    table checksum_map_tbl{
      key = { 
        hdr.tcp.isValid() : ternary;
        hdr.udp.isValid() : ternary;
        hdr.inner_tcp.isValid() : ternary;
        hdr.inner_udp.isValid() : ternary; 
      }
      actions = {
        map_tcp_chksum;
        map_udp_chksum;
        map_inner_tcp_chksum;
        map_inner_udp_chksum;
        NoAction; 
      }
      const entries = {
         ( _,     _,    true,     _): map_inner_tcp_chksum;
         ( _,     _,   false,  true): map_inner_udp_chksum;
         ( true,  _,   false, false): map_tcp_chksum;
         ( false, true,false, false): map_udp_chksum;
      }
   }
   //negate original checksum to get the sum of all fields
   action invert_org() 
   {
      org_cksm = org_cksm ^ 0xffff;
   }

   action step_rx_4(){
      cksm = eg_md.bridge.sum_mac_timestamp;
    }
    
    action step_tx_4(){
      cksm = egress_timestamp; 
    }

   table initialize_cs_tbl{
       key = {
        eg_md.bridge.l23_rxtstmp_insert: exact;
        eg_md.bridge.l23_txtstmp_insert: exact;
        eg_md.bridge.l47_timestamp_insert: exact;
       }
       actions = {
        step_rx_4();
        step_tx_4();
        NoAction;
       }
       const entries = {
        (1, 0, 0): step_rx_4;
        (0, 1, 0): step_tx_4;
        (0, 0, 1): step_tx_4;
       }
    }

    action add_cksm_to_org()
    {
      cksm = cksm + identityHash32_cksm.get(org_cksm);
    }

    action shift_out_carry() {
      carry = cksm >> 16;
      cksm = cksm & 0xFFFF;
    }
    
    action add_carry() {
      cksm = cksm + carry;
    }

    action shift_out_carry_2() {
      carry_2 = cksm >> 16;
      cksm = cksm & 0xFFFF;
    }
    
    action add_carry_2() {
      cksm = cksm + carry_2;
    }

    action finalize_checksum()
    {
      final = (bit<16>)(cksm) ^ 0xffff;
    }

    action insert_tcp_chksum()
    {
      hdr.tcp.checksum = final;
    }

    action insert_udp_chksum()
    {
      hdr.udp.checksum = final;
    }

    action insert_inner_udp_chksum() {
      hdr.inner_udp.checksum = final;
    }

    action insert_inner_tcp_chksum() {
      hdr.inner_tcp.checksum = final;
    }

   table checksum_insert_tbl{
      key = { 
        hdr.tcp.isValid() : ternary;
        hdr.udp.isValid() : ternary;
        hdr.inner_tcp.isValid() : ternary;
        hdr.inner_udp.isValid() : ternary; 
      }
      actions = {
        insert_tcp_chksum;
        insert_udp_chksum;
        insert_inner_tcp_chksum;
        insert_inner_udp_chksum;
        NoAction; 
      }
      const entries = {
         ( _,     _,    true,     _): insert_inner_tcp_chksum;
         ( _,     _,   false,  true): insert_inner_udp_chksum;
         ( true,  _,   false, false): insert_tcp_chksum;
         ( false, true,false, false): insert_udp_chksum;
      }
   }

    apply
    {
      checksum_map_tbl.apply();
      invert_org();
      sum_timestamp();
      initialize_cs_tbl.apply();
      add_cksm_to_org();
      shift_out_carry();
      add_carry();
      shift_out_carry_2();
      add_carry_2();
      finalize_checksum();
      if (eg_md.bridge.l23_txtstmp_insert == 1 || eg_md.bridge.l47_timestamp_insert == 1 || eg_md.bridge.l23_rxtstmp_insert ==1)
        checksum_insert_tbl.apply();
    }
}

