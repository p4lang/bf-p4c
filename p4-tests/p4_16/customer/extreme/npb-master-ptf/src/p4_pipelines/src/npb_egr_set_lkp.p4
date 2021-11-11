
#ifndef _NPB_EGR_SET_LKP_
#define _NPB_EGR_SET_LKP_

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control EgressSetLookup(
	in    switch_header_outer_t       hdr_1, // src
	in    switch_header_inner_t       hdr_2, // src
	inout switch_egress_metadata_t    eg_md, // dst

	in    egress_intrinsic_metadata_t eg_intr_md
) {

	// Override whatever the parser set "ip_type" to.  Doing so allows the
	// signal to fit when normally it doesn't.  This code should be only
	// temporary, and can be removed at a later date when a better compiler
	// is available....

	// Set "ip_tos" here:
	//
	// ipv6: would like to do this stuff in the parser, but can't because tos
	// field isn't byte aligned...
	//
	// ipv4: would like to do this stuff in the parser, but get the following error:
	//   "error: Field is extracted in the parser into multiple containers, but
	//    the container slices after the first aren't byte aligned"

	// -----------------------------
	// Table: Hdr to Lkp
	// -----------------------------

#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED

	action set_lkp_1_type_tos_v4() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		eg_md.lkp_1.ip_tos = hdr_1.ipv4.tos;
	}

	action set_lkp_1_type_tos_v6() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
		eg_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
	}

	action set_lkp_1_type_tos_none() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
	}

	action set_lkp_2_v4() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		eg_md.lkp_1.ip_tos = hdr_2.ipv4.tos;
	}

	action set_lkp_2_v6() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
		eg_md.lkp_1.ip_tos = hdr_2.ipv6.tos;
	}

	action set_lkp_2_none() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_1_type_tos {
		key = {
			eg_md.nsh_md.scope : exact;
			hdr_1.ipv4.isValid() : exact;
			hdr_1.ipv6.isValid() : exact;
			hdr_2.ipv4.isValid() : exact;
			hdr_2.ipv6.isValid() : exact;
		}

		actions = {
			NoAction;
			set_lkp_1_type_tos_v4;
			set_lkp_1_type_tos_v6;
			set_lkp_1_type_tos_none;
			set_lkp_2_v4;
			set_lkp_2_v6;
			set_lkp_2_none;
		}

		const entries = {
/*
			(0, true,  false, _,     _    ) : set_lkp_1_type_tos_v4();   // inner is a don't care
			(0, false, true,  _,     _    ) : set_lkp_1_type_tos_v6();   // inner is a don't care
			(0, false, false, _,     _    ) : set_lkp_1_type_tos_none(); // inner is a don't care
			(1, _,     _,     true,  false) : set_lkp_2_v4();   // outer is a don't care
			(1, _,     _,     false, true ) : set_lkp_2_v6();   // outer is a don't care
			(1, _,     _,     false, false) : set_lkp_2_none(); // outer is a don't care
*/
			(1, true,  false, false, false) : set_lkp_1_type_tos_v4();   // note: inner is a don't care
			(1, true,  false, true,  false) : set_lkp_1_type_tos_v4();   // note: inner is a don't care
			(1, true,  false, false, true ) : set_lkp_1_type_tos_v4();   // note: inner is a don't care
			(1, true,  false, true,  true ) : set_lkp_1_type_tos_v4();   // note: inner is a don't care

			(1, false, true,  false, false) : set_lkp_1_type_tos_v6();   // note: inner is a don't care
			(1, false, true,  true,  false) : set_lkp_1_type_tos_v6();   // note: inner is a don't care
			(1, false, true,  false, true ) : set_lkp_1_type_tos_v6();   // note: inner is a don't care
			(1, false, true,  true,  true ) : set_lkp_1_type_tos_v6();   // note: inner is a don't care

			(1, false, false, false, false) : set_lkp_1_type_tos_none(); // note: inner is a don't care
			(1, false, false, true,  false) : set_lkp_1_type_tos_none(); // note: inner is a don't care
			(1, false, false, false, true ) : set_lkp_1_type_tos_none(); // note: inner is a don't care
			(1, false, false, true,  true ) : set_lkp_1_type_tos_none(); // note: inner is a don't care

			(2, false, false, true,  false) : set_lkp_2_v4();   // note: outer is a don't care
			(2, true,  false, true,  false) : set_lkp_2_v4();   // note: outer is a don't care
			(2, false, true,  true,  false) : set_lkp_2_v4();   // note: outer is a don't care
			(2, true,  true,  true,  false) : set_lkp_2_v4();   // note: outer is a don't care

			(2, false, false, false, true ) : set_lkp_2_v6();   // note: outer is a don't care
			(2, true,  false, false, true ) : set_lkp_2_v6();   // note: outer is a don't care
			(2, false, true,  false, true ) : set_lkp_2_v6();   // note: outer is a don't care
			(2, true,  true,  false, true ) : set_lkp_2_v6();   // note: outer is a don't care

			(2, false, false, false, false) : set_lkp_2_none(); // note: outer is a don't care
			(2, true,  false, false, false) : set_lkp_2_none(); // note: outer is a don't care
			(2, false, true,  false, false) : set_lkp_2_none(); // note: outer is a don't care
			(2, true,  true,  false, false) : set_lkp_2_none(); // note: outer is a don't care
		}
		const default_action = NoAction;
	}

#else
  #ifdef EGRESS_PARSER_POPULATES_LKP_WITH_OUTER

	action set_lkp_1_type_tos_v4() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		eg_md.lkp_1.ip_tos = hdr_1.ipv4.tos;
	}

	action set_lkp_1_type_tos_v6() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
		eg_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
	}

	action set_lkp_1_type_tos_none() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_1_type_tos {
		key = {
			hdr_1.ipv4.isValid() : exact;
			hdr_1.ipv6.isValid() : exact;
		}

		actions = {
			NoAction;
			set_lkp_1_type_tos_v4;
			set_lkp_1_type_tos_v6;
			set_lkp_1_type_tos_none;
		}

		const entries = {
			(true,  false) : set_lkp_1_type_tos_v4();
			(false, true ) : set_lkp_1_type_tos_v6();
			(false, false) : set_lkp_1_type_tos_none();
			(true,  true ) : NoAction(); // illegal
		}
		const default_action = NoAction;
	}

  #endif
#endif

	// -----------------------------
	// Table: Lkp to Lkp
	// -----------------------------

	action set_lkp_1_next_lyr_valid_value(bool value) {
		eg_md.lkp_1.next_lyr_valid = value;
	}

	table set_lkp_1_next_lyr_valid {
		key = {
			eg_md.lkp_1.tunnel_type : exact;
		}
		actions = { set_lkp_1_next_lyr_valid_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_lkp_1_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_VXLAN)       : set_lkp_1_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP)      : set_lkp_1_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_lkp_1_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_1_next_lyr_valid_value(false);
		}
		const default_action = set_lkp_1_next_lyr_valid_value(true);
	}

	// -----------------------------
	// Apply
	// -----------------------------

	apply {

//		eg_md.tunnel_1.terminate = false;

#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED
/*
		if(eg_md.nsh_md.scope == 1) {
			if     (hdr_1.ipv4.isValid())
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
			else if(hdr_1.ipv6.isValid()) {
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
				eg_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
			} else
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		} else {
			if     (hdr_2.ipv4.isValid())
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
			else if(hdr_2.ipv6.isValid()) {
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
				eg_md.lkp_1.ip_tos = hdr_2.ipv6.tos;
			} else
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		}
*/
		set_lkp_1_type_tos.apply();
#else
  #ifdef EGRESS_PARSER_POPULATES_LKP_WITH_OUTER
		if     (hdr_1.ipv4.isValid())
			eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
		else if(hdr_1.ipv6.isValid()) {
			eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
			eg_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
		} else
			eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
  #endif
#endif

		// -----------------------------------------------------------------------

#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
/*
//		eg_md.lkp_1.next_lyr_valid = true;

		if((eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			eg_md.lkp_1.next_lyr_valid = true;
		} else {
			eg_md.lkp_1.next_lyr_valid = false;
		}
*/
		set_lkp_1_next_lyr_valid.apply();
#endif

		// -----------------------------------------------------------------------

		// This code does not work for detecting copy-to-cpu packets, due to bug in chip....
		// (note: leaving in, because removing it causes design to take 21 stages?!?!)
/*
		if((eg_intr_md.egress_rid == 0) && (eg_intr_md.egress_rid_first == 1)) {
			eg_md.flags.bypass_egress = true;
		}
*/
	}
}

#endif // _NPB_EGR_SET_LKP_
