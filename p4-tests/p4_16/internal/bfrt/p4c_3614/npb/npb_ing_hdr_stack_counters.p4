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


    // ------------------------------------------------------------
    // local variables to support ifdefs

    // error: PHV allocation creates an invalid container action within a Tofino ALU
    // bool hdr_transport_ipv4_isValid;
    // bool hdr_transport_gre_isValid;
    // bool hdr_transport_gre_sequence_isValid;
    // bool hdr_transport_erspan_type2_isValid;
    
    bool hdr_outer_ipv6_isValid;
    bool hdr_inner_ipv6_isValid;
    
    bool hdr_inner_gtp_v1_base_isValid;
    bool hdr_inner_gtp_v1_optional_isValid;
    bool hdr_inner_gre_isValid;
    bool hdr_inner_gre_optional_isValid;


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
            // hdr_transport_ipv4_isValid: exact;
            // hdr_transport_gre_isValid: exact;
            // hdr_transport_gre_sequence_isValid: exact;
            // hdr_transport_erspan_type2_isValid: exact;
#if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
            hdr.transport.ipv4.isValid(): exact;
            hdr.transport.gre.isValid(): exact;
#ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
            hdr.transport.gre_sequence.isValid(): exact;
            hdr.transport.erspan_type2.isValid(): exact;
#endif // #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
#endif // #if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_transport_stack_hdr_cntr;
        }

#ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
        size = 9;
#elif defined(GRE_TRANSPORT_INGRESS_ENABLE)
        size = 5;
#else 
        size = 3;
#endif // #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE

        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_transport_stack_hdr_cntr;
        // const default_action = bump_transport_stack_unexpected_hdr_cntr;
        counters = transport_stack_hdr_cntrs;

        // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//
// #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//
//             //enet  vlan0   nsh    ipv4   gre    greSeq erspan 
// 
//             // None
//             ( false, false, false, false, false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false, true,  true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  false, false ): bump_transport_stack_hdr_cntr;
// 
//             // ERSPAN-TYPE1
//             ( true,  false, false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr;
// 
//             // ERSPAN-TYPE2
//             ( true,  false, false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
//
// #elif defined(GRE_TRANSPORT_INGRESS_ENABLE)
//
//             //enet  vlan0   nsh    ipv4   gre
// 
//             // None
//             ( false, false, false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true,  false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false, true,  true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true  ): bump_transport_stack_hdr_cntr;
// 
// #else
// 
//             //enet  vlan0   nsh
// 
//             // None
//             ( false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true  ): bump_transport_stack_hdr_cntr; 
// 
//             // GRE
//             ( true,  false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false ): bump_transport_stack_hdr_cntr;
// 
// #endif // #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//         }
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
        
            hdr.outer.ipv4.isValid(): exact;
            hdr_outer_ipv6_isValid: exact;
            
            hdr.outer.udp.isValid(): exact;
            hdr.outer.tcp.isValid(): exact;
            hdr.outer.sctp.isValid(): exact;
            
            hdr.outer.gre.isValid(): exact;        
            hdr.outer.gre_optional.isValid(): exact;        
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

// VXLAN  NVGRE  ETAG  VNTAG
//   1      1      1     1
        
#if defined(VXLAN_ENABLE) && defined(NVGRE_ENABLE) && defined(ETAG_ENABLE) && defined(VNTAG_ENABLE) 
        
        size = 210;  // was 190 prior to adding gre_opt

        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_outer_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // None (invalid)                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2                                                                                  
        //     ( true,  false, false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV4                                                                           
        //     ( true,  false, false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV6                                                                           
        //     ( true,  false, false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / UDP                                                                      
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / TCP                                                                       
        //     ( true,  false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / SCTP                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / GRE                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                             
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 

        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // L2 / L3 / L4 / VXLAN                                                               
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     // L2 / L3 / L4 / NVGRE
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U                                                                
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U w/ Sequence Number                                             
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                           
        //     // IPV4                                                                               
        //     ( false, false, false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // IPV6                                                                                
        //     ( false, false, false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / UDP                                                                            
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / TCP                                                                            
        //     ( false, false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / SCTP                                                                           
        //     ( false, false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //                                                                                            
        //     // L3 / GRE                                                                            
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / VXLAN                                                                     
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / NVGRE                                                                     
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U                                                                     
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U w/ Sequence Number                                                  
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // }

#endif // defined(VXLAN_ENABLE) && defined(NVGRE_ENABLE) && defined(ETAG_ENABLE) && defined(VNTAG_ENABLE) 



// VXLAN  NVGRE  ETAG  VNTAG
//   1      1      1     0
//   1      1      0     1
        
#if ((defined(VXLAN_ENABLE) && defined(NVGRE_ENABLE) && defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)) || \
     (defined(VXLAN_ENABLE) && defined(NVGRE_ENABLE) && !defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)))
        
        size = 147;  // was 133 prior to adding gre_opt

        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_outer_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   etag   vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre-opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //     //       vntag                                                                 
        //                                                                                    
        //     // None (invalid)                                                              
        //     ( false, false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2                                                                           
        //     ( true,  false, false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / IPV4                                                                    
        //     ( true,  false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / IPV6                                                                    
        //     ( true,  false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //     //       vntag                                                                 
        //                                                                                    
        //     // L2 / L3 / UDP                                                               
        //     ( true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / TCP                                                                
        //     ( true,  false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / SCTP                                                               
        //     ( true,  false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //     //       vntag                                                                 
        //                                                                                    
        //     // L2 / L3 / GRE                                                               
        //     ( true,  false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / L4 / VXLAN                                                         
        //     ( true,  false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / L4 / NVGRE                                                         
        //     ( true,  false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / L4 / GTP-U                                                         
        //     ( true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / L4 / GTP-U w/ Sequence Number                                      
        //     ( true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  nvgre  gtp_v1 gtp_v1_opt
        //     //       vntag                                                                 
        //                                                                                    
        //     // IPV4                                                                        
        //     ( false, false, false, false, true,  false, false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // IPV6                                                                         
        //     ( false, false, false, false, false, true,  false, false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / UDP                                                                     
        //     ( false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / TCP                                                                     
        //     ( false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / SCTP                                                                    
        //     ( false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / GRE                                                                     
        //     ( false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / L4 / VXLAN                                                              
        //     ( false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / L4 / NVGRE                                                              
        //     ( false, false, false, false, true,  false, false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, true,  false,  false, true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / L4 / GTP-U                                                              
        //     ( false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / L4 / GTP-U w/ Sequence Number                                           
        //     ( false, false, false, false, true,  false, true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  true,  false, false, false, false,  false, false, true,  true  ): bump_outer_stack_hdr_cntr;
        // }

#endif


// VXLAN  NVGRE  ETAG  VNTAG
//   1      0      1     1
//   0      1      1     1        

#if ((defined(VXLAN_ENABLE) && !defined(NVGRE_ENABLE) && defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)) || \
     (!defined(VXLAN_ENABLE) && defined(NVGRE_ENABLE) && defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)))

        size = 210; // was 190 prior to adding gre_opt

        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_outer_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  gtp_v1 gtp_v1_opt
        //     //                                                                                     nvgre
        //                                                                                           
        //     // None (invalid)                                                                     
        //     ( false, false, false, false, false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2                                                                                  
        //     ( true,  false, false, false, false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV4                                                                           
        //     ( true,  false, false, false, false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / IPV6                                                                           
        //     ( true,  false, false, false, false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  gtp_v1 gtp_v1_opt
        //     //                                                                                     nvgre
        //                                                                                           
        //     // L2 / L3 / UDP                                                                      
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / TCP                                                                       
        //     ( true,  false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / SCTP                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  gtp_v1 gtp_v1_opt
        //     //                                                                                     nvgre
        //                                                                                           
        //     // L2 / L3 / GRE                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                             
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / VXLAN                                                                
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / NVGRE                                                                
        //     ( true,  false, false, false, false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L2 / L3 / L4 / GTP-U                                                                
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        // 
        //     // L2 / L3 / L4 / GTP-U w/ Sequence Number
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //                                                                                                   
        //     ( true,  false, false, false, false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vntag  vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  gtp_v1 gtp_v1_opt
        //     //                                                                                     nvgre
        //                                                                                           
        //     // IPV4                                                                               
        //     ( false, false, false, false, false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // IPV6                                                                                
        //     ( false, false, false, false, false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / UDP                                                                            
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / TCP                                                                            
        //     ( false, false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / SCTP                                                                           
        //     ( false, false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / GRE                                                                            
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / VXLAN                                                                     
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / NVGRE                                                                     
        //     ( false, false, false, false, false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U                                                                     
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                            
        //     // L3 / L4 / GTP-U w/ Sequence Number                                                  
        //     ( false, false, false, false, false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        // }

#endif


// VXLAN  NVGRE  ETAG  VNTAG
//   1      0      1     0
//   1      0      0     1
//   0      1      1     0
//   0      1      0     1
        
#if ((defined(VXLAN_ENABLE) && !defined(NVGRE_ENABLE) && defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)) || \
     (defined(VXLAN_ENABLE) && !defined(NVGRE_ENABLE) && !defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)) || \
     (!defined(VXLAN_ENABLE) && defined(NVGRE_ENABLE) && defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)) || \
     (!defined(VXLAN_ENABLE) && defined(NVGRE_ENABLE) && !defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)))
        
        size = 147; // was 133 prior to adding gre_opt

        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_outer_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   etag   vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  gtp_v1 gtp_v1_opt
        //     //       vntag                                                                  nvgre
        //                                                                                    
        //     // None (invalid)                                                              
        //     ( false, false, false, false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2                                                                           
        //     ( true,  false, false, false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / IPV4                                                                    
        //     ( true,  false, false, false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / IPV6                                                                    
        //     ( true,  false, false, false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  gtp_v1 gtp_v1_opt
        //     //       vntag                                                                  nvgre
        //                                                                                    
        //     // L2 / L3 / UDP                                                               
        //     ( true,  false, false, false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / TCP                                                                
        //     ( true,  false, false, false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / SCTP                                                               
        //     ( true,  false, false, false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gtp_opt vxlan  gtp_v1 gtp_v1_opt
        //     //       vntag                                                                  nvgre
        //                                                                                    
        //     // L2 / L3 / GRE                                                               
        //     ( true,  false, false, false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                      
        //     ( true,  false, false, false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / L4 / VXLAN                                                         
        //     ( true,  false, false, false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / L4 / NVGRE                                                         
        //     ( true,  false, false, false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / L4 / GTP-U                                                         
        //     ( true,  false, false, false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L2 / L3 / L4 / GTP-U w/ Sequence Number                                      
        //     ( true,  false, false, false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     ( true,  false, false, false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  false, true,  true,  false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( true,  true,  true,  true,  false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        // 
        //     //enet   etag   vlan0  vlan1  ipv4   ipv6   udp    tcp    sctp   gre    gre_opt vxlan  gtp_v1 gtp_v1_opt
        //     //       vntag                                                                  nvgre
        //                                                                                    
        //     // IPV4                                                                        
        //     ( false, false, false, false, true,  false, false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // IPV6                                                                         
        //     ( false, false, false, false, false, true,  false, false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / UDP                                                                     
        //     ( false, false, false, false, true,  false, true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  true,  false, false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / TCP                                                                     
        //     ( false, false, false, false, true,  false, false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, true,  false, false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / SCTP                                                                    
        //     ( false, false, false, false, true,  false, false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, true,  false, false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / GRE                                                                     
        //     ( false, false, false, false, true,  false, false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, true,  false,  false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, true,  false, false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, true,  true,   false, false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / L4 / VXLAN                                                              
        //     ( false, false, false, false, true,  false, true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  true,  false, false, false, false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / L4 / NVGRE                                                              
        //     ( false, false, false, false, true,  false, false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  false, false, false, true,  false,  true,  false, false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / L4 / GTP-U                                                              
        //     ( false, false, false, false, true,  false, true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  true,  false, false, false, false,  false, true,  false ): bump_outer_stack_hdr_cntr;
        //                                                                                     
        //     // L3 / L4 / GTP-U w/ Sequence Number                                           
        //     ( false, false, false, false, true,  false, true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        //     ( false, false, false, false, false, true,  true,  false, false, false, false,  false, true,  true  ): bump_outer_stack_hdr_cntr;
        // }

#endif

        
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


#if defined(INNER_GRE_ENABLE) && defined(INNER_GTP_ENABLE)
        
        size = 51;  // Was 45 prior to addnig gre optional
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_inner_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
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

#endif // defined(INNER_GRE_ENABLE) && defined(INNER_GTP_ENABLE)

#if !defined(INNER_GRE_ENABLE) && defined(INNER_GTP_ENABLE)

        size = 39;  // Was 41 prior to removing arp
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_inner_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   vlan0  ipv4   ipv6   udp    tcp    sctp   gtp_v1 gtp_v1_opt
        // 
        //     // None (invalid)
        //     ( false, false, false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2
        //     ( true,  false, false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3
        //     ( true,  false, true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / UDP
        //     ( true,  false, true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / TCP
        //     ( true,  false, true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / SCTP
        //     ( true,  false, true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / UDP / GTP-U
        //     ( true,  false, true,  false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / UDP / GTP-U w/ Sequence Number
        //     ( true,  false, true,  false, true,  false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3
        //     ( false, false, true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / UDP
        //     ( false, false, true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / TCP
        //     ( false, false, true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / SCTP
        //     ( false, false, true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / UDP / GTP-U
        //     ( false, false, true,  false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / UDP / GTP-U w/ Sequence Number
        //     ( false, false, true,  false, true,  false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        // 
        // }

#endif // !defined(INNER_GRE_ENABLE) && defined(INNER_GTP_ENABLE)

#if defined(INNER_GRE_ENABLE) && !defined(INNER_GTP_ENABLE)
        
        size = 39;  // Was 33 prior to adding gre optional
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_inner_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   vlan0  ipv4   ipv6   udp    tcp    sctp   gre   gre_opt
        // 
        //     // None (invalid)
        //     ( false, false, false, false, false, false, false, false false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L2                                                          
        //     ( true,  false, false, false, false, false, false, false false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false, false false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L2 / L3                                                     
        //     ( true,  false, true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L2 / L3 / UDP                                               
        //     ( true,  false, true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L2 / L3 / TCP                                               
        //     ( true,  false, true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L2 / L3 / SCTP                                              
        //     ( true,  false, true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L2 / L3 / GRE                                               
        //     ( true,  false, true,  false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L2 / L3 / GRE w/ OPTIONAL
        //     ( true,  false, true,  false, false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L3                                                          
        //     ( false, false, true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L3 / UDP                                                    
        //     ( false, false, true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L3 / TCP                                                    
        //     ( false, false, true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L3 / SCTP                                                   
        //     ( false, false, true,  false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //                                                                    
        //     // L3 / GRE                                                    
        //     ( false, false, true,  false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / GRE w/ OPTIONAL
        //     ( false, false, true,  false, false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false, true,  true  ): bump_inner_stack_hdr_cntr;
        // 
        // }

#endif // defined(INNER_GRE_ENABLE) && !defined(INNER_GTP_ENABLE)

#if !defined(INNER_GRE_ENABLE) && !defined(INNER_GTP_ENABLE)

        size = 27;  // Was 29 prior to removing arp
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_inner_stack_hdr_cntr;
        // Cannot have constant entries if we're going to clear counters in our test.
        // const entries = {
        // 
        //     //enet   vlan0  ipv4   ipv6   udp    tcp    sctp   
        // 
        //     // None (invalid)
        //     ( false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2
        //     ( true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3
        //     ( true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / UDP
        //     ( true,  false, true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / TCP
        //     ( true,  false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L2 / L3 / SCTP
        //     ( true,  false, true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  false, false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
        //     ( true,  true,  false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3
        //     ( false, false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / UDP
        //     ( false, false, true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / TCP
        //     ( false, false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
        // 
        //     // L3 / SCTP
        //     ( false, false, true,  false, false, false, true, ): bump_inner_stack_hdr_cntr;
        //     ( false, false, false, true,  false, false, true, ): bump_inner_stack_hdr_cntr;
        // 
        // }

#endif // !defined(INNER_GRE_ENABLE) && !defined(INNER_GTP_ENABLE)
        
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

    // Stubs (for #defines)

// error: PHV allocation creates an invalid container action within a Tofino ALU
// #if defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
//     hdr_transport_ipv4_isValid = hdr.transport.ipv4.isValid();
//     hdr_transport_gre_isValid = hdr.transport.gre.isValid();
// #else
//     hdr_transport_ipv4_isValid = false;
//     hdr_transport_gre_isValid = false;
// #endif // defined(GRE_TRANSPORT_INGRESS_ENABLE) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE)
//         
// #ifdef ERSPAN_TRANSPORT_INGRESS_ENABLE
//     hdr_transport_gre_sequence_isValid = hdr.transport.gre_sequence.isValid();
//     hdr_transport_erspan_type2_isValid = hdr.transport.erspan_type2.isValid();
// #else
//     hdr_transport_gre_sequence_isValid = false;
//     hdr_transport_erspan_type2_isValid = false;
// #endif // ERSPAN_TRANSPORT_INGRESS_ENABLE

        
#ifdef IPV6_ENABLE
        hdr_outer_ipv6_isValid = hdr.outer.ipv6.isValid();
        hdr_inner_ipv6_isValid = hdr.inner.ipv6.isValid();
#else
        hdr_outer_ipv6_isValid = false;
        hdr_inner_ipv6_isValid = false;
#endif // IPV6_ENABLE


#ifdef INNER_GTP_ENABLE
        hdr_inner_gtp_v1_base_isValid = hdr.inner.gtp_v1_base.isValid();
        hdr_inner_gtp_v1_optional_isValid = hdr.inner.gtp_v1_optional.isValid();
#else
        hdr_inner_gtp_v1_base_isValid = false;
        hdr_inner_gtp_v1_optional_isValid = false;
#endif // INNER_GTP_ENABLE
        
#ifdef INNER_GRE_ENABLE    
        hdr_inner_gre_isValid = hdr.inner.gre.isValid();
        hdr_inner_gre_optional_isValid = hdr.inner.gre_optional.isValid();
#else
        hdr_inner_gre_isValid = false;
        hdr_inner_gre_optional_isValid = false;
#endif // INNER_GRE_ENABLE


        
        // Tables
#ifdef CPU_ENABLE            
        cpu_hdr_cntr_tbl.apply();
#endif // UDF_ENABLE
        transport_stack_hdr_cntr_tbl.apply();
        outer_stack_hdr_cntr_tbl.apply();
        inner_stack_hdr_cntr_tbl.apply();
#ifdef UDF_ENABLE            
        udf_hdr_cntr_tbl.apply();
#endif // UDF_ENABLE
    }

}

