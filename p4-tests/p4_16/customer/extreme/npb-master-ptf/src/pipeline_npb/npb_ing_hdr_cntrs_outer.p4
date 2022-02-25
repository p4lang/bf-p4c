// Copyright 2020-2021 Extreme Networks, Inc.
// All rights reserved.

#ifndef _NPB_ING_HDR_CNTRS_OUTER_
#define _NPB_ING_HDR_CNTRS_OUTER_

control IngressHdrCntrsOuter(
    in switch_header_outer_t hdr
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
    table hdr_cntr_L2_etag_vntag_mpls_4_pwcw_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
            hdr.mpls_pw_cw.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 128;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_vntag_mpls_4_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 64;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_vntag_mpls_2_pwcw_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_pw_cw.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 64;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_vntag_mpls_2_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 32;
    }


    // -------------------------------------------------------------------------
    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_mpls_4_pwcw_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
            hdr.mpls_pw_cw.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 64;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_mpls_4_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 32;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_mpls_2_pwcw_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_pw_cw.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 32;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_mpls_2_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 24;
    }

    // -------------------------------------------------------------------------
    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_vntag_mpls_4_pwcw_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
            hdr.mpls_pw_cw.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 64;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_vntag_mpls_4_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 32;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_vntag_mpls_2_pwcw_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_pw_cw.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 32;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_vntag_mpls_2_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 24;
    }

    // -------------------------------------------------------------------------
    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_mpls_4_pwcw_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_2.isValid(): exact;
            hdr.mpls_3.isValid(): exact;
            hdr.mpls_pw_cw.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 32;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_mpls_4_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
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
    table hdr_cntr_L2_mpls_2_pwcw_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
            hdr.mpls_pw_cw.isValid(): exact;
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
            hdr.vlan_tag[1].isValid(): exact;
            hdr.mpls_0.isValid(): exact;
            hdr.mpls_1.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 16;
    }
    

    // -------------------------------------------------------------------------
    // No MPLS
    
    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_vntag_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 16;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_etag_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.e_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_L2;
        }
        counters = hdr_cntrs_L2;
        size = 8;
    }

    @name("hdr_cntr_L2_tbl")
    table hdr_cntr_L2_vntag_tbl {
        key = {
            hdr.ethernet.isValid(): exact;
            hdr.vn_tag.isValid(): exact;
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[1].isValid(): exact;
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
            hdr.vlan_tag[1].isValid(): exact;
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
    table hdr_cntr_TNL_gre_nvgre_geneve_vxlan_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.geneve.isValid(): exact;
            hdr.vxlan.isValid(): exact;
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
    table hdr_cntr_TNL_gre_nvgre_geneve_vxlan_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.nvgre.isValid(): exact;
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
    table hdr_cntr_TNL_gre_nvgre_geneve_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.geneve.isValid(): exact;
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
    table hdr_cntr_TNL_gre_nvgre_geneve_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.geneve.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 8;
    }
    

    // -------------------------------------------------------------------------
    // No GENEVE
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_gre_nvgre_vxlan_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.vxlan.isValid(): exact;
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
    table hdr_cntr_TNL_gre_nvgre_vxlan_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 8;
    }
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_gre_nvgre_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.nvgre.isValid(): exact;
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
    table hdr_cntr_TNL_gre_nvgre_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.nvgre.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }

    
    // -------------------------------------------------------------------------
    // No NVGRE
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_gre_geneve_vxlan_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.geneve.isValid(): exact;
            hdr.vxlan.isValid(): exact;
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
    table hdr_cntr_TNL_gre_geneve_vxlan_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
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
    table hdr_cntr_TNL_gre_geneve_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.geneve.isValid(): exact;
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
    table hdr_cntr_TNL_gre_geneve_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.geneve.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
    

    // -------------------------------------------------------------------------
    // No NVGRE or GENEVE
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_gre_vxlan_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.vxlan.isValid(): exact;
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
    table hdr_cntr_TNL_gre_vxlan_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.gre_optional.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
    
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


    // -------------------------------------------------------------------------
    // No GRE
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nvgre_geneve_vxlan_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.geneve.isValid(): exact;
            hdr.vxlan.isValid(): exact;
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
    table hdr_cntr_TNL_nvgre_geneve_vxlan_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.nvgre.isValid(): exact;
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
    table hdr_cntr_TNL_nvgre_geneve_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.geneve.isValid(): exact;
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
    table hdr_cntr_TNL_nvgre_geneve_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.geneve.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }
    

    // -------------------------------------------------------------------------
    // No GRE or GENEVE
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nvgre_vxlan_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.vxlan.isValid(): exact;
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
    table hdr_cntr_TNL_nvgre_vxlan_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.nvgre.isValid(): exact;
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 8;
    }
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_nvgre_gtp_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.nvgre.isValid(): exact;
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
    table hdr_cntr_TNL_nvgre_tbl {
        key = {
            hdr.gre.isValid(): exact;
            hdr.nvgre.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }

    
    // -------------------------------------------------------------------------
    // No GRE or NVGRE
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_geneve_vxlan_gtp_tbl {
        key = {
            hdr.geneve.isValid(): exact;
            hdr.vxlan.isValid(): exact;
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
    table hdr_cntr_TNL_geneve_vxlan_tbl {
        key = {
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
    table hdr_cntr_TNL_geneve_gtp_tbl {
        key = {
            hdr.geneve.isValid(): exact;
            hdr.gtp_v1_base.isValid(): exact;
            hdr.gtp_v1_optional.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }

    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_geneve_tbl {
        key = {
            hdr.geneve.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 2;
    }
    

    // -------------------------------------------------------------------------
    // No GRE or NVGRE or GENEVE
    
    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_vxlan_gtp_tbl {
        key = {
            hdr.vxlan.isValid(): exact;
            hdr.gtp_v1_base.isValid(): exact;
            hdr.gtp_v1_optional.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 4;
    }

    @name("hdr_cntr_TNL_tbl")
    table hdr_cntr_TNL_vxlan_tbl {
        key = {
            hdr.vxlan.isValid(): exact;
        }
        actions = {
            bump_hdr_cntr_TNL;
        }
        counters = hdr_cntrs_TNL;
        size = 2;
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
        
        if(
            OUTER_ETAG_ENABLE
            && OUTER_VNTAG_ENABLE
            && OUTER_EoMPLS_PWCW_ENABLE
            && MPLS_DEPTH_TRANSPORT == 4) {
            hdr_cntr_L2_etag_vntag_mpls_4_pwcw_tbl.apply();
        } else if(
            OUTER_ETAG_ENABLE
            && OUTER_VNTAG_ENABLE
            && (OUTER_EoMPLS_ENABLE || OUTER_IPoMPLS_ENABLE)
            && MPLS_DEPTH_TRANSPORT == 4) {
            hdr_cntr_L2_etag_vntag_mpls_4_tbl.apply();
        } else if(
            OUTER_ETAG_ENABLE
            && OUTER_VNTAG_ENABLE
            && OUTER_EoMPLS_PWCW_ENABLE
            && MPLS_DEPTH_TRANSPORT == 2) {
            hdr_cntr_L2_etag_vntag_mpls_2_pwcw_tbl.apply();
        } else if(
            OUTER_ETAG_ENABLE
            && OUTER_VNTAG_ENABLE
            && (OUTER_EoMPLS_ENABLE || OUTER_IPoMPLS_ENABLE)
            && MPLS_DEPTH_TRANSPORT == 2) {
            hdr_cntr_L2_etag_vntag_mpls_2_tbl.apply();

        // -----------------------------------------------------------------
        } else if(
            OUTER_ETAG_ENABLE
            && OUTER_EoMPLS_PWCW_ENABLE
            && MPLS_DEPTH_TRANSPORT == 4) {
            hdr_cntr_L2_etag_mpls_4_pwcw_tbl.apply();
        } else if(
            OUTER_ETAG_ENABLE
            && (OUTER_EoMPLS_ENABLE || OUTER_IPoMPLS_ENABLE)
            && MPLS_DEPTH_TRANSPORT == 4) {
            hdr_cntr_L2_etag_mpls_4_tbl.apply();
        } else if(
            OUTER_ETAG_ENABLE
            && OUTER_EoMPLS_PWCW_ENABLE
            && MPLS_DEPTH_TRANSPORT == 2) {
            hdr_cntr_L2_etag_mpls_2_pwcw_tbl.apply();
        } else if(
            OUTER_ETAG_ENABLE
            && (OUTER_EoMPLS_ENABLE || OUTER_IPoMPLS_ENABLE)
            && MPLS_DEPTH_TRANSPORT == 2) {
            hdr_cntr_L2_etag_mpls_2_tbl.apply();

        // -----------------------------------------------------------------
        } else if(
            OUTER_VNTAG_ENABLE
            && OUTER_EoMPLS_PWCW_ENABLE
            && MPLS_DEPTH_TRANSPORT == 4) {
            hdr_cntr_L2_vntag_mpls_4_pwcw_tbl.apply();
        } else if(
            OUTER_VNTAG_ENABLE
            && (OUTER_EoMPLS_ENABLE || OUTER_IPoMPLS_ENABLE)
            && MPLS_DEPTH_TRANSPORT == 4) {
            hdr_cntr_L2_vntag_mpls_4_tbl.apply();
        } else if(
            OUTER_VNTAG_ENABLE
            && OUTER_EoMPLS_PWCW_ENABLE
            && MPLS_DEPTH_TRANSPORT == 2) {
            hdr_cntr_L2_vntag_mpls_2_pwcw_tbl.apply();
        } else if(
            OUTER_VNTAG_ENABLE
            && (OUTER_EoMPLS_ENABLE || OUTER_IPoMPLS_ENABLE)
            && MPLS_DEPTH_TRANSPORT == 2) {
            hdr_cntr_L2_vntag_mpls_2_tbl.apply();

        // -----------------------------------------------------------------
        } else if(
            OUTER_EoMPLS_PWCW_ENABLE
            && MPLS_DEPTH_TRANSPORT == 4) {
            hdr_cntr_L2_mpls_4_pwcw_tbl.apply();
        } else if(
            (OUTER_EoMPLS_ENABLE || OUTER_IPoMPLS_ENABLE)
            && MPLS_DEPTH_TRANSPORT == 4) {
            hdr_cntr_L2_mpls_4_tbl.apply();
        } else if(
            OUTER_EoMPLS_PWCW_ENABLE
            && MPLS_DEPTH_TRANSPORT == 2) {
            hdr_cntr_L2_mpls_2_pwcw_tbl.apply();
        } else if(
            (OUTER_EoMPLS_ENABLE || OUTER_IPoMPLS_ENABLE)
            && MPLS_DEPTH_TRANSPORT == 2) {
            hdr_cntr_L2_mpls_2_tbl.apply();

        // -----------------------------------------------------------------

        } else if(OUTER_ETAG_ENABLE && OUTER_VNTAG_ENABLE) {
            hdr_cntr_L2_etag_vntag_tbl.apply();
        } else if(OUTER_ETAG_ENABLE) {            
            hdr_cntr_L2_etag_tbl.apply();
        } else if(OUTER_VNTAG_ENABLE) {
            hdr_cntr_L2_vntag_tbl.apply();
        } else {
            hdr_cntr_L2_tbl.apply();
        }


        // -----------------------------------------------------------------
        // table (L3) ------------------------------------------------------
        // -----------------------------------------------------------------
        
        if(OUTER_IPV6_ENABLE) {
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

        if(
            OUTER_GRE_ENABLE
            && OUTER_NVGRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_VXLAN_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_nvgre_geneve_vxlan_gtp_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_NVGRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_VXLAN_ENABLE) {
            hdr_cntr_TNL_gre_nvgre_geneve_vxlan_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_NVGRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_nvgre_geneve_gtp_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_NVGRE_ENABLE
            && OUTER_GENEVE_ENABLE) {
            hdr_cntr_TNL_gre_nvgre_geneve_tbl.apply();
            
        // -----------------------------------------------------------------
        // No GENEVE

        } else if(
            OUTER_GRE_ENABLE
            && OUTER_NVGRE_ENABLE
            && OUTER_VXLAN_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_nvgre_vxlan_gtp_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_NVGRE_ENABLE
            && OUTER_VXLAN_ENABLE) {
            hdr_cntr_TNL_gre_nvgre_vxlan_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_NVGRE_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_nvgre_gtp_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_NVGRE_ENABLE) {
            hdr_cntr_TNL_gre_nvgre_tbl.apply();
            
        // -----------------------------------------------------------------
        // No NVGRE

        } else if(
            OUTER_GRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_VXLAN_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_geneve_vxlan_gtp_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_VXLAN_ENABLE) {
            hdr_cntr_TNL_gre_geneve_vxlan_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_geneve_gtp_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_GENEVE_ENABLE) {
            hdr_cntr_TNL_gre_geneve_tbl.apply();
            
        // -----------------------------------------------------------------
        // No NVGRE or GENEVE
  
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_VXLAN_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_vxlan_gtp_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_VXLAN_ENABLE) {
            hdr_cntr_TNL_gre_vxlan_tbl.apply();
        } else if(
            OUTER_GRE_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gre_gtp_tbl.apply();
        } else if(OUTER_GRE_ENABLE) {
            hdr_cntr_TNL_gre_tbl.apply();

        // -----------------------------------------------------------------
        // No GRE

        } else if(
            OUTER_NVGRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_VXLAN_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_nvgre_geneve_vxlan_gtp_tbl.apply();
        } else if(
            OUTER_NVGRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_VXLAN_ENABLE) {
            hdr_cntr_TNL_nvgre_geneve_vxlan_tbl.apply();
        } else if(
            OUTER_NVGRE_ENABLE
            && OUTER_GENEVE_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_nvgre_geneve_gtp_tbl.apply();
        } else if(
            OUTER_NVGRE_ENABLE
            && OUTER_GENEVE_ENABLE) {
            hdr_cntr_TNL_nvgre_geneve_tbl.apply();
            
        // -----------------------------------------------------------------
        // No GRE or GENEVE

        } else if(
            OUTER_NVGRE_ENABLE
            && OUTER_VXLAN_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_nvgre_vxlan_gtp_tbl.apply();
        } else if(
            OUTER_NVGRE_ENABLE
            && OUTER_VXLAN_ENABLE) {
            hdr_cntr_TNL_nvgre_vxlan_tbl.apply();
        } else if(
            OUTER_NVGRE_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_nvgre_gtp_tbl.apply();
        } else if(
            OUTER_NVGRE_ENABLE) {
            hdr_cntr_TNL_nvgre_tbl.apply();
            
        // -----------------------------------------------------------------
        // No GRE or NVGRE

        } else if(
            OUTER_GENEVE_ENABLE
            && OUTER_VXLAN_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_geneve_vxlan_gtp_tbl.apply();
        } else if(
            OUTER_GENEVE_ENABLE
            && OUTER_VXLAN_ENABLE) {
            hdr_cntr_TNL_geneve_vxlan_tbl.apply();
        } else if(
            OUTER_GENEVE_ENABLE
            && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_geneve_gtp_tbl.apply();
        } else if(OUTER_GENEVE_ENABLE) {
            hdr_cntr_TNL_geneve_tbl.apply();
            
        // -----------------------------------------------------------------
        // No GRE or NVGRE or GENEVE
  
        } else if(OUTER_VXLAN_ENABLE && OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_vxlan_gtp_tbl.apply();
        } else if(OUTER_VXLAN_ENABLE) {            
            hdr_cntr_TNL_vxlan_tbl.apply();
        } else if(OUTER_GTP_ENABLE) {
            hdr_cntr_TNL_gtp_tbl.apply();
        } else {
            ;
        }
    }
}

#endif // _NPB_ING_HDR_CNTRS_OUTER_
