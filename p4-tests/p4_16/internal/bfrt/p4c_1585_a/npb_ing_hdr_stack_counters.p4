

control IngressHdrStackCounters(in switch_header_t hdr) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_outer;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_outer_tunnel;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_inner;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_inner_tunnel;
// #ifdef INNER_INNER_PARSER_ENABLE
//     DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_inner_inner;
// #endif  /* INNER_INNER_PARSER_ENABLE */


    bit<2> cntrs_outer_addr_l3 = 0;
    bit<3> cntrs_outer_addr_l4 = 0;
    bit<4> cntrs_outer_tnl_addr = 0;
    bit<2> cntrs_inner_addr_l3 = 0;
    bit<3> cntrs_inner_addr_l4 = 0;
    bit<3> cntrs_inner_tnl_addr = 0;


    // ------------------------------------------------------------
    // outer ------------------------------------------------------
    // ------------------------------------------------------------

    action hit_outer() {
        cntrs_outer.count();
    }

    table cntrs_outer_tbl {
        key = {
            hdr.ethernet.isValid() : exact;
            hdr.e_tag.isValid() : exact;
            hdr.vn_tag.isValid() : exact;
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[1].isValid() : exact;
            hdr.vlan_tag[2].isValid() : exact;
            cntrs_outer_addr_l3 : exact;
            cntrs_outer_addr_l4 : exact;
        }

        actions = {
            //NoAction;
            hit_outer;
        }

        //const default_action = NoAction;
        //const default_action = hit_outer;
        size = 2048;
        counters = cntrs_outer;
    }

    // ------------------------------------------------------------
    // outer tunnel -----------------------------------------------
    // ------------------------------------------------------------

    action hit_outer_tunnel() {
        cntrs_outer_tunnel.count();
    }

    table cntrs_outer_tunnel_tbl {
        key = {
            cntrs_outer_tnl_addr : exact;
#ifdef MPLS_ENABLE
            hdr.mpls_pw_cw.isValid() : exact;
            hdr.mpls[3].isValid() : exact;
            hdr.mpls[2].isValid() : exact;
            hdr.mpls[1].isValid() : exact;
            hdr.mpls[0].isValid() : exact;
#endif  /* MPLS_ENABLE */
        }

        actions = {
            //NoAction;
            hit_outer_tunnel;
        }

        //const default_action = NoAction;
        //const default_action = hit_outer_tunnel;
        size = 512;
        counters = cntrs_outer_tunnel;
    }

    // ------------------------------------------------------------
    // inner ------------------------------------------------------
    // ------------------------------------------------------------

    action hit_inner() {
        cntrs_inner.count();
    }

    table cntrs_inner_tbl {
        key = {
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_vlan_tag.isValid() : exact;
            cntrs_inner_addr_l3 : exact;
            cntrs_inner_addr_l4 : exact;
        }

        actions = {
            //NoAction;
            hit_inner;
        }

        //const default_action = NoAction;
        //const default_action = hit_inner;
        size = 128;
        counters = cntrs_inner;
    }

    // ------------------------------------------------------------
    // inner tunnel -----------------------------------------------
    // ------------------------------------------------------------

    action hit_inner_tunnel() {
        cntrs_inner_tunnel.count();
    }

    table cntrs_inner_tunnel_tbl {
        key = {
            cntrs_inner_tnl_addr : exact;
// #ifdef MPLS_ENABLE
//             hdr.inner_mpls_pw_cw.isValid() : exact;
//             hdr.inner_mpls[3].isValid() : exact;
//             hdr.inner_mpls[2].isValid() : exact;
//             hdr.inner_mpls[1].isValid() : exact;
//             hdr.inner_mpls[0].isValid() : exact;
// #endif  /* MPLS_ENABLE */
        }

        actions = {
            //NoAction;
            hit_inner_tunnel;
        }

        //const default_action = NoAction;
        //const default_action = hit_inner_tunnel;
        size = 256;
        counters = cntrs_inner_tunnel;
    }


//     // ----------------------------------------------
//     // inner inner ----------------------------------
//     // ----------------------------------------------
// #ifdef INNER_INNER_PARSER_ENABLE
// 
//     action hit_inner_inner() {
//         cntrs_inner_inner.count();
//     }
// 
//     table cntrs_inner_inner_tbl {
//         key = {
//             hdr.inner_inner_ethernet.isValid() : exact;
//             hdr.inner_inner_vlan_tag.isValid() : exact;
//             hdr.inner_inner_ipv4.isValid() : exact;
//             hdr.inner_inner_ipv6.isValid() : exact;
//             hdr.inner_inner_icmp.isValid() : exact;
//             hdr.inner_inner_igmp.isValid() : exact;
//             hdr.inner_inner_udp.isValid() : exact;
//             hdr.inner_inner_tcp.isValid() : exact;
//             hdr.inner_inner_sctp.isValid() : exact;
//             hdr.inner_inner_gre.isValid() : exact;
//             hdr.inner_inner_esp.isValid() : exact;
//         }
// 
//         actions = {
//             //NoAction;
//             hit_inner_inner;
//         }
// 
//         //const default_action = NoAction;
//         //const default_action = hit_inner_inner;
//         size = 2048;
//         counters = cntrs_inner_inner;
//     }
// #endif  /* INNER_INNER_PARSER_ENABLE */


    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {

        // outer  -------------------------------------------------
        // --------------------------------------------------------

        // encode outer l3 address (2 bits)
        if(hdr.ipv4.isValid()) {
            cntrs_outer_addr_l3 = 1;
        }
        else if(hdr.ipv6.isValid()) {
            cntrs_outer_addr_l3 = 2;
        }
        else if(hdr.arp.isValid()) {
            cntrs_outer_addr_l3 = 3;
        }
        else {
            cntrs_outer_addr_l3 = 0;
        }

        // encode outer l4 address (3 bits)
        if(hdr.icmp.isValid()) {
            cntrs_outer_addr_l4 = 1;
        }
        else if(hdr.igmp.isValid()) {
            cntrs_outer_addr_l4 = 2;
        }
        else if(hdr.udp.isValid()) {
            cntrs_outer_addr_l4 = 3;
        }
        else if(hdr.tcp.isValid()) {
            cntrs_outer_addr_l4 = 4;
        }
        else if(hdr.sctp.isValid()) {
            cntrs_outer_addr_l4 = 5;
        }
        else {
            cntrs_outer_addr_l4 = 0;
        }

        // outer tunnel -------------------------------------------
        // --------------------------------------------------------

        // encode outer tunnel address (4 bits)
        // if(hdr.nsh_extr.isValid()) {
        //     cntrs_outer_tnl_addr = 1;
        // }
        // else if(hdr.erspan_type1.isValid()) {  // GRE/ERSPAN
        //     cntrs_outer_tnl_addr = 2;
        // }
        // else if(hdr.erspan_type2.isValid()) {  // GRE/ERSPAN
        //     cntrs_outer_tnl_addr = 3;
        // }

        if(hdr.vxlan.isValid()) {
            cntrs_outer_tnl_addr = 4;
        }

        else if(hdr.nvgre.isValid()) {
            cntrs_outer_tnl_addr = 5;
        }
        // GRE must come after ERSPAN and NVGRE
        else if(hdr.gre.isValid()) {
            cntrs_outer_tnl_addr = 6;
        }

        else if(hdr.esp.isValid()) {
            cntrs_outer_tnl_addr = 7;
        }

#ifdef GTP_ENABLE
        else if(hdr.gtp_v1_optional.isValid()) {
            cntrs_outer_tnl_addr = 8;
        }
        // GTP must come after GTP-Opt
        else if(hdr.gtp_v1_base.isValid()) {
            cntrs_outer_tnl_addr = 9;
        }
#endif  /* GTP_ENABLE */

        else {
            cntrs_outer_tnl_addr = 0;
        }

        // inner  -------------------------------------------------
        // --------------------------------------------------------

        // encode inner l3 address (2 bits)
        if(hdr.inner_ipv4.isValid()) {
            cntrs_inner_addr_l3 = 1;
        }
        else if(hdr.inner_ipv6.isValid()) {
            cntrs_inner_addr_l3 = 2;
        }
        else {
            cntrs_inner_addr_l3 = 0;
        }

        // encode inner l4 address (3 bits)
        if(hdr.inner_icmp.isValid()) {
            cntrs_inner_addr_l4 = 1;
        }
        else if(hdr.inner_igmp.isValid()) {
            cntrs_inner_addr_l4 = 2;
        }
        else if(hdr.inner_udp.isValid()) {
            cntrs_inner_addr_l4 = 3;
        }
        else if(hdr.inner_tcp.isValid()) {
            cntrs_inner_addr_l4 = 4;
        }
        else if(hdr.inner_sctp.isValid()) {
            cntrs_inner_addr_l4 = 5;
        }
        else {
            cntrs_inner_addr_l4 = 0;
        }

        // inner tunnel  ------------------------------------------
        // --------------------------------------------------------

        // // encode inner tunnel address (3 bits)
        // if(hdr.inner_vxlan.isValid()) {
        //     cntrs_inner_tnl_addr = 1;
        // }
        // 
        // else if(hdr.inner_nvgre.isValid()) {
        //     cntrs_inner_tnl_addr = 2;
        // }
        // GRE must come after ERSPAN and NVGRE
        if(hdr.inner_gre.isValid()) {
            cntrs_inner_tnl_addr = 3;
        }
        else if(hdr.inner_esp.isValid()) {
            cntrs_inner_tnl_addr = 4;
        }

// #ifdef GTP_ENABLE
//         else if(hdr.inner_gtp_v1_optional.isValid()) {
//             cntrs_inner_tnl_addr = 5;
//         }
//         // GTP must come after GTP-Opt
//         else if(hdr.inner_gtp_v1_base.isValid()) {
//             cntrs_inner_tnl_addr = 6;
//         }
// #endif  /* GTP_ENABLE */

        else {
            cntrs_inner_tnl_addr = 0;
        }


        cntrs_outer_tbl.apply();
        cntrs_outer_tunnel_tbl.apply();
        cntrs_inner_tbl.apply();
        cntrs_inner_tunnel_tbl.apply();
// #ifdef INNER_INNER_PARSER_ENABLE
//         cntrs_inner_inner_tbl.apply();
// #endif  /* INNER_INNER_PARSER_ENABLE */

    }

}


