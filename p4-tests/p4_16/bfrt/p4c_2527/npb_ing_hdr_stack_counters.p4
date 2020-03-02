

control IngressHdrStackCounters(
    in switch_header_t hdr
) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) transport_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) outer_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) inner_stack_hdr_cntrs;

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
#ifdef ERSPAN_INGRESS_ENABLE
            hdr.transport.ipv4.isValid(): exact;
            hdr.transport.gre.isValid(): exact;
            hdr.transport.gre_sequence.isValid(): exact;
            hdr.transport.erspan_type2.isValid(): exact;
#endif // ERSPAN_INGRESS_ENABLE
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_transport_stack_hdr_cntr;
        }

        size = 3;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_transport_stack_hdr_cntr;
        // const default_action = bump_transport_stack_unexpected_hdr_cntr;
        counters = transport_stack_hdr_cntrs;

        // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
// #ifndef ERSPAN_INGRESS_ENABLE
//             //enet   vlan0  nsh
// 
//             // None
//             ( false, false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // NSH
//             ( true,  false, true ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true ): bump_transport_stack_hdr_cntr;
// #else
//             //enet  vlan0   nsh    ipv4   gre    greSeq erspan 
// 
//             // None
//             ( false, false, false, false, false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // ERSPAN-TYPE1
//             ( true,  false, false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr;
// 
//             // ERSPAN-TYPE2
//             ( true,  false, false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
// 
// 
// #endif // ERSPAN_INGRESS_ENABLE
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
            hdr.outer.e_tag.isValid(): exact;
            hdr.outer.vn_tag.isValid(): exact;
            hdr.outer.vlan_tag[0].isValid(): exact;
            hdr.outer.vlan_tag[1].isValid(): exact;
        
            hdr.outer.arp.isValid(): exact;
            hdr.outer.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
            hdr.outer.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
            
            hdr.outer.icmp.isValid(): exact;
            hdr.outer.igmp.isValid(): exact;
            hdr.outer.udp.isValid(): exact;
            hdr.outer.tcp.isValid(): exact;
            hdr.outer.sctp.isValid(): exact;
            
            hdr.outer.gre.isValid(): exact;        
            hdr.outer.esp.isValid(): exact;
            
            hdr.outer.vxlan.isValid(): exact;
            hdr.outer.nvgre.isValid(): exact;
            hdr.outer.gtp_v1_base.isValid(): exact;
            hdr.outer.gtp_v2_base.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_outer_stack_hdr_cntr;
        }

        size = 217;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_outer_stack_hdr_cntr;
        counters = outer_stack_hdr_cntrs;
        // Cannot have constant entries if we're going to clear counters in our test.
        // todo: IPV6_ENABLE/DISABLE versions of this
//         const entries = {
// 
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2
// 
//             // None (invalid)
//             ( false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2
//             ( true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / ARP
//             ( true,  false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / IPV4
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / IPV6
//             ( true,  false, false, false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2
// 
//             // L2 / L3 / ICMP
//             ( true,  false, false, false, false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//                      
//             ( true,  false, false, false, false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / IPV4 / IGMP
//             ( true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//                      
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2
// 
//             // L2 / L3 / UDP
//             ( true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / TCP
//             ( true,  false, false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / SCTP
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//                      
//             ( true,  false, false, false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2
// 
//             // L2 / L3 / GRE
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / IPV4 / ESP
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
// 
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2
// 
//             // L2 / L3 / L4 / VXLAN
//             ( true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / L4 / NVGRE
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / L4 / GTP-U
//             ( true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / L4 / GTP-C
//             ( true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, true  ): bump_outer_stack_hdr_cntr;
//         }
    }



    // ------------------------------------------------------------
    // inner stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_inner_stack_hdr_cntr() {
        inner_stack_hdr_cntrs.count();
    }
    
    table inner_stack_hdr_cntr_tbl {
        key = {
            hdr.inner.ethernet.isValid(): exact;
            hdr.inner.vlan_tag[0].isValid(): exact;

            //hdr.inner.arp.isValid(): exact;
            hdr.inner.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE            
            hdr.inner.ipv6.isValid(): exact;
#endif // IPV6_ENABLE
            //hdr.inner.icmp.isValid(): exact;
            //hdr.inner.igmp.isValid(): exact;
            hdr.inner.udp.isValid(): exact;
            hdr.inner.tcp.isValid(): exact;
            hdr.inner.sctp.isValid(): exact;

            //hdr.inner.gre.isValid(): exact;        
            //hdr.inner.esp.isValid(): exact;

            //hdr.inner.gtp_v1_base.isValid(): exact;
            //hdr.inner.gtp_v2_base.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_inner_stack_hdr_cntr;
        }

        size = 27;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_inner_stack_hdr_cntr;
        counters = inner_stack_hdr_cntrs;
        // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
// 
// #ifdef IPV6_ENABLE
// 
//             //enet   vlan0  ipv4   ipv6   udp    tcp    sctp   gre    esp
// 
//             // None (invalid)
//             ( false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2                                             
//             ( true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2 / L3                                        
//             ( true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2 / L3 / UDP                                  
//             ( true,  false, true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2 / L3 / TCP                                  
//             ( true,  false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2 / L3 / SCTP                                 
//             ( true,  false, true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
// 
//             // L3                                        
//             ( false, false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L3 / UDP                                  
//             ( false, false, true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L3 / TCP                                  
//             ( false, false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L3 / SCTP                                 
//             ( false, false, true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
// 
//             // // L2 / L3 / GRE
//             // ( true,  false, true,  false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  true,  false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  false, false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
// 
//             // // L2 / IPV4 / ESP
//             // ( true,  false, true,  false, false, false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  true,  false, false, false, false, false, true  ): bump_inner_stack_hdr_cntr;
// 
//             // // L3 / GRE
//             // // L3 / ESP
// 
// #else
// 
//             //enet   vlan0  ipv4   udp    tcp    sctp   gre    esp
// 
//             // None (invalid)
//             ( false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//                                                        
//             // L2                                      
//             ( true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
//                                                        
//             // L2 / L3                                 
//             ( true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
//                                                        
//             // L2 / L3 / UDP                           
//             ( true,  false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
//                                                        
//             // L2 / L3 / TCP                           
//             ( true,  false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
//                                                        
//             // L2 / L3 / SCTP                          
//             ( true,  false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
// 
//             // L3                                 
//             ( false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//                                                        
//             // L3 / UDP                           
//             ( false, false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  false, false ): bump_inner_stack_hdr_cntr;
//                                                        
//             // L3 / TCP                           
//             ( false, false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//                                                        
//             // L3 / SCTP                          
//             ( false, false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, false, false, true  ): bump_inner_stack_hdr_cntr;
// 
//             // // L2 / L3 / GRE
//             // ( true,  false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  false, false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
// 
//             // // L2 / IPV4 / ESP
//             // ( true,  false, true,  false, false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  true,  false, false, false, false, true  ): bump_inner_stack_hdr_cntr;
// 
//             // // L3 / GRE
//             // // L3 / ESP
// 
// #endif // IPV6_ENABLE          
// 
//         }
    }



    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {

        transport_stack_hdr_cntr_tbl.apply();
        outer_stack_hdr_cntr_tbl.apply();
        inner_stack_hdr_cntr_tbl.apply();
    }

}


