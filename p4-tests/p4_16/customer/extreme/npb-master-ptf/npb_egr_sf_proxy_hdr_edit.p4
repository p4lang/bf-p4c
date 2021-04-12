
control npb_egr_sf_proxy_hdr_edit (
	inout switch_header_transport_t                   hdr_0,
	inout switch_header_outer_t                       hdr_1,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	bool      hit  = false;
	bit<3>    pcp_ = 0;
	vlan_id_t vid_ = 0;

	bool      hdr_1_ethernet_isEtypeStag;
	bool      hdr_1_e_tag_isEtypeStag;
	bool      hdr_1_vn_tag_isEtypeStag;

	// -----------------------------------------------------------------
	// Table: bd_to_vlan_mapping
	// -----------------------------------------------------------------
#ifdef SF_2_EDIT_BD_TO_VID_TABLE_ENABLE
	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

    action set_vlan_tagged(vlan_id_t vid, bit<3> pcp) {
		stats.count();

		hit  = true;
		pcp_ = pcp;
		vid_ = vid;
    }

	action no_action() { 
		stats.count();
	}

    table bd_to_vlan_mapping {
        key = { eg_md.nsh_md.add_tag_vlan_bd : exact @name("bd"); }
        actions = {
//			NoAction;
			no_action;
			set_vlan_tagged;
        }

        const default_action = no_action;
        size = 512;
		counters = stats;
    }
#endif
	// -----------------------------------------------------------------
	// Table: hdr_add
	// -----------------------------------------------------------------

	// helper action
	action hdr_add_vlan_tag(vlan_id_t vid, bit<3> pcp) {
		// copy from 0 to 1
//		hdr_1.vlan_tag[1].setValid(); // will be set by the individual actions
		hdr_1.vlan_tag[1].pcp        = hdr_1.vlan_tag[0].pcp;
		hdr_1.vlan_tag[1].cfi        = hdr_1.vlan_tag[0].cfi;
		hdr_1.vlan_tag[1].vid        = hdr_1.vlan_tag[0].vid;
		hdr_1.vlan_tag[1].ether_type = hdr_1.vlan_tag[0].ether_type;

		// add 0
		hdr_1.vlan_tag[0].setValid(); // might already be valid, which is fine
		hdr_1.vlan_tag[0].pcp        = pcp;
		hdr_1.vlan_tag[0].cfi        = 0;
		hdr_1.vlan_tag[0].vid        = vid;
//		hdr_1.vlan_tag[0].ether_type = ?; // will be set by the individual actions
	}

	// --------------------------------

	action hdr_add_0__from_eth_____to_vlan_tag0() {
		hdr_add_vlan_tag(vid_, pcp_);
		hdr_1.vlan_tag[0].ether_type = hdr_1.ethernet.ether_type;

		hdr_1.ethernet.ether_type = ETHERTYPE_VLAN;
	}

	action hdr_add_0__from_e_tag___to_vlan_tag0() {
#ifdef ETAG_ENABLE
		hdr_add_vlan_tag(vid_, pcp_);
		hdr_1.vlan_tag[0].ether_type = hdr_1.e_tag.ether_type;

		hdr_1.e_tag.ether_type = ETHERTYPE_VLAN;
#endif
	}

	action hdr_add_0__from_vn_tag__to_vlan_tag0() {
#ifdef VNTAG_ENABLE
		hdr_add_vlan_tag(vid_, pcp_);
		hdr_1.vlan_tag[0].ether_type = hdr_1.vn_tag.ether_type;

		hdr_1.vn_tag.ether_type = ETHERTYPE_VLAN;
#endif
	}

	// --------------------------------

	action hdr_add_1__from_eth_____to_vlan_tag0() {
		hdr_add_vlan_tag(vid_, pcp_);
		hdr_1.vlan_tag[1].setValid();
		hdr_1.vlan_tag[0].ether_type = hdr_1.ethernet.ether_type;

		hdr_1.ethernet.ether_type = ETHERTYPE_VLAN;
	}

	action hdr_add_1__from_e_tag___to_vlan_tag0() {
#ifdef ETAG_ENABLE
		hdr_add_vlan_tag(vid_, pcp_);
		hdr_1.vlan_tag[1].setValid();
		hdr_1.vlan_tag[0].ether_type = hdr_1.e_tag.ether_type;

		hdr_1.e_tag.ether_type = ETHERTYPE_VLAN;
#endif
	}

	action hdr_add_1__from_vn_tag__to_vlan_tag0() {
#ifdef VNTAG_ENABLE
		hdr_add_vlan_tag(vid_, pcp_);
		hdr_1.vlan_tag[1].setValid();
		hdr_1.vlan_tag[0].ether_type = hdr_1.vn_tag.ether_type;

		hdr_1.vn_tag.ether_type = ETHERTYPE_VLAN;
#endif
	}

	// --------------------------------

	table hdr_add {
		key = {
			hit                           : exact;

			hdr_1_ethernet_isEtypeStag    : exact;
#ifdef ETAG_ENABLE
			hdr_1.e_tag.isValid()         : exact;
			hdr_1_e_tag_isEtypeStag       : exact;
#endif
#ifdef VNTAG_ENABLE
			hdr_1.vn_tag.isValid()        : exact;
			hdr_1_vn_tag_isEtypeStag      : exact;
#endif
			hdr_1.vlan_tag[0].isValid()   : exact;
			hdr_1.vlan_tag[1].isValid()   : exact;
		}

		actions = {
			NoAction();
			hdr_add_0__from_eth_____to_vlan_tag0();
			hdr_add_0__from_e_tag___to_vlan_tag0();
			hdr_add_0__from_vn_tag__to_vlan_tag0();
			hdr_add_1__from_eth_____to_vlan_tag0();
			hdr_add_1__from_e_tag___to_vlan_tag0();
			hdr_add_1__from_vn_tag__to_vlan_tag0();
		}
		const entries = {

			// My notes on a complete truth table for just two things (e/vn and vlan)
			// =====================
			// Packet               
			// {e/vn,  vl[0], vl[1]}
			// =====================
			// {false, false, false}   --> empty,      disabled --> no action
			// {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
			// {false, false, true }   --> impossible, disabled --> no action
			// {false, false, true }   --> impossible, enabled  --> no action
			// ---------------------
			// {false, true,  false}   --> one full,   disabled --> no action
			// {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
			// {false, true,  true }   --> both full,  disabled --> no action
			// {false, true,  true }   --> both full,  enabled  --> no action
			// ---------------------
			// {true,  false, false}   --> empty,      disabled --> no action
			// {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
			// {true,  false, true }   --> impossible, disabled --> no action
			// {true,  false, true }   --> impossible, enabled  --> no action
			// ---------------------
			// {true,  true,  false}   --> one full,   disabled --> no action
			// {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
			// {true,  true,  true }   --> both full,  disabled --> no action
			// {true,  true,  true }   --> both full,  enabled  --> no action

// eth,		e, vn, vl[0], vl[1], ipv4

#if defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)

			// ===    ======   =============   =============   =====    =====
			// hit    eth      e               vn              vl[0]    vl[1]
			// ===    ======   =============   =============   =====    =====

			// case 0 (eth  to vlan)
			(true,    false,   false, false,   false, false,   false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
			(true,    false,   false, true,    false, false,   false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
			(true,    false,   false, false,   false, true,    false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
			(true,    false,   false, true,    false, true,    false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

			// case 1 (eth  to vlan)
			(true,    false,   false, false,   false, false,   true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
			(true,    false,   false, true,    false, false,   true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
			(true,    false,   false, false,   false, true,    true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
			(true,    false,   false, true,    false, true,    true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

			// case 2 (e/vn to vlan)
			(true,    false,   true,  false,   false, false,   false,   false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty
			(true,    false,   true,  false,   false, true,    false,   false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty

			(true,    false,   false, false,   true,  false,   false,   false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty
			(true,    false,   false, true,    true,  false,   false,   false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty

			// case 3 (e/vn to vlan)
			(true,    false,   true,  false,   false, false,   true,    false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full
			(true,    false,   true,  false,   false, true,    true,    false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full

			(true,    false,   false, false,   true,  false,   true,    false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
			(true,    false,   false, true,    true,  false,   true,    false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full

#elif defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)

			// ===    ======   =============   =============   =====    =====
			// hit    eth      e               vn              vl[0]    vl[1]
			// ===    ======   =============   =============   =====    =====

			// case 0 (eth  to vlan)
			(true,    false,   false, false,                   false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
			(true,    false,   false, true,                    false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

			// case 1 (eth  to vlan)
			(true,    false,   false, false,                   true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
			(true,    false,   false, true,                    true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

			// case 2 (e/vn to vlan)
			(true,    false,   true,  false,                   false,   false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty

			// case 3 (e/vn to vlan)
			(true,    false,   true,  false,                   true,    false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full

#elif !defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)

			// ===    ======   =============   =============   =====    =====
			// hit    eth      e               vn              vl[0]    vl[1]
			// ===    ======   =============   =============   =====    =====

			// case 0 (eth  to vlan)
			(true,    false,                   false, false    false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
			(true,    false,                   false, true     false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

			// case 1 (eth  to vlan)
			(true,    false,                   false, false,   true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
			(true,    false,                   false, true,    true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

			// case 2 (e/vn to vlan)
			(true,    false,                   true,  false,   false,   false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty
			(true,    false,                   true,  false,   false,   false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty

			// case 3 (e/vn to vlan)
			(true,    false,                   true,  false    true,    false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
			(true,    false,                   true,  false    true,    false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full

#elif !defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)

			// ===    ======   =============   =============   =====    =====
			// hit    eth      e               vn              vl[0]    vl[1]
			// ===    ======   =============   =============   =====    =====

			// case 0 (eth  to vlan)
			(true,    false,                                   false,   false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

			// case 1 (eth  to vlan)
			(true,    false,                                   true,    false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

#endif 
		}
	}

	// -----------------------------------------------------------------
	// Apply
	// -----------------------------------------------------------------

	apply {
		if(hdr_1.ethernet.ether_type == 0x88a8) hdr_1_ethernet_isEtypeStag = true; else hdr_1_ethernet_isEtypeStag = false;
#ifdef ETAG_ENABLE
		if(hdr_1.e_tag.ether_type    == 0x88a8) hdr_1_e_tag_isEtypeStag    = true; else hdr_1_e_tag_isEtypeStag    = false;
#endif
#ifdef VNTAG_ENABLE
		if(hdr_1.vn_tag.ether_type   == 0x88a8) hdr_1_vn_tag_isEtypeStag   = true; else hdr_1_vn_tag_isEtypeStag   = false;
#endif
		
#ifdef SF_2_EDIT_BD_TO_VID_TABLE_ENABLE
/*
		if(bd_to_vlan_mapping.apply().hit) {
			hdr_add.apply();
		}
*/
		bd_to_vlan_mapping.apply();
		hdr_add.apply();
#endif
	}

}
