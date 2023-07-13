/*!
 * @file outbound_l47.p4
 * @brief Remove MPLS (overhead) labels and sends the packet out
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"

control outbound_l47_insert_timestamp(inout eg_header_t hdr,
  inout egress_metadata_t eg_md, 
  in bit<32> egress_timestamp) {
  
  action insert_udp_timestamp() {
    hdr.first_payload.signature_top = egress_timestamp;
  }

  action insert_l47_timestamp() {
    hdr.l47_tstamp.l47_tstamp = egress_timestamp;
  }

  action insert_tcp_timestamp() {
    hdr.first_payload.signature_bot = egress_timestamp;
  }
  /*****************************************/
  apply
  {
    if (hdr.l47_tstamp.isValid())
        insert_l47_timestamp();
    else {
      if (hdr.first_payload.isValid()) {
        //insert_compute_node_timestampTbl.apply();
        if (hdr.inner_tcp.isValid() || hdr.tcp.isValid()) {
          insert_tcp_timestamp();
        }
        else if (hdr.inner_udp.isValid() || hdr.udp.isValid() || hdr.icmp.isValid()) {
          insert_udp_timestamp();
        }
      }
    }
    
  }
}

