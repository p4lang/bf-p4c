
// =============================================================================
// =============================================================================
// Taken from l2.p4 ============================================================
// =============================================================================
// =============================================================================

// THIS IS NOW UNUSED!

control npb_egr_sff_vlan_decap(inout switch_header_t hdr, in switch_port_t port) {

	// ----------------------------------------

	action remove_vlan_tag() {
		hdr.ethernet_underlay.ether_type = hdr.vlan_tag_underlay.ether_type;
//		hdr.vlan_tag_underlay.pop_front(1);
	}

	table vlan_decap {
		key = {
			port : ternary;
			hdr.vlan_tag_underlay.isValid() : exact;
		}

		actions = {
			NoAction;
			remove_vlan_tag;
		}

		const default_action = NoAction;
	}

	// ----------------------------------------

	apply {
#ifdef QINQ_ENABLE
		vlan_decap.apply();
#else
		// Remove the vlan tag by default.
		if (hdr.vlan_tag_underlay.isValid()) {
			hdr.ethernet_underlay.ether_type = hdr.vlan_tag_underlay.ether_type;
			hdr.vlan_tag_underlay.setInvalid();
		}
#endif
	}
}

// =============================================================================
// =============================================================================
// Taken from tunnel.p4 ========================================================
// =============================================================================
// =============================================================================

// THIS IS NOW UNUSED!

control npb_egr_sff_tunnel_decap (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// ----------------------------------------

	action invalidate_tunneling_headers() {
		// Removing tunneling headers by default.
	}

	// ----------------------------------------

	action decap_inner_ethernet_non_ip() {
		hdr.ethernet_underlay.setInvalid();
		invalidate_tunneling_headers();
	}

	table decap_inner_ip {
		key = {
			hdr.ethernet_underlay.isValid() : exact;
		}

		actions = {
			decap_inner_ethernet_non_ip;
		}

		const entries = {
			(true) : decap_inner_ethernet_non_ip();
		}
	}

	// ----------------------------------------

	apply {
		// Copy L3 headers into outer headers.
		decap_inner_ip.apply();
	}

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_rewrite (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

    EgressBd(
        EGRESS_BD_MAPPING_TABLE_SIZE, EGRESS_BD_STATS_TABLE_SIZE) egress_bd;
    switch_smac_index_t smac_index;

	// =========================================================================
	// Table
	// =========================================================================

    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = false;
        eg_md.tunnel.type = type;
#endif
    }

    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = bd;
    }

    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        eg_md.tunnel.type = type;
        eg_md.tunnel.id = id;
#endif
    }

    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = bd;
        eg_md.tunnel.type = type;
#endif
    }

    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.tunnel.type = type;
#endif
    }

    table nexthop_rewrite {
        key = { eg_md.nexthop : exact; }
        actions = {
            NoAction;
            rewrite_l2_with_tunnel;
            rewrite_l3;
            rewrite_l3_with_tunnel;
            rewrite_l3_with_tunnel_bd;
            rewrite_l3_with_tunnel_id;
        }

        const default_action = NoAction;
        size = NEXTHOP_TABLE_SIZE;
    }

	// =========================================================================
	// Table
	// =========================================================================

    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }

    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        const default_action = NoAction;
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

        // Should not rewrite packets redirected to CPU.
        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
            nexthop_rewrite.apply();
        }

        egress_bd.apply(
			hdr,             // in
			eg_md.bd,        // in
			eg_md.pkt_type,  // in
			eg_md.bd_label,  // out
            smac_index,      // out
			eg_md.checks.mtu // out
		);

        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL && eg_md.flags.routed) {
            smac_rewrite.apply();
        }

	}

}
*/

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_tunnel_rewrite (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	EgressBd(EGRESS_OUTER_BD_MAPPING_TABLE_SIZE,
	         EGRESS_BD_STATS_TABLE_SIZE) egress_bd;
	switch_bd_label_t bd_label;
	switch_smac_index_t smac_index;

	// =========================================================================
	// Table - DA & BD
	// =========================================================================

    // Outer nexthop rewrite
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet_underlay.dst_addr = dmac;
    }

    table nexthop_rewrite {
        key = {
            eg_md.nexthop : exact;
        }

        actions = {
            rewrite_tunnel;
        }
    }

	// =========================================================================
	// Table, SA
	// =========================================================================

    // Tunnel source MAC rewrite
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }
    
    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        size = TUNNEL_SMAC_REWRITE_TABLE_SIZE;
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		nexthop_rewrite.apply(); // sets l2 da, eg_md.bd

		egress_bd.apply(
			hdr,             // in
			eg_md.bd,        // in
			eg_md.pkt_type,  // in
			bd_label,        // out --> currently unused!?!?
			smac_index,      // out
			eg_md.checks.mtu // out
		);

		smac_rewrite.apply(); // sets l2 sa

	}

}
*/

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_tunnel_encap (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Table - Set VNI
	// =========================================================================

    action set_vni(switch_tunnel_id_t id) {
        eg_md.tunnel.id = id;
    }

    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }

        actions = {
            NoAction;
            set_vni;
        }

        size = VNI_MAPPING_TABLE_SIZE;
    }

	// =========================================================================
	// Table - Tunnel Type
	// =========================================================================

	action rewrite_eth_nsh() {

			hdr.ethernet_underlay.setValid();
			hdr.vlan_tag_underlay.setValid();

			hdr.ethernet_underlay.ether_type = ETHERTYPE_NSH;
	}

	// -----------------------------------------------

    table tunnel {
        key = {
            eg_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            rewrite_eth_nsh;
        }

        const default_action = NoAction;
        const entries = {
            SWITCH_TUNNEL_TYPE_MACINMAC_NSH : rewrite_eth_nsh();
        }
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		if(eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE && eg_md.tunnel.id == 0) {
			bd_to_vni_mapping.apply();
		}

		if(eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {

			// Add outer Tunnel headers.
			tunnel.apply();

			npb_egr_sff_tunnel_rewrite.apply(
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			); 

		}

	}

}
*/
