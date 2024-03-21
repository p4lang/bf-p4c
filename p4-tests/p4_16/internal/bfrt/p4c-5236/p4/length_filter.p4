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


control length_filter( inout eg_header_t hdr, 
                        in egress_metadata_t eg_md,  
                        in egress_intrinsic_metadata_t eg_intr_md
        ) {

  bit<3>  length_match_no = 0;
 
  //reserve 0 for non-match

 /**********************************/
    action length_match(bit<3> entry)
    {
        length_match_no = entry;
    }

    table length_tbl{
    key = {
        eg_intr_md.pkt_length : range;
    }
    actions = {
        length_match;
        NoAction;
    }
    default_action = NoAction;
    size = 8;
    }

    action trigger_match()
    {
        hdr.capture.filter = 1w0;
        hdr.capture.trigger = 1w1;
    }

    action trigger_and_filter_match()
    {
        hdr.capture.filter = 1w1;
        hdr.capture.trigger = 1w1;
    }

    action filter_match()
    {
        hdr.capture.filter = 1w1;
        hdr.capture.trigger = 1w0;
    }

    action no_match()
    {
        hdr.capture.filter = 1w0;
        hdr.capture.trigger = 1w0;
    }
    

    table capture_matchers_tbl {
        key = {
            length_match_no  : ternary;
            eg_md.ing_port_mirror.filter : exact;
            eg_md.ing_port_mirror.trigger : exact;
        }
        actions = {
            trigger_match;
            trigger_and_filter_match;
            filter_match;
            no_match;
        }
        default_action = no_match;
        size = 32;
    }
 
/******************************/
apply 
{
    length_tbl.apply();
    capture_matchers_tbl.apply();
}

}



