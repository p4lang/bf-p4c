#ifndef _NPB_ING_HDR_STACK_COUNTERS_
#define _NPB_ING_HDR_STACK_COUNTERS_

control IngressHdrStackCounters(
    in switch_header_t hdr
) {

#ifdef CPU_ENABLE    
    DirectCounter<bit<32>>(CounterType_t.PACKETS) cpu_hdr_cntrs;
#endif // UDF_ENABLE    
    DirectCounter<bit<32>>(CounterType_t.PACKETS) transport_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) outer_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) inner_stack_hdr_cntrs;
#ifdef UDF_ENABLE    
    DirectCounter<bit<32>>(CounterType_t.PACKETS) udf_hdr_cntrs;
#endif // UDF_ENABLE


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

    action bump_transport_stack_hdr_cntr() {
        transport_stack_hdr_cntrs.count();
    }

    table transport_stack_hdr_cntr_tbl {
        key = {
            hdr.transport.ethernet.isValid(): exact;
            hdr.transport.vlan_tag[0].isValid(): exact;
            hdr.transport.nsh_type1.isValid(): exact;
#ifdef MPLS_SR_TRANSPORT_INGRESS_ENABLE
            hdr.transport.mpls[0].isValid(): exact;
            hdr.transport.mpls[1].isValid(): exact;
            hdr.transport.mpls[2].isValid(): exact;
            hdr.transport.mpls[3].isValid(): exact;
#endif // MPLS_SR_TRANSPORT_INGRESS_ENABLE
            
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(GENEVE_TRANSPORT_INGRESS_ENABLE_V4)
            hdr.transport.ipv4.isValid(): exact;
#endif //#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || \
       //    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //    defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //    defined(GENEVE_TRANSPORT_INGRESS_ENABLE_V4)

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            hdr.transport.ipv6.isValid(): exact;
#endif //#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || \
       //    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
   
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            hdr.transport.gre.isValid(): exact;
#endif // #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || \
       //     defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //     defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || \
       //     defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)

#if defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)            
            hdr.transport.gre_sequence.isValid(): exact;
            hdr.transport.erspan_type2.isValid(): exact;
#endif // #if defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //     defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
            
#if defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) || \
    defined(GENEVE_TRANSPORT_INGRESS_ENABLE_V4)
            hdr.transport.udp.isValid(): exact;
#endif // #if defined (VXLAN_TRANSPORT_INGRESS_ENABLE_V4) || \
       //     defined(GENEVE_TRANSPORT_INGRESS_ENABLE_V4)

#ifdef GENEVE_TRANSPORT_INGRESS_ENABLE_V4
            hdr.transport.geneve.isValid(): exact;
#endif // #ifdef GENEVE_TRANSPORT_INGRESS_ENABLE_V4
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
            hdr.transport.vxlan.isValid(): exact;
#endif // #ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_transport_stack_hdr_cntr;
        }
        counters = transport_stack_hdr_cntrs;
        size = 32;  // Little slop built-in here

        // // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //      //enet  vlan0   nsh    ipv4   ipv6   gre    greSeq erspan udp    geneve vxlan  mpls0  mpls1  mpls2  mpls3
        //                                                                       
        //      // None                              
        //      ( false, false, false, false, false, false, false, false, false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr;
        //                                           
        //      // NSH                               
        //      ( true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //      ( true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //                                           
        //      // GRE                               
        //      ( true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //      ( true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr;
        //      ( true,  false, false, false, true,  true,  false, false, false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //      ( true,  true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr;
        //                                           
        //      // ERSPAN-TYPE2                      
        //      ( true,  false, false, true,  false, true,  true,  true,  false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //      ( true,  true,  false, true,  false, true,  true,  true,  false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //      ( true,  false, false, false, true,  true,  true,  true,  false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //      ( true,  true,  false, false, true,  true,  true,  true,  false, false, false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //                                           
        //      // GENEVE                            
        //      ( true,  false, false, true,  true,  false, false, false, true,  true,  false, false, false, false, false): bump_transport_stack_hdr_cntr; 
        //                                           
        //      // VXLAN                             
        //      ( true,  false, false, true,  true,  false, false, false, true,  false, true,  false, false, false, false): bump_transport_stack_hdr_cntr; 
        //                                           
        //      // MPLS                              
        //      ( true,  false, false, false, false, false, false, false, false, false, false, true,  false, false, false): bump_transport_stack_hdr_cntr; 
        //      ( true,  false, false, false, false, false, false, false, false, false, false, true,  true,  false, false): bump_transport_stack_hdr_cntr; 
        //      ( true,  false, false, false, false, false, false, false, false, false, false, true,  true,  true,  false): bump_transport_stack_hdr_cntr; 
        //      ( true,  false, false, false, false, false, false, false, false, false, false, true,  true,  true,  true ): bump_transport_stack_hdr_cntr; 
        // }
    }


    // ------------------------------------------------------------
    // outer stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_outer_stack_hdr_cntr() {
        outer_stack_hdr_cntrs.count();
    }
    
    table outer_stack_hdr_cntr_tbl {
        key = {
            hdr.outer.ethernet.isValid(): exact;
#ifdef ETAG_ENABLE
            hdr.outer.e_tag.isValid(): exact;
#endif // ETAG_ENABLE
#ifdef VNTAG_ENABLE
            hdr.outer.vn_tag.isValid(): exact;
#endif // VNTAG_ENABLE
            hdr.outer.vlan_tag[0].isValid(): exact;
            hdr.outer.vlan_tag[1].isValid(): exact;
#if defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
            hdr.outer.mpls[0].isValid(): exact;
            hdr.outer.mpls[1].isValid(): exact;
            hdr.outer.mpls[2].isValid(): exact;
            hdr.outer.mpls[3].isValid(): exact;
#endif // defined(MPLS_SR_ENABLE) || defined(MPLS_L2VPN_ENABLE) || defined(MPLS_L3VPN_ENABLE)
#ifdef MPLS_L2VPN_ENABLE
            hdr.outer.mpls_pw_cw.isValid(): exact;
#endif // MPLS_L2VPN_ENABLE            
            hdr.outer.ipv4.isValid(): exact;
            hdr.outer.ipv6.isValid(): exact;

            hdr.outer.udp.isValid(): exact;
            hdr.outer.tcp.isValid(): exact;
            hdr.outer.sctp.isValid(): exact;
            
            hdr.outer.gre.isValid(): exact;        
            hdr.outer.gre_optional.isValid(): exact;        
#ifdef GENEVE_ENABLE
            hdr.outer.geneve.isValid(): exact;
#endif // GENEVE_ENABLE    
#ifdef VXLAN_ENABLE
            hdr.outer.vxlan.isValid(): exact;
#endif // VXLAN_ENABLE    
#ifdef NVGRE_ENABLE
            hdr.outer.nvgre.isValid(): exact;
#endif // NVGRE_ENABLE    
            hdr.outer.gtp_v1_base.isValid(): exact;
            hdr.outer.gtp_v1_optional.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_outer_stack_hdr_cntr;
        }

        counters = outer_stack_hdr_cntrs;
        size = 512;  // There is a little slop built-in here (1+(9*53)+23)

        // const entries = {
        // 
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // None (invalid)                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2                                                                                  
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV4                                                                           
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV6                                                                           
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / UDP                                                                      
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / TCP                                                                       
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / SCTP                                                                      
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / GRE                                                                      
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                             
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / L4 / GENEVE                                                               
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     // L2 / L3 / L4 / VXLAN                                                               
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     // L2 / L3 / L4 / NVGRE
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U                                                                
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U w/ Sequence Number                                             
        //     ( true,  false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //
        //     // L2 / MPLS-SR
        //     ( true,  false, false, false, false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //
        // 
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //
        //     // L2 / MPLS (L2VPN)                                                              
        //     ( true,  false, false, false, false, true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  false, false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  false, true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  true,  true,      false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     // L2 / MPLS (L3VPN)                                                                                                                 
        //     ( true,  false, false, false, false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  false, false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  false, false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  true,  false,     false, false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //            
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //
        //     // L2 / GRE / MPLS (L2VPN)                                                              
        //     ( true,  false, false, false, false, true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  false, false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  false, false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  false, true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  false, true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  true,  true,      true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  true,  true,      false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //
        //     // L2 / GRE / MPLS (L3VPN)                                                                
        //     ( true,  false, false, false, false, true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  true,  false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                                                                          
        //     ( true,  false, false, false, false, true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  true,  true,  true,  false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //            
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // IPV4                                                                               
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // IPV6                                                                                
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  false, false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / UDP                                                                            
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / TCP                                                                            
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  false, true,  false, false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / SCTP                                                                           
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  false, false, true,  false, false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     //enet   etag   vntag  vlan0  vlan1  mpls0  mpls1  mpls2  mpls3  mpls_pw_cw ipv4   ipv6   udp    tcp    sctp   gre    gre_opt geneve vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                            
        //     // L3 / GRE                                                                            
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  true,   false, false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GENEVE                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / VXLAN                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / NVGRE                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  false, false, false, true,  false,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U w/ Sequence Number                                                  
        //     ( false, false, false, false, false, false, false, false, false, false,     true,  false, true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, false, false, false, false,     false, true,  true,  false, false, false, false,  false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // }
    }


    // ------------------------------------------------------------
    // inner stack ------------------------------------------------
    // ------------------------------------------------------------

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

#ifdef INNER_GRE_ENABLE
            hdr.inner.gre.isValid(): exact;        
            hdr.inner.gre_optional.isValid(): exact;
#endif // INNER_GRE_ENABLE
#ifdef INNER_GTP_ENABLE            
            hdr.inner.gtp_v1_base.isValid(): exact;
            hdr.inner.gtp_v1_optional.isValid(): exact;
#endif // INNER_GTP_ENABLE
        }

        actions = {
            //NoAction;
            bump_inner_stack_hdr_cntr;
        }

        counters = inner_stack_hdr_cntrs;
        size = 64; // There is some slop built-in here

        // const entries = {
        // 
        //     //enet   vlan0  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt gtp_v1 gtp_v1_opt
        //                                                                      
        //     // None (invalid)                                                
        //     ( false, false, false, false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2                                                             
        //     ( true,  false, false, false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3                                                        
        //     ( true,  false, true,  false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / UDP                                                  
        //     ( true,  false, true,  false, true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / TCP                                                  
        //     ( true,  false, true,  false, false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / SCTP                                                 
        //     ( true,  false, true,  false, false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / GRE                                                  
        //     ( true,  false, true,  false, false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / GRE w/ OPTIONAL                                       
        //     ( true,  false, true,  false, false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / UDP / GTP-U                                          
        //     ( true,  false, true,  false, true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L2 / L3 / UDP / GTP-U w/ Sequence Number                       
        //     ( true,  false, true,  false, true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3                                                             
        //     ( false, false, true,  false, false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / UDP                                                       
        //     ( false, false, true,  false, true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / TCP                                                       
        //     ( false, false, true,  false, false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, true,  false, false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / SCTP                                                      
        //     ( false, false, true,  false, false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, true,  false, false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / GRE                                                       
        //     ( false, false, true,  false, false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, true,  false,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / GRE w/ OPTIONAL                                            
        //     ( false, false, true,  false, false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, true,  true,   false, false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / UDP / GTP-U                                               
        //     ( false, false, true,  false, true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false,  true,  false ): bump_inner_stack_hdr_cntr;
        //                                                                       
        //     // L3 / UDP / GTP-U w/ Sequence Number                            
        //     ( false, false, true,  false, true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false,  true,  true  ): bump_inner_stack_hdr_cntr;
        // 
        // }        
    }


    
#ifdef UDF_ENABLE

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
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_udf_hdr_cntr;
        counters = udf_hdr_cntrs;

//         // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//             false: bump_udf_hdr_cntr; 
//             true:  bump_udf_hdr_cntr; 
//         }
    }

#endif // UDF_ENABLE
    
    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {        
        // Tables
#ifdef CPU_ENABLE            
        cpu_hdr_cntr_tbl.apply();
#endif // CPU_ENABLE
        transport_stack_hdr_cntr_tbl.apply();
        outer_stack_hdr_cntr_tbl.apply();
        inner_stack_hdr_cntr_tbl.apply();
#ifdef UDF_ENABLE            
        udf_hdr_cntr_tbl.apply();
#endif // UDF_ENABLE
    }

}

#endif /* _NPB_ING_HDR_STACK_COUNTERS_ */
