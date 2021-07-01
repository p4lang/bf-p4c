
#ifndef _NPB_ING_SET_LKP_
#define _NPB_ING_SET_LKP_

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupTransport(
	inout switch_header_transport_t hdr_0, // src
	inout switch_ingress_metadata_t ig_md  // dst
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
	// Table: Hdr to Lkp
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_0
	action set_lkp_0_type_tos_v4() {
		ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_0.ip_tos = hdr_0.ipv4.tos;
	}

	action set_lkp_0_type_tos_v6() {
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
		ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV6;
		ig_md.lkp_0.ip_tos = hdr_0.ipv6.tos;
  #endif
	}

	action set_lkp_0_type_tos_none() {
		ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_0_type_tos {
		key = {
			hdr_0.ipv4.isValid() : exact;
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
			hdr_0.ipv6.isValid() : exact;
  #endif
		}

		actions = {
			NoAction;
			set_lkp_0_type_tos_v4;
			set_lkp_0_type_tos_v6;
			set_lkp_0_type_tos_none;
		}

		const entries = {
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
			(true,  false) : set_lkp_0_type_tos_v4();
			(false, true ) : set_lkp_0_type_tos_v6();
			(false, false) : set_lkp_0_type_tos_none();
			(true,  true ) : NoAction(); // illegal
  #else
			(true        ) : set_lkp_0_type_tos_v4();
			(false       ) : set_lkp_0_type_tos_none();
  #endif
		}
		const default_action = NoAction;
	}
#endif
	// -----------------------------
	// Table: Lkp to Lkp
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_0
	action set_lkp_0_next_lyr_valid_value(bool value) {
		ig_md.lkp_0.next_lyr_valid = value;
	}

	table set_lkp_0_next_lyr_valid {
		key = {
			ig_md.lkp_0.tunnel_type : exact;
		}
		actions = { set_lkp_0_next_lyr_valid_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_lkp_0_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_VXLAN)       : set_lkp_0_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP)      : set_lkp_0_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_lkp_0_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_0_next_lyr_valid_value(false);
		}
		const default_action = set_lkp_0_next_lyr_valid_value(true);
	}
#endif
	// -----------------------------
	// Apply
	// -----------------------------

	apply {

#ifdef INGRESS_PARSER_POPULATES_LKP_0
		if     (hdr_0.ipv4.isValid()) {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV4;
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
		} else if(hdr.transport.ipv6.isValid()) {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_0.ip_tos = hdr_1.ipv6.tos;
  #endif
		} else {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
		}

//		set_lkp_0_type_tos.apply();
#endif // INGRESS_PARSER_POPULATES_LKP_0

		// -----------------------------------------------------------------------

#ifdef INGRESS_PARSER_POPULATES_LKP_0
//		ig_md.lkp_0.next_lyr_valid = true;
/*
		if((ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_0.next_lyr_valid = true;
		} else {
			ig_md.lkp_0.next_lyr_valid = false;
		}
*/
		set_lkp_0_next_lyr_valid.apply();
#endif // INGRESS_PARSER_POPULATES_LKP_0
		
	}
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupOuter(
	inout switch_header_outer_t     hdr_1, // src
	inout switch_ingress_metadata_t ig_md, // dst

	inout switch_header_transport_t hdr_0  // src
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
	// Table: Hdr to Lkp
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_1
	action set_lkp_1_type_tos_v4() {
		ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_1.ip_tos = hdr_1.ipv4.tos;
	}

	action set_lkp_1_type_tos_v6() {
		ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
		ig_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
	}

	action set_lkp_1_type_tos_none() {
		ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
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
	// -----------------------------
	// Table: Lkp to Lkp
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_1
	action set_lkp_1_next_lyr_valid_value(bool value) {
		ig_md.lkp_1.next_lyr_valid = value;
	}

	table set_lkp_1_next_lyr_valid {
		key = {
			ig_md.lkp_1.tunnel_type : exact;
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
#endif
	// -----------------------------
	// Apply
	// -----------------------------

	apply {

        // This is for the special ipv4 / udp / vxlan case.
        // When we attempt to do this in the parser, unrelated parser tests start failing.
        if(ig_md.flags.outer_enet_in_transport == true) {
//          hdr_1.ethernet = {
//              dst_addr   = hdr_0.ethernet.dst_addr,
//              src_addr   = hdr_0.ethernet.src_addr,
//              ether_type = hdr_0.ethernet.ether_type
//			};

//          hdr_1.ethernet.dst_addr   = hdr_0.ethernet.dst_addr;
//          hdr_1.ethernet.src_addr   = hdr_0.ethernet.src_addr;
            hdr_1.ethernet.ether_type = hdr_0.ethernet.ether_type;
            hdr_0.ethernet.setInvalid();
		}

		// -----------------------------------------------------------------------

#ifdef INGRESS_PARSER_POPULATES_LKP_1
		if     (hdr_1.ipv4.isValid()) {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
  #ifdef IPV6_ENABLE
		}else if(hdr_1.ipv6.isValid()) {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
  #endif
		} else {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		}

//		set_lkp_1_type_tos.apply();
#endif // INGRESS_PARSER_POPULATES_LKP_1

		// -----------------------------------------------------------------------

#ifdef INGRESS_PARSER_POPULATES_LKP_1
/*
//		ig_md.lkp_1.next_lyr_valid = true;
		if((ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_1.next_lyr_valid = true;
		} else {
			ig_md.lkp_1.next_lyr_valid = false;
		}
*/
		set_lkp_1_next_lyr_valid.apply();
#endif // INGRESS_PARSER_POPULATES_LKP_1

	}
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupInner(
	inout switch_header_inner_t     hdr_2, // src
	inout switch_ingress_metadata_t ig_md  // dst
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
	// Table: Hdr to Lkp
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_2
	action set_lkp_2_type_tos_v4() {
		ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_2.ip_tos = hdr_2.ipv4.tos;
	}

	action set_lkp_2_type_tos_v6() {
		ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
		ig_md.lkp_2.ip_tos = hdr_2.ipv6.tos;
	}

	action set_lkp_2_type_tos_none() {
		ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_2_type_tos {
		key = {
			hdr_2.ipv4.isValid() : exact;
			hdr_2.ipv6.isValid() : exact;
		}

		actions = {
			NoAction;
			set_lkp_2_type_tos_v4;
			set_lkp_2_type_tos_v6;
			set_lkp_2_type_tos_none;
		}

		const entries = {
			(true,  false) : set_lkp_2_type_tos_v4();
			(false, true ) : set_lkp_2_type_tos_v6();
			(false, false) : set_lkp_2_type_tos_none();
			(true,  true ) : NoAction(); // illegal
		}
		const default_action = NoAction;
	}
#endif
	// -----------------------------
	// Table: Lkp to Lkp
	// -----------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_2
	action set_lkp_2_next_lyr_valid_value(bool value) {
		ig_md.lkp_2.next_lyr_valid = value;
	}

	table set_lkp_2_next_lyr_valid {
		key = {
			ig_md.lkp_2.tunnel_type : exact;
		}
		actions = { set_lkp_2_next_lyr_valid_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_lkp_2_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_VXLAN)       : set_lkp_2_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP)      : set_lkp_2_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_lkp_2_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_2_next_lyr_valid_value(false);
		}
		const default_action = set_lkp_2_next_lyr_valid_value(true);
	}
#endif
	// -----------------------------
	// Apply
	// -----------------------------

	apply {

#ifdef INGRESS_PARSER_POPULATES_LKP_2
		if     (hdr_2.ipv4.isValid()) {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
  #ifdef IPV6_ENABLE
		} else if(hdr_2.ipv6.isValid()) {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_2.ip_tos = hdr_2.ipv6.tos;
  #endif
		} else {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
		}

//		set_lkp_2_type_tos.apply();
#endif // INGRESS_PARSER_POPULATES_LKP_2

		// -----------------------------------------------------------------------

#ifdef INGRESS_PARSER_POPULATES_LKP_2
//		ig_md.lkp_2.next_lyr_valid = true;
/*
		if((ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_2.next_lyr_valid = true;
		} else {
			ig_md.lkp_2.next_lyr_valid = false;
		}
*/
		set_lkp_2_next_lyr_valid.apply();
#endif // INGRESS_PARSER_POPULATES_LKP_2

	}
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookup(
	inout switch_header_t           hdr,  // src
	inout switch_ingress_metadata_t ig_md // dst
) {
	apply {
		IngressSetLookupTransport.apply(hdr.transport, ig_md);  // set lookup structure fields that parser couldn't
		IngressSetLookupOuter.apply    (hdr.outer,     ig_md, hdr.transport);  // set lookup structure fields that parser couldn't
		IngressSetLookupInner.apply    (hdr.inner,     ig_md);  // set lookup structure fields that parser couldn't
	}
}

#endif // _NPB_ING_SET_LKP_
