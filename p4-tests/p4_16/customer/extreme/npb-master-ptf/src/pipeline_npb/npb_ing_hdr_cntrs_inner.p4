// Copyright 2021-2022 Extreme Networks, Inc.
// All rights reserved.

#ifndef _NPB_ING_HDR_CNTRS_INNER_
#define _NPB_ING_HDR_CNTRS_INNER_

control IngressHdrCntrsInner(
    in switch_header_inner_t hdr
) (
	MODULE_DEPLOYMENT_PARAMS
) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) hdr_cntrs_L2;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) hdr_cntrs_L3;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) hdr_cntrs_L4;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) hdr_cntrs_TNL;

    action bump_hdr_cntr_L2() {
        hdr_cntrs_L2.count();
    }
    action bump_hdr_cntr_L3() {
        hdr_cntrs_L3.count();
    }
    action bump_hdr_cntr_L4() {
        hdr_cntrs_L4.count();
    }
    action bump_hdr_cntr_TNL() {
        hdr_cntrs_TNL.count();
    }

    // -------------------------------------------------------------------------
    // table definitions (L2) --------------------------------------------------
    // -------------------------------------------------------------------------

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 4;
    }

    // -------------------------------------------------------------------------
    // table definitions (L3) --------------------------------------------------
    // -------------------------------------------------------------------------
    
    @name("hdr_cntr_L3_tbl")
    table hdr_cntr_L3_ipv4_ipv6_tbl {
        key = {
            hdr.ipv4.isValid(): exact;
            hdr.ipv6.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L3;
        }
        counters = hdr_cntrs_L3;
        size = 4;
    }

    @name("hdr_cntr_L3_tbl")
    table hdr_cntr_L3_ipv4_tbl {
        key = {
            hdr.ipv4.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L3;
        }
        counters = hdr_cntrs_L3;
        size = 2;
    }
    
    // -------------------------------------------------------------------------
    // table definitions (L4) --------------------------------------------------
    // -------------------------------------------------------------------------
    
    @name("hdr_cntr_L4_tbl")
    table hdr_cntr_L4_udp_tcp_sctp_tbl {
        key = {
            hdr.udp.isValid(): exact;
            hdr.tcp.isValid(): exact;
            hdr.sctp.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L4;
        }
        counters = hdr_cntrs_L4;
        size = 4;
    }

    // -------------------------------------------------------------------------
    // table definitions (TNL) -------------------------------------------------
    // -------------------------------------------------------------------------

    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_gre_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.gtp_v1_base.isValid(): exact;
            hdr.gtp_v1_optional.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 8;
    }

    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_gre_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_gtp_tbl {
        key = {
            hdr.gtp_v1_base.isValid(): exact;
            hdr.gtp_v1_optional.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }    

    // -------------------------------------------------------------------------
    // apply -------------------------------------------------------------------
    // -------------------------------------------------------------------------

    apply {

        // -----------------------------------------------------------------
        // table (L2) ------------------------------------------------------
        // -----------------------------------------------------------------
        
        hdr_cntr_L2_tbl.apply();
        
        // -----------------------------------------------------------------
        // table (L3) ------------------------------------------------------
        // -----------------------------------------------------------------
        
        if(INNER_IPV6_ENABLE) {
            hdr_cntr_L3_ipv4_ipv6_tbl.apply();
        } else {
            hdr_cntr_L3_ipv4_tbl.apply();
        }

        // -----------------------------------------------------------------
        // table (L4) ------------------------------------------------------
        // -----------------------------------------------------------------
        
        hdr_cntr_L4_udp_tcp_sctp_tbl.apply();
        
        // -----------------------------------------------------------------
        // table (TNL) -----------------------------------------------------
        // -----------------------------------------------------------------

        if(INNER_GRE_ENABLE && INNER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_gtp_tbl.apply();
        } else if(INNER_GRE_ENABLE) {
            hdr_cntr_TNL_gre_tbl.apply();
        } else if(INNER_GTP_ENABLE) {
            hdr_cntr_TNL_gtp_tbl.apply();
        }
    }
}

#endif /* _NPB_ING_HDR_CNTRS_INNER_ */
            
