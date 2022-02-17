
#ifndef _NPB_ING_SET_LKP_
#define _NPB_ING_SET_LKP_

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupTransport(
	inout switch_header_transport_t hdr_0, // src
	inout switch_ingress_metadata_t ig_md  // dst
) (
	MODULE_DEPLOYMENT_PARAMS
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

	action set_lkp_type_tos_v4() {
		if(TRANSPORT_IPV4_INGRESS_ENABLE) {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV4;
//			ig_md.lkp_0.ip_tos = hdr_0.ipv4.tos;
		}
	}

	action set_lkp_type_tos_v6() {
		if(TRANSPORT_IPV6_INGRESS_ENABLE) {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_0.ip_tos = hdr_0.ipv6.tos;
		}
	}

	action set_lkp_type_tos_none() {
		ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
	}

	bool hdr_0_ipv6_isValid;

	table set_lkp_type_tos {
		key = {
			hdr_0.ipv4.isValid() : exact;
			hdr_0_ipv6_isValid   : exact;
			hdr_0.udp.isValid() : exact; // dummy key, to get around barefoot table with less than 4 entries issue
		}

		actions = {
			NoAction;
			set_lkp_type_tos_v4;
			set_lkp_type_tos_v6;
			set_lkp_type_tos_none;
		}

		const entries = {
			(true,  false, false) : set_lkp_type_tos_v4();
			(false, true,  false) : set_lkp_type_tos_v6();
			(false, false, false) : set_lkp_type_tos_none();
			(true,  true,  false) : NoAction(); // illegal
			(true,  false, true ) : set_lkp_type_tos_v4();
			(false, true,  true ) : set_lkp_type_tos_v6();
			(false, false, true ) : set_lkp_type_tos_none();
			(true,  true,  true ) : NoAction(); // illegal
		}
		const default_action = NoAction;
	}

	// -----------------------------
	// Table: Lkp to Lkp
	// -----------------------------

	action set_lkp_next_lyr_valid_value(bool value) {
		ig_md.lkp_0.next_lyr_valid = value;
	}

	table set_lkp_next_lyr_valid {
		key = {
			ig_md.lkp_0.tunnel_type : exact;
		}
		actions = { set_lkp_next_lyr_valid_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_lkp_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_VXLAN)       : set_lkp_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP)      : set_lkp_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_lkp_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_next_lyr_valid_value(false);
		}
		const default_action = set_lkp_next_lyr_valid_value(true);
	}

	// -----------------------------
	// Apply
	// -----------------------------

	apply {
		if(TRANSPORT_IPV6_INGRESS_ENABLE) hdr_0_ipv6_isValid = hdr_0.ipv6.isValid();
/*
		if       (TRANSPORT_IPV4_INGRESS_ENABLE && hdr_0.ipv4.isValid()) {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV4;
		} else if(TRANSPORT_IPV6_INGRESS_ENABLE && hdr_0.ipv6.isValid()) {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_0.ip_tos = hdr_0.ipv6.tos;
		} else {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
		}
*/
		set_lkp_type_tos.apply();

		// -----------------------------------------------------------------------

//		ig_md.lkp_0.next_lyr_valid = true;
/*
		if((ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_0.next_lyr_valid = true;
		} else {
			ig_md.lkp_0.next_lyr_valid = false;
		}
*/
		set_lkp_next_lyr_valid.apply();

	}
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupOuter(
	inout switch_header_outer_t     hdr_1, // src
	inout switch_ingress_metadata_t ig_md  // dst
) (
	MODULE_DEPLOYMENT_PARAMS
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

	action set_lkp_type_tos_v4() {
		ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_1.ip_tos = hdr_1.ipv4.tos;
	}

	action set_lkp_type_tos_v6() {
		if(OUTER_IPV6_ENABLE) {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
		}
	}

	action set_lkp_type_tos_none() {
		ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_type_tos_ {
		key = {
			hdr_1.ipv4.isValid() : exact;
			hdr_1.udp.isValid() : exact; // dummy key, to get around barefoot table with less than 4 entries issue
		}

		actions = {
			NoAction;
			set_lkp_type_tos_v4;
			set_lkp_type_tos_v6;
			set_lkp_type_tos_none;
		}

		const entries = {
			(true,         false) : set_lkp_type_tos_v4();
			(false,        false) : set_lkp_type_tos_none();
			(true,         true ) : set_lkp_type_tos_v4();
			(false,        true ) : set_lkp_type_tos_none();
		}
		const default_action = NoAction;
	}

	table set_lkp_type_tos_v6_ {
		key = {
			hdr_1.ipv4.isValid() : exact;
			hdr_1.ipv6.isValid() : exact;
			hdr_1.udp.isValid() : exact; // dummy key, to get around barefoot table with less than 4 entries issue
		}

		actions = {
			NoAction;
			set_lkp_type_tos_v4;
			set_lkp_type_tos_v6;
			set_lkp_type_tos_none;
		}

		const entries = {
			(true,  false, false) : set_lkp_type_tos_v4();
			(false, true,  false) : set_lkp_type_tos_v6();
			(false, false, false) : set_lkp_type_tos_none();
			(true,  true,  false) : NoAction(); // illegal
			(true,  false, true ) : set_lkp_type_tos_v4();
			(false, true,  true ) : set_lkp_type_tos_v6();
			(false, false, true ) : set_lkp_type_tos_none();
			(true,  true,  true ) : NoAction(); // illegal
		}
		const default_action = NoAction;
	}

	// -----------------------------
	// Table: Lkp to Lkp
	// -----------------------------

	action set_lkp_next_lyr_valid_value(bool value) {
		ig_md.lkp_1.next_lyr_valid = value;
	}

	table set_lkp_next_lyr_valid {
		key = {
			ig_md.lkp_1.tunnel_type : exact;
		}
		actions = { set_lkp_next_lyr_valid_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_lkp_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_VXLAN)       : set_lkp_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP)      : set_lkp_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_lkp_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_next_lyr_valid_value(false);
		}
		const default_action = set_lkp_next_lyr_valid_value(true);
	}

	// -----------------------------
	// Apply
	// -----------------------------

	apply {
/*
		if     (hdr_1.ipv4.isValid()) {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
		} else if(OUTER_IPV6_ENABLE && hdr_1.ipv6.isValid()) {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
		} else {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		}
*/
		if(OUTER_IPV6_ENABLE) {
			set_lkp_type_tos_v6_.apply();
		} else {
			set_lkp_type_tos_.apply();
		}

		// -----------------------------------------------------------------------

/*
//		ig_md.lkp_1.next_lyr_valid = true;
		if((ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_1.next_lyr_valid = true;
		} else {
			ig_md.lkp_1.next_lyr_valid = false;
		}
*/
		set_lkp_next_lyr_valid.apply();

	}
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupInner(
	inout switch_header_inner_t     hdr_2, // src
	inout switch_ingress_metadata_t ig_md  // dst
) (
	MODULE_DEPLOYMENT_PARAMS
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

	action set_lkp_type_tos_v4() {
		ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_2.ip_tos = hdr_2.ipv4.tos;
	}

	action set_lkp_type_tos_v6() {
		if(INNER_IPV6_ENABLE) {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_2.ip_tos = hdr_2.ipv6.tos;
		}
	}

	action set_lkp_type_tos_none() {
		ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
	}

	table set_lkp_type_tos_ {
		key = {
			hdr_2.ipv4.isValid() : exact;
			hdr_2.udp.isValid() : exact; // dummy key, to get around barefoot table with less than 4 entries issue
		}

		actions = {
			NoAction;
			set_lkp_type_tos_v4;
			set_lkp_type_tos_v6;
			set_lkp_type_tos_none;
		}

		const entries = {
			(true,         false) : set_lkp_type_tos_v4();
			(false,        false) : set_lkp_type_tos_none();
			(true,         true ) : set_lkp_type_tos_v4();
			(false,        true ) : set_lkp_type_tos_none();
		}
		const default_action = NoAction;
	}

	table set_lkp_type_tos_v6_ {
		key = {
			hdr_2.ipv4.isValid() : exact;
			hdr_2.ipv6.isValid() : exact;
			hdr_2.udp.isValid() : exact; // dummy key, to get around barefoot table with less than 4 entries issue
		}

		actions = {
			NoAction;
			set_lkp_type_tos_v4;
			set_lkp_type_tos_v6;
			set_lkp_type_tos_none;
		}

		const entries = {
			(true,  false, false) : set_lkp_type_tos_v4();
			(false, true,  false) : set_lkp_type_tos_v6();
			(false, false, false) : set_lkp_type_tos_none();
			(true,  true,  false) : NoAction(); // illegal
			(true,  false, true ) : set_lkp_type_tos_v4();
			(false, true,  true ) : set_lkp_type_tos_v6();
			(false, false, true ) : set_lkp_type_tos_none();
			(true,  true,  true ) : NoAction(); // illegal
		}
		const default_action = NoAction;
	}

	// -----------------------------
	// Table: Lkp to Lkp
	// -----------------------------

	action set_lkp_next_lyr_valid_value(bool value) {
		ig_md.lkp_2.next_lyr_valid = value;
	}

	table set_lkp_next_lyr_valid {
		key = {
			ig_md.lkp_2.tunnel_type : exact;
		}
		actions = { set_lkp_next_lyr_valid_value; }
		const entries = {
			(SWITCH_TUNNEL_TYPE_NONE)        : set_lkp_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_VXLAN)       : set_lkp_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_IPINIP)      : set_lkp_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
			(SWITCH_TUNNEL_TYPE_GTPC)        : set_lkp_next_lyr_valid_value(false);
			(SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_next_lyr_valid_value(false);
		}
		const default_action = set_lkp_next_lyr_valid_value(true);
	}

	// -----------------------------
	// Apply
	// -----------------------------

	apply {
/*
		if     (hdr_2.ipv4.isValid()) {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
		} else if(INNER_IPV6_ENABLE && hdr_2.ipv6.isValid()) {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_2.ip_tos = hdr_2.ipv6.tos;
		} else {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
		}
*/
		if(INNER_IPV6_ENABLE) {
			set_lkp_type_tos_v6_.apply();
		} else {
			set_lkp_type_tos_.apply();
		}

		// -----------------------------------------------------------------------

//		ig_md.lkp_2.next_lyr_valid = true;
/*
		if((ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_2.next_lyr_valid = true;
		} else {
			ig_md.lkp_2.next_lyr_valid = false;
		}
*/
		set_lkp_next_lyr_valid.apply();

	}
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookup(
	inout switch_header_t           hdr,  // src
	inout switch_ingress_metadata_t ig_md // dst
) (
	MODULE_DEPLOYMENT_PARAMS
) {
	IngressSetLookupTransport(INSTANCE_DEPLOYMENT_PARAMS) IngressSetLookupTransport_;
	IngressSetLookupOuter    (INSTANCE_DEPLOYMENT_PARAMS) IngressSetLookupOuter_;
	IngressSetLookupInner    (INSTANCE_DEPLOYMENT_PARAMS) IngressSetLookupInner_;

	apply {
        // This is for the special ipv4 / udp / vxlan case.
        // When we attempt to do this in the parser, unrelated parser tests start failing.
        if(ig_md.flags.outer_enet_in_transport == true) {
//          hdr.outer.ethernet = {
//              dst_addr   = hdr_transport.ethernet.dst_addr,
//              src_addr   = hdr_transport.ethernet.src_addr,
//              ether_type = hdr_transport.ethernet.ether_type
//			};

//          hdr.outer.ethernet.dst_addr   = hdr.transport.ethernet.dst_addr;
//          hdr.outer.ethernet.src_addr   = hdr.transport.ethernet.src_addr;
            hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;
            hdr.transport.ethernet.setInvalid();
		}

		// -----------------------------------------------------------------------

#ifdef INGRESS_PARSER_POPULATES_LKP_0
		IngressSetLookupTransport_.apply(hdr.transport, ig_md);  // set lookup structure fields that parser couldn't
#endif
#ifdef INGRESS_PARSER_POPULATES_LKP_1
		IngressSetLookupOuter_.apply    (hdr.outer,     ig_md);  // set lookup structure fields that parser couldn't
#endif
#ifdef INGRESS_PARSER_POPULATES_LKP_2
		IngressSetLookupInner_.apply    (hdr.inner,     ig_md);  // set lookup structure fields that parser couldn't
#endif

	}
}

#endif // _NPB_ING_SET_LKP_
