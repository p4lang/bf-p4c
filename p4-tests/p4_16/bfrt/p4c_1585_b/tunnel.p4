/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

#if defined(IPV6_TUNNEL_ENABLE) && !defined(IPV6_ENABLE)
#error "IPv6 tunneling cannot be enabled without enabling IPv6"
#endif

//-----------------------------------------------------------------------------
// Tunnel processing
// Outer router MAC
// IP source and destination VTEP
//-----------------------------------------------------------------------------
control IngressTunnel(in switch_header_t hdr,
                      inout switch_ingress_metadata_t ig_md,
                      inout switch_lookup_fields_t lkp,
                      inout switch_lookup_fields_t lkp_nsh)(
                      switch_uint32_t ipv4_src_vtep_table_size=1024,
                      switch_uint32_t ipv6_src_vtep_table_size=1024,
                      switch_uint32_t ipv4_dst_vtep_table_size=1024,
                      switch_uint32_t ipv6_dst_vtep_table_size=1024,
                      switch_uint32_t vni_mapping_table_size=1024) {
    InnerPktValidation() pkt_validation;
    InnerPktValidation() pkt_validation_nsh;

    // ---------------------------------
    // RMAC ----------------------------
    // ---------------------------------

    action rmac_hit() { }

    table rmac {
        key = {
            ig_md.rmac_group : exact;
            lkp.mac_dst_addr : exact;
        }

        actions = {
            NoAction;
            rmac_hit;
        }

        const default_action = NoAction;
        size = 1024;
    }

    // ---------------------------------
    // Src VTEP ------------------------
    // ---------------------------------

    action src_vtep_hit(switch_ifindex_t ifindex) {
        ig_md.tunnel.ifindex = ifindex;
    }

    action src_vtep_miss() {}

    table src_vtep {
        key = {
            lkp.ipv4_src_addr : exact @name("src_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }

        const default_action = src_vtep_miss;
        size = ipv4_src_vtep_table_size;
    }

    // ---------------------------------

    table src_vtepv6 {
        key = {
            lkp.ipv6_src_addr : exact @name("src_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }

        const default_action = src_vtep_miss;
        size = ipv6_src_vtep_table_size;
    }

    // ---------------------------------
    // Src VTEP (NPB) ------------------
    // ---------------------------------

    action src_vtep_hit_nsh(switch_ifindex_t ifindex) {
        ig_md.tunnel_nsh.ifindex = ifindex;
    }

    action src_vtep_miss_nsh() {}

    table src_vtep_nsh {
        key = {
// Derek: Comment out these lines...we only want to look for tunnel type!
//          lkp_nsh.ipv4_src_addr : exact @name("src_addr");
//          ig_md.vrf : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            src_vtep_miss_nsh;
            src_vtep_hit_nsh;
        }

        const default_action = src_vtep_miss_nsh;
        size = ipv4_src_vtep_table_size;
    }

    // ---------------------------------

    table src_vtepv6_nsh {
        key = {
// Derek: Comment out these lines...we only want to look for tunnel type!
//          lkp_nsh.ipv6_src_addr : exact @name("src_addr");
//          ig_md.vrf : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            src_vtep_miss_nsh;
            src_vtep_hit_nsh;
        }

        const default_action = src_vtep_miss_nsh;
        size = ipv6_src_vtep_table_size;
    }

    // ---------------------------------
    // Dst VTEP ------------------------
    // ---------------------------------

    action dst_vtep_hit() {}

    // ---------------------------------

    //TODO(msharif): Add exclusion id.
    action set_vni_properties(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_bd_label_t bd_label,
            switch_rid_t rid,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv4_multicast_enable,
            bool igmp_snooping_enable,
            bool ipv6_unicast_enable,
            bool ipv6_multicast_enable,
            bool mld_snooping_enable,
            switch_multicast_rpf_group_t mrpf_group,
            switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        // ig_intr_md_for_tm.rid = rid;
        // ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        ig_md.rmac_group = rmac_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = learning_mode;
        ig_md.ipv4.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel.terminate = true;
    }

    // ---------------------------------

    table dst_vtep {
        key = {
            lkp.ipv4_src_addr : ternary @name("src_addr");
            lkp.ipv4_dst_addr : ternary @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            set_vni_properties;
        }

        const default_action = NoAction;
    }

    // ---------------------------------

    table dst_vtepv6 {
        key = {
            lkp.ipv6_src_addr : ternary @name("src_addr");
            lkp.ipv6_dst_addr : ternary @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            set_vni_properties;
        }

        const default_action = NoAction;
    }

    // ---------------------------------

    // Tunnel id -> BD Translation
    table vni_to_bd_mapping {
        key = { ig_md.tunnel.id : exact; }

        actions = {
            NoAction;
            set_vni_properties;
        }

        default_action = NoAction;
        size = vni_mapping_table_size;
    }

    // ---------------------------------
    // Dst VTEP (NPB) ------------------
    // ---------------------------------

    action dst_vtep_hit_nsh() {}

    // ---------------------------------

    //TODO(msharif): Add exclusion id.
    action set_vni_properties_nsh(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_bd_label_t bd_label,
            switch_rid_t rid,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv4_multicast_enable,
            bool igmp_snooping_enable,
            bool ipv6_unicast_enable,
            bool ipv6_multicast_enable,
            bool mld_snooping_enable,
            switch_multicast_rpf_group_t mrpf_group,
            switch_rmac_group_t rmac_group) {
        ig_md.bd_nsh = bd;
        ig_md.bd_label_nsh = bd_label;
        ig_md.vrf_nsh = vrf;
        // ig_intr_md_for_tm.rid = rid;
        // ig_intr_md_for_tm.level1_exclusion_id = exclusion_id;
        ig_md.rmac_group_nsh = rmac_group;
        ig_md.multicast_nsh.rpf_group = mrpf_group;
        ig_md.learning_nsh.bd_mode = learning_mode;
        ig_md.ipv4_nsh.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4_nsh.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4_nsh.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6_nsh.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6_nsh.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6_nsh.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel_nsh.terminate = true;
    }

    // ---------------------------------

    table dst_vtep_nsh {
        key = {
// Derek: Comment out these lines...we only want to look for tunnel type!
//          lkp_nsh.ipv4_src_addr : ternary @name("src_addr");
//          lkp_nsh.ipv4_dst_addr : ternary @name("dst_addr");
//          ig_md.vrf : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit_nsh;
            set_vni_properties_nsh;
        }

        const default_action = NoAction;
    }

    // ---------------------------------

    table dst_vtepv6_nsh {
        key = {
// Derek: Comment out these lines...we only want to look for tunnel type!
//          lkp_nsh.ipv6_src_addr : ternary @name("src_addr");
//          lkp_nsh.ipv6_dst_addr : ternary @name("dst_addr");
//          ig_md.vrf : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit_nsh;
            set_vni_properties_nsh;
        }

        const default_action = NoAction;
    }

    // ---------------------------------

    // Tunnel id -> BD Translation
    table vni_to_bd_mapping_nsh {
        key = { ig_md.tunnel_nsh.id : exact; }

        actions = {
            NoAction;
            set_vni_properties_nsh;
        }

        default_action = NoAction;
        size = vni_mapping_table_size;
    }

    // ---------------------------------
    // ---------------------------------
    // ---------------------------------

    apply {
#ifdef TUNNEL_ENABLE
        // outer RMAC lookup for tunnel termination.
        switch(rmac.apply().action_run) {
            rmac_hit : {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                    // src_vtep.apply();
                    switch(dst_vtep.apply().action_run) {
                        dst_vtep_hit : {
                            // Vxlan
                            vni_to_bd_mapping.apply();
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }

                        set_vni_properties : {
                            // IPinIP
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                    }
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
#ifdef IPV6_TUNNEL_ENABLE
                    // src_vtepv6.apply();
                    switch(dst_vtepv6.apply().action_run) {
                        dst_vtep_hit : {
                            // Vxlan
                            vni_to_bd_mapping.apply();
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }

                        set_vni_properties : {
                            // IPinIP
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                    }
#endif
                }

                // ---------------------------------
                // Extreme Added
                // ---------------------------------

                if (lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV4) {
                    // src_vtep_nsh.apply();
                    switch(dst_vtep_nsh.apply().action_run) {
                        dst_vtep_hit_nsh : {
                            // Vxlan
                            vni_to_bd_mapping_nsh.apply();
                            pkt_validation_nsh.apply(hdr, lkp_nsh, ig_md.flags, ig_md.drop_reason);
                        }

                        set_vni_properties_nsh : {
                            // IPinIP
                            pkt_validation_nsh.apply(hdr, lkp_nsh, ig_md.flags, ig_md.drop_reason);
                        }
                    }
                } else if (lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV6) {
#ifdef IPV6_TUNNEL_ENABLE
                    // src_vtepv6_nsh.apply();
                    switch(dst_vtepv6_nsh.apply().action_run) {
                        dst_vtep_hit_nsh : {
                            // Vxlan
                            vni_to_bd_mapping_nsh.apply();
                            pkt_validation_nsh.apply(hdr, lkp_nsh, ig_md.flags, ig_md.drop_reason);
                        }

                        set_vni_properties_nsh : {
                            // IPinIP
                            pkt_validation_nsh.apply(hdr, lkp_nsh, ig_md.flags, ig_md.drop_reason);
                        }
                    }
#endif
                }

            }
        }
#endif /* TUNNEL_ENABLE */
    }
}

//-----------------------------------------------------------------------------
// Tunnel decapsulation
//
// @param hdr : Parsed headers.
// @param mode :  Specify the model for tunnel decapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying from the outer header on decapsulation. In the PIPE mode, ttl,
// and dscp fields of the inner header are independent of that in the outer header and remain the
// same on decapsulation.
//
//-----------------------------------------------------------------------------
control TunnelDecap(inout switch_header_t hdr,
                    in switch_tunnel_metadata_t tunnel_md)(
                    switch_tunnel_mode_t mode) {
    action decap_inner_udp() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }

    action decap_inner_tcp() {
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
        hdr.udp.setInvalid();
    }

    action decap_inner_unknown() {
        hdr.udp.setInvalid();
    }

    table decap_inner_l4 {
        key = { hdr.inner_udp.isValid() : exact; }
        actions = {
            decap_inner_udp;
            decap_inner_unknown;
        }

        const default_action = decap_inner_unknown;
        const entries = {
            (true) : decap_inner_udp();
        }
    }

    action copy_ipv4_header() {
        hdr.ipv4.setValid();
        hdr.ipv4.version = hdr.inner_ipv4.version;
        hdr.ipv4.ihl = hdr.inner_ipv4.ihl;
        hdr.ipv4.total_len = hdr.inner_ipv4.total_len;
        hdr.ipv4.identification = hdr.inner_ipv4.identification;
        hdr.ipv4.flags = hdr.inner_ipv4.flags;
        hdr.ipv4.frag_offset = hdr.inner_ipv4.frag_offset;
        hdr.ipv4.protocol = hdr.inner_ipv4.protocol;
        // hdr.ipv4.hdr_checksum = hdr.inner_ipv4.hdr_checksum;
        hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
        hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
            hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;
        }

        hdr.inner_ipv4.setInvalid();
    }

    action copy_ipv6_header() {
        hdr.ipv6.setValid();
        hdr.ipv6.version = hdr.inner_ipv6.version;
        hdr.ipv6.flow_label = hdr.inner_ipv6.flow_label;
        hdr.ipv6.payload_len = hdr.inner_ipv6.payload_len;
        hdr.ipv6.next_hdr = hdr.inner_ipv6.next_hdr;
        hdr.ipv6.src_addr = hdr.inner_ipv6.src_addr;
        hdr.ipv6.dst_addr = hdr.inner_ipv6.dst_addr;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv6.hop_limit = hdr.inner_ipv6.hop_limit;
            hdr.ipv6.traffic_class = hdr.inner_ipv6.traffic_class;
        }

        hdr.inner_ipv6.setInvalid();
    }

    action invalidate_tunneling_headers() {
        // Removing tunneling headers by default.
        hdr.vxlan.setInvalid();
    }

    action decap_inner_ethernet_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ethernet_ipv6() {
#ifdef IPV6_TUNNEL_ENABLE
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv6_header();
        hdr.ipv4.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
#endif
    }

    action decap_inner_ethernet_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ipv4() {
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ipv6() {
#ifdef IPV6_TUNNEL_ENABLE
        hdr.ethernet.ether_type = ETHERTYPE_IPV6;
        copy_ipv6_header();
        hdr.ipv4.setInvalid();
        invalidate_tunneling_headers();
#endif
    }

    table decap_inner_ip {
        key = {
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            decap_inner_ethernet_ipv4;
            decap_inner_ethernet_ipv6;
            decap_inner_ethernet_non_ip;
            decap_inner_ipv4;
            decap_inner_ipv6;
        }

        const entries = {
            (true, true, false) : decap_inner_ethernet_ipv4();
            (true, false, true) : decap_inner_ethernet_ipv6();
            (true, false, false) : decap_inner_ethernet_non_ip();
            (false, true, false) : decap_inner_ipv4();
            (false, false, true) : decap_inner_ipv6();
        }
    }

    apply {
#ifdef TUNNEL_ENABLE
        // Copy L3 headers into inner headers.
        if (tunnel_md.terminate)
            decap_inner_ip.apply();
        // Copy L4 headers into inner headers.
        if (tunnel_md.terminate)
            decap_inner_l4.apply();
#endif /* TUNNEL_ENABLE */
    }
}

control TunnelRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md)(
                      switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024,//XXX
                      switch_uint32_t ipv6_dst_addr_rewrite_table_size=1024,//XXX
                      switch_uint32_t src_addr_rewrite_table_size=1024,//XXX
                      switch_uint32_t nexthop_rewrite_table_size=512,
                      switch_uint32_t smac_rewrite_table_size=1024) {

    EgressBd(BD_TABLE_SIZE) egress_bd;
    switch_bd_label_t bd_label;
    switch_smac_index_t smac_index;

    // Outer nexthop rewrite
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet.dst_addr = dmac;
    }

    // --------------------- 
    // Extreme Added
    // ---------------------

    action rewrite_tunnel_nsh(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet_underlay.dst_addr = dmac;
    }

    // ---------------------

    table nexthop_rewrite {
        key = {
            eg_md.outer_nexthop : exact;
//          hdr.nsh_extr_underlay.isValid() : exact;
        }

        actions = {
            NoAction;
            rewrite_tunnel;

            rewrite_tunnel_nsh;
        }

        const default_action = NoAction;
        size = nexthop_rewrite_table_size;
    }

    // Tunnel source IP rewrite
    action rewrite_ipv4_src(ipv4_addr_t src_addr) {
        hdr.ipv4.src_addr = src_addr;
    }

    action rewrite_ipv6_src(ipv6_addr_t src_addr) {
#ifdef IPV6_TUNNEL_ENABLE
        hdr.ipv6.src_addr = src_addr;
#endif
    }

    table src_addr_rewrite {
        key = { eg_md.bd : exact; }
        actions = {
            rewrite_ipv4_src;
            rewrite_ipv6_src;
        }

        size = src_addr_rewrite_table_size;
    }

    // Tunnel destination IP rewrite
    action rewrite_ipv4_dst(ipv4_addr_t dst_addr) {
        hdr.ipv4.dst_addr = dst_addr;
    }

    action rewrite_ipv6_dst(ipv6_addr_t dst_addr) {
        hdr.ipv6.dst_addr = dst_addr;
    }

    table ipv4_dst_addr_rewrite {
        key = { eg_md.tunnel.index : exact; }
        actions = {
            NoAction;
            rewrite_ipv4_dst;
        }

        const default_action = NoAction;
        size = ipv4_dst_addr_rewrite_table_size;
    }

    table ipv6_dst_addr_rewrite {
        key = { eg_md.tunnel.index : exact; }
        actions = {
            NoAction;
            rewrite_ipv6_dst;
        }

        const default_action = NoAction;
        size = ipv6_dst_addr_rewrite_table_size;
    }


    // Tunnel source MAC rewrite
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }

    // --------------------- 
    // Extreme Added
    // ---------------------

    action rewrite_smac_nsh(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }

    // ---------------------

    table smac_rewrite {
//      key = { smac_index : exact; }
        key = {
            smac_index : exact;
//          hdr.nsh_extr_underlay.isValid() : exact;
        }
        actions = {
            NoAction;
            rewrite_smac;

            rewrite_smac_nsh;
        }

        const default_action = NoAction;
        size = smac_rewrite_table_size;
    }

    apply {
#ifdef TUNNEL_ENABLE
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            nexthop_rewrite.apply();
            egress_bd.apply(
                hdr, eg_md.bd, eg_md.pkt_type, bd_label, smac_index, eg_md.checks.mtu);
        }

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            src_addr_rewrite.apply();
            ipv4_dst_addr_rewrite.apply();
#ifdef IPV6_TUNNEL_ENABLE
            ipv6_dst_addr_rewrite.apply();
#endif
            smac_rewrite.apply();
        }
#endif /* TUNNEL_ENABLE */
    }
}

//-----------------------------------------------------------------------------
// Tunnel encapsulation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param mode :  Specify the model for tunnel encapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying into the outer header on encapsulation. This results in 'normal'
// behaviour for ECN field (See RFC 6040 secion 4.1). In the PIPE model, outer header ttl and dscp
// fields are independent of that in the inner header and are set to user-defined values on
// encapsulation.
// @param vni_mapping_table_size : Number of VNIs.
//
//-----------------------------------------------------------------------------
control TunnelEncap(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md)(
                    switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
                    switch_uint32_t vni_mapping_table_size=1024) {
    bit<16> payload_len;
    bit<8> ip_proto;

    action set_vni(switch_tunnel_id_t id) {
        eg_md.tunnel.id = id;
    }

    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }

        actions = {
            NoAction;
            set_vni;
        }

        size = vni_mapping_table_size;
    }

    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields.
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        // hdr.inner_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        hdr.ipv4.setInvalid();
    }

    action copy_ipv6_header() {
        hdr.inner_ipv6.version = hdr.ipv6.version;
        hdr.inner_ipv6.flow_label = hdr.ipv6.flow_label;
        hdr.inner_ipv6.payload_len = hdr.ipv6.payload_len;
        hdr.inner_ipv6.src_addr = hdr.ipv6.src_addr;
        hdr.inner_ipv6.dst_addr = hdr.ipv6.dst_addr;
        hdr.inner_ipv6.hop_limit = hdr.ipv6.hop_limit;
        hdr.inner_ipv6.traffic_class = hdr.ipv6.traffic_class;
        hdr.ipv6.setInvalid();
    }


    action rewrite_inner_ipv4_udp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        ip_proto = IP_PROTOCOLS_IPV4;
    }

    action rewrite_inner_ipv4_tcp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        ip_proto = IP_PROTOCOLS_IPV4;
    }

    action rewrite_inner_ipv4_unknown() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        ip_proto = IP_PROTOCOLS_IPV4;
    }

    action rewrite_inner_ipv6_udp() {
#ifdef IPV6_TUNNEL_ENABLE
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
        hdr.ipv6.setInvalid();
        ip_proto = IP_PROTOCOLS_IPV6;
#endif
    }

    action rewrite_inner_ipv6_tcp() {
#ifdef IPV6_TUNNEL_ENABLE
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
        hdr.ipv6.setInvalid();
        ip_proto = IP_PROTOCOLS_IPV6;
#endif
    }

    action rewrite_inner_ipv6_unknown() {
#ifdef IPV6_TUNNEL_ENABLE
        payload_len = hdr.ipv6.payload_len + 16w40;
        hdr.inner_ipv6 = hdr.ipv6;
        hdr.ipv6.setInvalid();
        ip_proto = IP_PROTOCOLS_IPV6;
#endif
    }

    table encap_outer {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            // hdr.tcp.isValid() : exact;

            hdr.nsh_extr_underlay.isValid() : exact;
        }

        actions = {
            rewrite_inner_ipv4_udp;
            // rewrite_inner_ipv4_tcp;
            rewrite_inner_ipv4_unknown;
            rewrite_inner_ipv6_udp;
            // rewrite_inner_ipv6_tcp;
            rewrite_inner_ipv6_unknown;
        }

        const entries = {
//          (true, false, false) : rewrite_inner_ipv4_unknown();
//          (false, true, false) : rewrite_inner_ipv6_unknown();
//          (true, false, true) : rewrite_inner_ipv4_udp();
//          (false, true, true) : rewrite_inner_ipv6_udp();

            (true, false, false, false) : rewrite_inner_ipv4_unknown();
            (false, true, false, false) : rewrite_inner_ipv6_unknown();
            (true, false, true,  false) : rewrite_inner_ipv4_udp();
            (false, true, true,  false) : rewrite_inner_ipv6_udp();
        }
    }

//-----------------------------------------------------------------------------
// Helper actions to add various headers.
//-----------------------------------------------------------------------------
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
        // hdr.udp.length = 0;
    }

    action add_vxlan_header(bit<24> vni) {
#ifdef VXLAN_ENABLE
        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        // hdr.vxlan.reserved = 0;
        hdr.vxlan.vni = vni;
        // hdr.vxlan.reserved2 = 0;
#endif
    }

    action add_gre_header(bit<16> proto) {
#ifdef GRE_ENABLE
        hdr.gre.setValid();
        hdr.gre.proto = proto;
        hdr.gre.C = 0;
        hdr.gre.R = 0;
        hdr.gre.K = 0;
        hdr.gre.S = 0;
        hdr.gre.s = 0;
        hdr.gre.recurse = 0;
        hdr.gre.flags = 0;
        hdr.gre.version = 0;
#endif
    }

    action add_erspan_header(bit<32> timestamp, switch_mirror_session_t session_id) {
#ifdef ERSPAN_ENABLE
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.timestamp = timestamp;
        hdr.erspan_type3.session_id = (bit<10>) session_id;
        hdr.erspan_type3.version = 4w0x2;
        hdr.erspan_type3.sgt = 0;
        hdr.erspan_type3.vlan = 0;
#endif
    }

    action add_ipv4_header(bit<8> proto) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.protocol = proto;
        // hdr.ipv4.src_addr = 0;
        // hdr.ipv4.dst_addr = 0;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = 8w64;
            hdr.ipv4.diffserv = 0;
        }
    }

    action add_ipv6_header(bit<8> proto) {
#ifdef IPV6_ENABLE
        hdr.ipv6.setValid();
        hdr.ipv6.version = 4w6;
        hdr.ipv6.flow_label = 0;
        // hdr.ipv6.payload_len = 0;
        hdr.ipv6.next_hdr = proto;
        // hdr.ipv6.src_addr = 0;
        // hdr.ipv6.dst_addr = 0;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv6.hop_limit = 8w64;
            hdr.ipv6.traffic_class = 0;
        }
#endif
    }

    action rewrite_ipv4_vxlan(bit<16> vxlan_port) {
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv4_header(IP_PROTOCOLS_UDP);
        // Total length = packet length + 50
        //   IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv4.total_len = payload_len + 16w50;

        add_udp_header(eg_md.tunnel.hash, vxlan_port);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + 16w30;

        add_vxlan_header(eg_md.tunnel.id);
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
    }

    action rewrite_ipv4_ip() {
        add_ipv4_header(ip_proto);
        // Total length = packet length + 20
        //   IPv4 (20)
        hdr.ipv4.total_len = payload_len + 16w20;
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
    }

    action rewrite_ipv6_vxlan(bit<16> vxlan_port) {
#ifdef IPV6_TUNNEL_ENABLE
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv6_header(IP_PROTOCOLS_UDP);
        // Payload length = packet length + 50
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv6.payload_len = payload_len + 16w30;

        add_udp_header(eg_md.tunnel.hash, vxlan_port);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + 16w30;

        add_vxlan_header(eg_md.tunnel.id);
        hdr.ethernet.ether_type = ETHERTYPE_IPV6;
#endif
    }

    action rewrite_ipv6_ip() {
#ifdef IPV6_TUNNEL_ENABLE
        add_ipv6_header(ip_proto);
        // Payload length = packet length
        hdr.ipv6.payload_len = payload_len;
        hdr.ethernet.ether_type = ETHERTYPE_IPV6;
#endif
    }

    // --------------------- 
    // Extreme Added
    // ---------------------

    action rewrite_mac_in_mac_nsh() {
        hdr.ethernet_underlay.setValid();

        hdr.ethernet_underlay.ether_type = ETHERTYPE_NSH;
    }

    // ---------------------

    table tunnel {
        key = {
            eg_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            rewrite_ipv4_vxlan;
            rewrite_ipv6_vxlan;
            rewrite_ipv4_ip;
            rewrite_ipv6_ip;

            rewrite_mac_in_mac_nsh;
        }

        const default_action = NoAction;
    }

    apply {
#ifdef TUNNEL_ENABLE
        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE && eg_md.tunnel.id == 0)
            bd_to_vni_mapping.apply();

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            // Copy L3/L4 header into inner headers.
            encap_outer.apply();

            // Add outer L3/L4/Tunnel headers.
            tunnel.apply();
        }
#endif /* TUNNEL_ENABLE */
    }
}

