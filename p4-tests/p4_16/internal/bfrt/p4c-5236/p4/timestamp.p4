/*!
 * @file timestamp.p4
 * @brief insert timestamp for L23
 */
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "headers.p4"

control timestamp_insertion(inout eg_header_t hdr,
                            inout egress_metadata_t eg_md,
                            in bit<32> egress_timestamp ) {

    action insert_tx_timestamp() {
        hdr.l23_option.txtstamp = egress_timestamp;
    }



  /***************************************************/
  apply
  {
    if(eg_md.bridge.l23_txtstmp_insert == 1)
    {
        insert_tx_timestamp();
    }
  }
}
