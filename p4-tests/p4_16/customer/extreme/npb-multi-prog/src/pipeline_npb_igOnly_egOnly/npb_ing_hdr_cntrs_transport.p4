// Copyright 2021-2022 Extreme Networks, Inc.
// All rights reserved.

#ifndef _NPB_ING_HDR_CNTRS_TRANSPORT_
#define _NPB_ING_HDR_CNTRS_TRANSPORT_

control IngressHdrCntrsTransport(
    in switch_header_transport_t hdr
) (
	MODULE_DEPLOYMENT_PARAMS
) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) hdr_cntrs_L2;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) hdr_cntrs_L3;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) hdr_cntrs_TNL;

    action bump_hdr_cntr_L2() {
        hdr_cntrs_L2.count();
    }
    action bump_hdr_cntr_L3() {
        hdr_cntrs_L3.count();
    }
    action bump_hdr_cntr_TNL() {
        hdr_cntrs_TNL.count();
    }

    
    // -------------------------------------------------------------------------
    // table definitions (L2) --------------------------------------------------
    // -------------------------------------------------------------------------

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_mpls_6_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
            hdr.mpls_4.isValid(): exact;
            hdr.mpls_5.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 16;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_mpls_4_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 16;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_mpls_2_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 8;
    }

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
        size = 2;
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
    // table definitions (TNL) -------------------------------------------------
    // -------------------------------------------------------------------------

    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_gre_erspan_geneve_vxlan_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.gre.isValid(): exact;
            hdr.gre_sequence.isValid(): exact;
            hdr.erspan_type2.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.geneve.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 8;
    }

    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_gre_erspan_geneve_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.gre.isValid(): exact;
            hdr.gre_sequence.isValid(): exact;
            hdr.erspan_type2.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.geneve.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 8;
    }
                            
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_gre_erspan_vxlan_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.gre.isValid(): exact;
            hdr.gre_sequence.isValid(): exact;
            hdr.erspan_type2.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 8;
    }
                            
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_gre_erspan_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.gre.isValid(): exact;
            hdr.gre_sequence.isValid(): exact;
            hdr.erspan_type2.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
                            
    // -------------------------------------------------------------------------
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_gre_geneve_vxlan_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.gre.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.geneve.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 8;
    }

    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_gre_geneve_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.gre.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.geneve.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
                            
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_gre_vxlan_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.gre.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
                            
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_gre_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.gre.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }

    // -------------------------------------------------------------------------
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_geneve_vxlan_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.geneve.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }

    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_geneve_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.geneve.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
                            
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_vxlan_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
            hdr.udp.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
                            
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nsh_tbl {
        key = {
            hdr.nsh_type1.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 2;
    }
                                                        

    // -------------------------------------------------------------------------
    // apply -------------------------------------------------------------------
    // -------------------------------------------------------------------------

    apply {

        if(TRANSPORT_INGRESS_ENABLE) {        

            // -----------------------------------------------------------------
            // table (L2) ------------------------------------------------------
            // -----------------------------------------------------------------

            if(TRANSPORT_EoMPLS_INGRESS_ENABLE) {
                if(MPLS_DEPTH_TRANSPORT == 6) {
                    hdr_cntr_L2_mpls_6_tbl.apply();
                } else if(MPLS_DEPTH_TRANSPORT == 4) {
                    hdr_cntr_L2_mpls_4_tbl.apply();
                } else {
                    hdr_cntr_L2_mpls_2_tbl.apply();
                }
            } else {
                hdr_cntr_L2_tbl.apply();
            }

            // -----------------------------------------------------------------
            // table (L3) ------------------------------------------------------
            // -----------------------------------------------------------------

            if(TRANSPORT_IPV6_INGRESS_ENABLE) {
                hdr_cntr_L3_ipv4_ipv6_tbl.apply();
            } else {
                hdr_cntr_L3_ipv4_tbl.apply();
            }

            
            // -----------------------------------------------------------------
            // table (TNL) -----------------------------------------------------
            // -----------------------------------------------------------------

            if(
                TRANSPORT_GRE_INGRESS_ENABLE
                && TRANSPORT_ERSPAN_INGRESS_ENABLE
                && TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE
                && TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE) {            
                hdr_cntr_TNL_nsh_gre_erspan_geneve_vxlan_tbl.apply();
            } else if(
                TRANSPORT_GRE_INGRESS_ENABLE
                && TRANSPORT_ERSPAN_INGRESS_ENABLE
                && TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE) {
                hdr_cntr_TNL_nsh_gre_erspan_geneve_tbl.apply();
            } else if(
                TRANSPORT_GRE_INGRESS_ENABLE
                && TRANSPORT_ERSPAN_INGRESS_ENABLE
                && TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE) {
                hdr_cntr_TNL_nsh_gre_erspan_vxlan_tbl.apply();
            } else if(
                TRANSPORT_GRE_INGRESS_ENABLE
                && TRANSPORT_ERSPAN_INGRESS_ENABLE) {
                hdr_cntr_TNL_nsh_gre_erspan_tbl.apply();                
            // -----------------------------------------------------------------
            // No ERSPAN
            } else if(
                TRANSPORT_GRE_INGRESS_ENABLE
                && TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE
                && TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE) {            
                hdr_cntr_TNL_nsh_gre_geneve_vxlan_tbl.apply();
            } else if(
                TRANSPORT_GRE_INGRESS_ENABLE
                && TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE) {
                hdr_cntr_TNL_nsh_gre_geneve_tbl.apply();
            } else if(
                TRANSPORT_GRE_INGRESS_ENABLE
                && TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE) {
                hdr_cntr_TNL_nsh_gre_vxlan_tbl.apply();
            } else if(
                TRANSPORT_GRE_INGRESS_ENABLE) {
                hdr_cntr_TNL_nsh_gre_tbl.apply();
            // -----------------------------------------------------------------
            // No GRE or ERSPAN    
            } else if(
                TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE
                && TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE) {            
                hdr_cntr_TNL_nsh_geneve_vxlan_tbl.apply();
            } else if(TRANSPORT_IPV4_GENEVE_INGRESS_ENABLE) {
                hdr_cntr_TNL_nsh_geneve_tbl.apply();
            } else if(TRANSPORT_IPV4_VXLAN_INGRESS_ENABLE) {
                hdr_cntr_TNL_nsh_vxlan_tbl.apply();
            } else {
                hdr_cntr_TNL_nsh_tbl.apply();
            }
        }                                                                
    }
}

#endif /* _NPB_ING_HDR_CNTRS_TRANSPORT_ */
