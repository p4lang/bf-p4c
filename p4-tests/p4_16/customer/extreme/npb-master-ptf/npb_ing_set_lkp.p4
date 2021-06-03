
#ifndef _NPB_ING_SET_LKP_
#define _NPB_ING_SET_LKP_

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookup(
	inout switch_header_t           hdr,  // src
	inout switch_ingress_metadata_t ig_md // dst
) {

	// Override whatever the parser set "ip_type" to.  Doing so allows the
	// signal to fit when normally it doesn't.  This code should be only
	// temporary, and can be removed at a later date when a better compiler
	// is available....

	// Set "ip_tos here:
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
#ifdef INGRESS_PARSER_POPULATES_LKP_1
	action set_lkp_1_v4() {
		ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
	}

	action set_lkp_1_v6() {
		ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
		ig_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
	}

	action set_lkp_1_none() {
		ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
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
			(true,  true ) : NoAction(); // illegal
		}
		const default_action = NoAction;
	}
#endif
	// -----------------------------
	// Table
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_2
	action set_lkp_2_v4() {
		ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_2.ip_tos = hdr.inner.ipv4.tos;
	}

	action set_lkp_2_v6() {
		ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
		ig_md.lkp_2.ip_tos = hdr.inner.ipv6.tos;
	}

	action set_lkp_2_none() {
		ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_2 {
		key = {
			hdr.inner.ipv4.isValid() : exact;
			hdr.inner.ipv6.isValid() : exact;
		}

		actions = {
			NoAction;
			set_lkp_2_v4;
			set_lkp_2_v6;
			set_lkp_2_none;
		}

		const entries = {
			(true,  false) : set_lkp_2_v4();
			(false, true ) : set_lkp_2_v6();
			(false, false) : set_lkp_2_none();
			(true,  true ) : NoAction(); // illegal
		}
		const default_action = NoAction;
	}
#endif
	// -----------------------------
	// Table
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_1
	action set_next_lyr_valid_1_value(bool value) {
		ig_md.lkp_1.next_lyr_valid = value;
	}

	table set_next_lyr_valid_1 {
		key = {
			ig_md.lkp_1.tunnel_type : exact;
		}
		actions = { set_next_lyr_valid_1_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_next_lyr_valid_1_value(false);
			(SWITCH_TUNNEL_TYPE_VXLAN)       : set_next_lyr_valid_1_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP)      : set_next_lyr_valid_1_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_next_lyr_valid_1_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_next_lyr_valid_1_value(false);
		}
		const default_action = set_next_lyr_valid_1_value(true);
	}
#endif
	// -----------------------------
	// Table
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_2
	action set_next_lyr_valid_2_value(bool value) {
		ig_md.lkp_2.next_lyr_valid = value;
	}

	table set_next_lyr_valid_2 {
		key = {
			ig_md.lkp_2.tunnel_type : exact;
		}
		actions = { set_next_lyr_valid_2_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_next_lyr_valid_2_value(false);
			(SWITCH_TUNNEL_TYPE_VXLAN)       : set_next_lyr_valid_2_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP)      : set_next_lyr_valid_2_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_next_lyr_valid_2_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_next_lyr_valid_2_value(false);
		}
		const default_action = set_next_lyr_valid_2_value(true);
	}
#endif
	// -----------------------------
	// Apply
	// -----------------------------

	apply {

        // This is for the special ipv4 / udp / vxlan case.
        // When we attempt to do this in the parser, unrelated parser tests start failing.
        if(ig_md.flags.outer_enet_in_transport == true) {
/*
            hdr.outer.ethernet = {
                dst_addr   = hdr.transport.ethernet.dst_addr,
                src_addr   = hdr.transport.ethernet.src_addr,
                ether_type = hdr.transport.ethernet.ether_type
			};
*/
//          hdr.outer.ethernet.dst_addr   = hdr.transport.ethernet.dst_addr;
//          hdr.outer.ethernet.src_addr   = hdr.transport.ethernet.src_addr;
            hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;
            hdr.transport.ethernet.setInvalid();
        }
		// -----------------------------------------------------------------------

#ifdef INGRESS_PARSER_POPULATES_LKP_0
		ig_md.lkp_0.next_lyr_valid = true;
//		if((ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
//			ig_md.lkp_0.next_lyr_valid = true;
//		} else {
//			ig_md.lkp_0.next_lyr_valid = false;
//		}
#endif
		
#ifdef INGRESS_PARSER_POPULATES_LKP_1
/*
//		ig_md.lkp_1.next_lyr_valid = true;
		if((ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_1.next_lyr_valid = true;
		} else {
			ig_md.lkp_1.next_lyr_valid = false;
		}
*/
		set_next_lyr_valid_1.apply();
#endif

#ifdef INGRESS_PARSER_POPULATES_LKP_2
/*
//		ig_md.lkp_2.next_lyr_valid = true;
		if((ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_2.next_lyr_valid = true;
		} else {
			ig_md.lkp_2.next_lyr_valid = false;
		}
*/
		set_next_lyr_valid_2.apply();
#endif

		// -----------------------------------------------------------------------
/*
#ifdef INGRESS_PARSER_POPULATES_LKP_0
		if     (hdr.transport.ipv4.isValid())
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV4;
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
		else if(hdr.transport.ipv6.isValid())
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV6;
  #endif
		else
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
#endif // INGRESS_PARSER_POPULATES_LKP_0
*/
#ifdef INGRESS_PARSER_POPULATES_LKP_1
		if     (hdr.outer.ipv4.isValid())
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
  #ifdef IPV6_ENABLE
		else if(hdr.outer.ipv6.isValid()) {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
  #endif
		} else
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
#endif // INGRESS_PARSER_POPULATES_LKP_1
/*
#ifdef INGRESS_PARSER_POPULATES_LKP_2
		if     (hdr.inner.ipv4.isValid())
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
  #ifdef IPV6_ENABLE
		else if(hdr.inner.ipv6.isValid()) {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_2.ip_tos = hdr.inner.ipv6.tos;
  #endif
		} else
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
#endif // INGRESS_PARSER_POPULATES_LKP_2
*/
		// -----------------------------------------------------------------------
/*
#ifdef INGRESS_PARSER_POPULATES_LKP_1
  #ifdef IPV6_ENABLE
		if(hdr.outer.ipv6.isValid()) {
		}
  #endif // IPV6_ENABLE
//		if(hdr.outer.ipv4.isValid()) {
//			ig_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//		}
#endif
#ifdef INGRESS_PARSER_POPULATES_LKP_2
  #ifdef IPV6_ENABLE
		if(hdr.inner.ipv6.isValid()) {
		}
  #endif // IPV6_ENABLE
//		if(hdr.inner.ipv4.isValid()) {
//			ig_md.lkp_2.ip_tos = hdr.inner.ipv4.tos;
//		}
#endif
*/

#ifdef INGRESS_PARSER_POPULATES_LKP_1
//		set_lkp_1.apply();
#endif
#ifdef INGRESS_PARSER_POPULATES_LKP_2
		set_lkp_2.apply();
#endif

	}
}

#endif // _NPB_ING_SET_LKP_
