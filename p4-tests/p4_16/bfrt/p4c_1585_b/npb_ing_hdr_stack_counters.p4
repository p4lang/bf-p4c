

control IngressHdrStackCounters(in switch_header_t hdr) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_underlay_tunnel;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_outer;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_tunnel;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) cntrs_inner;

    bit<3> cntrs_underlay_tunnel_addr = 0;
    bit<2> cntrs_outer_addr_l3 = 0;
    bit<3> cntrs_outer_addr_l4 = 0;
    bit<3> cntrs_tunnel_addr = 0;
    bit<2> cntrs_inner_addr_l3 = 0;
    bit<3> cntrs_inner_addr_l4 = 0;


    // ------------------------------------------------------------
    // tunnel underlay --------------------------------------------
    // ------------------------------------------------------------

    action hit_underlay_tunnel() {
        cntrs_underlay_tunnel.count();
    }

    table cntrs_underlay_tunnel_tbl {
        key = {
            cntrs_underlay_tunnel_addr : exact;
        }

        actions = {
            //NoAction;
            hit_underlay_tunnel;
        }

        //const default_action = NoAction;
        //const default_action = hit_underlay_tunnel;
        size = 8;
        counters = cntrs_underlay_tunnel;
    }

    // ------------------------------------------------------------
    // L2/L3/L4 outer ---------------------------------------------
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
    // tunnel -----------------------------------------------------
    // ------------------------------------------------------------

    action hit_tunnel() {
        cntrs_tunnel.count();
    }

    table cntrs_tunnel_tbl {
        key = {
            cntrs_tunnel_addr : exact;
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
            hit_tunnel;
        }

        //const default_action = NoAction;
        //const default_action = hit_outer_tunnel;
        size = 256;
        counters = cntrs_tunnel;
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
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {

        // tunnel underlay ----------------------------------------
        // --------------------------------------------------------

        // encode underlay tunnel address (3 bits)
        if(hdr.nsh_extr_underlay.isValid()) {
            cntrs_underlay_tunnel_addr = 1;
        }
        // else if(hdr.erspan_type1_underlay.isValid()) {  // GRE/ERSPAN
        //     cntrs_outer_tnl_addr = 2;
        // }
        // else if(hdr.erspan_type2_underlay.isValid()) {  // GRE/ERSPAN
        //     cntrs_outer_tnl_addr = 3;
        // }
        // else if(hdr.vxlan_underlay.isValid()) {
        //     cntrs_outer_tnl_addr = 4;
        // }

        // L2/L3/L4 outer -----------------------------------------
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

        // tunnel -------------------------------------------------
        // --------------------------------------------------------

        // encode tunnel address (3 bits)
        if(hdr.vxlan.isValid()) {
            cntrs_tunnel_addr = 1;
        }

        else if(hdr.nvgre.isValid()) {
            cntrs_tunnel_addr = 2;
        }
        // GRE must come after ERSPAN and NVGRE
        else if(hdr.gre.isValid()) {
            cntrs_tunnel_addr = 3;
        }

        else if(hdr.esp.isValid()) {
            cntrs_tunnel_addr = 4;
        }

#ifdef GTP_ENABLE
        else if(hdr.gtp_v2_optional_teid.isValid()) { //GTP-C
            cntrs_tunnel_addr = 5;
        }
        else if(hdr.gtp_v1_base.isValid()) { //GTP-U
            cntrs_tunnel_addr = 6;
        }
#endif  /* GTP_ENABLE */

        else {
            cntrs_tunnel_addr = 0;
        }

        // L2/L3/L4 inner  ----------------------------------------
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

        cntrs_underlay_tunnel_tbl.apply();
        cntrs_outer_tbl.apply();
        cntrs_tunnel_tbl.apply();
        cntrs_inner_tbl.apply();

    }

}


