
#ifndef _NPB_ING_SET_LKP_
#define _NPB_ING_SET_LKP_

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookup(
        in    switch_header_t           hdr,  // src
        inout switch_ingress_metadata_t ig_md // dst
) {
    
    // -----------------------------
	// Apply
    // -----------------------------

    apply {

		ig_md.lkp_0.next_lyr_valid = true;
//		if((ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
//			ig_md.lkp_0.next_lyr_valid = true;
//		}
		
//		ig_md.lkp_1.next_lyr_valid = true;
		if((ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_1.next_lyr_valid = true;
		}

//		ig_md.lkp_2.next_lyr_valid = true;
		if((ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_2.next_lyr_valid = true;
		}

		// -----------------------------------------------------------------------
        
        // Override whatever the parser set "ip_type" to.  Doing so allows the
        // signal to fit when normally it doesn't.  This code should be only
        // temporary, and can be removed at a later date when a better compiler
        // is available....
        if     (hdr.outer.ipv4.isValid())
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
        else if(hdr.outer.ipv6.isValid())
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
        else
            ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;

        if     (hdr.inner.ipv4.isValid())
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
        else if(hdr.inner.ipv6.isValid())
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
        else
            ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;

		// -----------------------------------------------------------------------
        
		// ipv6: would like to do this stuff in the parser, but can't because tos
		// field isn't byte aligned...

		// ipv4: would like to do this stuff in the parser, but get the following error:
        //   "error: Field is extracted in the parser into multiple containers, but
        //    the container slices after the first aren't byte aligned"
#ifdef INGRESS_PARSER_POPULATES_LKP_1
#ifdef IPV6_ENABLE
		if(hdr.outer.ipv6.isValid()) {
			ig_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
		}        
#endif // IPV6_ENABLE
//		if(hdr.outer.ipv4.isValid()) {
//			ig_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//		}        
#endif
#ifdef INGRESS_PARSER_POPULATES_LKP_2
#ifdef IPV6_ENABLE
		if(hdr.inner.ipv6.isValid()) {
			ig_md.lkp_2.ip_tos = hdr.inner.ipv6.tos;
		}
#endif // IPV6_ENABLE
//		if(hdr.inner.ipv4.isValid()) {
//			ig_md.lkp_2.ip_tos = hdr.inner.ipv4.tos;
//		}
#endif        

    }
}


#endif // _NPB_ING_SET_LKP_
    
