
control npb_egr_sf_proxy_hdr_strip (
	inout switch_header_transport_t                   hdr_0,
	inout switch_header_outer_t                       hdr_1,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// -----------------------------------------------------------------
	// Table
	// -----------------------------------------------------------------

	action hdr_strip_1__from_vlan_tag0__to_eth() {
		hdr_1.ethernet.ether_type = hdr_1.vlan_tag[0].ether_type;
		hdr_1.vlan_tag[0].setInvalid();
	}

	action hdr_strip_1__from_vlan_tag0__to_e_tag() {
#ifdef ETAG_ENABLE
		hdr_1.e_tag.ether_type = hdr_1.vlan_tag[0].ether_type;
		hdr_1.vlan_tag[0].setInvalid();
#endif
	}

	action hdr_strip_1__from_vlan_tag0__to_vn_tag() {
#ifdef VNTAG_ENABLE
		hdr_1.vn_tag.ether_type = hdr_1.vlan_tag[0].ether_type;
		hdr_1.vlan_tag[0].setInvalid();
#endif
	}

	// --------------------------------

	action hdr_strip_1__from_vn_tag_____to_eth() {
#ifdef VNTAG_ENABLE
		hdr_1.ethernet.ether_type = hdr_1.vn_tag.ether_type;
		hdr_1.vn_tag.setInvalid();
#endif
	}

	// --------------------------------

	action hdr_strip_1__from_e_tag______to_eth() {
#ifdef ETAG_ENABLE
		hdr_1.ethernet.ether_type = hdr_1.e_tag.ether_type;
		hdr_1.e_tag.setInvalid();
#endif
	}

	// --------------------------------

	action hdr_strip_2__from_vlan_tag0__to_eth() {
		// tag0 to eth
		hdr_1.ethernet.ether_type = hdr_1.vlan_tag[0].ether_type;
#ifdef ETAG_ENABLE
		hdr_1.e_tag.setInvalid();
#endif
#ifdef VNTAG_ENABLE
		hdr_1.vn_tag.setInvalid();
#endif
		hdr_1.vlan_tag[0].setInvalid();
	}

	// --------------------------------

	bool hdr_1_e_tag_isValid;
	bool hdr_1_vn_tag_isValid;

	table hdr_strip {
		key = {
#ifdef ETAG_ENABLE
			hdr_1.e_tag.isValid()       : exact;
#endif
#ifdef VNTAG_ENABLE
			hdr_1.vn_tag.isValid()      : exact;
#endif
			hdr_1.vlan_tag[0].isValid() : exact;
//			hdr_1.vlan_tag[1].isValid() : exact;

#ifdef ETAG_ENABLE
			eg_md.nsh_md.strip_e_tag    : ternary;
#endif
#ifdef VNTAG_ENABLE
			eg_md.nsh_md.strip_vn_tag   : ternary;
#endif
			eg_md.nsh_md.strip_vlan_tag : ternary;
		}

		actions = {
			NoAction();
			hdr_strip_1__from_e_tag______to_eth();
			hdr_strip_1__from_vn_tag_____to_eth();
			hdr_strip_1__from_vlan_tag0__to_eth();
			hdr_strip_1__from_vlan_tag0__to_e_tag();
			hdr_strip_1__from_vlan_tag0__to_vn_tag();

			hdr_strip_2__from_vlan_tag0__to_eth();
		}
		const entries = {

			// My notes on a complete truth table for just two things (e/vn and vlan)
			// ==============         ==============      
			// Packet                 Enables
			// {vn/e,  vlan}          {e/vn,  vlan}
			// ==============         ==============      
			// {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
			// {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
			// {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
			// {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
			// --------------         --------------      
			// {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
			// {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
			// {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
			// {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
			// --------------         --------------      
			// {true,  false}         {false, false}          --> nothing   enabled, vn in pkt        --> no action
			// {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
			// {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
			// {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
			// --------------         --------------      
			// {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
			// {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
			// {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
			// {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)

// ipv4,	 vl[0], vn,    e,   ethernet

#if defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)

			// case 0 (---- + vlan delete, only vlan          are valid):
			(false, false, true,      _,     _,     true ): hdr_strip_1__from_vlan_tag0__to_eth();         // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

			// case 1 (e/vn + ---- delete, only e/vn          are valid):
			(true,  false, false,     true,  _,     _    ): hdr_strip_1__from_e_tag______to_eth();         // pkt: 0   tags + e  ==> delete e        (e    to eth)
			(false, true,  false,     _,     true,  _    ): hdr_strip_1__from_vn_tag_____to_eth();         // pkt: 0   tags + vn ==> delete vn       (vn   to eth)

			// case 2 (---  + vlan delete, both e/vn and vlan are valid):
			(true,  false, true,      false, _,     true ): hdr_strip_1__from_vlan_tag0__to_e_tag();       // pkt: 1-2 tags + e  ==> delete vlan0    (vlan to e)
			(false, true,  true,      _,     false, true ): hdr_strip_1__from_vlan_tag0__to_vn_tag();      // pkt: 1-2 tags + vn ==> delete vlan0    (vlan to vn)

			// case 3 (e/vn + ---- delete, both e/vn and vlan are valid):
			(true,  false, true,      true,  _,     false): hdr_strip_1__from_e_tag______to_eth();         // pkt: 1-2 tags + e  ==> delete e        (e    to eth)
			(false, true,  true,      _,     true,  false): hdr_strip_1__from_vn_tag_____to_eth();         // pkt: 1-2 tags + vn ==> delete vn       (vn   to eth)

			// case 4 (e/vn + vlan delete, both e/vn and vlan are valid): -- double delete case
			(true,  false, true,      true,  _,     true ): hdr_strip_2__from_vlan_tag0__to_eth();         // pkt: 1-2 tags + e  ==> delete vlan0+e  (vlan to eth)
			(false, true,  true,      _,     true,  true ): hdr_strip_2__from_vlan_tag0__to_eth();         // pkt: 1-2 tags + vn ==> delete vlan0+vn (vlan to eth)

#elif defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)

			// case 0 (---- + vlan delete, only vlan          are valid):
			(false,        true,      _,            true ): hdr_strip_1__from_vlan_tag0__to_eth();         // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

			// case 1 (e/vn + ---- delete, only e/vn          are valid):
			(true,         false,     true,         _    ): hdr_strip_1__from_e_tag______to_eth();         // pkt: 0   tags + e  ==> delete e        (e    to eth)

			// case 2 (---  + vlan delete, both e/vn and vlan are valid):
			(true,         true,      false,        true ): hdr_strip_1__from_vlan_tag0__to_e_tag();       // pkt: 1-2 tags + e  ==> delete vlan0    (vlan to e)

			// case 3 (e/vn + ---- delete, both e/vn and vlan are valid):
			(true,         true,      true,         false): hdr_strip_1__from_e_tag______to_eth();         // pkt: 1-2 tags + e  ==> delete e        (e    to eth)

			// case 4 (e/vn + vlan delete, both e/vn and vlan are valid): -- double delete case
			(true,         true,      true,         true ): hdr_strip_2__from_vlan_tag0__to_eth();         // pkt: 1-2 tags + e  ==> delete vlan0+e  (vlan to eth)

#elif !defined(ETAG_ENABLE) && defined(VNTAG_ENABLE)

			// case 0 (---- + vlan delete, only vlan          are valid):
			(       false, true,             _,     true ): hdr_strip_1__from_vlan_tag0__to_eth();         // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

			// case 1 (e/vn + ---- delete, only e/vn          are valid):
			(       true,  false,            true,  _    ): hdr_strip_1__from_vn_tag_____to_eth();         // pkt: 0   tags + vn ==> delete vn       (vn   to eth)

			// case 2 (---  + vlan delete, both e/vn and vlan are valid):
			(       true,  true,             false, true ): hdr_strip_1__from_vlan_tag0__to_vn_tag();      // pkt: 1-2 tags + vn ==> delete vlan0    (vlan to vn)

			// case 3 (e/vn + ---- delete, both e/vn and vlan are valid):
			(       true,  true,             true,  false): hdr_strip_1__from_vn_tag_____to_eth();         // pkt: 1-2 tags + vn ==> delete vn       (vn   to eth)

			// case 4 (e/vn + vlan delete, both e/vn and vlan are valid): -- double delete case
			(       true,  true,             true,  true ): hdr_strip_2__from_vlan_tag0__to_eth();         // pkt: 1-2 tags + vn ==> delete vlan0+vn (vlan to eth)

#elif !defined(ETAG_ENABLE) && !defined(VNTAG_ENABLE)

			// case 0 (---- + vlan delete, only vlan          are valid):
			(              true,                    true ): hdr_strip_1__from_vlan_tag0__to_eth();         // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

#endif

		}
	}

	// -----------------------------------------------------------------
	// Apply
	// -----------------------------------------------------------------

	apply {
#ifdef ETAG_ENABLE
 		hdr_1_e_tag_isValid = hdr_1.e_tag.isValid();
#else
 		hdr_1_e_tag_isValid = false;
#endif

#ifdef VNTAG_ENABLE
 		hdr_1_vn_tag_isValid = hdr_1.vn_tag.isValid();
#else
 		hdr_1_vn_tag_isValid = false;
#endif

		hdr_strip.apply();
	}

}
