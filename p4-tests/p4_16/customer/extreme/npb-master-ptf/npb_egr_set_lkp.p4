
#ifndef _NPB_EGR_SET_LKP_
#define _NPB_EGR_SET_LKP_

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control EgressSetLookup(
	in    switch_header_t          hdr, // src
	inout switch_egress_metadata_t eg_md // dst
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
	// Table
	// -----------------------------

#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED

	action set_lkp_1_v4() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
	}

	action set_lkp_1_v6() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
		eg_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
	}

	action set_lkp_1_none() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
	}

	action set_lkp_2_v4() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		eg_md.lkp_1.ip_tos = hdr.inner.ipv4.tos;
	}

	action set_lkp_2_v6() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
		eg_md.lkp_1.ip_tos = hdr.inner.ipv6.tos;
	}

	action set_lkp_2_none() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_1 {
		key = {
			eg_md.nsh_md.scope : exact;
			hdr.outer.ipv4.isValid() : exact;
			hdr.outer.ipv6.isValid() : exact;
			hdr.inner.ipv4.isValid() : exact;
			hdr.inner.ipv6.isValid() : exact;
		}

		actions = {
			NoAction;
			set_lkp_1_v4;
			set_lkp_1_v6;
			set_lkp_1_none;
			set_lkp_2_v4;
			set_lkp_2_v6;
			set_lkp_2_none;
		}

		const entries = {
/*
			(0, true,  false, _,     _    ) : set_lkp_1_v4();   // inner is a don't care
			(0, false, true,  _,     _    ) : set_lkp_1_v6();   // inner is a don't care
			(0, false, false, _,     _    ) : set_lkp_1_none(); // inner is a don't care
			(1, _,     _,     true,  false) : set_lkp_2_v4();   // outer is a don't care
			(1, _,     _,     false, true ) : set_lkp_2_v6();   // outer is a don't care
			(1, _,     _,     false, false) : set_lkp_2_none(); // outer is a don't care
*/
			(0, true,  false, false, false) : set_lkp_1_v4();   // note: inner is a don't care
			(0, true,  false, true,  false) : set_lkp_1_v4();   // note: inner is a don't care
			(0, true,  false, false, true ) : set_lkp_1_v4();   // note: inner is a don't care
			(0, true,  false, true,  true ) : set_lkp_1_v4();   // note: inner is a don't care

			(0, false, true,  false, false) : set_lkp_1_v6();   // note: inner is a don't care
			(0, false, true,  true,  false) : set_lkp_1_v6();   // note: inner is a don't care
			(0, false, true,  false, true ) : set_lkp_1_v6();   // note: inner is a don't care
			(0, false, true,  true,  true ) : set_lkp_1_v6();   // note: inner is a don't care

			(0, false, false, false, false) : set_lkp_1_none(); // note: inner is a don't care
			(0, false, false, true,  false) : set_lkp_1_none(); // note: inner is a don't care
			(0, false, false, false, true ) : set_lkp_1_none(); // note: inner is a don't care
			(0, false, false, true,  true ) : set_lkp_1_none(); // note: inner is a don't care

			(1, false, false, true,  false) : set_lkp_2_v4();   // note: outer is a don't care
			(1, true,  false, true,  false) : set_lkp_2_v4();   // note: outer is a don't care
			(1, false, true,  true,  false) : set_lkp_2_v4();   // note: outer is a don't care
			(1, true,  true,  true,  false) : set_lkp_2_v4();   // note: outer is a don't care

			(1, false, false, false, true ) : set_lkp_2_v6();   // note: outer is a don't care
			(1, true,  false, false, true ) : set_lkp_2_v6();   // note: outer is a don't care
			(1, false, true,  false, true ) : set_lkp_2_v6();   // note: outer is a don't care
			(1, true,  true,  false, true ) : set_lkp_2_v6();   // note: outer is a don't care

			(1, false, false, false, false) : set_lkp_2_none(); // note: outer is a don't care
			(1, true,  false, false, false) : set_lkp_2_none(); // note: outer is a don't care
			(1, false, true,  false, false) : set_lkp_2_none(); // note: outer is a don't care
			(1, true,  true,  false, false) : set_lkp_2_none(); // note: outer is a don't care
		}
		const default_action = NoAction;
	}

#else
  #ifdef EGRESS_PARSER_POPULATES_LKP_WITH_OUTER

	action set_lkp_1_v4() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
	}

	action set_lkp_1_v6() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
		eg_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
	}

	action set_lkp_1_none() {
		eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_1 {
		key = {
			hdr.outer.ipv4.isValid() : exact;
			hdr.outer.ipv6.isValid() : exact;
		}

		actions = {
			NoAction;
			set_lkp_1_v4;
			set_lkp_1_v6;
			set_lkp_1_none;
		}

		const entries = {
			(true,  false) : set_lkp_1_v4();
			(false, true ) : set_lkp_1_v6();
			(false, false) : set_lkp_1_none();
		}
		const default_action = NoAction;
	}

  #endif
#endif

	// -----------------------------
	// Table
	// -----------------------------

	action set_next_lyr_valid_1_value(bool value) {
		eg_md.lkp_1.next_lyr_valid = value;
	}

	table set_next_lyr_valid_1 {
		key = {
			eg_md.lkp_1.tunnel_type : exact;
		}
		actions = { set_next_lyr_valid_1_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_next_lyr_valid_1_value(false);
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_next_lyr_valid_1_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_next_lyr_valid_1_value(false);
		}
		const default_action = set_next_lyr_valid_1_value(true);
	}

	// -----------------------------
	// Apply
	// -----------------------------

	apply {

#if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//		eg_md.lkp_1.next_lyr_valid = true;

		if((eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			eg_md.lkp_1.next_lyr_valid = true;
		} else {
			eg_md.lkp_1.next_lyr_valid = false;
		}

//		set_next_lyr_valid_1.apply();
#endif

		// -----------------------------------------------------------------------

#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED
		if(eg_md.nsh_md.scope == 0) {
			if     (hdr.outer.ipv4.isValid())
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
			else if(hdr.outer.ipv6.isValid()) {
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
				eg_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
			} else
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		} else {
			if     (hdr.inner.ipv4.isValid())
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
			else if(hdr.inner.ipv6.isValid()) {
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
				eg_md.lkp_1.ip_tos = hdr.inner.ipv6.tos;
			} else
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		}
#else
  #ifdef EGRESS_PARSER_POPULATES_LKP_WITH_OUTER
		if     (hdr.outer.ipv4.isValid())
			eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
		else if(hdr.outer.ipv6.isValid()) {
			eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
			eg_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
		} else
			eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
  #endif
#endif

		// -----------------------------------------------------------------------
/*
#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED
		if(eg_md.nsh_md.scope == 0) {
			// ----- outer -----
  #ifdef IPV6_ENABLE
			if(hdr.outer.ipv6.isValid()) {
			}
  #endif // IPV6_ENABLE
//			if(hdr.outer.ipv4.isValid()) {
//				eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//			}
		} else {
			// ----- inner -----
  #ifdef IPV6_ENABLE
			if(hdr.inner.ipv6.isValid()) {
			}
  #endif // IPV6_ENABLE
//			if(hdr.inner.ipv4.isValid()) {
//				eg_md.lkp_1.ip_tos = hdr.inner.ipv4.tos;
//			}
		}
#else // EGRESS_PARSER_POPULATES_LKP_SCOPED
  #ifdef EGRESS_PARSER_POPULATES_LKP_WITH_OUTER
		// ----- outer -----
#ifdef IPV6_ENABLE
		if(hdr.outer.ipv6.isValid()) {
		}
#endif // IPV6_ENABLE
//		if(hdr.outer.ipv4.isValid()) {
//			eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//		}
  #endif
#endif // EGRESS_PARSER_POPULATES_LKP_SCOPED
*/

//		set_lkp_1.apply();

	}
}

#endif // _NPB_EGR_SET_LKP_
