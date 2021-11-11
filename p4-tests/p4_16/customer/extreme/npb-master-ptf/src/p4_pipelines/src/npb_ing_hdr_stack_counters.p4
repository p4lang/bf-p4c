#ifndef _NPB_ING_HDR_STACK_COUNTERS_
#define _NPB_ING_HDR_STACK_COUNTERS_

control IngressHdrStackCounters(
    in switch_header_t hdr
) (
	MODULE_DEPLOYMENT_PARAMS
) {

#ifdef CPU_ENABLE    
    DirectCounter<bit<32>>(CounterType_t.PACKETS) cpu_hdr_cntrs;
#endif // CPU_ENABLE    
    DirectCounter<bit<32>>(CounterType_t.PACKETS) transport_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) outer_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) inner_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) udf_hdr_cntrs;

#ifdef CPU_ENABLE

    // ------------------------------------------------------------
    // CPU Header -------------------------------------------------
    // ------------------------------------------------------------

    action bump_cpu_hdr_cntr() {
        cpu_hdr_cntrs.count();
    }

    table cpu_hdr_cntr_tbl {
        key = {
            hdr.cpu.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_cpu_hdr_cntr;
        }

        size = 2;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_cpu_hdr_cntr;
        counters = cpu_hdr_cntrs;

//         // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//             false: bump_cpu_hdr_cntr; 
//             true:  bump_cpu_hdr_cntr; 
//         }
    }

#endif // CPU_ENABLE

    
    // ------------------------------------------------------------
    // transport stack --------------------------------------------
    // ------------------------------------------------------------

    bool hdr_transport_ethernet_isValid;
    bool hdr_transport_vlan_tag_0_isValid;
    bool hdr_transport_nsh_type1_isValid;
    bool hdr_transport_mpls_0_isValid;
    bool hdr_transport_mpls_1_isValid;
    bool hdr_transport_mpls_2_isValid;
    bool hdr_transport_mpls_3_isValid;
    bool hdr_transport_ipv4_isValid;
    bool hdr_transport_ipv6_isValid;
    bool hdr_transport_gre_isValid;
    bool hdr_transport_gre_sequence_isValid;
    bool hdr_transport_erspan_type2_isValid;
    bool hdr_transport_udp_isValid;
    bool hdr_transport_geneve_isValid;
    bool hdr_transport_vxlan_isValid;    

    action bump_transport_stack_hdr_cntr() {
        transport_stack_hdr_cntrs.count();
    }

    table transport_stack_hdr_cntr_tbl {
        key = {
            hdr_transport_ethernet_isValid: exact;
            hdr_transport_vlan_tag_0_isValid: exact;
            hdr_transport_nsh_type1_isValid: exact;
            hdr_transport_mpls_0_isValid: exact;
            hdr_transport_mpls_1_isValid: exact;
            hdr_transport_mpls_2_isValid: exact;
            hdr_transport_mpls_3_isValid: exact;
            hdr_transport_ipv4_isValid: exact;
            hdr_transport_ipv6_isValid: exact;
            hdr_transport_gre_isValid: exact;
            hdr_transport_gre_sequence_isValid: exact;
            hdr_transport_erspan_type2_isValid: exact;
            hdr_transport_udp_isValid: exact;
            hdr_transport_geneve_isValid: exact;
            hdr_transport_vxlan_isValid: exact;
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_transport_stack_hdr_cntr;
        }
        counters = transport_stack_hdr_cntrs;
        size = 32;  // Little slop built-in here

    }


    // ------------------------------------------------------------
    // outer stack --------------------------------------------
    // ------------------------------------------------------------

    bool hdr_outer_ethernet_isValid;
    bool hdr_outer_e_tag_isValid;
    bool hdr_outer_vn_tag_isValid;
    bool hdr_outer_vlan_tag_0_isValid;
    bool hdr_outer_vlan_tag_1_isValid;
    bool hdr_outer_mpls_0_isValid;
    bool hdr_outer_mpls_1_isValid;
    bool hdr_outer_mpls_2_isValid;
    bool hdr_outer_mpls_3_isValid;
    bool hdr_outer_mpls_pw_cw_isValid;
    bool hdr_outer_ipv4_isValid;
    bool hdr_outer_ipv6_isValid;
    bool hdr_outer_udp_isValid;
    bool hdr_outer_tcp_isValid;
    bool hdr_outer_sctp_isValid;
    bool hdr_outer_gre_isValid;        
    bool hdr_outer_gre_optional_isValid;        
    bool hdr_outer_geneve_isValid;
    bool hdr_outer_vxlan_isValid;
    bool hdr_outer_nvgre_isValid;
    bool hdr_outer_gtp_v1_base_isValid;
    bool hdr_outer_gtp_v1_optional_isValid;

    
    action bump_outer_stack_hdr_cntr() {
        outer_stack_hdr_cntrs.count();
    }
    
    table outer_stack_hdr_cntr_tbl {
        key = {
            hdr_outer_ethernet_isValid: exact;
            hdr_outer_e_tag_isValid: exact;
            hdr_outer_vn_tag_isValid: exact;
            hdr_outer_vlan_tag_0_isValid: exact;
            hdr_outer_vlan_tag_1_isValid: exact;
            hdr_outer_mpls_0_isValid: exact;
            hdr_outer_mpls_1_isValid: exact;
            hdr_outer_mpls_2_isValid: exact;
            hdr_outer_mpls_3_isValid: exact;
            hdr_outer_mpls_pw_cw_isValid: exact;
            hdr_outer_ipv4_isValid: exact;
            hdr_outer_ipv6_isValid: exact;
            hdr_outer_udp_isValid: exact;
            hdr_outer_tcp_isValid: exact;
            hdr_outer_sctp_isValid: exact;
            hdr_outer_gre_isValid: exact;        
            hdr_outer_gre_optional_isValid: exact;        
            hdr_outer_geneve_isValid: exact;
            hdr_outer_vxlan_isValid: exact;
            hdr_outer_nvgre_isValid: exact;
            hdr_outer_gtp_v1_base_isValid: exact;
            hdr_outer_gtp_v1_optional_isValid: exact;
        }

        actions = {
            //NoAction;
            bump_outer_stack_hdr_cntr;
        }

        counters = outer_stack_hdr_cntrs;
        size = 512;  // There is a little slop built-in here
    }


    // ------------------------------------------------------------
    // inner stack ------------------------------------------------
    // ------------------------------------------------------------

    bool hdr_inner_gre_isValid;
    bool hdr_inner_gre_optional_isValid;
    bool hdr_inner_gtp_v1_base_isValid;
    bool hdr_inner_gtp_v1_optional_isValid;

    
    action bump_inner_stack_hdr_cntr() {
        inner_stack_hdr_cntrs.count();
    }
    
    table inner_stack_hdr_cntr_tbl {
        key = {

            hdr.inner.ethernet.isValid(): exact;
            hdr.inner.vlan_tag[0].isValid(): exact;

            hdr.inner.ipv4.isValid(): exact;
            hdr.inner.ipv6.isValid(): exact;

            hdr.inner.udp.isValid(): exact;
            hdr.inner.tcp.isValid(): exact;
            hdr.inner.sctp.isValid(): exact;

            hdr_inner_gre_isValid: exact;        
            hdr_inner_gre_optional_isValid: exact;

            hdr_inner_gtp_v1_base_isValid: exact;
            hdr_inner_gtp_v1_optional_isValid: exact;
        }

        actions = {
            //NoAction;
            bump_inner_stack_hdr_cntr;
        }

        counters = inner_stack_hdr_cntrs;
        size = 64; // There is some slop built-in here
    }


    
    // ------------------------------------------------------------
    // Layer7 UDF -------------------------------------------------
    // ------------------------------------------------------------

    action bump_udf_hdr_cntr() {
        udf_hdr_cntrs.count();
    }

    table udf_hdr_cntr_tbl {
        key = {
            hdr.udf.isValid(): exact;
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_udf_hdr_cntr;
        }

        size = 2;
        counters = udf_hdr_cntrs;
    }


    
    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {

        // ------------------------------------------------------------
        // Transport

        hdr_transport_ethernet_isValid   = hdr.transport.ethernet.isValid();
        hdr_transport_vlan_tag_0_isValid = hdr.transport.vlan_tag[0].isValid();
        hdr_transport_nsh_type1_isValid  = hdr.transport.nsh_type1.isValid();

#ifdef MPLS_SR_TRANSPORT_INGRESS_ENABLE
        hdr_transport_mpls_0_isValid = hdr.transport.mpls[0].isValid();
  #if MPLS_DEPTH > 1
        hdr_transport_mpls_1_isValid = hdr.transport.mpls[1].isValid();
  #else
		hdr_transport_mpls_1_isValid = false;
  #endif
  #if MPLS_DEPTH > 2
        hdr_transport_mpls_2_isValid = hdr.transport.mpls[2].isValid();
  #else
		hdr_transport_mpls_2_isValid = false;
  #endif
  #if MPLS_DEPTH > 3
        hdr_transport_mpls_3_isValid = hdr.transport.mpls[3].isValid();
  #else
		hdr_transport_mpls_3_isValid = false;
  #endif
#else
        hdr_transport_mpls_0_isValid = false;
        hdr_transport_mpls_1_isValid = false;
        hdr_transport_mpls_2_isValid = false;
        hdr_transport_mpls_3_isValid = false;        
#endif // MPLS_SR_TRANSPORT_INGRESS_ENABLE

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(GENEVE_TRANSPORT_INGRESS_ENABLE_V4)
        hdr_transport_ipv4_isValid = hdr.transport.ipv4.isValid();
#else
        hdr_transport_ipv4_isValid = false;
#endif //#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || \
       //    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //    defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //    defined(GENEVE_TRANSPORT_INGRESS_ENABLE_V4)

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
        hdr_transport_ipv6_isValid = hdr.transport.ipv6.isValid();
#else
        hdr_transport_ipv6_isValid = false;        
#endif //#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || \
       //    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
        

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            hdr_transport_gre_isValid = hdr.transport.gre.isValid();
#else
            hdr_transport_gre_isValid = false;
#endif // #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || \
       //     defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //     defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || \
       //     defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)


#if defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)            
            hdr_transport_gre_sequence_isValid = hdr.transport.gre_sequence.isValid();
            hdr_transport_erspan_type2_isValid = hdr.transport.erspan_type2.isValid();
#else
            hdr_transport_gre_sequence_isValid = false;
            hdr_transport_erspan_type2_isValid = false;
#endif // #if defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //     defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)

        
#if defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(GENEVE_TRANSPORT_INGRESS_ENABLE_V4)
            hdr_transport_udp_isValid = hdr.transport.udp.isValid();
#else
            hdr_transport_udp_isValid = false;
#endif // #if defined (VXLAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //     defined(GENEVE_TRANSPORT_INGRESS_ENABLE_V4)


#ifdef GENEVE_TRANSPORT_INGRESS_ENABLE_V4
            hdr_transport_geneve_isValid = hdr.transport.geneve.isValid();
#else
            hdr_transport_geneve_isValid = false;
#endif // #ifdef GENEVE_TRANSPORT_INGRESS_ENABLE_V4
        
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
            hdr_transport_vxlan_isValid = hdr.transport.vxlan.isValid();
#else
            hdr_transport_vxlan_isValid = false;
#endif // #ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
        


        // ------------------------------------------------------------
        // Outer

        hdr_outer_ethernet_isValid = hdr.outer.ethernet.isValid();

        if(OUTER_ETAG_ENABLE) {
            hdr_outer_e_tag_isValid = hdr.outer.e_tag.isValid();
        } else {
            hdr_outer_e_tag_isValid = false;
        }

        if(OUTER_VNTAG_ENABLE) {
            hdr_outer_vn_tag_isValid = hdr.outer.vn_tag.isValid();
        } else {
            hdr_outer_vn_tag_isValid = false;
        }

        hdr_outer_vlan_tag_0_isValid = hdr.outer.vlan_tag[0].isValid();
        hdr_outer_vlan_tag_1_isValid = hdr.outer.vlan_tag[1].isValid();

#if defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
        hdr_outer_mpls_0_isValid = hdr.outer.mpls[0].isValid();
        hdr_outer_mpls_1_isValid = hdr.outer.mpls[1].isValid();
        hdr_outer_mpls_2_isValid = hdr.outer.mpls[2].isValid();
        hdr_outer_mpls_3_isValid = hdr.outer.mpls[3].isValid();
#else
        hdr_outer_mpls_0_isValid = false;
        hdr_outer_mpls_1_isValid = false;
        hdr_outer_mpls_2_isValid = false;
        hdr_outer_mpls_3_isValid = false;
#endif // defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)

#ifdef MPLS_L2VPN_ENABLE
        hdr_outer_mpls_pw_cw_isValid = hdr.outer.mpls_pw_cw.isValid();
#else
        hdr_outer_mpls_pw_cw_isValid = false;
#endif // MPLS_L2VPN_ENABLE            

        hdr_outer_ipv4_isValid = hdr.outer.ipv4.isValid();
        hdr_outer_ipv6_isValid = hdr.outer.ipv6.isValid();
        hdr_outer_udp_isValid  = hdr.outer.udp.isValid();
        hdr_outer_tcp_isValid  = hdr.outer.tcp.isValid();
        hdr_outer_sctp_isValid = hdr.outer.sctp.isValid();
        
#if defined(GRE_ENABLE) || defined(MPLSoGRE_ENABLE)
        //if(OUTER_GRE_ENABLE || OUTER_NVGRE_ENABLE) {
            hdr_outer_gre_isValid          = hdr.outer.gre.isValid();        
            hdr_outer_gre_optional_isValid = hdr.outer.gre_optional.isValid();        
#else
        //} else {
            hdr_outer_gre_isValid          = false;
            hdr_outer_gre_optional_isValid = false;
#endif // #if defined(GRE_ENABLE) || defined(MPLSoGRE_ENABLE)
        //}

        if(OUTER_GENEVE_ENABLE) {
            hdr_outer_geneve_isValid = hdr.outer.geneve.isValid();
        } else {
            hdr_outer_geneve_isValid = false;
        }
       
        if(OUTER_VXLAN_ENABLE) {
            hdr_outer_vxlan_isValid = hdr.outer.vxlan.isValid();
        } else {
            hdr_outer_vxlan_isValid = false;
        }

        if(OUTER_NVGRE_ENABLE) {
            hdr_outer_nvgre_isValid = hdr.outer.nvgre.isValid();
        } else {
            hdr_outer_nvgre_isValid = false;
        }

#ifdef GTP_ENABLE
        hdr_outer_gtp_v1_base_isValid     = hdr.outer.gtp_v1_base.isValid();
        hdr_outer_gtp_v1_optional_isValid = hdr.outer.gtp_v1_optional.isValid();
#else
        hdr_outer_gtp_v1_base_isValid     = false;
        hdr_outer_gtp_v1_optional_isValid = false;
#endif // GTP_ENABLE          

                

        // ------------------------------------------------------------
        // Inner

#ifdef INNER_GRE_ENABLE
        hdr_inner_gre_isValid = hdr.inner.gre.isValid();        
        hdr_inner_gre_optional_isValid = hdr.inner.gre_optional.isValid();
#else
        hdr_inner_gre_isValid = false;
        hdr_inner_gre_optional_isValid = false;
#endif // INNER_GRE_ENABLE
#ifdef INNER_GTP_ENABLE            
        hdr_inner_gtp_v1_base_isValid = hdr.inner.gtp_v1_base.isValid();
        hdr_inner_gtp_v1_optional_isValid = hdr.inner.gtp_v1_optional.isValid();
#else
        hdr_inner_gtp_v1_base_isValid = false;
        hdr_inner_gtp_v1_optional_isValid = false;
#endif // INNER_GTP_ENABLE        

        

        // ------------------------------------------------------------
        // Tables
#ifdef CPU_ENABLE            
        cpu_hdr_cntr_tbl.apply();
#endif // CPU_ENABLE
        transport_stack_hdr_cntr_tbl.apply();
        outer_stack_hdr_cntr_tbl.apply();
        inner_stack_hdr_cntr_tbl.apply();

        if(UDF_ENABLE) {
            udf_hdr_cntr_tbl.apply();
        }
    }
}

#endif /* _NPB_ING_HDR_STACK_COUNTERS_ */
            
